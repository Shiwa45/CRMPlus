# tickets/admin.py
from django.contrib import admin
from .models import TicketCategory, SLAPolicy, Ticket, TicketReply, TicketAttachment, TicketActivity


@admin.register(TicketCategory)
class TicketCategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'color', 'is_active']
    search_fields = ['name']


@admin.register(SLAPolicy)
class SLAPolicyAdmin(admin.ModelAdmin):
    list_display = ['name', 'priority', 'first_response_hours', 'resolution_hours', 'is_active']
    list_filter  = ['priority', 'is_active', 'business_hours_only']


class TicketReplyInline(admin.TabularInline):
    model  = TicketReply
    extra  = 0
    fields = ['reply_type', 'body', 'is_public', 'author', 'created_at']
    readonly_fields = ['created_at']


class TicketActivityInline(admin.TabularInline):
    model   = TicketActivity
    extra   = 0
    readonly_fields = ['action', 'description', 'old_value', 'new_value', 'performed_by', 'created_at']
    can_delete = False


@admin.register(Ticket)
class TicketAdmin(admin.ModelAdmin):
    list_display  = ['ticket_number', 'subject', 'status', 'priority', 'channel',
                     'contact', 'assigned_to', 'sla_breached', 'csat_score', 'created_at']
    list_filter   = ['status', 'priority', 'channel', 'sla_breached', 'category']
    search_fields = ['ticket_number', 'subject', 'contact__first_name', 'company__name']
    readonly_fields = ['ticket_number', 'first_response_at', 'first_response_due',
                       'resolution_due', 'resolved_at', 'closed_at', 'created_at', 'updated_at']
    inlines = [TicketReplyInline, TicketActivityInline]


# tickets/apps.py
