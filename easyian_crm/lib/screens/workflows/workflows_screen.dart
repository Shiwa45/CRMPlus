// lib/screens/workflows/workflows_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/desktop_widgets.dart';

class WorkflowsScreen extends StatefulWidget {
  const WorkflowsScreen({super.key});
  @override State<WorkflowsScreen> createState() => _WorkflowsScreenState();
}

class _WorkflowsScreenState extends State<WorkflowsScreen> {
  List<WorkflowModel> _workflows = [];
  bool _loading = true;
  bool _showForm = false;

  static const _triggerLabels = {
    'lead_created':         'Lead Created',
    'lead_updated':         'Lead Updated',
    'lead_status_changed':  'Lead Status Changed',
    'lead_assigned':        'Lead Assigned',
    'deal_created':         'Deal Created',
    'deal_stage_changed':   'Deal Stage Changed',
    'deal_won':             'Deal Won',
    'deal_lost':            'Deal Lost',
    'contact_created':      'Contact Created',
    'ticket_created':       'Ticket Created',
    'ticket_resolved':      'Ticket Resolved',
    'ticket_sla_breached':  'Ticket SLA Breached',
    'task_created':         'Task Created',
    'task_overdue':         'Task Overdue',
    'invoice_overdue':      'Invoice Overdue',
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final wfs = await WorkflowsService.instance.getWorkflows();
      setState(() => _workflows = wfs);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _toggle(WorkflowModel wf) async {
    // Optimistic UI
    setState(() {
      final i = _workflows.indexWhere((w) => w.id == wf.id);
      if (i >= 0) {
        _workflows[i] = WorkflowModel(
          id: wf.id, runCount: wf.runCount, name: wf.name, trigger: wf.trigger,
          createdAt: wf.createdAt, description: wf.description, lastRunAt: wf.lastRunAt,
          isActive: !wf.isActive);
      }
    });
    try { await WorkflowsService.instance.toggleActive(wf.id); }
    catch (_) { _load(); } // revert on error
  }

  Future<void> _delete(WorkflowModel wf) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text('Delete "${wf.name}"?', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      content: const Text('This workflow and all its executions will be removed.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    )) ?? false;
    if (!ok) return;
    try { await WorkflowsService.instance.deleteWorkflow(wf.id); } catch (_) {}
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      Expanded(child: Column(children: [
        PageHeader(
          title: 'Workflows',
          subtitle: '${_workflows.length} automations · ${_workflows.where((w) => w.isActive).length} active',
          actions: [
            CrmButton(label: 'Refresh', icon: Icons.refresh_rounded, onPressed: _load, loading: _loading),
            const SizedBox(width: 8),
            CrmButton(label: 'New Workflow', icon: Icons.add_rounded, primary: true,
                onPressed: () => setState(() => _showForm = true)),
          ],
        ),

        // Stats chips
        if (_workflows.isNotEmpty)
          _StatsBar(workflows: _workflows, isDark: isDark),

        Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),

        Expanded(
          child: _loading ? const TableShimmer(rows: 5)
              : _workflows.isEmpty
                  ? EmptyState(icon: Icons.account_tree_outlined,
                      title: 'No workflows yet',
                      subtitle: 'Automate repetitive tasks with if/then workflows',
                      actionLabel: 'New Workflow',
                      onAction: () => setState(() => _showForm = true))
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: _workflows.length,
                      itemBuilder: (_, i) => _WorkflowCard(
                        workflow: _workflows[i],
                        isDark: isDark,
                        triggerLabels: _triggerLabels,
                        onToggle: () => _toggle(_workflows[i]),
                        onDelete: () => _delete(_workflows[i]),
                      )),
        ),
      ])),

      if (_showForm)
        SidePanel(title: 'New Workflow', width: 460,
          onClose: () => setState(() => _showForm = false),
          child: _WorkflowForm(
            key: const ValueKey('new'),
            triggerLabels: _triggerLabels,
            onSaved: () { setState(() => _showForm = false); _load(); })),
    ]);
  }
}

class _StatsBar extends StatelessWidget {
  final List<WorkflowModel> workflows; final bool isDark;
  const _StatsBar({required this.workflows, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final active    = workflows.where((w) => w.isActive).length;
    final totalRuns = workflows.fold(0, (s, w) => s + w.runCount);
    return Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 20),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Row(children: [
        _chip('Active', '$active / ${workflows.length}', AppColors.success, isDark),
        const SizedBox(width: 24),
        _chip('Total Runs', '$totalRuns', AppColors.info, isDark),
      ]));
  }
  Widget _chip(String l, String v, Color c, bool isDark) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text('$l: ', style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
    Text(v, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
  ]);
}

class _WorkflowCard extends StatelessWidget {
  final WorkflowModel workflow;
  final bool isDark;
  final Map<String, String> triggerLabels;
  final VoidCallback onToggle, onDelete;
  const _WorkflowCard({required this.workflow, required this.isDark,
    required this.triggerLabels, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(color: workflow.isActive
            ? AppColors.success.withOpacity(0.35)
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        // Toggle
        Switch(
          value: workflow.isActive, onChanged: (_) => onToggle(),
          activeColor: AppColors.success,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        const SizedBox(width: 12),
        // Icon
        Container(width: 40, height: 40,
          decoration: BoxDecoration(
            color: (workflow.isActive ? AppColors.success : AppColors.lightTextMuted).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Icon(Icons.account_tree_rounded, size: 20,
              color: workflow.isActive ? AppColors.success : AppColors.lightTextMuted)),
        const SizedBox(width: 14),
        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(workflow.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText)),
          const SizedBox(height: 3),
          Row(children: [
            _triggerChip(triggerLabels[workflow.trigger] ?? workflow.trigger),
            const SizedBox(width: 8),
            Text('${workflow.runCount} runs', style: GoogleFonts.inter(fontSize: 11,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
            if (workflow.lastRunAt != null) ...[
              Text(' · Last: ${workflow.lastRunAt!.length > 10 ? workflow.lastRunAt!.substring(0,10) : workflow.lastRunAt}',
                  style: GoogleFonts.inter(fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
            ],
          ]),
          if (workflow.description != null && workflow.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(workflow.description!, style: GoogleFonts.inter(fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ])),
        // Actions
        IconButton(icon: Icon(Icons.delete_rounded, size: 18, color: AppColors.error),
            padding: EdgeInsets.zero, tooltip: 'Delete', onPressed: onDelete),
      ]),
    );
  }

  Widget _triggerChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4)),
    child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)));
}

class _WorkflowForm extends StatefulWidget {
  final Map<String, String> triggerLabels; final VoidCallback onSaved;
  const _WorkflowForm({super.key, required this.triggerLabels, required this.onSaved});
  @override State<_WorkflowForm> createState() => _WorkflowFormState();
}

class _WorkflowFormState extends State<_WorkflowForm> {
  final _name = TextEditingController(), _desc = TextEditingController();
  String? _trigger; bool _saving = false;

  @override
  void dispose() { _name.dispose(); _desc.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _trigger == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name and trigger are required'))); return;
    }
    setState(() => _saving = true);
    try {
      await WorkflowsService.instance.createWorkflow({
        'name': _name.text.trim(),
        'trigger': _trigger,
        'description': _desc.text.trim(),
        'is_active': false, // start inactive so user can configure first
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
      _fld('Workflow Name *', _name, isDark), const SizedBox(height: 12),
      _fld('Description', _desc, isDark, maxLines: 2), const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: _trigger,
        decoration: InputDecoration(labelText: 'Trigger *', isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
        items: [
          const DropdownMenuItem(value: null, child: Text('Select a trigger event')),
          ...widget.triggerLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
        ],
        onChanged: (v) => setState(() => _trigger = v),
        style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText)),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.info.withOpacity(0.07),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info.withOpacity(0.2))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(child: Text('The workflow will be created in inactive state. '
              'Add conditions and actions in the backend admin before activating.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.info))),
        ])),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity,
        child: CrmButton(label: 'Create Workflow', primary: true, loading: _saving, onPressed: _save)),
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
