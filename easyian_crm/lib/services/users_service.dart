import '../core/constants/app_constants.dart';
import '../core/utils/api_client.dart';
import '../models/models.dart';

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

class UsersService {
  static UsersService? _instance;
  static UsersService get instance => _instance ??= UsersService._();
  UsersService._();

  Future<Map<String, dynamic>> getUsers({int page = 1, String? search}) async {
    final params = <String, dynamic>{'page': page.toString()};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final response = await ApiClient.instance.get(
      AppConstants.usersEndpoint,
      queryParams: params,
    );
    if (response is List) {
      final results = _mapList(response, (j) => UserModel.fromJson(j));
      return {'results': results, 'count': results.length};
    }
    final results = _mapList(response['results'], (j) => UserModel.fromJson(j));
    return {'results': results, 'count': _asInt(response['count'])};
  }

  Future<UserModel> getUser(int id) async {
    final response = await ApiClient.instance.get('${AppConstants.usersEndpoint}$id/');
    return UserModel.fromJson(response);
  }

  Future<UserModel> createUser(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post(AppConstants.usersEndpoint, body: data);
    return UserModel.fromJson(response);
  }

  Future<UserModel> updateUser(int id, Map<String, dynamic> data) async {
    final response = await ApiClient.instance.patch(
      '${AppConstants.usersEndpoint}$id/',
      body: data,
    );
    return UserModel.fromJson(response);
  }

  Future<void> deleteUser(int id) async {
    await ApiClient.instance.delete('${AppConstants.usersEndpoint}$id/');
  }
}
