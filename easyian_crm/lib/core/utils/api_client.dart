import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  Future<String?> get _token async {
    final p = await SharedPreferences.getInstance();
    return p.getString(AppConstants.tokenKey);
  }

  Future<Map<String, String>> get _headers async {
    final t = await _token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (t != null) 'Authorization': 'Token $t',
    };
  }

  Uri _uri(String ep, {Map<String, dynamic>? q}) {
    final uri = Uri.parse('${AppConstants.baseUrl}$ep');
    if (q == null || q.isEmpty) return uri;
    final clean = q.map((k, v) => MapEntry(k, v?.toString() ?? ''))
        ..removeWhere((_, v) => v.isEmpty);
    return uri.replace(queryParameters: clean);
  }

  void _check(http.Response r) {
    if (r.statusCode >= 400) {
      String msg;
      try {
        final b = jsonDecode(r.body);
        msg = b is Map
            ? (b['detail'] ?? b['message'] ?? b['non_field_errors']?.toString() ?? b.values.first?.toString() ?? 'Error ${r.statusCode}')
            : b.toString();
      } catch (_) { msg = 'Error ${r.statusCode}'; }
      throw ApiException(msg, statusCode: r.statusCode);
    }
  }

  Future<dynamic> get(String ep, {Map<String, dynamic>? q}) async {
    final r = await http.get(_uri(ep, q: q), headers: await _headers).timeout(const Duration(seconds: 30));
    _check(r); if (r.body.isEmpty) return null; return jsonDecode(r.body);
  }

  Future<dynamic> post(String ep, {Map<String, dynamic>? body, bool noAuth = false}) async {
    final h = noAuth ? {'Content-Type': 'application/json'} : await _headers;
    final r = await http.post(_uri(ep), headers: h, body: body != null ? jsonEncode(body) : null).timeout(const Duration(seconds: 30));
    _check(r); if (r.body.isEmpty) return null; return jsonDecode(r.body);
  }

  Future<dynamic> patch(String ep, {Map<String, dynamic>? body}) async {
    final r = await http.patch(_uri(ep), headers: await _headers, body: body != null ? jsonEncode(body) : null).timeout(const Duration(seconds: 30));
    _check(r); if (r.body.isEmpty) return null; return jsonDecode(r.body);
  }

  Future<dynamic> put(String ep, {Map<String, dynamic>? body}) async {
    final r = await http.put(_uri(ep), headers: await _headers, body: body != null ? jsonEncode(body) : null).timeout(const Duration(seconds: 30));
    _check(r); if (r.body.isEmpty) return null; return jsonDecode(r.body);
  }

  Future<void> delete(String ep) async {
    final r = await http.delete(_uri(ep), headers: await _headers).timeout(const Duration(seconds: 30));
    _check(r);
  }
}
