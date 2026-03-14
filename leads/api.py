from rest_framework import viewsets, serializers
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

class LeadActivityViewSet(viewsets.ModelViewSet):
    queryset = LeadActivity.objects.all()
    serializer_class = LeadActivitySerializer
