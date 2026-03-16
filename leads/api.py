from rest_framework import viewsets, serializers, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Count, Q
from leads.models import Lead, LeadSource, LeadActivity

class LeadSourceSerializer(serializers.ModelSerializer):
    class Meta:
        model = LeadSource
        fields = '__all__'

class LeadSerializer(serializers.ModelSerializer):
    is_hot = serializers.BooleanField(read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    source_name = serializers.SerializerMethodField()
    assigned_to_name = serializers.SerializerMethodField()

    class Meta:
        model = Lead
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
        model = LeadActivity
        fields = '__all__'

    def get_user_name(self, obj):
        if obj.user:
            return obj.user.get_full_name() or obj.user.username
        return None

class LeadSourceViewSet(viewsets.ModelViewSet):
    queryset = LeadSource.objects.all()
    serializer_class = LeadSourceSerializer

class LeadViewSet(viewsets.ModelViewSet):
    serializer_class = LeadSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['first_name', 'last_name', 'email', 'company']
    ordering_fields = ['created_at', 'updated_at', 'first_name', 'status', 'priority']
    ordering = ['-created_at']

    def get_queryset(self):
        qs = Lead.objects.select_related('source', 'assigned_to').all()
        status = self.request.query_params.get('status')
        priority = self.request.query_params.get('priority')
        source = self.request.query_params.get('source')
        assigned_to = self.request.query_params.get('assigned_to')
        if status:
            qs = qs.filter(status=status)
        if priority:
            qs = qs.filter(priority=priority)
        if source:
            qs = qs.filter(source_id=source)
        if assigned_to:
            qs = qs.filter(assigned_to_id=assigned_to)
        return qs

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Get lead statistics"""
        user = request.user

        if user.role == 'sales_rep':
            queryset = Lead.objects.filter(assigned_to=user)
        elif user.role == 'sales_manager':
            from django.contrib.auth import get_user_model
            User = get_user_model()
            team_members = User.objects.filter(
                role='sales_rep',
                department=user.department,
                is_active=True
            )
            queryset = Lead.objects.filter(
                Q(assigned_to=user) | Q(assigned_to__in=team_members)
            )
        else:
            queryset = Lead.objects.all()

        total = queryset.count()
        by_status = queryset.values('status').annotate(count=Count('id'))
        by_priority = queryset.values('priority').annotate(count=Count('id'))
        by_source = queryset.values('source__name').annotate(count=Count('id'))

        return Response({
            'total': total,
            'by_status': {item['status']: item['count'] for item in by_status},
            'by_priority': {item['priority']: item['count'] for item in by_priority},
            'by_source': {
                item['source__name']: item['count']
                for item in by_source
                if item['source__name']
            },
        })

class LeadActivityViewSet(viewsets.ModelViewSet):
    queryset = LeadActivity.objects.select_related('user').all()
    serializer_class = LeadActivitySerializer
