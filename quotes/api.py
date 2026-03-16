# quotes/api.py
from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Sum, Count, Q
from django.utils import timezone
from .models import TaxProfile, Product, Quote, Invoice, Payment
from .serializers import (
    TaxProfileSerializer, ProductSerializer,
    QuoteSerializer, QuoteListSerializer,
    InvoiceSerializer, InvoiceListSerializer,
    PaymentSerializer,
)


class TaxProfileViewSet(viewsets.ModelViewSet):
    queryset           = TaxProfile.objects.filter(is_active=True)
    serializer_class   = TaxProfileSerializer
    permission_classes = [IsAuthenticated]


class ProductViewSet(viewsets.ModelViewSet):
    serializer_class   = ProductSerializer
    permission_classes = [IsAuthenticated]
    filter_backends    = [filters.SearchFilter, filters.OrderingFilter]
    search_fields      = ['name', 'code', 'description', 'hsn_sac_code']
    ordering           = ['name']

    def get_queryset(self):
        qs = Product.objects.filter(is_active=True)
        if self.request.query_params.get('type'):
            qs = qs.filter(product_type=self.request.query_params['type'])
        return qs


class QuoteViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    filter_backends    = [filters.SearchFilter, filters.OrderingFilter]
    search_fields      = ['quote_number', 'title', 'bill_to_name', 'bill_to_gstin']
    ordering           = ['-created_at']

    def get_serializer_class(self):
        if self.action == 'list':
            return QuoteListSerializer
        return QuoteSerializer

    def get_queryset(self):
        qs = Quote.objects.select_related('contact', 'company', 'owner', 'tax_profile')
        p  = self.request.query_params
        if p.get('status'):
            qs = qs.filter(status=p['status'])
        if p.get('owner'):
            qs = qs.filter(owner_id=p['owner'])
        return qs

    @action(detail=True, methods=['post'])
    def convert_to_invoice(self, request, pk=None):
        """Convert accepted quote to invoice"""
        quote = self.get_object()
        if hasattr(quote, 'invoice'):
            return Response({'error': 'Quote already converted'}, status=status.HTTP_400_BAD_REQUEST)
        from .models import Invoice, InvoiceItem
        invoice = Invoice.objects.create(
            quote=quote, tax_profile=quote.tax_profile,
            contact=quote.contact, company=quote.company, deal=quote.deal,
            supply_type=quote.supply_type,
            bill_to_name=quote.bill_to_name, bill_to_gstin=quote.bill_to_gstin,
            bill_to_addr=quote.bill_to_addr, bill_to_city=quote.bill_to_city,
            bill_to_state=quote.bill_to_state, bill_to_pin=quote.bill_to_pin,
            subtotal=quote.subtotal, discount_pct=quote.discount_pct,
            discount_amt=quote.discount_amt, taxable_amount=quote.taxable_amount,
            cgst_total=quote.cgst_total, sgst_total=quote.sgst_total,
            igst_total=quote.igst_total, cess_total=quote.cess_total,
            round_off=quote.round_off, grand_total=quote.grand_total,
            amount_due=quote.grand_total, currency=quote.currency,
            terms=quote.terms, notes=quote.notes,
            owner=quote.owner, created_by=request.user,
        )
        for qi in quote.items.all():
            InvoiceItem.objects.create(
                invoice=invoice, product=qi.product, name=qi.name,
                description=qi.description, hsn_sac_code=qi.hsn_sac_code,
                quantity=qi.quantity, unit=qi.unit, unit_price=qi.unit_price,
                discount_pct=qi.discount_pct, gst_rate=qi.gst_rate,
                cess_rate=qi.cess_rate, amount=qi.amount, order=qi.order,
            )
        quote.status = 'converted'
        quote.save()
        return Response(InvoiceSerializer(invoice, context={'request': request}).data,
                        status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get'])
    def stats(self, request):
        qs = Quote.objects.all()
        return Response({
            'total': qs.count(),
            'draft': qs.filter(status='draft').count(),
            'sent': qs.filter(status='sent').count(),
            'accepted': qs.filter(status='accepted').count(),
            'total_value': qs.aggregate(v=Sum('grand_total'))['v'] or 0,
            'accepted_value': qs.filter(status='accepted').aggregate(v=Sum('grand_total'))['v'] or 0,
        })


class InvoiceViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    filter_backends    = [filters.SearchFilter, filters.OrderingFilter]
    search_fields      = ['invoice_number', 'bill_to_name', 'bill_to_gstin', 'po_number']
    ordering           = ['-created_at']

    def get_serializer_class(self):
        if self.action == 'list':
            return InvoiceListSerializer
        return InvoiceSerializer

    def get_queryset(self):
        qs = Invoice.objects.select_related('contact', 'company', 'owner', 'tax_profile')
        p  = self.request.query_params
        if p.get('status'):
            qs = qs.filter(status=p['status'])
        if p.get('overdue') == 'true':
            qs = qs.filter(due_date__lt=timezone.now().date(), status__in=['sent', 'partial'])
        return qs

    @action(detail=True, methods=['post'])
    def record_payment(self, request, pk=None):
        invoice = self.get_object()
        serializer = PaymentSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        payment = serializer.save(invoice=invoice)
        return Response(PaymentSerializer(payment).data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get'])
    def stats(self, request):
        qs = Invoice.objects.all()
        return Response({
            'total': qs.count(),
            'paid': qs.filter(status='paid').count(),
            'partial': qs.filter(status='partial').count(),
            'overdue': qs.filter(due_date__lt=timezone.now().date(), status__in=['sent','partial']).count(),
            'total_invoiced': qs.aggregate(v=Sum('grand_total'))['v'] or 0,
            'total_collected': qs.aggregate(v=Sum('amount_paid'))['v'] or 0,
            'total_outstanding': qs.aggregate(v=Sum('amount_due'))['v'] or 0,
        })


class PaymentViewSet(viewsets.ModelViewSet):
    serializer_class   = PaymentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = Payment.objects.select_related('invoice', 'recorded_by')
        if self.request.query_params.get('invoice'):
            qs = qs.filter(invoice_id=self.request.query_params['invoice'])
        return qs
