from rest_framework import viewsets, serializers
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
    
    class Meta:
        model = Lead
        fields = '__all__'
        read_only_fields = ['created_by']

class LeadActivitySerializer(serializers.ModelSerializer):
    class Meta:
        model = LeadActivity
        fields = '__all__'

class LeadSourceViewSet(viewsets.ModelViewSet):
    queryset = LeadSource.objects.all()
    serializer_class = LeadSourceSerializer

class LeadViewSet(viewsets.ModelViewSet):
    queryset = Lead.objects.all()
    serializer_class = LeadSerializer

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
    queryset = LeadActivity.objects.all()
    serializer_class = LeadActivitySerializer
