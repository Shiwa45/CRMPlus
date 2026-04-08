// lib/providers/app_provider.dart  ← FULL REPLACEMENT
//
// Key changes:
//   • login() delegates fully to AuthService — tenant slug is set there.
//   • _ensureTenant() uses tenantSlugKey instead of tenantIdKey.
//     It no longer looks up the integer 'id' field from the tenants list —
//     it reads 'slug' field and stores/sends that.
//   • init() calls AuthService.checkAuth() which also restores the slug.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/api_client.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/services.dart' hide AuthService;

enum AppRoute {
  // Core
  dashboard,
  // CRM
  leads, contacts, companies,
  // Sales
  pipeline, deals,
  // Finance
  quotes, invoices, products,
  // Support
  tickets, tasks,
  // Automation
  workflows,
  // Analytics
  analytics,
  // Communications
  emails, campaigns, templates, sequences,
  // Settings / Admin
  emailConfig, kpiTargets, users, profile, superAdmin, settings,
}

class AppProvider extends ChangeNotifier {
  static final GlobalKey<NavigatorState> shellNavigatorKey =
      GlobalKey<NavigatorState>();

  ThemeMode  _themeMode    = ThemeMode.light;
  UserModel? _user;
  AppRoute   _currentRoute = AppRoute.dashboard;
  bool       _loading      = false;
  int        _unreadNotifs = 0;
  String?    _tenantName;   // for display in the UI
  String?    _tenantLogo;   // logo url

  ThemeMode  get themeMode    => _themeMode;
  UserModel? get currentUser  => _user;
  AppRoute   get currentRoute => _currentRoute;
  bool       get loading      => _loading;
  bool       get isDark       => _themeMode == ThemeMode.dark;
  int        get unreadNotifs => _unreadNotifs;
  String?    get tenantName   => _tenantName;
  String?    get tenantLogo   => _tenantLogo;

  // ── App init (called at startup) ────────────────────────────────────────────

  Future<void> init() async {
    final p     = await SharedPreferences.getInstance();
    final theme = p.getString(AppConstants.themeKey);
    _themeMode  = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;

    // Restore token + tenant slug into ApiClient
    await ApiClient.instance.loadFromPrefs();

    // Try to restore user session
    final ok = await AuthService.instance.checkAuth();
    if (ok) {
      _user       = AuthService.instance.currentUser;
      _tenantName = p.getString(AppConstants.tenantNameKey);
      _tenantLogo = p.getString(AppConstants.tenantLogoKey);
      _refreshNotifCount();
    }
    notifyListeners();
  }

  // ── Navigation ────────────────────────────────────────────────────────────────

  void navigate(AppRoute route) {
    if (_currentRoute != route) {
      _currentRoute = route;
      shellNavigatorKey.currentState?.popUntil((r) => r.isFirst);
      notifyListeners();
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────────

  Future<void> login(String username, String password) async {
    _loading = true;
    notifyListeners();
    try {
      // AuthService.login() handles:
      //   1. POST /api/auth/login/  (no tenant header — goes to public schema)
      //   2. Saving token + tenant_slug + all tenant fields to SharedPreferences
      //   3. Setting ApiClient token + slug
      //   4. Fetching full user profile
      _user = await AuthService.instance.login(username, password);

      // Refresh display name from prefs
      final p = await SharedPreferences.getInstance();
      _tenantName = p.getString(AppConstants.tenantNameKey);
      _tenantLogo = p.getString(AppConstants.tenantLogoKey);

      _refreshNotifCount();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await AuthService.instance.logout();
    _user        = null;
    _tenantName  = null;
    _tenantLogo  = null;
    _currentRoute = AppRoute.dashboard;
    _unreadNotifs = 0;
    notifyListeners();
  }

  // ── Theme ─────────────────────────────────────────────────────────────────────

  Future<void> toggleTheme() async {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    final p    = await SharedPreferences.getInstance();
    await p.setString(AppConstants.themeKey, isDark ? 'dark' : 'light');
    notifyListeners();
  }

  // ── User updates ──────────────────────────────────────────────────────────────

  void updateUser(UserModel u) {
    _user = u;
    notifyListeners();
  }

  // ── Tenant switching (superadmin) ─────────────────────────────────────────────

  /// Called from the SuperAdmin screen when the admin wants to impersonate
  /// a tenant (i.e. browse that tenant's data).
  Future<void> switchTenant({
    required String slug,
    required String name,
    int?    tenantId,
    String? tenantRole,
    String? schemaName,
  }) async {
    await AuthService.instance.switchTenant(
      slug,
      tenantId:   tenantId,
      tenantName: name,
      tenantRole: tenantRole,
      schemaName: schemaName,
    );
    _tenantName = name;
    notifyListeners();
  }

  // ── Notifications ─────────────────────────────────────────────────────────────

  Future<void> _refreshNotifCount() async {
    try {
      _unreadNotifs = await NotificationsService.instance.getUnreadCount();
      notifyListeners();
    } catch (_) {}
  }

  void decrementNotif() {
    if (_unreadNotifs > 0) {
      _unreadNotifs--;
      notifyListeners();
    }
  }

  void clearNotifs() {
    _unreadNotifs = 0;
    notifyListeners();
  }

  Future<void> setTenantLogo(String? url) async {
    _tenantLogo = url;
    final p = await SharedPreferences.getInstance();
    if (url == null || url.isEmpty) {
      await p.remove(AppConstants.tenantLogoKey);
    } else {
      await p.setString(AppConstants.tenantLogoKey, url);
    }
    notifyListeners();
  }
}
