import {
  AreaChart, Area, BarChart, Bar, LineChart, Line,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, RadarChart, Radar, PolarGrid,
  PolarAngleAxis, PolarRadiusAxis
} from "recharts";
import { revenueData, pipelineData, leadSourceData, teamMembers, weeklyActivity } from "../data/mockData";
import { TrendingUp, TrendingDown, BarChart3 } from "lucide-react";
import { useTheme } from "../context/ThemeContext";
import { themeClasses } from "../utils/themeClasses";

const radarData = [
  { subject: "Calls",       A: 82, B: 65 },
  { subject: "Emails",      A: 91, B: 74 },
  { subject: "Meetings",    A: 68, B: 80 },
  { subject: "Conversions", A: 75, B: 58 },
  { subject: "Retention",   A: 88, B: 70 },
  { subject: "Upsell",      A: 60, B: 72 },
];

export default function Analytics() {
  const { theme } = useTheme();
  const isDark = theme === "dark";
  const t = themeClasses(isDark);

  const TooltipComp = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      return (
        <div className={`rounded-lg p-3 shadow-xl border ${isDark ? "bg-[#1a1d2e] border-[#2e3247]" : "bg-white border-slate-200"}`}>
          <p className={`text-xs mb-1 ${t.textMuted}`}>{label}</p>
          {payload.map((p: any) => (
            <p key={p.name} className="text-sm font-semibold" style={{ color: p.color }}>
              {p.name}: {p.dataKey === "revenue" ? `$${Number(p.value).toLocaleString()}` : p.value}
            </p>
          ))}
        </div>
      );
    }
    return null;
  };

  const barBg = isDark ? "bg-[#1a1d2e]" : "bg-slate-100";

  return (
    <div className="p-4 sm:p-6 space-y-5 sm:space-y-6">
      {/* KPI Row */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
        {[
          { label: "Customer Lifetime Value", value: "$8,420", change: "+12.4%", positive: true },
          { label: "Customer Acq. Cost",      value: "$620",   change: "-8.2%",  positive: true },
          { label: "Churn Rate",              value: "3.2%",   change: "+0.4%",  positive: false },
          { label: "Net Promoter Score",      value: "74",     change: "+6pts",  positive: true },
        ].map((k) => (
          <div key={k.label} className={`rounded-xl p-5 border ${t.card}`}>
            <div className="flex items-center justify-between mb-3">
              <p className={`text-xs ${t.textMuted}`}>{k.label}</p>
              <span className={`flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-full ${k.positive ? "bg-emerald-500/10 text-emerald-500" : "bg-red-500/10 text-red-500"}`}>
                {k.positive ? <TrendingUp size={10} /> : <TrendingDown size={10} />}{k.change}
              </span>
            </div>
            <p className={`text-2xl font-bold ${t.textPrimary}`}>{k.value}</p>
          </div>
        ))}
      </div>

      {/* Revenue + Pipeline */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-4">
        <div className={`xl:col-span-2 rounded-xl p-4 sm:p-5 border ${t.card}`}>
          <div className="flex flex-wrap items-center justify-between gap-2 mb-5">
            <div>
              <h3 className={`font-semibold ${t.textPrimary}`}>Revenue vs Target</h3>
              <p className={`text-xs mt-0.5 ${t.textMuted}`}>Full year performance</p>
            </div>
            <div className={`flex gap-3 text-xs ${t.textSub}`}>
              <span className="flex items-center gap-1"><span className="w-3 h-0.5 bg-indigo-500 inline-block" />Revenue</span>
              <span className="flex items-center gap-1"><span className="w-3 h-0.5 bg-violet-400 inline-block" />Target</span>
            </div>
          </div>
          <ResponsiveContainer width="100%" height={250}>
            <AreaChart data={revenueData} margin={{ top: 0, right: 0, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="g1" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%"  stopColor="#6366f1" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#6366f1" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="g2" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%"  stopColor="#8b5cf6" stopOpacity={0.15} />
                  <stop offset="95%" stopColor="#8b5cf6" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke={t.chartGrid} />
              <XAxis dataKey="month" tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} tickFormatter={(v) => `$${v / 1000}k`} />
              <Tooltip content={<TooltipComp />} />
              <Area type="monotone" dataKey="revenue" name="Revenue" stroke="#6366f1" strokeWidth={2} fill="url(#g1)" dot={false} />
              <Area type="monotone" dataKey="target"  name="Target"  stroke="#8b5cf6" strokeWidth={2} strokeDasharray="5 5" fill="url(#g2)" dot={false} />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
          <div className="mb-4">
            <h3 className={`font-semibold ${t.textPrimary}`}>Pipeline Breakdown</h3>
            <p className={`text-xs mt-0.5 ${t.textMuted}`}>By stage distribution</p>
          </div>
          <ResponsiveContainer width="100%" height={200}>
            <PieChart>
              <Pie data={pipelineData} cx="50%" cy="50%" outerRadius={80} innerRadius={50} paddingAngle={3} dataKey="value">
                {pipelineData.map((entry, i) => <Cell key={i} fill={entry.color} stroke="transparent" />)}
              </Pie>
              <Tooltip contentStyle={{ background: t.tooltipBg, border: `1px solid ${t.tooltipBorder}`, borderRadius: "8px", color: t.tooltipText }} />
            </PieChart>
          </ResponsiveContainer>
          <div className="space-y-2 mt-2">
            {pipelineData.map((item) => (
              <div key={item.name} className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: item.color }} />
                  <span className={`text-xs ${t.textSub}`}>{item.name}</span>
                </div>
                <span className={`text-xs font-bold ${t.textPrimary}`}>{item.value}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Weekly Activity + Lead Sources + Radar */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
          <div className="mb-4">
            <h3 className={`font-semibold ${t.textPrimary}`}>Weekly Activity</h3>
            <p className={`text-xs mt-0.5 ${t.textMuted}`}>Calls, Emails, Meetings</p>
          </div>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={weeklyActivity} barSize={7} margin={{ top: 0, right: 0, left: -30, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke={t.chartGrid} vertical={false} />
              <XAxis dataKey="day" tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} />
              <Tooltip content={<TooltipComp />} />
              <Bar dataKey="calls"    name="Calls"    fill="#6366f1" radius={[3,3,0,0]} />
              <Bar dataKey="emails"   name="Emails"   fill="#8b5cf6" radius={[3,3,0,0]} />
              <Bar dataKey="meetings" name="Meetings" fill="#34d399" radius={[3,3,0,0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
          <div className="mb-4">
            <h3 className={`font-semibold ${t.textPrimary}`}>Lead Sources</h3>
            <p className={`text-xs mt-0.5 ${t.textMuted}`}>Acquisition channels</p>
          </div>
          <div className="space-y-4 mt-6">
            {leadSourceData.map((src) => (
              <div key={src.name}>
                <div className="flex items-center justify-between mb-1.5">
                  <div className="flex items-center gap-2">
                    <span className="w-2 h-2 rounded-full" style={{ backgroundColor: src.color }} />
                    <span className={`text-sm ${t.textSub}`}>{src.name}</span>
                  </div>
                  <span className={`text-sm font-bold ${t.textPrimary}`}>{src.value}%</span>
                </div>
                <div className={`w-full rounded-full h-2 ${barBg}`}>
                  <div className="h-2 rounded-full" style={{ width: `${src.value}%`, backgroundColor: src.color }} />
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
          <div className="mb-4">
            <h3 className={`font-semibold ${t.textPrimary}`}>Team Performance</h3>
            <p className={`text-xs mt-0.5 ${t.textMuted}`}>This month vs last month</p>
          </div>
          <ResponsiveContainer width="100%" height={220}>
            <RadarChart data={radarData} margin={{ top: 10, right: 20, bottom: 10, left: 20 }}>
              <PolarGrid stroke={t.chartGrid} />
              <PolarAngleAxis dataKey="subject" tick={{ fill: t.chartTick, fontSize: 10 }} />
              <PolarRadiusAxis tick={false} axisLine={false} />
              <Radar name="This Month" dataKey="A" stroke="#6366f1" fill="#6366f1" fillOpacity={0.2} />
              <Radar name="Last Month" dataKey="B" stroke="#8b5cf6" fill="#8b5cf6" fillOpacity={0.1} />
              <Tooltip contentStyle={{ background: t.tooltipBg, border: `1px solid ${t.tooltipBorder}`, borderRadius: "8px", color: t.tooltipText }} />
            </RadarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Team Table */}
      <div className={`rounded-xl overflow-hidden border ${t.card}`}>
        <div className={`px-5 py-4 border-b ${t.divider} flex items-center justify-between`}>
          <div>
            <h3 className={`font-semibold ${t.textPrimary}`}>Sales Rep Performance</h3>
            <p className={`text-xs mt-0.5 ${t.textMuted}`}>December 2024</p>
          </div>
          <button className={`flex items-center gap-2 text-xs px-3 py-1.5 rounded-lg border transition-all ${t.btnGhost}`}>
            <BarChart3 size={13} /> Export Report
          </button>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className={`border-b ${t.divider}`}>
                {["Rep","Role","Deals Closed","Revenue","Conversion","Status"].map(h => (
                  <th key={h} className={`text-left text-[11px] uppercase tracking-wider px-5 py-3 font-semibold ${t.thead}`}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {teamMembers.map((member, i) => (
                <tr key={member.id} className={`border-b transition-all ${t.trow}`}>
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-3">
                      <div className={`w-9 h-9 rounded-full flex items-center justify-center text-white text-xs font-bold ${
                        i === 0 ? "bg-gradient-to-br from-amber-500 to-orange-600" :
                        i === 1 ? "bg-gradient-to-br from-indigo-500 to-violet-600" :
                        i === 2 ? "bg-gradient-to-br from-emerald-500 to-teal-600" :
                        "bg-gradient-to-br from-pink-500 to-rose-600"
                      }`}>{member.avatar}</div>
                      <div>
                        <p className={`text-sm font-medium ${t.textPrimary}`}>{member.name}</p>
                        {i === 0 && <span className="text-[10px] text-amber-500">🏆 Top Performer</span>}
                      </div>
                    </div>
                  </td>
                  <td className="px-5 py-4"><span className={`text-sm ${t.textSub}`}>{member.role}</span></td>
                  <td className="px-5 py-4"><span className={`text-sm font-semibold ${t.textPrimary}`}>{member.deals}</span></td>
                  <td className="px-5 py-4"><span className="text-sm font-bold text-emerald-500">{member.revenue}</span></td>
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-2">
                      <div className={`w-20 rounded-full h-1.5 ${barBg}`}>
                        <div className="h-1.5 rounded-full bg-indigo-500" style={{ width: member.conversion }} />
                      </div>
                      <span className={`text-xs font-semibold ${t.textPrimary}`}>{member.conversion}</span>
                    </div>
                  </td>
                  <td className="px-5 py-4">
                    <span className={`text-xs font-semibold px-2 py-1 rounded-full border ${
                      member.status === "online" ? "bg-emerald-500/10 text-emerald-500 border-emerald-500/20" :
                      member.status === "away"   ? "bg-amber-500/10 text-amber-500 border-amber-500/20" :
                      isDark ? "bg-gray-500/10 text-gray-400 border-gray-500/20" : "bg-slate-100 text-slate-500 border-slate-200"
                    }`}>{member.status}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Deals Line + Conversions */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
        <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
          <div className="mb-4">
            <h3 className={`font-semibold ${t.textPrimary}`}>Monthly Deals Closed</h3>
            <p className={`text-xs mt-0.5 ${t.textMuted}`}>12-month trend</p>
          </div>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={revenueData} margin={{ top: 0, right: 0, left: -20, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke={t.chartGrid} />
              <XAxis dataKey="month" tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} />
              <Tooltip content={<TooltipComp />} />
              <Line type="monotone" dataKey="deals" name="Deals" stroke="#34d399" strokeWidth={2.5} dot={{ fill: "#34d399", r: 3, strokeWidth: 0 }} activeDot={{ r: 5 }} />
            </LineChart>
          </ResponsiveContainer>
        </div>

        <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
          <div className="mb-5">
            <h3 className={`font-semibold ${t.textPrimary}`}>Conversion Metrics</h3>
            <p className={`text-xs mt-0.5 ${t.textMuted}`}>Stage-to-stage drop-off</p>
          </div>
          <div className="space-y-4">
            {[
              { from: "Visitors → Leads",       rate: "12.4%", bar: 12 },
              { from: "Leads → Qualified",       rate: "68%",   bar: 68 },
              { from: "Qualified → Proposal",    rate: "54%",   bar: 54 },
              { from: "Proposal → Closed",       rate: "38%",   bar: 38 },
            ].map((m) => (
              <div key={m.from}>
                <div className="flex items-center justify-between mb-1">
                  <span className={`text-sm ${t.textSub}`}>{m.from}</span>
                  <span className={`text-sm font-bold ${t.textPrimary}`}>{m.rate}</span>
                </div>
                <div className={`w-full rounded-full h-2.5 ${barBg}`}>
                  <div className="h-2.5 rounded-full bg-gradient-to-r from-indigo-500 to-violet-500" style={{ width: `${m.bar}%` }} />
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
