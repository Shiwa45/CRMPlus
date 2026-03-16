# tenants/models.py
import uuid
from django.db import models
from django.utils import timezone


class Plan(models.Model):
    STARTER = 'starter'; GROWTH = 'growth'
    PROFESSIONAL = 'professional'; ENTERPRISE = 'enterprise'
    PLAN_CHOICES = [
        (STARTER, 'Starter'), (GROWTH, 'Growth'),
        (PROFESSIONAL, 'Professional'), (ENTERPRISE, 'Enterprise'),
    ]
    name          = models.CharField(max_length=50, choices=PLAN_CHOICES, unique=True)
    display_name  = models.CharField(max_length=100)
    tagline       = models.CharField(max_length=200, blank=True)
    monthly_price = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    annual_price  = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    # Limits (-1 = unlimited)
    max_users     = models.IntegerField(default=2)
    max_leads     = models.IntegerField(default=500)
    max_contacts  = models.IntegerField(default=500)
    max_deals     = models.IntegerField(default=100)
    max_emails_pm = models.IntegerField(default=1000)
    max_wa_pm     = models.IntegerField(default=0)
    max_ai_pm     = models.IntegerField(default=0)
    storage_gb    = models.IntegerField(default=1)
    # Feature flags
    feat_whatsapp      = models.BooleanField(default=False)
    feat_ai_scoring    = models.BooleanField(default=False)
    feat_ai_assistant  = models.BooleanField(default=False)
    feat_ai_calls      = models.BooleanField(default=False)
    feat_workflows     = models.BooleanField(default=False)
    feat_quotes        = models.BooleanField(default=True)
    feat_invoices      = models.BooleanField(default=True)
    feat_tickets       = models.BooleanField(default=False)
    feat_analytics     = models.BooleanField(default=True)
    feat_api_access    = models.BooleanField(default=False)
    feat_custom_domain = models.BooleanField(default=False)
    feat_sso           = models.BooleanField(default=False)
    feat_audit_log     = models.BooleanField(default=False)
    is_active  = models.BooleanField(default=True)
    sort_order = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['sort_order']

    def __str__(self):
        return f"{self.display_name} — ₹{self.monthly_price}/mo"

    @classmethod
    def seed(cls):
        plans = [
            dict(name=cls.STARTER, display_name='Starter', sort_order=1,
                 tagline='Solo freelancers & micro teams',
                 monthly_price=999, annual_price=9590,
                 max_users=2, max_leads=500, max_contacts=500, max_deals=100,
                 max_emails_pm=1000, max_wa_pm=0, max_ai_pm=0, storage_gb=1,
                 feat_whatsapp=False, feat_ai_scoring=False, feat_ai_assistant=False,
                 feat_ai_calls=False, feat_workflows=False, feat_quotes=True,
                 feat_invoices=True, feat_tickets=False, feat_analytics=True,
                 feat_api_access=False, feat_custom_domain=False, feat_sso=False, feat_audit_log=False),
            dict(name=cls.GROWTH, display_name='Growth', sort_order=2,
                 tagline='Growing teams that close deals faster',
                 monthly_price=2999, annual_price=28790,
                 max_users=10, max_leads=5000, max_contacts=5000, max_deals=1000,
                 max_emails_pm=10000, max_wa_pm=1000, max_ai_pm=100, storage_gb=10,
                 feat_whatsapp=True, feat_ai_scoring=True, feat_ai_assistant=True,
                 feat_ai_calls=False, feat_workflows=True, feat_quotes=True,
                 feat_invoices=True, feat_tickets=True, feat_analytics=True,
                 feat_api_access=False, feat_custom_domain=False, feat_sso=False, feat_audit_log=False),
            dict(name=cls.PROFESSIONAL, display_name='Professional', sort_order=3,
                 tagline='Full power — AI calls, automation & API',
                 monthly_price=7999, annual_price=76790,
                 max_users=25, max_leads=-1, max_contacts=-1, max_deals=-1,
                 max_emails_pm=50000, max_wa_pm=5000, max_ai_pm=500, storage_gb=50,
                 feat_whatsapp=True, feat_ai_scoring=True, feat_ai_assistant=True,
                 feat_ai_calls=True, feat_workflows=True, feat_quotes=True,
                 feat_invoices=True, feat_tickets=True, feat_analytics=True,
                 feat_api_access=True, feat_custom_domain=True, feat_sso=False, feat_audit_log=True),
            dict(name=cls.ENTERPRISE, display_name='Enterprise', sort_order=4,
                 tagline='Unlimited scale — SSO, SLAs & white-glove support',
                 monthly_price=19999, annual_price=191990,
                 max_users=-1, max_leads=-1, max_contacts=-1, max_deals=-1,
                 max_emails_pm=-1, max_wa_pm=-1, max_ai_pm=-1, storage_gb=500,
                 feat_whatsapp=True, feat_ai_scoring=True, feat_ai_assistant=True,
                 feat_ai_calls=True, feat_workflows=True, feat_quotes=True,
                 feat_invoices=True, feat_tickets=True, feat_analytics=True,
                 feat_api_access=True, feat_custom_domain=True, feat_sso=True, feat_audit_log=True),
        ]
        for p in plans:
            cls.objects.update_or_create(name=p['name'], defaults=p)
        print("✓ Plans seeded")


class Tenant(models.Model):
    STATUS = [('trial','Trial'),('active','Active'),('suspended','Suspended'),('expired','Expired')]
    id         = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name       = models.CharField(max_length=200)
    slug       = models.SlugField(max_length=100, unique=True)
    domain     = models.CharField(max_length=200, blank=True)
    gstin      = models.CharField(max_length=20, blank=True)
    pan        = models.CharField(max_length=10, blank=True)
    address    = models.TextField(blank=True)
    city       = models.CharField(max_length=100, blank=True)
    state      = models.CharField(max_length=100, blank=True)
    pincode    = models.CharField(max_length=10, blank=True)
    phone      = models.CharField(max_length=20, blank=True)
    email      = models.EmailField(blank=True)
    logo       = models.ImageField(upload_to='tenants/', blank=True, null=True)
    plan       = models.ForeignKey(Plan, on_delete=models.PROTECT, related_name='tenants')
    billing    = models.CharField(max_length=10, default='monthly')
    status     = models.CharField(max_length=20, choices=STATUS, default='trial')
    trial_ends = models.DateTimeField(null=True, blank=True)
    plan_ends  = models.DateTimeField(null=True, blank=True)
    # Monthly usage counters
    emails_sent = models.IntegerField(default=0)
    wa_sent     = models.IntegerField(default=0)
    ai_used     = models.IntegerField(default=0)
    usage_reset = models.DateTimeField(default=timezone.now)
    tenant_timezone = models.CharField(max_length=50, default='Asia/Kolkata', db_column='timezone')
    currency    = models.CharField(max_length=5, default='INR')
    is_active   = models.BooleanField(default=True)
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f"{self.name} [{self.plan.display_name}]"

    def has_feature(self, feat):
        return getattr(self.plan, f'feat_{feat}', False)

    def within_limit(self, resource):
        limits = {
            'emails': (self.plan.max_emails_pm, self.emails_sent),
            'whatsapp': (self.plan.max_wa_pm, self.wa_sent),
            'ai': (self.plan.max_ai_pm, self.ai_used),
        }
        if resource not in limits:
            return True
        limit, used = limits[resource]
        return limit == -1 or used < limit


ROLES = [
    ('super_admin','Super Admin'), ('tenant_admin','Tenant Admin'),
    ('sales_manager','Sales Manager'), ('sales_rep','Sales Rep'),
    ('marketing','Marketing'), ('support','Support'), ('readonly','Read Only'),
]

class TenantUser(models.Model):
    tenant    = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name='members')
    user      = models.ForeignKey('accounts.CustomUser', on_delete=models.CASCADE, related_name='tenants')
    role      = models.CharField(max_length=20, choices=ROLES, default='sales_rep')
    is_active = models.BooleanField(default=True)
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['tenant', 'user']

    def __str__(self):
        return f"{self.user} @ {self.tenant.slug} [{self.role}]"


class TenantInvitation(models.Model):
    tenant     = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name='invitations')
    email      = models.EmailField()
    role       = models.CharField(max_length=20, choices=ROLES, default='sales_rep')
    token      = models.UUIDField(default=uuid.uuid4, unique=True)
    invited_by = models.ForeignKey('accounts.CustomUser', on_delete=models.SET_NULL, null=True)
    accepted   = models.BooleanField(default=False)
    expires_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    @property
    def is_expired(self):
        return timezone.now() > self.expires_at


class TenantAuditLog(models.Model):
    tenant      = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name='audit_logs')
    user        = models.ForeignKey('accounts.CustomUser', on_delete=models.SET_NULL, null=True, blank=True)
    action      = models.CharField(max_length=100)
    resource    = models.CharField(max_length=100, blank=True)
    resource_id = models.CharField(max_length=100, blank=True)
    details     = models.JSONField(default=dict, blank=True)
    ip          = models.GenericIPAddressField(null=True, blank=True)
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
