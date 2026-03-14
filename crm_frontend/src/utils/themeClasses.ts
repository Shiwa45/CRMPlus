/**
 * Returns consistent theme-aware class strings.
 * Usage: const t = themeClasses(isDark);
 */
export function themeClasses(isDark: boolean) {
  return {
    // surfaces
    card:        isDark ? "bg-[#13151f] border-[#1e2130]"  : "bg-white border-slate-200 shadow-sm",
    cardHover:   isDark ? "hover:border-indigo-500/30"      : "hover:border-indigo-300 hover:shadow-md",
    elevated:    isDark ? "bg-[#1a1d2e] border-[#2e3247]"  : "bg-slate-50 border-slate-200",
    elevatedHover: isDark ? "hover:border-indigo-500/30"   : "hover:border-indigo-300",

    // text
    textPrimary: isDark ? "text-white"                      : "text-slate-800",
    textSub:     isDark ? "text-gray-400"                   : "text-slate-500",
    textMuted:   isDark ? "text-gray-500"                   : "text-slate-400",
    textTiny:    isDark ? "text-gray-600"                   : "text-slate-400",

    // dividers
    divider:     isDark ? "border-[#1e2130]"                : "border-slate-100",
    dividerMid:  isDark ? "border-[#2e3247]"                : "border-slate-200",

    // inputs
    input:       isDark
      ? "bg-[#1a1d2e] border-[#2e3247] text-gray-300 placeholder-gray-600 focus:border-indigo-500"
      : "bg-white border-slate-200 text-slate-700 placeholder-slate-400 focus:border-indigo-400 shadow-sm",

    // buttons
    btnGhost:    isDark
      ? "bg-[#13151f] border-[#1e2130] text-gray-400 hover:border-indigo-500 hover:text-white"
      : "bg-white border-slate-200 text-slate-500 hover:border-indigo-400 hover:text-slate-700 shadow-sm",
    btnIcon:     isDark
      ? "bg-[#1a1d2e] border-[#2e3247] text-gray-400 hover:text-white"
      : "bg-white border-slate-200 text-slate-400 hover:text-slate-700 shadow-sm",

    // tab active
    tabActive:   "bg-indigo-600 text-white",
    tabInactive: isDark ? "text-gray-400 hover:text-white hover:bg-white/5" : "text-slate-500 hover:text-slate-700 hover:bg-slate-100",

    // chart
    chartGrid:   isDark ? "#1e2130"  : "#e2e8f0",
    chartTick:   isDark ? "#4b5563" : "#94a3b8",
    tooltipBg:   isDark ? "#1a1d2e" : "#ffffff",
    tooltipBorder: isDark ? "#2e3247" : "#e2e8f0",
    tooltipText: isDark ? "#ffffff"  : "#0f172a",

    // thead
    thead:       isDark ? "text-gray-500"                   : "text-slate-400",
    trow:        isDark ? "border-[#1e2130] hover:bg-white/[0.02]" : "border-slate-100 hover:bg-slate-50",
  };
}
