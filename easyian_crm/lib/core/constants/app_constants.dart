// lib/core/constants/app_constants.dart  ← FULL REPLACEMENT
class AppConstants {
  // ── Server ───────────────────────────────────────────────────────────────────
  // Base URL never changes — django-tenants routes by HEADER, not by URL path.
  // All endpoint paths remain identical to what they were before.
  static const String baseUrl   = 'http://127.0.0.1:8000';
  static const String apiPrefix = '/api';

  // ── Auth ─────────────────────────────────────────────────────────────────────
  static const String loginEndpoint = '$apiPrefix/auth/login/';

  // ── General ──────────────────────────────────────────────────────────────────
  static const String appVersion  = '1.0.0';
  static const String companyName = 'Easyian CRM';
  static const String themeKey    = 'theme_key';

  // ── Dashboard ────────────────────────────────────────────────────────────────
  static const String dashboardStatsEndpoint   = '$apiPrefix/dashboard/stats/';
  static const String dashboardWidgetsEndpoint = '$apiPrefix/dashboard-widgets/';
  static const String dashboardPrefsEndpoint   = '$apiPrefix/dashboard-preferences/';
  static const String kpiTargetsEndpoint       = '$apiPrefix/kpi-targets/';
  static const String notifPrefsEndpoint       = '$apiPrefix/notification-preferences/';

  // ── Users ────────────────────────────────────────────────────────────────────
  static const String usersEndpoint   = '$apiPrefix/users/';
  static const String usersMeEndpoint = '$apiPrefix/users/me/';

  // ── Leads ────────────────────────────────────────────────────────────────────
  static const String leadsEndpoint          = '$apiPrefix/leads/';
  static const String leadSourcesEndpoint    = '$apiPrefix/lead-sources/';
  static const String leadActivitiesEndpoint = '$apiPrefix/lead-activities/';

  // ── Contacts & Companies ─────────────────────────────────────────────────────
  static const String contactsEndpoint    = '$apiPrefix/contacts/';
  static const String companiesEndpoint   = '$apiPrefix/companies/';
  static const String contactDocsEndpoint = '$apiPrefix/contact-documents/';
  static const String contactActsEndpoint = '$apiPrefix/contact-activities/';

  // ── Deals & Pipeline ─────────────────────────────────────────────────────────
  static const String pipelinesEndpoint      = '$apiPrefix/pipelines/';
  static const String pipelineStagesEndpoint = '$apiPrefix/pipeline-stages/';
  static const String dealsEndpoint          = '$apiPrefix/deals/';
  static const String dealActivitiesEndpoint = '$apiPrefix/deal-activities/';

  // ── Quotes & Invoices ────────────────────────────────────────────────────────
  static const String taxProfilesEndpoint = '$apiPrefix/tax-profiles/';
  static const String productsEndpoint    = '$apiPrefix/products/';
  static const String quotesEndpoint      = '$apiPrefix/quotes/';
  static const String invoicesEndpoint    = '$apiPrefix/invoices/';
  static const String paymentsEndpoint    = '$apiPrefix/payments/';

  // ── Tickets ──────────────────────────────────────────────────────────────────
  static const String ticketCatsEndpoint       = '$apiPrefix/ticket-categories/';
  static const String ticketCategoriesEndpoint = ticketCatsEndpoint;
  static const String slaPoliciesEndpoint      = '$apiPrefix/sla-policies/';
  static const String ticketsEndpoint          = '$apiPrefix/tickets/';
  static const String ticketRepliesEndpoint    = '$apiPrefix/ticket-replies/';

  // ── Workflows & Tasks ────────────────────────────────────────────────────────
  static const String workflowsEndpoint     = '$apiPrefix/workflows/';
  static const String tasksEndpoint         = '$apiPrefix/tasks/';
  static const String notificationsEndpoint = '$apiPrefix/notifications/';

  // ── Email ────────────────────────────────────────────────────────────────────
  static const String emailConfigsEndpoint   = '$apiPrefix/email-configs/';
  static const String emailTemplatesEndpoint = '$apiPrefix/email-templates/';
  static const String emailCampaignsEndpoint = '$apiPrefix/email-campaigns/';
  static const String emailsEndpoint         = '$apiPrefix/emails/';
  static const String emailSequencesEndpoint = '$apiPrefix/email-sequences/';

  // ── Tenancy (superadmin — public schema, no X-Tenant-ID header needed) ───────
  static const String plansEndpoint         = '$apiPrefix/plans/';
  static const String tenantsEndpoint       = '$apiPrefix/tenants/';
  static const String tenantUsersEndpoint   = '$apiPrefix/tenant-users/';
  static const String tenantInvitesEndpoint = '$apiPrefix/tenant-invites/';
  static const String auditLogsEndpoint     = '$apiPrefix/audit-logs/';
  static const String tenantMeEndpoint      = '$apiPrefix/tenant/me/';

  // ── Integrations & WhatsApp ──────────────────────────────────────────────────
  static const String integrationsEndpoint = '$apiPrefix/integrations/';
  static const String waTemplatesEndpoint  = '$apiPrefix/wa-templates/';
  static const String waLogsEndpoint       = '$apiPrefix/wa-logs/';

  // ── AI ───────────────────────────────────────────────────────────────────────
  static const String aiEndpoint           = '$apiPrefix/ai';
  static const String aiScoreLeadEndpoint  = '$aiEndpoint/score_lead/';
  static const String aiDraftEmailEndpoint = '$aiEndpoint/draft_email/';
  static const String aiMarketingEndpoint  = '$aiEndpoint/marketing_copy/';
  static const String aiChatEndpoint       = '$aiEndpoint/chat/';
  static const String aiTranslateEndpoint  = '$aiEndpoint/translate/';
  static const String aiBulkScoreEndpoint  = '$aiEndpoint/bulk_score_leads/';

  // ── SharedPreferences keys ───────────────────────────────────────────────────
  static const String tokenKey     = 'auth_token';
  static const String userIdKey    = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userRoleKey  = 'user_role';

  // ── Tenant keys (NEW with django-tenants) ────────────────────────────────────
  // tenantSlugKey  →  stores the SLUG (e.g. "sharma-infotech")
  //                   this is what gets sent in the X-Tenant-ID header.
  // tenantIdKey    →  stores the integer PK (kept for reference / display)
  // tenantNameKey  →  stores the human-readable name (e.g. "Sharma InfoTech")
  // tenantRoleKey  →  stores the user's role within this tenant
  // schemaNameKey  →  stores the PostgreSQL schema name (e.g. "sharma_infotech")
  static const String tenantSlugKey = 'tenant_slug';   // ← what X-Tenant-ID uses
  static const String tenantIdKey   = 'tenant_id';     // integer PK (display only)
  static const String tenantNameKey = 'tenant_name';
  static const String tenantLogoKey = 'tenant_logo';
  static const String tenantRoleKey = 'tenant_role';
  static const String schemaNameKey = 'schema_name';
}
