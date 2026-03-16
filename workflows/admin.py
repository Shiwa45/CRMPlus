# workflows/admin.py
from django.contrib import admin
from .models import Workflow, WorkflowCondition, WorkflowAction, WorkflowExecution, Notification, Task


class WorkflowConditionInline(admin.TabularInline):
    model  = WorkflowCondition
    extra  = 1
    fields = ['field', 'operator', 'value', 'logic', 'order']


class WorkflowActionInline(admin.TabularInline):
    model  = WorkflowAction
    extra  = 1
    fields = ['action_type', 'config', 'order', 'delay_minutes']


@admin.register(Workflow)
class WorkflowAdmin(admin.ModelAdmin):
    list_display = ['name', 'trigger', 'is_active', 'run_count', 'last_run_at', 'created_at']
    list_filter  = ['trigger', 'is_active']
    search_fields = ['name', 'description']
    readonly_fields = ['run_count', 'last_run_at', 'created_at', 'updated_at']
    inlines = [WorkflowConditionInline, WorkflowActionInline]


@admin.register(WorkflowExecution)
class WorkflowExecutionAdmin(admin.ModelAdmin):
    list_display = ['workflow', 'status', 'object_type', 'object_id', 'triggered_by', 'started_at']
    list_filter  = ['status', 'object_type']
    readonly_fields = ['workflow', 'status', 'triggered_by', 'object_type', 'object_id',
                       'actions_executed', 'error_message', 'started_at', 'completed_at']


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['user', 'notif_type', 'title', 'is_read', 'created_at']
    list_filter  = ['notif_type', 'is_read']
    search_fields = ['user__username', 'title']


@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ['title', 'task_type', 'status', 'priority', 'assigned_to', 'due_date', 'is_overdue']
    list_filter  = ['status', 'priority', 'task_type']
    search_fields = ['title', 'description', 'assigned_to__username']
    readonly_fields = ['created_at', 'updated_at']
