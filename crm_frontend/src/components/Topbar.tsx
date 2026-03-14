import { Search, Bell, Plus, ChevronDown, Sun, Moon, Menu } from "lucide-react";
import { useTheme } from "../context/ThemeContext";

const pageTitles: Record<string, { title: string; subtitle: string }> = {
  dashboard:  { title: "Dashboard",  subtitle: "Welcome back, Alex 👋" },
  contacts:   { title: "Contacts",   subtitle: "Manage your customer relationships" },
  deals:      { title: "Deals",      subtitle: "Track and close your deals" },
  pipeline:   { title: "Pipeline",   subtitle: "Visualize your sales pipeline" },
  analytics:  { title: "Analytics",  subtitle: "Deep-dive into your performance" },
  activities: { title: "Activities", subtitle: "Your team's recent actions" },
  calendar:   { title: "Calendar",   subtitle: "Upcoming events and meetings" },
  tasks:      { title: "Tasks",      subtitle: "Your to-do list" },
  messages:   { title: "Messages",   subtitle: "Team communication" },
  reports:    { title: "Reports",    subtitle: "Export and analyze data" },
  settings:   { title: "Settings",   subtitle: "Configure your workspace" },
};

interface TopbarProps {
  activeTab: string;
  onMenuClick: () => void;
}

export default function Topbar({ activeTab, onMenuClick }: TopbarProps) {
  const { theme, toggleTheme } = useTheme();
  const page = pageTitles[activeTab] || pageTitles["dashboard"];

  const btnBase =
    "w-9 h-9 rounded-lg border flex items-center justify-center transition-all";
  const btnCls =
    theme === "dark"
      ? `${btnBase} bg-[#1a1d2e] border-[#2e3247] text-gray-400 hover:text-white hover:border-indigo-500`
      : `${btnBase} bg-white border-slate-200 text-slate-400 hover:text-slate-700 hover:border-indigo-400 shadow-sm`;

  return (
    <header
      className={`flex items-center justify-between px-4 sm:px-6 py-3 sm:py-4 border-b sticky top-0 z-30 transition-colors duration-200 ${
        theme === "dark"
          ? "bg-[#13151f] border-[#1e2130]"
          : "bg-white border-slate-200 shadow-sm"
      }`}
    >
      {/* Left: hamburger (mobile) + title */}
      <div className="flex items-center gap-3 min-w-0">
        <button
          onClick={onMenuClick}
          className={`lg:hidden shrink-0 ${btnCls}`}
          aria-label="Open menu"
        >
          <Menu size={16} />
        </button>
        <div className="min-w-0">
          <h1
            className={`text-lg sm:text-xl font-bold truncate ${
              theme === "dark" ? "text-white" : "text-slate-900"
            }`}
          >
            {page.title}
          </h1>
          <p
            className={`text-xs mt-0.5 hidden sm:block ${
              theme === "dark" ? "text-gray-500" : "text-slate-400"
            }`}
          >
            {page.subtitle}
          </p>
        </div>
      </div>

      {/* Right: actions */}
      <div className="flex items-center gap-2 sm:gap-3 shrink-0">
        {/* Search — hidden on small screens */}
        <div className="relative hidden md:flex items-center">
          <Search
            size={14}
            className={`absolute left-3 ${
              theme === "dark" ? "text-gray-500" : "text-slate-400"
            }`}
          />
          <input
            type="text"
            placeholder="Search anything..."
            className={`rounded-lg pl-8 pr-4 py-2 text-sm placeholder focus:outline-none w-48 xl:w-56 transition-all focus:w-64 xl:focus:w-72 border ${
              theme === "dark"
                ? "bg-[#1a1d2e] border-[#2e3247] text-gray-300 placeholder-gray-600 focus:border-indigo-500"
                : "bg-slate-50 border-slate-200 text-slate-700 placeholder-slate-400 focus:border-indigo-400 shadow-sm"
            }`}
          />
        </div>

        {/* New Button */}
        <button className="flex items-center gap-1.5 bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-medium px-3 sm:px-4 py-2 rounded-lg transition-all shadow-lg shadow-indigo-900/30">
          <Plus size={14} />
          <span className="hidden sm:inline">New</span>
        </button>

        {/* Notifications */}
        <button className={`relative ${btnCls}`}>
          <Bell size={16} />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-indigo-500 rounded-full" />
        </button>

        {/* Theme toggle */}
        <button
          onClick={toggleTheme}
          className={btnCls}
          aria-label="Toggle theme"
        >
          {theme === "dark" ? (
            <Sun size={16} className="text-amber-400" />
          ) : (
            <Moon size={16} className="text-indigo-500" />
          )}
        </button>

        {/* Date range — hidden on small/medium screens */}
        <button
          className={`hidden lg:flex items-center gap-2 text-sm px-3 py-2 rounded-lg border transition-all ${
            theme === "dark"
              ? "bg-[#1a1d2e] border-[#2e3247] text-gray-400 hover:border-indigo-500 hover:text-white"
              : "bg-white border-slate-200 text-slate-500 hover:border-indigo-400 hover:text-slate-700 shadow-sm"
          }`}
        >
          <span>Dec 2024</span>
          <ChevronDown size={14} />
        </button>
      </div>
    </header>
  );
}
