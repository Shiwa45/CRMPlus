# contacts/models.py  ← FULL REPLACEMENT  (tenant FK removed — schema = isolation)
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()


class Company(models.Model):
    EMPLOYEE_SIZE_CHOICES = [
        ('1-10', '1-10'), ('11-50', '11-50'), ('51-200', '51-200'),
        ('201-500', '201-500'), ('501-1000', '501-1000'), ('1000+', '1000+'),
    ]
    INDUSTRY_CHOICES = [
        ('technology', 'Technology'), ('manufacturing', 'Manufacturing'),
        ('retail', 'Retail'), ('healthcare', 'Healthcare'), ('finance', 'Finance'),
        ('education', 'Education'), ('real_estate', 'Real Estate'),
        ('pharma', 'Pharma'), ('automotive', 'Automotive'), ('fmcg', 'FMCG'),
        ('other', 'Other'),
    ]

    name             = models.CharField(max_length=200)
    website          = models.URLField(blank=True, null=True)
    phone            = models.CharField(max_length=20, blank=True, null=True)
    email            = models.EmailField(blank=True, null=True)
    industry         = models.CharField(max_length=50, choices=INDUSTRY_CHOICES,
                                        blank=True, null=True)
    employee_size    = models.CharField(max_length=20, choices=EMPLOYEE_SIZE_CHOICES,
                                        blank=True, null=True)
    annual_revenue   = models.DecimalField(max_digits=15, decimal_places=2,
                                           blank=True, null=True)
    gstin            = models.CharField(max_length=20, blank=True)
    pan              = models.CharField(max_length=20, blank=True)
    description      = models.TextField(blank=True)
    logo             = models.ImageField(upload_to='company_logos/', blank=True, null=True)
    tags             = models.JSONField(default=list, blank=True)

    # Address
    address_line1    = models.CharField(max_length=255, blank=True)
    address_line2    = models.CharField(max_length=255, blank=True)
    city             = models.CharField(max_length=100, blank=True)
    state            = models.CharField(max_length=100, blank=True)
    postal_code      = models.CharField(max_length=20, blank=True)
    country          = models.CharField(max_length=100, default='India')

    # Ownership
    owner            = models.ForeignKey(User, on_delete=models.SET_NULL,
                                         null=True, blank=True, related_name='owned_companies')
    created_by       = models.ForeignKey(User, on_delete=models.SET_NULL,
                                         null=True, related_name='created_companies')
    created_at       = models.DateTimeField(auto_now_add=True)
    updated_at       = models.DateTimeField(auto_now=True)

    class Meta:
        ordering   = ['name']
        verbose_name_plural = 'Companies'

    def __str__(self):
        return self.name

    @property
    def contact_count(self):
        return self.contacts.count()


class Contact(models.Model):
    SALUTATION_CHOICES = [
        ('mr', 'Mr.'), ('mrs', 'Mrs.'), ('ms', 'Ms.'),
        ('dr', 'Dr.'), ('prof', 'Prof.'),
    ]

    salutation       = models.CharField(max_length=10, choices=SALUTATION_CHOICES,
                                        blank=True, null=True)
    first_name       = models.CharField(max_length=100)
    last_name        = models.CharField(max_length=100, blank=True)
    job_title        = models.CharField(max_length=150, blank=True)
    department       = models.CharField(max_length=100, blank=True)
    company          = models.ForeignKey(Company, on_delete=models.SET_NULL,
                                         null=True, blank=True, related_name='contacts')

    # Contact info
    email            = models.EmailField(blank=True)
    email_secondary  = models.EmailField(blank=True)
    phone            = models.CharField(max_length=20, blank=True)
    mobile           = models.CharField(max_length=20, blank=True)
    whatsapp         = models.CharField(max_length=20, blank=True)

    # Social
    linkedin         = models.URLField(blank=True)
    twitter          = models.CharField(max_length=100, blank=True)

    # Address
    address_line1    = models.CharField(max_length=255, blank=True)
    address_line2    = models.CharField(max_length=255, blank=True)
    city             = models.CharField(max_length=100, blank=True)
    state            = models.CharField(max_length=100, blank=True)
    postal_code      = models.CharField(max_length=20, blank=True)
    country          = models.CharField(max_length=100, default='India')

    # Status
    tags             = models.JSONField(default=list, blank=True)
    is_active        = models.BooleanField(default=True)
    do_not_contact   = models.BooleanField(default=False)
    last_contacted   = models.DateTimeField(null=True, blank=True)
    notes            = models.TextField(blank=True)
    profile_picture  = models.ImageField(upload_to='contact_pics/', blank=True, null=True)

    # Ownership
    owner            = models.ForeignKey(User, on_delete=models.SET_NULL,
                                         null=True, blank=True, related_name='owned_contacts')
    created_by       = models.ForeignKey(User, on_delete=models.SET_NULL,
                                         null=True, related_name='created_contacts')
    created_at       = models.DateTimeField(auto_now_add=True)
    updated_at       = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['first_name', 'last_name']

    def __str__(self):
        return f'{self.first_name} {self.last_name}'.strip()

    def get_full_name(self):
        return f'{self.first_name} {self.last_name}'.strip()


class ContactDocument(models.Model):
    contact     = models.ForeignKey(Contact, on_delete=models.CASCADE,
                                    related_name='documents')
    name        = models.CharField(max_length=200)
    file        = models.FileField(upload_to='contact_docs/')
    file_type   = models.CharField(max_length=50, blank=True)
    uploaded_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    created_at  = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.name} — {self.contact}'


class ContactActivity(models.Model):
    ACTIVITY_TYPES = [
        ('call', 'Phone Call'), ('email', 'Email'),
        ('meeting', 'Meeting'), ('note', 'Note'),
        ('whatsapp', 'WhatsApp'), ('task', 'Task'),
    ]

    contact       = models.ForeignKey(Contact, on_delete=models.CASCADE,
                                      related_name='activities')
    activity_type = models.CharField(max_length=20, choices=ACTIVITY_TYPES)
    subject       = models.CharField(max_length=200, blank=True)
    description   = models.TextField(blank=True)
    outcome       = models.CharField(max_length=200, blank=True)
    performed_by  = models.ForeignKey(User, on_delete=models.SET_NULL, null=True,
                                      related_name='contact_activities')
    scheduled_at  = models.DateTimeField(null=True, blank=True)
    completed_at  = models.DateTimeField(null=True, blank=True)
    created_at    = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.activity_type} — {self.contact}'
