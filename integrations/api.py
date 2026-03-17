# integrations/api.py  (django-tenants version — no tenant FK, no WhatsAppLog)
from rest_framework import viewsets, serializers, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from .models import Integration, WhatsAppTemplate


# ── Serializers ───────────────────────────────────────────────────────────────

class IntegrationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Integration
        fields = '__all__'


class WATemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = WhatsAppTemplate
        fields = '__all__'


# ── ViewSets ──────────────────────────────────────────────────────────────────

class IntegrationViewSet(viewsets.ModelViewSet):
    """Manages per-tenant integration configs. Schema isolation ensures privacy."""
    serializer_class = IntegrationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Integration.objects.all()

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @action(detail=True, methods=['post'])
    def toggle(self, request, pk=None):
        intg = self.get_object()
        intg.status = 'active' if intg.status != 'active' else 'inactive'
        intg.save(update_fields=['status'])
        return Response({'status': intg.status})


class WATemplateViewSet(viewsets.ModelViewSet):
    """Manages WhatsApp message templates. Schema isolation ensures privacy."""
    serializer_class = WATemplateSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return WhatsAppTemplate.objects.all()


class WALogViewSet(viewsets.ReadOnlyModelViewSet):
    """Stub — WALog removed from models; returns empty queryset."""
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        from django.db.models.query import QuerySet
        return Integration.objects.none()

    def list(self, request, *args, **kwargs):
        return Response([])

    def retrieve(self, request, *args, **kwargs):
        return Response({'detail': 'Not found.'}, status=404)


class AIViewSet(viewsets.ViewSet):
    """General AI endpoints. Reads from DB Integration record for API keys."""
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['post'])
    def score_lead(self, request):
        return Response({'message': 'AI scoring not configured yet.'}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

    @action(detail=False, methods=['post'])
    def draft_email(self, request):
        return Response({'message': 'AI email drafting not configured yet.'}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

    @action(detail=False, methods=['post'])
    def chat(self, request):
        return Response({'reply': "I'm your AI assistant! AI features haven't been fully activated yet."})
