import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:henox/controller/apps/task/task_list_controller.dart';
import 'package:henox/controller/my_controller.dart';
import 'package:henox/helpers/services/api_service.dart';

class CheckboxItem {
  final String label;
  final String avatar;
  bool isChecked;

  CheckboxItem({required this.label, required this.avatar, this.isChecked = false});
}

class AddTaskController extends MyController {
  final formKey = GlobalKey<FormState>();
  late TextEditingController projectNameController, titleController, clientNameController;
  DateTime? selectedDate;
  String status = 'New';
  String priority = 'Medium';
  bool isSaving = false;

  @override
  void onInit() {
    projectNameController = TextEditingController();
    titleController = TextEditingController();
    clientNameController = TextEditingController();
    super.onInit();
  }

  String? projectNameValidation(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a project name';
    return null;
  }

  String? titleValidation(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a title';
    return null;
  }

  String? clientNameValidation(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a client name';
    return null;
  }

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
        context: Get.context!,
        initialDate: selectedDate ?? DateTime.now(),
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      selectedDate = picked;
      update();
    }
  }

  void onSelectPriority(String value) {
    priority = value;
    update();
  }

  Future<void> onTapAddTask() async {
    if (formKey.currentState?.validate() ?? false) {
      isSaving = true;
      update();
      final body = {
        'first_name': titleController.text.trim(),
        'last_name': clientNameController.text.trim(),
        'email': '${titleController.text.replaceAll(' ', '').toLowerCase()}@task.local',
        'status': status.toLowerCase(),
        'source': 'Website',
        'notes': 'Project: ${projectNameController.text}',
        if (selectedDate != null)
          'follow_up_date': selectedDate!.toIso8601String().substring(0, 10),
      };
      final result = await ApiService.createLead(body);
      isSaving = false;
      if (result != null) {
        projectNameController.clear();
        clientNameController.clear();
        titleController.clear();
        Get.back();
        // Refresh the task list
        if (Get.isRegistered<TaskListController>()) {
          Get.find<TaskListController>().refresh();
        }
      } else {
        Get.snackbar('Error', 'Failed to save task. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red[100]);
      }
      update();
    }
  }

  List<CheckboxItem> checkboxItems = [
    CheckboxItem(label: 'James Forbes', avatar: 'avatar-2.jpg'),
    CheckboxItem(label: 'John Robles', avatar: 'avatar-3.jpg'),
    CheckboxItem(label: 'Mary Gant', avatar: 'avatar-4.jpg'),
    CheckboxItem(label: 'Curtis Saenz', avatar: 'avatar-1.jpg'),
    CheckboxItem(label: 'Virgie Price', avatar: 'avatar-5.jpg'),
    CheckboxItem(label: 'Anthony Mills', avatar: 'avatar-10.jpg'),
    CheckboxItem(label: 'Marian Angel', avatar: 'avatar-6.jpg'),
    CheckboxItem(label: 'Johnnie Walton', avatar: 'avatar-7.jpg'),
    CheckboxItem(label: 'Donna Weston', avatar: 'avatar-8.jpg'),
    CheckboxItem(label: 'Diego Norris', avatar: 'avatar-9.jpg'),
  ];
}
