from django.db import models
from django.conf import settings


class Notification(models.Model):
    TYPE_CHOICES = [
        ('info', 'Info'), ('success', 'Success'),
        ('warning', 'Warning'), ('danger', 'Danger'),
    ]
    CHANNEL_CHOICES = [
        ('app', 'In-App'), ('email', 'Email'),
        ('sms', 'SMS'), ('push', 'Push'), ('whatsapp', 'WhatsApp'),
    ]
    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications'
    )
    title = models.CharField(max_length=200)
    message = models.TextField()
    notification_type = models.CharField(max_length=10, choices=TYPE_CHOICES, default='info')
    channel = models.CharField(max_length=10, choices=CHANNEL_CHOICES, default='app')
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(null=True, blank=True)
    link = models.CharField(max_length=300, blank=True, help_text='Optional URL to navigate to')
    icon = models.CharField(max_length=50, blank=True, help_text='Bootstrap icon class')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self): return f"{self.recipient.username} — {self.title}"

    class Meta:
        db_table = 'notification'
        app_label = 'notifications'
        ordering = ['-created_at']


class SMSLog(models.Model):
    STATUS_CHOICES = [
        ('queued', 'Queued'), ('sent', 'Sent'),
        ('delivered', 'Delivered'), ('failed', 'Failed'),
    ]
    recipient_phone = models.CharField(max_length=15)
    recipient_name = models.CharField(max_length=100, blank=True)
    message = models.TextField()
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='queued')
    provider = models.CharField(max_length=50, blank=True)
    provider_message_id = models.CharField(max_length=100, blank=True)
    error_message = models.TextField(blank=True)
    sent_at = models.DateTimeField(null=True, blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self): return f"SMS to {self.recipient_phone} ({self.status})"
    class Meta: db_table = 'sms_log'; app_label = 'notifications'; ordering = ['-created_at']


class EmailLog(models.Model):
    STATUS_CHOICES = [
        ('queued', 'Queued'), ('sent', 'Sent'), ('failed', 'Failed'),
    ]
    recipient_email = models.EmailField()
    recipient_name = models.CharField(max_length=100, blank=True)
    subject = models.CharField(max_length=200)
    body = models.TextField()
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='queued')
    error_message = models.TextField(blank=True)
    sent_at = models.DateTimeField(null=True, blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self): return f"Email to {self.recipient_email}: {self.subject}"
    class Meta: db_table = 'email_log'; app_label = 'notifications'; ordering = ['-created_at']
