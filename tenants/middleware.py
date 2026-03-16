# tenants/middleware.py
"""
Attaches the current Tenant to every request.
Reads X-Tenant-ID header (UUID) sent by the Flutter app.
SuperAdmin requests without a tenant header get request.tenant = None.
"""
from django.http import JsonResponse
from .models import Tenant, TenantUser


class TenantMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        tenant_id = request.headers.get('X-Tenant-ID')
        request.tenant = None
        request.tenant_user = None

        if tenant_id and request.user.is_authenticated:
            try:
                t = Tenant.objects.select_related('plan').get(id=tenant_id, is_active=True)
                request.tenant = t
                try:
                    request.tenant_user = TenantUser.objects.get(
                        tenant=t, user=request.user, is_active=True
                    )
                except TenantUser.DoesNotExist:
                    # superadmin may not have a TenantUser row
                    if request.user.role != 'superadmin':
                        return JsonResponse({'error': 'Not a member of this tenant'}, status=403)
            except Tenant.DoesNotExist:
                return JsonResponse({'error': 'Tenant not found'}, status=404)

        return self.get_response(request)
