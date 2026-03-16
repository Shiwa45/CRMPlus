# contacts/models.py
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()


class Company(models.Model):
    INDUSTRY_CHOICES = [
        ('technology', 'Technology'), ('manufacturing', 'Manufacturing'),
        ('retail', 'Retail'), ('healthcare', 'Healthcare'),
        ('finance', 'Finance & Banking'), ('education', 'Education'),
        ('real_estate', 'Real Estate'), ('hospitality', 'Hospitality'),
        ('logistics', 'Logistics'), ('agriculture', 'Agriculture'),
        ('textile', 'Textile'), ('pharma', 'Pharmaceuticals'),
        ('automotive', 'Automotive'), ('fmcg', 'FMCG'),
        ('construction', 'Construction'), ('other', 'Other'),
    ]
    SIZE_CHOICES = [
        ('1-10', '1-10'), ('11-50', '11-50'), ('51-200', '51-200'),
        ('201-500', '201-500'), ('501-1000', '501-1000'), ('1000+', '1000+'),
    ]

    name            = models.CharField(max_length=255, unique=True)
    website         = models.URLField(blank=True, null=True)
    phone           = models.CharField(max_length=20, blank=True, null=True)
    email           = models.EmailField(blank=True, null=True)
    industry        = models.CharField(max_length=50, choices=INDUSTRY_CHOICES, blank=True)
    employee_size   = models.CharField(max_length=20, choices=SIZE_CHOICES, blank=True)
    annual_revenue  = models.DecimalField(max_digits=15, decimal_places=2, blank=True, null=True)

    # Indian business fields
    gstin           = models.CharField(max_length=15, blank=True, null=True, verbose_name='GSTIN')
    pan             = models.CharField(max_length=10, blank=True, null=True, verbose_name='PAN')
    cin             = models.CharField(max_length=21, blank=True, null=True, verbose_name='CIN')

    # Address
    address_line1   = models.CharField(max_length=255, blank=True)
    address_line2   = models.CharField(max_length=255, blank=True)
    city            = models.CharField(max_length=100, blank=True)
    state           = models.CharField(max_length=100, blank=True)
    country         = models.CharField(max_length=100, default='India')
    postal_code     = models.CharField(max_length=10, blank=True)

    description     = models.TextField(blank=True)
    logo            = models.ImageField(upload_to='company_logos/', blank=True, null=True)

    owner           = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='owned_companies')
    created_by      = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_companies')
    created_at      = models.DateTimeField(auto_now_add=True)
    updated_at      = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']
        verbose_name_plural = 'companies'

    def __str__(self):
        return self.name


class Contact(models.Model):
    SALUTATION_CHOICES = [
        ('mr', 'Mr.'), ('mrs', 'Mrs.'), ('ms', 'Ms.'),
        ('dr', 'Dr.'), ('prof', 'Prof.'),
    ]

    # Basic
    salutation      = models.CharField(max_length=10, choices=SALUTATION_CHOICES, blank=True)
    first_name      = models.CharField(max_length=100)
    last_name       = models.CharField(max_length=100, blank=True)
    job_title       = models.CharField(max_length=150, blank=True)
    department      = models.CharField(max_length=100, blank=True)
    company         = models.ForeignKey(Company, on_delete=models.SET_NULL, null=True, blank=True, related_name='contacts')

    # Contact Details (multiple)
    email           = models.EmailField(blank=True)
    email2          = models.EmailField(blank=True, null=True)
    phone           = models.CharField(max_length=20, blank=True)
    phone2          = models.CharField(max_length=20, blank=True, null=True)
    mobile          = models.CharField(max_length=20, blank=True, null=True)
    whatsapp        = models.CharField(max_length=20, blank=True, null=True)
    linkedin        = models.URLField(blank=True, null=True)
    twitter         = models.CharField(max_length=100, blank=True, null=True)

    # Indian compliance fields
    pan             = models.CharField(max_length=10, blank=True, null=True)
    aadhaar_last4   = models.CharField(max_length=4, blank=True, null=True, help_text='Last 4 digits only')

    # Address
    address_line1   = models.CharField(max_length=255, blank=True)
    city            = models.CharField(max_length=100, blank=True)
    state           = models.CharField(max_length=100, blank=True)
    country         = models.CharField(max_length=100, default='India')
    postal_code     = models.CharField(max_length=10, blank=True)

    # Metadata
    tags            = models.JSONField(default=list, blank=True)
    notes           = models.TextField(blank=True)
    avatar          = models.ImageField(upload_to='contact_avatars/', blank=True, null=True)
    is_active       = models.BooleanField(default=True)
    do_not_contact  = models.BooleanField(default=False)
    dnd_reason      = models.CharField(max_length=255, blank=True)

    owner           = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='owned_contacts')
    created_by      = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_contacts')
    created_at      = models.DateTimeField(auto_now_add=True)
    updated_at      = models.DateTimeField(auto_now=True)
    last_contacted  = models.DateTimeField(blank=True, null=True)

    class Meta:
        ordering = ['first_name', 'last_name']

    def __str__(self):
        return f"{self.first_name} {self.last_name}".strip()

    @property
    def full_name(self):
        parts = [self.salutation, self.first_name, self.last_name]
        return ' '.join(p for p in parts if p).strip()


class ContactDocument(models.Model):
    DOC_TYPE_CHOICES = [
        ('aadhaar', 'Aadhaar Card'), ('pan', 'PAN Card'),
        ('passport', 'Passport'), ('driving_license', 'Driving License'),
        ('gst_certificate', 'GST Certificate'), ('incorporation', 'Certificate of Incorporation'),
        ('other', 'Other'),
    ]
    contact     = models.ForeignKey(Contact, on_delete=models.CASCADE, related_name='documents')
    doc_type    = models.CharField(max_length=30, choices=DOC_TYPE_CHOICES)
    title       = models.CharField(max_length=200)
    file        = models.FileField(upload_to='contact_docs/')
    uploaded_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.contact} - {self.title}"


class ContactActivity(models.Model):
    TYPE_CHOICES = [
        ('call', 'Call'), ('email', 'Email'), ('meeting', 'Meeting'),
        ('whatsapp', 'WhatsApp'), ('note', 'Note'), ('task', 'Task'),
    ]
    contact     = models.ForeignKey(Contact, on_delete=models.CASCADE, related_name='activities')
    activity_type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    subject     = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    outcome     = models.CharField(max_length=255, blank=True)
    performed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    performed_at = models.DateTimeField(default=timezone.now)
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-performed_at']
