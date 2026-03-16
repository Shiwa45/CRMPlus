# quotes/models.py
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from contacts.models import Contact, Company
from deals.models import Deal
import uuid

User = get_user_model()

# GST rate choices (India)
GST_RATE_CHOICES = [
    (0, '0%'), (5, '5%'), (12, '12%'), (18, '18%'), (28, '28%'),
]

INDIAN_STATES = [
    ('AN', 'Andaman and Nicobar Islands'), ('AP', 'Andhra Pradesh'),
    ('AR', 'Arunachal Pradesh'), ('AS', 'Assam'), ('BR', 'Bihar'),
    ('CH', 'Chandigarh'), ('CT', 'Chhattisgarh'), ('DN', 'Dadra and Nagar Haveli'),
    ('DD', 'Daman and Diu'), ('DL', 'Delhi'), ('GA', 'Goa'),
    ('GJ', 'Gujarat'), ('HR', 'Haryana'), ('HP', 'Himachal Pradesh'),
    ('JK', 'Jammu and Kashmir'), ('JH', 'Jharkhand'), ('KA', 'Karnataka'),
    ('KL', 'Kerala'), ('LA', 'Ladakh'), ('LD', 'Lakshadweep'),
    ('MP', 'Madhya Pradesh'), ('MH', 'Maharashtra'), ('MN', 'Manipur'),
    ('ML', 'Meghalaya'), ('MZ', 'Mizoram'), ('NL', 'Nagaland'),
    ('OR', 'Odisha'), ('PY', 'Puducherry'), ('PB', 'Punjab'),
    ('RJ', 'Rajasthan'), ('SK', 'Sikkim'), ('TN', 'Tamil Nadu'),
    ('TG', 'Telangana'), ('TR', 'Tripura'), ('UP', 'Uttar Pradesh'),
    ('UK', 'Uttarakhand'), ('WB', 'West Bengal'),
]


def generate_quote_number():
    from django.utils import timezone
    import random
    return f"QT-{timezone.now().strftime('%Y%m')}-{random.randint(1000, 9999)}"


def generate_invoice_number():
    from django.utils import timezone
    import random
    return f"INV-{timezone.now().strftime('%Y%m')}-{random.randint(1000, 9999)}"


class TaxProfile(models.Model):
    """Your company's tax profile for generating GST invoices"""
    name          = models.CharField(max_length=200)
    gstin         = models.CharField(max_length=15)
    pan           = models.CharField(max_length=10)
    address       = models.TextField()
    city          = models.CharField(max_length=100)
    state         = models.CharField(max_length=2, choices=INDIAN_STATES)
    postal_code   = models.CharField(max_length=6)
    phone         = models.CharField(max_length=15, blank=True)
    email         = models.EmailField(blank=True)
    bank_name     = models.CharField(max_length=200, blank=True)
    bank_account  = models.CharField(max_length=20, blank=True)
    bank_ifsc     = models.CharField(max_length=11, blank=True)
    bank_branch   = models.CharField(max_length=200, blank=True)
    upi_id        = models.CharField(max_length=100, blank=True)
    logo          = models.ImageField(upload_to='tax_profile_logos/', blank=True, null=True)
    signature     = models.ImageField(upload_to='signatures/', blank=True, null=True)
    is_active     = models.BooleanField(default=True)
    created_at    = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.gstin})"


class Product(models.Model):
    """Product/Service catalog"""
    TYPE_CHOICES = [('product', 'Product'), ('service', 'Service')]
    UNIT_CHOICES = [
        ('nos', 'Nos'), ('pcs', 'Pcs'), ('kg', 'KG'), ('gm', 'Gram'),
        ('ltr', 'Litre'), ('mt', 'Meter'), ('sqft', 'Sq.Ft'),
        ('hr', 'Hour'), ('day', 'Day'), ('month', 'Month'),
        ('unit', 'Unit'), ('box', 'Box'), ('set', 'Set'),
    ]

    name          = models.CharField(max_length=255)
    code          = models.CharField(max_length=50, unique=True)
    product_type  = models.CharField(max_length=10, choices=TYPE_CHOICES, default='service')
    description   = models.TextField(blank=True)
    hsn_sac_code  = models.CharField(max_length=10, blank=True, help_text='HSN/SAC code for GST')
    unit          = models.CharField(max_length=10, choices=UNIT_CHOICES, default='nos')
    unit_price    = models.DecimalField(max_digits=12, decimal_places=2)
    gst_rate      = models.PositiveIntegerField(choices=GST_RATE_CHOICES, default=18)
    cess_rate     = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    is_active     = models.BooleanField(default=True)
    created_by    = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    created_at    = models.DateTimeField(auto_now_add=True)
    updated_at    = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.code})"


class Quote(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'), ('sent', 'Sent'), ('viewed', 'Viewed'),
        ('accepted', 'Accepted'), ('rejected', 'Rejected'), ('expired', 'Expired'),
        ('converted', 'Converted to Invoice'),
    ]
    SUPPLY_TYPE_CHOICES = [
        ('intra', 'Intra-State'), ('inter', 'Inter-State'), ('export', 'Export'),
    ]

    quote_number  = models.CharField(max_length=30, unique=True, default=generate_quote_number)
    title         = models.CharField(max_length=300)
    status        = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')

    # Parties
    tax_profile   = models.ForeignKey(TaxProfile, on_delete=models.PROTECT, related_name='quotes')
    contact       = models.ForeignKey(Contact, on_delete=models.SET_NULL, null=True, blank=True, related_name='quotes')
    company       = models.ForeignKey(Company, on_delete=models.SET_NULL, null=True, blank=True, related_name='quotes')
    deal          = models.ForeignKey(Deal, on_delete=models.SET_NULL, null=True, blank=True, related_name='quotes')

    # Bill-to address
    bill_to_name  = models.CharField(max_length=300)
    bill_to_gstin = models.CharField(max_length=15, blank=True)
    bill_to_addr  = models.TextField(blank=True)
    bill_to_city  = models.CharField(max_length=100, blank=True)
    bill_to_state = models.CharField(max_length=2, choices=INDIAN_STATES, blank=True)
    bill_to_pin   = models.CharField(max_length=6, blank=True)

    # GST type
    supply_type   = models.CharField(max_length=10, choices=SUPPLY_TYPE_CHOICES, default='intra')

    # Dates
    quote_date    = models.DateField(default=timezone.now)
    valid_until   = models.DateField(blank=True, null=True)

    # Totals (auto-calculated)
    subtotal      = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    discount_pct  = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    discount_amt  = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    taxable_amount = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    cgst_total    = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    sgst_total    = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    igst_total    = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    cess_total    = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    round_off     = models.DecimalField(max_digits=6, decimal_places=2, default=0)
    grand_total   = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    currency      = models.CharField(max_length=3, default='INR')

    # Content
    terms         = models.TextField(blank=True)
    notes         = models.TextField(blank=True)

    # Tracking
    sent_at       = models.DateTimeField(blank=True, null=True)
    viewed_at     = models.DateTimeField(blank=True, null=True)
    accepted_at   = models.DateTimeField(blank=True, null=True)

    owner         = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='owned_quotes')
    created_by    = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_quotes')
    created_at    = models.DateTimeField(auto_now_add=True)
    updated_at    = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.quote_number} - {self.title}"

    def calculate_totals(self):
        items = self.items.all()
        subtotal = sum(i.amount for i in items)
        discount_amt = (subtotal * self.discount_pct / 100)
        taxable = subtotal - discount_amt
        is_intra = self.supply_type == 'intra'
        cgst = sgst = igst = cess = 0
        for item in items:
            item_taxable = item.amount - (item.amount * self.discount_pct / 100)
            tax_amt = item_taxable * item.gst_rate / 100
            if is_intra:
                cgst += tax_amt / 2
                sgst += tax_amt / 2
            else:
                igst += tax_amt
            cess += item_taxable * item.cess_rate / 100
        total = taxable + cgst + sgst + igst + cess
        round_off = round(total) - total
        self.subtotal = subtotal
        self.discount_amt = discount_amt
        self.taxable_amount = taxable
        self.cgst_total = round(cgst, 2)
        self.sgst_total = round(sgst, 2)
        self.igst_total = round(igst, 2)
        self.cess_total = round(cess, 2)
        self.round_off = round(round_off, 2)
        self.grand_total = round(total + round_off, 2)
        self.save(update_fields=[
            'subtotal', 'discount_amt', 'taxable_amount',
            'cgst_total', 'sgst_total', 'igst_total', 'cess_total',
            'round_off', 'grand_total'
        ])


class QuoteItem(models.Model):
    quote         = models.ForeignKey(Quote, on_delete=models.CASCADE, related_name='items')
    product       = models.ForeignKey(Product, on_delete=models.SET_NULL, null=True, blank=True)
    name          = models.CharField(max_length=300)
    description   = models.TextField(blank=True)
    hsn_sac_code  = models.CharField(max_length=10, blank=True)
    quantity      = models.DecimalField(max_digits=10, decimal_places=3, default=1)
    unit          = models.CharField(max_length=20, default='nos')
    unit_price    = models.DecimalField(max_digits=12, decimal_places=2)
    discount_pct  = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    gst_rate      = models.PositiveIntegerField(choices=GST_RATE_CHOICES, default=18)
    cess_rate     = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    amount        = models.DecimalField(max_digits=15, decimal_places=2, default=0)  # qty * price - discount
    order         = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['order']

    def save(self, *args, **kwargs):
        self.amount = round(self.quantity * self.unit_price * (1 - self.discount_pct / 100), 2)
        super().save(*args, **kwargs)


class Invoice(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'), ('sent', 'Sent'), ('partial', 'Partially Paid'),
        ('paid', 'Paid'), ('overdue', 'Overdue'), ('cancelled', 'Cancelled'),
        ('credit_note', 'Credit Note'),
    ]

    invoice_number = models.CharField(max_length=30, unique=True, default=generate_invoice_number)
    quote          = models.OneToOneField(Quote, on_delete=models.SET_NULL, null=True, blank=True, related_name='invoice')
    status         = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    is_einvoice    = models.BooleanField(default=False, verbose_name='E-Invoice')
    irn            = models.CharField(max_length=100, blank=True, verbose_name='IRN')  # E-invoice reference

    # Same structure as Quote for denormalization
    tax_profile    = models.ForeignKey(TaxProfile, on_delete=models.PROTECT, related_name='invoices')
    contact        = models.ForeignKey(Contact, on_delete=models.SET_NULL, null=True, blank=True, related_name='invoices')
    company        = models.ForeignKey(Company, on_delete=models.SET_NULL, null=True, blank=True, related_name='invoices')
    deal           = models.ForeignKey(Deal, on_delete=models.SET_NULL, null=True, blank=True, related_name='invoices')
    supply_type    = models.CharField(max_length=10, default='intra')

    bill_to_name   = models.CharField(max_length=300)
    bill_to_gstin  = models.CharField(max_length=15, blank=True)
    bill_to_addr   = models.TextField(blank=True)
    bill_to_city   = models.CharField(max_length=100, blank=True)
    bill_to_state  = models.CharField(max_length=2, choices=INDIAN_STATES, blank=True)
    bill_to_pin    = models.CharField(max_length=6, blank=True)

    invoice_date   = models.DateField(default=timezone.now)
    due_date       = models.DateField(blank=True, null=True)
    po_number      = models.CharField(max_length=100, blank=True, verbose_name='PO Number')

    subtotal       = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    discount_pct   = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    discount_amt   = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    taxable_amount = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    cgst_total     = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    sgst_total     = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    igst_total     = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    cess_total     = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    round_off      = models.DecimalField(max_digits=6, decimal_places=2, default=0)
    grand_total    = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    amount_paid    = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    amount_due     = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    currency       = models.CharField(max_length=3, default='INR')

    terms          = models.TextField(blank=True)
    notes          = models.TextField(blank=True)

    owner          = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='owned_invoices')
    created_by     = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_invoices')
    created_at     = models.DateTimeField(auto_now_add=True)
    updated_at     = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.invoice_number} - ₹{self.grand_total}"

    def update_payment_status(self):
        paid = self.payments.filter(status='confirmed').aggregate(
            t=models.Sum('amount'))['t'] or 0
        self.amount_paid = paid
        self.amount_due  = self.grand_total - paid
        if self.amount_due <= 0:
            self.status = 'paid'
        elif self.amount_paid > 0:
            self.status = 'partial'
        self.save(update_fields=['amount_paid', 'amount_due', 'status'])


class InvoiceItem(models.Model):
    invoice       = models.ForeignKey(Invoice, on_delete=models.CASCADE, related_name='items')
    product       = models.ForeignKey(Product, on_delete=models.SET_NULL, null=True, blank=True)
    name          = models.CharField(max_length=300)
    description   = models.TextField(blank=True)
    hsn_sac_code  = models.CharField(max_length=10, blank=True)
    quantity      = models.DecimalField(max_digits=10, decimal_places=3, default=1)
    unit          = models.CharField(max_length=20, default='nos')
    unit_price    = models.DecimalField(max_digits=12, decimal_places=2)
    discount_pct  = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    gst_rate      = models.PositiveIntegerField(choices=GST_RATE_CHOICES, default=18)
    cess_rate     = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    amount        = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    order         = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['order']

    def save(self, *args, **kwargs):
        self.amount = round(self.quantity * self.unit_price * (1 - self.discount_pct / 100), 2)
        super().save(*args, **kwargs)


class Payment(models.Model):
    METHOD_CHOICES = [
        ('upi', 'UPI'), ('neft', 'NEFT'), ('rtgs', 'RTGS'),
        ('imps', 'IMPS'), ('cheque', 'Cheque'), ('cash', 'Cash'),
        ('card', 'Card'), ('razorpay', 'Razorpay'),
        ('payu', 'PayU'), ('cashfree', 'Cashfree'),
    ]
    STATUS_CHOICES = [
        ('pending', 'Pending'), ('confirmed', 'Confirmed'), ('failed', 'Failed'),
    ]

    invoice       = models.ForeignKey(Invoice, on_delete=models.CASCADE, related_name='payments')
    amount        = models.DecimalField(max_digits=15, decimal_places=2)
    method        = models.CharField(max_length=20, choices=METHOD_CHOICES)
    status        = models.CharField(max_length=20, choices=STATUS_CHOICES, default='confirmed')
    transaction_id = models.CharField(max_length=200, blank=True)
    reference     = models.CharField(max_length=200, blank=True)
    payment_date  = models.DateField(default=timezone.now)
    notes         = models.TextField(blank=True)
    recorded_by   = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    created_at    = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        self.invoice.update_payment_status()
