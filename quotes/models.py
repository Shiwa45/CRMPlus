# quotes/models.py  ← FULL REPLACEMENT  (tenant FK removed — schema = isolation)
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from decimal import Decimal

User = get_user_model()


# ── Tax / Billing Profile ─────────────────────────────────────────────────────

class TaxProfile(models.Model):
    """Sender (company) details printed on quotes and invoices."""
    name         = models.CharField(max_length=200)
    gstin        = models.CharField(max_length=20, blank=True)
    pan          = models.CharField(max_length=20, blank=True)
    address      = models.TextField(blank=True)
    city         = models.CharField(max_length=100, blank=True)
    state        = models.CharField(max_length=100, blank=True)
    state_code   = models.CharField(max_length=5, blank=True)
    postal_code  = models.CharField(max_length=20, blank=True)
    country      = models.CharField(max_length=100, default='India')
    phone        = models.CharField(max_length=20, blank=True)
    email        = models.EmailField(blank=True)
    rate         = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal('18.00'),
                                       help_text='Default GST rate %')

    # Banking
    bank_name    = models.CharField(max_length=200, blank=True)
    bank_account = models.CharField(max_length=50, blank=True)
    bank_ifsc    = models.CharField(max_length=20, blank=True)
    bank_branch  = models.CharField(max_length=200, blank=True)
    upi_id       = models.CharField(max_length=100, blank=True)

    is_default   = models.BooleanField(default=False)
    created_by   = models.ForeignKey(User, on_delete=models.SET_NULL,
                                     null=True, related_name='created_tax_profiles')
    created_at   = models.DateTimeField(auto_now_add=True)
    updated_at   = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name


# ── Product / Service ─────────────────────────────────────────────────────────

class Product(models.Model):
    UNIT_CHOICES = [
        ('unit', 'Unit'), ('hour', 'Hour'), ('day', 'Day'),
        ('month', 'Month'), ('year', 'Year'), ('license', 'License'),
    ]

    name        = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    sku         = models.CharField(max_length=100, blank=True)
    price       = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    unit        = models.CharField(max_length=20, choices=UNIT_CHOICES, default='unit')
    hsn_sac     = models.CharField(max_length=20, blank=True,
                                   help_text='HSN / SAC code for GST')
    tax_profile = models.ForeignKey(TaxProfile, on_delete=models.SET_NULL,
                                    null=True, blank=True, related_name='products')
    is_active   = models.BooleanField(default=True)
    created_by  = models.ForeignKey(User, on_delete=models.SET_NULL,
                                    null=True, related_name='created_products')
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name


# ── Quote ─────────────────────────────────────────────────────────────────────

class Quote(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'), ('sent', 'Sent'), ('viewed', 'Viewed'),
        ('accepted', 'Accepted'), ('rejected', 'Rejected'), ('expired', 'Expired'),
    ]
    SUPPLY_TYPE_CHOICES = [
        ('intra', 'Intra-state'), ('inter', 'Inter-state'), ('export', 'Export'),
    ]

    title           = models.CharField(max_length=300)
    quote_number    = models.CharField(max_length=50, blank=True, unique=True)
    status          = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')

    # Relations
    contact         = models.ForeignKey('contacts.Contact', on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='quotes')
    company         = models.ForeignKey('contacts.Company', on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='quotes')
    deal            = models.ForeignKey('deals.Deal', on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='quotes')
    tax_profile     = models.ForeignKey(TaxProfile, on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='quotes')

    # Billing address
    bill_to_name    = models.CharField(max_length=200, blank=True)
    bill_to_gstin   = models.CharField(max_length=20, blank=True)
    bill_to_address = models.TextField(blank=True)
    bill_to_city    = models.CharField(max_length=100, blank=True)
    bill_to_state   = models.CharField(max_length=100, blank=True)
    bill_to_pincode = models.CharField(max_length=20, blank=True)
    supply_type     = models.CharField(max_length=10, choices=SUPPLY_TYPE_CHOICES,
                                       default='intra')

    # Totals (auto-computed)
    subtotal        = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    discount_amount = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    tax_amount      = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    total           = models.DecimalField(max_digits=15, decimal_places=2, default=0)

    valid_until     = models.DateField(null=True, blank=True)
    terms           = models.TextField(blank=True)
    notes           = models.TextField(blank=True)

    created_by      = models.ForeignKey(User, on_delete=models.SET_NULL,
                                        null=True, related_name='created_quotes')
    created_at      = models.DateTimeField(auto_now_add=True)
    updated_at      = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.quote_number or self.title}'

    def save(self, *args, **kwargs):
        if not self.quote_number:
            count = Quote.objects.count() + 1
            self.quote_number = f'QT-{count:05d}'
        super().save(*args, **kwargs)


class QuoteItem(models.Model):
    quote       = models.ForeignKey(Quote, on_delete=models.CASCADE, related_name='items')
    product     = models.ForeignKey(Product, on_delete=models.SET_NULL,
                                    null=True, blank=True, related_name='quote_items')
    description = models.CharField(max_length=300, blank=True)
    quantity    = models.DecimalField(max_digits=10, decimal_places=2, default=1)
    unit_price  = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    discount_pct = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    tax_rate    = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    amount      = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    order       = models.IntegerField(default=0)

    class Meta:
        ordering = ['order']

    def save(self, *args, **kwargs):
        discounted = self.unit_price * (1 - self.discount_pct / Decimal('100'))
        self.amount = self.quantity * discounted
        super().save(*args, **kwargs)


# ── Invoice ───────────────────────────────────────────────────────────────────

class Invoice(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'), ('sent', 'Sent'), ('partially_paid', 'Partially Paid'),
        ('paid', 'Paid'), ('overdue', 'Overdue'), ('cancelled', 'Cancelled'),
    ]

    title           = models.CharField(max_length=300)
    invoice_number  = models.CharField(max_length=50, blank=True, unique=True)
    status          = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    quote           = models.ForeignKey(Quote, on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='invoices')
    contact         = models.ForeignKey('contacts.Contact', on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='invoices')
    company         = models.ForeignKey('contacts.Company', on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='invoices')
    tax_profile     = models.ForeignKey(TaxProfile, on_delete=models.SET_NULL,
                                        null=True, blank=True, related_name='invoices')

    subtotal        = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    discount_amount = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    tax_amount      = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    total           = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    amount_paid     = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    amount_due      = models.DecimalField(max_digits=15, decimal_places=2, default=0)

    issue_date      = models.DateField(default=timezone.now)
    due_date        = models.DateField(null=True, blank=True)
    paid_date       = models.DateField(null=True, blank=True)
    terms           = models.TextField(blank=True)
    notes           = models.TextField(blank=True)

    created_by      = models.ForeignKey(User, on_delete=models.SET_NULL,
                                        null=True, related_name='created_invoices')
    created_at      = models.DateTimeField(auto_now_add=True)
    updated_at      = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.invoice_number or self.title}'

    def save(self, *args, **kwargs):
        if not self.invoice_number:
            count = Invoice.objects.count() + 1
            self.invoice_number = f'INV-{count:05d}'
        self.amount_due = self.total - self.amount_paid
        super().save(*args, **kwargs)


class InvoiceItem(models.Model):
    invoice     = models.ForeignKey(Invoice, on_delete=models.CASCADE, related_name='items')
    product     = models.ForeignKey(Product, on_delete=models.SET_NULL,
                                    null=True, blank=True)
    description = models.CharField(max_length=300, blank=True)
    quantity    = models.DecimalField(max_digits=10, decimal_places=2, default=1)
    unit_price  = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    discount_pct = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    tax_rate    = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    amount      = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    order       = models.IntegerField(default=0)

    class Meta:
        ordering = ['order']


class Payment(models.Model):
    METHOD_CHOICES = [
        ('cash', 'Cash'), ('bank_transfer', 'Bank Transfer'),
        ('upi', 'UPI'), ('cheque', 'Cheque'), ('card', 'Card'),
        ('online', 'Online Gateway'),
    ]

    invoice         = models.ForeignKey(Invoice, on_delete=models.CASCADE,
                                        related_name='payments')
    amount          = models.DecimalField(max_digits=15, decimal_places=2)
    method          = models.CharField(max_length=20, choices=METHOD_CHOICES, default='bank_transfer')
    reference       = models.CharField(max_length=200, blank=True)
    payment_date    = models.DateField(default=timezone.now)
    notes           = models.TextField(blank=True)
    received_by     = models.ForeignKey(User, on_delete=models.SET_NULL,
                                        null=True, related_name='received_payments')
    created_at      = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-payment_date']

    def __str__(self):
        return f'₹{self.amount} — {self.invoice}'
