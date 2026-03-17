# crm_project/tenant_urls.py  — TENANT SCHEMA URL CONF
"""
These URLs are served for every TENANT schema request
(when X-Tenant-ID header is present and resolves to a real tenant).

All CRM business logic lives here.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('crm_project.tenant_api_urls')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
