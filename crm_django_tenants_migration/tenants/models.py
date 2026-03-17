# tenants/models.py  ← FULL REPLACEMENT
"""
Tenant & domain models for django-tenants.

Hierarchy:
    Plan  →  Tenant (TenantMixin)  →  Domain (DomainMixin)
                     ↓
               TenantUser  (links CustomUser ↔ Tenant)
               TenantInvitation
               TenantAuditLog

All of these live in the PUBLIC schema so the superadmin can manage
them without being inside any tenant schema.
"""

from django.db import models
from django.conf import settings
from django.utils import timezone
from django_tenants.models import TenantMixin, DomainMixin


# ── Subscription Plans (global, shared) ───────────────────────────────────────

class Plan(models.Model):
    BILLING_CYCLE = [
        ('monthly', 'Monthly'),
        ('yearly',  'Yearly'),
    ]

    name            = models.CharField(max_length=100, unique=True)
    slug            = models.SlugField(unique=True)
    description     = models.TextField(blank=True)
    price_monthly   = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    price_yearly    = models.DecimalField(max_digits=10, decimal_places=2, default=0)

    # Feature limits (0 = unlimited)
    max_users       = models.IntegerField(default=5)
    max_leads       = models.IntegerField(default=500)
    max_contacts    = models.IntegerField(default=1000)
    max_deals       = models.IntegerField(default=200)
    max_emails_month = models.IntegerField(default=1000)
    max_storage_gb  = models.IntegerField(default=5)

    # Feature flags
    has_whatsapp    = models.BooleanField(default=False)
    has_ai          = models.BooleanField(default=False)
    has_api_access  = models.BooleanField(default=False)
    has_custom_domain = models.BooleanField(default=False)
    has_advanced_reports = models.BooleanField(default=False)

    is_active       = models.BooleanField(default=True)
    is_popular      = models.BooleanField(default=False)
    sort_order      = models.IntegerField(default=0)

    created_at      = models.DateTimeField(auto_now_add=True)
    updated_at      = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['sort_order', 'price_monthly']

    def __str__(self):
        return self.name


# ── Tenant (one per customer organisation) ────────────────────────────────────

class Tenant(TenantMixin):
    """
    Extends django-tenants TenantMixin.

    TenantMixin adds:
        schema_name         CharField — PostgreSQL schema name (e.g. 'sharma_infotech')
        auto_create_schema  BooleanField
        auto_drop_schema    BooleanField
        create_schema()
        drop_schema()
    """

    STATUS_CHOICES = [
        ('active',    'Active'),
        ('trial',     'Trial'),
        ('suspended', 'Suspended'),
        ('expired',   'Expired'),
        ('cancelled', 'Cancelled'),
    ]

    BILLING_CHOICES = [
        ('monthly', 'Monthly'),
        ('yearly',  'Yearly'),
    ]

    # Business identity
    name    = models.CharField(max_length=200)
    slug    = models.SlugField(unique=True)          # human-readable ID used in API header
    logo    = models.ImageField(upload_to='tenant_logos/', blank=True, null=True)

    # Subscription
    plan    = models.ForeignKey(Plan, on_delete=models.PROTECT,
                                related_name='tenants', null=True, blank=True)
    status  = models.CharField(max_length=20, choices=STATUS_CHOICES, default='trial')
    billing = models.CharField(max_length=10, choices=BILLING_CHOICES, default='monthly')
    trial_ends = models.DateTimeField(null=True, blank=True)
    plan_ends  = models.DateTimeField(null=True, blank=True)

    # Indian business details
    gstin   = models.CharField(max_length=20, blank=True)
    pan     = models.CharField(max_length=20, blank=True)

    # Contact
    email   = models.EmailField()
    phone   = models.CharField(max_length=20, blank=True)
    address = models.TextField(blank=True)
    city    = models.CharField(max_length=100, blank=True)
    state   = models.CharField(max_length=100, blank=True)
    pincode = models.CharField(max_length=10, blank=True)
    country = models.CharField(max_length=100, default='India')

    # Settings
    timezone_name = models.CharField(max_length=50, default='Asia/Kolkata')
    currency      = models.CharField(max_length=5, default='INR')
    date_format   = models.CharField(max_length=20, default='DD/MM/YYYY')

    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    # Required by TenantMixin — create schema automatically on save
    auto_create_schema = True

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name

    @property
    def is_active_subscription(self):
        if self.status == 'active':
            return self.plan_ends is None or self.plan_ends > timezone.now()
        if self.status == 'trial':
            return self.trial_ends is None or self.trial_ends > timezone.now()
        return False

    def save(self, *args, **kwargs):
        # Keep schema_name in sync with slug (replace hyphens with underscores)
        if not self.schema_name:
            self.schema_name = self.slug.replace('-', '_')
        super().save(*args, **kwargs)


# ── Domain (subdomain → tenant mapping) ───────────────────────────────────────

class Domain(DomainMixin):
    """
    Maps a domain/subdomain to a Tenant.

    DomainMixin adds:
        domain      CharField
        tenant      ForeignKey → Tenant
        is_primary  BooleanField
    """
    class Meta:
        verbose_name = 'Domain'

    def __str__(self):
        return self.domain


# ── Tenant ↔ User membership ──────────────────────────────────────────────────

class TenantUser(models.Model):
    ROLE_CHOICES = [
        ('super_admin',   'Super Admin'),
        ('tenant_admin',  'Tenant Admin'),
        ('sales_manager', 'Sales Manager'),
        ('sales_rep',     'Sales Rep'),
        ('marketing',     'Marketing'),
        ('support',       'Support'),
    ]

    tenant  = models.ForeignKey(Tenant, on_delete=models.CASCADE,
                                related_name='memberships')
    user    = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
                                related_name='tenant_memberships')
    role    = models.CharField(max_length=30, choices=ROLE_CHOICES, default='sales_rep')
    is_active = models.BooleanField(default=True)
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('tenant', 'user')
        ordering = ['tenant', 'role']

    def __str__(self):
        return f'{self.user.username} @ {self.tenant.name} ({self.role})'


# ── Invitation system ─────────────────────────────────────────────────────────

class TenantInvitation(models.Model):
    STATUS_CHOICES = [
        ('pending',   'Pending'),
        ('accepted',  'Accepted'),
        ('expired',   'Expired'),
        ('cancelled', 'Cancelled'),
    ]

    tenant      = models.ForeignKey(Tenant, on_delete=models.CASCADE,
                                    related_name='invitations')
    email       = models.EmailField()
    role        = models.CharField(max_length=30,
                                   choices=TenantUser.ROLE_CHOICES,
                                   default='sales_rep')
    token       = models.CharField(max_length=64, unique=True)
    status      = models.CharField(max_length=20, choices=STATUS_CHOICES,
                                   default='pending')
    invited_by  = models.ForeignKey(settings.AUTH_USER_MODEL,
                                    on_delete=models.SET_NULL, null=True)
    expires_at  = models.DateTimeField()
    accepted_at = models.DateTimeField(null=True, blank=True)
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'Invite {self.email} → {self.tenant.name}'

    @property
    def is_expired(self):
        return timezone.now() > self.expires_at


# ── Audit log (per-tenant action history, stored in public schema) ────────────

class TenantAuditLog(models.Model):
    tenant    = models.ForeignKey(Tenant, on_delete=models.CASCADE,
                                  related_name='audit_logs')
    user      = models.ForeignKey(settings.AUTH_USER_MODEL,
                                  on_delete=models.SET_NULL, null=True)
    action    = models.CharField(max_length=100)
    resource  = models.CharField(max_length=100, blank=True)
    resource_id = models.CharField(max_length=50, blank=True)
    details   = models.JSONField(default=dict, blank=True)
    ip        = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.CharField(max_length=300, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.tenant.name} | {self.action} by {self.user}'
