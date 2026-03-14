class AppConstants {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const String apiPrefix = '/api';
  static const String loginEndpoint = '$apiPrefix/auth/login/';
  static const String dashboardStatsEndpoint = '$apiPrefix/dashboard/stats/';
  static const String leadsEndpoint = '$apiPrefix/leads/';
  static const String leadSourcesEndpoint = '$apiPrefix/lead-sources/';
  static const String leadActivitiesEndpoint = '$apiPrefix/lead-activities/';
  static const String emailConfigsEndpoint = '$apiPrefix/email-configs/';
  static const String emailTemplatesEndpoint = '$apiPrefix/email-templates/';
  static const String emailCampaignsEndpoint = '$apiPrefix/email-campaigns/';
  static const String emailsEndpoint = '$apiPrefix/emails/';
  static const String emailSequencesEndpoint = '$apiPrefix/email-sequences/';
  static const String emailSequenceStepsEndpoint = '$apiPrefix/email-sequence-steps/';
  static const String emailSequenceEnrollmentsEndpoint = '$apiPrefix/email-sequence-enrollments/';
  static const String usersEndpoint = '$apiPrefix/users/';
  static const String kpiTargetsEndpoint = '$apiPrefix/kpi-targets/';
  static const String dashboardWidgetsEndpoint = '$apiPrefix/dashboard-widgets/';
  static const String dashboardPreferencesEndpoint = '$apiPrefix/dashboard-preferences/';
  static const String notificationPreferencesEndpoint = '$apiPrefix/notification-preferences/';

  static const String appName = 'Easyian CRM';
  static const String appVersion = '1.0.0';
  static const String companyName = 'Easyian';

  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
}
