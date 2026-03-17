# tickets/models.py  ← FULL REPLACEMENT  (tenant FK removed — schema = isolation)
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()


class TicketCategory(models.Model):
    name        = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    color       = models.CharField(max_length=20, default='#6366f1')
    is_active   = models.BooleanField(default=True)
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']
        verbose_name_plural = 'Ticket Categories'

    def __str__(self):
        return self.name


class SLAPolicy(models.Model):
    PRIORITY_CHOICES = [
        ('critical', 'Critical'), ('high', 'High'),
        ('medium', 'Medium'), ('low', 'Low'),
    ]

    name                  = models.CharField(max_length=100)
    priority              = models.CharField(max_length=20, choices=PRIORITY_CHOICES,
                                             default='medium')
    first_response_hours  = models.IntegerField(default=8,
                                                help_text='Hours to first response')
    every_response_hours  = models.IntegerField(default=24,
                                                help_text='Hours between responses')
    resolution_hours      = models.IntegerField(default=72,
                                                help_text='Hours to resolution')
    is_active             = models.BooleanField(default=True)
    created_by            = models.ForeignKey(User, on_delete=models.SET_NULL,
                                              null=True, related_name='created_slas')
    created_at            = models.DateTimeField(auto_now_add=True)
    updated_at            = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']
        verbose_name = 'SLA Policy'
        verbose_name_plural = 'SLA Policies'

    def __str__(self):
        return f'{self.name} ({self.priority})'


class Ticket(models.Model):
    STATUS_CHOICES = [
        ('open', 'Open'), ('in_progress', 'In Progress'),
        ('waiting', 'Waiting on Customer'), ('resolved', 'Resolved'),
        ('closed', 'Closed'),
    ]
    PRIORITY_CHOICES = [
        ('low', 'Low'), ('medium', 'Medium'),
        ('high', 'High'), ('urgent', 'Urgent'), ('critical', 'Critical'),
    ]
    SOURCE_CHOICES = [
        ('email', 'Email'), ('phone', 'Phone'), ('chat', 'Chat'),
        ('portal', 'Portal'), ('whatsapp', 'WhatsApp'), ('manual', 'Manual'),
    ]

    # Core
    subject         = models.CharField(max_length=300)
    description     = models.TextField()
    status          = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')
    priority        = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default='medium')
    source          = models.CharField(max_length=20, choices=SOURCE_CHOICES, default='manual')

    # Relations
    category        = models.ForeignKey(TicketCategory, on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='tickets')
    sla_policy      = models.ForeignKey(SLAPolicy, on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='tickets')
    contact         = models.ForeignKey('contacts.Contact', on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='tickets')
    company         = models.ForeignKey('contacts.Company', on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='tickets')
    deal            = models.ForeignKey('deals.Deal', on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='tickets')

    # Ownership & assignment
    assigned_to     = models.ForeignKey(User, on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='assigned_tickets')
    created_by      = models.ForeignKey(User, on_delete=models.SET_NULL,
                                        null=True, related_name='created_tickets')

    # SLA tracking
    first_response_at = models.DateTimeField(null=True, blank=True)
    resolved_at       = models.DateTimeField(null=True, blank=True)
    closed_at         = models.DateTimeField(null=True, blank=True)
    sla_breached      = models.BooleanField(default=False)

    tags            = models.JSONField(default=list, blank=True)
    created_at      = models.DateTimeField(auto_now_add=True)
    updated_at      = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'#{self.pk} — {self.subject}'

    @property
    def is_overdue(self):
        if not self.sla_policy or self.status in ('resolved', 'closed'):
            return False
        deadline = self.created_at + timezone.timedelta(hours=self.sla_policy.resolution_hours)
        return timezone.now() > deadline


class TicketReply(models.Model):
    REPLY_TYPES = [
        ('reply', 'Reply'), ('note', 'Internal Note'), ('system', 'System Event'),
    ]

    ticket      = models.ForeignKey(Ticket, on_delete=models.CASCADE,
                                    related_name='replies')
    reply_type  = models.CharField(max_length=20, choices=REPLY_TYPES, default='reply')
    body        = models.TextField()
    is_public   = models.BooleanField(default=True)
    author      = models.ForeignKey(User, on_delete=models.SET_NULL,
                                    null=True, related_name='ticket_replies')
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f'{self.reply_type} on {self.ticket}'


class TicketActivity(models.Model):
    ticket     = models.ForeignKey(Ticket, on_delete=models.CASCADE,
                                   related_name='activities')
    action     = models.CharField(max_length=200)
    old_value  = models.CharField(max_length=200, blank=True)
    new_value  = models.CharField(max_length=200, blank=True)
    performed_by = models.ForeignKey(User, on_delete=models.SET_NULL,
                                     null=True, related_name='ticket_activities')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
