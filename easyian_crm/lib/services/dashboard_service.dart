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

class DashboardService {
  static DashboardService? _instance;
  static DashboardService get instance => _instance ??= DashboardService._();
  DashboardService._();

  Future<DashboardStats> getDashboardStats({String dateRange = 'month'}) async {
    final response = await ApiClient.instance.get(
      AppConstants.dashboardStatsEndpoint,
      q: {'date_range': dateRange},
    );
    return DashboardStats.fromJson(response);
  }

  Future<Map<String, dynamic>> getChartData(String type, {String dateRange = 'month'}) async {
    final response = await ApiClient.instance.get(
      '/api/chart-data/',
      queryParams: {'type': type, 'date_range': dateRange},
    );
    return response as Map<String, dynamic>;
  }

  Future<List<KPITargetModel>> getKPITargets() async {
    final response = await ApiClient.instance.get(AppConstants.kpiTargetsEndpoint);
    final list = response is List ? response : (response is Map ? (response['results'] as List? ?? []) : []);
    return _mapList(list, (j) => KPITargetModel.fromJson(j));
  }

  Future<KPITargetModel> createKPITarget(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post(
      AppConstants.kpiTargetsEndpoint,
      body: data,
    );
    return KPITargetModel.fromJson(response);
  }

  Future<KPITargetModel> updateKPITarget(int id, Map<String, dynamic> data) async {
    final response = await ApiClient.instance.patch(
      '${AppConstants.kpiTargetsEndpoint}$id/',
      body: data,
    );
    return KPITargetModel.fromJson(response);
  }
}

class CommunicationsService {
  static CommunicationsService? _instance;
  static CommunicationsService get instance => _instance ??= CommunicationsService._();
  CommunicationsService._();

  // Email Configs
  Future<List<EmailConfigModel>> getEmailConfigs() async {
    final response = await ApiClient.instance.get(AppConstants.emailConfigsEndpoint);
    final list = response is List ? response : (response is Map ? (response['results'] as List? ?? []) : []);
    return _mapList(list, (j) => EmailConfigModel.fromJson(j));
  }

  Future<EmailConfigModel> createEmailConfig(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post(AppConstants.emailConfigsEndpoint, body: data);
    return EmailConfigModel.fromJson(response);
  }

  Future<EmailConfigModel> updateEmailConfig(int id, Map<String, dynamic> data) async {
    final response = await ApiClient.instance.patch('${AppConstants.emailConfigsEndpoint}$id/', body: data);
    return EmailConfigModel.fromJson(response);
  }

  Future<void> deleteEmailConfig(int id) async {
    await ApiClient.instance.delete('${AppConstants.emailConfigsEndpoint}$id/');
  }

  // Email Templates
  Future<Map<String, dynamic>> getEmailTemplates({int page = 1, String? search}) async {
    final params = <String, dynamic>{'page': page.toString()};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final response = await ApiClient.instance.get(AppConstants.emailTemplatesEndpoint, queryParams: params);
    if (response is List) {
      final results = _mapList(response, (j) => EmailTemplateModel.fromJson(j));
      return {'results': results, 'count': results.length};
    }
    final results = _mapList(response['results'], (j) => EmailTemplateModel.fromJson(j));
    return {
      'results': results,
      'count': _asInt(response['count']),
    };
  }

  Future<EmailTemplateModel> createEmailTemplate(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post(AppConstants.emailTemplatesEndpoint, body: data);
    return EmailTemplateModel.fromJson(response);
  }

  Future<EmailTemplateModel> updateEmailTemplate(int id, Map<String, dynamic> data) async {
    final response = await ApiClient.instance.patch('${AppConstants.emailTemplatesEndpoint}$id/', body: data);
    return EmailTemplateModel.fromJson(response);
  }

  Future<void> deleteEmailTemplate(int id) async {
    await ApiClient.instance.delete('${AppConstants.emailTemplatesEndpoint}$id/');
  }

  // Email Campaigns
  Future<Map<String, dynamic>> getEmailCampaigns({int page = 1}) async {
    final response = await ApiClient.instance.get(
      AppConstants.emailCampaignsEndpoint,
      queryParams: {'page': page.toString()},
    );
    if (response is List) {
      final results = _mapList(response, (j) => EmailCampaignModel.fromJson(j));
      return {'results': results, 'count': results.length};
    }
    final results = _mapList(response['results'], (j) => EmailCampaignModel.fromJson(j));
    return {
      'results': results,
      'count': _asInt(response['count']),
    };
  }

  Future<EmailCampaignModel> createCampaign(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post(AppConstants.emailCampaignsEndpoint, body: data);
    return EmailCampaignModel.fromJson(response);
  }

  Future<EmailCampaignModel> updateCampaign(int id, Map<String, dynamic> data) async {
    final response = await ApiClient.instance.patch('${AppConstants.emailCampaignsEndpoint}$id/', body: data);
    return EmailCampaignModel.fromJson(response);
  }

  // Emails
  Future<Map<String, dynamic>> getEmails({int page = 1, String? status, int? leadId}) async {
    final params = <String, dynamic>{'page': page.toString()};
    if (status != null) params['status'] = status;
    if (leadId != null) params['lead'] = leadId.toString();
    final response = await ApiClient.instance.get(AppConstants.emailsEndpoint, queryParams: params);
    if (response is List) {
      final results = _mapList(response, (j) => EmailModel.fromJson(j));
      return {'results': results, 'count': results.length};
    }
    final results = _mapList(response['results'], (j) => EmailModel.fromJson(j));
    return {
      'results': results,
      'count': _asInt(response['count']),
    };
  }

  // Email Sequences
  Future<List<EmailSequenceModel>> getEmailSequences() async {
    final response = await ApiClient.instance.get(AppConstants.emailSequencesEndpoint);
    final list = response is List ? response : (response is Map ? (response['results'] as List? ?? []) : []);
    return _mapList(list, (j) => EmailSequenceModel.fromJson(j));
  }

  Future<EmailSequenceModel> createEmailSequence(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post(AppConstants.emailSequencesEndpoint, body: data);
    return EmailSequenceModel.fromJson(response);
  }
}
