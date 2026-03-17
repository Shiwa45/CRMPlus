# workflows/models.py  ← FULL REPLACEMENT  (tenant FK removed — schema = isolation)
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()


class Workflow(models.Model):
    TRIGGER_CHOICES = [
        ('lead_created',       'Lead Created'),
        ('lead_status_changed','Lead Status Changed'),
        ('deal_stage_changed', 'Deal Stage Changed'),
        ('ticket_created',     'Ticket Created'),
        ('ticket_status_changed','Ticket Status Changed'),
        ('contact_created',    'Contact Created'),
        ('deal_won',           'Deal Won'),
        ('deal_lost',          'Deal Lost'),
        ('invoice_overdue',    'Invoice Overdue'),
        ('manual',             'Manual Trigger'),
        ('schedule',           'Scheduled'),
    ]

    name        = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    trigger     = models.CharField(max_length=50, choices=TRIGGER_CHOICES)
    is_active   = models.BooleanField(default=False)
    run_once    = models.BooleanField(default=False,
                                      help_text='Run only once per record')
    priority    = models.IntegerField(default=0)
    last_run    = models.DateTimeField(null=True, blank=True)
    run_count   = models.IntegerField(default=0)
    created_by  = models.ForeignKey(User, on_delete=models.SET_NULL,
                                    null=True, related_name='created_workflows')
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-is_active', 'priority', 'name']

    def __str__(self):
        return self.name


class WorkflowCondition(models.Model):
    OPERATOR_CHOICES = [
        ('equals', 'Equals'), ('not_equals', 'Not Equals'),
        ('contains', 'Contains'), ('not_contains', 'Not Contains'),
        ('greater_than', 'Greater Than'), ('less_than', 'Less Than'),
        ('is_empty', 'Is Empty'), ('is_not_empty', 'Is Not Empty'),
        ('in', 'In List'), ('not_in', 'Not In List'),
    ]

    workflow   = models.ForeignKey(Workflow, on_delete=models.CASCADE,
                                   related_name='conditions')
    field      = models.CharField(max_length=100)
    operator   = models.CharField(max_length=20, choices=OPERATOR_CHOICES)
    value      = models.CharField(max_length=500, blank=True)
    order      = models.IntegerField(default=0)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f'{self.workflow.name}: {self.field} {self.operator} {self.value}'


class WorkflowAction(models.Model):
    ACTION_TYPES = [
        ('send_email',       'Send Email'),
        ('send_whatsapp',    'Send WhatsApp'),
        ('create_task',      'Create Task'),
        ('create_notification', 'Create Notification'),
        ('update_field',     'Update Field'),
        ('assign_user',      'Assign to User'),
        ('add_tag',          'Add Tag'),
        ('remove_tag',       'Remove Tag'),
        ('webhook',          'Send Webhook'),
        ('wait',             'Wait / Delay'),
    ]

    workflow    = models.ForeignKey(Workflow, on_delete=models.CASCADE,
                                    related_name='actions')
    action_type = models.CharField(max_length=30, choices=ACTION_TYPES)
    config      = models.JSONField(default=dict,
                                   help_text='Action-specific configuration')
    order       = models.IntegerField(default=0)
    delay_minutes = models.IntegerField(default=0,
                                        help_text='Minutes to wait before this action')

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f'{self.workflow.name} → {self.action_type}'


class WorkflowExecution(models.Model):
    STATUS_CHOICES = [
        ('running', 'Running'), ('completed', 'Completed'),
        ('failed', 'Failed'), ('skipped', 'Skipped'),
    ]

    workflow    = models.ForeignKey(Workflow, on_delete=models.CASCADE,
                                    related_name='executions')
    status      = models.CharField(max_length=20, choices=STATUS_CHOICES, default='running')
    trigger_data = models.JSONField(default=dict)
    result      = models.JSONField(default=dict)
    error       = models.TextField(blank=True)
    started_at  = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-started_at']

    def __str__(self):
        return f'{self.workflow.name} — {self.status}'


class Notification(models.Model):
    TYPE_CHOICES = [
        ('info', 'Info'), ('success', 'Success'),
        ('warning', 'Warning'), ('error', 'Error'),
    ]

    user        = models.ForeignKey(User, on_delete=models.CASCADE,
                                    related_name='notifications')
    title       = models.CharField(max_length=200)
    body        = models.TextField(blank=True)
    type        = models.CharField(max_length=20, choices=TYPE_CHOICES, default='info')
    is_read     = models.BooleanField(default=False)
    read_at     = models.DateTimeField(null=True, blank=True)
    link        = models.CharField(max_length=500, blank=True)
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.title} → {self.user.username}'


class Task(models.Model):
    PRIORITY_CHOICES = [
        ('low', 'Low'), ('medium', 'Medium'), ('high', 'High'), ('urgent', 'Urgent'),
    ]
    STATUS_CHOICES = [
        ('todo', 'To Do'), ('in_progress', 'In Progress'),
        ('done', 'Done'), ('cancelled', 'Cancelled'),
    ]

    title       = models.CharField(max_length=300)
    description = models.TextField(blank=True)
    priority    = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default='medium')
    status      = models.CharField(max_length=20, choices=STATUS_CHOICES, default='todo')
    due_date    = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    assigned_to = models.ForeignKey(User, on_delete=models.SET_NULL,
                                    null=True, blank=True, related_name='assigned_tasks')
    created_by  = models.ForeignKey(User, on_delete=models.SET_NULL,
                                    null=True, related_name='created_tasks')

    # Polymorphic context (optional link to any record)
    related_model = models.CharField(max_length=50, blank=True)
    related_id    = models.IntegerField(null=True, blank=True)

    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['due_date', 'priority']

    def __str__(self):
        return self.title
