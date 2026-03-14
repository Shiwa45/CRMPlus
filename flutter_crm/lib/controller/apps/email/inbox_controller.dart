import 'package:get/get.dart';
import 'package:henox/controller/my_controller.dart';
import 'package:henox/helpers/services/api_service.dart';

class InboxController extends MyController {
  List<Map<String, dynamic>> emails = [];
  bool isLoading = false;
  bool _isFetching = false; // guard against recursive rebuild calls

  @override
  void onInit() {
    super.onInit();
    _loadEmails();
  }

  Future<void> _loadEmails() async {
    if (_isFetching) return; // prevent re-entrant calls
    _isFetching = true;
    isLoading = true;
    update();
    try {
      final data = await ApiService.getEmails();
      emails = data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('InboxController error: $e');
    } finally {
      isLoading = false;
      _isFetching = false;
      update();
    }
  }

  Future<void> refresh() => _loadEmails();

  void onCheckMail(Map<String, dynamic> mail) {
    mail['_checked'] = !(mail['_checked'] ?? false);
    update();
  }

  Future<void> markAsRead(Map<String, dynamic> mail) async {
    final id = mail['id'];
    if (id != null) {
      await ApiService.markEmailRead(id as int);
      mail['is_read'] = true;
      update();
    }
  }

  void gotoDetailScreen() {
    Get.toNamed('/apps/read-email');
  }
}
