import { Tooltip, ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid } from "recharts";
import { pipelineData, revenueData } from "../data/mockData";
import { ArrowRight, TrendingUp } from "lucide-react";
import { useTheme } from "../context/ThemeContext";
import { themeClasses } from "../utils/themeClasses";

const stages = [
  { name: "Lead",        count: 120, value: "$1.2M", conv: "70%", color: "#6366f1", bg: "from-indigo-500/20 to-indigo-500/5",  border: "border-indigo-500/30" },
  { name: "Qualified",   count: 84,  value: "$890K", conv: "67%", color: "#8b5cf6", bg: "from-violet-500/20 to-violet-500/5",  border: "border-violet-500/30" },
  { name: "Proposal",    count: 56,  value: "$620K", conv: "57%", color: "#a78bfa", bg: "from-violet-400/20 to-violet-400/5",  border: "border-violet-400/30" },
  { name: "Negotiation", count: 32,  value: "$380K", conv: "56%", color: "#c4b5fd", bg: "from-purple-400/15 to-purple-400/5", border: "border-purple-400/30" },
  { name: "Closed Won",  count: 18,  value: "$214K", conv: "100%",color: "#34d399", bg: "from-emerald-500/20 to-emerald-500/5", border: "border-emerald-500/30" },
];

export default function Pipeline() {
  const { theme } = useTheme();
  const isDark = theme === "dark";
  const t = themeClasses(isDark);

  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      return (
        <div className={`rounded-lg p-3 shadow-xl border ${isDark ? "bg-[#1a1d2e] border-[#2e3247]" : "bg-white border-slate-200"}`}>
          <p className={`text-sm font-semibold ${t.textPrimary}`}>{payload[0].payload.name}</p>
          <p className="text-indigo-400 text-sm">{payload[0].value} deals</p>
        </div>
      );
    }
    return null;
  };

  return (
    <div className="p-4 sm:p-6 space-y-5 sm:space-y-6">
      {/* Overview cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
        {[
          { label: "Pipeline Value", value: "$2.4M",    change: "+14%",   positive: true },
          { label: "Avg Deal Size",  value: "$27,600",  change: "+8%",    positive: true },
          { label: "Deal Velocity",  value: "42 days",  change: "-5d",    positive: true },
          { label: "Win Rate",       value: "34.8%",    change: "+5.6%",  positive: true },
        ].map((s) => (
          <div key={s.label} className={`rounded-xl p-4 border ${t.card}`}>
            <div className="flex items-center justify-between mb-2">
              <p className={`text-xs ${t.textMuted}`}>{s.label}</p>
              <span className={`text-xs font-semibold px-1.5 py-0.5 rounded-full ${s.positive ? "bg-emerald-500/10 text-emerald-500" : "bg-red-500/10 text-red-500"}`}>
                {s.change}
              </span>
            </div>
            <p className={`text-xl font-bold ${t.textPrimary}`}>{s.value}</p>
          </div>
        ))}
      </div>

      {/* Funnel + Bar */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
        <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
          <div className="mb-5">
            <h3 className={`font-semibold ${t.textPrimary}`}>Sales Funnel</h3>
            <p className={`text-xs mt-0.5 ${t.textMuted}`}>Stage-by-stage visualization</p>
          </div>
          <div className="space-y-2">
            {stages.map((stage, i) => {
              const width = 100 - i * 14;
              return (
                <div key={stage.name} className="flex items-center gap-3">
                  <div className="flex-1 flex justify-center">
                    <div
                      className={`h-12 rounded-lg bg-gradient-to-r ${stage.bg} border ${stage.border} flex items-center justify-between px-4 transition-all hover:brightness-110 cursor-pointer`}
                      style={{ width: `${width}%` }}
                    >
                      <span className={`text-sm font-semibold ${t.textPrimary}`}>{stage.name}</span>
                      <div className="flex items-center gap-3">
                        <span className={`text-xs ${t.textMuted}`}>{stage.count} deals</span>
                        <span className="text-sm font-bold" style={{ color: stage.color }}>{stage.value}</span>
                      </div>
                    </div>
                  </div>
                  {i < stages.length - 1 && (
                    <div className={`flex items-center gap-1 text-xs shrink-0 w-16 ${t.textMuted}`}>
                      <TrendingUp size={11} />
                      <span>{stage.conv}</span>
                      <ArrowRight size={10} />
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
          <div className="mb-5">
            <h3 className={`font-semibold ${t.textPrimary}`}>Deals per Stage</h3>
            <p className={`text-xs mt-0.5 ${t.textMuted}`}>Count & distribution</p>
          </div>
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={pipelineData} margin={{ top: 0, right: 0, left: -20, bottom: 0 }} barSize={32}>
              <CartesianGrid strokeDasharray="3 3" stroke={t.chartGrid} vertical={false} />
              <XAxis dataKey="name" tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} />
              <Tooltip content={<CustomTooltip />} />
              <Bar dataKey="value" name="Deals" fill="#6366f1" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Stage Cards */}
      <div>
        <h3 className={`font-semibold mb-4 ${t.textPrimary}`}>Stage Breakdown</h3>
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3 sm:gap-4">
          {stages.map((stage, i) => (
            <div key={stage.name} className={`rounded-xl p-4 border ${t.card}`}>
              <div className="flex items-center justify-between mb-3">
                <span className="w-3 h-3 rounded-full" style={{ backgroundColor: stage.color }} />
                <span className={`text-xs ${t.textTiny}`}>#{i + 1}</span>
              </div>
              <p className={`text-lg font-bold ${t.textPrimary}`}>{stage.count}</p>
              <p className={`text-sm mt-0.5 ${t.textSub}`}>{stage.name}</p>
              <p className="text-xs font-semibold mt-2" style={{ color: stage.color }}>{stage.value}</p>
              <div className={`mt-3 pt-3 border-t ${t.divider}`}>
                <div className="flex items-center justify-between text-xs">
                  <span className={t.textMuted}>Conv. Rate</span>
                  <span className={`font-semibold ${t.textPrimary}`}>{stage.conv}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Monthly trend */}
      <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
        <div className="mb-4">
          <h3 className={`font-semibold ${t.textPrimary}`}>Pipeline Value Trend</h3>
          <p className={`text-xs mt-0.5 ${t.textMuted}`}>Monthly revenue tracked across the year</p>
        </div>
        <ResponsiveContainer width="100%" height={180}>
          <BarChart data={revenueData} barSize={18} margin={{ top: 0, right: 0, left: -20, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke={t.chartGrid} vertical={false} />
            <XAxis dataKey="month" tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} />
            <YAxis tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} tickFormatter={(v) => `$${v / 1000}k`} />
            <Tooltip contentStyle={{ background: t.tooltipBg, border: `1px solid ${t.tooltipBorder}`, borderRadius: "8px", color: t.tooltipText }} formatter={(v: any) => [`$${Number(v).toLocaleString()}`, "Revenue"]} />
            <Bar dataKey="revenue" fill="#6366f1" radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
