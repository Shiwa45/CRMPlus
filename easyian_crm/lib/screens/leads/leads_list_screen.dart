import 'package:flutter/material.dart';
import '../../core/utils/app_scaffold_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/num_utils.dart';
import '../../models/lead_model.dart';
import '../../services/leads_service.dart';
import '../../widgets/app_loader.dart';
import '../leads/lead_detail_screen.dart';
import '../leads/lead_form_screen.dart';

class LeadsListScreen extends StatefulWidget {
  const LeadsListScreen({super.key});

  @override
  State<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends State<LeadsListScreen> {
  List<LeadModel> _leads = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _totalCount = 0;
  bool _hasMore = true;

  String? _filterStatus;
  String? _filterPriority;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() { _page = 1; _leads = []; _hasMore = true; _loading = true; _error = null; });
    }
    try {
      final result = await LeadsService.instance.getLeads(
        page: _page,
        status: _filterStatus,
        priority: _filterPriority,
        search: _search.isEmpty ? null : _search,
      );
      final newLeads = result['results'] as List<LeadModel>;
      final count = toInt(result['count']);
      setState(() {
        _leads = reset ? newLeads : [..._leads, ...newLeads];
        _totalCount = count;
        _hasMore = result['next'] != null;
      });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loading) return;
    setState(() { _page++; });
    await _load();
  }

  void _onSearch(String v) {
    _search = v;
    _load(reset: true);
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FilterSheet(
        status: _filterStatus,
        priority: _filterPriority,
        onApply: (status, priority) {
          setState(() { _filterStatus = status; _filterPriority = priority; });
          _load(reset: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFilters = _filterStatus != null || _filterPriority != null || _search.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: AppScaffoldController.openDrawer,
        ),
        title: Text('Leads', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          if (hasFilters)
            TextButton(
              onPressed: () {
                setState(() { _filterStatus = null; _filterPriority = null; _search = ''; _searchCtrl.clear(); });
                _load(reset: true);
              },
              child: const Text('Clear'),
            ),
          IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: _showFilters),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search leads...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18),
                        onPressed: () { _searchCtrl.clear(); _onSearch(''); })
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: _onSearch,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LeadFormScreen()));
          if (result == true) _load(reset: true);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Lead'),
      ),
      body: Column(
        children: [
          // Stats bar
          if (!_loading && _error == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              child: Row(
                children: [
                  Text('$_totalCount leads', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (_filterStatus != null)
                    _chip('Status: ${_filterStatus}', () { setState(() => _filterStatus = null); _load(reset: true); }),
                  if (_filterPriority != null)
                    _chip('Priority: ${_filterPriority}', () { setState(() => _filterPriority = null); _load(reset: true); }),
                ],
              ),
            ),
          Expanded(
            child: _loading && _leads.isEmpty
                ? const Center(child: AppLoader())
                : _error != null && _leads.isEmpty
                    ? _buildError()
                    : _leads.isEmpty
                        ? _buildEmpty()
                        : _buildList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary)),
        const SizedBox(width: 4),
        GestureDetector(onTap: onRemove, child: const Icon(Icons.close, size: 14, color: AppColors.primary)),
      ]),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
      const SizedBox(height: 12),
      Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13)),
      const SizedBox(height: 16),
      OutlinedButton.icon(onPressed: () => _load(reset: true), icon: const Icon(Icons.refresh, size: 18), label: const Text('Retry')),
    ]));
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.withOpacity(0.3)),
      const SizedBox(height: 16),
      Text('No leads found', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
      const SizedBox(height: 8),
      Text('Add your first lead to get started', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
    ]));
  }

  Widget _buildList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _leads.length + (_hasMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _leads.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: TextButton(
              onPressed: _loadMore,
              child: const Text('Load more'),
            )),
          );
        }
        return _LeadCard(
          lead: _leads[i],
          isDark: isDark,
          onTap: () async {
            final result = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => LeadDetailScreen(lead: _leads[i])));
            if (result == true) _load(reset: true);
          },
        );
      },
    );
  }
}

class _LeadCard extends StatelessWidget {
  final LeadModel lead;
  final bool isDark;
  final VoidCallback onTap;

  const _LeadCard({required this.lead, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(lead.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: statusColor.withOpacity(0.15),
                    child: Text(lead.fullName.isNotEmpty ? lead.fullName[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: statusColor, fontSize: 15)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(lead.fullName,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                      if (lead.company != null && lead.company!.isNotEmpty)
                        Text(lead.company!,
                            style: GoogleFonts.inter(fontSize: 12,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                            overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  _priorityBadge(lead.priority),
                ],
              ),
              const SizedBox(height: 10),
              Row(children: [
                _statusBadge(lead.status, statusColor),
                const Spacer(),
                if (lead.budget != null)
                  Text(NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(lead.budget),
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppColors.success)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.email_outlined, size: 13,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                const SizedBox(width: 4),
                Expanded(child: Text(lead.email,
                    style: GoogleFonts.inter(fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    overflow: TextOverflow.ellipsis)),
                if (lead.isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text('Overdue', style: GoogleFonts.inter(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600)),
                  ),
              ]),
            ],
          ),
        ),
      ),
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
    final icon = priority == 'hot' ? Icons.local_fire_department_rounded
        : priority == 'warm' ? Icons.thermostat_rounded : Icons.ac_unit_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text('${priority[0].toUpperCase()}${priority.substring(1)}',
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
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
}

class _FilterSheet extends StatefulWidget {
  final String? status;
  final String? priority;
  final Function(String?, String?) onApply;

  const _FilterSheet({this.status, this.priority, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _status;
  String? _priority;

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    _priority = widget.priority;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter Leads', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Text('Status', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            _filterChip('new', 'New', _status),
            _filterChip('contacted', 'Contacted', _status),
            _filterChip('qualified', 'Qualified', _status),
            _filterChip('proposal', 'Proposal', _status),
            _filterChip('won', 'Won', _status),
            _filterChip('lost', 'Lost', _status),
            _filterChip('on_hold', 'On Hold', _status),
          ]),
          const SizedBox(height: 16),
          Text('Priority', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            _priorityChip('hot', 'Hot'),
            _priorityChip('warm', 'Warm'),
            _priorityChip('cold', 'Cold'),
          ]),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () { setState(() { _status = null; _priority = null; }); },
              child: const Text('Clear'),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () { widget.onApply(_status, _priority); Navigator.pop(context); },
              child: const Text('Apply'),
            )),
          ]),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label, String? selected) {
    final isSelected = selected == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _status = isSelected ? null : value),
    );
  }

  Widget _priorityChip(String value, String label) {
    final isSelected = _priority == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _priority = isSelected ? null : value),
    );
  }
}

