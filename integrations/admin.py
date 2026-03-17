# integrations/admin.py
from django.contrib import admin
from .models import Integration, WhatsAppTemplate


@admin.register(Integration)
class IntegrationAdmin(admin.ModelAdmin):
    list_display  = ['service', 'display_name', 'status', 'is_active', 'last_sync', 'created_at']
    list_filter   = ['service', 'status', 'is_active']
    search_fields = ['display_name']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(WhatsAppTemplate)
class WATemplateAdmin(admin.ModelAdmin):
    list_display  = ['name', 'category', 'created_at']
    list_filter   = ['category']
    search_fields = ['name', 'body']
