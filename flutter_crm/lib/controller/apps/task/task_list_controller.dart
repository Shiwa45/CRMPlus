import 'package:henox/controller/my_controller.dart';
import 'package:henox/helpers/services/api_service.dart';

class TaskListController extends MyController {
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = false;
  bool _isFetching = false; // guard against recursive calls

  @override
  void onInit() {
    super.onInit();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    if (_isFetching) return; // prevent re-entrant calls
    _isFetching = true;
    isLoading = true;
    update();
    try {
      final data = await ApiService.getLeads();
      tasks = data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('TaskListController error: $e');
    } finally {
      isLoading = false;
      _isFetching = false;
      update();
    }
  }

  Future<void> refresh() => _loadTasks();

  Future<void> updateTaskStatus(int id, String newStatus) async {
    await ApiService.updateLead(id, {'status': newStatus});
    await _loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await ApiService.deleteLead(id);
    await _loadTasks();
  }
}
