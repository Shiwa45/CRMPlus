# crm_project/tenant_api_urls.py  ← NEW FILE
"""
API routes for TENANT schemas.

Every endpoint here runs inside the active tenant's PostgreSQL schema.
No cross-tenant data leakage is possible — django-tenants enforces schema
isolation at the database level.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter

# Auth (tokens live in public schema but are usable from tenant schemas)
from accounts.api import UserViewSet, CustomAuthToken

# Phase 1 — Leads & Communications
from leads.api import LeadViewSet, LeadSourceViewSet, LeadActivityViewSet
from communications.api import (
    EmailConfigurationViewSet, EmailTemplateViewSet, EmailCampaignViewSet,
    EmailViewSet, EmailTrackingViewSet, EmailSequenceViewSet,
    EmailSequenceStepViewSet, EmailSequenceEnrollmentViewSet,
)

# Phase 2 — Contacts, Deals, Quotes, Tickets, Workflows
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

# Phase 3 — Integrations & WhatsApp / AI
from integrations.api import (
    IntegrationViewSet, WATemplateViewSet, WALogViewSet, AIViewSet,
)

# Tenant-level user management (tenant admin can manage their own users)
from tenants.api import TenantUserViewSet, TenantInviteViewSet, AuditLogViewSet

router = DefaultRouter()

# ── Users ─────────────────────────────────────────────────────────────────────
router.register(r'users', UserViewSet, basename='user')

# ── Leads ─────────────────────────────────────────────────────────────────────
router.register(r'leads',            LeadViewSet,         basename='lead')
router.register(r'lead-sources',     LeadSourceViewSet,   basename='leadsource')
router.register(r'lead-activities',  LeadActivityViewSet, basename='leadactivity')

# ── Communications ────────────────────────────────────────────────────────────
router.register(r'email-configs',       EmailConfigurationViewSet,     basename='emailconfig')
router.register(r'email-templates',     EmailTemplateViewSet,          basename='emailtemplate')
router.register(r'email-campaigns',     EmailCampaignViewSet,          basename='emailcampaign')
router.register(r'emails',              EmailViewSet,                  basename='email')
router.register(r'email-tracking',      EmailTrackingViewSet,          basename='emailtracking')
router.register(r'email-sequences',     EmailSequenceViewSet,          basename='emailsequence')
router.register(r'email-sequence-steps',EmailSequenceStepViewSet,      basename='emailseqstep')
router.register(r'email-enrollments',   EmailSequenceEnrollmentViewSet,basename='emailenroll')

# ── Dashboard ─────────────────────────────────────────────────────────────────
router.register(r'dashboard-widgets',   DashboardWidgetViewSet,       basename='dashwidget')
router.register(r'dashboard-prefs',     DashboardPreferenceViewSet,   basename='dashpref')
router.register(r'kpi-targets',         KPITargetViewSet,             basename='kpitarget')
router.register(r'notification-prefs',  NotificationPreferenceViewSet,basename='notifpref')

# ── Contacts ──────────────────────────────────────────────────────────────────
router.register(r'companies',           CompanyViewSet,               basename='company')
router.register(r'contacts',            ContactViewSet,               basename='contact')
router.register(r'contact-documents',   ContactDocumentViewSet,       basename='contactdoc')
router.register(r'contact-activities',  ContactActivityViewSet,       basename='contactact')

# ── Deals ─────────────────────────────────────────────────────────────────────
router.register(r'pipelines',           PipelineViewSet,              basename='pipeline')
router.register(r'pipeline-stages',     PipelineStageViewSet,         basename='pipelinestage')
router.register(r'deals',              DealViewSet,                  basename='deal')
router.register(r'deal-activities',    DealActivityViewSet,          basename='dealact')

# ── Quotes & Invoices ─────────────────────────────────────────────────────────
router.register(r'tax-profiles',        TaxProfileViewSet,            basename='taxprofile')
router.register(r'products',           ProductViewSet,               basename='product')
router.register(r'quotes',             QuoteViewSet,                 basename='quote')
router.register(r'invoices',           InvoiceViewSet,               basename='invoice')
router.register(r'payments',           PaymentViewSet,               basename='payment')

# ── Tickets ───────────────────────────────────────────────────────────────────
router.register(r'ticket-categories',   TicketCategoryViewSet,        basename='ticketcat')
router.register(r'sla-policies',        SLAPolicyViewSet,             basename='sla')
router.register(r'tickets',            TicketViewSet,                basename='ticket')
router.register(r'ticket-replies',     TicketReplyViewSet,           basename='ticketreply')

# ── Workflows & Automation ────────────────────────────────────────────────────
router.register(r'workflows',           WorkflowViewSet,              basename='workflow')
router.register(r'workflow-conditions', WorkflowConditionViewSet,     basename='workflowcond')
router.register(r'workflow-actions',    WorkflowActionViewSet,        basename='workflowact')
router.register(r'workflow-executions', WorkflowExecutionViewSet,     basename='workflowexec')
router.register(r'notifications',       NotificationViewSet,          basename='notification')
router.register(r'tasks',              TaskViewSet,                  basename='task')

# ── Integrations & WhatsApp ───────────────────────────────────────────────────
router.register(r'integrations',        IntegrationViewSet,           basename='integration')
router.register(r'wa-templates',        WATemplateViewSet,            basename='watemplate')
router.register(r'wa-logs',             WALogViewSet,                 basename='walog')

# ── AI ────────────────────────────────────────────────────────────────────────
router.register(r'ai',                 AIViewSet,                    basename='ai')

# ── Tenant self-management (tenant admin only, no cross-tenant) ───────────────
router.register(r'tenant-users',       TenantUserViewSet,            basename='tenantuser')
router.register(r'tenant-invites',     TenantInviteViewSet,          basename='tenantinvite')
router.register(r'audit-logs',         AuditLogViewSet,              basename='auditlog')

urlpatterns = [
    path('auth/login/',      CustomAuthToken.as_view(), name='api-token-auth'),
    path('dashboard/stats/', DashboardStatsView.as_view(), name='dashboard-stats'),
    path('', include(router.urls)),
]
