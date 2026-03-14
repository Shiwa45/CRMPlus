import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/models.dart';
import '../services/services.dart';

enum AppRoute {
  dashboard, leads, analytics,
  emails, campaigns, templates, sequences,
  emailConfig, kpiTargets, users, profile, settings
}

class AppProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  UserModel? _user;
  AppRoute _currentRoute = AppRoute.dashboard;
  bool _loading = false;

  ThemeMode get themeMode => _themeMode;
  UserModel? get currentUser => _user;
  AppRoute get currentRoute => _currentRoute;
  bool get loading => _loading;
  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final theme = p.getString(AppConstants.themeKey);
    _themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    _user = await AuthService.instance.getMe();
    notifyListeners();
  }

  void navigate(AppRoute route) {
    _currentRoute = route;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    _loading = true; notifyListeners();
    try {
      await AuthService.instance.login(username, password);
      _user = await AuthService.instance.getMe();
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> logout() async {
    await AuthService.instance.logout();
    _user = null;
    _currentRoute = AppRoute.dashboard;
    notifyListeners();
  }

  void updateUser(UserModel u) { _user = u; notifyListeners(); }

  Future<void> toggleTheme() async {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    final p = await SharedPreferences.getInstance();
    await p.setString(AppConstants.themeKey, isDark ? 'dark' : 'light');
    notifyListeners();
  }
}
