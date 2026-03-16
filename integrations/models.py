# integrations/models.py
"""
Per-tenant API keys and WhatsApp templates.
Admin stores keys here; services read from here at runtime.
"""
from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class Integration(models.Model):
    """Stores encrypted API keys per tenant per service."""
    SERVICE_WHATSAPP = 'whatsapp'
    SERVICE_SARVAM   = 'sarvam'
    SERVICE_GEMINI   = 'gemini'
    SERVICE_SMTP     = 'smtp'
    SERVICE_SENDGRID = 'sendgrid'
    SERVICE_RAZORPAY = 'razorpay'

    SERVICE_CHOICES = [
        (SERVICE_WHATSAPP, 'WhatsApp Business (Meta / Gupshup)'),
        (SERVICE_SARVAM,   'Sarvam AI (Voice & Calls)'),
        (SERVICE_GEMINI,   'Google Gemini AI'),
        (SERVICE_SMTP,     'Custom SMTP'),
        (SERVICE_SENDGRID, 'SendGrid'),
        (SERVICE_RAZORPAY, 'Razorpay Payments'),
    ]

    tenant      = models.ForeignKey('tenants.Tenant', on_delete=models.CASCADE,
                                    related_name='integrations')
    service     = models.CharField(max_length=30, choices=SERVICE_CHOICES)
    is_enabled  = models.BooleanField(default=False)
    # Key fields (store as plain text here; use django-encrypted-fields in prod)
    api_key     = models.CharField(max_length=500, blank=True)
    api_secret  = models.CharField(max_length=500, blank=True)
    extra       = models.JSONField(default=dict, blank=True,
                                   help_text='phone_id, waba_id, sender_name, etc.')
    last_tested = models.DateTimeField(null=True, blank=True)
    test_ok     = models.BooleanField(null=True)
    created_by  = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ['tenant', 'service']
        ordering = ['service']

    def __str__(self):
        return f"{self.tenant.slug} – {self.service}"


class WhatsAppTemplate(models.Model):
    """
    WhatsApp message templates per tenant.
    Variables use {{name}}, {{company}}, {{phone}}, {{email}},
    {{lead_status}}, {{deal_value}}, {{custom_1}} … {{custom_5}}
    """
    CATEGORY = [
        ('utility','Utility'), ('marketing','Marketing'), ('authentication','Authentication'),
    ]
    STATUS = [
        ('draft','Draft'), ('pending','Pending Approval'),
        ('approved','Approved'), ('rejected','Rejected'),
    ]

    tenant      = models.ForeignKey('tenants.Tenant', on_delete=models.CASCADE,
                                    related_name='wa_templates')
    name        = models.CharField(max_length=100)
    category    = models.CharField(max_length=20, choices=CATEGORY, default='utility')
    language    = models.CharField(max_length=10, default='en')
    header_text = models.CharField(max_length=200, blank=True)
    body        = models.TextField()
    footer_text = models.CharField(max_length=100, blank=True)
    status      = models.CharField(max_length=20, choices=STATUS, default='draft')
    wa_template_id = models.CharField(max_length=100, blank=True,
                                      help_text='Meta-approved template name/ID')
    variables   = models.JSONField(default=list, blank=True,
                                   help_text='List of variable names in this template')
    use_count   = models.IntegerField(default=0)
    created_by  = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f"[{self.tenant.slug}] {self.name}"

    def render(self, context: dict) -> str:
        """Replace {{variable}} placeholders with real values."""
        msg = self.body
        for k, v in context.items():
            msg = msg.replace('{{' + k + '}}', str(v or ''))
        return msg


class WhatsAppLog(models.Model):
    """Log of every WA message sent."""
    STATUS_SENT    = 'sent'
    STATUS_FAILED  = 'failed'
    STATUS_PENDING = 'pending'

    tenant    = models.ForeignKey('tenants.Tenant', on_delete=models.CASCADE,
                                   related_name='wa_logs')
    template  = models.ForeignKey(WhatsAppTemplate, on_delete=models.SET_NULL,
                                   null=True, blank=True)
    to_phone  = models.CharField(max_length=20)
    to_name   = models.CharField(max_length=200, blank=True)
    message   = models.TextField()
    status    = models.CharField(max_length=20, default=STATUS_PENDING)
    wa_msg_id = models.CharField(max_length=200, blank=True)
    error     = models.TextField(blank=True)
    sent_by   = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    lead_id   = models.IntegerField(null=True, blank=True)
    contact_id= models.IntegerField(null=True, blank=True)
    created_at= models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
