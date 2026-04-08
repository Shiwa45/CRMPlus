# models.py
from django.db import models
from django.conf import settings


class Notice(models.Model):
    AUDIENCE_CHOICES = [
        ('all', 'Everyone'), ('staff', 'Staff Only'),
        ('students', 'Students'), ('parents', 'Parents'),
        ('teachers', 'Teachers'),
    ]
    title = models.CharField(max_length=200)
    content = models.TextField()
    audience = models.CharField(max_length=20, choices=AUDIENCE_CHOICES, default='all')
    attachment = models.FileField(upload_to='notices/', null=True, blank=True)
    is_active = models.BooleanField(default=True)
    is_pinned = models.BooleanField(default=False)
    published_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateField(null=True, blank=True)

    def __str__(self):
        return self.title

    class Meta:
        db_table = 'notices'
        ordering = ['-is_pinned', '-created_at']


class Announcement(models.Model):
    PRIORITY_CHOICES = [
        ('low', 'Low'), ('normal', 'Normal'),
        ('high', 'High'), ('urgent', 'Urgent'),
    ]
    title = models.CharField(max_length=200)
    message = models.TextField()
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='normal')
    send_sms = models.BooleanField(default=False)
    send_email = models.BooleanField(default=False)
    send_push = models.BooleanField(default=False)
    target_classes = models.ManyToManyField('academics.Class', blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title

    class Meta:
        db_table = 'announcements'
        ordering = ['-created_at']


class Message(models.Model):
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='sent_messages'
    )
    receiver = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='received_messages'
    )
    subject = models.CharField(max_length=200, blank=True)
    body = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"From {self.sender} to {self.receiver}: {self.subject}"

    class Meta:
        db_table = 'messages'
        ordering = ['-created_at']
