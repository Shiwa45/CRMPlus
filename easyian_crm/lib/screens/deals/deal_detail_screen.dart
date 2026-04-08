// screens/deals/deal_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';

class DealDetailScreen extends StatefulWidget {
  final int dealId;
  const DealDetailScreen({super.key, required this.dealId});

  @override
  State<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends State<DealDetailScreen>
    with SingleTickerProviderStateMixin {
  DealModel? _deal;
  List<dynamic> _activities = [];
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
      final d = await DealsService.instance.getDeal(widget.dealId);
      if (mounted) setState(() { _deal = d; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_deal == null) return const Scaffold(body: Center(child: Text('Deal not found')));

    final d = _deal!;
    final isWon = d.stageName?.toLowerCase().contains('won') == true;
    final isLost = d.stageName?.toLowerCase().contains('lost') == true;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF0FDF4),
      body: Column(children: [
        // ── Hero ───────────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: isWon
                  ? [const Color(0xFF065F46), const Color(0xFF10B981)]
                  : isLost
                      ? [const Color(0xFF7F1D1D), const Color(0xFFEF4444)]
                      : isDark
                          ? [const Color(0xFF14532D), const Color(0xFF052E16)]
                          : [const Color(0xFF16A34A), const Color(0xFF059669)],
            ),
          ),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context)),
                const Spacer(),
                _heroBtn(Icons.edit_outlined, () {}),
              ]),
              const SizedBox(height: 14),
              // Deal title + value
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.title, style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  if (d.contactName != null) Row(children: [
                    const Icon(Icons.person_outline, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(d.contactName!, style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                  ]),
                  if (d.companyName != null) Row(children: [
                    const Icon(Icons.business, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(d.companyName!, style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                  ]),
                ])),
                // Big value badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(_curr.format(d.value), style: GoogleFonts.inter(
                        fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text('${d.stageProbability}% probability',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
              // Stage chip + owner
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 8, height: 8, margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Color(int.parse(d.stageColor.replaceAll('#', '0xFF'))),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(d.stageName ?? 'No Stage', style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  ]),
                ),
                const SizedBox(width: 10),
                if (d.ownerName != null) Row(children: [
                  const Icon(Icons.person, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(d.ownerName!, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                ]),
                const Spacer(),
                _priorityBadge(d.priority),
              ]),
            ]),
          )),
        ),
        // ── Stage Progress Bar ──────────────────────────────────────────────
        _StageProgressBar(deal: d, isDark: isDark),
        // ── Tabs ───────────────────────────────────────────────────────────
        Container(
          color: isDark ? AppColors.darkSurface : Colors.white,
          child: TabBar(
            controller: _tabs,
            labelColor: const Color(0xFF16A34A),
            unselectedLabelColor: isDark ? AppColors.darkTextSub : AppColors.lightTextSub,
            indicatorColor: const Color(0xFF16A34A),
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.info_outline, size: 16), text: 'Details'),
              Tab(icon: Icon(Icons.timeline, size: 16), text: 'Activity'),
              Tab(icon: Icon(Icons.receipt_long_outlined, size: 16), text: 'Quotes'),
            ],
          ),
        ),
        Expanded(child: TabBarView(controller: _tabs, children: [
          _DealDetailsTab(deal: d, curr: _curr, isDark: isDark),
          _DealActivityTab(dealId: d.id, isDark: isDark),
          _DealQuotesTab(dealId: d.id, isDark: isDark),
        ])),
      ]),
    );
  }

  Widget _heroBtn(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );

  Widget _priorityBadge(String p) {
    final colors = {'high': Colors.red, 'medium': Colors.orange, 'low': Colors.blue};
    final c = colors[p] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.2), borderRadius: BorderRadius.circular(20),
      ),
      child: Text(p.toUpperCase(),
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
    );
  }
}

class _StageProgressBar extends StatelessWidget {
  final DealModel deal;
  final bool isDark;
  const _StageProgressBar({required this.deal, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final prob = deal.stageProbability / 100.0;
    return Container(
      color: isDark ? AppColors.darkSurface : Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Win Probability', style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)),
          Text('${deal.stageProbability}%', style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF16A34A))),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: prob, minHeight: 8,
            backgroundColor: isDark ? AppColors.darkBorder : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(
              prob > 0.7 ? const Color(0xFF16A34A) : prob > 0.4 ? Colors.orange : Colors.red,
            ),
          ),
        ),
      ]),
    );
  }
}

class _DealDetailsTab extends StatelessWidget {
  final DealModel deal;
  final NumberFormat curr;
  final bool isDark;
  const _DealDetailsTab({required this.deal, required this.curr, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final d = deal;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Value cards row
        Row(children: [
          _valCard('Deal Value', curr.format(d.value), Colors.green, isDark),
          const SizedBox(width: 12),
          _valCard('Weighted', curr.format(d.weightedValue), Colors.blue, isDark),
          const SizedBox(width: 12),
          _valCard('Expected Close',
              d.closeDate != null ? _fmtDate(d.closeDate!) : '—',
              Colors.orange, isDark),
        ]),
        const SizedBox(height: 16),
        _infoCard('Deal Info', [
          _row(Icons.account_tree_rounded, 'Pipeline', d.pipelineName ?? '—'),
          _row(Icons.flag_outlined, 'Stage', d.stageName ?? '—'),
          _row(Icons.person_outline, 'Owner', d.ownerName ?? '—'),
          _row(Icons.calendar_today, 'Created', _fmtDate(d.createdAt)),
          if (d.closeDate != null) _row(Icons.event, 'Expected Close', _fmtDate(d.closeDate!)),
        ], isDark),
        const SizedBox(height: 12),
        if (d.contactName != null || d.companyName != null)
          _infoCard('Links', [
            if (d.contactName != null) _row(Icons.person, 'Contact', d.contactName!),
            if (d.companyName != null) _row(Icons.business, 'Company', d.companyName!),
          ], isDark),
        if (d.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          _infoCard('Tags', [
            Wrap(spacing: 6, runSpacing: 6, children: d.tags.map((t) => Chip(
              label: Text(t, style: GoogleFonts.inter(fontSize: 11)),
              backgroundColor: Colors.green.withOpacity(0.1),
              visualDensity: VisualDensity.compact,
            )).toList()),
          ], isDark),
        ],
      ]),
    );
  }

  String _fmtDate(String dt) {
    try { return DateFormat('dd MMM yyyy').format(DateTime.parse(dt)); }
    catch (_) { return dt; }
  }

  Widget _valCard(String label, String value, Color color, bool isDark) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800,
              color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11,
              color: isDark ? AppColors.darkTextFaint : AppColors.lightTextFaint)),
        ]),
      ));

  Widget _infoCard(String title, List<Widget> children, bool isDark) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)),
      const SizedBox(height: 10),
      ...children,
    ]),
  );

  Widget _row(IconData icon, String label, String value) =>
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
        Icon(icon, size: 16, color: const Color(0xFF16A34A).withOpacity(0.7)),
        const SizedBox(width: 10),
        Text('$label: ', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 13), overflow: TextOverflow.ellipsis)),
      ]));
}

class _DealActivityTab extends StatelessWidget {
  final int dealId;
  final bool isDark;
  const _DealActivityTab({required this.dealId, required this.isDark});

  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.timeline, size: 48, color: isDark ? AppColors.darkTextFaint : Colors.grey.shade300),
    const SizedBox(height: 12),
    Text('Deal Activity', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
    const SizedBox(height: 6),
    Text('Activities and notes for this deal', style: GoogleFonts.inter(color: Colors.grey)),
    const SizedBox(height: 20),
    ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add),
      label: const Text('Log Activity'),
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
    ),
  ]));
}

class _DealQuotesTab extends StatelessWidget {
  final int dealId;
  final bool isDark;
  const _DealQuotesTab({required this.dealId, required this.isDark});

  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.receipt_long_outlined, size: 48, color: isDark ? AppColors.darkTextFaint : Colors.grey.shade300),
    const SizedBox(height: 12),
    Text('Quotes & Invoices', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
    const SizedBox(height: 6),
    Text('Quotes linked to this deal will appear here', style: GoogleFonts.inter(color: Colors.grey)),
    const SizedBox(height: 20),
    ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add),
      label: const Text('Create Quote'),
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
    ),
  ]));
}
