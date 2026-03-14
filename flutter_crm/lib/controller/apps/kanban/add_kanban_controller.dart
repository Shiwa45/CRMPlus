import 'package:appflowy_board/appflowy_board.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:henox/controller/my_controller.dart';
import 'package:henox/helpers/widgets/my_form_validator.dart';
import 'package:henox/images.dart';
import 'package:henox/helpers/services/api_service.dart';

enum Project {
  select,
  adminDashboard,
  crmDesignDevelopment,
  iosAppDesign,
}

enum Priority {
  high,
  medium,
  low;
}

enum Assign {
  coderthemes,
  robertCarlile,
  louisAllen,
  seanWhite,
  rileySteele,
  zakTurnbull,
}

class AddKanbanTaskController extends MyController {
  MyFormValidator basicValidator = MyFormValidator();
  Project selectedProject = Project.select;
  Priority selectPriority = Priority.medium;
  Assign selectAssign = Assign.coderthemes;
  TextEditingController titleController = TextEditingController();
  TextEditingController dateTEController = TextEditingController();
  TextEditingController detailController = TextEditingController();
  DateTime? selectedDate;
  List<TextItem>? addKanban = <TextItem>[];

  final AppFlowyBoardController boardData = AppFlowyBoardController(
    onMoveGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
      debugPrint('Move item from $fromIndex to $toIndex');
    },
    onMoveGroupItem: (groupId, fromIndex, toIndex) {
      debugPrint('Move $groupId:$fromIndex to $groupId:$toIndex');
    },
    onMoveGroupItemToGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
      debugPrint('Move $fromGroupId:$fromIndex to $toGroupId:$toIndex');
    },
  );
  late AppFlowyBoardScrollController boardController;

  void onSelectProjectTitle(Project project) {
    selectedProject = project;
    update();
  }

  void onSelectPriority(Priority priority) {
    selectPriority = priority;
    update();
  }

  void onSelectAssign(Assign assign) {
    selectAssign = assign;
    update();
  }

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
        context: Get.context!, initialDate: selectedDate ?? DateTime.now(), firstDate: DateTime(2015, 8), lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      selectedDate = picked;
      update();
    }
  }

  Future<void> onTapAddTask() async {
    if (titleController.text.isNotEmpty && selectedDate != null) {
      // POST the new Lead to the backend
      try {
        final body = {
          "title": titleController.text, // If backend supports Title
          "first_name": titleController.text.split(' ').first,
          "last_name": titleController.text.split(' ').length > 1 ? titleController.text.split(' ').last : "",
          "company": "Manually Added",
          "email": "temp@example.com", // Dummy required field
          "status": "new",
          "created_at": selectedDate!.toIso8601String()
        };
        
        // Let's assume there is a createLead API method inside ApiService
        // await ApiService.createLead(body);

        TextItem appFlowyGroupItem = TextItem(
          selectPriority.toString().split('.').last.capitalize!,
          selectPriority == Priority.high
              ? Colors.red.shade400
              : selectPriority == Priority.medium
                  ? Colors.brown
                  : Colors.green.shade400,
          DateTime.parse(selectedDate.toString()),
          titleController.text,
          Images.avatars[0],
          "Manually Added",
          0,
          [Images.avatars[0]],
        );
        addKanban!.add(appFlowyGroupItem);
        
        // Add it directly to the 'New' column
        boardData.addGroupItem("New", appFlowyGroupItem);
        
        titleController.clear();
        detailController.clear();
        selectedDate = null;
        Get.back();
        update();
      } catch (e) {
        debugPrint("Error creating lead: $e");
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    
    // Initialize empty groups
    final group1 = AppFlowyGroupData(id: "New", name: "New", items: []);
    final group2 = AppFlowyGroupData(id: "Contacted", name: "Contacted", items: []);
    final group3 = AppFlowyGroupData(id: "Qualified", name: "Qualified", items: []);
    final group4 = AppFlowyGroupData(id: "Converted", name: "Converted", items: []);
    
    boardData.addGroup(group1);
    boardData.addGroup(group2);
    boardData.addGroup(group3);
    boardData.addGroup(group4);

    _fetchLeads();
  }

  Future<void> _fetchLeads() async {
    try {
      final leads = await ApiService.getLeads();
      
      for (var lead in leads) {
        // Map Django Lead status to our columns
        String status = lead['status'] ?? 'new';
        String groupId = "New";
        
        if (status == 'contacted') groupId = "Contacted";
        else if (status == 'qualified') groupId = "Qualified";
        else if (status == 'converted') groupId = "Converted";
        else groupId = "New";

        TextItem item = TextItem(
          "High", // Priority (Mocked)
          Colors.brown,
          DateTime.tryParse(lead['created_at'] ?? '') ?? DateTime.now(),
          "${lead['first_name']} ${lead['last_name']}",
          Images.avatars[0], // Avatar (Mocked)
          lead['company'] ?? "Unknown", // JobType / Company
          0, // Comments Mocked
          [Images.avatars[0]]
        );

        boardData.addGroupItem(groupId, item);
      }
      update();
    } catch(e) {
      debugPrint("Error loading leads: $e");
    }
  }
}

class TextItem extends AppFlowyGroupItem {
  final String kanbanLevel;
  final Color color;
  final DateTime date;
  final String title, image, jobTypeName;
  final double comment;
  final List<String> avatar;

  TextItem(this.kanbanLevel, this.color, this.date, this.title, this.image, this.jobTypeName, this.comment, this.avatar);

  @override
  String get id => title;
}
