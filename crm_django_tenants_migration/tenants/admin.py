# tenants/admin.py
"""
Django admin registration for the public-schema tenant models.
All of these are accessible at /admin/ when connected to the public schema.
"""
from django.contrib import admin
from django_tenants.admin import TenantAdminMixin

from .models import Plan, Tenant, Domain, TenantUser, TenantInvitation, TenantAuditLog


@admin.register(Plan)
class PlanAdmin(admin.ModelAdmin):
    list_display  = ['name', 'slug', 'price_monthly', 'price_yearly',
                     'max_users', 'has_whatsapp', 'has_ai', 'is_active', 'sort_order']
    list_filter   = ['is_active', 'has_whatsapp', 'has_ai']
    search_fields = ['name', 'slug']
    prepopulated_fields = {'slug': ('name',)}
    ordering      = ['sort_order']


class DomainInline(admin.TabularInline):
    model        = Domain
    extra        = 1
    fields       = ['domain', 'is_primary']


@admin.register(Tenant)
class TenantAdmin(TenantAdminMixin, admin.ModelAdmin):
    list_display  = ['name', 'slug', 'schema_name', 'plan', 'status',
                     'city', 'email', 'created_at']
    list_filter   = ['status', 'plan', 'billing']
    search_fields = ['name', 'slug', 'schema_name', 'email', 'gstin']
    readonly_fields = ['schema_name', 'created_at', 'updated_at']
    inlines       = [DomainInline]
    ordering      = ['name']

    fieldsets = [
        ('Identity',  {'fields': ['name', 'slug', 'schema_name', 'logo']}),
        ('Subscription', {'fields': ['plan', 'status', 'billing', 'trial_ends', 'plan_ends']}),
        ('Business', {'fields': ['gstin', 'pan']}),
        ('Contact',  {'fields': ['email', 'phone', 'address', 'city', 'state',
                                 'pincode', 'country']}),
        ('Settings', {'fields': ['timezone_name', 'currency', 'date_format']}),
        ('Metadata', {'fields': ['created_at', 'updated_at'], 'classes': ['collapse']}),
    ]


@admin.register(Domain)
class DomainAdmin(admin.ModelAdmin):
    list_display  = ['domain', 'tenant', 'is_primary']
    list_filter   = ['is_primary']
    search_fields = ['domain', 'tenant__name']


@admin.register(TenantUser)
class TenantUserAdmin(admin.ModelAdmin):
    list_display  = ['user', 'tenant', 'role', 'is_active', 'joined_at']
    list_filter   = ['role', 'is_active', 'tenant']
    search_fields = ['user__username', 'user__email', 'tenant__name']
    raw_id_fields = ['user', 'tenant']


@admin.register(TenantInvitation)
class TenantInvitationAdmin(admin.ModelAdmin):
    list_display  = ['email', 'tenant', 'role', 'status', 'expires_at', 'created_at']
    list_filter   = ['status', 'role', 'tenant']
    search_fields = ['email', 'tenant__name']
    readonly_fields = ['token', 'created_at']


@admin.register(TenantAuditLog)
class TenantAuditLogAdmin(admin.ModelAdmin):
    list_display  = ['tenant', 'user', 'action', 'resource', 'ip', 'created_at']
    list_filter   = ['tenant', 'action']
    search_fields = ['action', 'resource', 'user__username', 'tenant__name']
    readonly_fields = ['created_at']
    ordering      = ['-created_at']
