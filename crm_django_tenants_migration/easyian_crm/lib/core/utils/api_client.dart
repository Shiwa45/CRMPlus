// lib/core/utils/api_client.dart  ← FULL REPLACEMENT
//
// Key change vs previous version:
//   • _tenantSlug stores the SLUG string (e.g. "sharma-infotech")
//   • X-Tenant-ID header now sends the SLUG — django-tenants middleware
//     reads it and switches to the matching PostgreSQL schema.
//   • The base URL and all endpoint paths are UNCHANGED.
//   • setTenantId(String? id) kept as an alias for backward compatibility
//     but the real setter is setTenantSlug().

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

// ── Exception ──────────────────────────────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int?   statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ── Client ────────────────────────────────────────────────────────────────────
class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  String? _token;
  String? _tenantSlug; // e.g. "sharma-infotech"

  // ── Setters ─────────────────────────────────────────────────────────────────

  void setToken(String token) => _token = token;

  /// Primary setter — pass the SLUG (e.g. "sharma-infotech").
  void setTenantSlug(String? slug) => _tenantSlug = slug;

  /// Backward-compatible alias — if you pass an integer string ("42") it is
  /// ignored and you should switch to setTenantSlug().
  void setTenantId(String? value) {
    if (value == null) {
      _tenantSlug = null;
      return;
    }
    // If the value looks like an integer PK, ignore it (old code path).
    // Only accept actual slug strings.
    if (int.tryParse(value) != null) return;
    _tenantSlug = value;
  }

  // ── Load persisted session ───────────────────────────────────────────────────

  Future<void> loadFromPrefs() async {
    final p     = await SharedPreferences.getInstance();
    _token      = p.getString(AppConstants.tokenKey);
    // Prefer slug key; fall back to old tenantIdKey if slug not yet stored
    _tenantSlug = p.getString(AppConstants.tenantSlugKey)
               ?? _coerceSlug(p.getString(AppConstants.tenantIdKey));
  }

  // ── Headers ──────────────────────────────────────────────────────────────────

  Map<String, String> _headers({bool noAuth = false}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept':       'application/json',
    };
    if (!noAuth && _token != null && _token!.isNotEmpty) {
      h['Authorization'] = 'Token $_token';
    }
    // Always send slug if available — even unauthenticated (login endpoint needs it)
    if (_tenantSlug != null && _tenantSlug!.isNotEmpty) {
      h['X-Tenant-ID'] = _tenantSlug!;
    }
    return h;
  }

  // ── URI builder ──────────────────────────────────────────────────────────────

  Uri _uri(String path, {Map<String, dynamic>? params}) {
    final base = Uri.parse(AppConstants.baseUrl);
    Uri uri = Uri(
      scheme: base.scheme,
      host:   base.host,
      port:   base.port,
      path:   path,
    );
    if (params != null && params.isNotEmpty) {
      final clean = params.map((k, v) => MapEntry(k, v.toString()));
      uri = uri.replace(queryParameters: clean);
    }
    return uri;
  }

  // ── Response parser ──────────────────────────────────────────────────────────

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
        if (err.containsKey('detail'))      msg = err['detail'].toString();
        else if (err.containsKey('error'))  msg = err['error'].toString();
        else if (err.isNotEmpty)            msg = err.values.first.toString();
      }
    } catch (_) {}
    throw ApiException(msg, statusCode: r.statusCode);
  }

  // ── HTTP verbs ───────────────────────────────────────────────────────────────

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    final r = await http.get(
      _uri(path, params: queryParams),
      headers: _headers(),
    );
    return _parse(r);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool noAuth = false,
  }) async {
    final r = await http.post(
      _uri(path),
      headers: _headers(noAuth: noAuth),
      body:    jsonEncode(body ?? {}),
    );
    return _parse(r);
  }

  /// Alias for post with noAuth: true  (used by auth_service.dart)
  Future<dynamic> postNoAuth(
    String path, {
    Map<String, dynamic>? body,
  }) =>
      post(path, body: body, noAuth: true);

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final r = await http.patch(
      _uri(path),
      headers: _headers(),
      body:    jsonEncode(body ?? {}),
    );
    return _parse(r);
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final r = await http.put(
      _uri(path),
      headers: _headers(),
      body:    jsonEncode(body ?? {}),
    );
    return _parse(r);
  }

  Future<dynamic> delete(String path) async {
    final r = await http.delete(_uri(path), headers: _headers());
    return _parse(r);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// If the stored value is an integer string it is not a slug — discard it.
  String? _coerceSlug(String? value) {
    if (value == null || value.isEmpty) return null;
    if (int.tryParse(value) != null)    return null; // old integer id — ignore
    return value;
  }
}
