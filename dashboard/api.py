from rest_framework import viewsets, serializers
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
