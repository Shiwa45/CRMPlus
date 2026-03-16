# deals/models.py
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from contacts.models import Contact, Company

User = get_user_model()


class Pipeline(models.Model):
    name        = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    is_default  = models.BooleanField(default=False)
    is_active   = models.BooleanField(default=True)
    created_by  = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_pipelines')
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name

    def save(self, *args, **kwargs):
        if self.is_default:
            Pipeline.objects.exclude(pk=self.pk).update(is_default=False)
        super().save(*args, **kwargs)


class PipelineStage(models.Model):
    pipeline    = models.ForeignKey(Pipeline, on_delete=models.CASCADE, related_name='stages')
    name        = models.CharField(max_length=150)
    order       = models.PositiveIntegerField(default=0)
    probability = models.PositiveIntegerField(default=0, help_text='Win probability 0-100%')
    color       = models.CharField(max_length=7, default='#6366f1', help_text='Hex color')
    is_won      = models.BooleanField(default=False)
    is_lost     = models.BooleanField(default=False)
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['order']
        unique_together = ['pipeline', 'name']

    def __str__(self):
        return f"{self.pipeline.name} → {self.name}"


class Deal(models.Model):
    PRIORITY_CHOICES = [
        ('critical', 'Critical'), ('high', 'High'), ('medium', 'Medium'), ('low', 'Low'),
    ]
    CURRENCY_CHOICES = [
        ('INR', '₹ INR'), ('USD', '$ USD'), ('EUR', '€ EUR'), ('GBP', '£ GBP'),
    ]

    # Core
    title           = models.CharField(max_length=300)
    pipeline        = models.ForeignKey(Pipeline, on_delete=models.PROTECT, related_name='deals')
    stage           = models.ForeignKey(PipelineStage, on_delete=models.PROTECT, related_name='deals')
    priority        = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')

    # Financials
    value           = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    currency        = models.CharField(max_length=3, choices=CURRENCY_CHOICES, default='INR')
    weighted_value  = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    expected_revenue = models.DecimalField(max_digits=15, decimal_places=2, default=0)

    # Relationships
    contact         = models.ForeignKey(Contact, on_delete=models.SET_NULL, null=True, blank=True, related_name='deals')
    company         = models.ForeignKey(Company, on_delete=models.SET_NULL, null=True, blank=True, related_name='deals')
    owner           = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='owned_deals')
    co_owners       = models.ManyToManyField(User, blank=True, related_name='co_owned_deals')
    created_by      = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_deals')

    # Dates
    close_date      = models.DateField(blank=True, null=True)
    actual_close_date = models.DateField(blank=True, null=True)

    # Outcome
    won_at          = models.DateTimeField(blank=True, null=True)
    lost_at         = models.DateTimeField(blank=True, null=True)
    lost_reason     = models.TextField(blank=True)
    competitor      = models.CharField(max_length=200, blank=True)

    # Details
    description     = models.TextField(blank=True)
    tags            = models.JSONField(default=list, blank=True)
    lead_source     = models.CharField(max_length=100, blank=True)

    created_at      = models.DateTimeField(auto_now_add=True)
    updated_at      = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.title

    def save(self, *args, **kwargs):
        # Auto-calc weighted value
        prob = self.stage.probability if self.stage_id else 0
        self.weighted_value = (self.value * prob) / 100
        # Set won/lost timestamps
        if self.stage and self.stage.is_won and not self.won_at:
            self.won_at = timezone.now()
            self.actual_close_date = timezone.now().date()
        if self.stage and self.stage.is_lost and not self.lost_at:
            self.lost_at = timezone.now()
        super().save(*args, **kwargs)


class DealActivity(models.Model):
    TYPE_CHOICES = [
        ('call', 'Call'), ('email', 'Email'), ('meeting', 'Meeting'),
        ('whatsapp', 'WhatsApp'), ('demo', 'Demo'), ('proposal', 'Proposal'),
        ('negotiation', 'Negotiation'), ('note', 'Note'), ('task', 'Task'),
    ]
    STATUS_CHOICES = [
        ('pending', 'Pending'), ('done', 'Done'), ('cancelled', 'Cancelled'),
    ]

    deal            = models.ForeignKey(Deal, on_delete=models.CASCADE, related_name='activities')
    activity_type   = models.CharField(max_length=20, choices=TYPE_CHOICES)
    subject         = models.CharField(max_length=255)
    description     = models.TextField(blank=True)
    outcome         = models.CharField(max_length=255, blank=True)
    status          = models.CharField(max_length=20, choices=STATUS_CHOICES, default='done')
    due_date        = models.DateTimeField(blank=True, null=True)
    performed_by    = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    performed_at    = models.DateTimeField(default=timezone.now)
    created_at      = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-performed_at']


class DealStageHistory(models.Model):
    """Tracks every stage change for analytics"""
    deal        = models.ForeignKey(Deal, on_delete=models.CASCADE, related_name='stage_history')
    from_stage  = models.ForeignKey(PipelineStage, on_delete=models.SET_NULL, null=True, blank=True, related_name='+')
    to_stage    = models.ForeignKey(PipelineStage, on_delete=models.SET_NULL, null=True, related_name='+')
    changed_by  = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    changed_at  = models.DateTimeField(auto_now_add=True)
    days_in_stage = models.PositiveIntegerField(default=0)
