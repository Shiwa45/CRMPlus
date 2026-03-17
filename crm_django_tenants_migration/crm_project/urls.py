# crm_project/urls.py  — PUBLIC SCHEMA URL CONF
"""
These URLs are only served when the request hits the PUBLIC schema
(i.e. no X-Tenant-ID header, or X-Tenant-ID: public).

Used by:
  • Superadmin — create/manage tenants and plans
  • Platform-level auth (initial login to discover which tenant a user belongs to)
  • Django admin for the public schema
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('crm_project.public_api_urls')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
