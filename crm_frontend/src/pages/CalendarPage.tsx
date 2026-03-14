import { ChevronLeft, ChevronRight, Plus, Clock, User, Video } from "lucide-react";
import { useTheme } from "../context/ThemeContext";
import { themeClasses } from "../utils/themeClasses";

const days = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
const hours = Array.from({ length: 10 }, (_, i) => i + 8);

const events = [
  { id: 1, title: "Sales Team Standup",         time: "9:00 AM",  duration: 1,   day: 1, color: "bg-indigo-500/20 border-indigo-500/40 text-indigo-400",  type: "Meeting" },
  { id: 2, title: "Demo — TechNova Inc.",        time: "11:00 AM", duration: 1.5, day: 2, color: "bg-violet-500/20 border-violet-500/40 text-violet-400",  type: "Demo" },
  { id: 3, title: "Follow-up: Global Ventures",  time: "2:00 PM",  duration: 1,   day: 2, color: "bg-cyan-500/20 border-cyan-500/40 text-cyan-400",        type: "Call" },
  { id: 4, title: "Contract Review",             time: "10:00 AM", duration: 2,   day: 3, color: "bg-amber-500/20 border-amber-500/40 text-amber-400",     type: "Internal" },
  { id: 5, title: "Q4 Pipeline Review",          time: "3:00 PM",  duration: 1.5, day: 4, color: "bg-pink-500/20 border-pink-500/40 text-pink-400",        type: "Meeting" },
  { id: 6, title: "Client Onboarding — Pinnacle", time: "9:30 AM", duration: 2,   day: 5, color: "bg-emerald-500/20 border-emerald-500/40 text-emerald-400", type: "Onboarding" },
];

const upcomingEvents = [
  { title: "Sales Team Standup",        date: "Today, 9:00 AM",      type: "Video Call",  attendees: 5, color: "bg-indigo-500" },
  { title: "Demo — TechNova Inc.",       date: "Tomorrow, 11:00 AM",  type: "Demo",        attendees: 3, color: "bg-violet-500" },
  { title: "Follow-up: Global Ventures", date: "Tomorrow, 2:00 PM",  type: "Phone Call",  attendees: 2, color: "bg-cyan-500" },
  { title: "Contract Review",            date: "Dec 27, 10:00 AM",   type: "Internal",    attendees: 4, color: "bg-amber-500" },
  { title: "Q4 Pipeline Review",         date: "Dec 28, 3:00 PM",    type: "Meeting",     attendees: 8, color: "bg-pink-500" },
];

const calDays = [
  [null,null,1,2,3,4,5],
  [6,7,8,9,10,11,12],
  [13,14,15,16,17,18,19],
  [20,21,22,23,24,25,26],
  [27,28,29,30,31,null,null],
];
const eventDots: Record<number,string> = { 2:"bg-indigo-500",5:"bg-violet-500",9:"bg-cyan-500",14:"bg-emerald-500",17:"bg-amber-500",22:"bg-pink-500",28:"bg-indigo-500" };

export default function CalendarPage() {
  const { theme } = useTheme();
  const isDark = theme === "dark";
  const t = themeClasses(isDark);

  return (
    <div className="p-4 sm:p-6 space-y-6">
      <div className="grid grid-cols-1 xl:grid-cols-4 gap-6">
        {/* Mini cal + upcoming */}
        <div className="space-y-4">
          <div className={`rounded-xl p-4 border ${t.card}`}>
            <div className="flex items-center justify-between mb-4">
              <h3 className={`font-semibold ${t.textPrimary}`}>December 2024</h3>
              <div className="flex gap-1">
                <button className={`w-7 h-7 rounded-lg border flex items-center justify-center transition-all ${t.btnIcon}`}><ChevronLeft size={14} /></button>
                <button className={`w-7 h-7 rounded-lg border flex items-center justify-center transition-all ${t.btnIcon}`}><ChevronRight size={14} /></button>
              </div>
            </div>
            <div className="grid grid-cols-7 gap-1 mb-2">
              {days.map(d => (
                <div key={d} className={`text-center text-[10px] font-semibold py-1 ${t.textTiny}`}>{d[0]}</div>
              ))}
            </div>
            <div className="grid grid-cols-7 gap-1">
              {calDays.flat().map((day, i) => (
                <div key={i} className={`relative flex items-center justify-center rounded-lg h-8 text-xs cursor-pointer transition-all ${
                  !day ? "opacity-0" :
                  day === 25 ? "bg-indigo-600 text-white font-bold" :
                  `${t.textSub} hover:bg-indigo-500/10`
                }`}>
                  {day}
                  {day && eventDots[day] && (
                    <span className={`absolute bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full ${eventDots[day]}`} />
                  )}
                </div>
              ))}
            </div>
          </div>

          <div className={`rounded-xl p-4 border ${t.card}`}>
            <div className="flex items-center justify-between mb-4">
              <h3 className={`font-semibold ${t.textPrimary}`}>Upcoming</h3>
              <button className="text-indigo-400 text-xs hover:text-indigo-300">View all</button>
            </div>
            <div className="space-y-3">
              {upcomingEvents.map((evt, i) => (
                <div key={i} className="flex items-start gap-3 group cursor-pointer">
                  <div className={`w-2 h-8 rounded-full ${evt.color} shrink-0 mt-0.5`} />
                  <div>
                    <p className={`text-sm font-medium group-hover:text-indigo-400 transition-colors ${t.textPrimary}`}>{evt.title}</p>
                    <div className="flex items-center gap-2 mt-0.5">
                      <Clock size={10} className={t.textTiny} />
                      <span className={`text-[11px] ${t.textMuted}`}>{evt.date}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Weekly View */}
        <div className={`xl:col-span-3 rounded-xl overflow-hidden border ${t.card}`}>
          <div className={`flex flex-wrap items-center justify-between gap-3 px-4 sm:px-5 py-4 border-b ${t.divider}`}>
            <div className="flex items-center gap-3">
              <button className={`w-8 h-8 rounded-lg border flex items-center justify-center transition-all ${t.btnIcon}`}><ChevronLeft size={14} /></button>
              <h3 className={`font-semibold text-sm sm:text-base ${t.textPrimary}`}>Dec 23 – Dec 29, 2024</h3>
              <button className={`w-8 h-8 rounded-lg border flex items-center justify-center transition-all ${t.btnIcon}`}><ChevronRight size={14} /></button>
            </div>
            <div className="flex items-center gap-2">
              <button className="text-xs bg-indigo-600 text-white px-3 py-1.5 rounded-lg">Today</button>
              <div className={`flex gap-1 border rounded-lg p-1 ${isDark ? "bg-[#1a1d2e] border-[#2e3247]" : "bg-slate-50 border-slate-200"}`}>
                {["Day","Week","Month"].map((v, i) => (
                  <button key={v} className={`text-xs px-2 py-1 rounded-md transition-all ${i === 1 ? "bg-indigo-600 text-white" : `${t.textMuted} hover:${t.textPrimary}`}`}>{v}</button>
                ))}
              </div>
              <button className="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-medium px-3 py-1.5 rounded-lg transition-all">
                <Plus size={13} /> Event
              </button>
            </div>
          </div>

          {/* Day headers */}
          <div className={`grid border-b ${t.divider}`} style={{ gridTemplateColumns: "60px repeat(7, 1fr)" }}>
            <div className={`border-r ${t.divider}`} />
            {["Sun 23","Mon 24","Tue 25","Wed 26","Thu 27","Fri 28","Sat 29"].map((d, i) => (
              <div key={d} className={`text-center py-3 border-r last:border-r-0 ${t.divider} ${i === 1 ? "bg-indigo-600/10" : ""}`}>
                <p className={`text-[11px] font-semibold uppercase tracking-wider ${i === 1 ? "text-indigo-400" : t.textMuted}`}>{d.split(" ")[0]}</p>
                <p className={`text-lg font-bold mt-0.5 ${i === 1 ? "text-indigo-400" : t.textPrimary}`}>{d.split(" ")[1]}</p>
              </div>
            ))}
          </div>

          {/* Time grid */}
          <div className="overflow-y-auto max-h-[440px]">
            {hours.map((hour) => (
              <div key={hour} className={`grid border-b ${t.divider}`} style={{ gridTemplateColumns: "60px repeat(7, 1fr)", minHeight: "60px" }}>
                <div className={`border-r ${t.divider} px-2 pt-2`}>
                  <span className={`text-[10px] ${t.textTiny}`}>{hour > 12 ? `${hour - 12}pm` : `${hour}am`}</span>
                </div>
                {Array.from({ length: 7 }).map((_, dayIdx) => {
                  const evt = events.find(e => e.day === dayIdx && parseInt(e.time) === hour);
                  return (
                    <div key={dayIdx} className={`border-r last:border-r-0 ${t.divider} p-1 ${dayIdx === 1 ? "bg-indigo-600/5" : ""}`}>
                      {evt && (
                        <div className={`rounded-lg border p-2 cursor-pointer ${evt.color} hover:brightness-110 transition-all`}>
                          <p className="text-xs font-semibold leading-tight">{evt.title}</p>
                          <p className="text-[10px] opacity-70 mt-0.5">{evt.time}</p>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Event Cards */}
      <div>
        <h3 className={`font-semibold mb-4 ${t.textPrimary}`}>Upcoming Events This Week</h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {upcomingEvents.slice(0, 3).map((evt, i) => (
            <div key={i} className={`rounded-xl p-4 border cursor-pointer transition-all ${t.card} ${t.cardHover}`}>
              <div className="flex items-center gap-2 mb-3">
                <span className={`w-2 h-2 rounded-full ${evt.color}`} />
                <span className={`text-xs font-medium ${t.textMuted}`}>{evt.type}</span>
              </div>
              <h4 className={`font-semibold text-sm mb-2 ${t.textPrimary}`}>{evt.title}</h4>
              <div className="space-y-1.5">
                <div className={`flex items-center gap-2 ${t.textMuted}`}>
                  <Clock size={12} /><span className="text-xs">{evt.date}</span>
                </div>
                <div className={`flex items-center gap-2 ${t.textMuted}`}>
                  <Video size={12} /><span className="text-xs">{evt.type}</span>
                </div>
                <div className={`flex items-center gap-2 ${t.textMuted}`}>
                  <User size={12} /><span className="text-xs">{evt.attendees} attendees</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
