# contacts/api.py
from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q, Count
from django.utils import timezone
from .models import Company, Contact, ContactDocument, ContactActivity
from .serializers import (
    CompanySerializer, ContactSerializer, ContactListSerializer,
    ContactDocumentSerializer, ContactActivitySerializer
)


class CompanyViewSet(viewsets.ModelViewSet):
    serializer_class   = CompanySerializer
    permission_classes = [IsAuthenticated]
    filter_backends    = [filters.SearchFilter, filters.OrderingFilter]
    search_fields      = ['name', 'email', 'phone', 'city', 'state', 'gstin', 'pan']
    ordering_fields    = ['name', 'created_at', 'annual_revenue']
    ordering           = ['name']

    def get_queryset(self):
        qs = Company.objects.annotate(contacts_count=Count('contacts'))
        industry = self.request.query_params.get('industry')
        if industry:
            qs = qs.filter(industry=industry)
        return qs


class ContactViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    filter_backends    = [filters.SearchFilter, filters.OrderingFilter]
    search_fields      = ['first_name', 'last_name', 'email', 'phone', 'mobile',
                          'company__name', 'job_title', 'city']
    ordering_fields    = ['first_name', 'last_name', 'created_at', 'last_contacted']
    ordering           = ['first_name']

    def get_serializer_class(self):
        if self.action == 'list':
            return ContactListSerializer
        return ContactSerializer

    def get_queryset(self):
        qs = Contact.objects.select_related('company', 'owner', 'created_by')
        params = self.request.query_params
        if params.get('company'):
            qs = qs.filter(company_id=params['company'])
        if params.get('owner'):
            qs = qs.filter(owner_id=params['owner'])
        if params.get('tag'):
            qs = qs.filter(tags__contains=params['tag'])
        if params.get('dnd') == 'true':
            qs = qs.filter(do_not_contact=True)
        if params.get('active') == 'false':
            qs = qs.filter(is_active=False)
        return qs

    @action(detail=True, methods=['post'])
    def log_activity(self, request, pk=None):
        contact = self.get_object()
        serializer = ContactActivitySerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        activity = serializer.save(contact=contact)
        # Update last_contacted for communication types
        if activity.activity_type in ('call', 'email', 'meeting', 'whatsapp'):
            contact.last_contacted = timezone.now()
            contact.save(update_fields=['last_contacted'])
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get'])
    def stats(self, request):
        qs = Contact.objects.all()
        return Response({
            'total': qs.count(),
            'active': qs.filter(is_active=True).count(),
            'dnd': qs.filter(do_not_contact=True).count(),
            'with_whatsapp': qs.exclude(whatsapp__isnull=True).exclude(whatsapp='').count(),
            'with_company': qs.exclude(company__isnull=True).count(),
        })

    @action(detail=False, methods=['get'])
    def duplicates(self, request):
        """Find potential duplicate contacts by email or phone"""
        from django.db.models import Count
        dupes_email = (Contact.objects.values('email')
                       .annotate(cnt=Count('id')).filter(cnt__gt=1, email__isnull=False)
                       .exclude(email=''))
        dupes_phone = (Contact.objects.values('phone')
                       .annotate(cnt=Count('id')).filter(cnt__gt=1, phone__isnull=False)
                       .exclude(phone=''))
        return Response({
            'duplicate_emails': list(dupes_email),
            'duplicate_phones': list(dupes_phone),
        })


class ContactDocumentViewSet(viewsets.ModelViewSet):
    serializer_class   = ContactDocumentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = ContactDocument.objects.select_related('contact', 'uploaded_by')
        if self.request.query_params.get('contact'):
            qs = qs.filter(contact_id=self.request.query_params['contact'])
        return qs


class ContactActivityViewSet(viewsets.ModelViewSet):
    serializer_class   = ContactActivitySerializer
    permission_classes = [IsAuthenticated]
    filter_backends    = [filters.OrderingFilter]
    ordering           = ['-performed_at']

    def get_queryset(self):
        qs = ContactActivity.objects.select_related('contact', 'performed_by')
        if self.request.query_params.get('contact'):
            qs = qs.filter(contact_id=self.request.query_params['contact'])
        return qs
