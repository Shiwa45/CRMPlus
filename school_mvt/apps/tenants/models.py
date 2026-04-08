"""
Tenants App — Public Schema Models
School (Tenant), Domain, SubscriptionPlan
"""
from django.db import models
from django_tenants.models import TenantMixin, DomainMixin


class School(TenantMixin):
    """
    The tenant model. One row = one school.
    Lives in the public schema.
    """
    PLAN_CHOICES = [
        ('free', 'Free'),
        ('basic', 'Basic'),
        ('standard', 'Standard'),
        ('premium', 'Premium'),
        ('enterprise', 'Enterprise'),
    ]
    BOARD_CHOICES = [
        ('cbse', 'CBSE'), ('icse', 'ICSE'), ('state', 'State Board'),
        ('ib', 'IB'), ('igcse', 'IGCSE'), ('other', 'Other'),
    ]

    # Basic info
    name = models.CharField(max_length=200, verbose_name='School Name')
    short_name = models.CharField(max_length=50, blank=True)
    school_code = models.CharField(max_length=20, unique=True)
    board = models.CharField(max_length=10, choices=BOARD_CHOICES, default='cbse')
    affiliation_number = models.CharField(max_length=50, blank=True)
    udise_code = models.CharField(max_length=20, blank=True, verbose_name='UDISE Code')

    # Contact
    address = models.TextField(blank=True)
    city = models.CharField(max_length=100, blank=True)
    state = models.CharField(max_length=100, blank=True)
    pincode = models.CharField(max_length=6, blank=True)
    phone = models.CharField(max_length=15, blank=True)
    email = models.EmailField(blank=True)
    website = models.URLField(blank=True)

    # Branding
    logo = models.ImageField(upload_to='school_logos/', null=True, blank=True)
    banner_image = models.ImageField(upload_to='school_banners/', null=True, blank=True)
    primary_color = models.CharField(max_length=7, default='#1a56db', help_text='Hex color')

    # Academic config
    current_academic_year = models.CharField(max_length=10, default='2024-25')
    academic_year_start_month = models.PositiveSmallIntegerField(default=4)
    school_timing_start = models.TimeField(null=True, blank=True)
    school_timing_end = models.TimeField(null=True, blank=True)
    working_days = models.JSONField(default=list, help_text='List of weekday numbers 0-6')

    # Subscription
    subscription_plan = models.CharField(max_length=20, choices=PLAN_CHOICES, default='basic')
    subscription_start = models.DateField(null=True, blank=True)
    subscription_end = models.DateField(null=True, blank=True)
    is_trial = models.BooleanField(default=True)
    trial_ends = models.DateField(null=True, blank=True)
    max_students = models.PositiveIntegerField(default=500)
    max_staff = models.PositiveIntegerField(default=50)

    # Status
    is_active = models.BooleanField(default=True)
    is_verified = models.BooleanField(default=False)
    onboarding_complete = models.BooleanField(default=False)

    # Settings blob
    settings = models.JSONField(default=dict, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Required by django-tenants
    auto_create_schema = True

    class Meta:
        verbose_name = 'School'
        verbose_name_plural = 'Schools'

    def __str__(self):
        return f"{self.name} ({self.schema_name})"

    @property
    def is_subscription_active(self):
        from django.utils import timezone
        if self.is_trial and self.trial_ends:
            return timezone.now().date() <= self.trial_ends
        if self.subscription_end:
            return timezone.now().date() <= self.subscription_end
        return False


class Domain(DomainMixin):
    """
    Domain model — one school can have multiple domains.
    e.g. school1.edumanage.pro, school1.example.com
    """
    class Meta:
        verbose_name = 'Domain'
        verbose_name_plural = 'Domains'

    def __str__(self):
        return self.domain


class SubscriptionPlan(models.Model):
    """
    Platform-level subscription plan config.
    """
    name = models.CharField(max_length=50, unique=True)
    code = models.CharField(max_length=20, unique=True)
    price_monthly = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    price_yearly = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    max_students = models.PositiveIntegerField(default=500, help_text='0 = unlimited')
    max_staff = models.PositiveIntegerField(default=50, help_text='0 = unlimited')
    features = models.JSONField(default=list, help_text='List of enabled feature keys')
    is_active = models.BooleanField(default=True)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Subscription Plan'
        verbose_name_plural = 'Subscription Plans'

    def __str__(self):
        return f"{self.name} (₹{self.price_monthly}/mo)"
