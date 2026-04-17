// ── Mock Data ──────────────────────────────────────────────────────────────

export const ROLES = { ADMIN: "admin", ENGINEER: "engineer", LABOUR: "labour", MANAGER: "manager" };

export const TECHNICIANS = [
  { id: 1, name: "Ravi Kumar", email: "ravi@ism.com", phone: "9876543210", specialization: "HVAC", status: "Active", joinDate: "2022-03-15", jobsCompleted: 142, rating: 4.8, avatar: "RK" },
  { id: 2, name: "Suresh Patel", email: "suresh@ism.com", phone: "9876543211", specialization: "Electrical", status: "Active", joinDate: "2021-07-20", jobsCompleted: 198, rating: 4.6, avatar: "SP" },
  { id: 3, name: "Deepak Singh", email: "deepak@ism.com", phone: "9876543212", specialization: "Plumbing", status: "On Leave", joinDate: "2023-01-10", jobsCompleted: 87, rating: 4.5, avatar: "DS" },
  { id: 4, name: "Anil Verma", email: "anil@ism.com", phone: "9876543213", specialization: "Carpentry", status: "Active", joinDate: "2020-11-05", jobsCompleted: 234, rating: 4.9, avatar: "AV" },
  { id: 5, name: "Mohan Das", email: "mohan@ism.com", phone: "9876543214", specialization: "HVAC", status: "Inactive", joinDate: "2022-08-18", jobsCompleted: 55, rating: 4.2, avatar: "MD" },
];

export const CLIENTS = [
  { id: 1, name: "TechCorp Solutions", contact: "Neha Joshi", email: "neha@techcorp.com", phone: "9123456789", address: "Bandra West, Mumbai", type: "Corporate", status: "Active", contractValue: 450000, joinDate: "2021-04-01" },
  { id: 2, name: "Sunflower Apartments", contact: "Ramesh Shah", email: "ramesh@sunflower.com", phone: "9123456790", address: "Andheri East, Mumbai", type: "Residential", status: "Active", contractValue: 180000, joinDate: "2022-06-15" },
  { id: 3, name: "City Mall Group", contact: "Meena Kapoor", email: "meena@citymall.com", phone: "9123456791", address: "Thane, Mumbai", type: "Commercial", status: "Active", contractValue: 820000, joinDate: "2020-01-10" },
  { id: 4, name: "Green Valley Society", contact: "Ajay Gupta", email: "ajay@greenvalley.com", phone: "9123456792", address: "Powai, Mumbai", type: "Residential", status: "Inactive", contractValue: 95000, joinDate: "2023-02-20" },
  { id: 5, name: "Horizon Hospitals", contact: "Dr. Sharma", email: "admin@horizon.com", phone: "9123456793", address: "Dadar, Mumbai", type: "Healthcare", status: "Active", contractValue: 1200000, joinDate: "2019-09-01" },
];

export const JOBS = [
  { id: "JOB-001", title: "HVAC Annual Servicing", clientId: 1, technicianId: 1, status: "Closed", priority: "High", category: "Maintenance", raisedDate: "2024-01-05", scheduledDate: "2024-01-10", closedDate: "2024-01-10", description: "Complete HVAC system servicing including filter replacement and coolant check.", amount: 18500, images: [] },
  { id: "JOB-002", title: "Electrical Panel Upgrade", clientId: 3, technicianId: 2, status: "In Progress", priority: "Critical", category: "Repair", raisedDate: "2024-01-12", scheduledDate: "2024-01-15", closedDate: null, description: "Upgrade main electrical panel to 3-phase 200A.", amount: 45000, images: [] },
  { id: "JOB-003", title: "Plumbing Leak Fix", clientId: 2, technicianId: 3, status: "Assigned", priority: "Medium", category: "Repair", raisedDate: "2024-01-14", scheduledDate: "2024-01-16", closedDate: null, description: "Fix water leakage in basement level 2.", amount: 8000, images: [] },
  { id: "JOB-004", title: "Office Renovation Carpentry", clientId: 1, technicianId: 4, status: "Raised", priority: "Low", category: "Installation", raisedDate: "2024-01-15", scheduledDate: null, closedDate: null, description: "Custom wooden partitions for open office space.", amount: 65000, images: [] },
  { id: "JOB-005", title: "Generator Maintenance", clientId: 5, technicianId: 1, status: "Closed", priority: "High", category: "Maintenance", raisedDate: "2024-01-08", scheduledDate: "2024-01-09", closedDate: "2024-01-09", description: "Monthly generator servicing and load testing.", amount: 12000, images: [] },
  { id: "JOB-006", title: "AC Installation - Ward B", clientId: 5, technicianId: 2, status: "In Progress", priority: "High", category: "Installation", raisedDate: "2024-01-13", scheduledDate: "2024-01-16", closedDate: null, description: "Install 5 ton split AC units in ward B.", amount: 85000, images: [] },
];

export const REPORTS = [
  { id: "RPT-001", jobId: "JOB-001", title: "HVAC Servicing Report", technicianId: 1, date: "2024-01-10", findings: "All units cleaned. Replaced 3 filters. Coolant refilled.", recommendations: "Next service due in 6 months.", status: "Approved", images: [] },
  { id: "RPT-002", jobId: "JOB-005", title: "Generator Maintenance Report", technicianId: 1, date: "2024-01-09", findings: "Oil changed, battery checked, load test passed.", recommendations: "Replace battery in next quarter.", status: "Approved", images: [] },
];

export const QUOTATIONS = [
  { id: "QT-001", clientId: 1, title: "Annual HVAC Contract", amount: 180000, status: "Approved", validTill: "2024-03-31", createdDate: "2024-01-01", items: [{ description: "HVAC Servicing (4 units)", qty: 4, rate: 18000, total: 72000 }, { description: "Filter Replacement", qty: 12, rate: 2000, total: 24000 }, { description: "Emergency Callouts (12)", qty: 12, rate: 7000, total: 84000 }] },
  { id: "QT-002", clientId: 3, title: "Electrical Upgrade Package", amount: 245000, status: "Pending", validTill: "2024-02-28", createdDate: "2024-01-12", items: [{ description: "Panel Upgrade", qty: 1, rate: 45000, total: 45000 }, { description: "Wiring Replacement", qty: 1, rate: 150000, total: 150000 }, { description: "Safety Audit", qty: 1, rate: 50000, total: 50000 }] },
  { id: "QT-003", clientId: 5, title: "Full Facility Management", amount: 1200000, status: "Approved", validTill: "2024-12-31", createdDate: "2024-01-05", items: [{ description: "Monthly Maintenance", qty: 12, rate: 80000, total: 960000 }, { description: "Emergency Services", qty: 1, rate: 240000, total: 240000 }] },
];

export const AMC_CONTRACTS = [
  { id: "AMC-001", clientId: 1, title: "HVAC AMC - TechCorp", startDate: "2024-01-01", endDate: "2024-12-31", value: 450000, status: "Active", services: ["HVAC Servicing", "Filter Replacement", "Emergency Support"], renewalReminder: 30, nextService: "2024-04-01" },
  { id: "AMC-002", clientId: 5, title: "Full Facility AMC - Horizon", startDate: "2024-01-01", endDate: "2024-12-31", value: 1200000, status: "Active", services: ["Electrical", "Plumbing", "HVAC", "Generator"], renewalReminder: 60, nextService: "2024-02-01" },
  { id: "AMC-003", clientId: 2, title: "Plumbing AMC - Sunflower", startDate: "2023-07-01", endDate: "2024-06-30", value: 180000, status: "Expiring Soon", services: ["Plumbing Maintenance", "Drain Cleaning"], renewalReminder: 30, nextService: "2024-02-15" },
];

export const ATTENDANCE = [
  { id: 1, technicianId: 1, date: "2024-01-15", checkIn: "08:55", checkOut: "17:30", status: "Present", hours: 8.6 },
  { id: 2, technicianId: 2, date: "2024-01-15", checkIn: "09:10", checkOut: "17:45", status: "Present", hours: 8.6 },
  { id: 3, technicianId: 3, date: "2024-01-15", checkIn: null, checkOut: null, status: "Absent", hours: 0 },
  { id: 4, technicianId: 4, date: "2024-01-15", checkIn: "08:30", checkOut: "17:00", status: "Present", hours: 8.5 },
  { id: 5, technicianId: 1, date: "2024-01-14", checkIn: "09:00", checkOut: "18:00", status: "Present", hours: 9.0 },
  { id: 6, technicianId: 2, date: "2024-01-14", checkIn: "09:30", checkOut: "17:30", status: "Late", hours: 8.0 },
  { id: 7, technicianId: 3, date: "2024-01-14", checkIn: "09:00", checkOut: "17:00", status: "Present", hours: 8.0 },
];

export const ACTIVITY_LOG = [
  { id: 1, type: "job", action: "Job JOB-006 status updated to In Progress", user: "Priya Sharma", timestamp: "2024-01-15 14:32" },
  { id: 2, type: "client", action: "New client Horizon Hospitals added", user: "Arjun Mehta", timestamp: "2024-01-15 11:15" },
  { id: 3, type: "quotation", action: "Quotation QT-002 sent to City Mall Group", user: "Arjun Mehta", timestamp: "2024-01-14 16:45" },
  { id: 4, type: "amc", action: "AMC-003 renewal reminder set", user: "Priya Sharma", timestamp: "2024-01-14 10:00" },
  { id: 5, type: "technician", action: "Deepak Singh marked On Leave", user: "Arjun Mehta", timestamp: "2024-01-13 09:30" },
  { id: 6, type: "report", action: "Report RPT-002 approved", user: "Arjun Mehta", timestamp: "2024-01-12 17:00" },
];

export const MONTHLY_JOBS = [
  { month: "Aug", jobs: 18, completed: 15, revenue: 280000 },
  { month: "Sep", jobs: 22, completed: 20, revenue: 340000 },
  { month: "Oct", jobs: 19, completed: 17, revenue: 310000 },
  { month: "Nov", jobs: 25, completed: 23, revenue: 420000 },
  { month: "Dec", jobs: 28, completed: 25, revenue: 480000 },
  { month: "Jan", jobs: 24, completed: 19, revenue: 390000 },
];

export const EMAIL_SETTINGS = {
  smtpHost: "smtp.gmail.com",
  smtpPort: "587",
  fromEmail: "notifications@vdti.com",
  fromName: "VDTI Service Hub",
  notifications: {
    jobRaised: true,
    jobAssigned: true,
    jobCompleted: true,
    reportApproved: false,
    amcRenewal: true,
    quotationSent: true,
  },
};
