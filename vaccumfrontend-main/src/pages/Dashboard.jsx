import { useApp } from "../context/AppContext";
import { PageTransition, StatCard, Card } from "../components/ui";
import { Briefcase, Users, UserCog, DollarSign, TrendingUp, Clock } from "lucide-react";
import { MONTHLY_JOBS } from "../data/mockData";
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer,
  LineChart, Line, PieChart, Pie, Cell, Legend, CartesianGrid
} from "recharts";
import { motion } from "framer-motion";

const PIE_DATA = [
  { name: "Raised", value: 4, color: "#a855f7" },
  { name: "Assigned", value: 6, color: "#3b82f6" },
  { name: "In Progress", value: 8, color: "#f59e0b" },
  { name: "Closed", value: 22, color: "#10b981" },
];

const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload?.length)
    return (
      <div className="bg-white dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-xl p-3 shadow-lg text-sm">
        <p className="font-semibold text-gray-700 dark:text-gray-200 mb-1">{label}</p>
        {payload.map(p => (
          <p key={p.name} style={{ color: p.color }}>{p.name}: {typeof p.value === "number" && p.name.includes("revenue") ? `₹${p.value.toLocaleString()}` : p.value}</p>
        ))}
      </div>
    );
  return null;
};

export default function Dashboard() {
  const { jobs, clients, technicians, quotations } = useApp();
  const activeJobs = jobs.filter(j => j.status !== "Closed").length;
  const totalRevenue = quotations.filter(q => q.status === "Approved").reduce((s, q) => s + q.amount, 0);

  return (
    <PageTransition>
      <div className="p-4 md:p-6 space-y-6 max-w-7xl mx-auto">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white font-display">Dashboard</h1>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-0.5">Welcome back — here's what's happening today.</p>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[
            { title: "Active Jobs", value: activeJobs, icon: Briefcase, color: "blue", change: 12 },
            { title: "Total Clients", value: clients.length, icon: Users, color: "emerald", change: 5 },
            { title: "Technicians", value: technicians.filter(t => t.status === "Active").length, icon: UserCog, color: "purple", subtitle: `${technicians.length} total` },
            { title: "Revenue (Approved)", value: `₹${(totalRevenue / 100000).toFixed(1)}L`, icon: DollarSign, color: "amber", change: 18 },
          ].map((s, i) => (
            <motion.div key={s.title} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.08 }}>
              <StatCard {...s} />
            </motion.div>
          ))}
        </div>

        {/* Charts row 1 */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          {/* Bar chart */}
          <Card className="col-span-1 lg:col-span-2 p-5">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="font-bold text-gray-800 dark:text-white font-display">Jobs & Revenue</h3>
                <p className="text-xs text-gray-400">Last 6 months</p>
              </div>
              <TrendingUp size={18} className="text-blue-500" />
            </div>
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={MONTHLY_JOBS} barGap={4}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="month" tick={{ fontSize: 12 }} />
                <YAxis yAxisId="left" tick={{ fontSize: 11 }} />
                <YAxis yAxisId="right" orientation="right" tick={{ fontSize: 11 }} tickFormatter={v => `₹${(v/1000).toFixed(0)}k`} />
                <Tooltip content={<CustomTooltip />} />
                <Bar yAxisId="left" dataKey="jobs" name="jobs" fill="#bfdbfe" radius={[4, 4, 0, 0]} />
                <Bar yAxisId="left" dataKey="completed" name="completed" fill="#2563eb" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </Card>

          {/* Pie chart */}
          <Card className="p-5">
            <h3 className="font-bold text-gray-800 dark:text-white font-display mb-4">Job Status</h3>
            <ResponsiveContainer width="100%" height={180}>
              <PieChart>
                <Pie data={PIE_DATA} cx="50%" cy="50%" innerRadius={50} outerRadius={75} paddingAngle={3} dataKey="value">
                  {PIE_DATA.map((entry, i) => <Cell key={i} fill={entry.color} />)}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
            <div className="space-y-2 mt-2">
              {PIE_DATA.map(d => (
                <div key={d.name} className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2">
                    <div className="w-2.5 h-2.5 rounded-full" style={{ background: d.color }} />
                    <span className="text-gray-600 dark:text-gray-300">{d.name}</span>
                  </div>
                  <span className="font-semibold text-gray-800 dark:text-white">{d.value}</span>
                </div>
              ))}
            </div>
          </Card>
        </div>

        {/* Line chart + Recent Activity */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <Card className="col-span-1 lg:col-span-2 p-5">
            <h3 className="font-bold text-gray-800 dark:text-white font-display mb-4">Revenue Trend</h3>
            <ResponsiveContainer width="100%" height={180}>
              <LineChart data={MONTHLY_JOBS}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="month" tick={{ fontSize: 12 }} />
                <YAxis tick={{ fontSize: 11 }} tickFormatter={v => `₹${v / 1000}k`} />
                <Tooltip formatter={v => `₹${v.toLocaleString()}`} />
                <Line type="monotone" dataKey="revenue" stroke="#2563eb" strokeWidth={3} dot={{ fill: "#2563eb", r: 4 }} activeDot={{ r: 6 }} />
              </LineChart>
            </ResponsiveContainer>
          </Card>

          {/* Quick stats */}
          <Card className="p-5">
            <h3 className="font-bold text-gray-800 dark:text-white font-display mb-4">Quick Overview</h3>
            <div className="space-y-3">
              {[
                { label: "Jobs This Month", value: 24, max: 30, color: "bg-blue-500" },
                { label: "Jobs Completed", value: 19, max: 24, color: "bg-emerald-500" },
                { label: "Active Technicians", value: technicians.filter(t => t.status === "Active").length, max: technicians.length, color: "bg-purple-500" },
                { label: "AMC Active", value: 2, max: 3, color: "bg-amber-500" },
              ].map(s => (
                <div key={s.label}>
                  <div className="flex justify-between text-xs mb-1">
                    <span className="text-gray-600 dark:text-gray-300 font-medium">{s.label}</span>
                    <span className="font-bold text-gray-800 dark:text-white">{s.value}/{s.max}</span>
                  </div>
                  <div className="h-2 bg-gray-100 dark:bg-gray-700 rounded-full overflow-hidden">
                    <motion.div
                      initial={{ width: 0 }}
                      animate={{ width: `${(s.value / s.max) * 100}%` }}
                      transition={{ duration: 0.8, delay: 0.3 }}
                      className={`h-full ${s.color} rounded-full`}
                    />
                  </div>
                </div>
              ))}
            </div>
          </Card>
        </div>

        {/* Recent jobs */}
        <Card className="p-5">
          <h3 className="font-bold text-gray-800 dark:text-white font-display mb-4">Recent Work Orders</h3>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 dark:border-gray-700">
                  {["Job ID", "Title", "Client", "Status", "Priority", "Amount"].map(h => (
                    <th key={h} className="text-left py-2 px-3 text-xs text-gray-500 dark:text-gray-400 font-semibold">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {useApp().jobs.slice(0, 5).map(job => {
                  const client = useApp().clients.find(c => c.id === job.clientId);
                  return (
                    <motion.tr key={job.id} initial={{ opacity: 0 }} animate={{ opacity: 1 }}
                      className="border-b border-gray-50 dark:border-gray-700/50 hover:bg-blue-50/30 dark:hover:bg-blue-900/10 transition"
                    >
                      <td className="py-2.5 px-3 font-mono text-blue-600 dark:text-blue-400 text-xs">{job.id}</td>
                      <td className="py-2.5 px-3 font-medium text-gray-800 dark:text-gray-200">{job.title}</td>
                      <td className="py-2.5 px-3 text-gray-500 dark:text-gray-400">{client?.name}</td>
                      <td className="py-2.5 px-3">
                        <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${
                          job.status === "Closed" ? "bg-emerald-100 text-emerald-700" :
                          job.status === "In Progress" ? "bg-amber-100 text-amber-700" :
                          job.status === "Assigned" ? "bg-blue-100 text-blue-700" :
                          "bg-purple-100 text-purple-700"
                        }`}>{job.status}</span>
                      </td>
                      <td className="py-2.5 px-3">
                        <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${
                          job.priority === "Critical" ? "bg-red-100 text-red-700" :
                          job.priority === "High" ? "bg-orange-100 text-orange-700" :
                          job.priority === "Medium" ? "bg-blue-100 text-blue-700" :
                          "bg-gray-100 text-gray-600"
                        }`}>{job.priority}</span>
                      </td>
                      <td className="py-2.5 px-3 font-semibold text-gray-800 dark:text-gray-200">₹{job.amount.toLocaleString()}</td>
                    </motion.tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </Card>
      </div>
    </PageTransition>
  );
}
