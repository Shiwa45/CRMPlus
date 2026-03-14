import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/api_client.dart';
import '../models/models.dart';

int _asInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

List<T> _mapList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
  if (raw is! List) return <T>[];
  return raw.whereType<Map>().map((e) => fromJson(Map<String, dynamic>.from(e))).toList();
}

// ─── Auth ─────────────────────────────────────────────────────────────────────
class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  Future<Map<String, dynamic>> login(String username, String password) async {
    final data = await ApiClient.instance.post(AppConstants.loginEndpoint,
        body: {'username': username, 'password': password}, noAuth: true);
    final token = data['token'] ?? data['key'] ?? '';
    final userId = data['user_id'] ?? 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token.toString());
    await prefs.setInt(AppConstants.userIdKey, userId);
    return data;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
  }

  Future<bool> get isLoggedIn async {
    final p = await SharedPreferences.getInstance();
    return (p.getString(AppConstants.tokenKey) ?? '').isNotEmpty;
  }

  Future<UserModel?> getMe() async {
    try {
      final p = await SharedPreferences.getInstance();
      final id = p.getInt(AppConstants.userIdKey);
      if (id == null) return null;
      final data = await ApiClient.instance.get('${AppConstants.usersEndpoint}$id/');
      return UserModel.fromJson(data);
    } catch (_) { return null; }
  }

  Future<UserModel> updateProfile(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.patch('${AppConstants.usersEndpoint}$id/', body: body);
    return UserModel.fromJson(data);
  }
}

// ─── Leads ────────────────────────────────────────────────────────────────────
class LeadsService {
  static final LeadsService instance = LeadsService._();
  LeadsService._();

  Future<Map<String, dynamic>> getLeads({int page = 1, int pageSize = 50,
      String? search, String? status, String? priority, int? sourceId,
      int? assignedTo, String? ordering}) async {
    final data = await ApiClient.instance.get(AppConstants.leadsEndpoint, q: {
      'page': page, 'page_size': pageSize,
      if (search != null) 'search': search,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (sourceId != null) 'source': sourceId,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (ordering != null) 'ordering': ordering,
    });
    // Handle both plain List (no pagination) and paginated Map responses
    if (data is List) {
      final results = _mapList(data, (j) => LeadModel.fromJson(j));
      return {'results': results, 'count': results.length, 'next': null, 'previous': null};
    }
    final results = _mapList(data['results'], (j) => LeadModel.fromJson(j));
    return {'results': results, 'count': _asInt(data['count'], fallback: results.length)};
  }

  Future<LeadModel> getLead(int id) async {
    final data = await ApiClient.instance.get('${AppConstants.leadsEndpoint}$id/');
    return LeadModel.fromJson(data);
  }

  Future<LeadModel> createLead(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.leadsEndpoint, body: body);
    return LeadModel.fromJson(data);
  }

  Future<LeadModel> updateLead(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.patch('${AppConstants.leadsEndpoint}$id/', body: body);
    return LeadModel.fromJson(data);
  }

  Future<void> deleteLead(int id) =>
      ApiClient.instance.delete('${AppConstants.leadsEndpoint}$id/');

  Future<void> bulkDelete(List<int> ids) async {
    await Future.wait(ids.map((id) => deleteLead(id)));
  }

  Future<List<LeadSourceModel>> getLeadSources() async {
    final data = await ApiClient.instance.get(AppConstants.leadSourcesEndpoint);
    final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
    return _mapList(list, (j) => LeadSourceModel.fromJson(j));
  }

  Future<LeadSourceModel> createLeadSource(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.leadSourcesEndpoint, body: body);
    return LeadSourceModel.fromJson(data);
  }

  Future<List<LeadActivityModel>> getActivities(int leadId) async {
    final data = await ApiClient.instance.get(AppConstants.leadActivitiesEndpoint,
        q: {'lead': leadId});
    final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
    return _mapList(list, (j) => LeadActivityModel.fromJson(j));
  }

  Future<LeadActivityModel> createActivity(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.leadActivitiesEndpoint, body: body);
    return LeadActivityModel.fromJson(data);
  }
}

// ─── Dashboard ────────────────────────────────────────────────────────────────
class DashboardService {
  static final DashboardService instance = DashboardService._();
  DashboardService._();

  Future<DashboardStats> getStats({String? dateRange}) async {
    try {
      final data = await ApiClient.instance.get(
        AppConstants.dashboardStatsEndpoint,
        q: {if (dateRange != null) 'date_range': dateRange},
      );
      final raw = (data is Map && data['results'] is Map)
          ? data['results']
          : (data is Map && data['results'] is List && (data['results'] as List).isNotEmpty)
              ? (data['results'] as List).first
              : data;
      if (raw is Map<String, dynamic>) {
        return DashboardStats.fromJson(raw);
      }
      return DashboardStats.empty();
    } catch (_) { return DashboardStats.empty(); }
  }

  Future<List<KPITargetModel>> getKpiTargets() async {
    final data = await ApiClient.instance.get(AppConstants.kpiTargetsEndpoint);
    final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
    return _mapList(list, (j) => KPITargetModel.fromJson(j));
  }

  Future<KPITargetModel> createKpiTarget(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.kpiTargetsEndpoint, body: body);
    return KPITargetModel.fromJson(data);
  }
}

// ─── Communications ───────────────────────────────────────────────────────────
class CommsService {
  static final CommsService instance = CommsService._();
  CommsService._();

  Future<Map<String, dynamic>> getEmails({int page = 1, String? status}) async {
    final data = await ApiClient.instance.get(AppConstants.emailsEndpoint,
        q: {'page': page, if (status != null) 'status': status});
    if (data is List) {
      final results = _mapList(data, (j) => EmailModel.fromJson(j));
      return {'results': results, 'count': results.length};
    }
    final results = _mapList(data['results'], (j) => EmailModel.fromJson(j));
    return {'results': results, 'count': _asInt(data['count'], fallback: results.length)};
  }

  Future<List<EmailConfigModel>> getEmailConfigs() async {
    final data = await ApiClient.instance.get(AppConstants.emailConfigsEndpoint);
    final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
    return _mapList(list, (j) => EmailConfigModel.fromJson(j));
  }

  Future<void> createEmailConfig(Map<String, dynamic> body) =>
      ApiClient.instance.post(AppConstants.emailConfigsEndpoint, body: body);
  Future<void> updateEmailConfig(int id, Map<String, dynamic> body) =>
      ApiClient.instance.patch('${AppConstants.emailConfigsEndpoint}$id/', body: body);

  Future<Map<String, dynamic>> getTemplates({int page = 1, String? search}) async {
    final data = await ApiClient.instance.get(AppConstants.emailTemplatesEndpoint,
        q: {'page': page, if (search != null) 'search': search});
    if (data is List) {
      final results = _mapList(data, (j) => EmailTemplateModel.fromJson(j));
      return {'results': results, 'count': results.length};
    }
    final results = _mapList(data['results'], (j) => EmailTemplateModel.fromJson(j));
    return {'results': results, 'count': _asInt(data['count'], fallback: results.length)};
  }

  Future<void> createTemplate(Map<String, dynamic> body) =>
      ApiClient.instance.post(AppConstants.emailTemplatesEndpoint, body: body);
  Future<void> updateTemplate(int id, Map<String, dynamic> body) =>
      ApiClient.instance.patch('${AppConstants.emailTemplatesEndpoint}$id/', body: body);
  Future<void> deleteTemplate(int id) =>
      ApiClient.instance.delete('${AppConstants.emailTemplatesEndpoint}$id/');

  Future<Map<String, dynamic>> getCampaigns({int page = 1}) async {
    final data = await ApiClient.instance.get(AppConstants.emailCampaignsEndpoint,
        q: {'page': page});
    if (data is List) {
      final results = _mapList(data, (j) => EmailCampaignModel.fromJson(j));
      return {'results': results, 'count': results.length};
    }
    final results = _mapList(data['results'], (j) => EmailCampaignModel.fromJson(j));
    return {'results': results, 'count': _asInt(data['count'], fallback: results.length)};
  }

  Future<void> createCampaign(Map<String, dynamic> body) =>
      ApiClient.instance.post(AppConstants.emailCampaignsEndpoint, body: body);

  Future<List<EmailSequenceModel>> getSequences() async {
    final data = await ApiClient.instance.get(AppConstants.emailSequencesEndpoint);
    final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
    return _mapList(list, (j) => EmailSequenceModel.fromJson(j));
  }

  Future<void> createSequence(Map<String, dynamic> body) =>
      ApiClient.instance.post(AppConstants.emailSequencesEndpoint, body: body);
}

// ─── Users ────────────────────────────────────────────────────────────────────
class UsersService {
  static final UsersService instance = UsersService._();
  UsersService._();

  Future<Map<String, dynamic>> getUsers({int page = 1, String? search, String? role}) async {
    final data = await ApiClient.instance.get(AppConstants.usersEndpoint,
        q: {'page': page, if (search != null) 'search': search, if (role != null) 'role': role});
    final rawList = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
    final results = _mapList(rawList, (j) => UserModel.fromJson(j));
    return {'results': results, 'count': _asInt(data is Map ? data['count'] : results.length, fallback: results.length)};
  }

  Future<UserModel> createUser(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.usersEndpoint, body: body);
    return UserModel.fromJson(data);
  }

  Future<UserModel> updateUser(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.patch('${AppConstants.usersEndpoint}$id/', body: body);
    return UserModel.fromJson(data);
  }

  Future<void> deleteUser(int id) =>
      ApiClient.instance.delete('${AppConstants.usersEndpoint}$id/');
}
