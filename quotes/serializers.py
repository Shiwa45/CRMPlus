# quotes/serializers.py
from rest_framework import serializers
from .models import TaxProfile, Product, Quote, QuoteItem, Invoice, InvoiceItem, Payment


class TaxProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model  = TaxProfile
        fields = '__all__'


class ProductSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)

    class Meta:
        model  = Product
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at', 'updated_at']

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class QuoteItemSerializer(serializers.ModelSerializer):
    class Meta:
        model  = QuoteItem
        fields = '__all__'
        read_only_fields = ['amount']


class QuoteSerializer(serializers.ModelSerializer):
    items          = QuoteItemSerializer(many=True)
    contact_name   = serializers.SerializerMethodField()
    company_name   = serializers.CharField(source='company.name', read_only=True)
    tax_profile_name = serializers.CharField(source='tax_profile.name', read_only=True)
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)

    class Meta:
        model  = Quote
        fields = '__all__'
        read_only_fields = [
            'quote_number', 'created_by',
            'subtotal', 'discount_amount', 'tax_amount', 'total',
            'created_at', 'updated_at',
        ]

    def get_contact_name(self, obj):
        return obj.contact.get_full_name() if obj.contact else None

    def _recalc_totals(self, quote):
        subtotal = 0
        discount_amount = 0
        tax_amount = 0
        for item in quote.items.all():
            line_base = item.quantity * item.unit_price
            line_discount = line_base * (item.discount_pct / 100)
            line_subtotal = line_base - line_discount
            line_tax = line_subtotal * (item.tax_rate / 100)
            subtotal += line_subtotal
            discount_amount += line_discount
            tax_amount += line_tax
        quote.subtotal = subtotal
        quote.discount_amount = discount_amount
        quote.tax_amount = tax_amount
        quote.total = subtotal + tax_amount
        quote.save(update_fields=['subtotal', 'discount_amount', 'tax_amount', 'total', 'updated_at'])

    def create(self, validated_data):
        items_data = validated_data.pop('items', [])
        validated_data['created_by'] = self.context['request'].user
        quote = Quote.objects.create(**validated_data)
        for item_data in items_data:
            QuoteItem.objects.create(quote=quote, **item_data)
        self._recalc_totals(quote)
        return quote

    def update(self, instance, validated_data):
        items_data = validated_data.pop('items', None)
        instance = super().update(instance, validated_data)
        if items_data is not None:
            instance.items.all().delete()
            for item_data in items_data:
                QuoteItem.objects.create(quote=instance, **item_data)
        self._recalc_totals(instance)
        return instance


class QuoteListSerializer(serializers.ModelSerializer):
    contact_name = serializers.SerializerMethodField()
    company_name = serializers.CharField(source='company.name', read_only=True)
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)

    class Meta:
        model  = Quote
        fields = ['id', 'quote_number', 'title', 'status', 'contact_name', 'company_name',
                  'created_by_name', 'valid_until', 'total', 'created_at']

    def get_contact_name(self, obj):
        return obj.contact.get_full_name() if obj.contact else None


class InvoiceItemSerializer(serializers.ModelSerializer):
    class Meta:
        model  = InvoiceItem
        fields = '__all__'
        read_only_fields = ['amount']


class PaymentSerializer(serializers.ModelSerializer):
    received_by_name = serializers.CharField(source='received_by.get_full_name', read_only=True)

    class Meta:
        model  = Payment
        fields = '__all__'
        read_only_fields = ['received_by', 'created_at']

    def create(self, validated_data):
        validated_data['received_by'] = self.context['request'].user
        return super().create(validated_data)


class InvoiceSerializer(serializers.ModelSerializer):
    items          = InvoiceItemSerializer(many=True)
    payments       = PaymentSerializer(many=True, read_only=True)
    contact_name   = serializers.SerializerMethodField()
    company_name   = serializers.CharField(source='company.name', read_only=True)
    tax_profile_name = serializers.CharField(source='tax_profile.name', read_only=True)
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)

    class Meta:
        model  = Invoice
        fields = '__all__'
        read_only_fields = [
            'invoice_number', 'created_by',
            'amount_paid', 'amount_due',
            'created_at', 'updated_at',
        ]

    def get_contact_name(self, obj):
        return obj.contact.get_full_name() if obj.contact else None

    def _recalc_totals(self, invoice):
        subtotal = 0
        discount_amount = 0
        tax_amount = 0
        for item in invoice.items.all():
            line_base = item.quantity * item.unit_price
            line_discount = line_base * (item.discount_pct / 100)
            line_subtotal = line_base - line_discount
            line_tax = line_subtotal * (item.tax_rate / 100)
            subtotal += line_subtotal
            discount_amount += line_discount
            tax_amount += line_tax
        invoice.subtotal = subtotal
        invoice.discount_amount = discount_amount
        invoice.tax_amount = tax_amount
        invoice.total = subtotal + tax_amount
        invoice.save(update_fields=['subtotal', 'discount_amount', 'tax_amount', 'total', 'updated_at'])

    def create(self, validated_data):
        items_data = validated_data.pop('items', [])
        validated_data['created_by'] = self.context['request'].user
        invoice = Invoice.objects.create(**validated_data)
        for item_data in items_data:
            InvoiceItem.objects.create(invoice=invoice, **item_data)
        self._recalc_totals(invoice)
        return invoice

    def update(self, instance, validated_data):
        items_data = validated_data.pop('items', None)
        instance = super().update(instance, validated_data)
        if items_data is not None:
            instance.items.all().delete()
            for item_data in items_data:
                InvoiceItem.objects.create(invoice=instance, **item_data)
        self._recalc_totals(instance)
        return instance


class InvoiceListSerializer(serializers.ModelSerializer):
    contact_name = serializers.SerializerMethodField()
    company_name = serializers.CharField(source='company.name', read_only=True)
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)

    class Meta:
        model  = Invoice
        fields = ['id', 'invoice_number', 'status', 'contact_name', 'company_name',
                  'created_by_name', 'issue_date', 'due_date', 'total', 'amount_paid',
                  'amount_due', 'created_at']

    def get_contact_name(self, obj):
        return obj.contact.get_full_name() if obj.contact else None
