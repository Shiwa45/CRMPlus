import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/num_utils.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/desktop_widgets.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});
  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  List<LeadModel> _leads = [];
  List<LeadSourceModel> _sources = [];
  bool _loading = true;
  int _total = 0;
  int _page = 1;
  static const _pageSize = 50;

  // Filters
  final _searchCtrl = TextEditingController();
  String? _filterStatus, _filterPriority;
  int? _filterSource;
  String _ordering = '-created_at';

  // Selection
  final Set<int> _selected = {};

  // Sort
  int _sortCol = 0;
  bool _sortAsc = false;

  // Detail panel
  LeadModel? _detailLead;
  bool _showForm = false;
  LeadModel? _editLead;

  // Filter sidebar
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadSources();
    _searchCtrl.addListener(() {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _load(reset: true);
      });
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load({bool reset = false}) async {
    if (reset) setState(() { _page = 1; _leads = []; });
    setState(() => _loading = true);
    try {
      final r = await LeadsService.instance.getLeads(
        page: _page, pageSize: _pageSize,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        status: _filterStatus, priority: _filterPriority,
        sourceId: _filterSource, ordering: _ordering,
      );
      setState(() {
        _leads = r['results'] as List<LeadModel>;
        _total = toInt(r['count']);
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _loadSources() async {
    final s = await LeadsService.instance.getLeadSources();
    setState(() => _sources = s);
  }

  void _onSort(int col, bool asc) {
    final fields = ['first_name', 'company', 'status', 'priority', 'created_at'];
    setState(() {
      _sortCol = col; _sortAsc = asc;
      _ordering = '${asc ? '' : '-'}${fields[col]}';
    });
    _load(reset: true);
  }

  Future<void> _bulkDelete() async {
    final confirmed = await _confirm('Delete ${_selected.length} leads?',
        'This cannot be undone.');
    if (!confirmed) return;
    await LeadsService.instance.bulkDelete(_selected.toList());
    _selected.clear();
    _load(reset: true);
  }

  Future<bool> _confirm(String title, String msg) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(children: [
      PageHeader(
        title: 'Leads',
        subtitle: '$_total total leads',
        actions: [
          CrmButton(
            label: 'Filters',
            icon: Icons.filter_list_rounded,
            onPressed: () => setState(() => _showFilters = !_showFilters),
            primary: _showFilters,
          ),
          const SizedBox(width: 8),
          CrmButton(
            label: 'Add Lead',
            icon: Icons.add_rounded,
            primary: true,
            onPressed: () => setState(() { _editLead = null; _showForm = true; _detailLead = null; }),
          ),
        ],
      ),

      Expanded(
        child: Row(children: [
          // ── Filter sidebar ──────────────────────────────────────────────
          if (_showFilters)
            _FilterPanel(
              status: _filterStatus,
              priority: _filterPriority,
              sourceId: _filterSource,
              sources: _sources,
              onApply: (s, p, src) {
                setState(() { _filterStatus = s; _filterPriority = p; _filterSource = src; });
                _load(reset: true);
              },
              onClear: () {
                setState(() { _filterStatus = null; _filterPriority = null; _filterSource = null; });
                _load(reset: true);
              },
            ),

          // ── Main table area ─────────────────────────────────────────────
          Expanded(
            child: Column(children: [
              // Toolbar
              TableToolbar(
                searchCtrl: _searchCtrl,
                searchHint: 'Search leads by name, email, company...',
                selectedCount: _selected.length,
                bulkActions: [
                  CrmButton(label: 'Delete', icon: Icons.delete_outline_rounded,
                      danger: true, onPressed: _bulkDelete),
                  CrmButton(label: 'Export', icon: Icons.download_rounded,
                      onPressed: () {}),
                ],
                actions: [
                  Text('$_total leads',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                  const SizedBox(width: 12),
                  // Pagination
                  _PaginationBar(
                    page: _page, total: _total, pageSize: _pageSize,
                    onPrev: _page > 1 ? () { setState(() => _page--); _load(); } : null,
                    onNext: _page * _pageSize < _total ? () { setState(() => _page++); _load(); } : null,
                  ),
                ],
              ),
              Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),

              // Data Table
              Expanded(
                child: _loading && _leads.isEmpty
                    ? const TableShimmer(rows: 12)
                    : _leads.isEmpty
                        ? const EmptyState(
                            icon: Icons.people_outline_rounded,
                            title: 'No leads found',
                            subtitle: 'Try adjusting your filters or add a new lead.',
                          )
                        : _buildTable(isDark),
              ),
            ]),
          ),

          // ── Detail / Form panel ─────────────────────────────────────────
          if (_showForm)
            SidePanel(
              title: _editLead != null ? 'Edit Lead' : 'New Lead',
              width: 480,
              onClose: () => setState(() => _showForm = false),
              child: _LeadFormPane(
                key: ValueKey(_editLead?.id ?? 'new'),
                lead: _editLead,
                sources: _sources,
                onSaved: (lead) {
                  setState(() => _showForm = false);
                  _load(reset: true);
                },
              ),
            )
          else if (_detailLead != null)
            SidePanel(
              title: 'Lead Details',
              width: 420,
              onClose: () => setState(() => _detailLead = null),
              actions: [
                CrmButton(
                  label: 'Edit', icon: Icons.edit_rounded,
                  onPressed: () => setState(() {
                    _editLead = _detailLead; _showForm = true; _detailLead = null;
                  }),
                ),
              ],
              child: _LeadDetailPane(lead: _detailLead!),
            ),
        ]),
      ),
    ]);
  }

  Widget _buildTable(bool isDark) {
    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 16,
      minWidth: 900,
      headingRowHeight: 40,
      dataRowHeight: 46,
      headingRowColor: MaterialStateProperty.all(
          isDark ? AppColors.darkSurface2 : AppColors.lightSurface2),
      sortColumnIndex: _sortCol,
      sortAscending: _sortAsc,
      onSelectAll: (v) => setState(() {
        if (v == true) { _selected.addAll(_leads.map((l) => l.id)); }
        else { _selected.clear(); }
      }),
      columns: [
        DataColumn2(label: _hdr('Name', isDark), size: ColumnSize.L, onSort: _onSort),
        DataColumn2(label: _hdr('Company', isDark), onSort: _onSort),
        DataColumn2(label: _hdr('Status', isDark), onSort: _onSort),
        DataColumn2(label: _hdr('Priority', isDark), onSort: _onSort),
        DataColumn2(label: _hdr('Assigned To', isDark)),
        DataColumn2(label: _hdr('Created', isDark), onSort: _onSort),
        DataColumn2(label: _hdr('', isDark), fixedWidth: 80),
      ],
      rows: _leads.map((lead) {
        final sel = _selected.contains(lead.id);
        return DataRow2(
          selected: sel,
          onSelectChanged: (v) => setState(() {
            if (v == true) _selected.add(lead.id);
            else _selected.remove(lead.id);
          }),
          onTap: () => setState(() {
            _detailLead = lead; _showForm = false;
          }),
          color: MaterialStateProperty.resolveWith((s) {
            if (s.contains(MaterialState.selected))
              return AppColors.primary.withOpacity(0.06);
            if (s.contains(MaterialState.hovered))
              return (isDark ? AppColors.darkSurface2 : AppColors.lightSurface2);
            return null;
          }),
          cells: [
            DataCell(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(lead.fullName,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkText : AppColors.lightText)),
                Text(lead.email,
                    style: GoogleFonts.inter(fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    overflow: TextOverflow.ellipsis),
              ],
            )),
            DataCell(Text(lead.company ?? '—',
                style: GoogleFonts.inter(fontSize: 12,
                    color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub),
                overflow: TextOverflow.ellipsis)),
            DataCell(StatusBadge(status: lead.status)),
            DataCell(PriorityBadge(priority: lead.priority)),
            DataCell(Text(lead.assignedToName ?? '—',
                style: GoogleFonts.inter(fontSize: 12,
                    color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub))),
            DataCell(Text(_fmtDate(lead.createdAt),
                style: GoogleFonts.inter(fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted))),
            DataCell(Row(children: [
              _iconBtn(Icons.edit_outlined, () => setState(() {
                _editLead = lead; _showForm = true; _detailLead = null;
              }), isDark),
              const SizedBox(width: 4),
              _iconBtn(Icons.delete_outline_rounded, () async {
                final ok = await _confirm('Delete ${lead.fullName}?', 'This cannot be undone.');
                if (ok) { await LeadsService.instance.deleteLead(lead.id); _load(reset: true); }
              }, isDark, danger: true),
            ])),
          ],
        );
      }).toList(),
    );
  }

  Widget _hdr(String t, bool isDark) => Text(t,
      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted));

  Widget _iconBtn(IconData icon, VoidCallback onTap, bool isDark, {bool danger = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16,
            color: danger ? AppColors.error
                : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
      ),
    );
  }

  String _fmtDate(String dt) {
    try { return DateFormat('dd MMM yy').format(DateTime.parse(dt).toLocal()); }
    catch (_) { return dt; }
  }
}

// ─── Filter Panel (left sidebar) ─────────────────────────────────────────────
class _FilterPanel extends StatefulWidget {
  final String? status, priority;
  final int? sourceId;
  final List<LeadSourceModel> sources;
  final void Function(String?, String?, int?) onApply;
  final VoidCallback onClear;

  const _FilterPanel({this.status, this.priority, this.sourceId,
    required this.sources, required this.onApply, required this.onClear});

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  String? _status, _priority;
  int? _sourceId;

  @override
  void initState() {
    super.initState();
    _status = widget.status; _priority = widget.priority; _sourceId = widget.sourceId;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Text('Filters', style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.lightText)),
            const Spacer(),
            GestureDetector(
              onTap: () {
                setState(() { _status = null; _priority = null; _sourceId = null; });
                widget.onClear();
              },
              child: Text('Clear', style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.primary)),
            ),
          ]),
        ),
        Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _filterSection('Status', [
                for (final s in ['new','contacted','qualified','proposal',
                    'negotiation','won','lost','on_hold'])
                  _filterChip(s.replaceAll('_', ' '), _status == s, () {
                    setState(() => _status = _status == s ? null : s);
                  }, isDark),
              ]),
              const SizedBox(height: 12),
              _filterSection('Priority', [
                _filterChip('Hot', _priority == 'hot', () {
                  setState(() => _priority = _priority == 'hot' ? null : 'hot');
                }, isDark, color: AppColors.hot),
                _filterChip('Warm', _priority == 'warm', () {
                  setState(() => _priority = _priority == 'warm' ? null : 'warm');
                }, isDark, color: AppColors.warm),
                _filterChip('Cold', _priority == 'cold', () {
                  setState(() => _priority = _priority == 'cold' ? null : 'cold');
                }, isDark, color: AppColors.cold),
              ]),
              if (widget.sources.isNotEmpty) ...[
                const SizedBox(height: 12),
                _filterSection('Source', [
                  for (final src in widget.sources)
                    _filterChip(src.name, _sourceId == src.id, () {
                      setState(() => _sourceId = _sourceId == src.id ? null : src.id);
                    }, isDark),
                ]),
              ],
            ]),
          ),
        ),
        Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: CrmButton(
              label: 'Apply Filters', primary: true,
              onPressed: () => widget.onApply(_status, _priority, _sourceId),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _filterSection(String title, List<Widget> chips) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title.toUpperCase(), style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          letterSpacing: 0.8)),
      const SizedBox(height: 6),
      Wrap(spacing: 4, runSpacing: 4, children: chips),
    ]);
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap,
      bool isDark, {Color? color}) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? c.withOpacity(0.5)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(label.split(' ').map((w) =>
            w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w).join(' '),
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? c
                    : (isDark ? AppColors.darkTextSub : AppColors.lightTextSub))),
      ),
    );
  }
}

// ─── Pagination Bar ────────────────────────────────────────────────────────────
class _PaginationBar extends StatelessWidget {
  final int page, total, pageSize;
  final VoidCallback? onPrev, onNext;
  const _PaginationBar({required this.page, required this.total,
    required this.pageSize, this.onPrev, this.onNext});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final start = (page - 1) * pageSize + 1;
    final end   = (page * pageSize).clamp(0, total);
    return Row(children: [
      Text('$start–$end of $total', style: GoogleFonts.inter(fontSize: 12,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
      const SizedBox(width: 8),
      _btn(Icons.chevron_left_rounded, onPrev, isDark),
      const SizedBox(width: 2),
      _btn(Icons.chevron_right_rounded, onNext, isDark),
    ]);
  }

  Widget _btn(IconData icon, VoidCallback? onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16,
            color: onTap == null
                ? (isDark ? AppColors.darkTextFaint : AppColors.lightTextFaint)
                : (isDark ? AppColors.darkTextSub : AppColors.lightTextSub)),
      ),
    );
  }
}

// ─── Lead Detail Pane ─────────────────────────────────────────────────────────
class _LeadDetailPane extends StatefulWidget {
  final LeadModel lead;
  const _LeadDetailPane({required this.lead});
  @override
  State<_LeadDetailPane> createState() => _LeadDetailPaneState();
}

class _LeadDetailPaneState extends State<_LeadDetailPane> {
  List<LeadActivityModel> _activities = [];
  bool _loadingAct = true;
  final _actSubjectCtrl = TextEditingController();
  String _actType = 'call';
  bool _savingAct = false;

  @override
  void initState() { super.initState(); _loadActivities(); }

  @override
  void dispose() { _actSubjectCtrl.dispose(); super.dispose(); }

  Future<void> _loadActivities() async {
    setState(() => _loadingAct = true);
    final acts = await LeadsService.instance.getActivities(widget.lead.id);
    setState(() { _activities = acts; _loadingAct = false; });
  }

  Future<void> _logActivity() async {
    if (_actSubjectCtrl.text.trim().isEmpty) return;
    setState(() => _savingAct = true);
    await LeadsService.instance.createActivity({
      'lead': widget.lead.id, 'activity_type': _actType,
      'subject': _actSubjectCtrl.text.trim(),
    });
    _actSubjectCtrl.clear();
    _loadActivities();
    setState(() => _savingAct = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = widget.lead;
    final curr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Avatar + name block
        Row(children: [
          CircleAvatar(
            radius: 22, backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text(l.fullName.isNotEmpty ? l.fullName[0].toUpperCase() : '?',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.fullName, style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText)),
            if (l.jobTitle != null || l.company != null)
              Text('${l.jobTitle ?? ''}${l.jobTitle != null && l.company != null ? ' · ' : ''}${l.company ?? ''}',
                  style: GoogleFonts.inter(fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          ])),
        ]),
        const SizedBox(height: 12),

        Row(children: [
          StatusBadge(status: l.status),
          const SizedBox(width: 6),
          PriorityBadge(priority: l.priority),
        ]),
        const SizedBox(height: 16),

        // Quick status change
        Text('Change Status', style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
        const SizedBox(height: 6),
        Wrap(spacing: 4, runSpacing: 4,
          children: ['new','contacted','qualified','proposal','negotiation','won','lost','on_hold']
              .map((s) => GestureDetector(
                onTap: () async {
                  await LeadsService.instance.updateLead(l.id, {'status': s});
                  if (mounted) setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: l.status == s ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
                    border: Border.all(color: l.status == s
                        ? AppColors.primary.withOpacity(0.4)
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(s.replaceAll('_', ' '),
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: l.status == s ? FontWeight.w600 : FontWeight.w400,
                          color: l.status == s ? AppColors.primary
                              : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted))),
                ),
              )).toList(),
        ),
        const SizedBox(height: 16),
        Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        const SizedBox(height: 8),

        // Contact info
        _section('Contact', [
          _row(Icons.email_outlined, 'Email', l.email, isDark),
          if (l.phone != null) _row(Icons.phone_outlined, 'Phone', l.phone!, isDark),
          if (l.company != null) _row(Icons.business_outlined, 'Company', l.company!, isDark),
          if (l.city != null || l.country != null)
            _row(Icons.location_on_outlined, 'Location',
                [l.city, l.state, l.country].where((e) => e != null).join(', '), isDark),
        ], isDark),
        const SizedBox(height: 12),

        _section('Deal', [
          if (l.budget != null) _row(Icons.currency_rupee_rounded, 'Budget', curr.format(l.budget), isDark),
          if (l.sourceName != null) _row(Icons.source_rounded, 'Source', l.sourceName!, isDark),
          if (l.assignedToName != null) _row(Icons.person_outlined, 'Assigned', l.assignedToName!, isDark),
          _row(Icons.calendar_today_outlined, 'Created', _fmtDate(l.createdAt), isDark),
        ], isDark),

        if (l.notes != null && l.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _section('Notes', [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(l.notes!, style: GoogleFonts.inter(fontSize: 12,
                  color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)),
            ),
          ], isDark),
        ],

        const SizedBox(height: 16),
        Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        const SizedBox(height: 8),

        // Log activity
        Text('Log Activity', style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkText : AppColors.lightText)),
        const SizedBox(height: 8),
        Row(children: [
          for (final t in ['call','email','meeting','note'])
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => setState(() => _actType = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _actType == t ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _actType == t ? AppColors.primary
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                  ),
                  child: Text(t, style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _actType == t ? Colors.white
                          : (isDark ? AppColors.darkTextSub : AppColors.lightTextSub))),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: SizedBox(
              height: 34,
              child: TextField(
                controller: _actSubjectCtrl,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: const InputDecoration(hintText: 'Add a note or log...'),
                onSubmitted: (_) => _logActivity(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          CrmButton(
            label: 'Log', primary: true, loading: _savingAct,
            onPressed: _logActivity,
          ),
        ]),
        const SizedBox(height: 16),

        // Activity feed
        Text('Activity', style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkText : AppColors.lightText)),
        const SizedBox(height: 8),
        if (_loadingAct)
          const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(strokeWidth: 2),
          ))
        else if (_activities.isEmpty)
          Text('No activities yet',
              style: GoogleFonts.inter(fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted))
        else
          ...(_activities.map((a) => _activityTile(a, isDark))),
      ]),
    );
  }

  Widget _activityTile(LeadActivityModel a, bool isDark) {
    final color = switch (a.activityType) {
      'call'    => AppColors.success,
      'email'   => AppColors.primary,
      'meeting' => AppColors.accent,
      _         => AppColors.warning,
    };
    final icon = switch (a.activityType) {
      'call'    => Icons.phone_rounded,
      'email'   => Icons.email_rounded,
      'meeting' => Icons.groups_rounded,
      _         => Icons.note_rounded,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.subject, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkText : AppColors.lightText)),
          Text(_fmtDate(a.createdAt), style: GoogleFonts.inter(fontSize: 10,
              color: isDark ? AppColors.darkTextFaint : AppColors.lightTextFaint)),
        ])),
      ]),
    );
  }

  Widget _section(String title, List<Widget> children, bool isDark) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title.toUpperCase(), style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
      const SizedBox(height: 8),
      ...children,
    ],
  );

  Widget _row(IconData icon, String label, String value, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(icon, size: 14, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
      const SizedBox(width: 8),
      SizedBox(width: 68, child: Text(label, style: GoogleFonts.inter(
          fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted))),
      Expanded(child: Text(value, style: GoogleFonts.inter(
          fontSize: 12, color: isDark ? AppColors.darkText : AppColors.lightText),
          overflow: TextOverflow.ellipsis)),
    ]),
  );

  String _fmtDate(String dt) {
    try { return DateFormat('dd MMM yyyy').format(DateTime.parse(dt).toLocal()); }
    catch (_) { return dt; }
  }
}

// ─── Lead Form Pane ────────────────────────────────────────────────────────────
class _LeadFormPane extends StatefulWidget {
  final LeadModel? lead;
  final List<LeadSourceModel> sources;
  final void Function(LeadModel) onSaved;
  const _LeadFormPane({super.key, this.lead, required this.sources, required this.onSaved});
  @override
  State<_LeadFormPane> createState() => _LeadFormPaneState();
}

class _LeadFormPaneState extends State<_LeadFormPane> {
  final _ctrls = <String, TextEditingController>{};
  String _status = 'new', _priority = 'warm';
  int? _sourceId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final k in ['first_name','last_name','email','phone','company',
        'job_title','address','city','state','postal_code','budget','notes']) {
      _ctrls[k] = TextEditingController();
    }
    if (widget.lead != null) {
      final l = widget.lead!;
      _ctrls['first_name']!.text = l.firstName;
      _ctrls['last_name']!.text = l.lastName ?? '';
      _ctrls['email']!.text = l.email;
      _ctrls['phone']!.text = l.phone ?? '';
      _ctrls['company']!.text = l.company ?? '';
      _ctrls['job_title']!.text = l.jobTitle ?? '';
      _ctrls['address']!.text = l.address ?? '';
      _ctrls['city']!.text = l.city ?? '';
      _ctrls['state']!.text = l.state ?? '';
      _ctrls['postal_code']!.text = l.postalCode ?? '';
      _ctrls['budget']!.text = l.budget?.toString() ?? '';
      _ctrls['notes']!.text = l.notes ?? '';
      _status = l.status; _priority = l.priority; _sourceId = l.sourceId;
    }
  }

  @override
  void dispose() { for (final c in _ctrls.values) c.dispose(); super.dispose(); }

  String v(String k) => _ctrls[k]!.text.trim();

  Future<void> _save() async {
    if (v('first_name').isEmpty || v('email').isEmpty) {
      setState(() => _error = 'First name and email are required'); return;
    }
    setState(() { _saving = true; _error = null; });
    final body = {
      'first_name': v('first_name'), 'last_name': v('last_name').isEmpty ? null : v('last_name'),
      'email': v('email'), 'phone': v('phone').isEmpty ? null : v('phone'),
      'company': v('company').isEmpty ? null : v('company'),
      'job_title': v('job_title').isEmpty ? null : v('job_title'),
      'status': _status, 'priority': _priority, 'source': _sourceId,
      'address': v('address').isEmpty ? null : v('address'),
      'city': v('city').isEmpty ? null : v('city'),
      'state': v('state').isEmpty ? null : v('state'),
      'postal_code': v('postal_code').isEmpty ? null : v('postal_code'),
      'budget': v('budget').isEmpty ? null : double.tryParse(v('budget')),
      'notes': v('notes').isEmpty ? null : v('notes'),
    };
    try {
      final LeadModel result;
      if (widget.lead != null) {
        result = await LeadsService.instance.updateLead(widget.lead!.id, body);
      } else {
        result = await LeadsService.instance.createLead(body);
      }
      widget.onSaved(result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget lbl(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 10),
      child: Text(t, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
          color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)),
    );

    Widget tf(String key, String hint, {TextInputType? kb, int lines = 1}) =>
        TextField(
          controller: _ctrls[key],
          keyboardType: kb,
          maxLines: lines,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(hintText: hint),
        );

    return Column(children: [
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(6)),
              child: Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.error)),
            ),

          // Section: Basic
          _sectionHdr('Basic Information', isDark),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              lbl('First Name *'),
              tf('first_name', 'John'),
            ])),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              lbl('Last Name'),
              tf('last_name', 'Doe'),
            ])),
          ]),
          lbl('Email *'),
          tf('email', 'john@company.com', kb: TextInputType.emailAddress),
          lbl('Phone'),
          tf('phone', '+91 98765 43210', kb: TextInputType.phone),
          lbl('Company'),
          tf('company', 'Acme Corp'),
          lbl('Job Title'),
          tf('job_title', 'Marketing Manager'),

          // Section: Status
          _sectionHdr('Lead Details', isDark),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              lbl('Status'),
              _dropField(_status, ['new','contacted','qualified','proposal',
                  'negotiation','won','lost','on_hold'],
                  (v) => setState(() => _status = v), isDark),
            ])),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              lbl('Priority'),
              _dropField(_priority, ['hot','warm','cold'],
                  (v) => setState(() => _priority = v), isDark),
            ])),
          ]),
          lbl('Source'),
          _sourceDropdown(isDark),

          // Section: Address
          _sectionHdr('Address', isDark),
          tf('address', 'Street address', lines: 2),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              lbl('City'), tf('city', 'Mumbai'),
            ])),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              lbl('State'), tf('state', 'Maharashtra'),
            ])),
          ]),
          lbl('Postal Code'),
          tf('postal_code', '400001'),

          // Section: Deal
          _sectionHdr('Deal Info', isDark),
          lbl('Budget (₹)'),
          tf('budget', '50000', kb: TextInputType.number),
          lbl('Notes'),
          tf('notes', 'Any notes...', lines: 3),

          const SizedBox(height: 8),
        ]),
      )),

      // Footer
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        ),
        child: Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () {
              // close
            },
            child: const Text('Cancel'),
          )),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.lead != null ? 'Update Lead' : 'Create Lead'),
          )),
        ]),
      ),
    ]);
  }

  Widget _sectionHdr(String t, bool isDark) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t.toUpperCase(), style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8,
          color: AppColors.primary)),
      const SizedBox(height: 6),
      Divider(height: 1, color: AppColors.primary.withOpacity(0.2)),
    ]),
  );

  Widget _dropField(String val, List<String> opts, ValueChanged<String> onChange, bool isDark) {
    return SizedBox(
      height: 36,
      child: DropdownButtonFormField<String>(
        value: val,
        isDense: true,
        isExpanded: true,
        decoration: const InputDecoration(),
        items: opts.map((o) => DropdownMenuItem(
          value: o,
          child: Text(o.replaceAll('_',' ').split(' ')
              .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w).join(' '),
              style: GoogleFonts.inter(fontSize: 12)),
        )).toList(),
        onChanged: (v) { if (v != null) onChange(v); },
      ),
    );
  }

  Widget _sourceDropdown(bool isDark) {
    return SizedBox(
      height: 36,
      child: DropdownButtonFormField<int?>(
        value: _sourceId,
        isDense: true,
        isExpanded: true,
        decoration: const InputDecoration(),
        items: [
          const DropdownMenuItem(value: null, child: Text('None')),
          ...widget.sources.map((s) => DropdownMenuItem(
              value: s.id, child: Text(s.name, style: GoogleFonts.inter(fontSize: 12)))),
        ],
        onChanged: (v) => setState(() => _sourceId = v),
      ),
    );
  }
}
