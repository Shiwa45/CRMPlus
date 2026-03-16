// screens/leads/lead_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/desktop_widgets.dart';
import '../leads/lead_form_dialog.dart';
import '../../widgets/dialogs/whatsapp_send_dialog.dart';
import '../../widgets/dialogs/quick_email_dialog.dart';

class LeadDetailScreen extends StatefulWidget {
  final int leadId;
  const LeadDetailScreen({super.key, required this.leadId});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen>
    with SingleTickerProviderStateMixin {
  LeadModel? _lead;
  List<LeadActivityModel> _activities = [];
  bool _loading = true;
  late TabController _tabs;

  final _curr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final lead = await LeadsService.instance.getLead(widget.leadId);
      final acts = await LeadsService.instance.getActivities(widget.leadId);
      if (mounted) setState(() { _lead = lead; _activities = acts; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_lead == null) return const Scaffold(body: Center(child: Text('Lead not found')));

    final lead = _lead!;
    final statusColor = _statusColor(lead.status);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF0F4FF),
      body: Column(children: [
        // ── Hero Header ────────────────────────────────────────────────────
        _buildHero(lead, statusColor, isDark),
        // ── Tab Bar ────────────────────────────────────────────────────────
        Container(
          color: isDark ? AppColors.darkSurface : Colors.white,
          child: TabBar(
            controller: _tabs,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? AppColors.darkTextSub : AppColors.lightTextSub,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.info_outline, size: 16), text: 'Overview'),
              Tab(icon: Icon(Icons.timeline, size: 16), text: 'Activity'),
              Tab(icon: Icon(Icons.task_alt, size: 16), text: 'Tasks'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(controller: _tabs, children: [
            _OverviewTab(lead: lead, curr: _curr, isDark: isDark, onRefresh: _load),
            _ActivityTab(activities: _activities, leadId: lead.id, onRefresh: _load, isDark: isDark),
            _TasksTab(leadId: lead.id, isDark: isDark),
          ]),
        ),
      ]),
    );
  }

  Widget _buildHero(LeadModel lead, Color statusColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1F3A), const Color(0xFF0F1628)]
              : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Back + actions row
            Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              _heroAction(Icons.edit_outlined, 'Edit', () => _editLead()),
              const SizedBox(width: 8),
              _heroAction(Icons.more_vert, 'More', () => _showMoreMenu()),
            ]),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Avatar
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: Center(
                  child: Text(
                    (lead.fullName.isNotEmpty ? lead.fullName[0] : '?').toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(lead.fullName,
                    style: GoogleFonts.inter(
                        fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                if (lead.jobTitle != null && lead.jobTitle!.isNotEmpty)
                  Text(lead.jobTitle!,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white.withOpacity(0.8))),
                if (lead.company != null && lead.company!.isNotEmpty)
                  Row(children: [
                    Icon(Icons.business, color: Colors.white.withOpacity(0.7), size: 13),
                    const SizedBox(width: 4),
                    Text(lead.company!,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.white.withOpacity(0.8))),
                  ]),
                const SizedBox(height: 8),
                Row(children: [
                  _statusChip(lead.status, statusColor),
                  const SizedBox(width: 8),
                  _priorityChip(lead.priority),
                ]),
              ])),
            ]),
            const SizedBox(height: 20),
            // Quick action buttons
            Row(children: [
              Expanded(child: _quickActionBtn(
                icon: Icons.whatsapp, label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _sendWhatsApp(),
              )),
              const SizedBox(width: 10),
              Expanded(child: _quickActionBtn(
                icon: Icons.email_outlined, label: 'Email',
                color: Colors.blue.shade300,
                onTap: () => _sendEmail(),
              )),
              const SizedBox(width: 10),
              Expanded(child: _quickActionBtn(
                icon: Icons.phone_outlined, label: 'Call',
                color: Colors.green.shade300,
                onTap: () => _callLead(),
              )),
              const SizedBox(width: 10),
              Expanded(child: _quickActionBtn(
                icon: Icons.star_outline, label: 'Convert',
                color: Colors.amber.shade300,
                onTap: () => _convertLead(),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _heroAction(IconData icon, String tooltip, VoidCallback onTap) =>
      Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      );

  Widget _quickActionBtn({
    required IconData icon, required String label,
    required Color color, required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      );

  Widget _statusChip(String status, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Text(status.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );

  Widget _priorityChip(String priority) {
    final colors = {'hot': Colors.red, 'warm': Colors.orange, 'cold': Colors.blue};
    final c = colors[priority] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.local_fire_department, size: 11, color: c),
        const SizedBox(width: 3),
        Text(priority.toUpperCase(),
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
      ]),
    );
  }

  Color _statusColor(String s) {
    const m = {
      'new': Color(0xFF6366F1), 'contacted': Colors.blue, 'qualified': Color(0xFF10B981),
      'proposal': Colors.orange, 'negotiation': Colors.purple,
      'won': Color(0xFF22C55E), 'lost': Color(0xFFEF4444),
    };
    return m[s] ?? Colors.grey;
  }

  void _editLead() {
    showDialog(
      context: context,
      builder: (_) => LeadFormDialog(lead: _lead, onSaved: _load),
    );
  }

  void _sendWhatsApp() {
    showDialog(
      context: context,
      builder: (_) => WhatsAppSendDialog(
        lead: _lead!,
        onSent: () => ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('WhatsApp sent!'))),
      ),
    );
  }

  void _sendEmail() {
    showDialog(
      context: context,
      builder: (_) => QuickEmailDialog(
        toEmail: _lead!.email,
        toName: _lead!.fullName,
        leadId: _lead!.id,
        onSent: () => ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Email sent!'))),
      ),
    );
  }

  void _callLead() {
    if (_lead?.phone != null) {
      Clipboard.setData(ClipboardData(text: _lead!.phone!));
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Phone ${_lead!.phone} copied')));
    }
  }

  void _convertLead() {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Convert to Deal — coming soon')));
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => _MoreActionsSheet(lead: _lead!, onAction: (a) {
        Navigator.pop(context);
        if (a == 'delete') Navigator.pop(context);
      }),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final LeadModel lead;
  final NumberFormat curr;
  final bool isDark;
  final VoidCallback onRefresh;

  const _OverviewTab({
    required this.lead, required this.curr,
    required this.isDark, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Stats row
        Row(children: [
          _statCard('Budget', lead.budget != null ? curr.format(lead.budget) : '—',
              Icons.currency_rupee, Colors.green, isDark),
          const SizedBox(width: 12),
          _statCard('Source', lead.sourceName ?? 'Direct',
              Icons.source, Colors.blue, isDark),
          const SizedBox(width: 12),
          _statCard('Assigned', lead.assignedToName ?? 'Unassigned',
              Icons.person_outline, Colors.purple, isDark),
        ]),
        const SizedBox(height: 16),
        _infoCard('Contact Information', [
          _infoRow(Icons.email_outlined, 'Email', lead.email),
          if (lead.phone != null) _infoRow(Icons.phone_outlined, 'Phone', lead.phone!),
          if (lead.city != null || lead.state != null)
            _infoRow(Icons.location_on_outlined, 'Location',
                [lead.city, lead.state, lead.country].where((e) => e != null && e!.isNotEmpty).join(', ')),
        ], isDark),
        const SizedBox(height: 12),
        if (lead.requirements != null && lead.requirements!.isNotEmpty)
          _infoCard('Requirements', [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(lead.requirements!,
                  style: GoogleFonts.inter(fontSize: 14,
                      color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)),
            ),
          ], isDark),
        const SizedBox(height: 12),
        _infoCard('Timeline', [
          _infoRow(Icons.add_circle_outline, 'Created', _fmt(lead.createdAt)),
          if (lead.lastContacted != null)
            _infoRow(Icons.access_time, 'Last contacted', _fmt(lead.lastContacted!)),
        ], isDark),
      ]),
    );
  }

  String _fmt(String dt) {
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(dt).toLocal());
    } catch (_) { return dt; }
  }

  Widget _statCard(String label, String value, IconData icon, Color color, bool isDark) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: GoogleFonts.inter(fontSize: 11,
              color: isDark ? AppColors.darkTextFaint : AppColors.lightTextFaint)),
        ]),
      ));

  Widget _infoCard(String title, List<Widget> children, bool isDark) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)),
      const SizedBox(height: 12),
      ...children,
    ]),
  );

  Widget _infoRow(IconData icon, String label, String value) =>
      Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
        Icon(icon, size: 16, color: AppColors.primary.withOpacity(0.7)),
        const SizedBox(width: 10),
        Text('$label: ', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 13),
            overflow: TextOverflow.ellipsis)),
      ]));
}

// ── Activity Tab ──────────────────────────────────────────────────────────────
class _ActivityTab extends StatefulWidget {
  final List<LeadActivityModel> activities;
  final int leadId;
  final VoidCallback onRefresh;
  final bool isDark;

  const _ActivityTab({
    required this.activities, required this.leadId,
    required this.onRefresh, required this.isDark,
  });

  @override
  State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> {
  final _ctrl = TextEditingController();
  String _type = 'call';
  bool _saving = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _log() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await LeadsService.instance.createActivity({
      'lead': widget.leadId, 'activity_type': _type, 'subject': _ctrl.text.trim(),
    });
    _ctrl.clear();
    widget.onRefresh();
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Column(children: [
      // Log activity bar
      Container(
        padding: const EdgeInsets.all(16),
        color: isDark ? AppColors.darkSurface : Colors.white,
        child: Row(children: [
          _typeChip('call', Icons.phone),
          const SizedBox(width: 6),
          _typeChip('email', Icons.email),
          const SizedBox(width: 6),
          _typeChip('note', Icons.note),
          const SizedBox(width: 6),
          _typeChip('meeting', Icons.people),
          const SizedBox(width: 12),
          Expanded(child: TextField(
            controller: _ctrl,
            style: GoogleFonts.inter(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Log an activity...',
              hintStyle: GoogleFonts.inter(fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          )),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _saving ? null : _log,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send, color: Colors.white, size: 16),
          ),
        ]),
      ),
      // Timeline
      Expanded(child: widget.activities.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.timeline, size: 48, color: isDark ? AppColors.darkTextFaint : Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('No activities yet', style: GoogleFonts.inter(color: AppColors.darkTextFaint)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.activities.length,
              itemBuilder: (_, i) => _ActivityTile(
                activity: widget.activities[i], isDark: isDark,
                isLast: i == widget.activities.length - 1,
              ),
            )),
    ]);
  }

  Widget _typeChip(String type, IconData icon) {
    final sel = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : Colors.transparent,
          border: Border.all(color: sel ? AppColors.primary : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: sel ? Colors.white : Colors.grey),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final LeadActivityModel activity;
  final bool isDark, isLast;

  const _ActivityTile({
    required this.activity, required this.isDark, required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final icons = {
      'call': Icons.phone, 'email': Icons.email, 'note': Icons.note,
      'meeting': Icons.people, 'whatsapp': Icons.chat,
    };
    final colors = {
      'call': Colors.green, 'email': Colors.blue, 'note': Colors.orange,
      'meeting': Colors.purple, 'whatsapp': const Color(0xFF25D366),
    };
    final icon = icons[activity.activityType] ?? Icons.circle;
    final color = colors[activity.activityType] ?? Colors.grey;

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: color),
        ),
        if (!isLast) Container(width: 2, height: 40, color: Colors.grey.withOpacity(0.2)),
      ]),
      const SizedBox(width: 14),
      Expanded(child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(activity.activityType.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            ),
            const Spacer(),
            Text(_ago(activity.createdAt),
                style: GoogleFonts.inter(fontSize: 11,
                    color: isDark ? AppColors.darkTextFaint : AppColors.lightTextFaint)),
          ]),
          const SizedBox(height: 6),
          Text(activity.subject,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText)),
        ]),
      )),
    ]);
  }

  String _ago(String dt) {
    try {
      final d = DateTime.parse(dt).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inDays > 1) return DateFormat('dd MMM').format(d);
      if (diff.inHours >= 1) return '${diff.inHours}h ago';
      if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
      return 'just now';
    } catch (_) { return dt; }
  }
}

// ── Tasks Tab ─────────────────────────────────────────────────────────────────
class _TasksTab extends StatelessWidget {
  final int leadId;
  final bool isDark;
  const _TasksTab({required this.leadId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.task_alt, size: 48,
            color: isDark ? AppColors.darkTextFaint : Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('Tasks for this lead',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Tasks linked to this lead will appear here',
            style: GoogleFonts.inter(
                color: isDark ? AppColors.darkTextFaint : AppColors.lightTextFaint)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Add Task'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
        ),
      ]),
    );
  }
}

// ── More Actions Sheet ────────────────────────────────────────────────────────
class _MoreActionsSheet extends StatelessWidget {
  final LeadModel lead;
  final void Function(String) onAction;
  const _MoreActionsSheet({required this.lead, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(
        leading: const Icon(Icons.copy, color: Colors.blue),
        title: const Text('Copy Email'),
        onTap: () {
          Clipboard.setData(ClipboardData(text: lead.email));
          onAction('copy_email');
        },
      ),
      ListTile(
        leading: const Icon(Icons.swap_horiz, color: Colors.orange),
        title: const Text('Change Status'),
        onTap: () => onAction('status'),
      ),
      ListTile(
        leading: const Icon(Icons.person_add_outlined, color: Colors.green),
        title: const Text('Reassign Lead'),
        onTap: () => onAction('reassign'),
      ),
      ListTile(
        leading: const Icon(Icons.delete_outline, color: Colors.red),
        title: const Text('Delete Lead'),
        onTap: () => onAction('delete'),
      ),
    ]));
  }
}
