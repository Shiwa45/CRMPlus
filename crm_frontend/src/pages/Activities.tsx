import { Phone, Mail, Calendar, CheckCircle, FileText, UserPlus, Plus, Filter } from "lucide-react";
import { activities, contacts } from "../data/mockData";
import { useTheme } from "../context/ThemeContext";
import { themeClasses } from "../utils/themeClasses";

const typeConfig: Record<string, { icon: any; darkColor: string; lightColor: string; label: string }> = {
  call:    { icon: Phone,     darkColor: "bg-blue-500/15 text-blue-400 border-blue-500/25",    lightColor: "bg-blue-50 text-blue-600 border-blue-200",    label: "Call" },
  email:   { icon: Mail,      darkColor: "bg-violet-500/15 text-violet-400 border-violet-500/25", lightColor: "bg-violet-50 text-violet-600 border-violet-200", label: "Email" },
  deal:    { icon: CheckCircle, darkColor: "bg-emerald-500/15 text-emerald-400 border-emerald-500/25", lightColor: "bg-emerald-50 text-emerald-600 border-emerald-200", label: "Deal" },
  note:    { icon: FileText,  darkColor: "bg-amber-500/15 text-amber-400 border-amber-500/25",  lightColor: "bg-amber-50 text-amber-600 border-amber-200",  label: "Note" },
  meeting: { icon: Calendar,  darkColor: "bg-cyan-500/15 text-cyan-400 border-cyan-500/25",    lightColor: "bg-cyan-50 text-cyan-600 border-cyan-200",    label: "Meeting" },
  contact: { icon: UserPlus,  darkColor: "bg-pink-500/15 text-pink-400 border-pink-500/25",    lightColor: "bg-pink-50 text-pink-600 border-pink-200",    label: "Contact" },
};

const avatarColors = [
  "from-indigo-500 to-violet-600","from-cyan-500 to-blue-600","from-emerald-500 to-teal-600",
  "from-amber-500 to-orange-600","from-pink-500 to-rose-600","from-violet-500 to-purple-600",
];

export default function Activities() {
  const { theme } = useTheme();
  const isDark = theme === "dark";
  const t = themeClasses(isDark);

  return (
    <div className="p-4 sm:p-6 space-y-5 sm:space-y-6">
      {/* Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 sm:gap-4">
        {[
          { label: "Calls Today",  value: "24", color: "text-blue-500" },
          { label: "Emails Sent",  value: "76", color: "text-violet-500" },
          { label: "Meetings",     value: "8",  color: "text-cyan-500" },
          { label: "Deals Moved",  value: "5",  color: "text-emerald-500" },
        ].map((s) => (
          <div key={s.label} className={`rounded-xl p-4 border ${t.card}`}>
            <p className={`text-2xl font-bold ${s.color}`}>{s.value}</p>
            <p className={`text-xs mt-1 ${t.textMuted}`}>{s.label}</p>
          </div>
        ))}
      </div>

      {/* Toolbar */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex flex-wrap gap-2">
          {["All","Calls","Emails","Meetings","Deals","Notes"].map((tab, i) => (
            <button key={tab} className={`text-sm px-3 py-1.5 rounded-lg transition-all ${i === 0 ? t.tabActive : t.tabInactive}`}>
              {tab}
            </button>
          ))}
        </div>
        <div className="flex gap-2">
          <button className={`flex items-center gap-2 text-sm px-3 py-2 rounded-lg border transition-all ${t.btnGhost}`}>
            <Filter size={13} /> Filter
          </button>
          <button className="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-medium px-4 py-2 rounded-lg transition-all">
            <Plus size={14} /> Log Activity
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        {/* Timeline */}
        <div className={`xl:col-span-2 rounded-xl p-4 sm:p-5 border ${t.card}`}>
          <h3 className={`font-semibold mb-5 ${t.textPrimary}`}>Activity Timeline</h3>
          <div className="relative">
            <div className={`absolute left-5 top-0 bottom-0 w-px ${isDark ? "bg-[#1e2130]" : "bg-slate-100"}`} />
            <div className="space-y-5 pl-14">
              {[...activities, ...activities].slice(0, 10).map((act, i) => {
                const cfg = typeConfig[act.type];
                const Icon = cfg.icon;
                const colorClass = isDark ? cfg.darkColor : cfg.lightColor;
                return (
                  <div key={`${act.id}-${i}`} className="relative">
                    <div className={`absolute -left-9 w-8 h-8 rounded-lg border flex items-center justify-center ${colorClass}`}>
                      <Icon size={14} />
                    </div>
                    <div className={`rounded-xl p-4 border cursor-pointer transition-all ${isDark ? "bg-[#1a1d2e] border-[#1e2130] hover:border-indigo-500/30" : "bg-slate-50 border-slate-100 hover:border-indigo-200"}`}>
                      <p className={`text-sm ${t.textSub}`}>
                        <span className={`font-semibold ${t.textPrimary}`}>{act.user}</span>{" "}
                        <span>{act.action}</span>{" "}
                        <span className="text-indigo-500 font-medium">{act.target}</span>
                      </p>
                      <div className="flex items-center gap-3 mt-1">
                        <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-full border ${colorClass}`}>
                          {cfg.label}
                        </span>
                        <span className={`text-xs ${t.textMuted}`}>{act.time}</span>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        {/* Sidebar panels */}
        <div className="space-y-4">
          {/* Activity breakdown */}
          <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
            <h3 className={`font-semibold mb-4 ${t.textPrimary}`}>Activity Breakdown</h3>
            <div className="space-y-3">
              {[
                { label: "Calls",       count: 24, pct: 76,  color: "bg-blue-500" },
                { label: "Emails",      count: 76, pct: 100, color: "bg-violet-500" },
                { label: "Meetings",    count: 8,  pct: 26,  color: "bg-cyan-500" },
                { label: "Deals Moved", count: 5,  pct: 16,  color: "bg-emerald-500" },
                { label: "Notes Added", count: 12, pct: 38,  color: "bg-amber-500" },
              ].map((item) => (
                <div key={item.label}>
                  <div className="flex items-center justify-between mb-1">
                    <span className={`text-sm ${t.textSub}`}>{item.label}</span>
                    <span className={`text-sm font-bold ${t.textPrimary}`}>{item.count}</span>
                  </div>
                  <div className={`w-full rounded-full h-2 ${isDark ? "bg-[#1a1d2e]" : "bg-slate-100"}`}>
                    <div className={`h-2 rounded-full ${item.color}`} style={{ width: `${item.pct}%` }} />
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Follow-up Queue */}
          <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
            <h3 className={`font-semibold mb-4 ${t.textPrimary}`}>Follow-up Queue</h3>
            <div className="space-y-3">
              {contacts.slice(0, 4).map((c, i) => (
                <div key={c.id} className={`flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-all ${isDark ? "bg-[#1a1d2e] border-[#1e2130] hover:border-indigo-500/30" : "bg-slate-50 border-slate-100 hover:border-indigo-200"}`}>
                  <div className={`w-8 h-8 rounded-full bg-gradient-to-br ${avatarColors[i % avatarColors.length]} flex items-center justify-center text-white text-xs font-bold shrink-0`}>
                    {c.avatar}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className={`text-sm font-medium truncate ${t.textPrimary}`}>{c.name}</p>
                    <p className={`text-xs truncate ${t.textMuted}`}>{c.company}</p>
                  </div>
                  <button className="shrink-0 w-7 h-7 rounded-lg bg-indigo-600/20 border border-indigo-500/30 flex items-center justify-center text-indigo-400 hover:bg-indigo-600 hover:text-white transition-all">
                    <Phone size={12} />
                  </button>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
