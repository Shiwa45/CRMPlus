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
    owner_name     = serializers.CharField(source='owner.get_full_name', read_only=True)

    class Meta:
        model  = Quote
        fields = '__all__'
        read_only_fields = ['quote_number', 'created_by', 'subtotal', 'discount_amt',
                            'taxable_amount', 'cgst_total', 'sgst_total', 'igst_total',
                            'cess_total', 'round_off', 'grand_total', 'created_at', 'updated_at']

    def get_contact_name(self, obj):
        return obj.contact.full_name if obj.contact else None

    def create(self, validated_data):
        items_data = validated_data.pop('items', [])
        validated_data['created_by'] = self.context['request'].user
        quote = Quote.objects.create(**validated_data)
        for item_data in items_data:
            QuoteItem.objects.create(quote=quote, **item_data)
        quote.calculate_totals()
        return quote

    def update(self, instance, validated_data):
        items_data = validated_data.pop('items', None)
        instance = super().update(instance, validated_data)
        if items_data is not None:
            instance.items.all().delete()
            for item_data in items_data:
                QuoteItem.objects.create(quote=instance, **item_data)
        instance.calculate_totals()
        return instance


class QuoteListSerializer(serializers.ModelSerializer):
    contact_name = serializers.SerializerMethodField()
    company_name = serializers.CharField(source='company.name', read_only=True)
    owner_name   = serializers.CharField(source='owner.get_full_name', read_only=True)

    class Meta:
        model  = Quote
        fields = ['id', 'quote_number', 'title', 'status', 'contact_name', 'company_name',
                  'owner_name', 'quote_date', 'valid_until', 'grand_total', 'currency', 'created_at']

    def get_contact_name(self, obj):
        return obj.contact.full_name if obj.contact else None


class InvoiceItemSerializer(serializers.ModelSerializer):
    class Meta:
        model  = InvoiceItem
        fields = '__all__'
        read_only_fields = ['amount']


class PaymentSerializer(serializers.ModelSerializer):
    recorded_by_name = serializers.CharField(source='recorded_by.get_full_name', read_only=True)

    class Meta:
        model  = Payment
        fields = '__all__'
        read_only_fields = ['recorded_by', 'created_at']

    def create(self, validated_data):
        validated_data['recorded_by'] = self.context['request'].user
        return super().create(validated_data)


class InvoiceSerializer(serializers.ModelSerializer):
    items          = InvoiceItemSerializer(many=True)
    payments       = PaymentSerializer(many=True, read_only=True)
    contact_name   = serializers.SerializerMethodField()
    company_name   = serializers.CharField(source='company.name', read_only=True)
    tax_profile_name = serializers.CharField(source='tax_profile.name', read_only=True)
    owner_name     = serializers.CharField(source='owner.get_full_name', read_only=True)

    class Meta:
        model  = Invoice
        fields = '__all__'
        read_only_fields = ['invoice_number', 'created_by', 'amount_paid', 'amount_due',
                            'created_at', 'updated_at']

    def get_contact_name(self, obj):
        return obj.contact.full_name if obj.contact else None

    def create(self, validated_data):
        items_data = validated_data.pop('items', [])
        validated_data['created_by'] = self.context['request'].user
        invoice = Invoice.objects.create(**validated_data)
        for item_data in items_data:
            InvoiceItem.objects.create(invoice=invoice, **item_data)
        return invoice

    def update(self, instance, validated_data):
        items_data = validated_data.pop('items', None)
        instance = super().update(instance, validated_data)
        if items_data is not None:
            instance.items.all().delete()
            for item_data in items_data:
                InvoiceItem.objects.create(invoice=instance, **item_data)
        return instance


class InvoiceListSerializer(serializers.ModelSerializer):
    contact_name = serializers.SerializerMethodField()
    company_name = serializers.CharField(source='company.name', read_only=True)
    owner_name   = serializers.CharField(source='owner.get_full_name', read_only=True)

    class Meta:
        model  = Invoice
        fields = ['id', 'invoice_number', 'status', 'contact_name', 'company_name',
                  'owner_name', 'invoice_date', 'due_date', 'grand_total', 'amount_paid',
                  'amount_due', 'currency', 'is_einvoice', 'created_at']

    def get_contact_name(self, obj):
        return obj.contact.full_name if obj.contact else None
