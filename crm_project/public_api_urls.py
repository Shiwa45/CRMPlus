# crm_project/public_api_urls.py  ← NEW FILE
"""
API routes for the PUBLIC schema.

Accessible when no X-Tenant-ID header is sent (or X-Tenant-ID: public).
Only superadmin operations live here.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter

from accounts.api import UserViewSet, CustomAuthToken
from tenants.api import (
    PlanViewSet, TenantViewSet, TenantUserViewSet,
    TenantInviteViewSet, AuditLogViewSet, TenantMeView,
)

router = DefaultRouter()
router.register(r'users',          UserViewSet,        basename='user')
router.register(r'plans',          PlanViewSet,         basename='plan')
router.register(r'tenants',        TenantViewSet,       basename='tenant')
router.register(r'tenant-users',   TenantUserViewSet,   basename='tenantuser')
router.register(r'tenant-invites', TenantInviteViewSet, basename='tenantinvite')
router.register(r'audit-logs',     AuditLogViewSet,     basename='auditlog')

urlpatterns = [
    # Login is available on the public schema so the Flutter app can
    # authenticate before knowing the tenant slug.
    path('auth/login/', CustomAuthToken.as_view(), name='api-token-auth'),
    path('tenant/me/', TenantMeView.as_view(), name='tenant-me'),
    path('', include(router.urls)),
]
