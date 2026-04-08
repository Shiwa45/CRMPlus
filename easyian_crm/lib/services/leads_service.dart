import '../core/constants/app_constants.dart';
import '../core/utils/api_client.dart';
import '../models/lead_model.dart';

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

class LeadsService {
  static LeadsService? _instance;
  static LeadsService get instance => _instance ??= LeadsService._();
  LeadsService._();

  Future<Map<String, dynamic>> getLeads({
    int page = 1,
    String? status,
    String? priority,
    String? search,
    String? ordering,
  }) async {
    final params = <String, dynamic>{
      'page': page.toString(),
    };
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (ordering != null) params['ordering'] = ordering;

    final response = await ApiClient.instance.get(
      AppConstants.leadsEndpoint,
      queryParams: params,
    );

    if (response is List) {
      final results = _mapList(response, (j) => LeadModel.fromJson(j));
      return {
        'results': results,
        'count': results.length,
        'next': null,
        'previous': null,
      };
    }

    final results = _mapList(response['results'], (j) => LeadModel.fromJson(j));
    return {
      'results': results,
      'count': _asInt(response['count']),
      'next': response['next'],
      'previous': response['previous'],
    };
  }

  Future<LeadModel> getLead(int id) async {
    final response = await ApiClient.instance.get(
      '${AppConstants.leadsEndpoint}$id/',
    );
    return LeadModel.fromJson(response);
  }

  Future<LeadModel> createLead(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post(
      AppConstants.leadsEndpoint,
      body: data,
    );
    return LeadModel.fromJson(response);
  }

  Future<LeadModel> updateLead(int id, Map<String, dynamic> data) async {
    final response = await ApiClient.instance.patch(
      '${AppConstants.leadsEndpoint}$id/',
      body: data,
    );
    return LeadModel.fromJson(response);
  }

  Future<void> deleteLead(int id) async {
    await ApiClient.instance.delete('${AppConstants.leadsEndpoint}$id/');
  }

  Future<LeadStats> getLeadStats() async {
    final response = await ApiClient.instance.get(
      '${AppConstants.leadsEndpoint}stats/',
    );
    return LeadStats.fromJson(response);
  }

  Future<List<LeadSourceModel>> getLeadSources() async {
    final response = await ApiClient.instance.get(
      AppConstants.leadSourcesEndpoint,
    );
    final list = response is List ? response : (response is Map ? (response['results'] as List? ?? []) : []);
    return _mapList(list, (j) => LeadSourceModel.fromJson(j));
  }

  Future<LeadSourceModel> createLeadSource(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post(
      AppConstants.leadSourcesEndpoint,
      body: data,
    );
    return LeadSourceModel.fromJson(response);
  }

  Future<List<LeadActivityModel>> getLeadActivities(int leadId) async {
    final response = await ApiClient.instance.get(
      AppConstants.leadActivitiesEndpoint,
      queryParams: {'lead': leadId.toString()},
    );
    final list = response is List ? response : (response is Map ? (response['results'] as List? ?? []) : []);
    return _mapList(list, (j) => LeadActivityModel.fromJson(j));
  }

  Future<LeadActivityModel> addActivity(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post(
      AppConstants.leadActivitiesEndpoint,
      body: data,
    );
    return LeadActivityModel.fromJson(response);
  }

  Future<void> bulkUpdate(List<int> leadIds, String action, dynamic value) async {
    await ApiClient.instance.post('/leads/bulk-update/', body: {
      'lead_ids[]': leadIds.map((e) => e.toString()).toList(),
      'action': action,
      if (action == 'change_status') 'new_status': value,
      if (action == 'change_priority') 'new_priority': value,
      if (action == 'assign_to') 'new_assignee': value,
    });
  }
}
