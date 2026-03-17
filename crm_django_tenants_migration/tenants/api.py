# tenants/api.py  ← FULL REPLACEMENT
"""
Tenant management API.

TenantViewSet / PlanViewSet run on the PUBLIC schema (superadmin operations).
TenantUserViewSet / TenantInviteViewSet / AuditLogViewSet can run on either
the public schema (superadmin) or a tenant schema (tenant admin managing
their own users).

Permission classes enforce that:
  • Only superadmin can create / delete tenants
  • Tenant admins can only read/update THEIR OWN tenant
  • Regular users cannot access this API at all
"""
import secrets
from datetime import timedelta

from django.utils import timezone
from django.contrib.auth import get_user_model
from rest_framework import viewsets, serializers, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Plan, Tenant, Domain, TenantUser, TenantInvitation, TenantAuditLog

User = get_user_model()


# ── Permissions ────────────────────────────────────────────────────────────────

class IsSuperAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated
                    and request.user.role == 'superadmin')


class IsSuperAdminOrTenantAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.role in ('superadmin', 'admin')


# ── Plan ───────────────────────────────────────────────────────────────────────

class PlanSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Plan
        fields = '__all__'


class PlanViewSet(viewsets.ModelViewSet):
    queryset           = Plan.objects.all()
    serializer_class   = PlanSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_permissions(self):
        if self.action in ('create', 'update', 'partial_update', 'destroy'):
            return [IsSuperAdmin()]
        return [permissions.IsAuthenticated()]


# ── Tenant ─────────────────────────────────────────────────────────────────────

class TenantSerializer(serializers.ModelSerializer):
    plan_name   = serializers.CharField(source='plan.name', read_only=True)
    user_count  = serializers.SerializerMethodField()
    is_active_subscription = serializers.BooleanField(read_only=True)

    class Meta:
        model  = Tenant
        fields = [
            'id', 'schema_name', 'name', 'slug', 'plan', 'plan_name',
            'status', 'billing', 'trial_ends', 'plan_ends',
            'gstin', 'pan', 'email', 'phone',
            'address', 'city', 'state', 'pincode', 'country',
            'timezone_name', 'currency', 'date_format',
            'user_count', 'is_active_subscription',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['schema_name', 'created_at', 'updated_at']

    def get_user_count(self, obj):
        return obj.memberships.filter(is_active=True).count()

    def validate_slug(self, value):
        """Ensure slug converts to a valid PostgreSQL identifier."""
        schema = value.replace('-', '_')
        if not schema.isidentifier():
            raise serializers.ValidationError(
                'Slug must be a valid identifier (letters, numbers, hyphens/underscores).'
            )
        return value


class TenantViewSet(viewsets.ModelViewSet):
    queryset           = Tenant.objects.select_related('plan').exclude(schema_name='public')
    serializer_class   = TenantSerializer
    permission_classes = [IsSuperAdmin]

    @action(detail=True, methods=['post'])
    def suspend(self, request, pk=None):
        tenant = self.get_object()
        tenant.status = 'suspended'
        tenant.save(update_fields=['status'])
        return Response({'detail': f'{tenant.name} suspended.'})

    @action(detail=True, methods=['post'])
    def activate(self, request, pk=None):
        tenant = self.get_object()
        tenant.status = 'active'
        tenant.save(update_fields=['status'])
        return Response({'detail': f'{tenant.name} activated.'})

    @action(detail=True, methods=['post'])
    def change_plan(self, request, pk=None):
        tenant    = self.get_object()
        plan_id   = request.data.get('plan_id')
        if not plan_id:
            return Response({'detail': 'plan_id required.'}, status=400)
        try:
            plan = Plan.objects.get(pk=plan_id)
        except Plan.DoesNotExist:
            return Response({'detail': 'Plan not found.'}, status=404)
        tenant.plan = plan
        tenant.save(update_fields=['plan'])
        return Response({'detail': f'Plan changed to {plan.name}.'})


# ── TenantUser ─────────────────────────────────────────────────────────────────

class TenantUserSerializer(serializers.ModelSerializer):
    username   = serializers.CharField(source='user.username', read_only=True)
    email      = serializers.CharField(source='user.email', read_only=True)
    full_name  = serializers.SerializerMethodField()
    tenant_name = serializers.CharField(source='tenant.name', read_only=True)

    class Meta:
        model  = TenantUser
        fields = [
            'id', 'tenant', 'tenant_name', 'user', 'username',
            'email', 'full_name', 'role', 'is_active', 'joined_at',
        ]
        read_only_fields = ['joined_at']

    def get_full_name(self, obj):
        return obj.user.get_full_name() or obj.user.username


class TenantUserViewSet(viewsets.ModelViewSet):
    serializer_class   = TenantUserSerializer
    permission_classes = [IsSuperAdminOrTenantAdmin]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'superadmin':
            return TenantUser.objects.select_related('user', 'tenant').all()
        # Tenant admin sees only their own tenant's members
        return TenantUser.objects.select_related('user', 'tenant').filter(
            tenant__memberships__user=user,
            tenant__memberships__role='tenant_admin',
        )


# ── TenantInvitation ──────────────────────────────────────────────────────────

class TenantInviteSerializer(serializers.ModelSerializer):
    class Meta:
        model  = TenantInvitation
        fields = '__all__'
        read_only_fields = ['token', 'status', 'accepted_at', 'created_at']


class TenantInviteViewSet(viewsets.ModelViewSet):
    serializer_class   = TenantInviteSerializer
    permission_classes = [IsSuperAdminOrTenantAdmin]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'superadmin':
            return TenantInvitation.objects.select_related('tenant').all()
        return TenantInvitation.objects.select_related('tenant').filter(
            tenant__memberships__user=user
        )

    def perform_create(self, serializer):
        token      = secrets.token_urlsafe(32)
        expires_at = timezone.now() + timedelta(days=7)
        serializer.save(
            invited_by=self.request.user,
            token=token,
            expires_at=expires_at,
        )


# ── AuditLog ──────────────────────────────────────────────────────────────────

class AuditLogSerializer(serializers.ModelSerializer):
    username    = serializers.CharField(source='user.username', read_only=True)
    tenant_name = serializers.CharField(source='tenant.name',  read_only=True)

    class Meta:
        model  = TenantAuditLog
        fields = '__all__'
        read_only_fields = ['created_at']


class AuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class   = AuditLogSerializer
    permission_classes = [IsSuperAdminOrTenantAdmin]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'superadmin':
            return TenantAuditLog.objects.select_related('user', 'tenant').all()
        return TenantAuditLog.objects.select_related('user', 'tenant').filter(
            tenant__memberships__user=user
        )
