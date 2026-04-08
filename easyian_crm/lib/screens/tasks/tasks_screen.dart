// lib/screens/tasks/tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/desktop_widgets.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<TaskModel> _tasks = [];
  bool _loading = true;
  int _total = 0, _page = 1;
  static const _pageSize = 50;
  String? _filterStatus;
  bool _myTasks = true, _overdueOnly = false;
  bool _showForm = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load({bool reset = false}) async {
    if (reset) setState(() => _page = 1);
    setState(() => _loading = true);
    try {
      final r = await TasksService.instance.getTasks(
        page: _page, status: _filterStatus,
        myTasks: _myTasks ? true : null,
        overdue: _overdueOnly ? true : null);
      setState(() { _tasks = r['results'] as List<TaskModel>; _total = r['count'] as int; });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _complete(TaskModel t) async {
    try {
      await TasksService.instance.completeTask(t.id);
      _load(reset: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  Future<void> _delete(TaskModel t) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text('Delete task?', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      content: Text('"${t.title}"'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    )) ?? false;
    if (!ok) return;
    try { await TasksService.instance.deleteTask(t.id); } catch (_) {}
    _load(reset: true);
  }

  Color _typeColor(String type) => switch (type) {
    'call'         => AppColors.info,
    'email'        => AppColors.primary,
    'meeting'      => AppColors.warning,
    'follow_up'    => AppColors.success,
    'demo'         => const Color(0xFF8b5cf6),
    _              => AppColors.lightTextMuted,
  };

  IconData _typeIcon(String type) => switch (type) {
    'call'      => Icons.phone_rounded,
    'email'     => Icons.email_rounded,
    'meeting'   => Icons.groups_rounded,
    'follow_up' => Icons.repeat_rounded,
    'demo'      => Icons.slideshow_rounded,
    _           => Icons.task_alt_rounded,
  };

  Widget _badge(String l, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
    child: Text(l, style: GoogleFonts.inter(fontSize: 11, color: c, fontWeight: FontWeight.w600)));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      PageHeader(
        title: 'Tasks', subtitle: '$_total tasks',
        actions: [
          CrmButton(label: 'Add Task', icon: Icons.add_rounded, primary: true,
              onPressed: () => setState(() => _showForm = true)),
        ],
      ),
      TableToolbar(
        searchCtrl: null, searchHint: '',
        filters: [
          FilterDropdown<String?>(value: _filterStatus, hint: 'All Status',
            items: const [
              DropdownMenuItem(value: null,        child: Text('All')),
              DropdownMenuItem(value: 'todo',       child: Text('To Do')),
              DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
              DropdownMenuItem(value: 'done',       child: Text('Done')),
            ],
            onChanged: (v) { setState(() => _filterStatus = v); _load(reset: true); }),
          const SizedBox(width: 8),
          _Chip(label: 'My Tasks', active: _myTasks,
              onTap: () { setState(() => _myTasks = !_myTasks); _load(reset: true); }),
          const SizedBox(width: 8),
          _Chip(label: 'Overdue', active: _overdueOnly, color: AppColors.error,
              onTap: () { setState(() => _overdueOnly = !_overdueOnly); _load(reset: true); }),
        ],
        actions: [Text('$_total total', style: GoogleFonts.inter(fontSize: 12,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted))],
      ),
      Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      Expanded(
        child: Stack(children: [
          _loading && _tasks.isEmpty ? const TableShimmer(rows: 10)
              : _tasks.isEmpty ? EmptyState(icon: Icons.task_alt_outlined,
                  title: 'No tasks', subtitle: 'Add your first task to get started',
                  actionLabel: 'Add Task', onAction: () => setState(() => _showForm = true))
              : DataTable2(
                  columnSpacing: 12, horizontalMargin: 16, minWidth: 820,
                  headingRowHeight: 40, dataRowHeight: 52,
                  headingTextStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  columns: const [
                    DataColumn2(label: Text('Done'), size: ColumnSize.S),
                    DataColumn2(label: Text('Task'), size: ColumnSize.L),
                    DataColumn2(label: Text('Type'), size: ColumnSize.S),
                    DataColumn2(label: Text('Assigned To'), size: ColumnSize.M),
                    DataColumn2(label: Text('Due Date'), size: ColumnSize.M),
                    DataColumn2(label: Text('Priority'), size: ColumnSize.S),
                    DataColumn2(label: Text('Actions'), size: ColumnSize.S, numeric: true),
                  ],
                  rows: _tasks.map((t) => DataRow2(
                    color: t.isOverdue && t.status != 'done'
                        ? MaterialStateProperty.all(AppColors.error.withOpacity(0.04))
                        : null,
                    cells: [
                      DataCell(Checkbox(
                        value: t.status == 'done',
                        onChanged: t.status != 'done' ? (_) => _complete(t) : null,
                        activeColor: AppColors.success,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)))),
                      DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, children: [
                        Text(t.title,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500,
                            decoration: t.status == 'done' ? TextDecoration.lineThrough : null,
                            color: t.status == 'done'
                                ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                : (isDark ? AppColors.darkText : AppColors.lightText)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (t.description != null && t.description!.isNotEmpty)
                          Text(t.description!, style: GoogleFonts.inter(fontSize: 11,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                      DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_typeIcon(t.taskType), size: 14, color: _typeColor(t.taskType)),
                        const SizedBox(width: 4),
                        Text(t.taskType.replaceAll('_', ' '), style: GoogleFonts.inter(fontSize: 11,
                            color: _typeColor(t.taskType))),
                      ])),
                      DataCell(Text(t.assignedToName ?? '—', style: GoogleFonts.inter(fontSize: 12))),
                      DataCell(t.dueDate != null
                          ? Row(mainAxisSize: MainAxisSize.min, children: [
                              if (t.isOverdue && t.status != 'done')
                                const Icon(Icons.warning_rounded, size: 13, color: AppColors.error),
                              const SizedBox(width: 4),
                              Text(t.dueDate!.length > 10 ? t.dueDate!.substring(0,10) : t.dueDate!,
                                  style: GoogleFonts.inter(fontSize: 12,
                                      color: t.isOverdue && t.status != 'done'
                                          ? AppColors.error : null)),
                            ])
                          : Text('—', style: GoogleFonts.inter(fontSize: 12))),
                      DataCell(_badge(t.priority.toUpperCase(), switch(t.priority) {
                        'high' => AppColors.error, 'medium' => AppColors.warning, _ => AppColors.info,
                      })),
                      DataCell(Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        if (t.status != 'done')
                          IconButton(icon: const Icon(Icons.check_rounded, size: 15, color: AppColors.success),
                              padding: EdgeInsets.zero, tooltip: 'Complete', onPressed: () => _complete(t)),
                        IconButton(icon: Icon(Icons.delete_rounded, size: 15, color: AppColors.error),
                            padding: EdgeInsets.zero, onPressed: () => _delete(t)),
                      ])),
                    ],
                  )).toList()),
          if (_showForm)
            Positioned.fill(child: Container(color: Colors.black26,
              alignment: Alignment.centerRight,
              child: SizedBox(width: 440,
                child: SidePanel(title: 'New Task', width: 440,
                  onClose: () => setState(() => _showForm = false),
                  child: _TaskForm(key: const ValueKey('new'),
                      onSaved: () { setState(() => _showForm = false); _load(); }))))),
        ]),
      ),
      if (_total > _pageSize)
        _Pager(page: _page, total: _total, pageSize: _pageSize,
            onPrev: () { setState(() => _page--); _load(); },
            onNext: () { setState(() => _page++); _load(); }),
    ]);
  }
}

class _TaskForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _TaskForm({super.key, required this.onSaved});
  @override State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  final _title = TextEditingController(), _desc = TextEditingController(), _due = TextEditingController();
  String _type = 'follow_up', _priority = 'medium'; bool _saving = false;

  @override
  void dispose() { _title.dispose(); _desc.dispose(); _due.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required'))); return; }
    setState(() => _saving = true);
    try {
      await TasksService.instance.createTask({
        'title': _title.text.trim(), 'description': _desc.text.trim(),
        'task_type': _type, 'priority': _priority,
        if (_due.text.trim().isNotEmpty) 'due_date': '${_due.text.trim()}T09:00:00Z',
      });
      widget.onSaved();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fld('Title *', _title, isDark), const SizedBox(height: 12),
      _fld('Description', _desc, isDark, maxLines: 3), const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: _type,
        decoration: InputDecoration(labelText: 'Type', isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
        items: const [
          DropdownMenuItem(value: 'follow_up', child: Text('Follow Up')),
          DropdownMenuItem(value: 'call',      child: Text('Call')),
          DropdownMenuItem(value: 'email',     child: Text('Email')),
          DropdownMenuItem(value: 'meeting',   child: Text('Meeting')),
          DropdownMenuItem(value: 'demo',      child: Text('Demo')),
          DropdownMenuItem(value: 'other',     child: Text('Other')),
        ],
        onChanged: (v) => setState(() => _type = v ?? 'follow_up'),
        style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText)),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: _priority,
        decoration: InputDecoration(labelText: 'Priority', isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
        items: const [
          DropdownMenuItem(value: 'low',    child: Text('Low')),
          DropdownMenuItem(value: 'medium', child: Text('Medium')),
          DropdownMenuItem(value: 'high',   child: Text('High')),
        ],
        onChanged: (v) => setState(() => _priority = v ?? 'medium'),
        style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText)),
      const SizedBox(height: 12),
      _fld('Due Date (YYYY-MM-DD)', _due, isDark),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity,
        child: CrmButton(label: 'Create Task', primary: true, loading: _saving, onPressed: _save)),
    ]));
  }

  Widget _fld(String label, TextEditingController ctrl, bool isDark, {int maxLines = 1}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        const SizedBox(height: 4),
        TextField(controller: ctrl, maxLines: maxLines, style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)))),
      ]);
}

class _Chip extends StatelessWidget {
  final String label; final bool active; final VoidCallback onTap;
  final Color? color;
  const _Chip({required this.label, required this.active, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? c : Colors.transparent,
        border: Border.all(color: active ? c : AppColors.lightBorder),
        borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
          color: active ? Colors.white : AppColors.lightTextSecondary))));
  }
}

class _Pager extends StatelessWidget {
  final int page, total, pageSize; final VoidCallback onPrev, onNext;
  const _Pager({required this.page, required this.total, required this.pageSize, required this.onPrev, required this.onNext});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = (total / pageSize).ceil();
    return Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(border: Border(top: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder))),
      child: Row(children: [
        Text('Page $page of $pages', style: GoogleFonts.inter(fontSize: 12,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
        const Spacer(),
        IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: page > 1 ? onPrev : null),
        IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: page < pages ? onNext : null),
      ]));
  }
}
