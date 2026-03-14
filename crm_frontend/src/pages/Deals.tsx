import { Plus, MoreHorizontal, TrendingUp, Calendar, User } from "lucide-react";
import { deals } from "../data/mockData";
import { useTheme } from "../context/ThemeContext";
import { themeClasses } from "../utils/themeClasses";

const stageConfigDark: Record<string, { color: string; bg: string; bar: string }> = {
  Lead:         { color: "text-gray-400",    bg: "bg-gray-500/10 border-gray-500/20",    bar: "bg-gray-500" },
  Qualified:    { color: "text-blue-400",    bg: "bg-blue-500/10 border-blue-500/20",    bar: "bg-blue-500" },
  Proposal:     { color: "text-violet-400",  bg: "bg-violet-500/10 border-violet-500/20", bar: "bg-violet-500" },
  Negotiation:  { color: "text-amber-400",   bg: "bg-amber-500/10 border-amber-500/20",  bar: "bg-amber-500" },
  "Closed Won": { color: "text-emerald-400", bg: "bg-emerald-500/10 border-emerald-500/20", bar: "bg-emerald-500" },
};
const stageConfigLight: Record<string, { color: string; bg: string; bar: string }> = {
  Lead:         { color: "text-slate-500",   bg: "bg-slate-50 border-slate-200",        bar: "bg-slate-400" },
  Qualified:    { color: "text-blue-600",    bg: "bg-blue-50 border-blue-200",          bar: "bg-blue-500" },
  Proposal:     { color: "text-violet-600",  bg: "bg-violet-50 border-violet-200",      bar: "bg-violet-500" },
  Negotiation:  { color: "text-amber-600",   bg: "bg-amber-50 border-amber-200",        bar: "bg-amber-500" },
  "Closed Won": { color: "text-emerald-600", bg: "bg-emerald-50 border-emerald-200",    bar: "bg-emerald-500" },
};

const kanbanStages = ["Lead", "Qualified", "Proposal", "Negotiation", "Closed Won"];

export default function Deals() {
  const { theme } = useTheme();
  const isDark = theme === "dark";
  const t = themeClasses(isDark);
  const stageConfig = isDark ? stageConfigDark : stageConfigLight;
  const barBg = isDark ? "bg-[#1a1d2e]" : "bg-slate-100";

  return (
    <div className="p-4 sm:p-6 space-y-5 sm:space-y-6">
      {/* Summary stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 sm:gap-4">
        {[
          { label: "Total Pipeline",  value: "$2.4M",    sub: "87 open deals" },
          { label: "Avg. Deal Size",  value: "$27,600",  sub: "+8% this month" },
          { label: "Win Rate",        value: "34.8%",    sub: "vs 29% last yr" },
          { label: "Avg. Cycle",      value: "42 days",  sub: "-5 days vs last yr" },
        ].map((s) => (
          <div key={s.label} className={`rounded-xl p-4 border ${t.card}`}>
            <p className={`text-xl font-bold ${t.textPrimary}`}>{s.value}</p>
            <p className={`text-xs mt-0.5 ${t.textSub}`}>{s.label}</p>
            <p className={`text-[11px] mt-1 ${t.textTiny}`}>{s.sub}</p>
          </div>
        ))}
      </div>

      {/* Action bar */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex flex-wrap gap-2">
          {["All Deals","My Deals","Won","Lost"].map((tab, i) => (
            <button key={tab} className={`text-sm px-3 py-1.5 rounded-lg transition-all ${i === 0 ? t.tabActive : t.tabInactive}`}>
              {tab}
            </button>
          ))}
        </div>
        <button className="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-medium px-4 py-2 rounded-lg transition-all">
          <Plus size={14} /> New Deal
        </button>
      </div>

      {/* Kanban Board */}
      <div className="flex gap-4 overflow-x-auto pb-4 -mx-4 px-4 sm:mx-0 sm:px-0">
        {kanbanStages.map((stage) => {
          const stageDeals = deals.filter(d => d.stage === stage);
          const cfg = stageConfig[stage];
          const total = stageDeals.reduce((sum, d) => sum + parseFloat(d.value.replace(/[$,]/g, "")), 0);
          return (
            <div key={stage} className="flex-shrink-0 w-64 sm:w-72">
              <div className={`flex items-center justify-between mb-3 px-3 py-2 rounded-lg border ${cfg.bg}`}>
                <div className="flex items-center gap-2">
                  <span className={`w-2 h-2 rounded-full ${cfg.bar}`} />
                  <span className={`text-sm font-semibold ${cfg.color}`}>{stage}</span>
                  <span className={`text-xs px-1.5 py-0.5 rounded-full bg-white/10 ${cfg.color}`}>{stageDeals.length}</span>
                </div>
                <span className={`text-xs ${t.textMuted}`}>${(total / 1000).toFixed(0)}k</span>
              </div>
              <div className="space-y-3">
                {stageDeals.map((deal) => (
                  <div key={deal.id} className={`rounded-xl p-4 border cursor-pointer transition-all group ${t.card} ${t.cardHover}`}>
                    <div className="flex items-start justify-between mb-3">
                      <h4 className={`text-sm font-semibold leading-snug pr-2 ${t.textPrimary}`}>{deal.title}</h4>
                      <button className={`opacity-0 group-hover:opacity-100 transition-all shrink-0 ${t.textMuted}`}><MoreHorizontal size={14} /></button>
                    </div>
                    <p className={`text-xs mb-3 ${t.textMuted}`}>{deal.company}</p>
                    <div className={`text-lg font-bold mb-3 ${t.textPrimary}`}>{deal.value}</div>
                    <div className="mb-3">
                      <div className={`flex justify-between text-[11px] mb-1 ${t.textMuted}`}>
                        <span>Probability</span>
                        <span className={cfg.color}>{deal.probability}%</span>
                      </div>
                      <div className={`w-full rounded-full h-1.5 ${barBg}`}>
                        <div className={`h-1.5 rounded-full ${cfg.bar}`} style={{ width: `${deal.probability}%` }} />
                      </div>
                    </div>
                    <div className={`flex items-center justify-between text-[11px] ${t.textMuted}`}>
                      <div className="flex items-center gap-1"><User size={10} /><span>{deal.owner}</span></div>
                      <div className="flex items-center gap-1"><Calendar size={10} /><span>{deal.closeDate}</span></div>
                    </div>
                  </div>
                ))}
                <button className={`w-full py-3 rounded-xl border border-dashed text-sm hover:border-indigo-500 hover:text-indigo-400 transition-all flex items-center justify-center gap-2 ${isDark ? "border-[#2e3247] text-gray-600" : "border-slate-300 text-slate-400"}`}>
                  <Plus size={14} /> Add Deal
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Deals Table */}
      <div className={`rounded-xl overflow-hidden border ${t.card}`}>
        <div className={`px-5 py-4 border-b ${t.divider}`}>
          <h3 className={`font-semibold ${t.textPrimary}`}>All Deals</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className={`border-b ${t.divider}`}>
                {["Deal","Contact","Stage","Value","Probability","Close Date","Owner",""].map(h => (
                  <th key={h} className={`text-left text-[11px] uppercase tracking-wider px-5 py-3 font-semibold ${t.thead}`}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {deals.map((deal) => {
                const cfg = stageConfig[deal.stage];
                return (
                  <tr key={deal.id} className={`border-b transition-all cursor-pointer group ${t.trow}`}>
                    <td className="px-5 py-4">
                      <p className={`text-sm font-medium ${t.textPrimary}`}>{deal.title}</p>
                      <p className={`text-xs ${t.textMuted}`}>{deal.company}</p>
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-2">
                        <div className="w-6 h-6 rounded-full bg-indigo-600 flex items-center justify-center text-white text-[10px] font-bold">
                          {deal.contact.split(" ").map(n => n[0]).join("").slice(0, 2)}
                        </div>
                        <span className={`text-sm ${t.textSub}`}>{deal.contact}</span>
                      </div>
                    </td>
                    <td className="px-5 py-4">
                      <span className={`text-[11px] font-semibold px-2 py-1 rounded-full border ${cfg.bg} ${cfg.color}`}>{deal.stage}</span>
                    </td>
                    <td className="px-5 py-4"><span className={`text-sm font-bold ${t.textPrimary}`}>{deal.value}</span></td>
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-2">
                        <div className={`w-16 rounded-full h-1.5 ${barBg}`}>
                          <div className={`h-1.5 rounded-full ${cfg.bar}`} style={{ width: `${deal.probability}%` }} />
                        </div>
                        <span className={`text-xs font-semibold ${cfg.color}`}>{deal.probability}%</span>
                      </div>
                    </td>
                    <td className="px-5 py-4">
                      <div className={`flex items-center gap-1.5 ${t.textSub}`}>
                        <Calendar size={12} /><span className="text-sm">{deal.closeDate}</span>
                      </div>
                    </td>
                    <td className="px-5 py-4"><span className={`text-sm ${t.textSub}`}>{deal.owner}</span></td>
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-1.5 opacity-0 group-hover:opacity-100 transition-all">
                        <button className={`w-7 h-7 rounded-lg border flex items-center justify-center hover:text-indigo-400 ${t.btnIcon}`}><TrendingUp size={12} /></button>
                        <button className={`w-7 h-7 rounded-lg border flex items-center justify-center ${t.btnIcon}`}><MoreHorizontal size={12} /></button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
