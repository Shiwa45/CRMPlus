import { useState } from "react";
import {
  LayoutDashboard, Users, Briefcase, BarChart3, CheckSquare,
  Settings, ChevronLeft, ChevronRight, TrendingUp,
  MessageSquare, Calendar, Target, Zap, HelpCircle, LogOut,
} from "lucide-react";
import { useTheme } from "../context/ThemeContext";

const navItems = [
  { label: "Dashboard",  icon: LayoutDashboard, id: "dashboard" },
  { label: "Contacts",   icon: Users,           id: "contacts" },
  { label: "Deals",      icon: Briefcase,       id: "deals" },
  { label: "Pipeline",   icon: Target,          id: "pipeline" },
  { label: "Analytics",  icon: BarChart3,       id: "analytics" },
  { label: "Activities", icon: Zap,             id: "activities" },
  { label: "Calendar",   icon: Calendar,        id: "calendar" },
  { label: "Tasks",      icon: CheckSquare,     id: "tasks" },
  { label: "Messages",   icon: MessageSquare,   id: "messages", badge: 4 },
  { label: "Reports",    icon: TrendingUp,      id: "reports" },
];

const bottomItems = [
  { label: "Settings", icon: Settings,  id: "settings" },
  { label: "Help",     icon: HelpCircle, id: "help" },
];

interface SidebarProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
}

export default function Sidebar({ activeTab, setActiveTab }: SidebarProps) {
  const [collapsed, setCollapsed] = useState(false);
  const { theme } = useTheme();

  const isDark = theme === "dark";

  const sidebarBg    = isDark ? "bg-[#13151f] border-[#1e2130]"   : "bg-white border-slate-200 shadow-lg";
  const textMuted    = isDark ? "text-gray-400"                    : "text-slate-500";
  const textActive   = isDark ? "text-indigo-400"                  : "text-indigo-600";
  const activeItem   = isDark
    ? "bg-indigo-600/20 text-indigo-400 border border-indigo-500/30"
    : "bg-indigo-50 text-indigo-600 border border-indigo-200";
  const hoverItem    = isDark
    ? "hover:bg-white/5 hover:text-white"
    : "hover:bg-slate-50 hover:text-slate-800";
  const divider      = isDark ? "border-[#1e2130]"                 : "border-slate-100";
  const userSub      = isDark ? "text-gray-500"                    : "text-slate-400";
  const badgeBg      = "bg-indigo-600 text-white";
  const toggleBtn    = isDark
    ? "bg-[#1e2130] border-[#2e3247] text-gray-400 hover:text-white hover:bg-indigo-600"
    : "bg-white border-slate-200 text-slate-400 hover:text-white hover:bg-indigo-600 shadow";
  const labelCat     = isDark ? "text-gray-500"                    : "text-slate-400";
  const tooltipBg    = isDark
    ? "bg-[#1e2130] text-white border border-[#2e3247]"
    : "bg-slate-800 text-white";

  return (
    <aside
      className={`relative flex flex-col border-r transition-all duration-300 ease-in-out shrink-0 h-screen ${sidebarBg} ${
        collapsed ? "w-[70px]" : "w-[240px]"
      }`}
    >
      {/* Logo */}
      <div className={`flex items-center gap-3 px-4 py-5 border-b ${divider} ${collapsed ? "justify-center" : ""}`}>
        <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-indigo-500 to-violet-600 flex items-center justify-center shrink-0">
          <span className="text-white font-bold text-sm">C</span>
        </div>
        {!collapsed && (
          <span className={`font-bold text-lg tracking-tight ${isDark ? "text-white" : "text-slate-800"}`}>
            CRM <span className="text-indigo-500">Pro</span>
          </span>
        )}
      </div>

      {/* Collapse toggle — hidden on mobile (drawer handles that) */}
      <button
        onClick={() => setCollapsed(!collapsed)}
        className={`hidden lg:flex absolute -right-3 top-16 z-10 w-6 h-6 rounded-full border items-center justify-center transition-all ${toggleBtn}`}
      >
        {collapsed ? <ChevronRight size={12} /> : <ChevronLeft size={12} />}
      </button>

      {/* Navigation */}
      <nav className="flex-1 px-2 py-4 space-y-0.5 overflow-y-auto">
        {!collapsed && (
          <p className={`text-[10px] uppercase tracking-widest px-3 mb-2 font-semibold ${labelCat}`}>
            Main Menu
          </p>
        )}
        {navItems.map(({ label, icon: Icon, id, badge }) => {
          const isActive = activeTab === id;
          return (
            <button
              key={id}
              onClick={() => setActiveTab(id)}
              title={collapsed ? label : undefined}
              className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all group relative ${
                isActive ? activeItem : `${textMuted} ${hoverItem}`
              } ${collapsed ? "justify-center" : ""}`}
            >
              <Icon
                size={18}
                className={`shrink-0 ${
                  isActive ? textActive : `${isDark ? "text-gray-500" : "text-slate-400"} group-hover:${isDark ? "text-white" : "text-slate-700"}`
                }`}
              />
              {!collapsed && (
                <span className={`text-sm font-medium ${isActive ? textActive : ""}`}>
                  {label}
                </span>
              )}
              {!collapsed && badge && (
                <span className={`ml-auto text-[10px] font-bold px-1.5 py-0.5 rounded-full ${badgeBg}`}>
                  {badge}
                </span>
              )}
              {collapsed && badge && (
                <span className="absolute top-1 right-1 w-2 h-2 bg-indigo-500 rounded-full" />
              )}
              {/* Tooltip on collapsed */}
              {collapsed && (
                <span className={`absolute left-full ml-2 text-xs py-1 px-2 rounded shadow-lg opacity-0 group-hover:opacity-100 pointer-events-none whitespace-nowrap z-50 ${tooltipBg}`}>
                  {label}
                </span>
              )}
            </button>
          );
        })}
      </nav>

      {/* Bottom */}
      <div className={`px-2 pb-4 space-y-0.5 border-t ${divider} pt-4`}>
        {bottomItems.map(({ label, icon: Icon, id }) => (
          <button
            key={id}
            onClick={() => setActiveTab(id)}
            title={collapsed ? label : undefined}
            className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all group relative ${textMuted} ${hoverItem} ${collapsed ? "justify-center" : ""}`}
          >
            <Icon size={18} className={`shrink-0 ${isDark ? "text-gray-500" : "text-slate-400"}`} />
            {!collapsed && <span className="text-sm font-medium">{label}</span>}
            {collapsed && (
              <span className={`absolute left-full ml-2 text-xs py-1 px-2 rounded shadow-lg opacity-0 group-hover:opacity-100 pointer-events-none whitespace-nowrap z-50 ${tooltipBg}`}>
                {label}
              </span>
            )}
          </button>
        ))}

        {/* User profile */}
        <div
          className={`flex items-center gap-3 px-3 py-2.5 rounded-lg cursor-pointer transition-all mt-2 ${hoverItem} ${collapsed ? "justify-center" : ""}`}
        >
          <div className="w-8 h-8 rounded-full bg-gradient-to-br from-violet-500 to-purple-700 flex items-center justify-center shrink-0 text-white text-xs font-bold">
            AT
          </div>
          {!collapsed && (
            <div className="flex-1 min-w-0">
              <p className={`text-sm font-medium truncate ${isDark ? "text-white" : "text-slate-800"}`}>
                Alex Turner
              </p>
              <p className={`text-[11px] truncate ${userSub}`}>Sales Manager</p>
            </div>
          )}
          {!collapsed && (
            <LogOut size={14} className={`${isDark ? "text-gray-500 hover:text-red-400" : "text-slate-400 hover:text-red-500"} transition-colors`} />
          )}
        </div>
      </div>
    </aside>
  );
}
