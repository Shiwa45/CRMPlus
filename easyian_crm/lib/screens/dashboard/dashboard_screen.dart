import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/services.dart';
import '../../widgets/desktop_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? _stats;
  List<LeadModel> _recentLeads = [];
  bool _loading = true;
  String? _error;
  String _range = 'month';

  final _curr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  final _num = NumberFormat.compact();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Fire both requests concurrently
      final statsFuture = DashboardService.instance.getStats(dateRange: _range);

      Map<String, dynamic> leadsResponse;
      try {
        leadsResponse = await LeadsService.instance.getLeads(
          pageSize: 8,
          ordering: '-created_at',
        );
      } catch (_) {
        leadsResponse = await LeadsService.instance.getLeads(pageSize: 8);
      }

      final stats = await statsFuture;

      if (!mounted) return;

      // results is already List<LeadModel> because LeadsService deserializes it
      final rawResults = leadsResponse['results'];
      final leads = rawResults is List<LeadModel>
          ? rawResults
          : (rawResults is List)
              ? rawResults
                  .whereType<Map>()
                  .map(
                    (e) => LeadModel.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList()
              : <LeadModel>[];

      setState(() {
        _stats = stats;
        _recentLeads = leads;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AppProvider>().currentUser;

    return Column(
      children: [
        PageHeader(
          title: 'Dashboard',
          subtitle: 'Welcome back, ${user?.firstName ?? 'there'} 👋',
          actions: [
            FilterDropdown<String>(
              value: _range,
              hint: 'Period',
              items: const [
                DropdownMenuItem(value: 'today', child: Text('Today')),
                DropdownMenuItem(value: 'week', child: Text('This Week')),
                DropdownMenuItem(value: 'month', child: Text('This Month')),
                DropdownMenuItem(
                  value: 'quarter',
                  child: Text('This Quarter'),
                ),
                DropdownMenuItem(value: 'year', child: Text('This Year')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _range = v);
                  _load();
                }
              },
            ),
            const SizedBox(width: 8),
            CrmButton(
              label: 'Refresh',
              icon: Icons.refresh_rounded,
              onPressed: _load,
              loading: _loading,
            ),
          ],
        ),
        Expanded(
          child: _loading && _stats == null
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: GoogleFonts.inter(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          CrmButton(
                            label: 'Retry',
                            icon: Icons.refresh_rounded,
                            onPressed: _load,
                          ),
                        ],
                      ),
                    )
                  : _buildBody(isDark),
        ),
      ],
    );
  }

  Widget _buildBody(bool isDark) {
    final s = _stats ?? DashboardStats.empty();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI Row ────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  label: 'Total Leads',
                  value: _num.format(s.totalLeads),
                  icon: Icons.people_rounded,
                  color: AppColors.primary,
                  sub: '+${s.newLeads} new this period',
                  trend: '+${s.newLeads}',
                  trendUp: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KpiCard(
                  label: 'Won',
                  value: '${s.wonLeads}',
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.success,
                  sub: '${s.conversionRate.toStringAsFixed(1)}% conversion rate',
                  trend: '${s.conversionRate.toStringAsFixed(1)}%',
                  trendUp: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KpiCard(
                  label: 'Revenue',
                  value: _curr.format(s.totalRevenue),
                  icon: Icons.currency_rupee_rounded,
                  color: AppColors.accent,
                  sub: 'Avg deal: ${_curr.format(s.avgDealSize)}',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KpiCard(
                  label: 'Overdue',
                  value: '${s.overdueLeads}',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.error,
                  sub: 'Require immediate follow-up',
                  trend: s.overdueLeads > 0 ? '${s.overdueLeads}' : null,
                  trendUp: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Charts Row ─────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _chartCard(
                  'Monthly Leads & Revenue',
                  isDark,
                  _buildBarChart(s, isDark),
                  height: 240,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _chartCard(
                  'Lead Status',
                  isDark,
                  _buildDonut(s, isDark),
                  height: 240,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Pipeline Funnel + Source Performance ───────────────────────
          if (s.funnelData.isNotEmpty || s.sourcePerformance.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (s.funnelData.isNotEmpty)
                  Expanded(
                    child: _chartCard(
                      'Pipeline Funnel',
                      isDark,
                      _buildFunnel(s, isDark),
                      height: 200,
                    ),
                  ),
                if (s.funnelData.isNotEmpty && s.sourcePerformance.isNotEmpty)
                  const SizedBox(width: 16),
                if (s.sourcePerformance.isNotEmpty)
                  Expanded(child: _buildSourceTable(s, isDark)),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // ── Recent Leads Table ─────────────────────────────────────────
          _buildRecentLeads(isDark),
        ],
      ),
    );
  }

  // ── Chart Card Wrapper ───────────────────────────────────────────────────

  Widget _chartCard(
    String title,
    bool isDark,
    Widget child, {
    double height = 220,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }

  // ── Bar Chart ────────────────────────────────────────────────────────────

  Widget _buildBarChart(DashboardStats s, bool isDark) {
    if (s.monthlyData.isEmpty) {
      return Center(
        child: Text(
          'No data',
          style: GoogleFonts.inter(
            color: isDark
                ? AppColors.darkTextMuted
                : AppColors.lightTextMuted,
          ),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: s.monthlyData.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.total.toDouble(),
                color: AppColors.primary.withOpacity(0.7),
                width: 14,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
              ),
              BarChartRodData(
                toY: e.value.won.toDouble(),
                color: AppColors.success,
                width: 14,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.darkTextFaint
                      : AppColors.lightTextFaint,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= s.monthlyData.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    s.monthlyData[idx].monthShort,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.darkTextFaint
                          : AppColors.lightTextFaint,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  // ── Donut / Pie Chart ────────────────────────────────────────────────────

  Widget _buildDonut(DashboardStats s, bool isDark) {
    final entries = s.leadsByStatus.entries.toList();

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No data',
          style: GoogleFonts.inter(
            color: isDark
                ? AppColors.darkTextMuted
                : AppColors.lightTextMuted,
          ),
        ),
      );
    }

    final colors = AppColors.chart;

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              sections: entries.asMap().entries.map((e) {
                return PieChartSectionData(
                  value: e.value.value.toDouble(),
                  color: colors[e.key % colors.length],
                  radius: 32,
                  showTitle: false,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors[e.key % colors.length],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    e.value.key.replaceAll('_', ' '),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${e.value.value}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkText
                          : AppColors.lightText,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Funnel Chart ─────────────────────────────────────────────────────────

  Widget _buildFunnel(DashboardStats s, bool isDark) {
    // Safe max calculation avoiding fold issues with empty list
    final maxCount = s.funnelData.isEmpty
        ? 1
        : s.funnelData
            .map((e) => e.count)
            .reduce((a, b) => a > b ? a : b);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: s.funnelData.map((f) {
        final pct = maxCount > 0 ? f.count / maxCount : 0.0;

        return Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                f.stage,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface2
                          : AppColors.lightSurface2,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: pct.clamp(0.0, 1.0),
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 36,
              child: Text(
                '${f.count}',
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── Source Performance Table ─────────────────────────────────────────────

  Widget _buildSourceTable(DashboardStats s, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Source Performance',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 12),

          // Header row
          Row(
            children: ['Source', 'Leads', 'Won', 'Conv.'].map((h) {
              return Expanded(
                child: Text(
                  h,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              );
            }).toList(),
          ),

          Divider(
            height: 12,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),

          // Data rows
          ...s.sourcePerformance.map((sp) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      sp.name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${sp.totalLeads}',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${sp.wonLeads}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${sp.conversionRate.toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Recent Leads Table ───────────────────────────────────────────────────

  Widget _buildRecentLeads(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                Text(
                  'Recent Leads',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      context.read<AppProvider>().navigate(AppRoute.leads),
                  child: Text(
                    'View all →',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),

          // Table header
          _tableRow(
            isDark,
            isHeader: true,
            cells: [
              'Name',
              'Company',
              'Email',
              'Status',
              'Priority',
              'Created',
            ],
          ),

          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),

          // Table body
          if (_recentLeads.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No leads yet',
                  style: GoogleFonts.inter(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ),
            )
          else
            ...(_recentLeads.map(
              (l) => Column(
                children: [
                  _tableRow(
                    isDark,
                    isHeader: false,
                    cells: [
                      l.fullName,
                      l.company ?? '—',
                      l.email,
                      'status:${l.status}',
                      'priority:${l.priority}',
                      _fmtDate(l.createdAt),
                    ],
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  // ── Table Row Builder ────────────────────────────────────────────────────

  Widget _tableRow(
    bool isDark, {
    required bool isHeader,
    required List<String> cells,
  }) {
    Widget buildCell(String v, int index) {
      // Render status badge
      if (!isHeader && v.startsWith('status:')) {
        return StatusBadge(status: v.substring(7));
      }
      // Render priority badge
      if (!isHeader && v.startsWith('priority:')) {
        return PriorityBadge(priority: v.substring(9));
      }
      return Text(
        v,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
          color: isHeader
              ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
              : (isDark ? AppColors.darkText : AppColors.lightText),
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    return Container(
      height: isHeader ? 36 : 44,
      color: isHeader
          ? (isDark ? AppColors.darkSurface2 : AppColors.lightSurface2)
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: cells.asMap().entries.map((e) {
          return Expanded(
            // Give email column more space
            flex: e.key == 2 ? 2 : 1,
            child: buildCell(e.value, e.key),
          );
        }).toList(),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _fmtDate(String dt) {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(dt).toLocal());
    } catch (_) {
      return dt;
    }
  }
}
