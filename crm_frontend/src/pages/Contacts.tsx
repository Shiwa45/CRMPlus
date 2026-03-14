import { useState } from "react";
import { Search, Filter, Plus, MoreHorizontal, Mail, Phone, Star, ChevronDown, SlidersHorizontal } from "lucide-react";
import { contacts } from "../data/mockData";
import { useTheme } from "../context/ThemeContext";
import { themeClasses } from "../utils/themeClasses";

const stageColorsDark: Record<string, string> = {
  Lead:         "bg-gray-500/15 text-gray-400 border-gray-500/30",
  Qualified:    "bg-blue-500/15 text-blue-400 border-blue-500/30",
  Proposal:     "bg-violet-500/15 text-violet-400 border-violet-500/30",
  Negotiation:  "bg-amber-500/15 text-amber-400 border-amber-500/30",
  "Closed Won": "bg-emerald-500/15 text-emerald-400 border-emerald-500/30",
};
const stageColorsLight: Record<string, string> = {
  Lead:         "bg-slate-100 text-slate-500 border-slate-200",
  Qualified:    "bg-blue-50 text-blue-600 border-blue-200",
  Proposal:     "bg-violet-50 text-violet-600 border-violet-200",
  Negotiation:  "bg-amber-50 text-amber-600 border-amber-200",
  "Closed Won": "bg-emerald-50 text-emerald-600 border-emerald-200",
};

const avatarColors = [
  "from-indigo-500 to-violet-600","from-cyan-500 to-blue-600","from-emerald-500 to-teal-600",
  "from-amber-500 to-orange-600","from-pink-500 to-rose-600","from-violet-500 to-purple-600","from-sky-500 to-cyan-600",
];

export default function Contacts() {
  const [view, setView] = useState<"table" | "grid">("table");
  const [search, setSearch] = useState("");
  const { theme } = useTheme();
  const isDark = theme === "dark";
  const t = themeClasses(isDark);
  const stageColors = isDark ? stageColorsDark : stageColorsLight;

  const filtered = contacts.filter(c =>
    c.name.toLowerCase().includes(search.toLowerCase()) ||
    c.company.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="p-4 sm:p-6 space-y-4 sm:space-y-5">
      {/* Stats row */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 sm:gap-4">
        {[
          { label: "Total Contacts", value: "1,284", color: "text-indigo-500" },
          { label: "Active Leads",   value: "342",   color: "text-violet-500" },
          { label: "Converted",      value: "187",   color: "text-emerald-500" },
          { label: "This Month",     value: "+48",   color: "text-cyan-500" },
        ].map((s) => (
          <div key={s.label} className={`rounded-xl p-4 border ${t.card}`}>
            <p className={`text-2xl font-bold ${s.color}`}>{s.value}</p>
            <p className={`text-xs mt-1 ${t.textMuted}`}>{s.label}</p>
          </div>
        ))}
      </div>

      {/* Toolbar */}
      <div className="flex items-center gap-2 sm:gap-3 flex-wrap">
        <div className="relative flex-1 min-w-[160px]">
          <Search size={14} className={`absolute left-3 top-1/2 -translate-y-1/2 ${t.textMuted}`} />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search contacts..."
            className={`w-full rounded-lg pl-9 pr-4 py-2.5 text-sm border focus:outline-none ${t.input}`}
          />
        </div>
        <button className={`flex items-center gap-2 text-sm px-3 py-2.5 rounded-lg border transition-all ${t.btnGhost}`}>
          <Filter size={14} /> <span className="hidden sm:inline">Filter</span>
        </button>
        <button className={`hidden sm:flex items-center gap-2 text-sm px-3 py-2.5 rounded-lg border transition-all ${t.btnGhost}`}>
          <SlidersHorizontal size={14} /> Sort <ChevronDown size={12} />
        </button>
        <div className={`flex gap-1 rounded-lg p-1 border ${isDark ? "bg-[#13151f] border-[#1e2130]" : "bg-white border-slate-200"}`}>
          <button onClick={() => setView("table")} className={`px-3 py-1.5 text-xs rounded-md transition-all ${view === "table" ? t.tabActive : t.tabInactive}`}>Table</button>
          <button onClick={() => setView("grid")}  className={`px-3 py-1.5 text-xs rounded-md transition-all ${view === "grid"  ? t.tabActive : t.tabInactive}`}>Grid</button>
        </div>
        <button className="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-medium px-3 sm:px-4 py-2.5 rounded-lg transition-all ml-auto">
          <Plus size={14} /> <span className="hidden sm:inline">Add Contact</span>
        </button>
      </div>

      {view === "table" ? (
        <div className={`rounded-xl overflow-hidden border ${t.card}`}>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className={`border-b ${t.divider}`}>
                  <th className={`text-left text-[11px] uppercase tracking-wider px-5 py-3 font-semibold ${t.thead}`}>Contact</th>
                  <th className={`text-left text-[11px] uppercase tracking-wider px-5 py-3 font-semibold hidden md:table-cell ${t.thead}`}>Company</th>
                  <th className={`text-left text-[11px] uppercase tracking-wider px-5 py-3 font-semibold hidden lg:table-cell ${t.thead}`}>Email</th>
                  <th className={`text-left text-[11px] uppercase tracking-wider px-5 py-3 font-semibold hidden xl:table-cell ${t.thead}`}>Phone</th>
                  <th className={`text-left text-[11px] uppercase tracking-wider px-5 py-3 font-semibold ${t.thead}`}>Stage</th>
                  <th className={`text-left text-[11px] uppercase tracking-wider px-5 py-3 font-semibold hidden md:table-cell ${t.thead}`}>Value</th>
                  <th className={`text-left text-[11px] uppercase tracking-wider px-5 py-3 font-semibold hidden lg:table-cell ${t.thead}`}>Last Contact</th>
                  <th className="px-5 py-3" />
                </tr>
              </thead>
              <tbody>
                {filtered.map((c, i) => (
                  <tr key={c.id} className={`border-b transition-all cursor-pointer group ${t.trow}`}>
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <div className={`w-9 h-9 rounded-full bg-gradient-to-br ${avatarColors[i % avatarColors.length]} flex items-center justify-center text-white text-xs font-bold shrink-0`}>
                          {c.avatar}
                        </div>
                        <div>
                          <p className={`text-sm font-medium ${t.textPrimary}`}>{c.name}</p>
                          <div className={`w-1.5 h-1.5 rounded-full inline-block mr-1 ${c.status === "active" ? "bg-emerald-400" : "bg-gray-400"}`} />
                          <span className={`text-[11px] capitalize ${t.textMuted}`}>{c.status}</span>
                        </div>
                      </div>
                    </td>
                    <td className="px-5 py-4 hidden md:table-cell"><span className={`text-sm ${t.textSub}`}>{c.company}</span></td>
                    <td className="px-5 py-4 hidden lg:table-cell"><span className={`text-sm ${t.textSub}`}>{c.email}</span></td>
                    <td className="px-5 py-4 hidden xl:table-cell"><span className={`text-sm ${t.textSub}`}>{c.phone}</span></td>
                    <td className="px-5 py-4">
                      <span className={`text-[11px] font-semibold px-2 py-1 rounded-full border ${stageColors[c.stage]}`}>{c.stage}</span>
                    </td>
                    <td className="px-5 py-4 hidden md:table-cell"><span className={`text-sm font-semibold ${t.textPrimary}`}>{c.value}</span></td>
                    <td className="px-5 py-4 hidden lg:table-cell"><span className={`text-xs ${t.textMuted}`}>{c.lastContact}</span></td>
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-all">
                        <button className={`w-7 h-7 rounded-lg border flex items-center justify-center hover:text-blue-400 transition-colors ${t.btnIcon}`}><Mail size={12} /></button>
                        <button className={`w-7 h-7 rounded-lg border flex items-center justify-center hover:text-green-400 transition-colors ${t.btnIcon}`}><Phone size={12} /></button>
                        <button className={`w-7 h-7 rounded-lg border flex items-center justify-center hover:text-white transition-colors ${t.btnIcon}`}><MoreHorizontal size={12} /></button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className={`flex flex-wrap items-center justify-between gap-3 px-5 py-3 border-t ${t.divider}`}>
            <span className={`text-xs ${t.textMuted}`}>Showing {filtered.length} of {contacts.length} contacts</span>
            <div className="flex gap-1">
              {["1","2","3","...","12"].map(p => (
                <button key={p} className={`w-7 h-7 text-xs rounded-md transition-all ${p === "1" ? "bg-indigo-600 text-white" : `${t.textSub} hover:bg-indigo-500/10`}`}>{p}</button>
              ))}
            </div>
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {filtered.map((c, i) => (
            <div key={c.id} className={`rounded-xl p-5 border transition-all cursor-pointer group ${t.card} ${t.cardHover}`}>
              <div className="flex items-start justify-between mb-4">
                <div className={`w-12 h-12 rounded-full bg-gradient-to-br ${avatarColors[i % avatarColors.length]} flex items-center justify-center text-white font-bold`}>
                  {c.avatar}
                </div>
                <button className={`${t.textMuted} hover:text-amber-400 transition-colors`}><Star size={16} /></button>
              </div>
              <h3 className={`font-semibold ${t.textPrimary}`}>{c.name}</h3>
              <p className={`text-xs mt-0.5 ${t.textMuted}`}>{c.company}</p>
              <div className="flex items-center gap-2 mt-3">
                <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-full border ${stageColors[c.stage]}`}>{c.stage}</span>
                <span className={`w-1.5 h-1.5 rounded-full ${c.status === "active" ? "bg-emerald-400" : "bg-gray-400"}`} />
              </div>
              <div className={`mt-4 pt-4 border-t ${t.divider} flex items-center justify-between`}>
                <span className="text-sm font-bold text-indigo-500">{c.value}</span>
                <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-all">
                  <button className={`w-7 h-7 rounded-lg flex items-center justify-center hover:text-blue-400 ${t.btnIcon} border`}><Mail size={12} /></button>
                  <button className={`w-7 h-7 rounded-lg flex items-center justify-center hover:text-green-400 ${t.btnIcon} border`}><Phone size={12} /></button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
