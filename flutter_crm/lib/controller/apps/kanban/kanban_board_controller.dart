import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:henox/controller/my_controller.dart';
import 'package:henox/helpers/services/api_service.dart';

class LeadsController extends MyController {
  List<Map<String, dynamic>> leads = [];
  bool isLoading = false;
  bool _isFetching = false;

  // Columns in kanban order
  static const List<String> statusColumns = [
    'new', 'contacted', 'qualified', 'proposal', 'negotiation', 'won', 'lost'
  ];

  static const Map<String, String> statusLabels = {
    'new': 'New',
    'contacted': 'Contacted',
    'qualified': 'Qualified',
    'proposal': 'Proposal Sent',
    'negotiation': 'Negotiation',
    'won': 'Won',
    'lost': 'Lost',
  };

  static const Map<String, Color> statusColors = {
    'new': Color(0xFF6366F1),
    'contacted': Color(0xFF3B82F6),
    'qualified': Color(0xFF8B5CF6),
    'proposal': Color(0xFFF59E0B),
    'negotiation': Color(0xFFEF4444),
    'won': Color(0xFF10B981),
    'lost': Color(0xFF6B7280),
  };

  static const Map<String, Color> priorityColors = {
    'hot': Color(0xFFEF4444),
    'warm': Color(0xFFF59E0B),
    'cold': Color(0xFF3B82F6),
  };

  // Returns leads filtered by status
  List<Map<String, dynamic>> leadsForStatus(String status) =>
      leads.where((l) => (l['status'] ?? 'new') == status).toList();

  @override
  void onInit() {
    super.onInit();
    fetchLeads();
  }

  Future<void> fetchLeads() async {
    if (_isFetching) return;
    _isFetching = true;
    isLoading = true;
    update();
    try {
      final data = await ApiService.getLeads();
      leads = data.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('LeadsController error: $e');
    } finally {
      isLoading = false;
      _isFetching = false;
      update();
    }
  }

  Future<void> createLead(Map<String, dynamic> body) async {
    final result = await ApiService.createLead(body);
    if (result != null) {
      await fetchLeads();
      Get.back();
      Get.snackbar('Success', 'Lead created successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white);
    } else {
      Get.snackbar('Error', 'Failed to create lead.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white);
    }
  }

  Future<void> updateLead(int id, Map<String, dynamic> body) async {
    final success = await ApiService.updateLead(id, body);
    if (success) {
      await fetchLeads();
      Get.back();
      Get.snackbar('Updated', 'Lead updated successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white);
    } else {
      Get.snackbar('Error', 'Failed to update lead.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white);
    }
  }

  Future<void> deleteLead(int id) async {
    final success = await ApiService.deleteLead(id);
    if (success) {
      leads.removeWhere((l) => l['id'] == id);
      update();
      Get.snackbar('Deleted', 'Lead deleted.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> updateStatus(int id, String newStatus) async {
    await ApiService.updateLead(id, {'status': newStatus});
    final idx = leads.indexWhere((l) => l['id'] == id);
    if (idx != -1) {
      leads[idx]['status'] = newStatus;
      update();
    }
  }
}
