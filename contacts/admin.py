# contacts/admin.py
from django.contrib import admin
from .models import Company, Contact, ContactDocument, ContactActivity


@admin.register(Company)
class CompanyAdmin(admin.ModelAdmin):
    list_display  = ['name', 'industry', 'employee_size', 'city', 'state', 'gstin', 'created_at']
    list_filter   = ['industry', 'employee_size', 'state', 'country']
    search_fields = ['name', 'email', 'phone', 'gstin', 'pan']
    readonly_fields = ['created_at', 'updated_at']


class ContactDocumentInline(admin.TabularInline):
    model  = ContactDocument
    extra  = 0
    fields = ['name', 'file', 'file_type', 'uploaded_by', 'created_at']
    readonly_fields = ['created_at']


@admin.register(Contact)
class ContactAdmin(admin.ModelAdmin):
    list_display  = ['__str__', 'email', 'phone', 'company', 'job_title', 'owner', 'is_active', 'do_not_contact']
    list_filter   = ['is_active', 'do_not_contact', 'state', 'country']
    search_fields = ['first_name', 'last_name', 'email', 'phone', 'company__name']
    readonly_fields = ['created_at', 'updated_at', 'last_contacted']
    inlines       = [ContactDocumentInline]
    raw_id_fields = ['company', 'owner', 'created_by']


@admin.register(ContactActivity)
class ContactActivityAdmin(admin.ModelAdmin):
    list_display  = ['contact', 'activity_type', 'subject', 'performed_by', 'completed_at']
    list_filter   = ['activity_type', 'completed_at']
    search_fields = ['contact__first_name', 'subject']
