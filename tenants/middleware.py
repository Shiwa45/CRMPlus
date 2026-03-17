# tenants/middleware.py  ← FULL REPLACEMENT
"""
TenantFromHeaderMiddleware

Resolves the active tenant from the HTTP header  X-Tenant-ID  or  X-Tenant-Slug
(both are accepted; Flutter's ApiClient sends X-Tenant-ID).

When no header is present the request is routed to the PUBLIC schema so that
superadmin endpoints (tenant CRUD, plan management) keep working.

This middleware inherits from django_tenants TenantMainMiddleware so that
django-tenants' schema-switching machinery is used correctly.

Lookup order for the header value:
  1. slug            (e.g.  sharma_infotech)
  2. schema_name     (same, hyphens → underscores)
  3. UUID / integer pk (old UUIDs stored by Flutter before migration)
"""

import logging
from django.db import connection
from django_tenants.middleware.main import TenantMainMiddleware
from django_tenants.utils import get_public_schema_name, get_tenant_model

logger = logging.getLogger(__name__)


class TenantFromHeaderMiddleware(TenantMainMiddleware):
    """
    Reads tenant identifier from HTTP header instead of subdomain.

    Header priority:
        1. X-Tenant-Slug
        2. X-Tenant-ID   (sent by Flutter app — can be slug OR old UUID pk)
        3. Falls back to public schema
    """

    HEADER_NAMES = [
        'HTTP_X_TENANT_SLUG',  # X-Tenant-Slug
        'HTTP_X_TENANT_ID',    # X-Tenant-ID  ← Flutter sends this
    ]

    def get_tenant(self, model, hostname, request):
        """Return the Tenant instance that should handle this request."""
        slug = self._extract_slug(request)

        if slug and slug.lower() != get_public_schema_name():
            tenant = self._resolve_tenant(model, slug)
            if tenant:
                return tenant
            logger.warning(
                'TenantFromHeaderMiddleware: unknown tenant identifier=%r; '
                'falling back to public schema.', slug
            )

        # No header or unknown tenant → use public schema
        return model.objects.get(schema_name=get_public_schema_name())

    def _resolve_tenant(self, model, identifier: str):
        """
        Try multiple strategies to resolve a tenant from an identifier string.
        Returns a Tenant instance or None.
        """
        # 1. Try slug directly
        try:
            return model.objects.get(slug=identifier)
        except model.DoesNotExist:
            pass

        # 2. Try schema_name (hyphens → underscores)
        schema = identifier.replace('-', '_')
        try:
            return model.objects.get(schema_name=schema)
        except model.DoesNotExist:
            pass

        # 3. Try UUID pk (old Flutter app stores tenant UUID from before migration)
        try:
            import uuid
            uuid.UUID(identifier)           # validates it's a proper UUID
            return model.objects.get(pk=identifier)
        except (ValueError, model.DoesNotExist):
            pass

        # 4. Try integer pk
        try:
            pk_int = int(identifier)
            return model.objects.get(pk=pk_int)
        except (ValueError, model.DoesNotExist):
            pass

        return None

    def process_request(self, request):
        """
        Resolve tenant from headers instead of hostname and set schema.
        """
        # Always start in public schema to read tenant metadata
        connection.set_schema_to_public()

        tenant_model = get_tenant_model()
        tenant = self.get_tenant(tenant_model, hostname=None, request=request)

        request.tenant = tenant
        connection.set_tenant(request.tenant)
        self.setup_url_routing(
            request,
            force_public=tenant.schema_name == get_public_schema_name(),
        )

    # ── helpers ───────────────────────────────────────────────────────

    def _extract_slug(self, request) -> str:
        """Extract and clean the tenant slug from request headers."""
        for header in self.HEADER_NAMES:
            value = request.META.get(header, '').strip()
            if value:
                return value
        return ''
