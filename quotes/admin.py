# quotes/admin.py
from django.contrib import admin
from .models import TaxProfile, Product, Quote, QuoteItem, Invoice, InvoiceItem, Payment


@admin.register(TaxProfile)
class TaxProfileAdmin(admin.ModelAdmin):
    list_display = ['name', 'gstin', 'pan', 'city', 'state', 'is_default']
    search_fields = ['name', 'gstin', 'pan']


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display  = ['name', 'sku', 'price', 'unit', 'is_active', 'created_at']
    list_filter   = ['is_active', 'unit']
    search_fields = ['name', 'sku', 'hsn_sac']


class QuoteItemInline(admin.TabularInline):
    model  = QuoteItem
    extra  = 1
    fields = ['product', 'description', 'quantity', 'unit_price', 'discount_pct', 'tax_rate', 'amount']
    readonly_fields = ['amount']


@admin.register(Quote)
class QuoteAdmin(admin.ModelAdmin):
    list_display  = ['quote_number', 'title', 'status', 'bill_to_name', 'total', 'created_at']
    list_filter   = ['status', 'supply_type']
    search_fields = ['quote_number', 'title', 'bill_to_name']
    readonly_fields = ['quote_number', 'subtotal', 'discount_amount', 'tax_amount',
                       'total', 'created_at', 'updated_at']
    inlines = [QuoteItemInline]


class InvoiceItemInline(admin.TabularInline):
    model  = InvoiceItem
    extra  = 1
    fields = ['product', 'description', 'quantity', 'unit_price', 'tax_rate', 'amount']
    readonly_fields = ['amount']


class PaymentInline(admin.TabularInline):
    model  = Payment
    extra  = 0
    readonly_fields = ['created_at']


@admin.register(Invoice)
class InvoiceAdmin(admin.ModelAdmin):
    list_display  = ['invoice_number', 'title', 'status', 'total',
                     'amount_paid', 'amount_due', 'due_date']
    list_filter   = ['status']
    search_fields = ['invoice_number', 'title']
    readonly_fields = ['invoice_number', 'amount_paid', 'amount_due', 'created_at', 'updated_at']
    inlines = [InvoiceItemInline, PaymentInline]
