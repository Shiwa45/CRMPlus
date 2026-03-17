# communications/models.py  ← FULL REPLACEMENT  (tenant FK removed — schema = isolation)
from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class EmailConfiguration(models.Model):
    """Per-tenant SMTP/sending configuration."""
    PROVIDER_CHOICES = [
        ('smtp',      'Custom SMTP'),
        ('gmail',     'Gmail'),
        ('outlook',   'Outlook'),
        ('sendgrid',  'SendGrid'),
        ('mailgun',   'Mailgun'),
        ('ses',       'Amazon SES'),
    ]

    name            = models.CharField(max_length=200)
    provider        = models.CharField(max_length=20, choices=PROVIDER_CHOICES, default='smtp')
    smtp_host       = models.CharField(max_length=200, blank=True)
    smtp_port       = models.IntegerField(default=587)
    smtp_username   = models.CharField(max_length=200, blank=True)
    smtp_password   = models.CharField(max_length=500, blank=True)
    use_tls         = models.BooleanField(default=True)
    use_ssl         = models.BooleanField(default=False)
    from_name       = models.CharField(max_length=200, blank=True)
    from_email      = models.EmailField(blank=True)
    reply_to        = models.EmailField(blank=True)
    is_default      = models.BooleanField(default=False)
    is_active       = models.BooleanField(default=True)
    daily_limit     = models.IntegerField(default=500)
    sent_today      = models.IntegerField(default=0)
    created_by      = models.ForeignKey(User, on_delete=models.SET_NULL,
                                        null=True, related_name='email_configs')
    created_at      = models.DateTimeField(auto_now_add=True)
    updated_at      = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-is_default', 'name']

    def __str__(self):
        return f'{self.name} ({self.provider})'


class EmailTemplate(models.Model):
    TEMPLATE_TYPES = [
        ('welcome',     'Welcome Email'),
        ('follow_up',   'Follow-up'),
        ('quote',       'Quote / Proposal'),
        ('invoice',     'Invoice'),
        ('thank_you',   'Thank You'),
        ('nurture',     'Nurture'),
        ('appointment', 'Appointment Confirmation'),
        ('custom',      'Custom'),
    ]

    user            = models.ForeignKey(User, on_delete=models.CASCADE,
                                        related_name='email_templates')
    name            = models.CharField(max_length=200)
    template_type   = models.CharField(max_length=20, choices=TEMPLATE_TYPES)
    subject         = models.CharField(max_length=300)
    body_html       = models.TextField()
    body_text       = models.TextField(blank=True)
    is_shared       = models.BooleanField(default=False)
    variables_help  = models.TextField(blank=True)
    open_count      = models.IntegerField(default=0)
    click_count     = models.IntegerField(default=0)
    created_at      = models.DateTimeField(auto_now_add=True)
    updated_at      = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.name


class EmailCampaign(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'), ('scheduled', 'Scheduled'),
        ('sending', 'Sending'), ('paused', 'Paused'),
        ('completed', 'Completed'), ('failed', 'Failed'),
    ]

    name                  = models.CharField(max_length=200)
    template              = models.ForeignKey(EmailTemplate, on_delete=models.SET_NULL,
                                              null=True, blank=True)
    email_config          = models.ForeignKey(EmailConfiguration, on_delete=models.SET_NULL,
                                              null=True, blank=True)
    subject               = models.CharField(max_length=300)
    status                = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    scheduled_at          = models.DateTimeField(null=True, blank=True)

    # Targeting
    target_all_leads      = models.BooleanField(default=False)
    target_statuses       = models.JSONField(default=list, blank=True)
    target_priorities     = models.JSONField(default=list, blank=True)
    target_sources        = models.JSONField(default=list, blank=True)

    # Stats
    total_recipients      = models.IntegerField(default=0)
    emails_sent           = models.IntegerField(default=0)
    emails_failed         = models.IntegerField(default=0)
    emails_opened         = models.IntegerField(default=0)
    emails_clicked        = models.IntegerField(default=0)
    batch_size            = models.IntegerField(default=50)
    delay_between_batches = models.IntegerField(default=60)
    started_at            = models.DateTimeField(null=True, blank=True)
    completed_at          = models.DateTimeField(null=True, blank=True)

    created_by            = models.ForeignKey(User, on_delete=models.SET_NULL,
                                              null=True, related_name='campaigns')
    created_at            = models.DateTimeField(auto_now_add=True)
    updated_at            = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.name} ({self.status})'


class Email(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'), ('queued', 'Queued'), ('sending', 'Sending'),
        ('sent', 'Sent'), ('delivered', 'Delivered'), ('opened', 'Opened'),
        ('clicked', 'Clicked'), ('bounced', 'Bounced'), ('failed', 'Failed'),
    ]

    campaign        = models.ForeignKey(EmailCampaign, on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='emails')
    template        = models.ForeignKey(EmailTemplate, on_delete=models.SET_NULL,
                                        null=True, blank=True)
    email_config    = models.ForeignKey(EmailConfiguration, on_delete=models.SET_NULL,
                                        null=True, blank=True)

    to_email        = models.EmailField()
    to_name         = models.CharField(max_length=200, blank=True)
    from_email      = models.EmailField(blank=True)
    from_name       = models.CharField(max_length=200, blank=True)
    subject         = models.CharField(max_length=300)
    body_html       = models.TextField()
    body_text       = models.TextField(blank=True)

    status          = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    message_id      = models.CharField(max_length=500, blank=True)
    error_message   = models.TextField(blank=True)

    scheduled_at    = models.DateTimeField(null=True, blank=True)
    sent_at         = models.DateTimeField(null=True, blank=True)
    opened_at       = models.DateTimeField(null=True, blank=True)
    clicked_at      = models.DateTimeField(null=True, blank=True)
    bounced_at      = models.DateTimeField(null=True, blank=True)

    sent_by         = models.ForeignKey(User, on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='sent_emails')
    created_at      = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.subject} → {self.to_email}'


class EmailTracking(models.Model):
    EVENT_TYPES = [
        ('open', 'Open'), ('click', 'Click'),
        ('bounce', 'Bounce'), ('unsubscribe', 'Unsubscribe'),
    ]

    email       = models.ForeignKey(Email, on_delete=models.CASCADE,
                                    related_name='tracking_events')
    event_type  = models.CharField(max_length=20, choices=EVENT_TYPES)
    ip_address  = models.GenericIPAddressField(null=True, blank=True)
    user_agent  = models.CharField(max_length=500, blank=True)
    link_url    = models.URLField(blank=True)
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']


class EmailSequence(models.Model):
    STATUS_CHOICES = [
        ('active', 'Active'), ('paused', 'Paused'), ('draft', 'Draft'),
    ]

    name        = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    status      = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    user        = models.ForeignKey(User, on_delete=models.CASCADE,
                                    related_name='email_sequences')
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.name


class EmailSequenceStep(models.Model):
    sequence    = models.ForeignKey(EmailSequence, on_delete=models.CASCADE,
                                    related_name='steps')
    template    = models.ForeignKey(EmailTemplate, on_delete=models.SET_NULL,
                                    null=True, blank=True)
    subject     = models.CharField(max_length=300, blank=True)
    body_html   = models.TextField(blank=True)
    delay_days  = models.IntegerField(default=1,
                                      help_text='Days after previous step')
    order       = models.IntegerField(default=0)
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f'{self.sequence.name} — Step {self.order}'


class EmailSequenceEnrollment(models.Model):
    STATUS_CHOICES = [
        ('active', 'Active'), ('completed', 'Completed'),
        ('paused', 'Paused'), ('unsubscribed', 'Unsubscribed'),
    ]

    sequence        = models.ForeignKey(EmailSequence, on_delete=models.CASCADE,
                                        related_name='enrollments')
    lead_email      = models.EmailField()
    current_step    = models.IntegerField(default=0)
    status          = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    enrolled_at     = models.DateTimeField(auto_now_add=True)
    next_send_at    = models.DateTimeField(null=True, blank=True)
    completed_at    = models.DateTimeField(null=True, blank=True)

    class Meta:
        unique_together = ('sequence', 'lead_email')
        ordering = ['-enrolled_at']
