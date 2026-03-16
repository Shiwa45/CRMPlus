# tenants/api.py
from rest_framework import viewsets, serializers, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from datetime import timedelta
from .models import Plan, Tenant, TenantUser, TenantInvitation, TenantAuditLog


# ── Serializers ───────────────────────────────────────────────────────────────
class PlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = Plan
        fields = '__all__'


class TenantSerializer(serializers.ModelSerializer):
    plan_name    = serializers.CharField(source='plan.display_name', read_only=True)
    plan_details = PlanSerializer(source='plan', read_only=True)
    user_count   = serializers.SerializerMethodField()

    class Meta:
        model = Tenant
        fields = '__all__'

    def get_user_count(self, obj):
        return obj.members.filter(is_active=True).count()


class TenantUserSerializer(serializers.ModelSerializer):
    user_name  = serializers.CharField(source='user.get_full_name', read_only=True)
    user_email = serializers.EmailField(source='user.email', read_only=True)

    class Meta:
        model = TenantUser
        fields = '__all__'


class TenantInviteSerializer(serializers.ModelSerializer):
    class Meta:
        model = TenantInvitation
        fields = ['id', 'email', 'role', 'token', 'accepted', 'expires_at', 'created_at']
        read_only_fields = ['token', 'accepted', 'created_at']


class AuditLogSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)

    class Meta:
        model = TenantAuditLog
        fields = '__all__'


# ── Permission helpers ────────────────────────────────────────────────────────
class IsSuperAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'superadmin'


class IsTenantAdminOrSuper(permissions.BasePermission):
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        if request.user.role == 'superadmin':
            return True
        tenant_id = request.headers.get('X-Tenant-ID') or request.query_params.get('tenant')
        if not tenant_id:
            return False
        return TenantUser.objects.filter(
            tenant_id=tenant_id, user=request.user,
            role__in=['tenant_admin', 'super_admin'], is_active=True
        ).exists()


# ── ViewSets ──────────────────────────────────────────────────────────────────
class PlanViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Plan.objects.filter(is_active=True)
    serializer_class = PlanSerializer
    permission_classes = [permissions.IsAuthenticated]


class TenantViewSet(viewsets.ModelViewSet):
    serializer_class = TenantSerializer

    def get_permissions(self):
        if self.action in ('list', 'create', 'destroy'):
            return [IsSuperAdmin()]
        return [IsTenantAdminOrSuper()]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'superadmin':
            return Tenant.objects.select_related('plan').all()
        return Tenant.objects.filter(members__user=user, members__is_active=True).distinct()

    @action(detail=True, methods=['post'], permission_classes=[IsSuperAdmin])
    def suspend(self, request, pk=None):
        t = self.get_object()
        t.status = 'suspended'; t.save()
        return Response({'status': 'suspended'})

    @action(detail=True, methods=['post'], permission_classes=[IsSuperAdmin])
    def activate(self, request, pk=None):
        t = self.get_object()
        t.status = 'active'; t.save()
        return Response({'status': 'active'})

    @action(detail=True, methods=['post'], permission_classes=[IsSuperAdmin])
    def change_plan(self, request, pk=None):
        t = self.get_object()
        plan_id = request.data.get('plan_id')
        try:
            t.plan = Plan.objects.get(id=plan_id)
            t.save()
            return Response(TenantSerializer(t).data)
        except Plan.DoesNotExist:
            return Response({'error': 'Plan not found'}, status=400)

    @action(detail=True, methods=['get'])
    def usage(self, request, pk=None):
        t = self.get_object()
        return Response({
            'users':     t.within_limit('emails'),   # reuse pattern
            'emails':    {'used': t.emails_sent, 'limit': t.plan.max_emails_pm},
            'whatsapp':  {'used': t.wa_sent,     'limit': t.plan.max_wa_pm},
            'ai':        {'used': t.ai_used,     'limit': t.plan.max_ai_pm},
            'user_count': t.members.filter(is_active=True).count(),
            'user_limit': t.plan.max_users,
        })

    @action(detail=True, methods=['get'])
    def features(self, request, pk=None):
        t = self.get_object()
        p = t.plan
        return Response({f: getattr(p, f'feat_{f}', False) for f in [
            'whatsapp','ai_scoring','ai_assistant','ai_calls','workflows',
            'quotes','invoices','tickets','analytics','api_access',
            'custom_domain','sso','audit_log'
        ]})


class TenantUserViewSet(viewsets.ModelViewSet):
    serializer_class = TenantUserSerializer
    permission_classes = [IsTenantAdminOrSuper]

    def get_queryset(self):
        tenant_id = self.request.headers.get('X-Tenant-ID') or self.request.query_params.get('tenant')
        if not tenant_id:
            return TenantUser.objects.none()
        return TenantUser.objects.filter(tenant_id=tenant_id).select_related('user')

    def perform_create(self, serializer):
        tenant_id = self.request.headers.get('X-Tenant-ID')
        tenant = Tenant.objects.get(id=tenant_id)
        # Check user limit
        current = tenant.members.filter(is_active=True).count()
        if tenant.plan.max_users != -1 and current >= tenant.plan.max_users:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied(f"User limit ({tenant.plan.max_users}) reached for your plan.")
        serializer.save(tenant=tenant)

    @action(detail=True, methods=['post'])
    def deactivate(self, request, pk=None):
        tu = self.get_object()
        tu.is_active = False; tu.save()
        return Response({'status': 'deactivated'})

    @action(detail=True, methods=['post'])
    def change_role(self, request, pk=None):
        tu = self.get_object()
        role = request.data.get('role')
        if role not in dict(TenantUser._meta.get_field('role').choices):
            return Response({'error': 'Invalid role'}, status=400)
        tu.role = role; tu.save()
        return Response(TenantUserSerializer(tu).data)


class TenantInviteViewSet(viewsets.ModelViewSet):
    serializer_class = TenantInviteSerializer
    permission_classes = [IsTenantAdminOrSuper]

    def get_queryset(self):
        tenant_id = self.request.headers.get('X-Tenant-ID') or self.request.query_params.get('tenant')
        return TenantInvitation.objects.filter(tenant_id=tenant_id)

    def perform_create(self, serializer):
        tenant_id = self.request.headers.get('X-Tenant-ID')
        serializer.save(
            tenant_id=tenant_id,
            invited_by=self.request.user,
            expires_at=timezone.now() + timedelta(days=7)
        )


class AuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = AuditLogSerializer
    permission_classes = [IsTenantAdminOrSuper]

    def get_queryset(self):
        tenant_id = self.request.headers.get('X-Tenant-ID') or self.request.query_params.get('tenant')
        return TenantAuditLog.objects.filter(tenant_id=tenant_id)
