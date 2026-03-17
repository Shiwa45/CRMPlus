# communications/admin.py
from django.contrib import admin
from .models import (
    EmailConfiguration, EmailTemplate, EmailCampaign, Email,
    EmailSequence, EmailSequenceStep, EmailSequenceEnrollment,
    EmailTracking,
)


@admin.register(EmailConfiguration)
class EmailConfigurationAdmin(admin.ModelAdmin):
    list_display = ['name', 'provider', 'from_email', 'is_default', 'is_active']
    list_filter = ['provider', 'is_active', 'is_default']
    search_fields = ['name', 'from_email']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(EmailTemplate)
class EmailTemplateAdmin(admin.ModelAdmin):
    list_display = ['name', 'user', 'template_type', 'is_shared', 'open_count', 'click_count']
    list_filter = ['template_type', 'is_shared']
    search_fields = ['name', 'subject', 'user__username']
    readonly_fields = ['open_count', 'click_count', 'created_at', 'updated_at']


@admin.register(EmailCampaign)
class EmailCampaignAdmin(admin.ModelAdmin):
    list_display = ['name', 'created_by', 'status', 'total_recipients', 'emails_sent', 'emails_failed', 'created_at']
    list_filter = ['status']
    search_fields = ['name']
    readonly_fields = ['total_recipients', 'emails_sent', 'emails_failed', 'started_at', 'completed_at', 'created_at', 'updated_at']


@admin.register(Email)
class EmailAdmin(admin.ModelAdmin):
    list_display = ['subject', 'to_email', 'status', 'sent_at']
    list_filter = ['status']
    search_fields = ['subject', 'to_email']
    readonly_fields = ['message_id', 'sent_at', 'created_at']


@admin.register(EmailSequence)
class EmailSequenceAdmin(admin.ModelAdmin):
    list_display = ['name', 'user', 'status', 'created_at']
    list_filter = ['status']
    search_fields = ['name', 'user__username']


@admin.register(EmailSequenceStep)
class EmailSequenceStepAdmin(admin.ModelAdmin):
    list_display = ['sequence', 'order', 'template', 'delay_days']
    search_fields = ['sequence__name', 'template__name']


@admin.register(EmailSequenceEnrollment)
class EmailSequenceEnrollmentAdmin(admin.ModelAdmin):
    list_display = ['lead_email', 'sequence', 'current_step', 'status', 'enrolled_at']
    list_filter = ['status']
    search_fields = ['lead_email', 'sequence__name']


@admin.register(EmailTracking)
class EmailTrackingAdmin(admin.ModelAdmin):
    list_display = ['email', 'event_type', 'ip_address', 'created_at']
    list_filter = ['event_type']
    search_fields = ['email__subject']
    readonly_fields = ['created_at']
