import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_theme.dart';

// ─── Page Header ──────────────────────────────────────────────────────────────
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? bottom;

  const PageHeader({
    super.key, required this.title, this.subtitle,
    this.actions = const [], this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : AppColors.lightText)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                  ],
                ]),
                const Spacer(),
                ...actions,
              ],
            ),
          ),
          if (bottom != null) bottom!,
          Divider(height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ],
      ),
    );
  }
}

// ─── KPI Stat Card ────────────────────────────────────────────────────────────
class KpiCard extends StatelessWidget {
  final String label, value;
  final String? sub, trend;
  final IconData icon;
  final Color color;
  final bool trendUp;

  const KpiCard({
    super.key, required this.label, required this.value,
    required this.icon, required this.color,
    this.sub, this.trend, this.trendUp = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const Spacer(),
          if (trend != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (trendUp ? AppColors.successBg : AppColors.errorBg),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(trendUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    size: 10, color: trendUp ? AppColors.success : AppColors.error),
                const SizedBox(width: 2),
                Text(trend!, style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: trendUp ? AppColors.success : AppColors.error)),
              ]),
            ),
        ]),
        const SizedBox(height: 14),
        Text(value, style: GoogleFonts.inter(
            fontSize: 26, fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkText : AppColors.lightText)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(
            fontSize: 13, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
        if (sub != null) ...[
          const SizedBox(height: 2),
          Text(sub!, style: GoogleFonts.inter(
              fontSize: 11, color: isDark ? AppColors.darkTextFaint : AppColors.lightTextFaint)),
        ],
      ]),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    final label = status.replaceAll('_', ' ').split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label, style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Color _color(String s) {
    switch (s) {
      case 'new': return AppColors.statusNew;
      case 'contacted': return AppColors.statusContacted;
      case 'qualified': return AppColors.statusQualified;
      case 'proposal': return AppColors.statusProposal;
      case 'negotiation': return AppColors.statusNegotiation;
      case 'won': return AppColors.statusWon;
      case 'lost': return AppColors.statusLost;
      case 'on_hold': return AppColors.statusOnHold;
      default: return AppColors.statusOnHold;
    }
  }
}

class PriorityBadge extends StatelessWidget {
  final String priority;
  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = priority == 'hot' ? AppColors.hot
        : priority == 'warm' ? AppColors.warm : AppColors.cold;
    final icon = priority == 'hot' ? '🔥' : priority == 'warm' ? '🌡️' : '❄️';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('$icon ${priority[0].toUpperCase()}${priority.substring(1)}',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

// ─── Table Toolbar ────────────────────────────────────────────────────────────
class TableToolbar extends StatelessWidget {
  final TextEditingController? searchCtrl;
  final String searchHint;
  final List<Widget> filters;
  final List<Widget> actions;
  final int? selectedCount;
  final List<Widget> bulkActions;

  const TableToolbar({
    super.key,
    required this.searchCtrl,
    this.searchHint = 'Search...',
    this.filters = const [],
    this.actions = const [],
    this.selectedCount,
    this.bulkActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasBulk = (selectedCount ?? 0) > 0;

    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (hasBulk) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text('$selectedCount selected',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
            const SizedBox(width: 8),
            ...bulkActions,
          ] else ...[
            if (searchCtrl != null) ...[
              // Search
              SizedBox(
                width: 260,
                height: 34,
                child: TextField(
                  controller: searchCtrl,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: searchHint,
                    prefixIcon: const Icon(Icons.search_rounded, size: 16),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            ...filters,
          ],
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key, required this.icon, required this.title,
    required this.subtitle, this.action, this.actionLabel, this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 48,
            color: (isDark ? AppColors.darkBorder : AppColors.lightBorder2)),
        const SizedBox(height: 16),
        Text(title, style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)),
        const SizedBox(height: 6),
        Text(subtitle, style: GoogleFonts.inter(
            fontSize: 13, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            textAlign: TextAlign.center),
        if (action != null) ...[
          const SizedBox(height: 20),
          action!,
        ] else if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(actionLabel!),
          ),
        ],
      ]),
    );
  }
}

// ─── Shimmer table loader ─────────────────────────────────────────────────────
class TableShimmer extends StatelessWidget {
  final int rows;
  const TableShimmer({super.key, this.rows = 10});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
      highlightColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      child: Column(
        children: List.generate(rows, (i) => Container(
          height: 44,
          margin: const EdgeInsets.only(bottom: 1),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Container(width: 16, height: 16, color: Colors.white),
              const SizedBox(width: 16),
              Container(width: 140, height: 12, color: Colors.white),
              const SizedBox(width: 40),
              Container(width: 100, height: 12, color: Colors.white),
              const Spacer(),
              Container(width: 60, height: 20, color: Colors.white),
              const SizedBox(width: 16),
              Container(width: 50, height: 20, color: Colors.white),
            ]),
          ),
        )),
      ),
    );
  }
}

// ─── Filter Dropdown ──────────────────────────────────────────────────────────
class FilterDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const FilterDropdown({
    super.key, this.value, required this.hint,
    required this.items, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface,
        border: Border.all(color: isDark ? AppColors.darkBorder2 : AppColors.lightBorder2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: GoogleFonts.inter(
              fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          items: items,
          onChanged: onChanged,
          icon: Icon(Icons.expand_more_rounded, size: 16,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          style: GoogleFonts.inter(fontSize: 12,
              color: isDark ? AppColors.darkText : AppColors.lightText),
          dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          isDense: true,
        ),
      ),
    );
  }
}

// ─── Right panel overlay ──────────────────────────────────────────────────────
class SidePanel extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback onClose;
  final double width;

  const SidePanel({
    super.key, required this.title, required this.child,
    required this.onClose, this.actions = const [], this.width = 440,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(left: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel header
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            ),
            child: Row(children: [
              Text(title, style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText)),
              const Spacer(),
              ...actions,
              const SizedBox(width: 4),
              SizedBox(
                width: 28, height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: onClose,
                ),
              ),
            ]),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── Inline action button ─────────────────────────────────────────────────────
class CrmButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool primary, danger, loading;
  final double? width;

  const CrmButton({
    super.key, required this.label, this.icon,
    this.onPressed, this.primary = false, this.danger = false,
    this.loading = false, this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg, fg, border;
    if (danger) {
      bg = AppColors.errorBg; fg = AppColors.error;
      border = AppColors.error.withOpacity(0.4);
    } else if (primary) {
      bg = AppColors.primary; fg = Colors.white;
      border = Colors.transparent;
    } else {
      bg = isDark ? AppColors.darkSurface2 : AppColors.lightSurface;
      fg = isDark ? AppColors.darkTextSub : AppColors.lightTextSub;
      border = isDark ? AppColors.darkBorder2 : AppColors.lightBorder2;
    }

    return SizedBox(
      width: width,
      height: 34,
      child: TextButton(
        onPressed: loading ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: const Size(0, 34),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: border)),
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        child: loading
            ? SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[Icon(icon, size: 15), const SizedBox(width: 6)],
                Text(label),
              ]),
      ),
    );
  }
}
