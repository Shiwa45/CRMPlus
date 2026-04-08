import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/num_utils.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/services.dart';
import '../../services/tenant_service.dart';
import '../../widgets/desktop_widgets.dart';

// ─── Email Config Screen ──────────────────────────────────────────────────────
class EmailConfigScreen extends StatefulWidget {
  const EmailConfigScreen({super.key});
  @override
  State<EmailConfigScreen> createState() => _EmailConfigScreenState();
}

class _EmailConfigScreenState extends State<EmailConfigScreen> {
  List<EmailConfigModel> _configs = [];
  bool _loading = true;
  EmailConfigModel? _editing;
  bool _showForm = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final c = await CommsService.instance.getEmailConfigs();
    setState(() { _configs = c; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(children: [
      Expanded(child: Column(children: [
        PageHeader(
          title: 'Email Configuration',
          subtitle: 'Manage SMTP and email provider settings',
          actions: [
            CrmButton(label: 'Add Config', icon: Icons.add_rounded, primary: true,
                onPressed: () => setState(() { _editing = null; _showForm = true; })),
          ],
        ),
        Expanded(
          child: _loading && _configs.isEmpty
              ? const TableShimmer(rows: 5)
              : _configs.isEmpty
                  ? const EmptyState(icon: Icons.settings_input_composite_outlined,
                      title: 'No email configs', subtitle: 'Add an SMTP configuration to start sending emails.')
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(children: _configs.map((c) => _ConfigCard(
                        config: c,
                        isDark: isDark,
                        onEdit: () => setState(() { _editing = c; _showForm = true; }),
                      )).toList()),
                    ),
        ),
      ])),
      if (_showForm)
        SidePanel(
          title: _editing != null ? 'Edit Config' : 'New Email Config',
          width: 460,
          onClose: () => setState(() => _showForm = false),
          child: _EmailConfigForm(
            key: ValueKey(_editing?.id ?? 'new'),
            config: _editing,
            onSaved: () { setState(() => _showForm = false); _load(); },
          ),
        ),
    ]);
  }
}

class _ConfigCard extends StatelessWidget {
  final EmailConfigModel config;
  final bool isDark;
  final VoidCallback onEdit;
  const _ConfigCard({required this.config, required this.isDark, required this.onEdit});
  @override
  Widget build(BuildContext context) {
    final c = config;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(c.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText)),
          const SizedBox(width: 8),
          if (c.isDefault) Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(4)),
            child: Text('Default', style: GoogleFonts.inter(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          Container(width: 8, height: 8, decoration: BoxDecoration(
              color: c.isActive ? AppColors.success : AppColors.error, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(c.isActive ? 'Active' : 'Inactive', style: GoogleFonts.inter(fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          const SizedBox(width: 12),
          CrmButton(label: 'Edit', icon: Icons.edit_outlined, onPressed: onEdit),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 24, runSpacing: 6, children: [
          _info('Provider', c.provider.toUpperCase(), isDark),
          _info('Host', '${c.smtpHost}:${c.smtpPort}', isDark),
          _info('From', '${c.fromName} <${c.fromEmail}>', isDark),
          _info('Daily Limit', '${c.dailyLimit}/day', isDark),
          if (c.useTls) _info('Security', 'TLS', isDark),
          if (c.useSsl) _info('Security', 'SSL', isDark),
        ]),
      ]),
    );
  }

  Widget _info(String label, String value, bool isDark) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text('$label: ', style: GoogleFonts.inter(fontSize: 12,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
    Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkText : AppColors.lightText)),
  ]);
}

class _EmailConfigForm extends StatefulWidget {
  final EmailConfigModel? config;
  final VoidCallback onSaved;
  const _EmailConfigForm({super.key, this.config, required this.onSaved});
  @override
  State<_EmailConfigForm> createState() => _EmailConfigFormState();
}

class _EmailConfigFormState extends State<_EmailConfigForm> {
  final _ctrls = <String, TextEditingController>{};
  String _provider = 'smtp';
  bool _tls = true, _ssl = false, _default = false, _active = true, _saving = false, _obscure = true;
  @override
  void initState() {
    super.initState();
    for (final k in ['name','host','port','username','password','fromEmail','fromName','limit']) {
      _ctrls[k] = TextEditingController();
    }
    _ctrls['port']!.text = '587'; _ctrls['limit']!.text = '500';
    if (widget.config != null) {
      final c = widget.config!;
      _ctrls['name']!.text = c.name; _ctrls['host']!.text = c.smtpHost;
      _ctrls['port']!.text = '${c.smtpPort}'; _ctrls['username']!.text = c.smtpUsername;
      _ctrls['fromEmail']!.text = c.fromEmail; _ctrls['fromName']!.text = c.fromName;
      _ctrls['limit']!.text = '${c.dailyLimit}'; _provider = c.provider;
      _tls = c.useTls; _ssl = c.useSsl; _default = c.isDefault; _active = c.isActive;
    }
  }
  @override
  void dispose() { for (final c in _ctrls.values) c.dispose(); super.dispose(); }
  String v(String k) => _ctrls[k]!.text.trim();
  Future<void> _save() async {
    setState(() => _saving = true);
    final body = {'name': v('name'), 'provider': _provider, 'smtp_host': v('host'),
      'smtp_port': int.tryParse(v('port')) ?? 587, 'smtp_username': v('username'),
      'from_email': v('fromEmail'), 'from_name': v('fromName'),
      'use_tls': _tls, 'use_ssl': _ssl, 'is_default': _default, 'is_active': _active,
      'daily_limit': int.tryParse(v('limit')) ?? 500,
      if (v('password').isNotEmpty) 'smtp_password': v('password')};
    if (widget.config != null) await CommsService.instance.updateEmailConfig(widget.config!.id, body);
    else await CommsService.instance.createEmailConfig(body);
    widget.onSaved();
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget lbl(String t) => Padding(padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(t, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)));
    Widget tf(String k, String hint, {TextInputType? kb}) => TextField(controller: _ctrls[k],
        keyboardType: kb, style: GoogleFonts.inter(fontSize: 13),
        decoration: InputDecoration(hintText: hint));
    return Column(children: [
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          lbl('Config Name *'), tf('name', 'e.g. Primary SMTP'),
          lbl('Provider'),
          DropdownButtonFormField<String>(value: _provider, decoration: const InputDecoration(),
            items: ['smtp','gmail','sendgrid','mailgun','ses'].map((p) =>
                DropdownMenuItem(value: p, child: Text(p.toUpperCase(), style: GoogleFonts.inter(fontSize: 13)))).toList(),
            onChanged: (v) { if (v != null) setState(() => _provider = v); }),
          lbl('SMTP Host'),
          Row(children: [
            Expanded(child: tf('host', 'smtp.gmail.com')),
            const SizedBox(width: 10),
            SizedBox(width: 80, child: tf('port', '587', kb: TextInputType.number)),
          ]),
          lbl('Username'), tf('username', 'user@email.com'),
          lbl('Password'),
          TextField(controller: _ctrls['password'], obscureText: _obscure,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: widget.config != null ? 'Leave blank to keep current' : 'Password',
                suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                    onPressed: () => setState(() => _obscure = !_obscure)),
              )),
          lbl('From Email'), tf('fromEmail', 'noreply@company.com', kb: TextInputType.emailAddress),
          lbl('From Name'), tf('fromName', 'Company Name'),
          lbl('Daily Send Limit'), tf('limit', '500', kb: TextInputType.number),
          const SizedBox(height: 8),
          Wrap(children: [
            _check('TLS', _tls, (v) => setState(() => _tls = v!)),
            _check('SSL', _ssl, (v) => setState(() => _ssl = v!)),
            _check('Set as Default', _default, (v) => setState(() => _default = v!)),
            _check('Active', _active, (v) => setState(() => _active = v!)),
          ]),
        ],
      ))),
      Padding(padding: const EdgeInsets.all(16),
        child: Row(children: [Expanded(child: ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(widget.config != null ? 'Update Config' : 'Add Config'),
        ))]),
      ),
    ]);
  }
  Widget _check(String label, bool val, ValueChanged<bool?> onChange) =>
      SizedBox(width: 160, child: CheckboxListTile(contentPadding: EdgeInsets.zero, dense: true,
          title: Text(label, style: GoogleFonts.inter(fontSize: 12)), value: val, onChanged: onChange));
}

// ─── KPI Targets Screen ───────────────────────────────────────────────────────
class KpiTargetsScreen extends StatefulWidget {
  const KpiTargetsScreen({super.key});
  @override
  State<KpiTargetsScreen> createState() => _KpiTargetsScreenState();
}

class _KpiTargetsScreenState extends State<KpiTargetsScreen> {
  List<KPITargetModel> _targets = [];
  bool _loading = true;
  bool _showForm = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final t = await DashboardService.instance.getKpiTargets();
    setState(() { _targets = t; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(children: [
      Expanded(child: Column(children: [
        PageHeader(
          title: 'KPI Targets',
          subtitle: 'Set and track performance goals',
          actions: [
            CrmButton(label: 'Add Target', icon: Icons.add_rounded, primary: true,
                onPressed: () => setState(() => _showForm = true)),
          ],
        ),
        Expanded(
          child: _loading && _targets.isEmpty
              ? const TableShimmer(rows: 6)
              : _targets.isEmpty
                  ? const EmptyState(icon: Icons.flag_outlined,
                      title: 'No KPI targets', subtitle: 'Add targets to track team performance.')
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(children: [
                        // KPI grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, crossAxisSpacing: 12,
                            mainAxisSpacing: 12, childAspectRatio: 2.2,
                          ),
                          itemCount: _targets.length,
                          itemBuilder: (_, i) => _KpiTargetCard(target: _targets[i], isDark: isDark),
                        ),
                      ]),
                    ),
        ),
      ])),
      if (_showForm)
        SidePanel(
          title: 'New KPI Target', width: 380,
          onClose: () => setState(() => _showForm = false),
          child: _KpiForm(onSaved: () { setState(() => _showForm = false); _load(); }),
        ),
    ]);
  }
}

class _KpiTargetCard extends StatelessWidget {
  final KPITargetModel target;
  final bool isDark;
  const _KpiTargetCard({required this.target, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final pct = (target.completionPercentage / 100).clamp(0.0, 1.0);
    final color = target.isAchieved ? AppColors.success
        : pct > 0.7 ? AppColors.accent : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(
            target.kpiType.replaceAll('_', ' ').split(' ')
                .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w).join(' '),
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.lightText),
            overflow: TextOverflow.ellipsis,
          )),
          if (target.isAchieved)
            const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
        ]),
        const Spacer(),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text('${target.currentValue.toInt()}',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          Text(' / ${target.targetValue.toInt()}',
              style: GoogleFonts.inter(fontSize: 13,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        Text('${target.completionPercentage.toStringAsFixed(0)}% complete',
            style: GoogleFonts.inter(fontSize: 10,
                color: isDark ? AppColors.darkTextFaint : AppColors.lightTextFaint)),
      ]),
    );
  }
}

class _KpiForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _KpiForm({required this.onSaved});
  @override
  State<_KpiForm> createState() => _KpiFormState();
}

class _KpiFormState extends State<_KpiForm> {
  String _type = 'leads_created';
  final _targetCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startCtrl.text = '${now.year}-${now.month.toString().padLeft(2,'0')}-01';
    _endCtrl.text = '${now.year}-${now.month.toString().padLeft(2,'0')}-${DateTime(now.year, now.month+1, 0).day}';
  }
  @override
  void dispose() { _targetCtrl.dispose(); _startCtrl.dispose(); _endCtrl.dispose(); super.dispose(); }
  Future<void> _save() async {
    if (_targetCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await DashboardService.instance.createKpiTarget({'kpi_type': _type,
      'target_value': double.tryParse(_targetCtrl.text.trim()) ?? 0,
      'period_start': _startCtrl.text.trim(), 'period_end': _endCtrl.text.trim(), 'is_active': true});
    widget.onSaved();
  }
  @override
  Widget build(BuildContext context) {
    Widget lbl(String t) => Padding(padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(t, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)));
    return Column(children: [
      Expanded(child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          lbl('KPI Type'),
          DropdownButtonFormField<String>(value: _type, decoration: const InputDecoration(),
            items: ['leads_created','leads_converted','revenue_generated','calls_made','emails_sent','meetings_scheduled']
                .map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_',' ').split(' ')
                    .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w).join(' '),
                    style: GoogleFonts.inter(fontSize: 13)))).toList(),
            onChanged: (v) { if (v != null) setState(() => _type = v); }),
          lbl('Target Value *'),
          TextField(controller: _targetCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'e.g. 100')),
          lbl('Period Start'),
          TextField(controller: _startCtrl, decoration: const InputDecoration(hintText: 'YYYY-MM-DD')),
          lbl('Period End'),
          TextField(controller: _endCtrl, decoration: const InputDecoration(hintText: 'YYYY-MM-DD')),
        ],
      ))),
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: ElevatedButton(
          onPressed: _saving ? null : _save,
          child: const Text('Create Target'),
        )),
      ])),
    ]);
  }
}

// ─── Users Screen ─────────────────────────────────────────────────────────────
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<UserModel> _users = [];
  bool _loading = true;
  int _total = 0;
  final _searchCtrl = TextEditingController();
  UserModel? _editing;
  bool _showForm = false;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await UsersService.instance.getUsers(
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim());
    setState(() { _users = r['results'] as List<UserModel>;
      _total = toInt(r['count']); _loading = false; });
  }

  Color _roleColor(String role) => switch(role) {
    'superadmin'   => AppColors.logoRed,
    'admin'        => AppColors.error,
    'sales_manager'=> AppColors.warning,
    _              => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(children: [
      Expanded(child: Column(children: [
        PageHeader(
          title: 'Users',
          subtitle: '$_total team members',
          actions: [
            CrmButton(label: 'Add User', icon: Icons.person_add_rounded, primary: true,
                onPressed: () => setState(() { _editing = null; _showForm = true; })),
          ],
        ),
        TableToolbar(
          searchCtrl: _searchCtrl,
          searchHint: 'Search users by name or email...',
          actions: [
            CrmButton(label: 'Search', onPressed: _load),
            const SizedBox(width: 8),
            Text('$_total users', style: GoogleFonts.inter(fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          ],
        ),
        Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        Expanded(
          child: _loading && _users.isEmpty
              ? const TableShimmer()
              : _users.isEmpty
                  ? const EmptyState(icon: Icons.people_outline_rounded,
                      title: 'No users found', subtitle: 'Add team members to get started.')
                  : DataTable2(
                      columnSpacing: 12, horizontalMargin: 16,
                      headingRowHeight: 40, dataRowHeight: 52,
                      headingRowColor: MaterialStateProperty.all(
                          isDark ? AppColors.darkSurface2 : AppColors.lightSurface2),
                      columns: [
                        DataColumn2(label: _h('User', isDark), size: ColumnSize.L),
                        DataColumn2(label: _h('Email', isDark), size: ColumnSize.L),
                        DataColumn2(label: _h('Role', isDark)),
                        DataColumn2(label: _h('Department', isDark)),
                        DataColumn2(label: _h('Status', isDark), fixedWidth: 80),
                        DataColumn2(label: _h('', isDark), fixedWidth: 60),
                      ],
                      rows: _users.map((u) => DataRow2(
                        onTap: () => setState(() { _editing = u; _showForm = true; }),
                        cells: [
                          DataCell(Row(children: [
                            CircleAvatar(radius: 16,
                                backgroundColor: _roleColor(u.role).withOpacity(0.12),
                                child: Text(u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
                                        color: _roleColor(u.role)))),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(u.fullName, style: GoogleFonts.inter(fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.darkText : AppColors.lightText)),
                              Text('@${u.username}', style: GoogleFonts.inter(fontSize: 11,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                            ])),
                          ])),
                          DataCell(Text(u.email, style: GoogleFonts.inter(fontSize: 12,
                              color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub),
                              overflow: TextOverflow.ellipsis)),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: _roleColor(u.role).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _roleColor(u.role).withOpacity(0.25))),
                            child: Text(u.roleDisplayName, style: GoogleFonts.inter(fontSize: 10,
                                fontWeight: FontWeight.w600, color: _roleColor(u.role))),
                          )),
                          DataCell(Text(u.department ?? '—', style: GoogleFonts.inter(fontSize: 12,
                              color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub))),
                          DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 6, height: 6, decoration: BoxDecoration(
                                color: u.isActive ? AppColors.success : AppColors.error,
                                shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text(u.isActive ? 'Active' : 'Off', style: GoogleFonts.inter(fontSize: 11)),
                          ])),
                          DataCell(InkWell(
                            onTap: () => setState(() { _editing = u; _showForm = true; }),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(padding: const EdgeInsets.all(4),
                                child: Icon(Icons.edit_outlined, size: 16,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                          )),
                        ],
                      )).toList(),
                    ),
        ),
      ])),
      if (_showForm)
        SidePanel(
          title: _editing != null ? 'Edit User' : 'New User',
          width: 420,
          onClose: () => setState(() => _showForm = false),
          child: _UserForm(
            key: ValueKey(_editing?.id ?? 'new'),
            user: _editing,
            onSaved: () { setState(() => _showForm = false); _load(); },
          ),
        ),
    ]);
  }

  Widget _h(String t, bool isDark) => Text(t, style: GoogleFonts.inter(fontSize: 11,
      fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted));
}

class _UserForm extends StatefulWidget {
  final UserModel? user;
  final VoidCallback onSaved;
  const _UserForm({super.key, this.user, required this.onSaved});
  @override
  State<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<_UserForm> {
  final _ctrls = <String, TextEditingController>{};
  String _role = 'sales_rep';
  bool _active = true, _saving = false, _obscure = true;
  @override
  void initState() {
    super.initState();
    for (final k in ['first','last','username','email','phone','dept','password']) {
      _ctrls[k] = TextEditingController();
    }
    if (widget.user != null) {
      final u = widget.user!;
      _ctrls['first']!.text = u.firstName; _ctrls['last']!.text = u.lastName;
      _ctrls['username']!.text = u.username; _ctrls['email']!.text = u.email;
      _ctrls['phone']!.text = u.phone ?? ''; _ctrls['dept']!.text = u.department ?? '';
      _role = u.role; _active = u.isActive;
    }
  }
  @override
  void dispose() { for (final c in _ctrls.values) c.dispose(); super.dispose(); }
  String v(String k) => _ctrls[k]!.text.trim();
  Future<void> _save() async {
    setState(() => _saving = true);
    final body = {'first_name': v('first'), 'last_name': v('last'), 'username': v('username'),
      'email': v('email'), 'phone': v('phone').isEmpty ? null : v('phone'),
      'department': v('dept').isEmpty ? null : v('dept'),
      'role': _role, 'is_active': _active,
      if (widget.user == null && v('password').isNotEmpty) 'password': v('password')};
    if (widget.user != null) await UsersService.instance.updateUser(widget.user!.id, body);
    else await UsersService.instance.createUser(body);
    widget.onSaved();
  }
  @override
  Widget build(BuildContext context) {
    Widget lbl(String t) => Padding(padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(t, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)));
    Widget tf(String k, String hint, {TextInputType? kb}) => TextField(controller: _ctrls[k],
        keyboardType: kb, style: GoogleFonts.inter(fontSize: 13),
        decoration: InputDecoration(hintText: hint));
    return Column(children: [
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              lbl('First Name *'), tf('first', 'John'),
            ])),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              lbl('Last Name'), tf('last', 'Doe'),
            ])),
          ]),
          lbl('Username *'), tf('username', 'johndoe'),
          lbl('Email *'), tf('email', 'john@company.com', kb: TextInputType.emailAddress),
          lbl('Phone'), tf('phone', '+91...', kb: TextInputType.phone),
          lbl('Department'), tf('dept', 'Sales'),
          lbl('Role'),
          DropdownButtonFormField<String>(value: _role, decoration: const InputDecoration(),
            items: const [
              DropdownMenuItem(value: 'sales_rep', child: Text('Sales Rep')),
              DropdownMenuItem(value: 'sales_manager', child: Text('Sales Manager')),
              DropdownMenuItem(value: 'marketing', child: Text('Marketing')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
              DropdownMenuItem(value: 'superadmin', child: Text('Super Admin')),
            ],
            onChanged: (v) { if (v != null) setState(() => _role = v); }),
          if (widget.user == null) ...[
            lbl('Password *'),
            TextField(controller: _ctrls['password'], obscureText: _obscure,
                decoration: InputDecoration(hintText: 'Set password',
                    suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                        onPressed: () => setState(() => _obscure = !_obscure)))),
          ],
          const SizedBox(height: 8),
          CheckboxListTile(contentPadding: EdgeInsets.zero, dense: true,
              title: Text('Active account', style: GoogleFonts.inter(fontSize: 12)),
              value: _active, onChanged: (v) => setState(() => _active = v!)),
        ],
      ))),
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(widget.user != null ? 'Update User' : 'Create User'),
        )),
      ])),
    ]);
  }
}

// ─── Profile Screen ───────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _ctrls = <String, TextEditingController>{};
  bool _editing = false, _saving = false;

  @override
  void initState() {
    super.initState();
    for (final k in ['first','last','email','phone','dept']) {
      _ctrls[k] = TextEditingController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUser());
  }

  void _loadUser() {
    final u = context.read<AppProvider>().currentUser;
    if (u != null) {
      _ctrls['first']!.text = u.firstName; _ctrls['last']!.text = u.lastName;
      _ctrls['email']!.text = u.email; _ctrls['phone']!.text = u.phone ?? '';
      _ctrls['dept']!.text = u.department ?? '';
    }
  }

  @override
  void dispose() { for (final c in _ctrls.values) c.dispose(); super.dispose(); }

  Future<void> _save() async {
    final u = context.read<AppProvider>().currentUser!;
    setState(() => _saving = true);
    final updated = await AuthService.instance.updateProfile(u.id, {
      'first_name': _ctrls['first']!.text.trim(), 'last_name': _ctrls['last']!.text.trim(),
      'email': _ctrls['email']!.text.trim(),
      'phone': _ctrls['phone']!.text.trim().isEmpty ? null : _ctrls['phone']!.text.trim(),
      'department': _ctrls['dept']!.text.trim().isEmpty ? null : _ctrls['dept']!.text.trim(),
    });
    if (mounted) {
      context.read<AppProvider>().updateUser(updated);
      setState(() { _editing = false; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AppProvider>().currentUser;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return Column(children: [
      PageHeader(
        title: 'My Profile',
        subtitle: 'Manage your personal information',
        actions: [
          if (!_editing)
            CrmButton(label: 'Edit Profile', icon: Icons.edit_rounded,
                onPressed: () => setState(() => _editing = true))
          else ...[
            CrmButton(label: 'Cancel',
                onPressed: () { setState(() => _editing = false); _loadUser(); }),
            const SizedBox(width: 8),
            CrmButton(label: 'Save Changes', primary: true, loading: _saving, onPressed: _save),
          ],
        ],
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(children: [
                // Avatar block
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 36, backgroundColor: AppColors.primary.withOpacity(0.12),
                      child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                    const SizedBox(width: 20),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user.fullName, style: GoogleFonts.inter(fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : AppColors.lightText)),
                      Text('@${user.username}', style: GoogleFonts.inter(fontSize: 13,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(user.roleDisplayName, style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),

                // Fields
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(children: [
                    _row(context, 'First Name', _ctrls['first']!,
                        user.firstName, isDark),
                    _divider(isDark),
                    _row(context, 'Last Name', _ctrls['last']!,
                        user.lastName, isDark),
                    _divider(isDark),
                    _row(context, 'Email', _ctrls['email']!,
                        user.email, isDark),
                    _divider(isDark),
                    _row(context, 'Phone', _ctrls['phone']!,
                        user.phone ?? '—', isDark),
                    _divider(isDark),
                    _row(context, 'Department', _ctrls['dept']!,
                        user.department ?? '—', isDark),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _row(BuildContext context, String label, TextEditingController ctrl,
      String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        SizedBox(width: 120, child: Text(label, style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted))),
        Expanded(child: _editing
            ? TextField(controller: ctrl, style: GoogleFonts.inter(fontSize: 13),
                decoration: const InputDecoration())
            : Text(value, style: GoogleFonts.inter(fontSize: 13,
                color: isDark ? AppColors.darkText : AppColors.lightText))),
      ]),
    );
  }

  Widget _divider(bool isDark) =>
      Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder);
}

// ─── Settings Screen ──────────────────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _uploadingLogo = false;

  @override
  void initState() {
    super.initState();
    _loadTenantLogo();
  }

  Future<void> _loadTenantLogo() async {
    final provider = context.read<AppProvider>();
    if (provider.tenantLogo != null && provider.tenantLogo!.isNotEmpty) return;
    try {
      final data = await TenantService.instance.getMe();
      final logo = data['logo'];
      if (logo is String && logo.isNotEmpty) {
        await provider.setTenantLogo(logo);
      }
    } catch (_) {}
  }

  Future<void> _uploadLogo() async {
    if (_uploadingLogo) return;
    setState(() => _uploadingLogo = true);
    try {
      final url = await TenantService.instance.uploadLogo();
      if (!mounted) return;
      if (url != null && url.isNotEmpty) {
        await context.read<AppProvider>().setTenantLogo(url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No logo selected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _uploadingLogo = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;
    final tenantLogo = provider.tenantLogo;

    return Column(children: [
      const PageHeader(
        title: 'Settings',
        subtitle: 'Application preferences and configuration',
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionTitle('Appearance', isDark),
                _settingRow(
                  isDark: isDark,
                  icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  title: 'Theme',
                  subtitle: isDark ? 'Currently using dark mode' : 'Currently using light mode',
                  trailing: Switch(value: isDark, onChanged: (_) => provider.toggleTheme(),
                      activeColor: AppColors.primary),
                ),
                const SizedBox(height: 24),

                _sectionTitle('API Configuration', isDark),
                _settingRow(isDark: isDark, icon: Icons.link_rounded,
                    title: 'Backend URL', subtitle: AppConstants.baseUrl),
                _settingRow(isDark: isDark, icon: Icons.api_rounded,
                    title: 'API Version', subtitle: 'Django REST Framework v3'),
                const SizedBox(height: 24),

                _sectionTitle('Branding', isDark),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: tenantLogo != null && tenantLogo.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(tenantLogo, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.apartment_rounded, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tenant Logo',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkText : AppColors.lightText)),
                          Text('Shown on invoices and PDFs',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                        ],
                      ),
                    ),
                    CrmButton(
                      label: _uploadingLogo ? 'Uploading...' : 'Upload',
                      icon: Icons.upload_rounded,
                      primary: true,
                      loading: _uploadingLogo,
                      onPressed: _uploadingLogo ? null : _uploadLogo,
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                _sectionTitle('About', isDark),
                _settingRow(isDark: isDark, icon: Icons.info_outline_rounded,
                    title: 'Version', subtitle: AppConstants.appVersion),
                _settingRow(isDark: isDark, icon: Icons.business_rounded,
                    title: 'Company', subtitle: AppConstants.companyName),
                const SizedBox(height: 24),

                _sectionTitle('Account', isDark),
                _settingRow(
                  isDark: isDark,
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  subtitle: 'Logout from your account',
                  iconColor: AppColors.error,
                  onTap: () async {
                    final ok = await showDialog<bool>(context: context,
                      builder: (_) => AlertDialog(
                        title: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        content: const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Sign Out')),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) context.read<AppProvider>().logout();
                  },
                ),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _sectionTitle(String title, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
  );

  Widget _settingRow({required bool isDark, required IconData icon, required String title,
      String? subtitle, Widget? trailing, VoidCallback? onTap, Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: iconColor ?? AppColors.primary)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500,
                color: iconColor ?? (isDark ? AppColors.darkText : AppColors.lightText))),
            if (subtitle != null) Text(subtitle, style: GoogleFonts.inter(fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          ])),
          if (trailing != null) trailing
          else if (onTap != null)
            Icon(Icons.chevron_right_rounded, size: 16,
                color: isDark ? AppColors.darkTextFaint : AppColors.lightTextFaint),
        ]),
      ),
    );
  }
}
