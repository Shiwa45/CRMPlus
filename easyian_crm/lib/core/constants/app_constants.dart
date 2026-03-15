// lib/core/constants/app_constants.dart
class AppConstants {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const String apiPrefix = '/api';

  // ── Auth ────────────────────────────────────────────────────────────────────
  static const String loginEndpoint = '$apiPrefix/auth/login/';

  // ── Dashboard ───────────────────────────────────────────────────────────────
  static const String dashboardStatsEndpoint    = '$apiPrefix/dashboard/stats/';
  static const String dashboardWidgetsEndpoint  = '$apiPrefix/dashboard-widgets/';
  static const String dashboardPrefsEndpoint    = '$apiPrefix/dashboard-preferences/';
  static const String kpiTargetsEndpoint        = '$apiPrefix/kpi-targets/';
  static const String notifPrefsEndpoint        = '$apiPrefix/notification-preferences/';

  // ── Users ───────────────────────────────────────────────────────────────────
  static const String usersEndpoint = '$apiPrefix/users/';

  // ── Leads ───────────────────────────────────────────────────────────────────
  static const String leadsEndpoint           = '$apiPrefix/leads/';
  static const String leadSourcesEndpoint     = '$apiPrefix/lead-sources/';
  static const String leadActivitiesEndpoint  = '$apiPrefix/lead-activities/';

  // ── Contacts & Companies ────────────────────────────────────────────────────
  static const String contactsEndpoint         = '$apiPrefix/contacts/';
  static const String companiesEndpoint        = '$apiPrefix/companies/';
  static const String contactDocsEndpoint      = '$apiPrefix/contact-documents/';
  static const String contactActivitiesEndpoint = '$apiPrefix/contact-activities/';

  // ── Deals & Pipeline ────────────────────────────────────────────────────────
  static const String pipelinesEndpoint       = '$apiPrefix/pipelines/';
  static const String pipelineStagesEndpoint  = '$apiPrefix/pipeline-stages/';
  static const String dealsEndpoint           = '$apiPrefix/deals/';
  static const String dealActivitiesEndpoint  = '$apiPrefix/deal-activities/';

  // ── Quotes & Invoices ───────────────────────────────────────────────────────
  static const String taxProfilesEndpoint = '$apiPrefix/tax-profiles/';
  static const String productsEndpoint    = '$apiPrefix/products/';
  static const String quotesEndpoint      = '$apiPrefix/quotes/';
  static const String invoicesEndpoint    = '$apiPrefix/invoices/';
  static const String paymentsEndpoint    = '$apiPrefix/payments/';

  // ── Tickets ─────────────────────────────────────────────────────────────────
  static const String ticketCategoriesEndpoint = '$apiPrefix/ticket-categories/';
  static const String slaPoliciesEndpoint      = '$apiPrefix/sla-policies/';
  static const String ticketsEndpoint          = '$apiPrefix/tickets/';
  static const String ticketRepliesEndpoint    = '$apiPrefix/ticket-replies/';

  // ── Workflows & Automation ──────────────────────────────────────────────────
  static const String workflowsEndpoint      = '$apiPrefix/workflows/';
  static const String wfConditionsEndpoint   = '$apiPrefix/workflow-conditions/';
  static const String wfActionsEndpoint      = '$apiPrefix/workflow-actions/';
  static const String wfExecutionsEndpoint   = '$apiPrefix/workflow-executions/';
  static const String notificationsEndpoint  = '$apiPrefix/notifications/';
  static const String tasksEndpoint          = '$apiPrefix/tasks/';

  // ── Communications ──────────────────────────────────────────────────────────
  static const String emailConfigsEndpoint            = '$apiPrefix/email-configs/';
  static const String emailTemplatesEndpoint          = '$apiPrefix/email-templates/';
  static const String emailCampaignsEndpoint          = '$apiPrefix/email-campaigns/';
  static const String emailsEndpoint                  = '$apiPrefix/emails/';
  static const String emailSequencesEndpoint          = '$apiPrefix/email-sequences/';
  static const String emailSequenceStepsEndpoint      = '$apiPrefix/email-sequence-steps/';
  static const String emailSequenceEnrollmentsEndpoint = '$apiPrefix/email-sequence-enrollments/';

  // ── App Meta ────────────────────────────────────────────────────────────────
  static const String appName     = 'Easyian CRM';
  static const String appVersion  = '2.0.0';
  static const String companyName = 'Easyian';

  // ── Prefs keys ──────────────────────────────────────────────────────────────
  static const String tokenKey  = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String themeKey  = 'theme_mode';
}
