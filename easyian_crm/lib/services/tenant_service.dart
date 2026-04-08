import 'package:file_picker/file_picker.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/api_client.dart';

class TenantService {
  static final TenantService instance = TenantService._();
  TenantService._();

  Future<Map<String, dynamic>> getMe() async {
    final data = await ApiClient.instance.get(AppConstants.tenantMeEndpoint);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<String?> uploadLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return null;

    final data = await ApiClient.instance.patchMultipart(
      AppConstants.tenantMeEndpoint,
      fileField: 'logo',
      fileBytes: bytes,
      filename: file.name,
    );
    if (data is Map && data['logo'] is String) {
      return data['logo'] as String;
    }
    return null;
  }
}
