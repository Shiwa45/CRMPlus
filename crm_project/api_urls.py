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
    NotificationPreferenceViewSet, DashboardStatsView
)

router = DefaultRouter()
# Accounts
router.register(r'users', UserViewSet, basename='user')
# Leads
router.register(r'leads', LeadViewSet, basename='lead')
router.register(r'lead-sources', LeadSourceViewSet, basename='leadsource')
router.register(r'lead-activities', LeadActivityViewSet, basename='leadactivity')
# Communications
router.register(r'email-configs', EmailConfigurationViewSet, basename='emailconfiguration')
router.register(r'email-templates', EmailTemplateViewSet, basename='emailtemplate')
router.register(r'email-campaigns', EmailCampaignViewSet, basename='emailcampaign')
router.register(r'emails', EmailViewSet, basename='email')
router.register(r'email-tracking', EmailTrackingViewSet, basename='emailtracking')
router.register(r'email-sequences', EmailSequenceViewSet, basename='emailsequence')
router.register(r'email-sequence-steps', EmailSequenceStepViewSet, basename='emailsequencestep')
router.register(r'email-sequence-enrollments', EmailSequenceEnrollmentViewSet, basename='emailsequenceenrollment')
# Dashboard
router.register(r'dashboard-widgets', DashboardWidgetViewSet, basename='dashboardwidget')
router.register(r'dashboard-preferences', DashboardPreferenceViewSet, basename='dashboardpreference')
router.register(r'kpi-targets', KPITargetViewSet, basename='kpitarget')
router.register(r'notification-preferences', NotificationPreferenceViewSet, basename='notificationpreference')

urlpatterns = [
    path('auth/login/', CustomAuthToken.as_view(), name='api-token-auth'),
    path('dashboard/stats/', DashboardStatsView.as_view(), name='dashboard-stats'),
    path('', include(router.urls)),
]
