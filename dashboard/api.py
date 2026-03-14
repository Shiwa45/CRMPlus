from rest_framework import viewsets, serializers
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.authentication import TokenAuthentication, SessionAuthentication
from django.db.models import Count

from leads.models import Lead
from communications.models import EmailCampaign, Email
from django.contrib.auth import get_user_model
from dashboard.views import DashboardView
from dashboard.models import DashboardWidget, DashboardPreference, KPITarget, NotificationPreference

class DashboardWidgetSerializer(serializers.ModelSerializer):
    class Meta:
        model = DashboardWidget
        fields = '__all__'

class DashboardPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = DashboardPreference
        fields = '__all__'

class KPITargetSerializer(serializers.ModelSerializer):
    completion_percentage = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    is_achieved = serializers.BooleanField(read_only=True)

    class Meta:
        model = KPITarget
        fields = '__all__'

class NotificationPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationPreference
        fields = '__all__'

class DashboardWidgetViewSet(viewsets.ModelViewSet):
    queryset = DashboardWidget.objects.all()
    serializer_class = DashboardWidgetSerializer

class DashboardPreferenceViewSet(viewsets.ModelViewSet):
    queryset = DashboardPreference.objects.all()
    serializer_class = DashboardPreferenceSerializer

class KPITargetViewSet(viewsets.ModelViewSet):
    queryset = KPITarget.objects.all()
    serializer_class = KPITargetSerializer

class NotificationPreferenceViewSet(viewsets.ModelViewSet):
    queryset = NotificationPreference.objects.all()
    serializer_class = NotificationPreferenceSerializer


class DashboardStatsView(APIView):
    authentication_classes = [TokenAuthentication, SessionAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        dashboard_view = DashboardView()
        date_range = request.GET.get('date_range', 'month')
        date_from, date_to = dashboard_view.get_date_range(date_range)

        leads_queryset = dashboard_view.get_user_leads_queryset(
            request.user, date_from, date_to
        )
        stats = dashboard_view.calculate_dashboard_stats(leads_queryset, request.user)

        # Aggregate counts expected by Flutter UI
        User = get_user_model()
        total_users = User.objects.count()
        total_campaigns = EmailCampaign.objects.count()
        total_emails = Email.objects.count()

        # Grouped data for charts
        leads_by_status = dict(
            leads_queryset.values_list('status')
            .annotate(count=Count('id'))
            .values_list('status', 'count')
        )
        leads_by_priority = dict(
            leads_queryset.values_list('priority')
            .annotate(count=Count('id'))
            .values_list('priority', 'count')
        )
        leads_by_source = dict(
            leads_queryset.values_list('source__name')
            .annotate(count=Count('id'))
            .values_list('source__name', 'count')
        )

        # Recent leads and active campaigns
        recent_leads = list(
            leads_queryset.order_by('-created_at').values(
                'id', 'first_name', 'last_name', 'email', 'company',
                'status', 'priority', 'created_at'
            )[:10]
        )
        active_campaigns = list(
            EmailCampaign.objects.filter(status='sending').values(
                'id', 'name', 'status', 'created_at'
            )[:10]
        )

        payload = {
            **stats,
            'total_users': total_users,
            'total_campaigns': total_campaigns,
            'total_emails': total_emails,
            'leads_by_status': leads_by_status,
            'leads_by_priority': leads_by_priority,
            'leads_by_source': leads_by_source,
            'recent_leads': recent_leads,
            'active_campaigns': active_campaigns,
        }

        return Response(payload)
