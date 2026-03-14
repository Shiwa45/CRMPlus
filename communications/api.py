from rest_framework import viewsets, serializers, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from communications.models import (
    EmailConfiguration, EmailTemplate, EmailCampaign, Email, 
    EmailTracking, EmailSequence, EmailSequenceStep, EmailSequenceEnrollment
)
from communications.services import EmailService, EmailCampaignService, EmailAnalyticsService

class EmailConfigurationSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmailConfiguration
        fields = '__all__'
        read_only_fields = ['user']

class EmailTemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmailTemplate
        fields = '__all__'
        read_only_fields = ['user']

class EmailCampaignSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmailCampaign
        fields = '__all__'
        read_only_fields = ['user']

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
        read_only_fields = ['user']

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

    def get_queryset(self):
        return self.queryset.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['post'])
    def test(self, request, pk=None):
        config = self.get_object()
        try:
            test_result = EmailService.test_email_configuration(config)
            if test_result:
                return Response({
                    'success': True,
                    'message': 'Email configuration test successful!'
                })
            return Response({
                'success': False,
                'message': 'Email configuration test failed. Please check your settings.'
            }, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Test failed: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class EmailTemplateViewSet(viewsets.ModelViewSet):
    queryset = EmailTemplate.objects.all()
    serializer_class = EmailTemplateSerializer

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class EmailCampaignViewSet(viewsets.ModelViewSet):
    queryset = EmailCampaign.objects.all()
    serializer_class = EmailCampaignSerializer

    def get_queryset(self):
        return self.queryset.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['post'])
    def start(self, request, pk=None):
        campaign = self.get_object()

        if campaign.status not in ['draft', 'paused']:
            return Response({
                'success': False,
                'message': 'Campaign can only be started from draft or paused status.'
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            if campaign.total_recipients == 0:
                emails_created = EmailCampaignService.create_campaign_emails(campaign)
                campaign.total_recipients = emails_created

            campaign.status = 'sending'
            campaign.started_at = timezone.now()
            campaign.save()

            return Response({
                'success': True,
                'message': 'Campaign started successfully!',
                'campaign_id': campaign.id,
                'total_recipients': campaign.total_recipients
            })
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Failed to start campaign: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=True, methods=['post'])
    def pause(self, request, pk=None):
        campaign = self.get_object()

        if campaign.status != 'sending':
            return Response({
                'success': False,
                'message': 'Only sending campaigns can be paused.'
            }, status=status.HTTP_400_BAD_REQUEST)

        campaign.status = 'paused'
        campaign.save()

        return Response({
            'success': True,
            'message': 'Campaign paused successfully!'
        })

    @action(detail=True, methods=['get'])
    def stats(self, request, pk=None):
        campaign = self.get_object()
        stats = EmailAnalyticsService.get_campaign_stats(campaign)
        return Response(stats)

class EmailViewSet(viewsets.ModelViewSet):
    queryset = Email.objects.all()
    serializer_class = EmailSerializer

class EmailTrackingViewSet(viewsets.ModelViewSet):
    queryset = EmailTracking.objects.all()
    serializer_class = EmailTrackingSerializer

class EmailSequenceViewSet(viewsets.ModelViewSet):
    queryset = EmailSequence.objects.all()
    serializer_class = EmailSequenceSerializer

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class EmailSequenceStepViewSet(viewsets.ModelViewSet):
    queryset = EmailSequenceStep.objects.all()
    serializer_class = EmailSequenceStepSerializer

class EmailSequenceEnrollmentViewSet(viewsets.ModelViewSet):
    queryset = EmailSequenceEnrollment.objects.all()
    serializer_class = EmailSequenceEnrollmentSerializer
