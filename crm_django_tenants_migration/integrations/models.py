# integrations/models.py  ← FULL REPLACEMENT  (tenant FK removed — schema = isolation)
from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class Integration(models.Model):
    SERVICE_CHOICES = [
        ('gmail',       'Gmail'),
        ('outlook',     'Outlook / Office 365'),
        ('whatsapp',    'WhatsApp Business API'),
        ('slack',       'Slack'),
        ('zapier',      'Zapier'),
        ('webhook',     'Generic Webhook'),
        ('zoho',        'Zoho CRM'),
        ('salesforce',  'Salesforce'),
        ('intercom',    'Intercom'),
        ('razorpay',    'Razorpay'),
        ('stripe',      'Stripe'),
        ('twilio',      'Twilio'),
        ('sendgrid',    'SendGrid'),
        ('mailchimp',   'Mailchimp'),
    ]
    STATUS_CHOICES = [
        ('active',    'Active'),
        ('inactive',  'Inactive'),
        ('error',     'Error'),
        ('pending',   'Pending Setup'),
    ]

    service         = models.CharField(max_length=50, choices=SERVICE_CHOICES, unique=True)
    display_name    = models.CharField(max_length=200, blank=True)
    status          = models.CharField(max_length=20, choices=STATUS_CHOICES, default='inactive')
    is_active       = models.BooleanField(default=False)

    # Credentials — stored as JSON (encrypt in production with django-encrypted-fields)
    credentials     = models.JSONField(default=dict, blank=True,
                                       help_text='Encrypted API keys / tokens')
    config          = models.JSONField(default=dict, blank=True,
                                       help_text='Service-specific configuration')

    # Usage tracking
    last_sync       = models.DateTimeField(null=True, blank=True)
    last_error      = models.TextField(blank=True)
    sync_count      = models.IntegerField(default=0)
    error_count     = models.IntegerField(default=0)

    created_by      = models.ForeignKey(User, on_delete=models.SET_NULL,
                                        null=True, related_name='created_integrations')
    created_at      = models.DateTimeField(auto_now_add=True)
    updated_at      = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['service']

    def __str__(self):
        return f'{self.get_service_display()} ({self.status})'


class WhatsAppTemplate(models.Model):
    CATEGORY_CHOICES = [
        ('marketing',    'Marketing'),
        ('utility',      'Utility'),
        ('authentication','Authentication'),
    ]
    STATUS_CHOICES = [
        ('draft',    'Draft'),
        ('pending',  'Pending Approval'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]

    name        = models.CharField(max_length=200)
    category    = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    language    = models.CharField(max_length=10, default='en')
    body        = models.TextField()
    header      = models.CharField(max_length=200, blank=True)
    footer      = models.CharField(max_length=200, blank=True)
    variables   = models.JSONField(default=list, blank=True,
                                   help_text='List of variable names used in body')
    status      = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    wa_template_id = models.CharField(max_length=200, blank=True,
                                      help_text='Template ID from WhatsApp Business API')
    created_by  = models.ForeignKey(User, on_delete=models.SET_NULL,
                                    null=True, related_name='created_wa_templates')
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f'{self.name} ({self.language})'


class WALog(models.Model):
    STATUS_CHOICES = [
        ('queued', 'Queued'), ('sent', 'Sent'), ('delivered', 'Delivered'),
        ('read', 'Read'), ('failed', 'Failed'),
    ]

    template    = models.ForeignKey(WhatsAppTemplate, on_delete=models.SET_NULL,
                                    null=True, blank=True, related_name='logs')
    to_number   = models.CharField(max_length=20)
    body_sent   = models.TextField(blank=True)
    status      = models.CharField(max_length=20, choices=STATUS_CHOICES, default='queued')
    wa_message_id = models.CharField(max_length=200, blank=True)
    error       = models.TextField(blank=True)
    sent_at     = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    read_at     = models.DateTimeField(null=True, blank=True)
    created_by  = models.ForeignKey(User, on_delete=models.SET_NULL,
                                    null=True, related_name='wa_logs')
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'WA → {self.to_number} ({self.status})'
