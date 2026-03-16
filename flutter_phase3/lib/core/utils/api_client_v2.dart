// lib/core/utils/api_client_v2.dart
// REPLACE your existing api_client.dart with this version.
// Key additions:
//   • Auto-injects X-Tenant-ID header on every request
//   • tenantId setter — call after login/tenant selection
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  String? _token;
  String? _tenantId;

  void setToken(String token) => _token = token;
  void setTenantId(String? id) => _tenantId = id;

  Future<void> loadFromPrefs() async {
    final p = await SharedPreferences.getInstance();
    _token    = p.getString(AppConstants.tokenKey);
    _tenantId = p.getString(AppConstants.tenantIdKey);
  }

  Map<String, String> _headers() {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) h['Authorization'] = 'Token $_token';
    if (_tenantId != null && _tenantId!.isNotEmpty) h['X-Tenant-ID'] = _tenantId!;
    return h;
  }

  Uri _uri(String path, {Map<String, dynamic>? params}) {
    final base = Uri.parse(AppConstants.baseUrl);
    Uri uri = Uri(
      scheme: base.scheme, host: base.host, port: base.port, path: path,
    );
    if (params != null && params.isNotEmpty) {
      final clean = params.map((k, v) => MapEntry(k, v.toString()));
      uri = uri.replace(queryParameters: clean);
    }
    return uri;
  }

  dynamic _parse(http.Response r) {
    final body = utf8.decode(r.bodyBytes);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (body.isEmpty) return {};
      return jsonDecode(body);
    }
    String msg = 'Request failed (${r.statusCode})';
    try {
      final err = jsonDecode(body);
      if (err is Map) {
        if (err.containsKey('detail')) msg = err['detail'].toString();
        else if (err.containsKey('error')) msg = err['error'].toString();
        else msg = err.values.first.toString();
      }
    } catch (_) {}
    throw ApiException(msg, statusCode: r.statusCode);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    final r = await http.get(_uri(path, params: queryParams), headers: _headers());
    return _parse(r);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool noAuth = false}) async {
    final h = noAuth ? {'Content-Type': 'application/json'} : _headers();
    final r = await http.post(_uri(path), headers: h, body: jsonEncode(body ?? {}));
    return _parse(r);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final r = await http.patch(_uri(path), headers: _headers(), body: jsonEncode(body ?? {}));
    return _parse(r);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final r = await http.put(_uri(path), headers: _headers(), body: jsonEncode(body ?? {}));
    return _parse(r);
  }

  Future<void> delete(String path) async {
    final r = await http.delete(_uri(path), headers: _headers());
    if (r.statusCode >= 400) _parse(r);
  }
}
