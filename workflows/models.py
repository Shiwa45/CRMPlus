# workflows/models.py
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()


class Workflow(models.Model):
    """Visual automation workflow (If/Then logic)"""
    TRIGGER_CHOICES = [
        # Lead triggers
        ('lead_created', 'Lead Created'),
        ('lead_status_changed', 'Lead Status Changed'),
        ('lead_assigned', 'Lead Assigned'),
        ('lead_priority_changed', 'Lead Priority Changed'),
        # Deal triggers
        ('deal_created', 'Deal Created'),
        ('deal_stage_changed', 'Deal Stage Changed'),
        ('deal_won', 'Deal Won'),
        ('deal_lost', 'Deal Lost'),
        ('deal_close_date_reached', 'Deal Close Date Reached'),
        # Contact triggers
        ('contact_created', 'Contact Created'),
        # Ticket triggers
        ('ticket_created', 'Ticket Created'),
        ('ticket_status_changed', 'Ticket Status Changed'),
        ('ticket_sla_breached', 'Ticket SLA Breached'),
        ('ticket_resolved', 'Ticket Resolved'),
        # Time-based
        ('scheduled', 'Scheduled (Time-based)'),
    ]

    name          = models.CharField(max_length=200)
    description   = models.TextField(blank=True)
    trigger       = models.CharField(max_length=50, choices=TRIGGER_CHOICES)
    trigger_config = models.JSONField(default=dict, blank=True,
                                      help_text='Filter conditions for trigger e.g. {status: "won"}')
    is_active     = models.BooleanField(default=True)
    run_once_per_object = models.BooleanField(default=True, help_text='Prevent duplicate runs')
    created_by    = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_workflows')
    created_at    = models.DateTimeField(auto_now_add=True)
    updated_at    = models.DateTimeField(auto_now=True)
    last_run_at   = models.DateTimeField(blank=True, null=True)
    run_count     = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.trigger})"


class WorkflowCondition(models.Model):
    """Conditions that must be met for the workflow actions to execute"""
    OPERATOR_CHOICES = [
        ('equals', 'Equals'), ('not_equals', 'Not Equals'),
        ('contains', 'Contains'), ('not_contains', 'Not Contains'),
        ('greater_than', 'Greater Than'), ('less_than', 'Less Than'),
        ('is_empty', 'Is Empty'), ('is_not_empty', 'Is Not Empty'),
        ('in', 'In List'), ('not_in', 'Not In List'),
    ]
    LOGIC_CHOICES = [('and', 'AND'), ('or', 'OR')]

    workflow    = models.ForeignKey(Workflow, on_delete=models.CASCADE, related_name='conditions')
    field       = models.CharField(max_length=100, help_text='e.g. lead.priority, deal.value')
    operator    = models.CharField(max_length=20, choices=OPERATOR_CHOICES)
    value       = models.CharField(max_length=500)
    logic       = models.CharField(max_length=5, choices=LOGIC_CHOICES, default='and')
    order       = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f"{self.field} {self.operator} {self.value}"


class WorkflowAction(models.Model):
    """Actions executed when workflow fires"""
    ACTION_CHOICES = [
        # Assignments
        ('assign_owner', 'Assign Owner'),
        ('assign_round_robin', 'Assign Round Robin'),
        # Status changes
        ('update_lead_status', 'Update Lead Status'),
        ('update_deal_stage', 'Update Deal Stage'),
        ('update_ticket_status', 'Update Ticket Status'),
        # Notifications
        ('send_email_notification', 'Send Email Notification'),
        ('send_whatsapp', 'Send WhatsApp Message'),
        ('create_notification', 'Create In-App Notification'),
        # Tasks
        ('create_task', 'Create Task/Activity'),
        ('create_ticket', 'Create Support Ticket'),
        # Tags
        ('add_tag', 'Add Tag'),
        ('remove_tag', 'Remove Tag'),
        # Data
        ('update_field', 'Update Field Value'),
        ('add_note', 'Add Note'),
        # Email
        ('send_email_template', 'Send Email from Template'),
        # Delay
        ('wait', 'Wait (Delay)'),
        # Webhook
        ('webhook', 'Call Webhook'),
    ]

    workflow    = models.ForeignKey(Workflow, on_delete=models.CASCADE, related_name='actions')
    action_type = models.CharField(max_length=50, choices=ACTION_CHOICES)
    config      = models.JSONField(default=dict, help_text='Action-specific config e.g. {user_id: 5, template_id: 3}')
    order       = models.PositiveIntegerField(default=0)
    delay_minutes = models.PositiveIntegerField(default=0, help_text='Delay before executing (0 = immediate)')

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f"{self.get_action_type_display()} (step {self.order})"


class WorkflowExecution(models.Model):
    """Audit log of every workflow run"""
    STATUS_CHOICES = [
        ('pending', 'Pending'), ('running', 'Running'),
        ('completed', 'Completed'), ('failed', 'Failed'), ('skipped', 'Skipped'),
    ]

    workflow        = models.ForeignKey(Workflow, on_delete=models.CASCADE, related_name='executions')
    status          = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    triggered_by    = models.CharField(max_length=100, help_text='Event that triggered the workflow')
    object_type     = models.CharField(max_length=50, help_text='e.g. lead, deal, ticket')
    object_id       = models.PositiveIntegerField()
    actions_executed = models.JSONField(default=list)
    error_message   = models.TextField(blank=True)
    started_at      = models.DateTimeField(default=timezone.now)
    completed_at    = models.DateTimeField(blank=True, null=True)

    class Meta:
        ordering = ['-started_at']

    def __str__(self):
        return f"{self.workflow.name} - {self.status} ({self.started_at.strftime('%Y-%m-%d %H:%M')})"


class Notification(models.Model):
    """In-app notifications for users"""
    TYPE_CHOICES = [
        ('lead_assigned', 'Lead Assigned'),
        ('deal_stage_changed', 'Deal Stage Changed'),
        ('ticket_assigned', 'Ticket Assigned'),
        ('ticket_sla_breach', 'Ticket SLA Breach'),
        ('deal_close_approaching', 'Deal Close Approaching'),
        ('workflow_alert', 'Workflow Alert'),
        ('payment_received', 'Payment Received'),
        ('quote_accepted', 'Quote Accepted'),
        ('mention', 'Mentioned'),
        ('system', 'System'),
    ]

    user        = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    notif_type  = models.CharField(max_length=40, choices=TYPE_CHOICES)
    title       = models.CharField(max_length=255)
    body        = models.TextField()
    link        = models.CharField(max_length=500, blank=True, help_text='Deep link in app')
    is_read     = models.BooleanField(default=False)
    object_type = models.CharField(max_length=50, blank=True)
    object_id   = models.PositiveIntegerField(blank=True, null=True)
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.notif_type}] {self.title} → {self.user.username}"


class Task(models.Model):
    """CRM Tasks - assignable to leads, deals, contacts, tickets"""
    STATUS_CHOICES = [
        ('todo', 'To Do'), ('in_progress', 'In Progress'),
        ('done', 'Done'), ('cancelled', 'Cancelled'),
    ]
    PRIORITY_CHOICES = [
        ('high', 'High'), ('medium', 'Medium'), ('low', 'Low'),
    ]
    TYPE_CHOICES = [
        ('call', 'Call'), ('email', 'Email'), ('meeting', 'Meeting'),
        ('follow_up', 'Follow Up'), ('demo', 'Demo'), ('other', 'Other'),
    ]

    title         = models.CharField(max_length=300)
    description   = models.TextField(blank=True)
    task_type     = models.CharField(max_length=20, choices=TYPE_CHOICES, default='follow_up')
    status        = models.CharField(max_length=20, choices=STATUS_CHOICES, default='todo')
    priority      = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')
    due_date      = models.DateTimeField(blank=True, null=True)
    completed_at  = models.DateTimeField(blank=True, null=True)

    # Polymorphic-lite: link to any object
    lead_id       = models.PositiveIntegerField(blank=True, null=True)
    deal_id       = models.PositiveIntegerField(blank=True, null=True)
    contact_id    = models.PositiveIntegerField(blank=True, null=True)
    ticket_id     = models.PositiveIntegerField(blank=True, null=True)

    assigned_to   = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_tasks')
    created_by    = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_tasks')
    created_at    = models.DateTimeField(auto_now_add=True)
    updated_at    = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['due_date', '-created_at']

    def __str__(self):
        return self.title

    @property
    def is_overdue(self):
        return bool(self.due_date and self.status not in ('done', 'cancelled')
                    and timezone.now() > self.due_date)
