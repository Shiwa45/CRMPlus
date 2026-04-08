from django.contrib import admin
from .models import FeeType, FeeStructure, FeePayment

admin.site.register(FeeType)
admin.site.register(FeeStructure)

@admin.register(FeePayment)
class FeePaymentAdmin(admin.ModelAdmin):
    list_display = ["receipt_number", "student", "fee_type", "amount_paid", "payment_date"]
    list_filter = ["payment_mode", "fee_type"]
