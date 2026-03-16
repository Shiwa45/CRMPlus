# crm_project/api_urls.py  ← FULL REPLACEMENT
from django.urls import path, include
from rest_framework.routers import DefaultRouter

# ── Existing apps ─────────────────────────────────────────────────────────────
from accounts.api import UserViewSet, CustomAuthToken
from leads.api import LeadViewSet, LeadSourceViewSet, LeadActivityViewSet
from communications.api import (
    EmailConfigurationViewSet, EmailTemplateViewSet, EmailCampaignViewSet,
    EmailViewSet, EmailTrackingViewSet, EmailSequenceViewSet,
    EmailSequenceStepViewSet, EmailSequenceEnrollmentViewSet,
)
from dashboard.api import (
    DashboardWidgetViewSet, DashboardPreferenceViewSet, KPITargetViewSet,
    NotificationPreferenceViewSet, DashboardStatsView,
)
from contacts.api import (
    CompanyViewSet, ContactViewSet, ContactDocumentViewSet, ContactActivityViewSet,
)
from deals.api import (
    PipelineViewSet, PipelineStageViewSet, DealViewSet, DealActivityViewSet,
)
from quotes.api import (
    TaxProfileViewSet, ProductViewSet, QuoteViewSet, InvoiceViewSet, PaymentViewSet,
)
from tickets.api import (
    TicketCategoryViewSet, SLAPolicyViewSet, TicketViewSet, TicketReplyViewSet,
)
from workflows.api import (
    WorkflowViewSet, WorkflowConditionViewSet, WorkflowActionViewSet,
    WorkflowExecutionViewSet, NotificationViewSet, TaskViewSet,
)

# ── Phase 3 apps ──────────────────────────────────────────────────────────────
from tenants.api import (
    PlanViewSet, TenantViewSet, TenantUserViewSet,
    TenantInviteViewSet, AuditLogViewSet,
)
from integrations.api import (
    IntegrationViewSet, WATemplateViewSet, WALogViewSet, AIViewSet,
)

router = DefaultRouter()

# Accounts
router.register(r'users', UserViewSet, basename='user')

# Leads
router.register(r'leads',            LeadViewSet,         basename='lead')
router.register(r'lead-sources',     LeadSourceViewSet,   basename='leadsource')
router.register(r'lead-activities',  LeadActivityViewSet, basename='leadactivity')

# Communications
router.register(r'email-configs',               EmailConfigurationViewSet,      basename='emailconfig')
router.register(r'email-templates',             EmailTemplateViewSet,           basename='emailtemplate')
router.register(r'email-campaigns',             EmailCampaignViewSet,           basename='emailcampaign')
router.register(r'emails',                      EmailViewSet,                   basename='email')
router.register(r'email-tracking',              EmailTrackingViewSet,           basename='emailtracking')
router.register(r'email-sequences',             EmailSequenceViewSet,           basename='emailsequence')
router.register(r'email-sequence-steps',        EmailSequenceStepViewSet,       basename='emailsequencestep')
router.register(r'email-sequence-enrollments',  EmailSequenceEnrollmentViewSet, basename='emailenrollment')

# Dashboard
router.register(r'dashboard-widgets',           DashboardWidgetViewSet,         basename='dashwidget')
router.register(r'dashboard-preferences',       DashboardPreferenceViewSet,     basename='dashpref')
router.register(r'kpi-targets',                 KPITargetViewSet,               basename='kpitarget')
router.register(r'notification-preferences',    NotificationPreferenceViewSet,  basename='notifpref')

# Contacts & Companies
router.register(r'companies',         CompanyViewSet,         basename='company')
router.register(r'contacts',          ContactViewSet,         basename='contact')
router.register(r'contact-documents', ContactDocumentViewSet, basename='contactdoc')
router.register(r'contact-activities',ContactActivityViewSet, basename='contactact')

# Deals & Pipeline
router.register(r'pipelines',       PipelineViewSet,      basename='pipeline')
router.register(r'pipeline-stages', PipelineStageViewSet, basename='pipelinestage')
router.register(r'deals',           DealViewSet,          basename='deal')
router.register(r'deal-activities', DealActivityViewSet,  basename='dealact')

# Quotes, Invoices
router.register(r'tax-profiles', TaxProfileViewSet, basename='taxprofile')
router.register(r'products',     ProductViewSet,    basename='product')
router.register(r'quotes',       QuoteViewSet,      basename='quote')
router.register(r'invoices',     InvoiceViewSet,    basename='invoice')
router.register(r'payments',     PaymentViewSet,    basename='payment')

# Tickets
router.register(r'ticket-categories', TicketCategoryViewSet, basename='ticketcat')
router.register(r'sla-policies',      SLAPolicyViewSet,      basename='slapolicy')
router.register(r'tickets',           TicketViewSet,         basename='ticket')
router.register(r'ticket-replies',    TicketReplyViewSet,    basename='ticketreply')

# Workflows
router.register(r'workflows',           WorkflowViewSet,          basename='workflow')
router.register(r'workflow-conditions', WorkflowConditionViewSet, basename='workflowcond')
router.register(r'workflow-actions',    WorkflowActionViewSet,    basename='workflowact')
router.register(r'workflow-executions', WorkflowExecutionViewSet, basename='workflowexec')
router.register(r'notifications',       NotificationViewSet,      basename='notification')
router.register(r'tasks',              TaskViewSet,               basename='task')

# ── Phase 3 ───────────────────────────────────────────────────────────────────
# Tenants & Multi-tenancy
router.register(r'plans',           PlanViewSet,         basename='plan')
router.register(r'tenants',         TenantViewSet,       basename='tenant')
router.register(r'tenant-users',    TenantUserViewSet,   basename='tenantuser')
router.register(r'tenant-invites',  TenantInviteViewSet, basename='tenantinvite')
router.register(r'audit-logs',      AuditLogViewSet,     basename='auditlog')

# Integrations & WhatsApp
router.register(r'integrations',    IntegrationViewSet,  basename='integration')
router.register(r'wa-templates',    WATemplateViewSet,   basename='watemplate')
router.register(r'wa-logs',         WALogViewSet,        basename='walog')

# AI
router.register(r'ai', AIViewSet, basename='ai')

urlpatterns = [
    path('auth/login/',      CustomAuthToken.as_view(), name='api-token-auth'),
    path('dashboard/stats/', DashboardStatsView.as_view(), name='dashboard-stats'),
    path('',                 include(router.urls)),
]
