from django.db import models
from django.conf import settings


class TicketCategory(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    assigned_team = models.CharField(max_length=100, blank=True)
    sla_hours = models.PositiveSmallIntegerField(default=24, help_text='SLA in hours')

    def __str__(self): return self.name
    class Meta: db_table = 'ticket_category'; app_label = 'helpdesk'; verbose_name_plural = 'Ticket Categories'


class Ticket(models.Model):
    PRIORITY_CHOICES = [
        ('low', 'Low'), ('medium', 'Medium'),
        ('high', 'High'), ('critical', 'Critical'),
    ]
    STATUS_CHOICES = [
        ('open', 'Open'), ('in_progress', 'In Progress'),
        ('waiting', 'Waiting for Info'), ('resolved', 'Resolved'), ('closed', 'Closed'),
    ]
    ticket_number = models.CharField(max_length=20, unique=True)
    title = models.CharField(max_length=200)
    description = models.TextField()
    category = models.ForeignKey(
        TicketCategory, on_delete=models.SET_NULL, null=True, blank=True
    )
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='open')
    raised_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='tickets_raised'
    )
    assigned_to = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='tickets_assigned'
    )
    attachment = models.FileField(upload_to='tickets/', null=True, blank=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    resolution_note = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self): return f"#{self.ticket_number} — {self.title}"
    class Meta: db_table = 'helpdesk_ticket'; app_label = 'helpdesk'; ordering = ['-created_at']


class TicketReply(models.Model):
    ticket = models.ForeignKey(Ticket, on_delete=models.CASCADE, related_name='replies')
    replied_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    message = models.TextField()
    is_internal = models.BooleanField(default=False, help_text='Internal note — not visible to requester')
    attachment = models.FileField(upload_to='ticket_replies/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self): return f"Reply to #{self.ticket.ticket_number}"
    class Meta: db_table = 'ticket_reply'; app_label = 'helpdesk'; ordering = ['created_at']
