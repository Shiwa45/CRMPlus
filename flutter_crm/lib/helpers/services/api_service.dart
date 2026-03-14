import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const Duration _timeout = Duration(seconds: 10);
  static String? authToken;

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Token $authToken',
      };

  // ─── Timeout-safe HTTP helpers ───────────────────────────────────────────

  static Future<http.Response?> _get(Uri uri) async {
    try {
      return await http.get(uri, headers: headers).timeout(_timeout);
    } catch (e) {
      print('GET $uri error: $e');
      return null;
    }
  }

  static Future<http.Response?> _post(Uri uri, Map<String, dynamic> body) async {
    try {
      return await http.post(uri, headers: headers, body: json.encode(body)).timeout(_timeout);
    } catch (e) {
      print('POST $uri error: $e');
      return null;
    }
  }

  static Future<http.Response?> _patch(Uri uri, Map<String, dynamic> body) async {
    try {
      return await http.patch(uri, headers: headers, body: json.encode(body)).timeout(_timeout);
    } catch (e) {
      print('PATCH $uri error: $e');
      return null;
    }
  }

  static Future<http.Response?> _delete(Uri uri) async {
    try {
      return await http.delete(uri, headers: headers).timeout(_timeout);
    } catch (e) {
      print('DELETE $uri error: $e');
      return null;
    }
  }

  static List<dynamic> _decodeListResponse(http.Response? response, {required String label}) {
    if (response == null) return [];
    if (response.statusCode != 200) {
      print('$label error: HTTP ${response.statusCode} - ${response.body}');
      return [];
    }
    try {
      final decoded = json.decode(response.body);
      if (decoded is List) return decoded;
      if (decoded is Map<String, dynamic> && decoded['results'] is List) {
        return decoded['results'] as List<dynamic>;
      }
      print('$label error: Unexpected response shape: ${decoded.runtimeType}');
    } catch (e) {
      print('$label decode error: $e');
    }
    return [];
  }

  // ─── Auth ────────────────────────────────────────────────────────────────

  static Future<bool> login(String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login/'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'username': username, 'password': password}),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        authToken = data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', authToken!);
        return true;
      }
    } catch (e) {
      print('Login error: $e');
    }
    return false;
  }

  static Future<void> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('auth_token');
  }

  static Future<void> logout() async {
    authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // ─── Leads ───────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getLeads({Map<String, String>? filters}) async {
    var uri = Uri.parse('$baseUrl/leads/');
    if (filters != null) uri = uri.replace(queryParameters: filters);
    final response = await _get(uri);
    return _decodeListResponse(response, label: 'getLeads');
  }

  static Future<Map<String, dynamic>?> getLead(int id) async {
    final response = await _get(Uri.parse('$baseUrl/leads/$id/'));
    if (response?.statusCode == 200) {
      try { return json.decode(response!.body); } catch (_) {}
    }
    return null;
  }

  static Future<Map<String, dynamic>?> createLead(Map<String, dynamic> body) async {
    final response = await _post(Uri.parse('$baseUrl/leads/'), body);
    if (response?.statusCode == 201) {
      try { return json.decode(response!.body); } catch (_) {}
    }
    print('createLead failed: ${response?.statusCode} ${response?.body}');
    return null;
  }

  static Future<bool> updateLead(int id, Map<String, dynamic> body) async {
    final response = await _patch(Uri.parse('$baseUrl/leads/$id/'), body);
    return response?.statusCode == 200;
  }

  static Future<bool> deleteLead(int id) async {
    final response = await _delete(Uri.parse('$baseUrl/leads/$id/'));
    return response?.statusCode == 204;
  }

  // ─── Lead Activities ─────────────────────────────────────────────────────

  static Future<List<dynamic>> getLeadActivities({int? leadId}) async {
    var uri = Uri.parse('$baseUrl/lead-activities/');
    if (leadId != null) uri = uri.replace(queryParameters: {'lead': '$leadId'});
    final response = await _get(uri);
    return _decodeListResponse(response, label: 'getLeadActivities');
  }

  static Future<bool> addLeadActivity(Map<String, dynamic> body) async {
    final response = await _post(Uri.parse('$baseUrl/lead-activities/'), body);
    return response?.statusCode == 201;
  }

  // ─── Users / Contacts ────────────────────────────────────────────────────

  static Future<List<dynamic>> getUsers() async {
    final response = await _get(Uri.parse('$baseUrl/users/'));
    return _decodeListResponse(response, label: 'getUsers');
  }

  static Future<Map<String, dynamic>?> createUser(Map<String, dynamic> body) async {
    final response = await _post(Uri.parse('$baseUrl/users/'), body);
    if (response?.statusCode == 201) {
      try { return json.decode(response!.body); } catch (_) {}
    }
    return null;
  }

  static Future<bool> deleteUser(int id) async {
    final response = await _delete(Uri.parse('$baseUrl/users/$id/'));
    return response?.statusCode == 204;
  }

  // ─── Emails ──────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getEmails({String? folder}) async {
    var uri = Uri.parse('$baseUrl/emails/');
    if (folder != null) uri = uri.replace(queryParameters: {'folder': folder});
    final response = await _get(uri);
    return _decodeListResponse(response, label: 'getEmails');
  }

  static Future<bool> sendEmail(Map<String, dynamic> body) async {
    final response = await _post(Uri.parse('$baseUrl/emails/'), body);
    return response?.statusCode == 201;
  }

  static Future<bool> markEmailRead(int id) async {
    final response = await _patch(Uri.parse('$baseUrl/emails/$id/'), {'is_read': true});
    return response?.statusCode == 200;
  }

  // ─── Email Templates ─────────────────────────────────────────────────────

  static Future<List<dynamic>> getEmailTemplates() async {
    final response = await _get(Uri.parse('$baseUrl/email-templates/'));
    return _decodeListResponse(response, label: 'getEmailTemplates');
  }

  // ─── Email Campaigns ─────────────────────────────────────────────────────

  static Future<List<dynamic>> getEmailCampaigns() async {
    final response = await _get(Uri.parse('$baseUrl/email-campaigns/'));
    return _decodeListResponse(response, label: 'getEmailCampaigns');
  }

  // ─── Dashboard & KPIs ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final results = await Future.wait([
        _get(Uri.parse('$baseUrl/leads/')),
        _get(Uri.parse('$baseUrl/users/')),
        _get(Uri.parse('$baseUrl/kpi-targets/')),
      ]);

      int leadsCount = 0;
      int usersCount = 0;
      List kpis = [];

      final leadsResp = results[0];
      final usersResp = results[1];
      final kpiResp = results[2];

      if (leadsResp?.statusCode == 200) {
        final decoded = json.decode(leadsResp!.body);
        leadsCount = decoded is List ? decoded.length : 0;
      }
      if (usersResp?.statusCode == 200) {
        final decoded = json.decode(usersResp!.body);
        usersCount = decoded is List ? decoded.length : 0;
      }
      if (kpiResp?.statusCode == 200) {
        final decoded = json.decode(kpiResp!.body);
        kpis = decoded is List ? decoded : [];
      }
      return {'leads': leadsCount, 'users': usersCount, 'kpis': kpis};
    } catch (e) {
      print('getDashboardStats error: $e');
    }
    return {'leads': 0, 'users': 0, 'kpis': []};
  }
}
