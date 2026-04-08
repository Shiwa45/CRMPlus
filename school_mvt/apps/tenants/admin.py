from django.contrib import admin
from .models import School, Domain, SubscriptionPlan

@admin.register(School)
class SchoolAdmin(admin.ModelAdmin):
    list_display = ['name', 'schema_name', 'subscription_plan', 'is_active', 'is_trial', 'created_at']
    list_filter = ['subscription_plan', 'is_active', 'is_trial', 'board']
    search_fields = ['name', 'school_code', 'email']
    readonly_fields = ['schema_name', 'created_at']

@admin.register(Domain)
class DomainAdmin(admin.ModelAdmin):
    list_display = ['domain', 'tenant', 'is_primary']

@admin.register(SubscriptionPlan)
class SubscriptionPlanAdmin(admin.ModelAdmin):
    list_display = ['name', 'code', 'price_monthly', 'max_students', 'is_active']
