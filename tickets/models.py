# tickets/models.py
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from contacts.models import Contact, Company

User = get_user_model()


class TicketCategory(models.Model):
    name        = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    color       = models.CharField(max_length=7, default='#6366f1')
    is_active   = models.BooleanField(default=True)
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']
        verbose_name_plural = 'Ticket Categories'

    def __str__(self):
        return self.name


class SLAPolicy(models.Model):
    """Service Level Agreement policies"""
    PRIORITY_CHOICES = [
        ('critical', 'Critical'), ('high', 'High'), ('medium', 'Medium'), ('low', 'Low'),
    ]

    name                  = models.CharField(max_length=200)
    priority              = models.CharField(max_length=20, choices=PRIORITY_CHOICES)
    first_response_hours  = models.PositiveIntegerField(default=4, help_text='Hours for first response')
    resolution_hours      = models.PositiveIntegerField(default=24, help_text='Hours for resolution')
    business_hours_only   = models.BooleanField(default=True)
    escalate_after_hours  = models.PositiveIntegerField(default=8, help_text='Escalate if no response after hours')
    escalate_to           = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='escalation_targets')
    is_active             = models.BooleanField(default=True)
    created_at            = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['priority']
        verbose_name = 'SLA Policy'
        verbose_name_plural = 'SLA Policies'

    def __str__(self):
        return f"{self.name} ({self.priority}) - {self.first_response_hours}h response / {self.resolution_hours}h resolution"


class Ticket(models.Model):
    STATUS_CHOICES = [
        ('open', 'Open'),
        ('in_progress', 'In Progress'),
        ('waiting', 'Waiting on Customer'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed'),
        ('cancelled', 'Cancelled'),
    ]
    PRIORITY_CHOICES = [
        ('critical', 'Critical'),
        ('high', 'High'),
        ('medium', 'Medium'),
        ('low', 'Low'),
    ]
    CHANNEL_CHOICES = [
        ('email', 'Email'),
        ('phone', 'Phone'),
        ('whatsapp', 'WhatsApp'),
        ('web', 'Web Portal'),
        ('chat', 'Live Chat'),
        ('manual', 'Manual Entry'),
    ]

    # Identity
    ticket_number = models.CharField(max_length=20, unique=True, editable=False)

    # Content
    subject       = models.CharField(max_length=300)
    description   = models.TextField()
    status        = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')
    priority      = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default='medium')
    channel       = models.CharField(max_length=20, choices=CHANNEL_CHOICES, default='manual')

    # Relationships
    contact       = models.ForeignKey(Contact, on_delete=models.SET_NULL, null=True, blank=True, related_name='tickets')
    company       = models.ForeignKey(Company, on_delete=models.SET_NULL, null=True, blank=True, related_name='tickets')
    category      = models.ForeignKey(TicketCategory, on_delete=models.SET_NULL, null=True, blank=True, related_name='tickets')
    sla_policy    = models.ForeignKey(SLAPolicy, on_delete=models.SET_NULL, null=True, blank=True, related_name='tickets')
    assigned_to   = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_tickets')
    created_by    = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_tickets')

    # SLA tracking
    sla_due_date        = models.DateTimeField(blank=True, null=True)
    first_response_at   = models.DateTimeField(blank=True, null=True)
    first_response_due  = models.DateTimeField(blank=True, null=True)
    sla_breached        = models.BooleanField(default=False)
    resolution_due      = models.DateTimeField(blank=True, null=True)

    # Timestamps
    created_at    = models.DateTimeField(auto_now_add=True)
    updated_at    = models.DateTimeField(auto_now=True)
    resolved_at   = models.DateTimeField(blank=True, null=True)
    closed_at     = models.DateTimeField(blank=True, null=True)

    # CSAT
    csat_score    = models.PositiveIntegerField(blank=True, null=True, help_text='1-5 rating')
    csat_comment  = models.TextField(blank=True)
    csat_sent_at  = models.DateTimeField(blank=True, null=True)
    csat_received_at = models.DateTimeField(blank=True, null=True)

    tags          = models.JSONField(default=list, blank=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.ticket_number}] {self.subject}"

    def save(self, *args, **kwargs):
        if not self.ticket_number:
            self.ticket_number = self._generate_ticket_number()
        # Set SLA deadlines on first save
        if self.sla_policy and not self.first_response_due:
            from datetime import timedelta
            self.first_response_due = timezone.now() + timedelta(hours=self.sla_policy.first_response_hours)
            self.resolution_due     = timezone.now() + timedelta(hours=self.sla_policy.resolution_hours)
        # Set timestamps on status changes
        if self.pk:
            try:
                old = Ticket.objects.get(pk=self.pk)
                if old.status != 'resolved' and self.status == 'resolved':
                    self.resolved_at = timezone.now()
                if old.status != 'closed' and self.status == 'closed':
                    self.closed_at = timezone.now()
            except Ticket.DoesNotExist:
                pass
        super().save(*args, **kwargs)

    def _generate_ticket_number(self):
        import random
        return f"TKT-{timezone.now().strftime('%Y%m')}-{random.randint(10000, 99999)}"

    @property
    def is_overdue(self):
        if self.resolution_due and self.status not in ('resolved', 'closed', 'cancelled'):
            return timezone.now() > self.resolution_due
        return False

    @property
    def response_overdue(self):
        if self.first_response_due and not self.first_response_at:
            return timezone.now() > self.first_response_due
        return False

    @property
    def time_to_resolution(self):
        """Returns hours taken to resolve"""
        if self.resolved_at and self.created_at:
            delta = self.resolved_at - self.created_at
            return round(delta.total_seconds() / 3600, 1)
        return None


class TicketReply(models.Model):
    REPLY_TYPE_CHOICES = [
        ('reply', 'Reply'),
        ('note', 'Internal Note'),
        ('system', 'System Event'),
    ]

    ticket      = models.ForeignKey(Ticket, on_delete=models.CASCADE, related_name='replies')
    reply_type  = models.CharField(max_length=10, choices=REPLY_TYPE_CHOICES, default='reply')
    body        = models.TextField()
    is_public   = models.BooleanField(default=True, help_text='Visible to contact if False = internal note')
    author      = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='ticket_replies')
    attachments = models.JSONField(default=list, blank=True)  # List of file URLs
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"Reply on {self.ticket.ticket_number} by {self.author}"

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        # Mark first response time
        ticket = self.ticket
        if not ticket.first_response_at and self.reply_type == 'reply' and self.is_public:
            ticket.first_response_at = self.created_at
            ticket.save(update_fields=['first_response_at'])


class TicketAttachment(models.Model):
    ticket      = models.ForeignKey(Ticket, on_delete=models.CASCADE, related_name='attachments')
    file        = models.FileField(upload_to='ticket_attachments/')
    file_name   = models.CharField(max_length=255)
    file_size   = models.PositiveIntegerField(default=0)
    uploaded_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.file_name


class TicketActivity(models.Model):
    """Audit log for ticket changes"""
    ACTION_CHOICES = [
        ('created', 'Created'), ('status_changed', 'Status Changed'),
        ('assigned', 'Assigned'), ('priority_changed', 'Priority Changed'),
        ('replied', 'Replied'), ('note_added', 'Note Added'),
        ('sla_breached', 'SLA Breached'), ('resolved', 'Resolved'),
        ('reopened', 'Reopened'), ('csat_received', 'CSAT Received'),
    ]

    ticket      = models.ForeignKey(Ticket, on_delete=models.CASCADE, related_name='activities')
    action      = models.CharField(max_length=30, choices=ACTION_CHOICES)
    description = models.TextField()
    old_value   = models.CharField(max_length=255, blank=True)
    new_value   = models.CharField(max_length=255, blank=True)
    performed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
