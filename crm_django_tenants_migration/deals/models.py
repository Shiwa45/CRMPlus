# deals/models.py  ← FULL REPLACEMENT  (tenant FK removed — schema = isolation)
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from decimal import Decimal

User = get_user_model()


class Pipeline(models.Model):
    name        = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    is_default  = models.BooleanField(default=False)
    is_active   = models.BooleanField(default=True)
    created_by  = models.ForeignKey(User, on_delete=models.SET_NULL,
                                    null=True, related_name='created_pipelines')
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-is_default', 'name']

    def __str__(self):
        return self.name

    def save(self, *args, **kwargs):
        if self.is_default:
            Pipeline.objects.exclude(pk=self.pk).update(is_default=False)
        super().save(*args, **kwargs)


class PipelineStage(models.Model):
    pipeline    = models.ForeignKey(Pipeline, on_delete=models.CASCADE,
                                    related_name='stages')
    name        = models.CharField(max_length=100)
    order       = models.IntegerField(default=0)
    probability = models.IntegerField(default=0)
    color       = models.CharField(max_length=20, default='#6366f1')
    is_won      = models.BooleanField(default=False)
    is_lost     = models.BooleanField(default=False)
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['pipeline', 'order']
        unique_together = ('pipeline', 'name')

    def __str__(self):
        return f'{self.pipeline.name} → {self.name}'

    @property
    def deals_count(self):
        return self.deals.count()

    @property
    def deals_value(self):
        return self.deals.aggregate(v=models.Sum('value'))['v'] or 0


class Deal(models.Model):
    PRIORITY_CHOICES = [
        ('low', 'Low'), ('medium', 'Medium'), ('high', 'High'), ('critical', 'Critical'),
    ]
    CURRENCY_CHOICES = [
        ('INR', '₹ INR'), ('USD', '$ USD'), ('EUR', '€ EUR'),
    ]

    title           = models.CharField(max_length=300)
    pipeline        = models.ForeignKey(Pipeline, on_delete=models.SET_NULL,
                                        null=True, related_name='deals')
    stage           = models.ForeignKey(PipelineStage, on_delete=models.SET_NULL,
                                        null=True, related_name='deals')

    # Value
    value           = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    currency        = models.CharField(max_length=5, choices=CURRENCY_CHOICES, default='INR')
    probability     = models.IntegerField(default=0)
    weighted_value  = models.DecimalField(max_digits=15, decimal_places=2, default=0)

    # Relations
    contact         = models.ForeignKey('contacts.Contact', on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='deals')
    company         = models.ForeignKey('contacts.Company', on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='deals')

    # Meta
    priority        = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')
    description     = models.TextField(blank=True)
    tags            = models.JSONField(default=list, blank=True)
    lead_source     = models.CharField(max_length=100, blank=True)
    close_date      = models.DateField(null=True, blank=True)
    won_at          = models.DateTimeField(null=True, blank=True)
    lost_at         = models.DateTimeField(null=True, blank=True)
    lost_reason     = models.TextField(blank=True)

    # Ownership
    owner           = models.ForeignKey(User, on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='owned_deals')
    created_by      = models.ForeignKey(User, on_delete=models.SET_NULL,
                                        null=True, related_name='created_deals')
    created_at      = models.DateTimeField(auto_now_add=True)
    updated_at      = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.title

    def save(self, *args, **kwargs):
        # Keep weighted_value in sync
        if self.probability and self.value:
            self.weighted_value = self.value * Decimal(self.probability) / Decimal(100)
        # Record won/lost timestamps
        if self.stage:
            if self.stage.is_won and not self.won_at:
                self.won_at = timezone.now()
            elif self.stage.is_lost and not self.lost_at:
                self.lost_at = timezone.now()
        super().save(*args, **kwargs)


class DealActivity(models.Model):
    ACTIVITY_TYPES = [
        ('call', 'Call'), ('email', 'Email'), ('meeting', 'Meeting'),
        ('demo', 'Demo'), ('proposal', 'Proposal'), ('note', 'Note'),
    ]
    STATUS_CHOICES = [
        ('planned', 'Planned'), ('done', 'Done'), ('cancelled', 'Cancelled'),
    ]

    deal          = models.ForeignKey(Deal, on_delete=models.CASCADE,
                                      related_name='activities')
    activity_type = models.CharField(max_length=20, choices=ACTIVITY_TYPES)
    subject       = models.CharField(max_length=200, blank=True)
    description   = models.TextField(blank=True)
    status        = models.CharField(max_length=20, choices=STATUS_CHOICES, default='planned')
    performed_by  = models.ForeignKey(User, on_delete=models.SET_NULL,
                                      null=True, related_name='deal_activities')
    scheduled_at  = models.DateTimeField(null=True, blank=True)
    completed_at  = models.DateTimeField(null=True, blank=True)
    created_at    = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.activity_type} — {self.deal}'


class DealStageHistory(models.Model):
    deal       = models.ForeignKey(Deal, on_delete=models.CASCADE,
                                   related_name='stage_history')
    from_stage = models.ForeignKey(PipelineStage, on_delete=models.SET_NULL,
                                   null=True, related_name='+')
    to_stage   = models.ForeignKey(PipelineStage, on_delete=models.SET_NULL,
                                   null=True, related_name='+')
    moved_by   = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    moved_at   = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-moved_at']
