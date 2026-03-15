// lib/screens/tickets/tickets_screen.dart
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/desktop_widgets.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});
  @override State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  List<TicketModel> _tickets = [];
  List<TicketCategoryModel> _categories = [];
  bool _loading = true;
  int _total = 0, _page = 1;
  static const _pageSize = 50;
  String? _filterStatus, _filterPriority;
  int? _filterCategory;
  bool _myTickets = false;

  TicketModel? _detail;
  bool _showForm = false;

  @override
  void initState() { super.initState(); _loadInit(); }

  Future<void> _loadInit() async {
    final cats = await TicketsService.instance.getCategories().catchError((_) => <TicketCategoryModel>[]);
    setState(() => _categories = cats);
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) setState(() => _page = 1);
    setState(() => _loading = true);
    try {
      final r = await TicketsService.instance.getTickets(
        page: _page, status: _filterStatus, priority: _filterPriority, myTickets: _myTickets ? true : null);
      setState(() { _tickets = r['results'] as List<TicketModel>; _total = r['count'] as int; });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _refreshDetail(int id) async {
    try {
      final t = await TicketsService.instance.getTicket(id);
      setState(() => _detail = t);
    } catch (_) {}
  }

  Color _statusColor(String s) => switch (s) {
    'open'     => AppColors.info,
    'pending'  => AppColors.warning,
    'resolved' => AppColors.success,
    'closed'   => AppColors.lightTextMuted,
    _          => AppColors.primary,
  };

  Color _priorityColor(String p) => switch (p) {
    'critical' || 'high' => AppColors.error,
    'medium'             => AppColors.warning,
    _                    => AppColors.info,
  };

  Widget _badge(String l, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
    child: Text(l, style: GoogleFonts.inter(fontSize: 11, color: c, fontWeight: FontWeight.w600)));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      Expanded(child: Column(children: [
        PageHeader(
          title: 'Tickets', subtitle: '$_total tickets',
          actions: [
            CrmButton(label: 'New Ticket', icon: Icons.add_rounded, primary: true,
                onPressed: () => setState(() { _showForm = true; _detail = null; })),
          ],
        ),
        TableToolbar(
          searchCtrl: null, searchHint: '',
          filters: [
            FilterDropdown<String?>(value: _filterStatus, hint: 'All Status',
              items: const [
                DropdownMenuItem(value: null,       child: Text('All Status')),
                DropdownMenuItem(value: 'open',     child: Text('Open')),
                DropdownMenuItem(value: 'pending',  child: Text('Pending')),
                DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                DropdownMenuItem(value: 'closed',   child: Text('Closed')),
              ],
              onChanged: (v) { setState(() => _filterStatus = v); _load(reset: true); }),
            const SizedBox(width: 8),
            FilterDropdown<String?>(value: _filterPriority, hint: 'All Priority',
              items: const [
                DropdownMenuItem(value: null,       child: Text('All Priority')),
                DropdownMenuItem(value: 'critical', child: Text('Critical')),
                DropdownMenuItem(value: 'high',     child: Text('High')),
                DropdownMenuItem(value: 'medium',   child: Text('Medium')),
                DropdownMenuItem(value: 'low',      child: Text('Low')),
              ],
              onChanged: (v) { setState(() => _filterPriority = v); _load(reset: true); }),
            const SizedBox(width: 8),
            _ToggleChip(label: 'My Tickets', active: _myTickets,
                onTap: () { setState(() => _myTickets = !_myTickets); _load(reset: true); }),
          ],
          actions: [Text('$_total total', style: GoogleFonts.inter(fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted))],
        ),
        Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        Expanded(
          child: _loading && _tickets.isEmpty ? const TableShimmer(rows: 10)
              : _tickets.isEmpty ? EmptyState(icon: Icons.support_agent_outlined,
                  title: 'No tickets', subtitle: 'All clear! No support tickets yet.',
                  actionLabel: 'New Ticket', onAction: () => setState(() { _showForm = true; _detail = null; }))
              : DataTable2(
                  columnSpacing: 12, horizontalMargin: 16, minWidth: 860,
                  headingRowHeight: 40, dataRowHeight: 52,
                  headingTextStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  columns: const [
                    DataColumn2(label: Text('#'), size: ColumnSize.S),
                    DataColumn2(label: Text('Subject'), size: ColumnSize.L),
                    DataColumn2(label: Text('Contact'), size: ColumnSize.M),
                    DataColumn2(label: Text('Category'), size: ColumnSize.M),
                    DataColumn2(label: Text('Priority'), size: ColumnSize.S),
                    DataColumn2(label: Text('Status'), size: ColumnSize.S),
                    DataColumn2(label: Text('SLA'), size: ColumnSize.S),
                  ],
                  rows: _tickets.map((t) => DataRow2(
                    onTap: () async {
                      final full = await TicketsService.instance.getTicket(t.id).catchError((_) => t);
                      setState(() { _detail = full; _showForm = false; });
                    },
                    selected: _detail?.id == t.id,
                    color: t.slaBreached || t.isOverdue
                        ? MaterialStateProperty.all(AppColors.error.withOpacity(0.04))
                        : null,
                    cells: [
                      DataCell(Text(t.ticketNumber, style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600))),
                      DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, children: [
                        Text(t.subject, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkText : AppColors.lightText),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (t.assignedToName != null)
                          Text('Assigned: ${t.assignedToName}', style: GoogleFonts.inter(fontSize: 11,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                      ])),
                      DataCell(Text(t.contactName ?? t.companyName ?? '—', style: GoogleFonts.inter(fontSize: 12))),
                      DataCell(t.categoryName != null
                          ? Row(children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(
                                  color: (() { try { return Color(int.parse((t.categoryColor ?? '#6366f1').replaceAll('#','0xFF'))); } catch (_) { return AppColors.primary; } })(),
                                  shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text(t.categoryName!, style: GoogleFonts.inter(fontSize: 12)),
                            ])
                          : Text('—', style: GoogleFonts.inter(fontSize: 12))),
                      DataCell(_badge(t.priority.toUpperCase(), _priorityColor(t.priority))),
                      DataCell(_badge(t.status.toUpperCase(), _statusColor(t.status))),
                      DataCell(t.slaBreached
                          ? Row(children: [
                              const Icon(Icons.warning_rounded, size: 14, color: AppColors.error),
                              const SizedBox(width: 4),
                              Text('BREACH', style: GoogleFonts.inter(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w700)),
                            ])
                          : Text('OK', style: GoogleFonts.inter(fontSize: 11, color: AppColors.success))),
                    ],
                  )).toList()),
        ),
        if (_total > _pageSize)
          _Pager(page: _page, total: _total, pageSize: _pageSize,
              onPrev: () { setState(() => _page--); _load(); },
              onNext: () { setState(() => _page++); _load(); }),
      ])),

      if (_detail != null && !_showForm)
        SidePanel(title: '#${_detail!.ticketNumber}', width: 440,
          onClose: () => setState(() => _detail = null),
          actions: [
            if (_detail!.status == 'open' || _detail!.status == 'pending')
              IconButton(icon: const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                  padding: EdgeInsets.zero, tooltip: 'Resolve',
                  onPressed: () async {
                    await TicketsService.instance.resolve(_detail!.id).catchError((_) {});
                    _refreshDetail(_detail!.id); _load();
                  }),
            if (_detail!.status == 'resolved' || _detail!.status == 'closed')
              IconButton(icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.info),
                  padding: EdgeInsets.zero, tooltip: 'Reopen',
                  onPressed: () async {
                    await TicketsService.instance.reopen(_detail!.id).catchError((_) {});
                    _refreshDetail(_detail!.id); _load();
                  }),
          ],
          child: _TicketDetailPanel(
            ticket: _detail!,
            isDark: isDark,
            onReply: (body, isPublic) async {
              await TicketsService.instance.addReply(_detail!.id, {'body': body, 'is_public': isPublic});
              _refreshDetail(_detail!.id);
            },
          )),

      if (_showForm)
        SidePanel(title: 'New Ticket', width: 460,
          onClose: () => setState(() => _showForm = false),
          child: _TicketForm(key: const ValueKey('new'), categories: _categories,
              onSaved: () { setState(() => _showForm = false); _load(); })),
    ]);
  }
}

// ── Ticket detail panel ───────────────────────────────────────────────────────
class _TicketDetailPanel extends StatefulWidget {
  final TicketModel ticket;
  final bool isDark;
  final Future<void> Function(String body, bool isPublic) onReply;
  const _TicketDetailPanel({required this.ticket, required this.isDark, required this.onReply});
  @override State<_TicketDetailPanel> createState() => _TicketDetailPanelState();
}

class _TicketDetailPanelState extends State<_TicketDetailPanel> {
  final _replyCtrl = TextEditingController();
  bool _isPublic = true, _sending = false;

  @override
  void dispose() { _replyCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    await widget.onReply(_replyCtrl.text.trim(), _isPublic);
    _replyCtrl.clear();
    setState(() => _sending = false);
  }

  Color _statusColor(String s) => switch (s) {
    'open' => AppColors.info, 'pending' => AppColors.warning,
    'resolved' => AppColors.success, _ => AppColors.lightTextMuted,
  };

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    final isDark = widget.isDark;
    return Column(children: [
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Meta
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _statusColor(t.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(t.status.toUpperCase(), style: GoogleFonts.inter(fontSize: 11,
                  color: _statusColor(t.status), fontWeight: FontWeight.w700))),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(t.priority.toUpperCase(), style: GoogleFonts.inter(fontSize: 11,
                  color: AppColors.warning, fontWeight: FontWeight.w700))),
            if (t.slaBreached) ...[
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text('SLA BREACHED', style: GoogleFonts.inter(fontSize: 11,
                    color: AppColors.error, fontWeight: FontWeight.w700))),
            ],
          ]),
          const SizedBox(height: 12),
          Text(t.subject, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText)),
          const SizedBox(height: 8),
          if (t.contactName != null)
            _meta(Icons.person_rounded, t.contactName!, isDark),
          if (t.categoryName != null)
            _meta(Icons.label_rounded, t.categoryName!, isDark),
          if (t.resolutionDue != null)
            _meta(Icons.timer_rounded, 'Due: ${t.resolutionDue!.length > 16 ? t.resolutionDue!.substring(0,16) : t.resolutionDue!}', isDark),
          const SizedBox(height: 16),
          Text('CONVERSATION', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
              letterSpacing: 0.8, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          const SizedBox(height: 8),
          // Replies
          ...t.replies.map((r) => _ReplyBubble(reply: r, isDark: isDark)),
          if (t.replies.isEmpty)
            Text('No replies yet', style: GoogleFonts.inter(fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
        ]),
      )),

      // Reply box
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder))),
        child: Column(children: [
          Row(children: [
            Text('Public', style: GoogleFonts.inter(fontSize: 12)),
            const SizedBox(width: 6),
            Switch(value: _isPublic, onChanged: (v) => setState(() => _isPublic = v),
                activeColor: AppColors.primary, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
            const SizedBox(width: 6),
            Text(_isPublic ? 'Visible to customer' : 'Internal note',
                style: GoogleFonts.inter(fontSize: 11,
                    color: _isPublic ? AppColors.primary : AppColors.warning)),
          ]),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: TextField(
              controller: _replyCtrl, maxLines: 3,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(hintText: 'Type your reply...', isDense: true,
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
            )),
            const SizedBox(width: 8),
            CrmButton(label: 'Send', icon: Icons.send_rounded, primary: true,
                loading: _sending, onPressed: _send),
          ]),
        ]),
      ),
    ]);
  }

  Widget _meta(IconData icon, String val, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Icon(icon, size: 13, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
      const SizedBox(width: 6),
      Text(val, style: GoogleFonts.inter(fontSize: 12,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
    ]));
}

class _ReplyBubble extends StatelessWidget {
  final TicketReplyModel reply; final bool isDark;
  const _ReplyBubble({required this.reply, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: reply.isPublic
          ? (isDark ? AppColors.darkSurface2 : AppColors.lightSurface2)
          : AppColors.warning.withOpacity(0.07),
      border: Border.all(color: reply.isPublic
          ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
          : AppColors.warning.withOpacity(0.3)),
      borderRadius: BorderRadius.circular(8)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(reply.authorName ?? 'Staff', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkText : AppColors.lightText)),
        const SizedBox(width: 6),
        if (!reply.isPublic)
          Text('(Internal)', style: GoogleFonts.inter(fontSize: 10, color: AppColors.warning)),
        const Spacer(),
        Text(reply.createdAt.length > 10 ? reply.createdAt.substring(0,10) : reply.createdAt,
            style: GoogleFonts.inter(fontSize: 10, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
      ]),
      const SizedBox(height: 4),
      Text(reply.body, style: GoogleFonts.inter(fontSize: 13,
          color: isDark ? AppColors.darkText : AppColors.lightText)),
    ]));
}

// ── New Ticket Form ───────────────────────────────────────────────────────────
class _TicketForm extends StatefulWidget {
  final List<TicketCategoryModel> categories; final VoidCallback onSaved;
  const _TicketForm({super.key, required this.categories, required this.onSaved});
  @override State<_TicketForm> createState() => _TicketFormState();
}

class _TicketFormState extends State<_TicketForm> {
  final _subject = TextEditingController(), _desc = TextEditingController();
  String _priority = 'medium'; int? _categoryId; bool _saving = false;

  @override
  void dispose() { _subject.dispose(); _desc.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_subject.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject is required'))); return; }
    setState(() => _saving = true);
    try {
      await TicketsService.instance.createTicket({
        'subject': _subject.text.trim(),
        'description': _desc.text.trim(),
        'priority': _priority,
        if (_categoryId != null) 'category': _categoryId,
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
      _fld('Subject *', _subject, isDark), const SizedBox(height: 12),
      _fld('Description', _desc, isDark, maxLines: 5), const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: _priority,
        decoration: InputDecoration(labelText: 'Priority', isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
        items: const [
          DropdownMenuItem(value: 'low',      child: Text('Low')),
          DropdownMenuItem(value: 'medium',   child: Text('Medium')),
          DropdownMenuItem(value: 'high',     child: Text('High')),
          DropdownMenuItem(value: 'critical', child: Text('Critical')),
        ],
        onChanged: (v) => setState(() => _priority = v ?? 'medium'),
        style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText)),
      const SizedBox(height: 12),
      if (widget.categories.isNotEmpty) ...[
        DropdownButtonFormField<int?>(value: _categoryId,
          decoration: InputDecoration(labelText: 'Category', isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
          items: [const DropdownMenuItem(value: null, child: Text('No category')),
            ...widget.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))],
          onChanged: (v) => setState(() => _categoryId = v),
          style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText)),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 12),
      SizedBox(width: double.infinity,
        child: CrmButton(label: 'Create Ticket', primary: true, loading: _saving, onPressed: _save)),
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

class _ToggleChip extends StatelessWidget {
  final String label; final bool active; final VoidCallback onTap;
  const _ToggleChip({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.transparent,
        border: Border.all(color: active ? AppColors.primary : AppColors.lightBorder),
        borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
          color: active ? Colors.white : AppColors.lightTextSecondary))));
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
