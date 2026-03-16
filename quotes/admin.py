# quotes/admin.py
from django.contrib import admin
from .models import TaxProfile, Product, Quote, QuoteItem, Invoice, InvoiceItem, Payment


@admin.register(TaxProfile)
class TaxProfileAdmin(admin.ModelAdmin):
    list_display = ['name', 'gstin', 'pan', 'city', 'state', 'is_active']
    search_fields = ['name', 'gstin', 'pan']


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display  = ['name', 'code', 'product_type', 'unit_price', 'gst_rate', 'hsn_sac_code', 'is_active']
    list_filter   = ['product_type', 'gst_rate', 'is_active']
    search_fields = ['name', 'code', 'hsn_sac_code']


class QuoteItemInline(admin.TabularInline):
    model  = QuoteItem
    extra  = 1
    fields = ['name', 'quantity', 'unit', 'unit_price', 'discount_pct', 'gst_rate', 'amount']
    readonly_fields = ['amount']


@admin.register(Quote)
class QuoteAdmin(admin.ModelAdmin):
    list_display  = ['quote_number', 'title', 'status', 'bill_to_name', 'grand_total', 'quote_date']
    list_filter   = ['status', 'supply_type', 'currency']
    search_fields = ['quote_number', 'title', 'bill_to_name', 'bill_to_gstin']
    readonly_fields = ['quote_number', 'subtotal', 'discount_amt', 'taxable_amount',
                       'cgst_total', 'sgst_total', 'igst_total', 'grand_total', 'created_at', 'updated_at']
    inlines = [QuoteItemInline]


class InvoiceItemInline(admin.TabularInline):
    model  = InvoiceItem
    extra  = 1
    fields = ['name', 'quantity', 'unit', 'unit_price', 'gst_rate', 'amount']
    readonly_fields = ['amount']


class PaymentInline(admin.TabularInline):
    model  = Payment
    extra  = 0
    readonly_fields = ['created_at']


@admin.register(Invoice)
class InvoiceAdmin(admin.ModelAdmin):
    list_display  = ['invoice_number', 'status', 'bill_to_name', 'grand_total', 'amount_paid', 'amount_due', 'invoice_date', 'due_date']
    list_filter   = ['status', 'supply_type', 'is_einvoice']
    search_fields = ['invoice_number', 'bill_to_name', 'bill_to_gstin', 'po_number']
    readonly_fields = ['invoice_number', 'amount_paid', 'amount_due', 'created_at', 'updated_at']
    inlines = [InvoiceItemInline, PaymentInline]


# quotes/apps.py
