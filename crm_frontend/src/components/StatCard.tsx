import { TrendingUp, TrendingDown } from "lucide-react";
import { ReactNode } from "react";
import { useTheme } from "../context/ThemeContext";

interface StatCardProps {
  title: string;
  value: string;
  change: string;
  positive: boolean;
  icon: ReactNode;
  iconBg: string;
  subtitle?: string;
}

export default function StatCard({ title, value, change, positive, icon, iconBg, subtitle }: StatCardProps) {
  const { theme } = useTheme();
  const isDark = theme === "dark";

  return (
    <div
      className={`rounded-xl p-5 border transition-all hover:border-indigo-400/50 group ${
        isDark
          ? "bg-[#13151f] border-[#1e2130]"
          : "bg-white border-slate-200 shadow-sm hover:shadow-md"
      }`}
    >
      <div className="flex items-start justify-between mb-4">
        <div className={`w-10 h-10 rounded-lg ${iconBg} flex items-center justify-center`}>
          {icon}
        </div>
        <div
          className={`flex items-center gap-1 text-xs font-semibold px-2 py-1 rounded-full ${
            positive ? "bg-emerald-500/10 text-emerald-500" : "bg-red-500/10 text-red-500"
          }`}
        >
          {positive ? <TrendingUp size={11} /> : <TrendingDown size={11} />}
          {change}
        </div>
      </div>
      <p className={`text-2xl font-bold mb-1 ${isDark ? "text-white" : "text-slate-800"}`}>
        {value}
      </p>
      <p className={`text-sm ${isDark ? "text-gray-500" : "text-slate-500"}`}>{title}</p>
      {subtitle && (
        <p className={`text-xs mt-1 ${isDark ? "text-gray-600" : "text-slate-400"}`}>
          {subtitle}
        </p>
      )}
    </div>
  );
}
