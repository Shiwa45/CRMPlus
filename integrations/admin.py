# integrations/admin.py
from django.contrib import admin
from .models import Integration, WhatsAppTemplate, WhatsAppLog

@admin.register(Integration)
class IntegrationAdmin(admin.ModelAdmin):
    list_display  = ['tenant', 'service', 'is_enabled', 'test_ok', 'last_tested', 'updated_at']
    list_filter   = ['service', 'is_enabled', 'test_ok']
    search_fields = ['tenant__name', 'tenant__slug']
    readonly_fields = ['created_by', 'created_at', 'updated_at', 'last_tested', 'test_ok']
    fields = [
        'tenant', 'service', 'is_enabled',
        'api_key', 'api_secret', 'extra',
        'test_ok', 'last_tested',
        'created_by', 'created_at', 'updated_at',
    ]

    def save_model(self, request, obj, form, change):
        if not obj.created_by:
            obj.created_by = request.user
        super().save_model(request, obj, form, change)

@admin.register(WhatsAppTemplate)
class WATemplateAdmin(admin.ModelAdmin):
    list_display  = ['tenant', 'name', 'category', 'status', 'use_count']
    list_filter   = ['status', 'category']
    search_fields = ['name', 'body']

@admin.register(WhatsAppLog)
class WALogAdmin(admin.ModelAdmin):
    list_display  = ['tenant', 'to_name', 'to_phone', 'status', 'created_at']
    list_filter   = ['status']
    readonly_fields = ['created_at']
