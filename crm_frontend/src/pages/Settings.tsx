import { User, Bell, Shield, Palette, Globe, Database, CreditCard, Users, ChevronRight, Check } from "lucide-react";
import { useTheme } from "../context/ThemeContext";
import { themeClasses } from "../utils/themeClasses";

const settingsSections = [
  { icon: User,       label: "Profile",       id: "profile" },
  { icon: Bell,       label: "Notifications", id: "notifications" },
  { icon: Shield,     label: "Security",      id: "security" },
  { icon: Palette,    label: "Appearance",    id: "appearance" },
  { icon: Globe,      label: "Integrations",  id: "integrations" },
  { icon: Database,   label: "Data & Privacy", id: "data" },
  { icon: CreditCard, label: "Billing",       id: "billing" },
  { icon: Users,      label: "Team",          id: "team" },
];

const integrations = [
  { name: "Slack",    desc: "Team notifications and alerts",  connected: true,  icon: "S", color: "bg-violet-500" },
  { name: "Gmail",    desc: "Email sync and tracking",        connected: true,  icon: "G", color: "bg-red-500" },
  { name: "Zoom",     desc: "Video meetings integration",     connected: false, icon: "Z", color: "bg-blue-500" },
  { name: "HubSpot",  desc: "Marketing automation sync",      connected: false, icon: "H", color: "bg-orange-500" },
  { name: "Stripe",   desc: "Payment processing",             connected: true,  icon: "S", color: "bg-indigo-500" },
  { name: "Zapier",   desc: "Workflow automation",            connected: false, icon: "Z", color: "bg-amber-500" },
];

export default function Settings() {
  const { theme, toggleTheme } = useTheme();
  const isDark = theme === "dark";
  const t = themeClasses(isDark);

  return (
    <div className="p-4 sm:p-6">
      <div className="flex flex-col lg:flex-row gap-6">
        {/* Settings sidebar */}
        <div className="lg:w-56 shrink-0">
          <div className={`rounded-xl overflow-hidden border ${t.card}`}>
            {settingsSections.map(({ icon: Icon, label, id }, i) => (
              <button key={id} className={`w-full flex items-center gap-3 px-4 py-3 text-sm transition-all border-b last:border-0 ${t.divider} ${
                i === 0
                  ? "bg-indigo-600/15 text-indigo-500"
                  : `${t.textSub} ${isDark ? "hover:bg-white/5 hover:text-white" : "hover:bg-slate-50 hover:text-slate-800"}`
              }`}>
                <Icon size={15} />
                <span>{label}</span>
                {i === 0 && <ChevronRight size={12} className="ml-auto" />}
              </button>
            ))}
          </div>
        </div>

        {/* Main */}
        <div className="flex-1 space-y-6">
          {/* Profile */}
          <div className={`rounded-xl p-5 sm:p-6 border ${t.card}`}>
            <h3 className={`font-semibold mb-5 ${t.textPrimary}`}>Profile Settings</h3>
            <div className="flex items-start gap-5 mb-6">
              <div className="w-16 h-16 rounded-full bg-gradient-to-br from-violet-500 to-purple-700 flex items-center justify-center text-white text-xl font-bold shrink-0">AT</div>
              <div>
                <p className={`font-semibold ${t.textPrimary}`}>Alex Turner</p>
                <p className={`text-sm mt-0.5 ${t.textSub}`}>Sales Manager</p>
                <button className="mt-2 text-xs text-indigo-500 hover:text-indigo-400 border border-indigo-500/30 px-3 py-1 rounded-lg transition-all">Change Photo</button>
              </div>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {[
                { label: "First Name",    value: "Alex",                   type: "text" },
                { label: "Last Name",     value: "Turner",                 type: "text" },
                { label: "Email Address", value: "alex.turner@crmco.io",   type: "email" },
                { label: "Phone Number",  value: "+1 (555) 123-4567",      type: "tel" },
                { label: "Job Title",     value: "Sales Manager",          type: "text" },
                { label: "Department",    value: "Sales",                  type: "text" },
              ].map((field) => (
                <div key={field.label}>
                  <label className={`text-xs font-semibold uppercase tracking-wider ${t.textMuted}`}>{field.label}</label>
                  <input
                    type={field.type}
                    defaultValue={field.value}
                    className={`mt-1.5 w-full rounded-lg px-3 py-2.5 text-sm border focus:outline-none transition-all ${t.input}`}
                  />
                </div>
              ))}
            </div>
            <div className="flex flex-wrap gap-3 mt-5">
              <button className="bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-medium px-5 py-2.5 rounded-lg transition-all">Save Changes</button>
              <button className={`text-sm px-5 py-2.5 rounded-lg border transition-all ${t.btnGhost}`}>Cancel</button>
            </div>
          </div>

          {/* Notifications */}
          <div className={`rounded-xl p-5 sm:p-6 border ${t.card}`}>
            <h3 className={`font-semibold mb-5 ${t.textPrimary}`}>Notification Preferences</h3>
            <div className="space-y-4">
              {[
                { label: "New leads assigned",       desc: "Get notified when a lead is assigned to you",      enabled: true },
                { label: "Deal stage changes",        desc: "Notify when a deal moves to a new stage",          enabled: true },
                { label: "Task reminders",            desc: "Reminders for upcoming and overdue tasks",         enabled: true },
                { label: "Team messages",             desc: "Notifications for new chat messages",              enabled: false },
                { label: "Weekly performance report", desc: "Summary email every Monday morning",               enabled: true },
                { label: "System alerts",             desc: "Critical system and security notifications",       enabled: true },
              ].map((item) => (
                <div key={item.label} className={`flex items-center justify-between py-3 border-b last:border-0 ${t.divider}`}>
                  <div>
                    <p className={`text-sm font-medium ${t.textPrimary}`}>{item.label}</p>
                    <p className={`text-xs mt-0.5 ${t.textMuted}`}>{item.desc}</p>
                  </div>
                  <button className={`relative w-12 h-6 rounded-full transition-all shrink-0 ${item.enabled ? "bg-indigo-600" : isDark ? "bg-[#2e3247]" : "bg-slate-200"}`}>
                    <span className={`absolute top-0.5 w-5 h-5 rounded-full bg-white shadow transition-all ${item.enabled ? "left-6" : "left-0.5"}`} />
                  </button>
                </div>
              ))}
            </div>
          </div>

          {/* Integrations */}
          <div className={`rounded-xl p-5 sm:p-6 border ${t.card}`}>
            <h3 className={`font-semibold mb-1 ${t.textPrimary}`}>Integrations</h3>
            <p className={`text-sm mb-5 ${t.textMuted}`}>Connect your favorite tools to streamline your workflow</p>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {integrations.map((intg) => (
                <div key={intg.name} className={`flex items-center gap-4 p-4 rounded-xl border transition-all ${isDark ? "bg-[#1a1d2e] border-[#2e3247] hover:border-indigo-500/30" : "bg-slate-50 border-slate-200 hover:border-indigo-300"}`}>
                  <div className={`w-10 h-10 rounded-xl ${intg.color} flex items-center justify-center text-white font-bold text-sm shrink-0`}>
                    {intg.icon}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className={`text-sm font-semibold ${t.textPrimary}`}>{intg.name}</p>
                    <p className={`text-xs truncate ${t.textMuted}`}>{intg.desc}</p>
                  </div>
                  <button className={`shrink-0 text-xs font-semibold px-3 py-1.5 rounded-lg border transition-all ${
                    intg.connected
                      ? "bg-emerald-500/10 text-emerald-500 border-emerald-500/25 hover:bg-emerald-500/20"
                      : "bg-indigo-600/20 text-indigo-500 border-indigo-500/30 hover:bg-indigo-600/30"
                  }`}>
                    {intg.connected ? <span className="flex items-center gap-1"><Check size={11} />Connected</span> : "Connect"}
                  </button>
                </div>
              ))}
            </div>
          </div>

          {/* Appearance */}
          <div className={`rounded-xl p-5 sm:p-6 border ${t.card}`}>
            <h3 className={`font-semibold mb-5 ${t.textPrimary}`}>Appearance</h3>
            <div className="space-y-5">
              <div>
                <label className={`text-xs font-semibold uppercase tracking-wider ${t.textMuted}`}>Theme</label>
                <div className="flex flex-wrap gap-3 mt-2">
                  {[
                    { name: "Dark",   active: isDark,   preview: "bg-[#0f1117]",                         action: () => !isDark && toggleTheme() },
                    { name: "Light",  active: !isDark,  preview: "bg-white border border-slate-200",     action: () => isDark && toggleTheme() },
                    { name: "System", active: false,    preview: "bg-gradient-to-r from-[#0f1117] to-gray-100", action: () => {} },
                  ].map((th) => (
                    <button
                      key={th.name}
                      onClick={th.action}
                      className={`flex items-center gap-2 px-4 py-2.5 rounded-lg border text-sm transition-all ${
                        th.active
                          ? "border-indigo-500 bg-indigo-600/10 text-indigo-500"
                          : `${t.dividerMid} ${t.textSub} ${isDark ? "hover:border-slate-500" : "hover:border-slate-400"}`
                      }`}
                    >
                      <div className={`w-4 h-4 rounded-full ${th.preview}`} />
                      {th.name}
                    </button>
                  ))}
                </div>
              </div>
              <div>
                <label className={`text-xs font-semibold uppercase tracking-wider ${t.textMuted}`}>Accent Color</label>
                <div className="flex gap-2 mt-2">
                  {["bg-indigo-500","bg-violet-500","bg-cyan-500","bg-emerald-500","bg-rose-500","bg-amber-500"].map((color, i) => (
                    <button key={color} className={`w-8 h-8 rounded-full ${color} transition-all hover:scale-110 ${i === 0 ? `ring-2 ring-indigo-500 ring-offset-2 ${isDark ? "ring-offset-[#13151f]" : "ring-offset-white"}` : ""}`} />
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
