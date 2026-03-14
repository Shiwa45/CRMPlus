import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/api_client.dart';
import '../core/utils/num_utils.dart';
import '../models/user_model.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<UserModel> login(String username, String password) async {
    final response = await ApiClient.instance.postNoAuth(
      AppConstants.loginEndpoint,
      body: {'username': username, 'password': password},
    );

    final token = response['token'] as String;
    final userId = toInt(response['user_id']);
    final email = response['email'] as String;
    final role = response['role'] as String;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setInt(AppConstants.userIdKey, userId);
    await prefs.setString(AppConstants.userEmailKey, email);
    await prefs.setString(AppConstants.userRoleKey, role);

    // Fetch full user profile
    final userResponse = await ApiClient.instance.get(
      '${AppConstants.usersEndpoint}$userId/',
    );
    _currentUser = UserModel.fromJson(userResponse);
    return _currentUser!;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userEmailKey);
    await prefs.remove(AppConstants.userRoleKey);
  }

  Future<bool> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token == null) return false;

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

  Future<void> loadSavedUser() async {
    await checkAuth();
  }

  Future<UserModel> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(AppConstants.userIdKey);
    if (userId == null) throw ApiException('Not logged in');
    final response = await ApiClient.instance.get(
      '${AppConstants.usersEndpoint}$userId/',
    );
    _currentUser = UserModel.fromJson(response);
    return _currentUser!;
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(AppConstants.userIdKey);
    if (userId == null) throw ApiException('Not logged in');
    final response = await ApiClient.instance.patch(
      '${AppConstants.usersEndpoint}$userId/',
      body: data,
    );
    _currentUser = UserModel.fromJson(response);
    return _currentUser!;
  }
}
