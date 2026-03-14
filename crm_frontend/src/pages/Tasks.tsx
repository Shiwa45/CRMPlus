import { useState } from "react";
import { Plus, Clock, User, CheckCircle, Circle, Filter, MoreHorizontal, AlertCircle } from "lucide-react";
import { tasks } from "../data/mockData";
import { useTheme } from "../context/ThemeContext";
import { themeClasses } from "../utils/themeClasses";

export default function Tasks() {
  const [filter, setFilter] = useState("all");
  const { theme } = useTheme();
  const isDark = theme === "dark";
  const t = themeClasses(isDark);

  const priorityConfig: Record<string, { label: string; dark: string; light: string; dot: string }> = {
    high:   { label: "High",   dark: "bg-red-500/10 text-red-400 border-red-500/25",     light: "bg-red-50 text-red-500 border-red-200",    dot: "bg-red-400" },
    medium: { label: "Medium", dark: "bg-amber-500/10 text-amber-400 border-amber-500/25", light: "bg-amber-50 text-amber-600 border-amber-200", dot: "bg-amber-400" },
    low:    { label: "Low",    dark: "bg-gray-500/10 text-gray-400 border-gray-500/25",  light: "bg-slate-50 text-slate-500 border-slate-200", dot: "bg-slate-400" },
  };

  const filtered = tasks.filter(t => {
    if (filter === "done")    return t.done;
    if (filter === "pending") return !t.done;
    if (filter === "high")    return t.priority === "high";
    return true;
  });

  return (
    <div className="p-4 sm:p-6 space-y-4 sm:space-y-5">
      {/* Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 sm:gap-4">
        {[
          { label: "Total Tasks",   value: tasks.length,                         color: "text-indigo-500" },
          { label: "Completed",     value: tasks.filter(t => t.done).length,     color: "text-emerald-500" },
          { label: "Pending",       value: tasks.filter(t => !t.done).length,    color: "text-amber-500" },
          { label: "High Priority", value: tasks.filter(t => t.priority === "high").length, color: "text-red-500" },
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
          {[
            { id: "all",     label: "All" },
            { id: "pending", label: "Pending" },
            { id: "done",    label: "Done" },
            { id: "high",    label: "High Priority" },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setFilter(tab.id)}
              className={`text-sm px-3 py-1.5 rounded-lg transition-all ${filter === tab.id ? t.tabActive : t.tabInactive}`}
            >
              {tab.label}
            </button>
          ))}
        </div>
        <div className="flex gap-2">
          <button className={`flex items-center gap-2 text-sm px-3 py-2 rounded-lg border transition-all ${t.btnGhost}`}>
            <Filter size={13} /> Filter
          </button>
          <button className="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-medium px-4 py-2 rounded-lg transition-all">
            <Plus size={14} /> Add Task
          </button>
        </div>
      </div>

      {/* Task Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {filtered.map((task) => {
          const pc = priorityConfig[task.priority];
          const pcColor = isDark ? pc.dark : pc.light;
          return (
            <div
              key={task.id}
              className={`rounded-xl p-4 border transition-all group ${t.card} ${t.cardHover} ${task.done ? "opacity-60" : ""}`}
            >
              <div className="flex items-start gap-3">
                <button className={`mt-0.5 shrink-0 transition-colors ${task.done ? "text-emerald-500" : `${t.textMuted} hover:text-indigo-400`}`}>
                  {task.done ? <CheckCircle size={20} /> : <Circle size={20} />}
                </button>
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <p className={`text-sm font-medium leading-snug ${task.done ? `line-through ${t.textMuted}` : t.textPrimary}`}>
                      {task.title}
                    </p>
                    <button className={`opacity-0 group-hover:opacity-100 transition-all shrink-0 ${t.textMuted}`}>
                      <MoreHorizontal size={14} />
                    </button>
                  </div>
                  <div className="flex items-center gap-3 mt-2 flex-wrap">
                    <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-full border capitalize ${pcColor}`}>
                      <span className={`w-1.5 h-1.5 rounded-full inline-block mr-1 ${pc.dot}`} />{pc.label}
                    </span>
                    <div className={`flex items-center gap-1 ${t.textMuted}`}>
                      <Clock size={11} /><span className="text-xs">{task.due}</span>
                    </div>
                    <div className={`flex items-center gap-1 ${t.textMuted}`}>
                      <User size={11} /><span className="text-xs">{task.assignee}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {filtered.length === 0 && (
        <div className="flex flex-col items-center justify-center py-20 text-center">
          <AlertCircle size={40} className={`mb-4 ${t.textMuted}`} />
          <p className={`font-medium ${t.textSub}`}>No tasks found</p>
          <p className={`text-sm mt-1 ${t.textMuted}`}>Try changing the filter or add a new task</p>
        </div>
      )}

      {/* Upcoming deadlines */}
      <div className={`rounded-xl p-4 sm:p-5 border ${t.card}`}>
        <h3 className={`font-semibold mb-4 ${t.textPrimary}`}>Upcoming Deadlines</h3>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {[
            { day: "Today",     count: 2, dark: "border-red-500/30 bg-red-500/5",    light: "border-red-200 bg-red-50" },
            { day: "Tomorrow",  count: 1, dark: "border-amber-500/30 bg-amber-500/5", light: "border-amber-200 bg-amber-50" },
            { day: "This Week", count: 3, dark: "border-indigo-500/30 bg-indigo-500/5", light: "border-indigo-200 bg-indigo-50" },
          ].map((d) => (
            <div key={d.day} className={`border rounded-xl p-4 ${isDark ? d.dark : d.light}`}>
              <p className={`text-sm ${t.textSub}`}>{d.day}</p>
              <p className={`text-3xl font-bold mt-1 ${t.textPrimary}`}>{d.count}</p>
              <p className={`text-xs ${t.textMuted}`}>tasks due</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
