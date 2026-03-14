from rest_framework import viewsets, serializers
from communications.models import (
    EmailConfiguration, EmailTemplate, EmailCampaign, Email, 
    EmailTracking, EmailSequence, EmailSequenceStep, EmailSequenceEnrollment
)

class EmailConfigurationSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmailConfiguration
        fields = '__all__'

class EmailTemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmailTemplate
        fields = '__all__'

class EmailCampaignSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmailCampaign
        fields = '__all__'

class EmailSerializer(serializers.ModelSerializer):
    class Meta:
        model = Email
        fields = '__all__'

class EmailTrackingSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmailTracking
        fields = '__all__'

class EmailSequenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmailSequence
        fields = '__all__'

class EmailSequenceStepSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmailSequenceStep
        fields = '__all__'

class EmailSequenceEnrollmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmailSequenceEnrollment
        fields = '__all__'

class EmailConfigurationViewSet(viewsets.ModelViewSet):
    queryset = EmailConfiguration.objects.all()
    serializer_class = EmailConfigurationSerializer

class EmailTemplateViewSet(viewsets.ModelViewSet):
    queryset = EmailTemplate.objects.all()
    serializer_class = EmailTemplateSerializer

class EmailCampaignViewSet(viewsets.ModelViewSet):
    queryset = EmailCampaign.objects.all()
    serializer_class = EmailCampaignSerializer

class EmailViewSet(viewsets.ModelViewSet):
    queryset = Email.objects.all()
    serializer_class = EmailSerializer

class EmailTrackingViewSet(viewsets.ModelViewSet):
    queryset = EmailTracking.objects.all()
    serializer_class = EmailTrackingSerializer

class EmailSequenceViewSet(viewsets.ModelViewSet):
    queryset = EmailSequence.objects.all()
    serializer_class = EmailSequenceSerializer

class EmailSequenceStepViewSet(viewsets.ModelViewSet):
    queryset = EmailSequenceStep.objects.all()
    serializer_class = EmailSequenceStepSerializer

class EmailSequenceEnrollmentViewSet(viewsets.ModelViewSet):
    queryset = EmailSequenceEnrollment.objects.all()
    serializer_class = EmailSequenceEnrollmentSerializer
