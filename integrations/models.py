# integrations/models.py  ← FULL REPLACEMENT  (tenant FK removed — schema = isolation)
from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class Integration(models.Model):
    SERVICE_GEMINI = 'gemini'
    SERVICE_SARVAM = 'sarvam'
    SERVICE_WHATSAPP = 'whatsapp'
    SERVICE_INDIAMART = 'indiamart'
    SERVICE_META_LEADS = 'meta_leads'
    SERVICE_CHOICES = [
        ('gmail',       'Gmail'),
        ('outlook',     'Outlook / Office 365'),
        (SERVICE_WHATSAPP,    'WhatsApp Business API'),
        (SERVICE_GEMINI,      'Google Gemini AI'),
        (SERVICE_SARVAM,      'Sarvam AI'),
        (SERVICE_INDIAMART,   'IndiaMART Lead Manager'),
        (SERVICE_META_LEADS,  'Meta (Facebook) Lead Ads'),
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

    @property
    def api_key(self):
        return (self.credentials or {}).get('api_key', '')

    @property
    def api_secret(self):
        return (self.credentials or {}).get('api_secret', '')

    @property
    def extra(self):
        return self.config or {}

    @property
    def is_enabled(self):
        return self.is_active


class LeadImportLog(models.Model):
    """Tracks every lead import batch from external platforms (IndiaMART, Meta, etc.)."""
    SOURCE_CHOICES = [
        ('indiamart',   'IndiaMART'),
        ('meta_leads',  'Meta Lead Ads'),
    ]
    METHOD_CHOICES = [
        ('pull_api',      'Pull API (Polling)'),
        ('push_webhook',  'Push API (Webhook)'),
        ('webhook',       'Webhook'),
        ('manual',        'Manual Sync'),
    ]

    source          = models.CharField(max_length=30, choices=SOURCE_CHOICES)
    method          = models.CharField(max_length=20, choices=METHOD_CHOICES)
    leads_received  = models.IntegerField(default=0,
                                          help_text='Total leads received from API')
    leads_created   = models.IntegerField(default=0,
                                          help_text='New leads actually created')
    leads_skipped   = models.IntegerField(default=0,
                                          help_text='Duplicate leads skipped')
    error_message   = models.TextField(blank=True)
    raw_response    = models.JSONField(default=dict, blank=True,
                                       help_text='Raw API response for debugging')
    external_ids    = models.JSONField(default=list, blank=True,
                                       help_text='List of external IDs processed (for dedup)')
    created_at      = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Lead Import Log'
        verbose_name_plural = 'Lead Import Logs'

    def __str__(self):
        return (f'{self.get_source_display()} via {self.get_method_display()} — '
                f'{self.leads_created} created, {self.leads_skipped} skipped '
                f'({self.created_at:%Y-%m-%d %H:%M})')


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
