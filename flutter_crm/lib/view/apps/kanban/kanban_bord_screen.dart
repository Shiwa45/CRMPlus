import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:henox/controller/apps/kanban/kanban_board_controller.dart';
import 'package:henox/helpers/theme/app_theme.dart';
import 'package:henox/helpers/utils/mixins/ui_mixin.dart';
import 'package:henox/helpers/utils/my_shadow.dart';
import 'package:henox/helpers/widgets/my_breadcrumb.dart';
import 'package:henox/helpers/widgets/my_breadcrumb_item.dart';
import 'package:henox/helpers/widgets/my_card.dart';
import 'package:henox/helpers/widgets/my_container.dart';
import 'package:henox/helpers/widgets/my_spacing.dart';
import 'package:henox/helpers/widgets/my_text.dart';
import 'package:henox/helpers/widgets/my_text_style.dart';
import 'package:henox/view/layouts/layout.dart';
import 'package:remixicon/remixicon.dart';

class KanbanBoardScreen extends StatefulWidget {
  const KanbanBoardScreen({super.key});
  @override
  State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends State<KanbanBoardScreen> with UIMixin {
  final LeadsController controller = Get.put(LeadsController());
  String _view = 'kanban';

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder<LeadsController>(
        builder: (controller) {
          return Padding(
            padding: MySpacing.x(flexSpacing / 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header ──────────────────────────────────────────
                Padding(
                  padding: MySpacing.x(flexSpacing / 2),
                  child: Row(
                    children: [
                      MyText.titleMedium('Leads Pipeline', fontWeight: 700, fontSize: 18),
                      MySpacing.width(12),
                      MyContainer(
                        onTap: () => _showAddLeadDialog(context),
                        color: contentTheme.primary,
                        paddingAll: 8,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(LucideIcons.plus, size: 16, color: contentTheme.onPrimary),
                          MySpacing.width(6),
                          MyText.bodyMedium('Add Lead', fontWeight: 600, color: contentTheme.onPrimary),
                        ]),
                      ),
                      MySpacing.width(8),
                      MyContainer(
                        onTap: () => controller.fetchLeads(),
                        color: contentTheme.secondary.withAlpha(40),
                        paddingAll: 8,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(LucideIcons.refresh_cw, size: 16, color: contentTheme.secondary),
                          MySpacing.width(6),
                          MyText.bodyMedium('Refresh', fontWeight: 600, color: contentTheme.secondary),
                        ]),
                      ),
                      const Spacer(),
                      _viewToggle(),
                      MySpacing.width(16),
                      MyBreadcrumb(children: [
                        MyBreadcrumbItem(name: 'CRM'),
                        MyBreadcrumbItem(name: 'Leads Pipeline', active: true),
                      ]),
                    ],
                  ),
                ),
                MySpacing.height(flexSpacing),

                // ─── Content ─────────────────────────────────────────
                if (controller.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(64),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_view == 'kanban')
                  _buildKanban()
                else
                  _buildTable(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── View Toggle ───────────────────────────────────────────────────────
  Widget _viewToggle() {
    return Row(children: [
      _toggleBtn(LucideIcons.layout_dashboard, 'kanban'),
      MySpacing.width(4),
      _toggleBtn(LucideIcons.table, 'table'),
    ]);
  }

  Widget _toggleBtn(IconData icon, String view) {
    final active = _view == view;
    return InkWell(
      onTap: () => setState(() => _view = view),
      child: MyContainer(
        paddingAll: 8,
        color: active ? contentTheme.primary : contentTheme.secondary.withAlpha(30),
        child: Icon(icon, size: 18, color: active ? contentTheme.onPrimary : contentTheme.secondary),
      ),
    );
  }

  // ─── Kanban View ───────────────────────────────────────────────────────
  // Layout is inside SingleChildScrollView (vertical), so we use horizontal scroll
  // with fixed-height columns. No Expanded used.
  Widget _buildKanban() {
    if (controller.leads.isEmpty) {
      return _emptyState();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: LeadsController.statusColumns.map((status) {
          final colLeads = controller.leadsForStatus(status);
          final label = LeadsController.statusLabels[status] ?? status;
          final color = LeadsController.statusColors[status] ?? Colors.grey;
          return _kanbanColumn(status, label, color, colLeads);
        }).toList(),
      ),
    );
  }

  Widget _kanbanColumn(String status, String label, Color color, List<Map<String, dynamic>> colLeads) {
    return Container(
      width: 270,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Column header
          Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            MySpacing.width(8),
            MyText.bodyMedium(label, fontWeight: 700, color: color),
            const Spacer(),
            MyContainer(
              paddingAll: 4,
              color: color.withAlpha(40),
              borderRadiusAll: 20,
              child: MyText.bodySmall('${colLeads.length}', fontWeight: 700, color: color),
            ),
          ]),
          MySpacing.height(10),
          // Cards — no Expanded, just list
          ...colLeads.map((lead) => _leadCard(lead, color)),
          MySpacing.height(6),
          // Add shortcut
          InkWell(
            onTap: () => _showAddLeadDialog(context, initialStatus: status),
            child: Container(
              width: double.infinity,
              padding: MySpacing.xy(12, 8),
              decoration: BoxDecoration(
                border: Border.all(color: color.withAlpha(80)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(LucideIcons.plus, size: 14, color: color),
                MySpacing.width(6),
                MyText.bodySmall('Add Lead', color: color),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leadCard(Map<String, dynamic> lead, Color colColor) {
    final name = '${lead['first_name'] ?? ''} ${lead['last_name'] ?? ''}'.trim();
    final company = lead['company'] ?? '';
    final email = lead['email'] ?? '';
    final priority = lead['priority'] ?? 'warm';
    final priColor = LeadsController.priorityColors[priority] ?? Colors.grey;
    final id = lead['id'] as int?;

    return GestureDetector(
      onTap: () => _showDetailDialog(context, lead),
      child: Container(
        margin: MySpacing.bottom(8),
        padding: MySpacing.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: MyText.bodyMedium(name.isNotEmpty ? name : 'Unnamed', fontWeight: 700, maxLines: 1, overflow: TextOverflow.ellipsis)),
              MySpacing.width(4),
              MyContainer(
                paddingAll: 3,
                color: priColor.withAlpha(30),
                borderRadiusAll: 4,
                child: MyText.bodySmall(priority.toUpperCase(), color: priColor, fontSize: 10, fontWeight: 700),
              ),
            ]),
            if (company.isNotEmpty) ...[
              MySpacing.height(4),
              Row(children: [
                Icon(Remix.building_line, size: 12, color: Colors.grey),
                MySpacing.width(4),
                Expanded(child: MyText.bodySmall(company, muted: true, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ],
            if (email.isNotEmpty) ...[
              MySpacing.height(2),
              Row(children: [
                Icon(Remix.mail_line, size: 12, color: Colors.grey),
                MySpacing.width(4),
                Expanded(child: MyText.bodySmall(email, muted: true, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ],
            MySpacing.height(8),
            Row(children: [
              InkWell(
                onTap: () => _showEditDialog(context, lead),
                child: Icon(LucideIcons.pencil, size: 14, color: contentTheme.primary),
              ),
              MySpacing.width(10),
              InkWell(
                onTap: () async {
                  if (id != null) {
                    final ok = await _confirmDelete(context);
                    if (ok == true) controller.deleteLead(id);
                  }
                },
                child: Icon(LucideIcons.trash_2, size: 14, color: contentTheme.danger),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                tooltip: 'Move to',
                itemBuilder: (_) => LeadsController.statusColumns
                    .where((s) => s != (lead['status'] ?? 'new'))
                    .map((s) => PopupMenuItem(value: s, child: MyText.bodySmall(LeadsController.statusLabels[s] ?? s)))
                    .toList(),
                onSelected: (newStatus) {
                  if (id != null) controller.updateStatus(id, newStatus);
                },
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(LucideIcons.arrow_right_left, size: 12, color: contentTheme.secondary),
                  MySpacing.width(4),
                  MyText.bodySmall('Move', color: contentTheme.secondary),
                ]),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ─── Table View ────────────────────────────────────────────────────────
  Widget _buildTable() {
    if (controller.leads.isEmpty) return _emptyState();

    return MyCard(
      paddingAll: 0,
      shadow: MyShadow(elevation: 0.5, position: MyShadowPosition.bottom),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(contentTheme.secondary.withAlpha(30)),
          dataRowMaxHeight: 60,
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Company', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Priority', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w700))),
          ],
          rows: controller.leads.map((lead) {
            final id = lead['id'] as int?;
            final name = '${lead['first_name'] ?? ''} ${lead['last_name'] ?? ''}'.trim();
            final status = lead['status'] ?? 'new';
            final priority = lead['priority'] ?? 'warm';
            final statusColor = LeadsController.statusColors[status] ?? Colors.grey;
            final priColor = LeadsController.priorityColors[priority] ?? Colors.grey;

            return DataRow(cells: [
              DataCell(InkWell(
                onTap: () => _showDetailDialog(context, lead),
                child: MyText.bodyMedium(name.isNotEmpty ? name : 'Unnamed', fontWeight: 600, color: contentTheme.primary),
              )),
              DataCell(MyText.bodyMedium(lead['company'] ?? '-')),
              DataCell(SizedBox(width: 180, child: MyText.bodyMedium(lead['email'] ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis))),
              DataCell(MyText.bodyMedium(lead['phone'] ?? '-')),
              DataCell(MyContainer(
                padding: MySpacing.xy(8, 4),
                color: statusColor.withAlpha(30),
                borderRadiusAll: 4,
                child: MyText.bodySmall(LeadsController.statusLabels[status] ?? status, color: statusColor, fontWeight: 600),
              )),
              DataCell(MyContainer(
                padding: MySpacing.xy(8, 4),
                color: priColor.withAlpha(30),
                borderRadiusAll: 4,
                child: MyText.bodySmall(priority.toUpperCase(), color: priColor, fontWeight: 600),
              )),
              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: Icon(LucideIcons.eye, size: 16, color: contentTheme.info), tooltip: 'View', onPressed: () => _showDetailDialog(context, lead), visualDensity: VisualDensity.compact),
                IconButton(icon: Icon(LucideIcons.pencil, size: 16, color: contentTheme.primary), tooltip: 'Edit', onPressed: () => _showEditDialog(context, lead), visualDensity: VisualDensity.compact),
                IconButton(
                  icon: Icon(LucideIcons.trash_2, size: 16, color: contentTheme.danger),
                  tooltip: 'Delete',
                  onPressed: () async {
                    if (id != null) {
                      final ok = await _confirmDelete(context);
                      if (ok == true) controller.deleteLead(id);
                    }
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ])),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────
  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(LucideIcons.users, size: 64, color: Colors.grey.shade300),
          MySpacing.height(16),
          MyText.bodyLarge('No leads yet', muted: true),
          MySpacing.height(12),
          MyContainer(
            onTap: () => _showAddLeadDialog(context),
            color: contentTheme.primary,
            padding: MySpacing.xy(16, 10),
            child: MyText.bodyMedium('Add Your First Lead', color: contentTheme.onPrimary, fontWeight: 600),
          ),
        ]),
      ),
    );
  }

  // ─── Add Lead Dialog ──────────────────────────────────────────────────
  void _showAddLeadDialog(BuildContext context, {String initialStatus = 'new'}) {
    final formKey = GlobalKey<FormState>();
    final firstName = TextEditingController();
    final lastName = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final company = TextEditingController();
    final jobTitle = TextEditingController();
    final budget = TextEditingController();
    final notes = TextEditingController();
    String status = initialStatus;
    String priority = 'warm';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, ss) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Add New Lead', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 540,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Expanded(child: _field('First Name *', firstName, required: true)),
                    MySpacing.width(12),
                    Expanded(child: _field('Last Name', lastName)),
                  ]),
                  MySpacing.height(12),
                  Row(children: [
                    Expanded(child: _field('Email *', email, required: true, keyboardType: TextInputType.emailAddress)),
                    MySpacing.width(12),
                    Expanded(child: _field('Phone', phone, keyboardType: TextInputType.phone)),
                  ]),
                  MySpacing.height(12),
                  Row(children: [
                    Expanded(child: _field('Company', company)),
                    MySpacing.width(12),
                    Expanded(child: _field('Job Title', jobTitle)),
                  ]),
                  MySpacing.height(12),
                  Row(children: [
                    Expanded(child: _dropdown('Status', status, LeadsController.statusLabels, (v) => ss(() => status = v!))),
                    MySpacing.width(12),
                    Expanded(child: _dropdown('Priority', priority, {'hot': 'Hot', 'warm': 'Warm', 'cold': 'Cold'}, (v) => ss(() => priority = v!))),
                  ]),
                  MySpacing.height(12),
                  _field('Budget', budget, keyboardType: TextInputType.number),
                  MySpacing.height(12),
                  _field('Notes', notes, maxLines: 3),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                ss(() => isSaving = true);
                await controller.createLead({
                  'first_name': firstName.text.trim(),
                  'last_name': lastName.text.trim(),
                  'email': email.text.trim(),
                  'phone': phone.text.trim(),
                  'company': company.text.trim(),
                  'job_title': jobTitle.text.trim(),
                  'status': status,
                  'priority': priority,
                  if (budget.text.isNotEmpty) 'budget': budget.text.trim(),
                  if (notes.text.isNotEmpty) 'notes': notes.text.trim(),
                });
                ss(() => isSaving = false);
              },
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Lead'),
            ),
          ],
        );
      }),
    );
  }

  // ─── Edit Lead Dialog ─────────────────────────────────────────────────
  void _showEditDialog(BuildContext context, Map<String, dynamic> lead) {
    final formKey = GlobalKey<FormState>();
    final id = lead['id'] as int?;
    final firstName = TextEditingController(text: lead['first_name'] ?? '');
    final lastName = TextEditingController(text: lead['last_name'] ?? '');
    final email = TextEditingController(text: lead['email'] ?? '');
    final phone = TextEditingController(text: lead['phone'] ?? '');
    final company = TextEditingController(text: lead['company'] ?? '');
    final jobTitle = TextEditingController(text: lead['job_title'] ?? '');
    final budget = TextEditingController(text: lead['budget']?.toString() ?? '');
    final notes = TextEditingController(text: lead['notes'] ?? '');
    String status = lead['status'] ?? 'new';
    String priority = lead['priority'] ?? 'warm';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, ss) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Edit Lead', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 540,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Expanded(child: _field('First Name *', firstName, required: true)),
                    MySpacing.width(12),
                    Expanded(child: _field('Last Name', lastName)),
                  ]),
                  MySpacing.height(12),
                  Row(children: [
                    Expanded(child: _field('Email *', email, required: true, keyboardType: TextInputType.emailAddress)),
                    MySpacing.width(12),
                    Expanded(child: _field('Phone', phone, keyboardType: TextInputType.phone)),
                  ]),
                  MySpacing.height(12),
                  Row(children: [
                    Expanded(child: _field('Company', company)),
                    MySpacing.width(12),
                    Expanded(child: _field('Job Title', jobTitle)),
                  ]),
                  MySpacing.height(12),
                  Row(children: [
                    Expanded(child: _dropdown('Status', status, LeadsController.statusLabels, (v) => ss(() => status = v!))),
                    MySpacing.width(12),
                    Expanded(child: _dropdown('Priority', priority, {'hot': 'Hot', 'warm': 'Warm', 'cold': 'Cold'}, (v) => ss(() => priority = v!))),
                  ]),
                  MySpacing.height(12),
                  _field('Budget', budget, keyboardType: TextInputType.number),
                  MySpacing.height(12),
                  _field('Notes', notes, maxLines: 3),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving || id == null ? null : () async {
                if (!formKey.currentState!.validate()) return;
                ss(() => isSaving = true);
                await controller.updateLead(id, {
                  'first_name': firstName.text.trim(),
                  'last_name': lastName.text.trim(),
                  'email': email.text.trim(),
                  'phone': phone.text.trim(),
                  'company': company.text.trim(),
                  'job_title': jobTitle.text.trim(),
                  'status': status,
                  'priority': priority,
                  if (budget.text.isNotEmpty) 'budget': budget.text.trim(),
                  if (notes.text.isNotEmpty) 'notes': notes.text.trim(),
                });
                ss(() => isSaving = false);
              },
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Update Lead'),
            ),
          ],
        );
      }),
    );
  }

  // ─── Detail Dialog ────────────────────────────────────────────────────
  void _showDetailDialog(BuildContext context, Map<String, dynamic> lead) {
    final name = '${lead['first_name'] ?? ''} ${lead['last_name'] ?? ''}'.trim();
    final status = lead['status'] ?? 'new';
    final priority = lead['priority'] ?? 'warm';
    final statusColor = LeadsController.statusColors[status] ?? Colors.grey;
    final priColor = LeadsController.priorityColors[priority] ?? Colors.grey;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(children: [
          Expanded(child: Text(name.isNotEmpty ? name : 'Lead Detail', style: const TextStyle(fontWeight: FontWeight.w700))),
          MyContainer(padding: MySpacing.xy(8, 4), color: statusColor.withAlpha(30), borderRadiusAll: 4,
            child: MyText.bodySmall(LeadsController.statusLabels[status] ?? status, color: statusColor, fontWeight: 600)),
        ]),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              MyContainer(padding: MySpacing.xy(12, 8), color: priColor.withAlpha(20), borderRadiusAll: 6,
                child: Row(children: [
                  Icon(LucideIcons.star, size: 14, color: priColor),
                  MySpacing.width(6),
                  MyText.bodySmall('Priority: ${priority.toUpperCase()}', color: priColor, fontWeight: 700),
                ])),
              MySpacing.height(16),
              _detailSection('Contact', [
                _detailRow(LucideIcons.mail, 'Email', lead['email']),
                _detailRow(LucideIcons.phone, 'Phone', lead['phone']),
              ]),
              _detailSection('Company', [
                _detailRow(LucideIcons.building_2, 'Company', lead['company']),
                _detailRow(LucideIcons.briefcase, 'Job Title', lead['job_title']),
              ]),
              _detailSection('Details', [
                _detailRow(LucideIcons.indian_rupee, 'Budget', lead['budget']?.toString()),
                _detailRow(LucideIcons.map_pin, 'Country', lead['country']),
              ]),
              if ((lead['notes'] ?? '').toString().isNotEmpty)
                _detailSection('Notes', [
                  Padding(padding: MySpacing.top(4), child: MyText.bodyMedium(lead['notes'], muted: true)),
                ]),
              _detailSection('Timestamps', [
                _detailRow(LucideIcons.calendar, 'Created', _formatDate(lead['created_at'])),
                _detailRow(LucideIcons.clock, 'Updated', _formatDate(lead['updated_at'])),
              ]),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () { Navigator.pop(context); _showEditDialog(context, lead); },
            icon: Icon(LucideIcons.pencil, size: 14),
            label: const Text('Edit Lead'),
          ),
        ],
      ),
    );
  }

  Widget _detailSection(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      MySpacing.height(8),
      MyText.labelMedium(title.toUpperCase(), muted: true, fontWeight: 700, letterSpacing: 0.6),
      const Divider(height: 12),
      ...children,
      MySpacing.height(4),
    ]);
  }

  Widget _detailRow(IconData icon, String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: MySpacing.bottom(6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 14, color: Colors.grey),
        MySpacing.width(8),
        SizedBox(width: 72, child: MyText.bodySmall('$label:', muted: true)),
        Expanded(child: MyText.bodySmall(value.toString(), fontWeight: 600)),
      ]),
    );
  }

  // ─── Form Helpers ─────────────────────────────────────────────────────
  Widget _field(String label, TextEditingController ctrl, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: MyTextStyle.bodySmall(muted: true),
        border: const OutlineInputBorder(),
        contentPadding: MySpacing.all(10),
        isDense: true,
      ),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null : null,
    );
  }

  Widget _dropdown(String label, String value, Map<String, String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: items.containsKey(value) ? value : items.keys.first,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: MyTextStyle.bodySmall(muted: true),
        border: const OutlineInputBorder(),
        contentPadding: MySpacing.all(10),
        isDense: true,
      ),
      items: items.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: MyTextStyle.bodyMedium())))
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Lead?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic val) {
    if (val == null) return '';
    try { return val.toString().substring(0, 10); } catch (_) { return val.toString(); }
  }
}
