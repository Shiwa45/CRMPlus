import { Download, FileText, TrendingUp, Users, Briefcase, BarChart3 } from "lucide-react";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  AreaChart, Area
} from "recharts";
import { revenueData } from "../data/mockData";
import { useTheme } from "../context/ThemeContext";
import { themeClasses } from "../utils/themeClasses";

const reports = [
  { icon: TrendingUp, title: "Revenue Report",     desc: "Monthly revenue breakdown, target vs actual",    updated: "Dec 24, 2024", type: "Financial", darkColor: "bg-indigo-500/10 text-indigo-400 border-indigo-500/20",   lightColor: "bg-indigo-50 text-indigo-600 border-indigo-200" },
  { icon: Users,      title: "Contacts Report",    desc: "New contacts, churn rate, demographics",         updated: "Dec 23, 2024", type: "CRM",       darkColor: "bg-violet-500/10 text-violet-400 border-violet-500/20",   lightColor: "bg-violet-50 text-violet-600 border-violet-200" },
  { icon: Briefcase,  title: "Deals Pipeline",     desc: "Pipeline value, stage distribution, velocity",  updated: "Dec 22, 2024", type: "Sales",     darkColor: "bg-cyan-500/10 text-cyan-400 border-cyan-500/20",         lightColor: "bg-cyan-50 text-cyan-600 border-cyan-200" },
  { icon: BarChart3,  title: "Activity Report",    desc: "Calls, emails, meetings per rep",               updated: "Dec 21, 2024", type: "Activity",  darkColor: "bg-emerald-500/10 text-emerald-400 border-emerald-500/20", lightColor: "bg-emerald-50 text-emerald-600 border-emerald-200" },
  { icon: TrendingUp, title: "Conversion Funnel",  desc: "Lead to close conversion at each stage",        updated: "Dec 20, 2024", type: "Analytics", darkColor: "bg-amber-500/10 text-amber-400 border-amber-500/20",      lightColor: "bg-amber-50 text-amber-600 border-amber-200" },
  { icon: Users,      title: "Team Performance",   desc: "Individual rep KPIs and rankings",              updated: "Dec 19, 2024", type: "HR",        darkColor: "bg-pink-500/10 text-pink-400 border-pink-500/20",         lightColor: "bg-pink-50 text-pink-600 border-pink-200" },
];

const quarterlyData = [
  { name: "Q1", revenue: 140000, deals: 59 },
  { name: "Q2", revenue: 193000, deals: 82 },
  { name: "Q3", revenue: 225000, deals: 92 },
  { name: "Q4", revenue: 285000, deals: 124 },
];

export default function Reports() {
  const { theme } = useTheme();
  const isDark = theme === "dark";
  const t = themeClasses(isDark);

  return (
    <div className="p-4 sm:p-6 space-y-5 sm:space-y-6">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex flex-wrap gap-2">
          {["All Reports","Scheduled","Custom"].map((tab, i) => (
            <button key={tab} className={`text-sm px-3 py-1.5 rounded-lg transition-all ${i === 0 ? t.tabActive : t.tabInactive}`}>
              {tab}
            </button>
          ))}
        </div>
        <button className="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-medium px-4 py-2 rounded-lg transition-all">
          <FileText size={14} /> Create Report
        </button>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
        <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className={`font-semibold ${t.textPrimary}`}>Quarterly Revenue</h3>
              <p className={`text-xs ${t.textMuted}`}>2024 performance</p>
            </div>
            <button className={`flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-lg border transition-all ${t.btnGhost}`}>
              <Download size={12} /> Export
            </button>
          </div>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={quarterlyData} barSize={40} margin={{ top: 0, right: 0, left: -20, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke={t.chartGrid} vertical={false} />
              <XAxis dataKey="name" tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} tickFormatter={(v) => `$${v / 1000}k`} />
              <Tooltip contentStyle={{ background: t.tooltipBg, border: `1px solid ${t.tooltipBorder}`, borderRadius: "8px", color: t.tooltipText }} formatter={(v: any) => [`$${Number(v).toLocaleString()}`, "Revenue"]} />
              <Bar dataKey="revenue" fill="#6366f1" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className={`font-semibold ${t.textPrimary}`}>Monthly Revenue Trend</h3>
              <p className={`text-xs ${t.textMuted}`}>12-month overview</p>
            </div>
            <button className={`flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-lg border transition-all ${t.btnGhost}`}>
              <Download size={12} /> Export
            </button>
          </div>
          <ResponsiveContainer width="100%" height={200}>
            <AreaChart data={revenueData} margin={{ top: 0, right: 0, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="rg" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%"  stopColor="#34d399" stopOpacity={0.25} />
                  <stop offset="95%" stopColor="#34d399" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke={t.chartGrid} />
              <XAxis dataKey="month" tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} tickFormatter={(v) => `$${v / 1000}k`} />
              <Tooltip contentStyle={{ background: t.tooltipBg, border: `1px solid ${t.tooltipBorder}`, borderRadius: "8px", color: t.tooltipText }} formatter={(v: any) => [`$${Number(v).toLocaleString()}`, "Revenue"]} />
              <Area type="monotone" dataKey="revenue" stroke="#34d399" strokeWidth={2} fill="url(#rg)" dot={false} />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Report Cards */}
      <div>
        <h3 className={`font-semibold mb-4 ${t.textPrimary}`}>Available Reports</h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {reports.map((r) => {
            const Icon = r.icon;
            const colorClass = isDark ? r.darkColor : r.lightColor;
            return (
              <div key={r.title} className={`rounded-xl p-5 border cursor-pointer transition-all group ${t.card} ${t.cardHover}`}>
                <div className="flex items-start justify-between mb-4">
                  <div className={`w-10 h-10 rounded-xl border flex items-center justify-center ${colorClass}`}>
                    <Icon size={18} />
                  </div>
                  <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-full border ${colorClass}`}>{r.type}</span>
                </div>
                <h4 className={`font-semibold ${t.textPrimary}`}>{r.title}</h4>
                <p className={`text-xs mt-1 ${t.textMuted}`}>{r.desc}</p>
                <div className={`flex items-center justify-between mt-4 pt-4 border-t ${t.divider}`}>
                  <span className={`text-[11px] ${t.textTiny}`}>Updated {r.updated}</span>
                  <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-all">
                    <button className={`w-7 h-7 rounded-lg border flex items-center justify-center hover:text-indigo-400 ${t.btnIcon}`}><Download size={12} /></button>
                    <button className={`w-7 h-7 rounded-lg border flex items-center justify-center ${t.btnIcon}`}><FileText size={12} /></button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Schedule Reports */}
      <div className={`rounded-xl p-5 sm:p-6 border ${t.card}`}>
        <h3 className={`font-semibold mb-4 ${t.textPrimary}`}>Schedule Reports</h3>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {[
            { label: "Daily Digest",   desc: "Sent every morning at 8 AM",      active: true },
            { label: "Weekly Summary", desc: "Sent every Monday at 9 AM",       active: true },
            { label: "Monthly Report", desc: "Sent on the 1st of each month",   active: false },
          ].map((s) => (
            <div key={s.label} className={`p-4 rounded-xl border transition-all ${
              s.active
                ? "border-indigo-500/30 bg-indigo-600/5"
                : isDark ? "border-[#2e3247] bg-[#1a1d2e]" : "border-slate-200 bg-slate-50"
            }`}>
              <div className="flex items-center justify-between mb-2">
                <p className={`text-sm font-semibold ${t.textPrimary}`}>{s.label}</p>
                <button className={`relative w-10 h-5 rounded-full transition-all ${s.active ? "bg-indigo-600" : isDark ? "bg-[#2e3247]" : "bg-slate-200"}`}>
                  <span className={`absolute top-0.5 w-4 h-4 rounded-full bg-white shadow transition-all ${s.active ? "left-5" : "left-0.5"}`} />
                </button>
              </div>
              <p className={`text-xs ${t.textMuted}`}>{s.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
