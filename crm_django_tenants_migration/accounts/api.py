# accounts/api.py  ← FULL REPLACEMENT
"""
User API — includes updated login that returns tenant context so the
Flutter app knows which schema_name / slug to use in subsequent requests.
"""
from rest_framework import viewsets, serializers, permissions
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.authtoken.models import Token
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework import status as http_status
from django.contrib.auth import get_user_model
from django.db import connection

from .models import UserProfile

User = get_user_model()


# ── Serializers ────────────────────────────────────────────────────────────────

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model  = UserProfile
        fields = '__all__'


class UserSerializer(serializers.ModelSerializer):
    profile          = UserProfileSerializer(read_only=True)
    role_display_name = serializers.CharField(source='get_role_display_name', read_only=True)

    class Meta:
        model  = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'phone', 'role', 'role_display_name', 'department',
            'is_active', 'date_joined', 'profile',
        ]
        read_only_fields = ['date_joined']


# ── ViewSets ───────────────────────────────────────────────────────────────────

class UserViewSet(viewsets.ModelViewSet):
    queryset           = User.objects.all()
    serializer_class   = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """
        Users scoped to the current schema.
        In the public schema this returns all users.
        In a tenant schema only users that belong to that tenant are visible.
        """
        qs = User.objects.all()
        # Optionally restrict to tenant members
        schema = connection.schema_name
        if schema != 'public':
            try:
                from tenants.models import TenantUser
                tenant_user_ids = TenantUser.objects.using('default').filter(
                    tenant__schema_name=schema
                ).values_list('user_id', flat=True)
                qs = qs.filter(id__in=tenant_user_ids)
            except Exception:
                pass
        return qs

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def me(self, request):
        """Return the currently authenticated user."""
        serializer = self.get_serializer(request.user)
        return Response(serializer.data)


# ── Custom Auth Token (Login) ─────────────────────────────────────────────────

class CustomAuthToken(ObtainAuthToken):
    """
    POST /api/auth/login/
    Body: { "username": "...", "password": "..." }
    Headers: X-Tenant-ID: <slug>  (optional — for tenant-scoped login)

    Returns token + user info + tenant info so the Flutter app can:
      1. Store the token
      2. Know which tenant slug to use in future X-Tenant-ID headers
    """

    def post(self, request, *args, **kwargs):
        serializer = self.serializer_class(
            data=request.data, context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        user  = serializer.validated_data['user']
        token, _ = Token.objects.get_or_create(user=user)

        # Build tenant context ─ look up which tenants this user belongs to
        tenant_info = self._get_tenant_info(user, request)

        return Response({
            'token':       token.key,
            'user_id':     user.pk,
            'username':    user.username,
            'email':       user.email,
            'first_name':  user.first_name,
            'last_name':   user.last_name,
            'role':        user.role,
            **tenant_info,
        })

    # ── helpers ────────────────────────────────────────────────────────

    def _get_tenant_info(self, user, request) -> dict:
        """
        Return tenant metadata so the Flutter app can store it.

        If the login request already came with a valid X-Tenant-ID header,
        confirm that tenant. Otherwise return the first active tenant the
        user belongs to.
        """
        try:
            from tenants.models import TenantUser, Tenant

            # Resolve membership queryset (runs on public schema)
            memberships = TenantUser.objects.select_related('tenant__plan').filter(
                user=user, is_active=True
            )

            # Prefer the tenant indicated by the header
            slug_header = (
                request.META.get('HTTP_X_TENANT_SLUG', '')
                or request.META.get('HTTP_X_TENANT_ID', '')
            ).strip()

            if slug_header and slug_header.lower() != 'public':
                try:
                    m = memberships.get(tenant__slug=slug_header)
                    return self._format_tenant(m)
                except TenantUser.DoesNotExist:
                    pass

            # Fall back to first membership
            m = memberships.first()
            if m:
                return self._format_tenant(m)

        except Exception:
            pass

        return {
            'schema_name': 'public',
            'tenant_id':   None,
            'tenant_name': None,
            'tenant_slug': None,
            'tenant_role': None,
            'plan_name':   None,
        }

    @staticmethod
    def _format_tenant(membership) -> dict:
        t = membership.tenant
        return {
            'schema_name': t.schema_name,
            'tenant_id':   t.pk,
            'tenant_name': t.name,
            'tenant_slug': t.slug,
            'tenant_role': membership.role,
            'plan_name':   t.plan.name if t.plan else None,
        }
