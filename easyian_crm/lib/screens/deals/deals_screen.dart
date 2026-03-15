// lib/screens/deals/deals_screen.dart
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/desktop_widgets.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});
  @override State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  List<DealModel> _deals = [];
  List<PipelineModel> _pipelines = [];
  bool _loading = true;
  int _total = 0, _page = 1;
  static const _pageSize = 50;
  int? _filterPipeline;
  String? _filterStatus, _filterPriority;
  final _curr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  DealModel? _detail;
  bool _showForm = false;

  @override
  void initState() { super.initState(); _loadInit(); }

  Future<void> _loadInit() async {
    final pipes = await DealsService.instance.getPipelines().catchError((_) => <PipelineModel>[]);
    setState(() => _pipelines = pipes);
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) setState(() => _page = 1);
    setState(() => _loading = true);
    try {
      final r = await DealsService.instance.getDeals(
        page: _page, pipelineId: _filterPipeline,
        status: _filterStatus, priority: _filterPriority);
      setState(() { _deals = r['results'] as List<DealModel>; _total = r['count'] as int; });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(DealModel d) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text('Delete "${d.title}"?', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      content: const Text('This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    )) ?? false;
    if (!ok) return;
    try { await DealsService.instance.deleteDeal(d.id); } catch (_) {}
    if (_detail?.id == d.id) setState(() => _detail = null);
    _load(reset: true);
  }

  Color _prColor(String p) => switch (p) {
    'high' || 'critical' => AppColors.error,
    'medium' => AppColors.warning,
    _ => AppColors.info,
  };

  Widget _badge(String l, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
    child: Text(l, style: GoogleFonts.inter(fontSize: 11, color: c, fontWeight: FontWeight.w600)));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      Expanded(child: Column(children: [
        PageHeader(
          title: 'Deals', subtitle: '$_total deals',
          actions: [
            CrmButton(label: 'Add Deal', icon: Icons.add_rounded, primary: true,
                onPressed: () => setState(() { _showForm = true; _detail = null; })),
          ],
        ),
        TableToolbar(
          searchCtrl: null,
          searchHint: '',
          filters: [
            FilterDropdown<int?>(value: _filterPipeline, hint: 'All Pipelines',
              items: [const DropdownMenuItem(value: null, child: Text('All Pipelines')),
                ..._pipelines.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))],
              onChanged: (v) { setState(() => _filterPipeline = v); _load(reset: true); }),
            const SizedBox(width: 8),
            FilterDropdown<String?>(value: _filterStatus, hint: 'All Status',
              items: const [
                DropdownMenuItem(value: null,   child: Text('All Status')),
                DropdownMenuItem(value: 'open', child: Text('Open')),
                DropdownMenuItem(value: 'won',  child: Text('Won')),
                DropdownMenuItem(value: 'lost', child: Text('Lost')),
              ],
              onChanged: (v) { setState(() => _filterStatus = v); _load(reset: true); }),
            const SizedBox(width: 8),
            FilterDropdown<String?>(value: _filterPriority, hint: 'All Priority',
              items: const [
                DropdownMenuItem(value: null,       child: Text('All Priority')),
                DropdownMenuItem(value: 'low',      child: Text('Low')),
                DropdownMenuItem(value: 'medium',   child: Text('Medium')),
                DropdownMenuItem(value: 'high',     child: Text('High')),
                DropdownMenuItem(value: 'critical', child: Text('Critical')),
              ],
              onChanged: (v) { setState(() => _filterPriority = v); _load(reset: true); }),
          ],
          actions: [Text('$_total total', style: GoogleFonts.inter(fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted))],
        ),
        Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        Expanded(
          child: _loading && _deals.isEmpty ? const TableShimmer(rows: 10)
              : _deals.isEmpty ? EmptyState(icon: Icons.handshake_outlined, title: 'No deals yet',
                  subtitle: 'Create your first deal to get started', actionLabel: 'Add Deal',
                  onAction: () => setState(() { _showForm = true; _detail = null; }))
              : DataTable2(
                  columnSpacing: 12, horizontalMargin: 16, minWidth: 860,
                  headingRowHeight: 40, dataRowHeight: 52,
                  headingTextStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  columns: const [
                    DataColumn2(label: Text('Title'), size: ColumnSize.L),
                    DataColumn2(label: Text('Stage'), size: ColumnSize.M),
                    DataColumn2(label: Text('Value'), size: ColumnSize.M, numeric: true),
                    DataColumn2(label: Text('Contact'), size: ColumnSize.M),
                    DataColumn2(label: Text('Priority'), size: ColumnSize.S),
                    DataColumn2(label: Text('Close Date'), size: ColumnSize.M),
                    DataColumn2(label: Text('Actions'), size: ColumnSize.S, numeric: true),
                  ],
                  rows: _deals.map((d) => DataRow2(
                    onTap: () => setState(() { _detail = d; _showForm = false; }),
                    selected: _detail?.id == d.id,
                    cells: [
                      DataCell(Row(children: [
                        if (d.isWon) const Icon(Icons.emoji_events_rounded, size: 14, color: Color(0xFFf59e0b)),
                        if (d.isLost) const Icon(Icons.cancel_rounded, size: 14, color: AppColors.error),
                        if (!d.isWon && !d.isLost) const Icon(Icons.circle_rounded, size: 10, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(d.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis)),
                      ])),
                      DataCell(Row(children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(
                            color: (() { try { return Color(int.parse(d.stageColor.replaceAll('#','0xFF'))); } catch (_) { return AppColors.primary; } })(),
                            shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(d.stageName ?? '—', style: GoogleFonts.inter(fontSize: 12)),
                      ])),
                      DataCell(Text(_curr.format(d.value), style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w700))),
                      DataCell(Text(d.contactName ?? d.companyName ?? '—',
                          style: GoogleFonts.inter(fontSize: 12))),
                      DataCell(_badge(d.priority.toUpperCase(), _prColor(d.priority))),
                      DataCell(Text(d.closeDate ?? '—', style: GoogleFonts.inter(fontSize: 12))),
                      DataCell(Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        IconButton(icon: Icon(Icons.delete_rounded, size: 15, color: AppColors.error),
                            padding: EdgeInsets.zero, onPressed: () => _delete(d)),
                      ])),
                    ],
                  )).toList()),
        ),
        if (_total > _pageSize)
          _Pager(page: _page, total: _total, pageSize: _pageSize,
              onPrev: () { setState(() => _page--); _load(); },
              onNext: () { setState(() => _page++); _load(); }),
      ])),
      if (_detail != null && !_showForm)
        SidePanel(title: _detail!.title, width: 380,
          onClose: () => setState(() => _detail = null),
          child: _DealDetailPanel(deal: _detail!, isDark: isDark, curr: _curr)),
      if (_showForm)
        SidePanel(title: 'New Deal', width: 460,
          onClose: () => setState(() => _showForm = false),
          child: _DealFormPanel(key: const ValueKey('new'), pipelines: _pipelines,
              onSaved: () { setState(() => _showForm = false); _load(); })),
    ]);
  }
}

class _DealDetailPanel extends StatelessWidget {
  final DealModel deal; final bool isDark; final NumberFormat curr;
  const _DealDetailPanel({required this.deal, required this.isDark, required this.curr});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(curr.format(deal.value), style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800,
          color: isDark ? AppColors.darkText : AppColors.lightText)),
      Text('Weighted: ${curr.format(deal.weightedValue)}', style: GoogleFonts.inter(fontSize: 12,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
      const SizedBox(height: 16),
      if (deal.stageName    != null) _r(Icons.view_kanban_rounded,     deal.stageName!,    isDark),
      if (deal.pipelineName != null) _r(Icons.account_tree_rounded,    deal.pipelineName!, isDark),
      if (deal.contactName  != null) _r(Icons.person_rounded,          deal.contactName!,  isDark),
      if (deal.companyName  != null) _r(Icons.business_rounded,        deal.companyName!,  isDark),
      if (deal.ownerName    != null) _r(Icons.manage_accounts_rounded, deal.ownerName!,    isDark),
      if (deal.closeDate    != null) _r(Icons.event_rounded, 'Close: ${deal.closeDate}',   isDark),
      if (deal.description != null && deal.description!.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('NOTES', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
        const SizedBox(height: 4),
        Text(deal.description!, style: GoogleFonts.inter(fontSize: 13,
            color: isDark ? AppColors.darkText : AppColors.lightText)),
      ],
    ]));
  Widget _r(IconData icon, String v, bool isDark) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, size: 14, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
      const SizedBox(width: 8),
      Expanded(child: Text(v, style: GoogleFonts.inter(fontSize: 13,
          color: isDark ? AppColors.darkText : AppColors.lightText))),
    ]));
}

class _DealFormPanel extends StatefulWidget {
  final List<PipelineModel> pipelines; final VoidCallback onSaved;
  const _DealFormPanel({super.key, required this.pipelines, required this.onSaved});
  @override State<_DealFormPanel> createState() => _DealFormPanelState();
}

class _DealFormPanelState extends State<_DealFormPanel> {
  final _title = TextEditingController(), _value = TextEditingController(),
      _close = TextEditingController(), _desc = TextEditingController();
  int? _pipelineId, _stageId;
  String _priority = 'medium';
  bool _saving = false;

  List<PipelineStageModel> get _stages =>
      widget.pipelines.firstWhere((p) => p.id == _pipelineId, orElse: () =>
          widget.pipelines.isNotEmpty ? widget.pipelines.first : PipelineModel(
              id: 0, name: '', isDefault: false, isActive: false, stages: [], dealsCount: 0, totalValue: 0)).stages;

  @override
  void initState() {
    super.initState();
    if (widget.pipelines.isNotEmpty) {
      _pipelineId = widget.pipelines.firstWhere((p) => p.isDefault, orElse: () => widget.pipelines.first).id;
    }
  }
  @override
  void dispose() { _title.dispose(); _value.dispose(); _close.dispose(); _desc.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required'))); return; }
    setState(() => _saving = true);
    try {
      await DealsService.instance.createDeal({
        'title': _title.text.trim(),
        'value': double.tryParse(_value.text.trim()) ?? 0,
        'priority': _priority,
        if (_pipelineId != null) 'pipeline': _pipelineId,
        if (_stageId    != null) 'stage': _stageId,
        if (_close.text.trim().isNotEmpty) 'close_date': _close.text.trim(),
        if (_desc.text.trim().isNotEmpty) 'description': _desc.text.trim(),
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
      _fld('Value (₹)', _value, isDark, keyboard: TextInputType.number), const SizedBox(height: 12),
      if (widget.pipelines.isNotEmpty) ...[
        _drop<int>('Pipeline', widget.pipelines.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
            _pipelineId, (v) => setState(() { _pipelineId = v; _stageId = null; }), isDark),
        const SizedBox(height: 12),
        if (_stages.isNotEmpty) ...[
          _drop<int>('Stage', _stages.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
              _stageId, (v) => setState(() => _stageId = v), isDark),
          const SizedBox(height: 12),
        ],
      ],
      _drop<String>('Priority', const [
        DropdownMenuItem(value: 'low',    child: Text('Low')),
        DropdownMenuItem(value: 'medium', child: Text('Medium')),
        DropdownMenuItem(value: 'high',   child: Text('High')),
      ], _priority, (v) => setState(() => _priority = v ?? 'medium'), isDark),
      const SizedBox(height: 12),
      _fld('Close Date (YYYY-MM-DD)', _close, isDark), const SizedBox(height: 12),
      _fld('Description', _desc, isDark, maxLines: 3), const SizedBox(height: 24),
      SizedBox(width: double.infinity,
        child: CrmButton(label: 'Create Deal', primary: true, loading: _saving, onPressed: _save)),
    ]));
  }

  Widget _fld(String l, TextEditingController c, bool isDark, {TextInputType? keyboard, int maxLines = 1}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        const SizedBox(height: 4),
        TextField(controller: c, keyboardType: keyboard, maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)))),
      ]);

  Widget _drop<T>(String label, List<DropdownMenuItem<T>> items, T? value,
      void Function(T?) cb, bool isDark) =>
      DropdownButtonFormField<T>(value: value,
        decoration: InputDecoration(labelText: label, isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
        items: items, onChanged: cb,
        style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText));
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
        Text('Page $page of $pages ($total total)', style: GoogleFonts.inter(fontSize: 12,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
        const Spacer(),
        IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: page > 1 ? onPrev : null),
        IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: page < pages ? onNext : null),
      ]));
  }
}
