import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/num_utils.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/desktop_widgets.dart';

// ─── Emails Screen ────────────────────────────────────────────────────────────
class EmailsScreen extends StatefulWidget {
  const EmailsScreen({super.key});
  @override
  State<EmailsScreen> createState() => _EmailsScreenState();
}

class _EmailsScreenState extends State<EmailsScreen> {
  List<EmailModel> _emails = [];
  bool _loading = true;
  int _total = 0;
  int _page = 1;
  String? _filterStatus;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load({bool reset = false}) async {
    if (reset) setState(() => _page = 1);
    setState(() => _loading = true);
    final r = await CommsService.instance.getEmails(page: _page, status: _filterStatus);
    setState(() {
      _emails = r['results'] as List<EmailModel>;
      _total = toInt(r['count']);
      _loading = false;
    });
  }

  Color _statusColor(String s) => switch(s) {
    'sent'    => AppColors.success,
    'pending' => AppColors.warning,
    'failed'  => AppColors.error,
    'opened'  => AppColors.info,
    _         => AppColors.lightTextMuted,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(children: [
      PageHeader(
        title: 'Emails',
        subtitle: '$_total emails sent',
        actions: [
          CrmButton(label: 'Refresh', icon: Icons.refresh_rounded, onPressed: () => _load(reset: true)),
        ],
      ),
      TableToolbar(
        searchCtrl: _searchCtrl,
        searchHint: 'Search by subject or recipient...',
        filters: [
          const SizedBox(width: 8),
          FilterDropdown<String?>(
            value: _filterStatus,
            hint: 'All Status',
            items: const [
              DropdownMenuItem(value: null,      child: Text('All')),
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'sent',    child: Text('Sent')),
              DropdownMenuItem(value: 'opened',  child: Text('Opened')),
              DropdownMenuItem(value: 'failed',  child: Text('Failed')),
            ],
            onChanged: (v) { setState(() => _filterStatus = v); _load(reset: true); },
          ),
        ],
        actions: [
          Text('$_total emails', style: GoogleFonts.inter(fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
        ],
      ),
      Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      Expanded(
        child: _loading && _emails.isEmpty
            ? const TableShimmer()
            : _emails.isEmpty
                ? const EmptyState(icon: Icons.email_outlined,
                    title: 'No emails yet', subtitle: 'Emails will appear here once sent.')
                : DataTable2(
                    columnSpacing: 12, horizontalMargin: 16, minWidth: 800,
                    headingRowHeight: 40, dataRowHeight: 48,
                    headingRowColor: MaterialStateProperty.all(
                        isDark ? AppColors.darkSurface2 : AppColors.lightSurface2),
                    columns: [
                      DataColumn2(label: _h('Subject', isDark), size: ColumnSize.L),
                      DataColumn2(label: _h('To', isDark)),
                      DataColumn2(label: _h('Status', isDark), fixedWidth: 90),
                      DataColumn2(label: _h('Lead', isDark)),
                      DataColumn2(label: _h('Sent At', isDark)),
                      DataColumn2(label: _h('Opened', isDark), fixedWidth: 80),
                    ],
                    rows: _emails.map((e) => DataRow2(cells: [
                      DataCell(Text(e.subject, style: GoogleFonts.inter(fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkText : AppColors.lightText),
                          overflow: TextOverflow.ellipsis)),
                      DataCell(Text(e.toEmail, style: GoogleFonts.inter(fontSize: 12,
                          color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub),
                          overflow: TextOverflow.ellipsis)),
                      DataCell(_badge(e.status, _statusColor(e.status))),
                      DataCell(Text(e.leadName ?? '—', style: GoogleFonts.inter(fontSize: 12,
                          color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub))),
                      DataCell(Text(e.sentAt != null ? _fmt(e.sentAt!) : '—',
                          style: GoogleFonts.inter(fontSize: 12,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted))),
                      DataCell(e.openedAt != null
                          ? const Icon(Icons.done_all_rounded, size: 16, color: AppColors.success)
                          : const SizedBox.shrink()),
                    ])).toList(),
                  ),
      ),
    ]);
  }

  Widget _h(String t, bool isDark) => Text(t, style: GoogleFonts.inter(fontSize: 11,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted));

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.25))),
    child: Text(label[0].toUpperCase() + label.substring(1),
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
  );

  String _fmt(String dt) {
    try { return DateFormat('dd MMM yy, hh:mm a').format(DateTime.parse(dt).toLocal()); }
    catch (_) { return dt; }
  }
}

// ─── Campaigns Screen ─────────────────────────────────────────────────────────
class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});
  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  List<EmailCampaignModel> _campaigns = [];
  bool _loading = true;
  int _total = 0;
  bool _showForm = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await CommsService.instance.getCampaigns();
    setState(() { _campaigns = r['results'] as List<EmailCampaignModel>;
      _total = toInt(r['count']); _loading = false; });
  }

  Color _statusColor(String s) => switch(s) {
    'running'   => AppColors.success,
    'completed' => AppColors.info,
    'paused'    => AppColors.warning,
    'draft'     => AppColors.lightTextMuted,
    _           => AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(children: [
      Expanded(child: Column(children: [
        PageHeader(
          title: 'Campaigns',
          subtitle: '$_total campaigns',
          actions: [
            CrmButton(label: 'New Campaign', icon: Icons.add_rounded, primary: true,
                onPressed: () => setState(() => _showForm = true)),
          ],
        ),
        Expanded(
          child: _loading && _campaigns.isEmpty
              ? const TableShimmer()
              : _campaigns.isEmpty
                  ? const EmptyState(icon: Icons.campaign_outlined,
                      title: 'No campaigns', subtitle: 'Create your first email campaign.')
                  : DataTable2(
                      columnSpacing: 12, horizontalMargin: 16, minWidth: 700,
                      headingRowHeight: 40, dataRowHeight: 60,
                      headingRowColor: MaterialStateProperty.all(
                          isDark ? AppColors.darkSurface2 : AppColors.lightSurface2),
                      columns: [
                        DataColumn2(label: _h('Campaign', isDark), size: ColumnSize.L),
                        DataColumn2(label: _h('Status', isDark), fixedWidth: 90),
                        DataColumn2(label: _h('Progress', isDark)),
                        DataColumn2(label: _h('Sent', isDark), fixedWidth: 70),
                        DataColumn2(label: _h('Opened', isDark), fixedWidth: 80),
                        DataColumn2(label: _h('Clicks', isDark), fixedWidth: 70),
                        DataColumn2(label: _h('Created', isDark)),
                      ],
                      rows: _campaigns.map((c) => DataRow2(cells: [
                        DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(c.name, style: GoogleFonts.inter(fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkText : AppColors.lightText),
                              overflow: TextOverflow.ellipsis),
                          if (c.description != null)
                            Text(c.description!, style: GoogleFonts.inter(fontSize: 11,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                overflow: TextOverflow.ellipsis),
                        ])),
                        DataCell(_badge(c.status, _statusColor(c.status))),
                        DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('${c.progress.toStringAsFixed(0)}%',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          SizedBox(height: 4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: c.progress / 100,
                                backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
                                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                              ),
                            ),
                          ),
                        ])),
                        DataCell(Text('${c.sentCount}', style: GoogleFonts.inter(fontSize: 12))),
                        DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('${c.openCount}', style: GoogleFonts.inter(fontSize: 12)),
                          Text('${c.openRate.toStringAsFixed(0)}%',
                              style: GoogleFonts.inter(fontSize: 10,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                        ])),
                        DataCell(Text('${c.clickCount}', style: GoogleFonts.inter(fontSize: 12))),
                        DataCell(Text(_fmt(c.createdAt), style: GoogleFonts.inter(fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted))),
                      ])).toList(),
                    ),
        ),
      ])),
      if (_showForm)
        SidePanel(
          title: 'New Campaign', width: 400,
          onClose: () => setState(() => _showForm = false),
          child: _CampaignForm(onSaved: () { setState(() => _showForm = false); _load(); }),
        ),
    ]);
  }

  Widget _h(String t, bool isDark) => Text(t, style: GoogleFonts.inter(fontSize: 11,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted));

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.25))),
    child: Text(label[0].toUpperCase() + label.substring(1),
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
  );

  String _fmt(String dt) {
    try { return DateFormat('dd MMM yyyy').format(DateTime.parse(dt).toLocal()); }
    catch (_) { return dt; }
  }
}

class _CampaignForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _CampaignForm({required this.onSaved});
  @override
  State<_CampaignForm> createState() => _CampaignFormState();
}

class _CampaignFormState extends State<_CampaignForm> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;
  List<EmailTemplateModel> _templates = [];
  List<EmailConfigModel> _configs = [];
  int? _templateId;
  int? _configId;
  bool _loadingDeps = true;

  @override
  void initState() {
    super.initState();
    _loadDeps();
  }

  Future<void> _loadDeps() async {
    try {
      final tRes = await CommsService.instance.getTemplates();
      final configs = await CommsService.instance.getEmailConfigs();
      if (mounted) {
        setState(() {
          _templates = tRes['results'] as List<EmailTemplateModel>;
          _configs = configs;
          _loadingDeps = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDeps = false);
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }
  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _templateId == null || _configId == null) return;
    setState(() => _saving = true);
    try {
      await CommsService.instance.createCampaign({
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'template': _templateId,
        'email_config': _configId,
        'status': 'draft',
      });
      widget.onSaved();
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: Padding(
        padding: const EdgeInsets.all(16),
        child: _loadingDeps
            ? const Center(child: CircularProgressIndicator())
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Campaign Name *', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'e.g. Q1 Outreach')),
                const SizedBox(height: 12),
                Text('Description', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Optional description...')),
                const SizedBox(height: 12),
                Text('Email Template *', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int?>(
                  value: _templateId,
                  decoration: const InputDecoration(hintText: 'Select a template'),
                  items: _templates.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name,
                      style: GoogleFonts.inter(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _templateId = v),
                ),
                const SizedBox(height: 12),
                Text('Email Configuration *', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int?>(
                  value: _configId,
                  decoration: const InputDecoration(hintText: 'Select email config'),
                  items: _configs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name,
                      style: GoogleFonts.inter(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _configId = v),
                ),
              ]),
      )),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Create Campaign'),
          )),
        ]),
      ),
    ]);
  }
}

// ─── Templates Screen ─────────────────────────────────────────────────────────
class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});
  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  List<EmailTemplateModel> _templates = [];
  bool _loading = true;
  int _total = 0;
  final _searchCtrl = TextEditingController();
  EmailTemplateModel? _editing;
  bool _showForm = false;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await CommsService.instance.getTemplates(
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim());
    setState(() { _templates = r['results'] as List<EmailTemplateModel>;
      _total = toInt(r['count']); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(children: [
      Expanded(child: Column(children: [
        PageHeader(
          title: 'Email Templates',
          subtitle: '$_total templates',
          actions: [
            CrmButton(label: 'New Template', icon: Icons.add_rounded, primary: true,
                onPressed: () => setState(() { _editing = null; _showForm = true; })),
          ],
        ),
        TableToolbar(
          searchCtrl: _searchCtrl,
          searchHint: 'Search templates...',
          actions: [
            CrmButton(label: 'Search', onPressed: _load),
          ],
        ),
        Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        Expanded(
          child: _loading && _templates.isEmpty
              ? const TableShimmer()
              : _templates.isEmpty
                  ? const EmptyState(icon: Icons.description_outlined,
                      title: 'No templates', subtitle: 'Create reusable email templates.')
                  : DataTable2(
                      columnSpacing: 12, horizontalMargin: 16,
                      headingRowHeight: 40, dataRowHeight: 52,
                      headingRowColor: MaterialStateProperty.all(
                          isDark ? AppColors.darkSurface2 : AppColors.lightSurface2),
                      columns: [
                        DataColumn2(label: _h('Name', isDark), size: ColumnSize.L),
                        DataColumn2(label: _h('Subject', isDark), size: ColumnSize.L),
                        DataColumn2(label: _h('Type', isDark), fixedWidth: 100),
                        DataColumn2(label: _h('Status', isDark), fixedWidth: 80),
                        DataColumn2(label: _h('Used', isDark), fixedWidth: 60),
                        DataColumn2(label: _h('', isDark), fixedWidth: 80),
                      ],
                      rows: _templates.map((t) => DataRow2(
                        onTap: () => setState(() { _editing = t; _showForm = true; }),
                        cells: [
                          DataCell(Text(t.name, style: GoogleFonts.inter(fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.darkText : AppColors.lightText),
                              overflow: TextOverflow.ellipsis)),
                          DataCell(Text(t.subject, style: GoogleFonts.inter(fontSize: 12,
                              color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub),
                              overflow: TextOverflow.ellipsis)),
                          DataCell(_typeBadge(t.templateType, isDark)),
                          DataCell(t.isActive
                              ? _dot(AppColors.success, 'Active')
                              : _dot(AppColors.error, 'Inactive')),
                          DataCell(Text('${t.usageCount}×', style: GoogleFonts.inter(fontSize: 12))),
                          DataCell(Row(children: [
                            _iconBtn(Icons.edit_outlined, () => setState(() { _editing = t; _showForm = true; }), isDark),
                            const SizedBox(width: 4),
                            _iconBtn(Icons.delete_outline_rounded, () async {
                              await CommsService.instance.deleteTemplate(t.id);
                              _load();
                            }, isDark, danger: true),
                          ])),
                        ],
                      )).toList(),
                    ),
        ),
      ])),
      if (_showForm)
        SidePanel(
          title: _editing != null ? 'Edit Template' : 'New Template',
          width: 500,
          onClose: () => setState(() => _showForm = false),
          child: _TemplateForm(
            key: ValueKey(_editing?.id ?? 'new'),
            template: _editing,
            onSaved: () { setState(() => _showForm = false); _load(); },
          ),
        ),
    ]);
  }

  Widget _h(String t, bool isDark) => Text(t, style: GoogleFonts.inter(fontSize: 11,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted));

  Widget _typeBadge(String type, bool isDark) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
        borderRadius: BorderRadius.circular(4)),
    child: Text(type.replaceAll('_', ' '), style: GoogleFonts.inter(fontSize: 10,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
  );

  Widget _dot(Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(label, style: GoogleFonts.inter(fontSize: 11)),
  ]);

  Widget _iconBtn(IconData icon, VoidCallback onTap, bool isDark, {bool danger = false}) =>
      InkWell(onTap: onTap, borderRadius: BorderRadius.circular(4),
          child: Padding(padding: const EdgeInsets.all(4),
              child: Icon(icon, size: 16,
                  color: danger ? AppColors.error
                      : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted))));
}

class _TemplateForm extends StatefulWidget {
  final EmailTemplateModel? template;
  final VoidCallback onSaved;
  const _TemplateForm({super.key, this.template, required this.onSaved});
  @override
  State<_TemplateForm> createState() => _TemplateFormState();
}

class _TemplateFormState extends State<_TemplateForm> {
  final _nameCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _type = 'custom';
  bool _shared = false, _active = true, _saving = false;
  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      final t = widget.template!;
      _nameCtrl.text = t.name; _subjectCtrl.text = t.subject;
      _bodyCtrl.text = t.bodyHtml; _type = t.templateType;
      _shared = t.isShared; _active = t.isActive;
    }
  }
  @override
  void dispose() { _nameCtrl.dispose(); _subjectCtrl.dispose(); _bodyCtrl.dispose(); super.dispose(); }
  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _subjectCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final body = {'name': _nameCtrl.text.trim(), 'subject': _subjectCtrl.text.trim(),
      'body_html': _bodyCtrl.text.trim(), 'template_type': _type,
      'is_shared': _shared, 'is_active': _active};
    if (widget.template != null) await CommsService.instance.updateTemplate(widget.template!.id, body);
    else await CommsService.instance.createTemplate(body);
    widget.onSaved();
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget lbl(String t) => Padding(padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(t, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)));
    return Column(children: [
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          lbl('Name *'),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Template name')),
          lbl('Subject *'),
          TextField(controller: _subjectCtrl, decoration: const InputDecoration(hintText: 'Email subject line')),
          lbl('Type'),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(),
            items: ['welcome','follow_up','quote_request','proposal','thank_you','nurture','appointment','custom']
                .map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_',' ').split(' ')
                    .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w).join(' '),
                    style: GoogleFonts.inter(fontSize: 13)))).toList(),
            onChanged: (v) { if (v != null) setState(() => _type = v); },
          ),
          lbl('Body (HTML)'),
          TextField(controller: _bodyCtrl, maxLines: 10,
              decoration: const InputDecoration(hintText: 'Email HTML content...',
                  alignLabelWithHint: true)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: CheckboxListTile(contentPadding: EdgeInsets.zero, dense: true,
                title: Text('Shared', style: GoogleFonts.inter(fontSize: 12)),
                value: _shared, onChanged: (v) => setState(() => _shared = v!))),
            Expanded(child: CheckboxListTile(contentPadding: EdgeInsets.zero, dense: true,
                title: Text('Active', style: GoogleFonts.inter(fontSize: 12)),
                value: _active, onChanged: (v) => setState(() => _active = v!))),
          ]),
        ],
      ))),
      Padding(padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(widget.template != null ? 'Update' : 'Create'),
            )),
          ])),
    ]);
  }
}

// ─── Sequences Screen ─────────────────────────────────────────────────────────
class SequencesScreen extends StatefulWidget {
  const SequencesScreen({super.key});
  @override
  State<SequencesScreen> createState() => _SequencesScreenState();
}

class _SequencesScreenState extends State<SequencesScreen> {
  List<EmailSequenceModel> _sequences = [];
  bool _loading = true;
  bool _showForm = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await CommsService.instance.getSequences();
    setState(() { _sequences = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(children: [
      Expanded(child: Column(children: [
        PageHeader(
          title: 'Email Sequences',
          subtitle: '${_sequences.length} sequences',
          actions: [
            CrmButton(label: 'New Sequence', icon: Icons.add_rounded, primary: true,
                onPressed: () => setState(() => _showForm = true)),
          ],
        ),
        Expanded(
          child: _loading && _sequences.isEmpty
              ? const TableShimmer()
              : _sequences.isEmpty
                  ? const EmptyState(icon: Icons.linear_scale_rounded,
                      title: 'No sequences', subtitle: 'Automate follow-up emails with sequences.')
                  : DataTable2(
                      columnSpacing: 12, horizontalMargin: 16,
                      headingRowHeight: 40, dataRowHeight: 48,
                      headingRowColor: MaterialStateProperty.all(
                          isDark ? AppColors.darkSurface2 : AppColors.lightSurface2),
                      columns: [
                        DataColumn2(label: _h('Name', isDark), size: ColumnSize.L),
                        DataColumn2(label: _h('Description', isDark), size: ColumnSize.L),
                        DataColumn2(label: _h('Steps', isDark), fixedWidth: 80),
                        DataColumn2(label: _h('Status', isDark), fixedWidth: 90),
                        DataColumn2(label: _h('Created', isDark)),
                      ],
                      rows: _sequences.map((s) => DataRow2(cells: [
                        DataCell(Text(s.name, style: GoogleFonts.inter(fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkText : AppColors.lightText))),
                        DataCell(Text(s.description ?? '—', style: GoogleFonts.inter(fontSize: 12,
                            color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub),
                            overflow: TextOverflow.ellipsis)),
                        DataCell(Text('${s.stepsCount}', style: GoogleFonts.inter(fontSize: 12))),
                        DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(
                              color: s.isActive ? AppColors.success : AppColors.error,
                              shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text(s.isActive ? 'Active' : 'Inactive', style: GoogleFonts.inter(fontSize: 11)),
                        ])),
                        DataCell(Text(_fmt(s.createdAt), style: GoogleFonts.inter(fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted))),
                      ])).toList(),
                    ),
        ),
      ])),
      if (_showForm)
        SidePanel(
          title: 'New Sequence', width: 380,
          onClose: () => setState(() => _showForm = false),
          child: _SequenceForm(onSaved: () { setState(() => _showForm = false); _load(); }),
        ),
    ]);
  }

  Widget _h(String t, bool isDark) => Text(t, style: GoogleFonts.inter(fontSize: 11,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted));

  String _fmt(String dt) {
    try { return DateFormat('dd MMM yyyy').format(DateTime.parse(dt).toLocal()); }
    catch (_) { return dt; }
  }
}

class _SequenceForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _SequenceForm({required this.onSaved});
  @override
  State<_SequenceForm> createState() => _SequenceFormState();
}

class _SequenceFormState extends State<_SequenceForm> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _active = true, _saving = false;
  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }
  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await CommsService.instance.createSequence({'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(), 'is_active': _active});
    widget.onSaved();
  }
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Name *', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Sequence name')),
          const SizedBox(height: 12),
          Text('Description', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Optional description')),
          const SizedBox(height: 8),
          CheckboxListTile(contentPadding: EdgeInsets.zero, dense: true,
              title: Text('Active', style: GoogleFonts.inter(fontSize: 12)),
              value: _active, onChanged: (v) => setState(() => _active = v!)),
        ],
      ))),
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: ElevatedButton(
          onPressed: _saving ? null : _save,
          child: const Text('Create Sequence'),
        )),
      ])),
    ]);
  }
}
