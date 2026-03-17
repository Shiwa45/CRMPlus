# tenants/middleware.py  ← FULL REPLACEMENT
"""
TenantFromHeaderMiddleware

Resolves the active tenant from the HTTP header  X-Tenant-ID  or  X-Tenant-Slug
(both are accepted; Flutter's ApiClient sends X-Tenant-ID).

When no header is present the request is routed to the PUBLIC schema so that
superadmin endpoints (tenant CRUD, plan management) keep working.

This middleware inherits from django_tenants BaseTenantMiddleware so that
django-tenants' schema-switching machinery is used correctly.
"""

import logging
from django.db import connection
from django_tenants.middleware.base import BaseTenantMiddleware
from django_tenants.utils import get_public_schema_name, get_tenant_model

logger = logging.getLogger(__name__)


class TenantFromHeaderMiddleware(BaseTenantMiddleware):
    """
    Reads tenant slug from HTTP header instead of subdomain.

    Header priority:
        1. X-Tenant-Slug
        2. X-Tenant-ID   (sent by Flutter app)
        3. Falls back to public schema

    The slug is matched against Tenant.slug  (e.g. 'sharma-infotech').
    """

    HEADER_NAMES = [
        'HTTP_X_TENANT_SLUG',  # X-Tenant-Slug
        'HTTP_X_TENANT_ID',    # X-Tenant-ID  ← Flutter sends this
    ]

    def get_tenant(self, model, hostname, request):
        """Return the Tenant instance that should handle this request."""
        slug = self._extract_slug(request)

        if slug and slug.lower() != get_public_schema_name():
            try:
                return model.objects.get(slug=slug)
            except model.DoesNotExist:
                # Try schema_name lookup (hyphens → underscores)
                schema = slug.replace('-', '_')
                try:
                    return model.objects.get(schema_name=schema)
                except model.DoesNotExist:
                    logger.warning(
                        'TenantFromHeaderMiddleware: unknown tenant slug=%r; '
                        'falling back to public schema.', slug
                    )

        # No header or unknown tenant → use public schema
        return model.objects.get(schema_name=get_public_schema_name())

    # ── helpers ───────────────────────────────────────────────────────

    def _extract_slug(self, request) -> str:
        """Extract and clean the tenant slug from request headers."""
        for header in self.HEADER_NAMES:
            value = request.META.get(header, '').strip()
            if value:
                return value
        return ''
