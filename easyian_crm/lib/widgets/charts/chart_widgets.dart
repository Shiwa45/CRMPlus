import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dashboard_stats_model.dart';

// ─── Monthly Bar Chart ────────────────────────────────────────────────────────
class MonthlyBarChart extends StatelessWidget {
  final List<MonthlyData> data;

  const MonthlyBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (data.isEmpty) return const Center(child: Text('No data available'));
    final recent = data.length > 6 ? data.sublist(data.length - 6) : data;
    final maxY = recent.map((e) => e.total.toDouble()).reduce((a, b) => a > b ? a : b) * 1.3;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY == 0 ? 10 : maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: isDark ? AppColors.darkSurfaceVariant : Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final d = recent[group.x];
              return BarTooltipItem(
                '${d.monthShort}\nTotal: ${d.total}\nWon: ${d.won}',
                GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.darkText : AppColors.lightText),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < recent.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(recent[idx].monthShort,
                        style: GoogleFonts.inter(fontSize: 10,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString(),
                  style: GoogleFonts.inter(fontSize: 10,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: recent.asMap().entries.map((e) {
          final idx = e.key;
          final d = e.value;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: d.total.toDouble(),
                color: AppColors.primary.withOpacity(0.25),
                width: 18,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                rodStackItems: [
                  BarChartRodStackItem(0, d.won.toDouble(), AppColors.success),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Pie / Donut Chart ────────────────────────────────────────────────────────
class StatusDonutChart extends StatefulWidget {
  final Map<String, int> data;
  final Map<String, Color> colorMap;

  const StatusDonutChart({super.key, required this.data, required this.colorMap});

  @override
  State<StatusDonutChart> createState() => _StatusDonutChartState();
}

class _StatusDonutChartState extends State<StatusDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.data.values.fold(0, (a, b) => a + b);
    if (total == 0) return const Center(child: Text('No data'));
    final sections = widget.data.entries.where((e) => e.value > 0).toList();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions || response?.touchedSection == null) {
                      _touchedIndex = -1;
                    } else {
                      _touchedIndex = response!.touchedSection!.touchedSectionIndex;
                    }
                  });
                },
              ),
              sections: sections.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final isTouched = i == _touchedIndex;
                final color = widget.colorMap[e.key] ?? AppColors.chartColors[i % AppColors.chartColors.length];
                return PieChartSectionData(
                  color: color,
                  value: e.value.toDouble(),
                  title: isTouched ? '${e.value}' : '',
                  radius: isTouched ? 60 : 50,
                  titleStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                );
              }).toList(),
              centerSpaceRadius: 38,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sections.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final color = widget.colorMap[e.key] ?? AppColors.chartColors[i % AppColors.chartColors.length];
              final pct = ((e.value / total) * 100).toStringAsFixed(0);
              final label = e.key.replaceAll('_', ' ');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${label[0].toUpperCase()}${label.substring(1)}',
                        style: GoogleFonts.inter(fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('$pct%',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Line Chart ────────────────────────────────────────────────────────────────
class ConversionLineChart extends StatelessWidget {
  final List<MonthlyData> data;

  const ConversionLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (data.isEmpty) return const Center(child: Text('No data'));
    final recent = data.length > 6 ? data.sublist(data.length - 6) : data;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < recent.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(recent[idx].monthShort,
                        style: GoogleFonts.inter(fontSize: 10,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}%',
                  style: GoogleFonts.inter(fontSize: 10,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: recent.asMap().entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.conversionRate))
                .toList(),
            isCurved: true,
            color: AppColors.accent,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, barData, idx) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.accent,
                strokeColor: Colors.white,
                strokeWidth: 2,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.accent.withOpacity(0.3), AppColors.accent.withOpacity(0)],
              ),
            ),
          ),
        ],
        minY: 0,
      ),
    );
  }
}

// ─── Funnel Chart ──────────────────────────────────────────────────────────────
class FunnelChartWidget extends StatelessWidget {
  final List<FunnelData> data;

  const FunnelChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (data.isEmpty) return const Center(child: Text('No data'));
    final total = data.isNotEmpty ? (data.first.count == 0 ? 1 : data.first.count) : 1;

    return Column(
      children: data.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final color = AppColors.chartColors[i % AppColors.chartColors.length];
        final pct = (item.count / total).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(item.stage,
                    style: GoogleFonts.inter(fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 22,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(
                        height: 22,
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text('${item.count}',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Source Performance Chart ─────────────────────────────────────────────────
class SourcePerformanceChart extends StatelessWidget {
  final List<SourcePerformance> data;

  const SourcePerformanceChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (data.isEmpty) return const Center(child: Text('No data'));
    final maxVal = data.map((e) => e.totalLeads).reduce((a, b) => a > b ? a : b);

    return Column(
      children: data.take(6).toList().asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final color = AppColors.chartColors[i % AppColors.chartColors.length];
        final pct = maxVal > 0 ? (item.totalLeads / maxVal).clamp(0.0, 1.0) : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(item.name,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(color: color.withOpacity(0.8), borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text('${item.totalLeads}',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkText : AppColors.lightText)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
