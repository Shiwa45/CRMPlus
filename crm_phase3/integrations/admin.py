# integrations/admin.py
from django.contrib import admin
from .models import Integration, WhatsAppTemplate, WhatsAppLog

@admin.register(Integration)
class IntegrationAdmin(admin.ModelAdmin):
    list_display  = ['tenant', 'service', 'is_enabled', 'test_ok', 'last_tested']
    list_filter   = ['service', 'is_enabled']
    search_fields = ['tenant__name']

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
