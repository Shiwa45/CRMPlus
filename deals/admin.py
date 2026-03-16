# deals/admin.py
from django.contrib import admin
from .models import Pipeline, PipelineStage, Deal, DealActivity, DealStageHistory


class PipelineStageInline(admin.TabularInline):
    model  = PipelineStage
    extra  = 3
    fields = ['name', 'order', 'probability', 'color', 'is_won', 'is_lost']


@admin.register(Pipeline)
class PipelineAdmin(admin.ModelAdmin):
    list_display = ['name', 'is_default', 'is_active', 'created_at']
    inlines      = [PipelineStageInline]


@admin.register(Deal)
class DealAdmin(admin.ModelAdmin):
    list_display  = ['title', 'pipeline', 'stage', 'value', 'currency', 'priority', 'owner', 'close_date', 'created_at']
    list_filter   = ['pipeline', 'stage', 'priority', 'currency']
    search_fields = ['title', 'contact__first_name', 'company__name']
    readonly_fields = ['weighted_value', 'won_at', 'lost_at', 'created_at', 'updated_at']


@admin.register(DealActivity)
class DealActivityAdmin(admin.ModelAdmin):
    list_display = ['deal', 'activity_type', 'subject', 'status', 'performed_at']
    list_filter  = ['activity_type', 'status']


# deals/apps.py
