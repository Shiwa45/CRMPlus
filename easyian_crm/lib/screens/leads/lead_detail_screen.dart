import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lead_model.dart';
import '../../services/leads_service.dart';
import '../../widgets/app_loader.dart';
import 'lead_form_screen.dart';

class LeadDetailScreen extends StatefulWidget {
  final LeadModel lead;
  const LeadDetailScreen({super.key, required this.lead});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> with SingleTickerProviderStateMixin {
  late LeadModel _lead;
  List<LeadActivityModel> _activities = [];
  bool _loadingActivities = true;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _lead = widget.lead;
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadActivities();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() => _loadingActivities = true);
    try {
      final list = await LeadsService.instance.getLeadActivities(_lead.id);
      setState(() => _activities = list);
    } catch (_) {}
    setState(() => _loadingActivities = false);
  }

  Future<void> _deleteLead() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Lead'),
        content: Text('Are you sure you want to delete ${_lead.fullName}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await LeadsService.instance.deleteLead(_lead.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _addActivity() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddActivitySheet(
        leadId: _lead.id,
        onAdded: () { _loadActivities(); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(_lead.status);

    return Scaffold(
      appBar: AppBar(
        title: Text(_lead.fullName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              final result = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => LeadFormScreen(lead: _lead)));
              if (result == true && mounted) {
                // Reload
                try {
                  final updated = await LeadsService.instance.getLead(_lead.id);
                  setState(() => _lead = updated);
                } catch (_) {}
              }
            },
          ),
          PopupMenuButton(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'delete', child: Row(children: [
                Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                SizedBox(width: 8),
                Text('Delete Lead', style: TextStyle(color: AppColors.error)),
              ])),
            ],
            onSelected: (v) { if (v == 'delete') _deleteLead(); },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Activities'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addActivity,
        icon: const Icon(Icons.add),
        label: const Text('Add Activity'),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildDetails(isDark, statusColor),
          _buildActivities(isDark),
        ],
      ),
    );
  }

  Widget _buildDetails(bool isDark, Color statusColor) {
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status & priority header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor.withOpacity(0.2)),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: statusColor.withOpacity(0.15),
              child: Text(_lead.fullName.isNotEmpty ? _lead.fullName[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: statusColor)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_lead.fullName, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
              if (_lead.jobTitle != null) Text(_lead.jobTitle!,
                  style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
              if (_lead.company != null) Text(_lead.company!,
                  style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            ])),
            Column(children: [
              _statusBadge(_lead.status, statusColor),
              const SizedBox(height: 6),
              _priorityBadge(_lead.priority),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // Status change quick actions
        Text('Quick Status Update', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['new', 'contacted', 'qualified', 'proposal', 'negotiation', 'won', 'lost', 'on_hold']
                .map((s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(s.replaceAll('_', ' ').split(' ')
                        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' '),
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500)),
                    backgroundColor: _lead.status == s
                        ? _statusColor(s).withOpacity(0.15) : null,
                    side: _lead.status == s
                        ? BorderSide(color: _statusColor(s)) : null,
                    onPressed: () async {
                      try {
                        final updated = await LeadsService.instance.updateLead(_lead.id, {'status': s});
                        setState(() => _lead = updated);
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                      }
                    },
                  ),
                ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Contact Info
        _infoSection('Contact Information', [
          _infoRow(Icons.email_outlined, 'Email', _lead.email),
          if (_lead.phone != null) _infoRow(Icons.phone_outlined, 'Phone', _lead.phone!),
          if (_lead.company != null) _infoRow(Icons.business_outlined, 'Company', _lead.company!),
          if (_lead.jobTitle != null) _infoRow(Icons.work_outline_rounded, 'Job Title', _lead.jobTitle!),
        ], isDark),
        const SizedBox(height: 12),

        // Address
        if (_lead.address != null || _lead.city != null)
          _infoSection('Address', [
            if (_lead.address != null) _infoRow(Icons.location_on_outlined, 'Address', _lead.address!),
            if (_lead.city != null) _infoRow(Icons.location_city_outlined, 'City', _lead.city!),
            if (_lead.state != null) _infoRow(Icons.map_outlined, 'State', _lead.state!),
            _infoRow(Icons.flag_outlined, 'Country', _lead.country ?? 'India'),
            if (_lead.postalCode != null) _infoRow(Icons.pin_outlined, 'Postal Code', _lead.postalCode!),
          ], isDark),
        const SizedBox(height: 12),

        // Deal Info
        _infoSection('Deal Information', [
          if (_lead.budget != null)
            _infoRow(Icons.currency_rupee_rounded, 'Budget',
                currencyFmt.format(_lead.budget)),
          if (_lead.requirements != null && _lead.requirements!.isNotEmpty)
            _infoRow(Icons.list_alt_rounded, 'Requirements', _lead.requirements!),
          if (_lead.notes != null && _lead.notes!.isNotEmpty)
            _infoRow(Icons.notes_rounded, 'Notes', _lead.notes!),
        ], isDark),
        const SizedBox(height: 12),

        // Meta
        _infoSection('Lead Meta', [
          if (_lead.sourceName != null) _infoRow(Icons.source_rounded, 'Source', _lead.sourceName!),
          if (_lead.assignedToName != null) _infoRow(Icons.person_outline_rounded, 'Assigned To', _lead.assignedToName!),
          _infoRow(Icons.calendar_today_outlined, 'Created', _formatDate(_lead.createdAt)),
          if (_lead.lastContacted != null) _infoRow(Icons.access_time_rounded, 'Last Contacted', _formatDate(_lead.lastContacted!)),
        ], isDark),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildActivities(bool isDark) {
    if (_loadingActivities) return const Center(child: AppLoader());
    if (_activities.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.history_toggle_off_rounded, size: 56, color: Colors.grey.withOpacity(0.3)),
        const SizedBox(height: 12),
        Text('No activities yet', style: GoogleFonts.inter(fontSize: 15, color: Colors.grey)),
        const SizedBox(height: 8),
        Text('Tap "Add Activity" to log a call, email, or meeting',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      itemBuilder: (_, i) => _ActivityTile(activity: _activities[i], isDark: isDark),
    );
  }

  Widget _infoSection(String title, List<Widget> rows, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
        const SizedBox(width: 10),
        SizedBox(width: 90, child: Text(label, style: GoogleFonts.inter(fontSize: 12,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted))),
        Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _statusBadge(String status, Color color) {
    final label = status.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text('${label[0].toUpperCase()}${label.substring(1)}',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _priorityBadge(String priority) {
    final color = priority == 'hot' ? AppColors.priorityHot
        : priority == 'warm' ? AppColors.priorityWarm : AppColors.priorityCold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text('${priority[0].toUpperCase()}${priority.substring(1)}',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'new': return AppColors.statusNew;
      case 'contacted': return AppColors.statusContacted;
      case 'qualified': return AppColors.statusQualified;
      case 'proposal': return AppColors.statusProposal;
      case 'won': return AppColors.statusWon;
      case 'lost': return AppColors.statusLost;
      case 'on_hold': return AppColors.statusOnHold;
      default: return AppColors.statusNew;
    }
  }

  String _formatDate(String dt) {
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(dt).toLocal());
    } catch (_) { return dt; }
  }
}

class _ActivityTile extends StatelessWidget {
  final LeadActivityModel activity;
  final bool isDark;
  const _ActivityTile({required this.activity, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = _activityColor(activity.activityType);
    final icon = _activityIcon(activity.activityType);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(activity.subject, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          if (activity.description != null && activity.description!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(activity.description!, style: GoogleFonts.inter(fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          ],
          const SizedBox(height: 4),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(activity.activityType.replaceAll('_', ' '),
                  style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 8),
            Text(_formatDate(activity.createdAt),
                style: GoogleFonts.inter(fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          ]),
        ])),
      ]),
    );
  }

  Color _activityColor(String type) {
    switch (type) {
      case 'call': return AppColors.success;
      case 'email': return AppColors.info;
      case 'meeting': return AppColors.accent;
      case 'note': return AppColors.warning;
      default: return AppColors.primary;
    }
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'call': return Icons.phone_rounded;
      case 'email': return Icons.email_rounded;
      case 'meeting': return Icons.groups_rounded;
      case 'note': return Icons.note_rounded;
      case 'status_change': return Icons.swap_horiz_rounded;
      case 'assignment': return Icons.assignment_ind_rounded;
      default: return Icons.circle_rounded;
    }
  }

  String _formatDate(String dt) {
    try {
      return DateFormat('dd MMM, hh:mm a').format(DateTime.parse(dt).toLocal());
    } catch (_) { return dt; }
  }
}

class _AddActivitySheet extends StatefulWidget {
  final int leadId;
  final VoidCallback onAdded;
  const _AddActivitySheet({required this.leadId, required this.onAdded});

  @override
  State<_AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends State<_AddActivitySheet> {
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'call';
  bool _saving = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_subjectCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await LeadsService.instance.addActivity({
        'lead': widget.leadId,
        'activity_type': _type,
        'subject': _subjectCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
      });
      widget.onAdded();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Add Activity', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Text('Type', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: ['call', 'email', 'meeting', 'note'].map((t) =>
          ChoiceChip(label: Text(t), selected: _type == t, onSelected: (_) => setState(() => _type = t))
        ).toList()),
        const SizedBox(height: 14),
        TextField(
          controller: _subjectCtrl,
          decoration: const InputDecoration(labelText: 'Subject *', hintText: 'e.g. Called to follow up'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Description', hintText: 'Optional details...'),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const AppLoader(color: Colors.white, size: 20) : const Text('Save Activity'),
          ),
        ),
      ]),
    );
  }
}
