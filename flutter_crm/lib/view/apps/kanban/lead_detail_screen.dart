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
import 'package:henox/helpers/widgets/my_flex.dart';
import 'package:henox/helpers/widgets/my_flex_item.dart';
import 'package:henox/helpers/widgets/my_spacing.dart';
import 'package:henox/helpers/widgets/my_text.dart';
import 'package:henox/helpers/widgets/my_text_style.dart';
import 'package:henox/view/layouts/layout.dart';
import 'package:remixicon/remixicon.dart';

class LeadDetailScreen extends StatefulWidget {
  const LeadDetailScreen({super.key});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> with UIMixin {
  final LeadsController controller = Get.find<LeadsController>();
  late Map<String, dynamic> lead;

  // Edit form controllers
  late TextEditingController _firstName, _lastName, _email, _phone;
  late TextEditingController _company, _jobTitle, _budget;
  late TextEditingController _address, _city, _state, _country, _postalCode;
  late TextEditingController _requirements, _notes;
  late String _editStatus, _editPriority;

  int _selectedTab = 0;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Lead is passed as argument via Get.toNamed arguments
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      lead = args;
    } else {
      lead = {};
    }
    _initControllers();
  }

  void _initControllers() {
    _firstName = TextEditingController(text: lead['first_name'] ?? '');
    _lastName = TextEditingController(text: lead['last_name'] ?? '');
    _email = TextEditingController(text: lead['email'] ?? '');
    _phone = TextEditingController(text: lead['phone'] ?? '');
    _company = TextEditingController(text: lead['company'] ?? '');
    _jobTitle = TextEditingController(text: lead['job_title'] ?? '');
    _budget = TextEditingController(text: lead['budget']?.toString() ?? '');
    _address = TextEditingController(text: lead['address'] ?? '');
    _city = TextEditingController(text: lead['city'] ?? '');
    _state = TextEditingController(text: lead['state'] ?? '');
    _country = TextEditingController(text: lead['country'] ?? 'India');
    _postalCode = TextEditingController(text: lead['postal_code'] ?? '');
    _requirements = TextEditingController(text: lead['requirements'] ?? '');
    _notes = TextEditingController(text: lead['notes'] ?? '');
    _editStatus = lead['status'] ?? 'new';
    _editPriority = lead['priority'] ?? 'warm';
  }

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _phone, _company, _jobTitle, _budget, _address, _city, _state, _country, _postalCode, _requirements, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _fullName => '${lead['first_name'] ?? ''} ${lead['last_name'] ?? ''}'.trim();
  String get _status => lead['status'] ?? 'new';
  String get _priority => lead['priority'] ?? 'warm';

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───────────────────────────────────────────────
          Padding(
            padding: MySpacing.x(flexSpacing),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Get.back(),
                  child: Row(children: [
                    Icon(LucideIcons.arrow_left, size: 18, color: contentTheme.secondary),
                    MySpacing.width(6),
                    MyText.bodyMedium('Back', color: contentTheme.secondary),
                  ]),
                ),
                MySpacing.width(16),
                MyText.titleMedium('Lead Detail', fontSize: 18, fontWeight: 700),
                const Spacer(),
                MyBreadcrumb(children: [
                  MyBreadcrumbItem(name: 'Leads Pipeline'),
                  MyBreadcrumbItem(name: _fullName.isNotEmpty ? _fullName : 'Detail', active: true),
                ]),
              ],
            ),
          ),
          MySpacing.height(flexSpacing),

          // ─── Two-column layout ────────────────────────────────────
          Padding(
            padding: MySpacing.x(flexSpacing / 2),
            child: MyFlex(
              children: [
                // LEFT: Lead info card
                MyFlexItem(
                  sizes: 'lg-3 md-12',
                  child: MyFlex(contentPadding: false, children: [
                    MyFlexItem(child: _leftPanel()),
                  ]),
                ),
                // RIGHT: Tabbed detail pane
                MyFlexItem(
                  sizes: 'lg-9 md-12',
                  child: MyCard(
                    shadow: MyShadow(elevation: 0.7, position: MyShadowPosition.bottom),
                    paddingAll: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _tabBar(),
                        MySpacing.height(24),
                        if (_selectedTab == 0) _overviewTab(),
                        if (_selectedTab == 1) _editTab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Left Panel ────────────────────────────────────────────────────────
  Widget _leftPanel() {
    final statusColor = LeadsController.statusColors[_status] ?? Colors.grey;
    final priColor = LeadsController.priorityColors[_priority] ?? Colors.grey;

    return MyCard(
      shadow: MyShadow(elevation: 0.7, position: MyShadowPosition.bottom),
      paddingAll: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top color banner
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor, statusColor.withAlpha(180)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ),
          Padding(
            padding: MySpacing.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MyContainer.rounded(
                      paddingAll: 0,
                      height: 64,
                      width: 64,
                      color: statusColor.withAlpha(30),
                      child: Center(
                        child: MyText.titleLarge(
                          _fullName.isNotEmpty ? _fullName[0].toUpperCase() : '?',
                          fontWeight: 700,
                          color: statusColor,
                          fontSize: 26,
                        ),
                      ),
                    ),
                    MySpacing.width(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText.bodyLarge(_fullName.isNotEmpty ? _fullName : 'Unknown', fontWeight: 700),
                          if ((lead['job_title'] ?? '').toString().isNotEmpty)
                            MyText.bodySmall(lead['job_title'], muted: true),
                        ],
                      ),
                    ),
                  ],
                ),
                MySpacing.height(16),
                const Divider(),
                MySpacing.height(12),

                // Status badge
                Row(children: [
                  MyContainer(
                    padding: MySpacing.xy(10, 5),
                    color: statusColor.withAlpha(25),
                    borderRadiusAll: 6,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                      MySpacing.width(6),
                      MyText.bodySmall(LeadsController.statusLabels[_status] ?? _status, color: statusColor, fontWeight: 700),
                    ]),
                  ),
                  MySpacing.width(8),
                  MyContainer(
                    padding: MySpacing.xy(10, 5),
                    color: priColor.withAlpha(25),
                    borderRadiusAll: 6,
                    child: MyText.bodySmall(_priority.toUpperCase(), color: priColor, fontWeight: 700),
                  ),
                ]),
                MySpacing.height(16),

                // Quick info rows
                _infoRow(LucideIcons.mail, lead['email']),
                _infoRow(LucideIcons.phone, lead['phone']),
                _infoRow(LucideIcons.building_2, lead['company']),
                _infoRow(LucideIcons.map_pin, _buildLocation()),
                _infoRow(LucideIcons.indian_rupee, lead['budget'] != null ? '${lead['budget']}' : null),
                MySpacing.height(16),

                // Action buttons
                Row(children: [
                  Expanded(
                    child: MyContainer(
                      onTap: () => setState(() => _selectedTab = 1),
                      color: contentTheme.primary,
                      padding: MySpacing.xy(12, 10),
                      child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(LucideIcons.pencil, size: 14, color: contentTheme.onPrimary),
                        MySpacing.width(6),
                        MyText.bodySmall('Edit', color: contentTheme.onPrimary, fontWeight: 600),
                      ])),
                    ),
                  ),
                  MySpacing.width(8),
                  Expanded(
                    child: MyContainer(
                      onTap: () async {
                        final id = lead['id'] as int?;
                        if (id == null) return;
                        final ok = await _confirmDelete(context);
                        if (ok == true) {
                          await controller.deleteLead(id);
                          Get.back();
                        }
                      },
                      color: contentTheme.danger.withAlpha(20),
                      padding: MySpacing.xy(12, 10),
                      child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(LucideIcons.trash_2, size: 14, color: contentTheme.danger),
                        MySpacing.width(6),
                        MyText.bodySmall('Delete', color: contentTheme.danger, fontWeight: 600),
                      ])),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildLocation() {
    final parts = [lead['city'], lead['state'], lead['country']].where((s) => s != null && s.toString().isNotEmpty).toList();
    return parts.join(', ');
  }

  Widget _infoRow(IconData icon, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: MySpacing.bottom(8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 14, color: Colors.grey),
        MySpacing.width(8),
        Expanded(child: MyText.bodySmall(value.toString(), muted: true)),
      ]),
    );
  }

  // ─── Tab Bar ───────────────────────────────────────────────────────────
  Widget _tabBar() {
    Widget tabBtn(int idx, String label, IconData icon) {
      final active = _selectedTab == idx;
      return InkWell(
        onTap: () => setState(() => _selectedTab = idx),
        child: Container(
          padding: MySpacing.xy(16, 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 2.5,
                color: active ? contentTheme.primary : Colors.transparent,
              ),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: active ? contentTheme.primary : contentTheme.secondary),
            MySpacing.width(8),
            MyText.bodyMedium(label, fontWeight: active ? 700 : 500, color: active ? contentTheme.primary : contentTheme.secondary),
          ]),
        ),
      );
    }

    return Row(children: [
      tabBtn(0, 'Overview', LucideIcons.user),
      tabBtn(1, 'Edit Lead', LucideIcons.pencil),
    ]);
  }

  // ─── Overview Tab ──────────────────────────────────────────────────────
  Widget _overviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Contact Information', [
          _detailRow(LucideIcons.user, 'Full Name', _fullName),
          _detailRow(LucideIcons.mail, 'Email', lead['email']),
          _detailRow(LucideIcons.phone, 'Phone', lead['phone']),
        ]),
        _section('Company Details', [
          _detailRow(LucideIcons.building_2, 'Company', lead['company']),
          _detailRow(LucideIcons.briefcase, 'Job Title', lead['job_title']),
        ]),
        _section('Lead Status', [
          _detailRow(LucideIcons.activity, 'Status', LeadsController.statusLabels[_status] ?? _status),
          _detailRow(LucideIcons.star, 'Priority', _priority.toUpperCase()),
          _detailRow(LucideIcons.indian_rupee, 'Budget', lead['budget']?.toString()),
        ]),
        _section('Location', [
          _detailRow(LucideIcons.map_pin, 'Address', lead['address']),
          _detailRow(LucideIcons.map, 'City', lead['city']),
          _detailRow(LucideIcons.map, 'State', lead['state']),
          _detailRow(LucideIcons.globe, 'Country', lead['country']),
          _detailRow(LucideIcons.hash, 'Postal Code', lead['postal_code']),
        ]),
        if ((lead['requirements'] ?? '').toString().isNotEmpty)
          _section('Requirements', [
            Container(
              width: double.infinity,
              padding: MySpacing.all(12),
              decoration: BoxDecoration(color: contentTheme.primary.withAlpha(10), borderRadius: BorderRadius.circular(8)),
              child: MyText.bodyMedium(lead['requirements'], muted: true),
            ),
          ]),
        if ((lead['notes'] ?? '').toString().isNotEmpty)
          _section('Notes', [
            Container(
              width: double.infinity,
              padding: MySpacing.all(12),
              decoration: BoxDecoration(color: contentTheme.warning.withAlpha(15), borderRadius: BorderRadius.circular(8)),
              child: MyText.bodyMedium(lead['notes'], muted: true),
            ),
          ]),
        _section('Timestamps', [
          _detailRow(LucideIcons.calendar_plus, 'Created', _formatDate(lead['created_at'])),
          _detailRow(LucideIcons.calendar_check, 'Updated', _formatDate(lead['updated_at'])),
          _detailRow(LucideIcons.calendar_clock, 'Last Contacted', _formatDate(lead['last_contacted'])),
        ]),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    final hasContent = children.any((w) => w is! SizedBox);
    if (!hasContent) return const SizedBox.shrink();
    return Padding(
      padding: MySpacing.bottom(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.circle_dot, size: 12, color: contentTheme.primary),
          MySpacing.width(8),
          MyText.labelMedium(title.toUpperCase(), muted: true, fontWeight: 700, letterSpacing: 0.6),
        ]),
        const Divider(height: 16),
        ...children,
      ]),
    );
  }

  Widget _detailRow(IconData icon, String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: MySpacing.bottom(10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 14, color: Colors.grey),
        MySpacing.width(10),
        SizedBox(width: 110, child: MyText.bodySmall('$label:', muted: true)),
        Expanded(child: MyText.bodySmall(value.toString(), fontWeight: 600)),
      ]),
    );
  }

  // ─── Edit Tab ──────────────────────────────────────────────────────────
  Widget _editTab() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Info section
          _editSectionHeader(Remix.contacts_book_2_line, 'PERSONAL INFO'),
          MySpacing.height(16),
          MyFlex(children: [
            MyFlexItem(sizes: 'md-6 sm-12', child: _field('First Name *', _firstName, required: true)),
            MyFlexItem(sizes: 'md-6 sm-12', child: _field('Last Name', _lastName)),
          ]),
          MySpacing.height(16),
          MyFlex(children: [
            MyFlexItem(sizes: 'md-6 sm-12', child: _field('Email *', _email, required: true, keyboard: TextInputType.emailAddress)),
            MyFlexItem(sizes: 'md-6 sm-12', child: _field('Phone', _phone, keyboard: TextInputType.phone)),
          ]),
          MySpacing.height(24),

          // Company section
          _editSectionHeader(Remix.building_line, 'COMPANY'),
          MySpacing.height(16),
          MyFlex(children: [
            MyFlexItem(sizes: 'md-6 sm-12', child: _field('Company', _company)),
            MyFlexItem(sizes: 'md-6 sm-12', child: _field('Job Title', _jobTitle)),
          ]),
          MySpacing.height(24),

          // Lead Details section
          _editSectionHeader(LucideIcons.activity, 'LEAD DETAILS'),
          MySpacing.height(16),
          MyFlex(children: [
            MyFlexItem(sizes: 'md-4 sm-12', child: _dropdown('Status', _editStatus, LeadsController.statusLabels, (v) => setState(() => _editStatus = v!))),
            MyFlexItem(sizes: 'md-4 sm-12', child: _dropdown('Priority', _editPriority, {'hot': 'Hot 🔥', 'warm': 'Warm ☀️', 'cold': 'Cold ❄️'}, (v) => setState(() => _editPriority = v!))),
            MyFlexItem(sizes: 'md-4 sm-12', child: _field('Budget (₹)', _budget, keyboard: TextInputType.number)),
          ]),
          MySpacing.height(16),
          _field('Requirements', _requirements, maxLines: 3),
          MySpacing.height(12),
          _field('Notes', _notes, maxLines: 3),
          MySpacing.height(24),

          // Location section
          _editSectionHeader(LucideIcons.map_pin, 'LOCATION'),
          MySpacing.height(16),
          _field('Address', _address, maxLines: 2),
          MySpacing.height(12),
          MyFlex(children: [
            MyFlexItem(sizes: 'md-4 sm-12', child: _field('City', _city)),
            MyFlexItem(sizes: 'md-4 sm-12', child: _field('State', _state)),
            MyFlexItem(sizes: 'md-4 sm-12', child: _field('Postal Code', _postalCode, keyboard: TextInputType.number)),
          ]),
          MySpacing.height(12),
          _field('Country', _country),
          MySpacing.height(24),

          // Save button
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            MyContainer(
              onTap: () => setState(() => _selectedTab = 0),
              color: contentTheme.secondary.withAlpha(30),
              padding: MySpacing.xy(20, 12),
              child: MyText.bodyMedium('Cancel', color: contentTheme.secondary, fontWeight: 600),
            ),
            MySpacing.width(12),
            MyContainer(
              onTap: _isSaving ? null : _saveChanges,
              color: contentTheme.primary,
              padding: MySpacing.xy(20, 12),
              child: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(LucideIcons.save, size: 16, color: contentTheme.onPrimary),
                      MySpacing.width(8),
                      MyText.bodyMedium('Save Changes', color: contentTheme.onPrimary, fontWeight: 600),
                    ]),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _editSectionHeader(IconData icon, String label) {
    return Row(children: [
      Icon(icon, size: 16),
      MySpacing.width(8),
      MyText.bodyMedium(label, fontWeight: 700, muted: true),
    ]);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    final id = lead['id'] as int?;
    if (id == null) return;
    setState(() => _isSaving = true);

    final body = {
      'first_name': _firstName.text.trim(),
      'last_name': _lastName.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'company': _company.text.trim(),
      'job_title': _jobTitle.text.trim(),
      'status': _editStatus,
      'priority': _editPriority,
      'address': _address.text.trim(),
      'city': _city.text.trim(),
      'state': _state.text.trim(),
      'country': _country.text.trim(),
      'postal_code': _postalCode.text.trim(),
      'requirements': _requirements.text.trim(),
      'notes': _notes.text.trim(),
      if (_budget.text.isNotEmpty) 'budget': _budget.text.trim(),
    };

    await controller.updateLead(id, body);

    // Also update local lead map so the screen refreshes
    body.forEach((k, v) => lead[k] = v);
    setState(() {
      _isSaving = false;
      _selectedTab = 0; // go back to overview after save
    });
  }

  // ─── Helpers ───────────────────────────────────────────────────────────
  Widget _field(String label, TextEditingController ctrl, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(width: 1.5, color: Colors.grey.withAlpha(50)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText.labelMedium(label, muted: true),
        MySpacing.height(6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: MyTextStyle.bodySmall(xMuted: true),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(borderSide: BorderSide(width: 1.5, color: contentTheme.primary)),
            errorBorder: border.copyWith(borderSide: BorderSide(width: 1.5, color: contentTheme.danger)),
            focusedErrorBorder: border.copyWith(borderSide: BorderSide(width: 1.5, color: contentTheme.danger)),
            contentPadding: MySpacing.all(12),
            isCollapsed: true,
            floatingLabelBehavior: FloatingLabelBehavior.never,
            filled: false,
          ),
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null : null,
        ),
      ],
    );
  }

  Widget _dropdown(String label, String value, Map<String, String> items, ValueChanged<String?> onChanged) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(width: 1.5, color: Colors.grey.withAlpha(50)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText.labelMedium(label, muted: true),
        MySpacing.height(6),
        DropdownButtonFormField<String>(
          value: items.containsKey(value) ? value : items.keys.first,
          decoration: InputDecoration(
            border: border, enabledBorder: border, focusedBorder: border,
            contentPadding: MySpacing.all(12),
            isCollapsed: true,
            floatingLabelBehavior: FloatingLabelBehavior.never,
          ),
          items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: MyTextStyle.bodyMedium()))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Lead?'),
        content: const Text('This cannot be undone.'),
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
    if (val == null || val.toString().isEmpty) return '';
    try { return val.toString().substring(0, 10); } catch (_) { return val.toString(); }
  }
}
