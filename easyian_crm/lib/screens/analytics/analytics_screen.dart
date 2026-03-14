import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/desktop_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  DashboardStats? _stats;
  bool _loading = true;
  String _range = 'month';
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
    final s = await DashboardService.instance.getStats(dateRange: _range);
    setState(() { _stats = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(children: [
      PageHeader(
        title: 'Analytics',
        subtitle: 'Performance overview and pipeline insights',
        actions: [
          FilterDropdown<String>(
            value: _range,
            hint: 'Period',
            items: const [
              DropdownMenuItem(value: 'today',   child: Text('Today')),
              DropdownMenuItem(value: 'week',    child: Text('This Week')),
              DropdownMenuItem(value: 'month',   child: Text('This Month')),
              DropdownMenuItem(value: 'quarter', child: Text('This Quarter')),
              DropdownMenuItem(value: 'year',    child: Text('This Year')),
            ],
            onChanged: (v) { if (v != null) { setState(() => _range = v); _load(); } },
          ),
          const SizedBox(width: 8),
          CrmButton(label: 'Refresh', icon: Icons.refresh_rounded,
              onPressed: _load, loading: _loading),
        ],
        bottom: Container(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          child: TabBar(
            controller: _tabs,
            isScrollable: false,
            labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Pipeline'),
              Tab(text: 'Sources'),
            ],
          ),
        ),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(controller: _tabs, children: [
                _OverviewTab(stats: _stats!, curr: _curr, isDark: isDark),
                _PipelineTab(stats: _stats!, isDark: isDark),
                _SourcesTab(stats: _stats!, isDark: isDark),
              ]),
      ),
    ]);
  }
}

class _OverviewTab extends StatelessWidget {
  final DashboardStats stats;
  final NumberFormat curr;
  final bool isDark;
  const _OverviewTab({required this.stats, required this.curr, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final s = stats;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // KPI grid
        Row(children: [
          Expanded(child: KpiCard(label: 'Total Leads', value: '${s.totalLeads}',
              icon: Icons.people_rounded, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: KpiCard(label: 'Won', value: '${s.wonLeads}',
              icon: Icons.emoji_events_rounded, color: AppColors.success)),
          const SizedBox(width: 12),
          Expanded(child: KpiCard(label: 'Lost', value: '${s.lostLeads}',
              icon: Icons.cancel_outlined, color: AppColors.error)),
          const SizedBox(width: 12),
          Expanded(child: KpiCard(label: 'Conversion', value: '${s.conversionRate.toStringAsFixed(1)}%',
              icon: Icons.percent_rounded, color: AppColors.accent)),
          const SizedBox(width: 12),
          Expanded(child: KpiCard(label: 'Revenue', value: curr.format(s.totalRevenue),
              icon: Icons.currency_rupee_rounded, color: AppColors.warning)),
        ]),
        const SizedBox(height: 20),

        // Monthly trend chart (full width)
        _card('Monthly Trends', isDark,
            SizedBox(height: 280, child: _buildLineChart(s, isDark))),
        const SizedBox(height: 20),

        // 2-col: status donut + priority donut
        Row(children: [
          Expanded(child: _card('Lead Status Breakdown', isDark,
              SizedBox(height: 220, child: _buildDonut(s.leadsByStatus, isDark)))),
          const SizedBox(width: 16),
          Expanded(child: _card('Lead Priority Breakdown', isDark,
              SizedBox(height: 220, child: _buildDonut(s.leadsByPriority, isDark,
                  colors: {
                    'hot': AppColors.hot, 'warm': AppColors.warm, 'cold': AppColors.cold,
                  })))),
        ]),
      ]),
    );
  }

  Widget _buildLineChart(DashboardStats s, bool isDark) {
    if (s.monthlyData.isEmpty) return Center(child: Text('No data',
        style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)));
    return LineChart(LineChartData(
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32,
            getTitlesWidget: (v, _) => Text('${v.toInt()}',
                style: GoogleFonts.inter(fontSize: 10,
                    color: isDark ? AppColors.darkTextFaint : AppColors.lightTextFaint)))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= s.monthlyData.length) return const SizedBox.shrink();
              return Padding(padding: const EdgeInsets.only(top: 4),
                  child: Text(s.monthlyData[i].monthShort,
                      style: GoogleFonts.inter(fontSize: 10,
                          color: isDark ? AppColors.darkTextFaint : AppColors.lightTextFaint)));
            })),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        _lineBar(s.monthlyData.asMap().entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.total.toDouble())).toList(),
            AppColors.primary),
        _lineBar(s.monthlyData.asMap().entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.won.toDouble())).toList(),
            AppColors.success),
      ],
    ));
  }

  LineChartBarData _lineBar(List<FlSpot> spots, Color color) => LineChartBarData(
    spots: spots, color: color, isCurved: true, barWidth: 2,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: true, color: color.withOpacity(0.06)),
  );

  Widget _buildDonut(Map<String, int> data, bool isDark,
      {Map<String, Color>? colors}) {
    final entries = data.entries.toList();
    if (entries.isEmpty) return Center(child: Text('No data',
        style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)));
    final chart = AppColors.chart;
    return Row(children: [
      Expanded(child: PieChart(PieChartData(
        sectionsSpace: 2, centerSpaceRadius: 44,
        sections: entries.asMap().entries.map((e) => PieChartSectionData(
          value: e.value.value.toDouble(),
          color: colors?[e.value.key] ?? chart[e.key % chart.length],
          radius: 28, showTitle: false,
        )).toList(),
      ))),
      const SizedBox(width: 8),
      SizedBox(
        width: 130,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.asMap().entries.map((e) {
            final c = colors?[e.value.key] ?? chart[e.key % chart.length];
            return Padding(padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 6),
                Expanded(child: Text(e.value.key.replaceAll('_', ' '),
                    style: GoogleFonts.inter(fontSize: 10,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    overflow: TextOverflow.ellipsis)),
                Text('${e.value.value}', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText)),
              ]),
            );
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _card(String title, bool isDark, Widget child) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkText : AppColors.lightText)),
      const SizedBox(height: 16),
      child,
    ]),
  );
}

class _PipelineTab extends StatelessWidget {
  final DashboardStats stats;
  final bool isDark;
  const _PipelineTab({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final s = stats;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (s.funnelData.isNotEmpty) ...[
          _card('Pipeline Funnel', isDark, _buildFunnel(s, isDark)),
          const SizedBox(height: 20),
        ],
        _buildStatusTable(s, isDark),
      ]),
    );
  }

  Widget _buildFunnel(DashboardStats s, bool isDark) {
    final max = s.funnelData.map((e) => e.count).fold(0, (a, b) => a > b ? a : b);
    return Column(
      children: s.funnelData.map((f) {
        final pct = max > 0 ? f.count / max : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            SizedBox(width: 100, child: Text(f.stage, style: GoogleFonts.inter(
                fontSize: 12, color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub))),
            Expanded(child: Stack(children: [
              Container(height: 28, decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
                  borderRadius: BorderRadius.circular(4))),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(height: 28, decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.primary, AppColors.primary.withOpacity(0.7),
                    ]),
                    borderRadius: BorderRadius.circular(4))),
              ),
            ])),
            const SizedBox(width: 12),
            SizedBox(width: 60, child: Text('${f.count} (${f.percentage.toStringAsFixed(0)}%)',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkText : AppColors.lightText))),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildStatusTable(DashboardStats s, bool isDark) {
    final rows = s.leadsByStatus.entries.toList();
    return _card('Status Summary', isDark, Column(children: [
      // Header
      _tr(['Status', 'Count', '% of Total'], isDark, isHeader: true),
      Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ...rows.map((e) {
        final pct = s.totalLeads > 0 ? e.value / s.totalLeads * 100 : 0.0;
        return Column(children: [
          Row(children: [
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: StatusBadge(status: e.key),
            )),
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('${e.value}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
            )),
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                Container(
                  width: (pct * 0.8).clamp(0, 80), height: 4,
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 6),
                Text('${pct.toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
              ]),
            )),
          ]),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ]);
      }),
    ]));
  }

  Widget _tr(List<String> cells, bool isDark, {bool isHeader = false}) {
    return Container(
      color: isHeader ? (isDark ? AppColors.darkSurface2 : AppColors.lightSurface2) : null,
      child: Row(
        children: cells.map((c) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(c, style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
              color: isHeader ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                  : (isDark ? AppColors.darkText : AppColors.lightText))),
        ))).toList(),
      ),
    );
  }

  Widget _card(String title, bool isDark, Widget child) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkText : AppColors.lightText)),
      const SizedBox(height: 16),
      child,
    ]),
  );
}

class _SourcesTab extends StatelessWidget {
  final DashboardStats stats;
  final bool isDark;
  const _SourcesTab({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final s = stats;
    if (s.sourcePerformance.isEmpty) {
      return const EmptyState(
        icon: Icons.source_outlined,
        title: 'No source data',
        subtitle: 'Assign lead sources to see performance.',
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        _card('Source Performance', isDark, _buildBarChart(s, isDark)),
        const SizedBox(height: 20),
        _card('Source Details', isDark, _buildTable(s, isDark)),
      ]),
    );
  }

  Widget _buildBarChart(DashboardStats s, bool isDark) {
    return SizedBox(
      height: 260,
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: s.sourcePerformance.asMap().entries.map((e) => BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(toY: e.value.totalLeads.toDouble(),
                color: AppColors.primary.withOpacity(0.7), width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
            BarChartRodData(toY: e.value.wonLeads.toDouble(),
                color: AppColors.success, width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
          ],
        )).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= s.sourcePerformance.length) return const SizedBox.shrink();
                return Padding(padding: const EdgeInsets.only(top: 4),
                    child: Text(s.sourcePerformance[i].name,
                        style: GoogleFonts.inter(fontSize: 10,
                            color: isDark ? AppColors.darkTextFaint : AppColors.lightTextFaint),
                        overflow: TextOverflow.ellipsis));
              })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
              getTitlesWidget: (v, _) => Text('${v.toInt()}',
                  style: GoogleFonts.inter(fontSize: 10,
                      color: isDark ? AppColors.darkTextFaint : AppColors.lightTextFaint)))),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
      )),
    );
  }

  Widget _buildTable(DashboardStats s, bool isDark) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2), 1: FlexColumnWidth(), 2: FlexColumnWidth(),
        3: FlexColumnWidth(), 4: FlexColumnWidth(1.5),
      },
      children: [
        _tableRow(['Source','Total','Won','Lost','Conv. Rate'], isDark, isHeader: true),
        ...s.sourcePerformance.map((sp) => _tableRow([
          sp.name,
          '${sp.totalLeads}',
          '${sp.wonLeads}',
          '${sp.totalLeads - sp.wonLeads}',
          '${sp.conversionRate.toStringAsFixed(1)}%',
        ], isDark)),
      ],
    );
  }

  TableRow _tableRow(List<String> cells, bool isDark, {bool isHeader = false}) => TableRow(
    decoration: isHeader ? BoxDecoration(
      color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
    ) : null,
    children: cells.map((c) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(c, style: GoogleFonts.inter(
          fontSize: isHeader ? 11 : 12,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
          color: isHeader ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
              : (isDark ? AppColors.darkText : AppColors.lightText))),
    )).toList(),
  );

  Widget _card(String title, bool isDark, Widget child) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkText : AppColors.lightText)),
      const SizedBox(height: 16),
      child,
    ]),
  );
}
