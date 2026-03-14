from django.urls import path, include
from rest_framework.routers import DefaultRouter
from accounts.api import UserViewSet, CustomAuthToken
from leads.api import LeadViewSet, LeadSourceViewSet, LeadActivityViewSet
from communications.api import (
    EmailConfigurationViewSet, EmailTemplateViewSet, EmailCampaignViewSet,
    EmailViewSet, EmailTrackingViewSet, EmailSequenceViewSet,
    EmailSequenceStepViewSet, EmailSequenceEnrollmentViewSet
)
from dashboard.api import (
    DashboardWidgetViewSet, DashboardPreferenceViewSet, KPITargetViewSet,
    NotificationPreferenceViewSet
)

router = DefaultRouter()
# Accounts
router.register(r'users', UserViewSet)
# Leads
router.register(r'leads', LeadViewSet)
router.register(r'lead-sources', LeadSourceViewSet)
router.register(r'lead-activities', LeadActivityViewSet)
# Communications
router.register(r'email-configs', EmailConfigurationViewSet)
router.register(r'email-templates', EmailTemplateViewSet)
router.register(r'email-campaigns', EmailCampaignViewSet)
router.register(r'emails', EmailViewSet)
router.register(r'email-tracking', EmailTrackingViewSet)
router.register(r'email-sequences', EmailSequenceViewSet)
router.register(r'email-sequence-steps', EmailSequenceStepViewSet)
router.register(r'email-sequence-enrollments', EmailSequenceEnrollmentViewSet)
# Dashboard
router.register(r'dashboard-widgets', DashboardWidgetViewSet)
router.register(r'dashboard-preferences', DashboardPreferenceViewSet)
router.register(r'kpi-targets', KPITargetViewSet)
router.register(r'notification-preferences', NotificationPreferenceViewSet)

urlpatterns = [
    path('auth/login/', CustomAuthToken.as_view(), name='api-token-auth'),
    path('', include(router.urls)),
]
