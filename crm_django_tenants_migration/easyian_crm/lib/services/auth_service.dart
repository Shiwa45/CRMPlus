// lib/services/auth_service.dart  ← FULL REPLACEMENT
//
// Key changes vs previous version:
//   • login() reads tenant_slug, tenant_name, tenant_id, tenant_role,
//     schema_name from the new login response and persists them.
//   • ApiClient.instance.setTenantSlug() is called right after token is set
//     so every subsequent request automatically includes X-Tenant-ID: <slug>.
//   • logout() clears all tenant prefs.
//   • checkAuth() restores the slug into ApiClient on app restart.

import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/api_client.dart';
import '../models/user_model.dart';

// small helper — same as in services.dart
int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // ── Login ────────────────────────────────────────────────────────────────────

  /// POST /api/auth/login/
  ///
  /// The new response shape (from our updated accounts/api.py):
  /// {
  ///   "token":        "abc123",
  ///   "user_id":      1,
  ///   "username":     "sharma_admin",
  ///   "email":        "rajesh@sharmainfotech.in",
  ///   "role":         "admin",
  ///   "schema_name":  "sharma_infotech",
  ///   "tenant_id":    3,
  ///   "tenant_name":  "Sharma InfoTech Pvt Ltd",
  ///   "tenant_slug":  "sharma-infotech",     ← THIS goes in X-Tenant-ID
  ///   "tenant_role":  "tenant_admin",
  ///   "plan_name":    "Professional"
  /// }
  Future<UserModel> login(String username, String password) async {
    // Login always goes to the PUBLIC schema — no tenant header needed yet.
    final data = await ApiClient.instance.postNoAuth(
      AppConstants.loginEndpoint,
      body: {'username': username, 'password': password},
    );

    // ── Extract fields ────────────────────────────────────────────────────────
    final token      = (data['token']       ?? '').toString();
    final userId     = _toInt(data['user_id']);
    final email      = (data['email']       ?? '').toString();
    final role       = (data['role']        ?? '').toString();
    final tenantSlug = (data['tenant_slug'] ?? '').toString(); // ← KEY FIELD
    final tenantId   = _toInt(data['tenant_id']);
    final tenantName = (data['tenant_name'] ?? '').toString();
    final tenantRole = (data['tenant_role'] ?? '').toString();
    final schemaName = (data['schema_name'] ?? '').toString();

    // ── Persist ───────────────────────────────────────────────────────────────
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey,      token);
    await prefs.setInt   (AppConstants.userIdKey,     userId);
    await prefs.setString(AppConstants.userEmailKey,  email);
    await prefs.setString(AppConstants.userRoleKey,   role);
    await prefs.setString(AppConstants.tenantSlugKey, tenantSlug);
    await prefs.setInt   (AppConstants.userIdKey,     userId);
    if (tenantId > 0)         await prefs.setInt   (AppConstants.tenantIdKey,   tenantId);
    if (tenantName.isNotEmpty) await prefs.setString(AppConstants.tenantNameKey, tenantName);
    if (tenantRole.isNotEmpty) await prefs.setString(AppConstants.tenantRoleKey, tenantRole);
    if (schemaName.isNotEmpty) await prefs.setString(AppConstants.schemaNameKey, schemaName);

    // ── Wire up ApiClient ─────────────────────────────────────────────────────
    ApiClient.instance.setToken(token);
    ApiClient.instance.setTenantSlug(tenantSlug.isNotEmpty ? tenantSlug : null);

    // ── Fetch full user profile (now using tenant schema) ─────────────────────
    final userResponse = await ApiClient.instance.get(
      '${AppConstants.usersEndpoint}$userId/',
    );
    _currentUser = UserModel.fromJson(userResponse);
    return _currentUser!;
  }

  // ── Logout ───────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    _currentUser = null;
    ApiClient.instance.setToken('');
    ApiClient.instance.setTenantSlug(null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userEmailKey);
    await prefs.remove(AppConstants.userRoleKey);
    await prefs.remove(AppConstants.tenantSlugKey);
    await prefs.remove(AppConstants.tenantIdKey);
    await prefs.remove(AppConstants.tenantNameKey);
    await prefs.remove(AppConstants.tenantRoleKey);
    await prefs.remove(AppConstants.schemaNameKey);
  }

  // ── Check / restore session ──────────────────────────────────────────────────

  Future<bool> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey) ?? '';
    if (token.isEmpty) return false;

    // Restore slug into ApiClient BEFORE any API call
    final slug = prefs.getString(AppConstants.tenantSlugKey) ?? '';
    ApiClient.instance.setToken(token);
    ApiClient.instance.setTenantSlug(slug.isNotEmpty ? slug : null);

    try {
      final userId = prefs.getInt(AppConstants.userIdKey);
      if (userId == null) return false;
      final userResponse = await ApiClient.instance.get(
        '${AppConstants.usersEndpoint}$userId/',
      );
      _currentUser = UserModel.fromJson(userResponse);
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<void> loadSavedUser() async => checkAuth();

  // ── Profile ──────────────────────────────────────────────────────────────────

  Future<UserModel?> getMe() async {
    try {
      final prefs  = await SharedPreferences.getInstance();
      final userId = prefs.getInt(AppConstants.userIdKey);
      if (userId == null) return null;
      final data = await ApiClient.instance.get(
        '${AppConstants.usersEndpoint}$userId/',
      );
      _currentUser = UserModel.fromJson(data);
      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> getProfile() async {
    final u = await getMe();
    if (u == null) throw ApiException('Not logged in');
    return u;
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final prefs  = await SharedPreferences.getInstance();
    final userId = prefs.getInt(AppConstants.userIdKey);
    if (userId == null) throw ApiException('Not logged in');
    final response = await ApiClient.instance.patch(
      '${AppConstants.usersEndpoint}$userId/',
      body: data,
    );
    _currentUser = UserModel.fromJson(response);
    return _currentUser!;
  }

  // ── Tenant context helpers ────────────────────────────────────────────────────

  /// Returns the currently active tenant slug (e.g. "sharma-infotech")
  Future<String?> get tenantSlug async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tenantSlugKey);
  }

  /// Returns the currently active tenant display name
  Future<String?> get tenantName async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tenantNameKey);
  }

  /// Returns the user's role within their tenant (e.g. "tenant_admin")
  Future<String?> get tenantRole async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tenantRoleKey);
  }

  /// Switch to a different tenant (for superadmins who belong to multiple tenants)
  Future<void> switchTenant(String slug, {
    int? tenantId,
    String? tenantName,
    String? tenantRole,
    String? schemaName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tenantSlugKey, slug);
    if (tenantId != null)    await prefs.setInt   (AppConstants.tenantIdKey,   tenantId);
    if (tenantName != null)  await prefs.setString(AppConstants.tenantNameKey, tenantName);
    if (tenantRole != null)  await prefs.setString(AppConstants.tenantRoleKey, tenantRole);
    if (schemaName != null)  await prefs.setString(AppConstants.schemaNameKey, schemaName);
    ApiClient.instance.setTenantSlug(slug);
  }
}
