# tenants/admin.py
from django.contrib import admin
from .models import Plan, Tenant, TenantUser, TenantInvitation, TenantAuditLog

@admin.register(Plan)
class PlanAdmin(admin.ModelAdmin):
    list_display = ['display_name', 'monthly_price', 'max_users', 'is_active', 'sort_order']
    list_editable = ['monthly_price', 'is_active', 'sort_order']

@admin.register(Tenant)
class TenantAdmin(admin.ModelAdmin):
    list_display = ['name', 'slug', 'plan', 'status', 'created_at']
    list_filter  = ['status', 'plan']
    search_fields = ['name', 'slug', 'email', 'gstin']
    raw_id_fields = ['plan']

@admin.register(TenantUser)
class TenantUserAdmin(admin.ModelAdmin):
    list_display = ['user', 'tenant', 'role', 'is_active', 'joined_at']
    list_filter  = ['role', 'is_active']

@admin.register(TenantAuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ['tenant', 'user', 'action', 'resource', 'created_at']
    list_filter  = ['action']
    readonly_fields = ['tenant','user','action','resource','resource_id','details','ip','created_at']
