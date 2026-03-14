import {
  AreaChart, Area, BarChart, Bar, LineChart, Line, XAxis, YAxis,
  CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell
} from "recharts";
import { DollarSign, Users, Briefcase, TrendingUp, Phone, Mail, Calendar, CheckCircle, Clock, ArrowRight, Star } from "lucide-react";
import StatCard from "../components/StatCard";
import { revenueData, pipelineData, leadSourceData, activities, tasks, weeklyActivity } from "../data/mockData";
import { useTheme } from "../context/ThemeContext";
import { themeClasses } from "../utils/themeClasses";

const activityIcons: Record<string, any> = {
  phone: <Phone size={14} />, mail: <Mail size={14} />,
  "check-circle": <CheckCircle size={14} />, "file-text": <Calendar size={14} />,
  calendar: <Calendar size={14} />, "user-plus": <Users size={14} />,
};
const activityColors: Record<string, string> = {
  call: "bg-blue-500/20 text-blue-400", email: "bg-violet-500/20 text-violet-400",
  deal: "bg-emerald-500/20 text-emerald-400", note: "bg-amber-500/20 text-amber-400",
  meeting: "bg-cyan-500/20 text-cyan-400", contact: "bg-pink-500/20 text-pink-400",
};
const priorityColors: Record<string, string> = {
  high:   "bg-red-500/15 text-red-400 border-red-500/30",
  medium: "bg-amber-500/15 text-amber-400 border-amber-500/30",
  low:    "bg-gray-500/15 text-gray-400 border-gray-500/30",
};
const priorityColorsLight: Record<string, string> = {
  high:   "bg-red-50 text-red-500 border-red-200",
  medium: "bg-amber-50 text-amber-600 border-amber-200",
  low:    "bg-slate-50 text-slate-500 border-slate-200",
};

export default function Dashboard() {
  const { theme } = useTheme();
  const isDark = theme === "dark";
  const t = themeClasses(isDark);

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      return (
        <div className={`rounded-lg p-3 shadow-xl border ${isDark ? "bg-[#1a1d2e] border-[#2e3247]" : "bg-white border-slate-200"}`}>
          <p className={`text-xs mb-1 ${t.textMuted}`}>{label}</p>
          {payload.map((p: any) => (
            <p key={p.name} className="text-sm font-semibold" style={{ color: p.color }}>
              {p.name}: {typeof p.value === "number" && p.name.toLowerCase().includes("revenue") ? `$${p.value.toLocaleString()}` : p.value}
            </p>
          ))}
        </div>
      );
    }
    return null;
  };

  return (
    <div className="p-4 sm:p-6 space-y-5 sm:space-y-6">
      {/* Stat Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
        <StatCard title="Total Revenue" value="$924,600" change="+18.4%" positive={true}
          icon={<DollarSign size={18} className="text-indigo-400" />}
          iconBg="bg-indigo-500/10" subtitle="vs last year" />
        <StatCard title="Active Contacts" value="1,284" change="+9.2%" positive={true}
          icon={<Users size={18} className="text-violet-400" />}
          iconBg="bg-violet-500/10" subtitle="Total in pipeline" />
        <StatCard title="Open Deals" value="87" change="-3.1%" positive={false}
          icon={<Briefcase size={18} className="text-cyan-400" />}
          iconBg="bg-cyan-500/10" subtitle="Worth $2.4M total" />
        <StatCard title="Conversion Rate" value="34.8%" change="+5.6%" positive={true}
          icon={<TrendingUp size={18} className="text-emerald-400" />}
          iconBg="bg-emerald-500/10" subtitle="Lead to close" />
      </div>

      {/* Revenue Chart + Lead Source */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-4">
        <div className={`xl:col-span-2 rounded-xl p-4 sm:p-5 border ${t.card}`}>
          <div className="flex flex-wrap items-center justify-between gap-2 mb-5">
            <div>
              <h3 className={`font-semibold ${t.textPrimary}`}>Revenue Overview</h3>
              <p className={`text-xs mt-0.5 ${t.textMuted}`}>Monthly revenue vs target</p>
            </div>
            <div className="flex gap-4 text-xs">
              <div className={`flex items-center gap-1.5 ${t.textSub}`}>
                <span className="w-3 h-3 rounded-full bg-indigo-500" />Revenue
              </div>
              <div className={`flex items-center gap-1.5 ${t.textSub}`}>
                <span className="w-3 h-3 rounded-full bg-violet-400/50" />Target
              </div>
            </div>
          </div>
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={revenueData} margin={{ top: 0, right: 0, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%"  stopColor="#6366f1" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#6366f1" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="colorTarget" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%"  stopColor="#8b5cf6" stopOpacity={0.15} />
                  <stop offset="95%" stopColor="#8b5cf6" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke={t.chartGrid} />
              <XAxis dataKey="month" tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} tickFormatter={(v) => `$${v / 1000}k`} />
              <Tooltip content={<CustomTooltip />} />
              <Area type="monotone" dataKey="revenue" name="Revenue" stroke="#6366f1" strokeWidth={2} fill="url(#colorRevenue)" dot={false} />
              <Area type="monotone" dataKey="target"  name="Target"  stroke="#8b5cf6" strokeWidth={2} strokeDasharray="5 5" fill="url(#colorTarget)" dot={false} />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Lead Source Pie */}
        <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
          <div className="mb-5">
            <h3 className={`font-semibold ${t.textPrimary}`}>Lead Sources</h3>
            <p className={`text-xs mt-0.5 ${t.textMuted}`}>Where leads come from</p>
          </div>
          <ResponsiveContainer width="100%" height={160}>
            <PieChart>
              <Pie data={leadSourceData} cx="50%" cy="50%" innerRadius={50} outerRadius={75} paddingAngle={3} dataKey="value">
                {leadSourceData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} stroke="transparent" />
                ))}
              </Pie>
              <Tooltip formatter={(value) => [`${value}%`, ""]} contentStyle={{ background: t.tooltipBg, border: `1px solid ${t.tooltipBorder}`, borderRadius: "8px", color: t.tooltipText }} />
            </PieChart>
          </ResponsiveContainer>
          <div className="space-y-2 mt-2">
            {leadSourceData.map((item) => (
              <div key={item.name} className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="w-2.5 h-2.5 rounded-full shrink-0" style={{ backgroundColor: item.color }} />
                  <span className={`text-xs ${t.textSub}`}>{item.name}</span>
                </div>
                <span className={`text-xs font-semibold ${t.textPrimary}`}>{item.value}%</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Pipeline + Weekly Activity + Tasks */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-4">
        {/* Pipeline */}
        <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
          <div className="flex items-center justify-between mb-5">
            <div>
              <h3 className={`font-semibold ${t.textPrimary}`}>Sales Pipeline</h3>
              <p className={`text-xs mt-0.5 ${t.textMuted}`}>Stage distribution</p>
            </div>
            <button className="text-indigo-400 text-xs hover:text-indigo-300 flex items-center gap-1">
              View all <ArrowRight size={12} />
            </button>
          </div>
          <div className="space-y-3">
            {pipelineData.map((stage) => {
              const pct = Math.round((stage.value / pipelineData[0].value) * 100);
              return (
                <div key={stage.name}>
                  <div className="flex items-center justify-between mb-1">
                    <span className={`text-xs ${t.textSub}`}>{stage.name}</span>
                    <span className={`text-xs font-semibold ${t.textPrimary}`}>{stage.value}</span>
                  </div>
                  <div className={`w-full rounded-full h-2 ${isDark ? "bg-[#1a1d2e]" : "bg-slate-100"}`}>
                    <div className="h-2 rounded-full transition-all" style={{ width: `${pct}%`, backgroundColor: stage.color }} />
                  </div>
                </div>
              );
            })}
          </div>
          <div className={`mt-5 pt-4 border-t ${t.divider} grid grid-cols-2 gap-4`}>
            <div>
              <p className={`text-2xl font-bold ${t.textPrimary}`}>$2.4M</p>
              <p className={`text-xs ${t.textMuted}`}>Pipeline value</p>
            </div>
            <div>
              <p className={`text-2xl font-bold ${t.textPrimary}`}>310</p>
              <p className={`text-xs ${t.textMuted}`}>Total leads</p>
            </div>
          </div>
        </div>

        {/* Weekly Activity */}
        <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
          <div className="flex items-center justify-between mb-5">
            <div>
              <h3 className={`font-semibold ${t.textPrimary}`}>Weekly Activity</h3>
              <p className={`text-xs mt-0.5 ${t.textMuted}`}>Calls · Emails · Meetings</p>
            </div>
          </div>
          <ResponsiveContainer width="100%" height={180}>
            <BarChart data={weeklyActivity} barSize={6} margin={{ top: 0, right: 0, left: -30, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke={t.chartGrid} vertical={false} />
              <XAxis dataKey="day" tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} />
              <Tooltip content={<CustomTooltip />} />
              <Bar dataKey="calls"    name="Calls"    fill="#6366f1" radius={[3, 3, 0, 0]} />
              <Bar dataKey="emails"   name="Emails"   fill="#8b5cf6" radius={[3, 3, 0, 0]} />
              <Bar dataKey="meetings" name="Meetings" fill="#34d399" radius={[3, 3, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
          <div className="flex gap-4 mt-3 justify-center">
            {[["Calls","#6366f1"],["Emails","#8b5cf6"],["Meetings","#34d399"]].map(([name, color]) => (
              <div key={name} className={`flex items-center gap-1.5 text-xs ${t.textSub}`}>
                <span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: color }} />{name}
              </div>
            ))}
          </div>
        </div>

        {/* Tasks */}
        <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
          <div className="flex items-center justify-between mb-5">
            <div>
              <h3 className={`font-semibold ${t.textPrimary}`}>Upcoming Tasks</h3>
              <p className={`text-xs mt-0.5 ${t.textMuted}`}>{tasks.filter(t => !t.done).length} pending</p>
            </div>
            <button className="text-indigo-400 text-xs hover:text-indigo-300 flex items-center gap-1">
              View all <ArrowRight size={12} />
            </button>
          </div>
          <div className="space-y-3">
            {tasks.map((task) => {
              const pc = isDark ? priorityColors[task.priority] : priorityColorsLight[task.priority];
              return (
                <div key={task.id} className={`flex items-start gap-3 p-3 rounded-lg border transition-all ${
                  task.done
                    ? `opacity-50 ${t.divider} bg-transparent`
                    : `${isDark ? "border-[#1e2130] bg-[#1a1d2e]" : "border-slate-100 bg-slate-50"} ${t.cardHover}`
                }`}>
                  <div className={`w-4 h-4 rounded border mt-0.5 shrink-0 flex items-center justify-center ${
                    task.done ? "bg-emerald-500 border-emerald-500" : isDark ? "border-gray-600" : "border-slate-300"
                  }`}>
                    {task.done && <CheckCircle size={12} className="text-white" />}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className={`text-sm ${task.done ? `line-through ${t.textMuted}` : t.textPrimary}`}>{task.title}</p>
                    <div className="flex items-center gap-2 mt-1">
                      <Clock size={11} className={t.textTiny} />
                      <span className={`text-[11px] ${t.textTiny}`}>{task.due}</span>
                    </div>
                  </div>
                  <span className={`text-[10px] font-semibold px-1.5 py-0.5 rounded border capitalize ${pc}`}>
                    {task.priority}
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Recent Activities */}
      <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
        <div className="flex items-center justify-between mb-5">
          <div>
            <h3 className={`font-semibold ${t.textPrimary}`}>Recent Activity</h3>
            <p className={`text-xs mt-0.5 ${t.textMuted}`}>Team interactions and updates</p>
          </div>
          <button className="text-indigo-400 text-xs hover:text-indigo-300 flex items-center gap-1">
            View all <ArrowRight size={12} />
          </button>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
          {activities.map((act) => (
            <div key={act.id} className={`flex items-start gap-3 p-3 rounded-lg border ${isDark ? "bg-[#1a1d2e] border-[#1e2130]" : "bg-slate-50 border-slate-100"}`}>
              <div className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${activityColors[act.type]}`}>
                {activityIcons[act.icon]}
              </div>
              <div>
                <p className={`text-sm ${t.textSub}`}>
                  <span className={`font-medium ${t.textPrimary}`}>{act.user}</span>{" "}
                  {act.action}{" "}
                  <span className="text-indigo-400">{act.target}</span>
                </p>
                <p className={`text-[11px] mt-0.5 ${t.textTiny}`}>{act.time}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Deals Line + Leaderboard */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
        <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
          <div className="flex items-center justify-between mb-5">
            <div>
              <h3 className={`font-semibold ${t.textPrimary}`}>Deals Closed</h3>
              <p className={`text-xs mt-0.5 ${t.textMuted}`}>Monthly closed deals trend</p>
            </div>
            <div className="bg-emerald-500/10 text-emerald-400 text-xs font-semibold px-2 py-1 rounded-full">+22% YTD</div>
          </div>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={revenueData} margin={{ top: 0, right: 0, left: -20, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke={t.chartGrid} />
              <XAxis dataKey="month" tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: t.chartTick, fontSize: 11 }} axisLine={false} tickLine={false} />
              <Tooltip content={<CustomTooltip />} />
              <Line type="monotone" dataKey="deals" name="Deals" stroke="#34d399" strokeWidth={2.5} dot={{ fill: "#34d399", strokeWidth: 0, r: 4 }} activeDot={{ r: 6 }} />
            </LineChart>
          </ResponsiveContainer>
        </div>

        <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
          <div className="flex items-center justify-between mb-5">
            <div>
              <h3 className={`font-semibold ${t.textPrimary}`}>Top Performers</h3>
              <p className={`text-xs mt-0.5 ${t.textMuted}`}>This month's leaderboard</p>
            </div>
            <Star size={16} className="text-amber-400" />
          </div>
          <div className="space-y-3">
            {[
              { rank: 1, name: "Alex Turner",  deals: 14, revenue: "$284,000", avatar: "AT", color: "from-amber-500 to-orange-600" },
              { rank: 2, name: "Mia Chen",     deals: 11, revenue: "$196,500", avatar: "MC", color: "from-indigo-500 to-violet-600" },
              { rank: 3, name: "Jordan Lee",   deals: 9,  revenue: "$142,000", avatar: "JL", color: "from-emerald-500 to-teal-600" },
              { rank: 4, name: "Priya Sharma", deals: 7,  revenue: "$98,400",  avatar: "PS", color: "from-pink-500 to-rose-600" },
            ].map((member) => (
              <div key={member.rank} className={`flex items-center gap-3 p-3 rounded-lg border transition-all ${isDark ? "bg-[#1a1d2e] border-[#1e2130]" : "bg-slate-50 border-slate-100"} ${t.cardHover}`}>
                <span className={`text-xs font-bold w-5 ${member.rank === 1 ? "text-amber-400" : t.textMuted}`}>#{member.rank}</span>
                <div className={`w-8 h-8 rounded-full bg-gradient-to-br ${member.color} flex items-center justify-center text-white text-xs font-bold shrink-0`}>
                  {member.avatar}
                </div>
                <div className="flex-1">
                  <p className={`text-sm font-medium ${t.textPrimary}`}>{member.name}</p>
                  <p className={`text-[11px] ${t.textMuted}`}>{member.deals} deals closed</p>
                </div>
                <span className="text-sm font-semibold text-emerald-500">{member.revenue}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
