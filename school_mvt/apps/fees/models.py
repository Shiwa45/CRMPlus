from django.db import models
from django.conf import settings


class FeeType(models.Model):
    name = models.CharField(max_length=100)  # Tuition, Transport, etc.
    code = models.CharField(max_length=20, unique=True)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return self.name

    class Meta:
        db_table = 'fee_types'


class FeeStructure(models.Model):
    school_class = models.ForeignKey('academics.Class', on_delete=models.CASCADE)
    fee_type = models.ForeignKey(FeeType, on_delete=models.CASCADE)
    academic_year = models.CharField(max_length=10, default='2024-25')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    due_date = models.DateField(null=True, blank=True)
    late_fee_per_day = models.DecimalField(max_digits=6, decimal_places=2, default=0)
    is_installment_allowed = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.school_class} | {self.fee_type} | ₹{self.amount}"

    class Meta:
        db_table = 'fee_structures'
        unique_together = ('school_class', 'fee_type', 'academic_year')


class FeePayment(models.Model):
    PAYMENT_MODE_CHOICES = [
        ('cash', 'Cash'), ('cheque', 'Cheque'), ('dd', 'DD'),
        ('online', 'Online/UPI'), ('neft', 'NEFT/RTGS'), ('card', 'Card'),
    ]
    STATUS_CHOICES = [
        ('paid', 'Paid'), ('pending', 'Pending'), ('partial', 'Partial'),
        ('refunded', 'Refunded'), ('waived', 'Waived'),
    ]

    receipt_number = models.CharField(max_length=20, unique=True)
    student = models.ForeignKey(
        'students.Student', on_delete=models.CASCADE, related_name='fee_payments'
    )
    fee_type = models.ForeignKey(FeeType, on_delete=models.PROTECT)
    academic_year = models.CharField(max_length=10, default='2024-25')
    amount_due = models.DecimalField(max_digits=10, decimal_places=2)
    amount_paid = models.DecimalField(max_digits=10, decimal_places=2)
    late_fee = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    concession = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    payment_date = models.DateField()
    payment_mode = models.CharField(max_length=10, choices=PAYMENT_MODE_CHOICES, default='cash')
    transaction_id = models.CharField(max_length=50, blank=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='paid')
    collected_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True
    )
    remarks = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Receipt #{self.receipt_number} | {self.student}"

    class Meta:
        db_table = 'fee_payments'
        ordering = ['-payment_date']


class Concession(models.Model):
    CONCESSION_TYPE_CHOICES = [
        ('scholarship', 'Scholarship'), ('sibling', 'Sibling Discount'),
        ('merit', 'Merit'), ('staff_ward', 'Staff Ward'),
        ('financial_aid', 'Financial Aid'), ('category', 'Category-based'),
    ]
    student = models.ForeignKey(
        'students.Student', on_delete=models.CASCADE, related_name='concessions'
    )
    concession_type = models.CharField(max_length=20, choices=CONCESSION_TYPE_CHOICES)
    fee_type = models.ForeignKey(FeeType, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    percentage = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    academic_year = models.CharField(max_length=10, default='2024-25')
    approved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True
    )
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = 'concessions'
