# leads/api.py  ← FULL REPLACEMENT
"""
Lead API — tenant filtering removed.

Because django-tenants sets the active PostgreSQL schema on every request,
Lead.objects.all() already returns ONLY the current tenant's leads.
No filter(tenant=...) is needed — or even possible.
"""
from rest_framework import viewsets, serializers, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import permissions
from django.db.models import Count, Q

from leads.models import Lead, LeadSource, LeadActivity


# ── Serializers ────────────────────────────────────────────────────────────────

class LeadSourceSerializer(serializers.ModelSerializer):
    class Meta:
        model  = LeadSource
        fields = '__all__'


class LeadSerializer(serializers.ModelSerializer):
    is_hot            = serializers.BooleanField(read_only=True)
    is_overdue        = serializers.BooleanField(read_only=True)
    source_name       = serializers.SerializerMethodField()
    assigned_to_name  = serializers.SerializerMethodField()

    class Meta:
        model  = Lead
        fields = '__all__'
        read_only_fields = ['created_by']

    def get_source_name(self, obj):
        return obj.source.name if obj.source else None

    def get_assigned_to_name(self, obj):
        if obj.assigned_to:
            return obj.assigned_to.get_full_name() or obj.assigned_to.username
        return None


class LeadActivitySerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()

    class Meta:
        model  = LeadActivity
        fields = '__all__'

    def get_user_name(self, obj):
        if obj.user:
            return obj.user.get_full_name() or obj.user.username
        return None


# ── ViewSets ───────────────────────────────────────────────────────────────────

class LeadSourceViewSet(viewsets.ModelViewSet):
    """Lead sources are per-tenant (each tenant has their own list)."""
    queryset           = LeadSource.objects.all()
    serializer_class   = LeadSourceSerializer
    permission_classes = [permissions.IsAuthenticated]


class LeadViewSet(viewsets.ModelViewSet):
    """
    Full CRUD for Leads.

    Security note: Lead.objects.all() returns only THIS tenant's leads because
    django-tenants has already switched the DB connection to the tenant's schema.
    Role-based row filtering (rep sees own leads, manager sees team, admin sees all)
    is applied on top of that.
    """
    serializer_class   = LeadSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends    = [filters.SearchFilter, filters.OrderingFilter]
    search_fields      = ['first_name', 'last_name', 'email', 'company']
    ordering_fields    = ['created_at', 'updated_at', 'first_name', 'status', 'priority']
    ordering           = ['-created_at']

    def get_queryset(self):
        """
        Schema-scoped by default.
        Additional role-based scoping applied on top.
        """
        user = self.request.user
        qs   = Lead.objects.select_related('source', 'assigned_to', 'created_by')

        # Role-based scoping within the tenant
        if user.role == 'sales_rep':
            qs = qs.filter(assigned_to=user)
        elif user.role == 'sales_manager':
            from django.contrib.auth import get_user_model
            User = get_user_model()
            team = User.objects.filter(role='sales_rep', department=user.department)
            qs   = qs.filter(Q(assigned_to=user) | Q(assigned_to__in=team))
        # admin / superadmin / marketing see all leads in the tenant

        # Optional query filters
        params = self.request.query_params
        if params.get('status'):
            qs = qs.filter(status=params['status'])
        if params.get('priority'):
            qs = qs.filter(priority=params['priority'])
        if params.get('source'):
            qs = qs.filter(source_id=params['source'])
        if params.get('assigned_to') and user.role in ('admin', 'sales_manager', 'superadmin'):
            qs = qs.filter(assigned_to_id=params['assigned_to'])
        if params.get('date_from'):
            qs = qs.filter(created_at__date__gte=params['date_from'])
        if params.get('date_to'):
            qs = qs.filter(created_at__date__lte=params['date_to'])

        return qs

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Lead statistics — automatically scoped to the current tenant."""
        qs = self.get_queryset()
        return Response({
            'total':       qs.count(),
            'by_status':   {i['status']:   i['count'] for i in qs.values('status').annotate(count=Count('id'))},
            'by_priority': {i['priority']: i['count'] for i in qs.values('priority').annotate(count=Count('id'))},
            'by_source':   {
                i['source__name']: i['count']
                for i in qs.values('source__name').annotate(count=Count('id'))
                if i['source__name']
            },
        })


class LeadActivityViewSet(viewsets.ModelViewSet):
    """Activities are automatically scoped to the active tenant schema."""
    serializer_class   = LeadActivitySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = LeadActivity.objects.select_related('user', 'lead')
        lead_id = self.request.query_params.get('lead')
        if lead_id:
            qs = qs.filter(lead_id=lead_id)
        return qs
