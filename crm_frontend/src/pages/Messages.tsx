import { Search, Send, Paperclip, Phone, Video, MoreHorizontal, Circle } from "lucide-react";
import { useTheme } from "../context/ThemeContext";
import { themeClasses } from "../utils/themeClasses";

const conversations = [
  { id: 1, name: "Sarah Johnson",   company: "TechNova Inc.",   message: "Can we schedule a call tomorrow to discuss the contract?", time: "2m",  unread: 2, avatar: "SJ", online: true,  color: "from-indigo-500 to-violet-600" },
  { id: 2, name: "Michael Chen",    company: "Global Ventures", message: "Sounds great! Looking forward to the proposal.",           time: "1h",  unread: 0, avatar: "MC", online: true,  color: "from-cyan-500 to-blue-600" },
  { id: 3, name: "Emma Williams",   company: "Creative Studio", message: "I'll review the documents and get back to you.",          time: "3h",  unread: 0, avatar: "EW", online: false, color: "from-emerald-500 to-teal-600" },
  { id: 4, name: "Sales Team",      company: "Internal",        message: "Alex: Great job closing that Pinnacle deal! 🎉",          time: "5h",  unread: 4, avatar: "ST", online: true,  color: "from-amber-500 to-orange-600" },
  { id: 5, name: "James Rodriguez", company: "DataSphere",      message: "The migration timeline works for us.",                    time: "1d",  unread: 0, avatar: "JR", online: false, color: "from-pink-500 to-rose-600" },
  { id: 6, name: "Olivia Smith",    company: "Pinnacle Corp.",  message: "Please send the signed contract to our legal team.",      time: "1d",  unread: 0, avatar: "OS", online: true,  color: "from-violet-500 to-purple-600" },
];

const messages = [
  { id: 1, from: "Sarah Johnson", text: "Hi Alex! I've reviewed your proposal and I have a few questions.", time: "10:22 AM", mine: false },
  { id: 2, from: "me", text: "Of course! Happy to walk you through everything. What would you like to know?", time: "10:24 AM", mine: true },
  { id: 3, from: "Sarah Johnson", text: "The pricing on the enterprise tier — is that per seat or flat rate?", time: "10:25 AM", mine: false },
  { id: 4, from: "me", text: "It's a flat rate up to 50 seats, then per-seat pricing kicks in. We can also do a custom enterprise plan if you need more flexibility.", time: "10:27 AM", mine: true },
  { id: 5, from: "Sarah Johnson", text: "That sounds promising! Can we schedule a call tomorrow to discuss the contract and finalize the details?", time: "10:28 AM", mine: false },
  { id: 6, from: "me", text: "Absolutely! I'll send a calendar invite for 10 AM your time. Does that work?", time: "10:30 AM", mine: true },
  { id: 7, from: "Sarah Johnson", text: "Perfect! Looking forward to it. Also, could you send over the updated pricing sheet before then?", time: "10:31 AM", mine: false },
];

export default function Messages() {
  const { theme } = useTheme();
  const isDark = theme === "dark";
  const t = themeClasses(isDark);

  return (
    <div className="p-4 sm:p-6">
      <div className="flex gap-4 h-[calc(100vh-140px)] min-h-[500px]">
        {/* Conversation list — hidden on mobile, shown on sm+ */}
        <div className={`hidden sm:flex w-72 lg:w-80 shrink-0 rounded-xl flex-col overflow-hidden border ${t.card}`}>
          <div className={`p-4 border-b ${t.divider}`}>
            <div className="relative">
              <Search size={14} className={`absolute left-3 top-1/2 -translate-y-1/2 ${t.textMuted}`} />
              <input
                placeholder="Search conversations..."
                className={`w-full rounded-lg pl-9 pr-4 py-2 text-sm border focus:outline-none ${t.input}`}
              />
            </div>
          </div>
          <div className={`flex gap-2 px-4 py-3 border-b ${t.divider}`}>
            {["All","Unread","Groups"].map((tab, i) => (
              <button key={tab} className={`flex-1 text-xs py-1.5 rounded-lg transition-all ${i === 0 ? t.tabActive : t.tabInactive}`}>
                {tab}
              </button>
            ))}
          </div>
          <div className="flex-1 overflow-y-auto">
            {conversations.map((conv) => (
              <div key={conv.id} className={`flex items-start gap-3 px-4 py-3 cursor-pointer border-b transition-all ${t.divider} ${
                conv.id === 1
                  ? isDark ? "bg-indigo-600/10 border-l-2 border-l-indigo-500" : "bg-indigo-50 border-l-2 border-l-indigo-500"
                  : isDark ? "hover:bg-white/[0.03]" : "hover:bg-slate-50"
              }`}>
                <div className="relative shrink-0">
                  <div className={`w-10 h-10 rounded-full bg-gradient-to-br ${conv.color} flex items-center justify-center text-white text-xs font-bold`}>
                    {conv.avatar}
                  </div>
                  {conv.online && (
                    <span className={`absolute bottom-0 right-0 w-2.5 h-2.5 bg-emerald-400 rounded-full border-2 ${isDark ? "border-[#13151f]" : "border-white"}`} />
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <p className={`text-sm font-semibold truncate ${t.textPrimary}`}>{conv.name}</p>
                    <span className={`text-[10px] shrink-0 ${t.textTiny}`}>{conv.time}</span>
                  </div>
                  <p className={`text-[11px] truncate mt-0.5 ${t.textMuted}`}>{conv.message}</p>
                </div>
                {conv.unread > 0 && (
                  <span className="shrink-0 bg-indigo-600 text-white text-[10px] font-bold w-5 h-5 rounded-full flex items-center justify-center mt-1">
                    {conv.unread}
                  </span>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Chat area */}
        <div className={`flex-1 rounded-xl flex flex-col overflow-hidden border ${t.card}`}>
          {/* Chat header */}
          <div className={`flex items-center justify-between px-4 sm:px-5 py-4 border-b ${t.divider}`}>
            <div className="flex items-center gap-3">
              <div className="relative">
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-indigo-500 to-violet-600 flex items-center justify-center text-white text-sm font-bold">SJ</div>
                <span className={`absolute bottom-0 right-0 w-2.5 h-2.5 bg-emerald-400 rounded-full border-2 ${isDark ? "border-[#13151f]" : "border-white"}`} />
              </div>
              <div>
                <p className={`font-semibold ${t.textPrimary}`}>Sarah Johnson</p>
                <div className="flex items-center gap-1">
                  <Circle size={7} className="text-emerald-400 fill-emerald-400" />
                  <p className={`text-xs ${t.textMuted}`}>Online · TechNova Inc.</p>
                </div>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <button className={`w-9 h-9 rounded-lg border flex items-center justify-center transition-all ${t.btnIcon}`}><Phone size={15} /></button>
              <button className={`w-9 h-9 rounded-lg border flex items-center justify-center transition-all ${t.btnIcon}`}><Video size={15} /></button>
              <button className={`w-9 h-9 rounded-lg border flex items-center justify-center transition-all ${t.btnIcon}`}><MoreHorizontal size={15} /></button>
            </div>
          </div>

          {/* Messages */}
          <div className="flex-1 overflow-y-auto p-4 sm:p-5 space-y-4">
            <div className="flex justify-center">
              <span className={`text-[11px] px-3 py-1 rounded-full border ${isDark ? "text-gray-600 bg-[#1a1d2e] border-[#2e3247]" : "text-slate-400 bg-slate-100 border-slate-200"}`}>Today</span>
            </div>
            {messages.map((msg) => (
              <div key={msg.id} className={`flex ${msg.mine ? "justify-end" : "justify-start"}`}>
                <div className={`max-w-[70%]`}>
                  <div className={`px-4 py-3 rounded-2xl text-sm leading-relaxed ${
                    msg.mine
                      ? "bg-indigo-600 text-white rounded-br-md"
                      : isDark
                        ? "bg-[#1a1d2e] border border-[#2e3247] text-gray-200 rounded-bl-md"
                        : "bg-slate-100 border border-slate-200 text-slate-700 rounded-bl-md"
                  }`}>
                    {msg.text}
                  </div>
                  <p className={`text-[10px] mt-1 ${msg.mine ? "text-right" : ""} ${t.textTiny}`}>{msg.time}</p>
                </div>
              </div>
            ))}
            {/* Typing */}
            <div className="flex justify-start">
              <div className={`px-4 py-3 rounded-2xl rounded-bl-md border ${isDark ? "bg-[#1a1d2e] border-[#2e3247]" : "bg-slate-100 border-slate-200"}`}>
                <div className="flex gap-1 items-center h-4">
                  <span className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: "0ms" }} />
                  <span className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: "150ms" }} />
                  <span className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: "300ms" }} />
                </div>
              </div>
            </div>
          </div>

          {/* Input */}
          <div className={`px-4 sm:px-5 py-4 border-t ${t.divider}`}>
            <div className={`flex items-center gap-3 rounded-xl px-4 py-3 border transition-all focus-within:border-indigo-500 ${isDark ? "bg-[#1a1d2e] border-[#2e3247]" : "bg-slate-50 border-slate-200"}`}>
              <button className={`${t.textMuted} hover:text-indigo-400 transition-colors`}><Paperclip size={16} /></button>
              <input
                placeholder="Type a message..."
                className={`flex-1 bg-transparent text-sm focus:outline-none ${isDark ? "text-gray-300 placeholder-gray-600" : "text-slate-700 placeholder-slate-400"}`}
              />
              <button className="w-8 h-8 rounded-lg bg-indigo-600 hover:bg-indigo-500 flex items-center justify-center text-white transition-all">
                <Send size={14} />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
