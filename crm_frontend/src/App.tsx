import React, { useState } from "react";
import Sidebar from "./components/Sidebar";
import Topbar from "./components/Topbar";
import Dashboard from "./pages/Dashboard";
import Contacts from "./pages/Contacts";
import Deals from "./pages/Deals";
import Pipeline from "./pages/Pipeline";
import Analytics from "./pages/Analytics";
import Activities from "./pages/Activities";
import CalendarPage from "./pages/CalendarPage";
import Tasks from "./pages/Tasks";
import Messages from "./pages/Messages";
import Reports from "./pages/Reports";
import Settings from "./pages/Settings";

const pages: Record<string, React.ReactElement> = {
  dashboard: <Dashboard />,
  contacts: <Contacts />,
  deals: <Deals />,
  pipeline: <Pipeline />,
  analytics: <Analytics />,
  activities: <Activities />,
  calendar: <CalendarPage />,
  tasks: <Tasks />,
  messages: <Messages />,
  reports: <Reports />,
  settings: <Settings />,
  help: <Dashboard />,
};

export default function App() {
  const [activeTab, setActiveTab] = useState("dashboard");
  const [mobileSidebarOpen, setMobileSidebarOpen] = useState(false);

  const handleTabChange = (tab: string) => {
    setActiveTab(tab);
    setMobileSidebarOpen(false);
  };

  return (
    <div className="flex min-h-screen bg-base">
      {/* Mobile overlay */}
      {mobileSidebarOpen && (
        <div
          className="fixed inset-0 bg-black/60 z-40 lg:hidden"
          onClick={() => setMobileSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <div
        className={`fixed inset-y-0 left-0 z-50 lg:static lg:z-auto lg:flex transition-transform duration-300 ease-in-out ${
          mobileSidebarOpen ? "translate-x-0" : "-translate-x-full lg:translate-x-0"
        }`}
      >
        <Sidebar activeTab={activeTab} setActiveTab={handleTabChange} />
      </div>

      {/* Main */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        <Topbar
          activeTab={activeTab}
          onMenuClick={() => setMobileSidebarOpen(true)}
        />
        <main className="flex-1 overflow-y-auto">
          {pages[activeTab] || pages["dashboard"]}
        </main>
      </div>
    </div>
  );
}
