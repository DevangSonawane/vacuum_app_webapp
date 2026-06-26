import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import {
  Briefcase, Users, UserCog, DollarSign,
  TrendingUp, RefreshCw, ChevronRight, Calendar,
  Clock, FileText, CheckCircle, Star, MapPin, Phone,
} from "lucide-react";
import axios from "axios";
import { useApp } from "../context/AppContext";
import { PageTransition, StatCard, Card, Badge, Avatar } from "../components/ui";
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer,
  LineChart, Line, PieChart, Pie, Cell, CartesianGrid,
} from "recharts";

const API_BASE_URL = "https://apivdti.asynk.in/api";

const PIE_COLORS = {
  Raised:        "#a855f7",
  Assigned:      "#3b82f6",
  "In Progress": "#f59e0b",
  Closed:        "#10b981",
};

const STATUS_COLORS = {
  Closed:        "bg-emerald-100 text-emerald-700",
  "In Progress": "bg-amber-100 text-amber-700",
  Assigned:      "bg-blue-100 text-blue-700",
  Raised:        "bg-purple-100 text-purple-700",
};
const PRIORITY_COLORS = {
  Critical: "bg-red-100 text-red-700",
  High:     "bg-orange-100 text-orange-700",
  Medium:   "bg-blue-100 text-blue-700",
  Low:      "bg-gray-100 text-gray-600",
};

const CustomTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-white dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-xl p-3 shadow-lg text-sm">
      <p className="font-semibold text-gray-700 dark:text-gray-200 mb-1">{label}</p>
      {payload.map(p => (
        <p key={p.name} style={{ color: p.color }}>
          {p.name}: {p.name.toLowerCase().includes("revenue") ? `₹${Number(p.value).toLocaleString()}` : p.value}
        </p>
      ))}
    </div>
  );
};

function Skeleton({ className = "", style }) {
  return (
    <div className={`relative overflow-hidden bg-gray-100 dark:bg-gray-800 rounded-2xl ${className}`} style={style}>
      <motion.div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/50 dark:via-white/10 to-transparent" animate={{ x: ["-100%", "100%"] }} transition={{ duration: 1.4, repeat: Infinity, ease: "linear" }} />
    </div>
  );
}

function StatCardSkeleton() {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 p-5 overflow-hidden relative">
      <div className="absolute top-0 right-0 w-24 h-24 bg-gray-100 dark:bg-gray-700 opacity-40 rounded-full translate-x-8 -translate-y-8" />
      <Skeleton className="h-3 w-24 rounded-lg mb-3" />
      <Skeleton className="h-8 w-20 rounded-xl mb-2" />
      <Skeleton className="h-2.5 w-28 rounded-lg" />
    </div>
  );
}

function DashboardSkeleton() {
  return (
    <div className="p-4 md:p-6 space-y-6 max-w-7xl mx-auto">
      <div className="flex items-center justify-between">
        <div><Skeleton className="h-7 w-36 rounded-xl mb-2" /><Skeleton className="h-4 w-64 rounded-lg" /></div>
        <Skeleton className="h-9 w-9 rounded-xl" />
      </div>
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[...Array(4)].map((_, i) => <motion.div key={i} initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.07 }}><StatCardSkeleton /></motion.div>)}
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <Skeleton className="lg:col-span-2 h-72 rounded-2xl" />
        <Skeleton className="h-72 rounded-2xl" />
      </div>
      <Skeleton className="h-64 rounded-2xl" />
    </div>
  );
}

const fmtRevenue = (v) => {
  if (v >= 100000) return `₹${(v / 100000).toFixed(1)}L`;
  if (v >= 1000)   return `₹${(v / 1000).toFixed(0)}k`;
  return `₹${v}`;
};

const pct = (v, t) => (t > 0 ? Math.round((v / t) * 100) : 0);

// ─────────────────────────────────────────────────────────────
// Main Dashboard
// ─────────────────────────────────────────────────────────────
export default function Dashboard() {
  const navigate = useNavigate();
  const { currentUser } = useApp();
  const [data, setData]       = useState(null);
  const [role, setRole]       = useState(null);
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState(null);

  useEffect(() => { fetchDashboard(); }, []);

  const fetchDashboard = async () => {
    setLoading(true);
    setError(null);
    try {
      const token  = localStorage.getItem("token");
      const isAdmin = ["admin", "manager"].includes(currentUser?.role?.toLowerCase());
      const url    = isAdmin ? `${API_BASE_URL}/dashboard` : `${API_BASE_URL}/dashboard/my`;
      const res    = await axios.get(url, { headers: { Authorization: `Bearer ${token}` } });
      if (res.data.success) {
        setData(res.data.data);
        setRole(isAdmin ? "admin" : (res.data.role || currentUser?.role || null));
        setProfile(res.data.technician_profile || null);
      } else {
        setError("Failed to load dashboard");
      }
    } catch (err) {
      setError(err.response?.data?.message || "Failed to load dashboard");
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <PageTransition><DashboardSkeleton /></PageTransition>;

  if (error || !data) {
    return (
      <PageTransition>
        <div className="p-8 text-center text-gray-400">
          <p className="mb-3">{error || "No data"}</p>
          <button onClick={fetchDashboard} className="text-blue-500 hover:underline text-sm">Retry</button>
        </div>
      </PageTransition>
    );
  }

  const isTechnician = ["technician", "engineer", "labour"].includes(role);

  if (isTechnician) {
    return <TechnicianDashboard data={data} profile={profile} navigate={navigate} onRefresh={fetchDashboard} />;
  }

  return <AdminDashboard data={data} navigate={navigate} onRefresh={fetchDashboard} />;
}

// ─────────────────────────────────────────────────────────────
// Admin / Manager Dashboard
// ─────────────────────────────────────────────────────────────
function AdminDashboard({ data, navigate, onRefresh }) {
  const { stats, job_status_breakdown, monthly_stats, revenue_trend, quick_overview, recent_jobs } = data;

  const barData = (monthly_stats || []).map(m => ({
    month: m.month.replace(" 20", " '"), jobs: m.jobs_raised, completed: m.jobs_completed, revenue: m.revenue,
  }));
  const lineData = (revenue_trend || []).map(m => ({ month: m.month.replace(" 20", " '"), revenue: m.revenue }));
  const pieData = (job_status_breakdown || []).map(s => ({ name: s.status, value: s.count, color: PIE_COLORS[s.status] || "#94a3b8" }));
  const qo = quick_overview || {};

  return (
    <PageTransition>
      <div className="p-4 md:p-6 space-y-6 max-w-7xl mx-auto">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white font-display">Dashboard</h1>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-0.5">Welcome back — here's what's happening today.</p>
          </div>
          <button onClick={onRefresh} className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-xl transition" title="Refresh">
            <RefreshCw size={18} />
          </button>
        </div>

        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[
            { title: "Active Jobs", value: stats.active_jobs, icon: Briefcase, color: "blue", change: stats.mom_active_jobs },
            { title: "Total Clients", value: stats.total_clients, icon: Users, color: "emerald", change: stats.mom_clients },
            { title: "Technicians", value: stats.active_technicians, icon: UserCog, color: "purple", subtitle: `${stats.total_technicians} total` },
            { title: "Revenue (Approved)", value: fmtRevenue(stats.revenue_approved || 0), icon: DollarSign, color: "amber", change: stats.mom_revenue },
          ].map((s, i) => (
            <motion.div key={s.title} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.08 }}>
              <StatCard {...s} />
            </motion.div>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <Card className="col-span-1 lg:col-span-2 p-5">
            <div className="flex items-center justify-between mb-4">
              <div><h3 className="font-bold text-gray-800 dark:text-white font-display">Jobs & Revenue</h3><p className="text-xs text-gray-400">Last 6 months</p></div>
              <TrendingUp size={18} className="text-blue-500" />
            </div>
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={barData} barGap={4}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="month" tick={{ fontSize: 12 }} />
                <YAxis yAxisId="left" tick={{ fontSize: 11 }} />
                <YAxis yAxisId="right" orientation="right" tick={{ fontSize: 11 }} tickFormatter={v => `₹${(v / 1000).toFixed(0)}k`} />
                <Tooltip content={<CustomTooltip />} />
                <Bar yAxisId="left" dataKey="jobs" name="Jobs Raised" fill="#bfdbfe" radius={[4, 4, 0, 0]} />
                <Bar yAxisId="left" dataKey="completed" name="Jobs Completed" fill="#2563eb" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </Card>

          <Card className="p-5">
            <h3 className="font-bold text-gray-800 dark:text-white font-display mb-4">Job Status</h3>
            <ResponsiveContainer width="100%" height={180}>
              <PieChart>
                <Pie data={pieData} cx="50%" cy="50%" innerRadius={50} outerRadius={75} paddingAngle={3} dataKey="value">
                  {pieData.map((entry, i) => <Cell key={i} fill={entry.color} />)}
                </Pie>
                <Tooltip formatter={(v, n) => [v, n]} />
              </PieChart>
            </ResponsiveContainer>
            <div className="space-y-2 mt-2">
              {pieData.map(d => (
                <div key={d.name} className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2"><div className="w-2.5 h-2.5 rounded-full" style={{ background: d.color }} /><span className="text-gray-600 dark:text-gray-300">{d.name}</span></div>
                  <span className="font-semibold text-gray-800 dark:text-white">{d.value}</span>
                </div>
              ))}
            </div>
          </Card>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <Card className="col-span-1 lg:col-span-2 p-5">
            <h3 className="font-bold text-gray-800 dark:text-white font-display mb-4">Revenue Trend</h3>
            <ResponsiveContainer width="100%" height={180}>
              <LineChart data={lineData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="month" tick={{ fontSize: 12 }} />
                <YAxis tick={{ fontSize: 11 }} tickFormatter={v => `₹${(v / 1000).toFixed(0)}k`} />
                <Tooltip formatter={v => [`₹${Number(v).toLocaleString()}`, "Revenue"]} />
                <Line type="monotone" dataKey="revenue" stroke="#2563eb" strokeWidth={3} dot={{ fill: "#2563eb", r: 4 }} activeDot={{ r: 6 }} />
              </LineChart>
            </ResponsiveContainer>
          </Card>

          <Card className="p-5">
            <h3 className="font-bold text-gray-800 dark:text-white font-display mb-4">Quick Overview</h3>
            <div className="space-y-4">
              {[
                { label: "Jobs This Month", v: qo.jobs_this_month?.value ?? 0, t: qo.jobs_this_month?.target ?? 30, color: "bg-blue-500" },
                { label: "Jobs Completed", v: qo.jobs_completed?.value ?? 0, t: qo.jobs_completed?.target ?? 1, color: "bg-emerald-500" },
                { label: "Active Technicians", v: qo.active_technicians?.value ?? 0, t: qo.active_technicians?.target ?? 1, color: "bg-purple-500" },
                { label: "AMC Active", v: qo.amc_active?.value ?? 0, t: qo.amc_active?.target ?? 1, color: "bg-amber-500" },
              ].map(s => (
                <div key={s.label}>
                  <div className="flex justify-between text-xs mb-1">
                    <span className="text-gray-600 dark:text-gray-300 font-medium">{s.label}</span>
                    <span className="font-bold text-gray-800 dark:text-white">{s.v}/{s.t}</span>
                  </div>
                  <div className="h-2 bg-gray-100 dark:bg-gray-700 rounded-full overflow-hidden">
                    <motion.div initial={{ width: 0 }} animate={{ width: `${pct(s.v, s.t)}%` }} transition={{ duration: 0.8, delay: 0.3 }} className={`h-full ${s.color} rounded-full`} />
                  </div>
                </div>
              ))}
            </div>
          </Card>
        </div>

        <Card className="p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold text-gray-800 dark:text-white font-display">Recent Work Orders</h3>
            <button onClick={() => navigate("/jobs")} className="text-xs text-blue-500 hover:text-blue-600 font-semibold flex items-center gap-1">View all <ChevronRight size={12} /></button>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead><tr className="border-b border-gray-100 dark:border-gray-700">
                {["Job ID", "Title", "Client", "Status", "Priority", "Amount"].map(h => (
                  <th key={h} className="text-left py-2 px-3 text-xs text-gray-500 dark:text-gray-400 font-semibold">{h}</th>
                ))}
              </tr></thead>
              <tbody>
                {(data.recent_jobs || []).map(job => (
                  <motion.tr key={job.id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} onClick={() => navigate(`/jobs/${job.id}`)}
                    className="border-b border-gray-50 dark:border-gray-700/50 hover:bg-blue-50/30 dark:hover:bg-blue-900/10 transition cursor-pointer">
                    <td className="py-2.5 px-3 font-mono text-blue-600 dark:text-blue-400 text-xs">{job.id}</td>
                    <td className="py-2.5 px-3 font-medium text-gray-800 dark:text-gray-200 max-w-[160px] truncate">{job.title}</td>
                    <td className="py-2.5 px-3 text-gray-500 dark:text-gray-400">{job.client_name || "—"}</td>
                    <td className="py-2.5 px-3"><span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${STATUS_COLORS[job.status] || "bg-gray-100 text-gray-600"}`}>{job.status}</span></td>
                    <td className="py-2.5 px-3"><span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${PRIORITY_COLORS[job.priority] || "bg-gray-100 text-gray-600"}`}>{job.priority}</span></td>
                    <td className="py-2.5 px-3 font-semibold text-gray-800 dark:text-gray-200">₹{Number(job.amount || 0).toLocaleString()}</td>
                  </motion.tr>
                ))}
              </tbody>
            </table>
            {(!data.recent_jobs || data.recent_jobs.length === 0) && <p className="text-center text-gray-400 text-sm py-8">No recent jobs</p>}
          </div>
        </Card>
      </div>
    </PageTransition>
  );
}

// ─────────────────────────────────────────────────────────────
// Technician / Engineer / Labour Dashboard
// ─────────────────────────────────────────────────────────────
function TechnicianDashboard({ data, profile, navigate, onRefresh }) {
  const { stats, job_status_breakdown, monthly_stats, today_visits, upcoming_visits, recent_jobs } = data;
  const s = stats || {};

  const pieData = (job_status_breakdown || []).map(d => ({ name: d.status, value: d.count, color: PIE_COLORS[d.status] || "#94a3b8" }));
  const barData = (monthly_stats || []).map(m => ({
    month: m.month.replace(" 20", " '"),
    assigned: m.jobs_assigned,
    completed: m.jobs_completed,
  }));

  function formatDate(raw) {
    if (!raw) return "";
    const d = new Date(raw);
    if (isNaN(d)) return raw;
    return d.toLocaleDateString("en-IN", { day: "numeric", month: "short" });
  }

  return (
    <PageTransition>
      <div className="p-4 md:p-6 space-y-6 max-w-7xl mx-auto">

        {/* Header with profile */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            {profile && (
              <Avatar initials={profile.avatar || profile.name?.slice(0, 2).toUpperCase() || "??"} size="lg" />
            )}
            <div>
              <h1 className="text-xl md:text-2xl font-bold text-gray-900 dark:text-white font-display">
                {profile ? `Hi, ${profile.name}` : "Dashboard"}
              </h1>
              <div className="flex items-center gap-2 mt-0.5">
                {profile?.specialization && <span className="text-sm text-blue-600 dark:text-blue-400 font-medium">{profile.specialization}</span>}
                {profile?.rating > 0 && (
                  <span className="flex items-center gap-1 text-xs text-amber-500">
                    <Star size={12} className="fill-amber-400" /> {Number(profile.rating).toFixed(1)}
                  </span>
                )}
              </div>
            </div>
          </div>
          <button onClick={onRefresh} className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-xl transition" title="Refresh">
            <RefreshCw size={18} />
          </button>
        </div>

        {/* KPI Cards */}
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
          {[
            { title: "Today's Visits", value: s.today_visits ?? 0, icon: Calendar, color: "blue" },
            { title: "This Week",      value: s.week_visits ?? 0,  icon: Clock,    color: "purple" },
            { title: "Open Jobs",      value: s.open_jobs ?? 0,    icon: Briefcase,color: "amber" },
            { title: "Closed Jobs",    value: s.closed_jobs ?? 0,  icon: CheckCircle, color: "emerald" },
            { title: "Pending Reports",value: s.pending_reports ?? 0, icon: FileText, color: "orange" },
            { title: "Revenue",        value: fmtRevenue(s.total_revenue || 0), icon: DollarSign, color: "blue" },
          ].map((kpi, i) => (
            <motion.div key={kpi.title} initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.06 }}>
              <StatCard {...kpi} />
            </motion.div>
          ))}
        </div>

        {/* Charts */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <Card className="lg:col-span-2 p-5">
            <div className="flex items-center justify-between mb-4">
              <div><h3 className="font-bold text-gray-800 dark:text-white font-display">Monthly Performance</h3><p className="text-xs text-gray-400">Assigned vs Completed</p></div>
              <TrendingUp size={18} className="text-blue-500" />
            </div>
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={barData} barGap={4}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="month" tick={{ fontSize: 12 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip content={<CustomTooltip />} />
                <Bar dataKey="assigned" name="Assigned" fill="#bfdbfe" radius={[4, 4, 0, 0]} />
                <Bar dataKey="completed" name="Completed" fill="#2563eb" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </Card>

          <Card className="p-5">
            <h3 className="font-bold text-gray-800 dark:text-white font-display mb-4">Job Status</h3>
            <ResponsiveContainer width="100%" height={180}>
              <PieChart>
                <Pie data={pieData} cx="50%" cy="50%" innerRadius={45} outerRadius={70} paddingAngle={3} dataKey="value">
                  {pieData.map((entry, i) => <Cell key={i} fill={entry.color} />)}
                </Pie>
                <Tooltip formatter={(v, n) => [v, n]} />
              </PieChart>
            </ResponsiveContainer>
            <div className="space-y-2 mt-2">
              {pieData.map(d => (
                <div key={d.name} className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2"><div className="w-2.5 h-2.5 rounded-full" style={{ background: d.color }} /><span className="text-gray-600 dark:text-gray-300">{d.name}</span></div>
                  <span className="font-semibold text-gray-800 dark:text-white">{d.value}</span>
                </div>
              ))}
            </div>
          </Card>
        </div>

        {/* Today's Schedule + Upcoming */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {/* Today */}
          <Card className="p-5">
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-bold text-gray-800 dark:text-white font-display">Today's Schedule</h3>
              <span className="text-xs font-bold text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/20 px-2 py-0.5 rounded-full">{(today_visits || []).length} visits</span>
            </div>
            {(!today_visits || today_visits.length === 0) ? (
              <div className="text-center py-8">
                <Calendar size={28} className="mx-auto mb-2 text-gray-300 dark:text-gray-600" />
                <p className="text-sm text-gray-400">No visits scheduled today</p>
              </div>
            ) : (
              <div className="space-y-3">
                {today_visits.map(v => (
                  <div key={v.id} onClick={() => navigate(`/jobs/${v.id}`)}
                    className="flex items-center gap-3 p-3 rounded-xl bg-gray-50 dark:bg-gray-700/50 hover:bg-blue-50/50 dark:hover:bg-blue-900/10 cursor-pointer transition">
                    <div className="w-10 h-10 rounded-xl bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center flex-shrink-0">
                      <Briefcase size={16} className="text-blue-600" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">{v.title}</p>
                      <div className="flex items-center gap-2 mt-0.5 text-xs text-gray-500 dark:text-gray-400">
                        <span>{v.client_name}</span>
                        {v.site_location && <span className="flex items-center gap-0.5"><MapPin size={10} />{v.site_location}</span>}
                      </div>
                    </div>
                    <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold flex-shrink-0 ${STATUS_COLORS[v.status] || "bg-gray-100 text-gray-600"}`}>{v.status}</span>
                  </div>
                ))}
              </div>
            )}
          </Card>

          {/* Upcoming */}
          <Card className="p-5">
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-bold text-gray-800 dark:text-white font-display">Upcoming (14 days)</h3>
              <span className="text-xs font-bold text-purple-600 dark:text-purple-400 bg-purple-50 dark:bg-purple-900/20 px-2 py-0.5 rounded-full">{(upcoming_visits || []).length}</span>
            </div>
            {(!upcoming_visits || upcoming_visits.length === 0) ? (
              <div className="text-center py-8">
                <Clock size={28} className="mx-auto mb-2 text-gray-300 dark:text-gray-600" />
                <p className="text-sm text-gray-400">No upcoming visits</p>
              </div>
            ) : (
              <div className="space-y-3">
                {upcoming_visits.map(v => (
                  <div key={v.id} onClick={() => navigate(`/jobs/${v.id}`)}
                    className="flex items-center gap-3 p-3 rounded-xl bg-gray-50 dark:bg-gray-700/50 hover:bg-purple-50/50 dark:hover:bg-purple-900/10 cursor-pointer transition">
                    <div className="w-10 h-10 rounded-xl bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center flex-shrink-0">
                      <Calendar size={16} className="text-purple-600" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">{v.title}</p>
                      <div className="flex flex-wrap items-center gap-x-2 gap-y-0.5 mt-0.5 text-xs text-gray-500 dark:text-gray-400">
                        <span>{v.client_name}</span>
                        {v.site_location && <span className="flex items-center gap-0.5"><MapPin size={10} />{v.site_location}</span>}
                        {v.client_phone && <span className="flex items-center gap-0.5"><Phone size={10} />{v.client_phone}</span>}
                      </div>
                    </div>
                    <div className="text-right flex-shrink-0">
                      <p className="text-xs font-bold text-gray-800 dark:text-gray-200">{formatDate(v.scheduled_date)}</p>
                      <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${STATUS_COLORS[v.status] || "bg-gray-100 text-gray-600"}`}>{v.status}</span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </Card>
        </div>

        {/* Recent Jobs */}
        <Card className="p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold text-gray-800 dark:text-white font-display">Recent Activity</h3>
            <button onClick={() => navigate("/jobs")} className="text-xs text-blue-500 hover:text-blue-600 font-semibold flex items-center gap-1">View all <ChevronRight size={12} /></button>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead><tr className="border-b border-gray-100 dark:border-gray-700">
                {["Job ID", "Title", "Client", "Status", "Date"].map(h => (
                  <th key={h} className="text-left py-2 px-3 text-xs text-gray-500 dark:text-gray-400 font-semibold">{h}</th>
                ))}
              </tr></thead>
              <tbody>
                {(recent_jobs || []).map(job => (
                  <motion.tr key={job.id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} onClick={() => navigate(`/jobs/${job.id}`)}
                    className="border-b border-gray-50 dark:border-gray-700/50 hover:bg-blue-50/30 dark:hover:bg-blue-900/10 transition cursor-pointer">
                    <td className="py-2.5 px-3 font-mono text-blue-600 dark:text-blue-400 text-xs">{job.id}</td>
                    <td className="py-2.5 px-3 font-medium text-gray-800 dark:text-gray-200 max-w-[160px] truncate">{job.title}</td>
                    <td className="py-2.5 px-3 text-gray-500 dark:text-gray-400">{job.client_name || "—"}</td>
                    <td className="py-2.5 px-3"><span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${STATUS_COLORS[job.status] || "bg-gray-100 text-gray-600"}`}>{job.status}</span></td>
                    <td className="py-2.5 px-3 text-gray-500 dark:text-gray-400 text-xs">{formatDate(job.scheduled_date || job.closed_date)}</td>
                  </motion.tr>
                ))}
              </tbody>
            </table>
            {(!recent_jobs || recent_jobs.length === 0) && <p className="text-center text-gray-400 text-sm py-8">No recent activity</p>}
          </div>
        </Card>
      </div>
    </PageTransition>
  );
}
