export const revenueData = [
  { month: "Jan", revenue: 42000, target: 38000, deals: 18 },
  { month: "Feb", revenue: 51000, target: 42000, deals: 22 },
  { month: "Mar", revenue: 47000, target: 45000, deals: 19 },
  { month: "Apr", revenue: 63000, target: 50000, deals: 27 },
  { month: "May", revenue: 58000, target: 55000, deals: 24 },
  { month: "Jun", revenue: 72000, target: 60000, deals: 31 },
  { month: "Jul", revenue: 68000, target: 65000, deals: 28 },
  { month: "Aug", revenue: 81000, target: 70000, deals: 34 },
  { month: "Sep", revenue: 76000, target: 73000, deals: 30 },
  { month: "Oct", revenue: 89000, target: 78000, deals: 38 },
  { month: "Nov", revenue: 94000, target: 84000, deals: 41 },
  { month: "Dec", revenue: 102000, target: 90000, deals: 45 },
];

export const pipelineData = [
  { name: "Lead", value: 120, color: "#6366f1" },
  { name: "Qualified", value: 84, color: "#8b5cf6" },
  { name: "Proposal", value: 56, color: "#a78bfa" },
  { name: "Negotiation", value: 32, color: "#c4b5fd" },
  { name: "Closed Won", value: 18, color: "#34d399" },
];

export const leadSourceData = [
  { name: "Organic Search", value: 32, color: "#6366f1" },
  { name: "Paid Ads", value: 24, color: "#8b5cf6" },
  { name: "Referral", value: 18, color: "#06b6d4" },
  { name: "Social Media", value: 14, color: "#f59e0b" },
  { name: "Email", value: 12, color: "#34d399" },
];

export const contacts = [
  { id: 1, name: "Sarah Johnson", company: "TechNova Inc.", email: "sarah@technova.com", phone: "+1 (555) 234-5678", stage: "Qualified", value: "$12,400", avatar: "SJ", status: "active", lastContact: "2h ago" },
  { id: 2, name: "Michael Chen", company: "Global Ventures", email: "m.chen@globalventures.io", phone: "+1 (555) 876-5432", stage: "Proposal", value: "$28,000", avatar: "MC", status: "active", lastContact: "1d ago" },
  { id: 3, name: "Emma Williams", company: "Creative Studio Co.", email: "emma@creativestudio.co", phone: "+1 (555) 345-6789", stage: "Negotiation", value: "$8,750", avatar: "EW", status: "inactive", lastContact: "3d ago" },
  { id: 4, name: "James Rodriguez", company: "DataSphere Ltd.", email: "james.r@datasphere.com", phone: "+1 (555) 654-3210", stage: "Lead", value: "$45,200", avatar: "JR", status: "active", lastContact: "5h ago" },
  { id: 5, name: "Olivia Smith", company: "Pinnacle Corp.", email: "o.smith@pinnacle.com", phone: "+1 (555) 789-0123", stage: "Closed Won", value: "$19,800", avatar: "OS", status: "active", lastContact: "1h ago" },
  { id: 6, name: "David Park", company: "Horizon Analytics", email: "dpark@horizon.ai", phone: "+1 (555) 432-1098", stage: "Qualified", value: "$33,500", avatar: "DP", status: "active", lastContact: "2d ago" },
  { id: 7, name: "Ava Martinez", company: "BlueSky Systems", email: "ava.m@bluesky.dev", phone: "+1 (555) 567-8901", stage: "Proposal", value: "$15,600", avatar: "AM", status: "inactive", lastContact: "4d ago" },
];

export const deals = [
  { id: 1, title: "Enterprise SaaS License", company: "TechNova Inc.", contact: "Sarah Johnson", value: "$84,000", stage: "Negotiation", probability: 75, closeDate: "Dec 31, 2024", owner: "Alex Turner" },
  { id: 2, title: "Cloud Migration Project", company: "DataSphere Ltd.", contact: "James Rodriguez", value: "$126,500", stage: "Proposal", probability: 55, closeDate: "Jan 15, 2025", owner: "Mia Chen" },
  { id: 3, title: "Annual Support Contract", company: "Pinnacle Corp.", contact: "Olivia Smith", value: "$24,000", stage: "Closed Won", probability: 100, closeDate: "Nov 20, 2024", owner: "Alex Turner" },
  { id: 4, title: "Digital Transformation", company: "Global Ventures", contact: "Michael Chen", value: "$210,000", stage: "Qualified", probability: 40, closeDate: "Feb 28, 2025", owner: "Jordan Lee" },
  { id: 5, title: "BI Dashboard Setup", company: "Horizon Analytics", contact: "David Park", value: "$56,000", stage: "Proposal", probability: 60, closeDate: "Jan 10, 2025", owner: "Mia Chen" },
  { id: 6, title: "SEO & Marketing Bundle", company: "Creative Studio Co.", contact: "Emma Williams", value: "$18,400", stage: "Lead", probability: 20, closeDate: "Mar 1, 2025", owner: "Jordan Lee" },
];

export const activities = [
  { id: 1, type: "call", user: "Alex Turner", action: "Called", target: "Sarah Johnson", time: "2 minutes ago", icon: "phone" },
  { id: 2, type: "email", user: "Mia Chen", action: "Sent email to", target: "James Rodriguez", time: "18 minutes ago", icon: "mail" },
  { id: 3, type: "deal", user: "Jordan Lee", action: "Closed deal with", target: "Pinnacle Corp.", time: "1 hour ago", icon: "check-circle" },
  { id: 4, type: "note", user: "Alex Turner", action: "Added note for", target: "Global Ventures", time: "3 hours ago", icon: "file-text" },
  { id: 5, type: "meeting", user: "Mia Chen", action: "Scheduled meeting with", target: "David Park", time: "5 hours ago", icon: "calendar" },
  { id: 6, type: "contact", user: "Jordan Lee", action: "Created contact", target: "Ava Martinez", time: "Yesterday" , icon: "user-plus" },
];

export const tasks = [
  { id: 1, title: "Follow up with TechNova Inc.", due: "Today, 2:00 PM", priority: "high", done: false, assignee: "Alex Turner" },
  { id: 2, title: "Prepare proposal for DataSphere", due: "Tomorrow, 10:00 AM", priority: "medium", done: false, assignee: "Mia Chen" },
  { id: 3, title: "Send contract to Pinnacle Corp.", due: "Today, 5:00 PM", priority: "high", done: true, assignee: "Alex Turner" },
  { id: 4, title: "Review Q4 pipeline performance", due: "Dec 28, 2024", priority: "low", done: false, assignee: "Jordan Lee" },
  { id: 5, title: "Update CRM contact list", due: "Dec 30, 2024", priority: "medium", done: false, assignee: "Mia Chen" },
];

export const teamMembers = [
  { id: 1, name: "Alex Turner", role: "Sales Manager", deals: 14, revenue: "$284,000", conversion: "68%", avatar: "AT", status: "online" },
  { id: 2, name: "Mia Chen", role: "Account Executive", deals: 11, revenue: "$196,500", conversion: "61%", avatar: "MC", status: "online" },
  { id: 3, name: "Jordan Lee", role: "Sales Representative", deals: 9, revenue: "$142,000", conversion: "54%", avatar: "JL", status: "away" },
  { id: 4, name: "Priya Sharma", role: "Business Dev.", deals: 7, revenue: "$98,400", conversion: "47%", avatar: "PS", status: "offline" },
];

export const weeklyActivity = [
  { day: "Mon", calls: 12, emails: 28, meetings: 4 },
  { day: "Tue", calls: 18, emails: 35, meetings: 6 },
  { day: "Wed", calls: 14, emails: 22, meetings: 8 },
  { day: "Thu", calls: 22, emails: 41, meetings: 5 },
  { day: "Fri", calls: 16, emails: 30, meetings: 7 },
  { day: "Sat", calls: 4, emails: 8, meetings: 1 },
  { day: "Sun", calls: 2, emails: 5, meetings: 0 },
];
