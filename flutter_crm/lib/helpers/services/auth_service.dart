import 'package:henox/helpers/services/api_service.dart';
import 'package:henox/helpers/services/storage/local_storage.dart';

class AuthService {
  static bool isLoggedIn = false;

  /// Authenticate with the Django backend.
  /// Returns null on success, or a map of field errors on failure.
  static Future<Map<String, String>?> loginUser(Map<String, dynamic> data) async {
    final username = (data['email'] ?? data['username'] ?? '').toString();
    final password = (data['password'] ?? '').toString();

    final success = await ApiService.login(username, password);
    if (success) {
      isLoggedIn = true;
      await LocalStorage.setLoggedInUser(true);
      return null;
    }
    return {'username': 'Invalid username or password. Please try again.'};
  }

  static Future<void> logoutUser() async {
    isLoggedIn = false;
    await ApiService.logout();
    await LocalStorage.setLoggedInUser(false);
  }
}
