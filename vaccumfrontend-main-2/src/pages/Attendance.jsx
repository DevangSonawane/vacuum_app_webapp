import { useState } from "react";
import { motion } from "framer-motion";
import { Clock, UserCheck, UserX, AlertCircle, Plus } from "lucide-react";
import { useApp } from "../context/AppContext";
import { PageTransition, Card, Badge, Button, Modal, Select, SectionHeader, StatCard } from "../components/ui";

const today = new Date().toISOString().split("T")[0];

export default function Attendance() {
  const { attendance, technicians, markAttendance, currentUser } = useApp();
  const [selectedDate, setSelectedDate] = useState(today);
  const [modalOpen, setModalOpen] = useState(false);
  const [form, setForm] = useState({ technicianId: "", status: "Present", checkIn: "09:00", checkOut: "17:00", hours: 8 });

  const canEdit = currentUser?.role !== "Technician";
  const dateRecords = attendance.filter(a => a.date === selectedDate);

  const presentIds = new Set(dateRecords.filter(a => a.status !== "Absent").map(a => a.technicianId));
  const absentIds = new Set(dateRecords.filter(a => a.status === "Absent").map(a => a.technicianId));

  const handleMark = e => {
    e.preventDefault();
    markAttendance(Number(form.technicianId), { date: selectedDate, ...form, hours: Number(form.hours) });
    setModalOpen(false);
  };

  // Build today's attendance table
  const techAttendance = technicians.map(tech => {
    const record = dateRecords.find(a => a.technicianId === tech.id);
    return { tech, record, status: record?.status || "—" };
  });

  // Weekly summary for sparkline
  const last7Days = Array.from({ length: 7 }, (_, i) => {
    const d = new Date();
    d.setDate(d.getDate() - (6 - i));
    return d.toISOString().split("T")[0];
  });

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-7xl mx-auto">
        <SectionHeader
          title="Attendance Tracking"
          subtitle="Daily check-in / check-out records"
          action={canEdit && <Button onClick={() => setModalOpen(true)}><Plus size={16} /> Mark Attendance</Button>}
        />

        {/* Stats */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          {[
            { title: "Present Today", value: dateRecords.filter(a => a.status === "Present").length, icon: UserCheck, color: "emerald" },
            { title: "Late", value: dateRecords.filter(a => a.status === "Late").length, icon: AlertCircle, color: "amber" },
            { title: "Absent", value: dateRecords.filter(a => a.status === "Absent").length, icon: UserX, color: "red" },
            { title: "Total Technicians", value: technicians.length, icon: Clock, color: "blue" },
          ].map((s, i) => (
            <motion.div key={s.title} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.07 }}>
              <StatCard {...s} />
            </motion.div>
          ))}
        </div>

        {/* Date picker */}
        <div className="flex items-center gap-3 mb-5">
          <label className="text-sm font-medium text-gray-600 dark:text-gray-300">Date:</label>
          <input type="date" value={selectedDate} onChange={e => setSelectedDate(e.target.value)} max={today}
            className="px-3 py-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-800 dark:text-gray-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500" />
        </div>

        {/* Attendance Table */}
        <Card className="overflow-hidden">
          <div className="p-5 border-b border-gray-100 dark:border-gray-700">
            <h3 className="font-bold text-gray-800 dark:text-white font-display">Attendance for {selectedDate}</h3>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 dark:bg-gray-700/50">
                <tr>
                  {["Technician", "Specialization", "Check In", "Check Out", "Hours", "Status"].map(h => (
                    <th key={h} className="text-left py-3 px-4 text-xs text-gray-500 dark:text-gray-400 font-semibold">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {techAttendance.map(({ tech, record, status }) => (
                  <motion.tr key={tech.id} initial={{ opacity: 0 }} animate={{ opacity: 1 }}
                    className="border-b border-gray-50 dark:border-gray-700/50 hover:bg-gray-50 dark:hover:bg-gray-700/30 transition"
                  >
                    <td className="py-3 px-4">
                      <div className="flex items-center gap-2">
                        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-blue-700 flex items-center justify-center text-white text-xs font-bold">{tech.avatar}</div>
                        <span className="font-medium text-gray-800 dark:text-gray-200">{tech.name}</span>
                      </div>
                    </td>
                    <td className="py-3 px-4 text-gray-500 dark:text-gray-400">{tech.specialization}</td>
                    <td className="py-3 px-4 font-mono text-sm text-gray-700 dark:text-gray-300">{record?.checkIn || "—"}</td>
                    <td className="py-3 px-4 font-mono text-sm text-gray-700 dark:text-gray-300">{record?.checkOut || "—"}</td>
                    <td className="py-3 px-4">
                      {record?.hours ? (
                        <span className="font-semibold text-gray-800 dark:text-gray-200">{record.hours}h</span>
                      ) : "—"}
                    </td>
                    <td className="py-3 px-4">
                      {record ? <Badge label={record.status} /> : <span className="text-gray-300 dark:text-gray-600 text-xs">Not marked</span>}
                    </td>
                  </motion.tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>

        {/* Weekly Overview */}
        <Card className="p-5 mt-4">
          <h3 className="font-bold text-gray-800 dark:text-white font-display mb-4">Weekly Overview</h3>
          <div className="overflow-x-auto">
            <table className="w-full text-xs">
              <thead>
                <tr>
                  <th className="text-left py-2 text-gray-400 font-semibold">Technician</th>
                  {last7Days.map(d => (
                    <th key={d} className={`text-center py-2 text-gray-400 font-semibold px-2 ${d === today ? "text-blue-600" : ""}`}>
                      {new Date(d).toLocaleDateString("en", { weekday: "short" })}<br />
                      <span className="font-mono">{d.slice(8)}</span>
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {technicians.map(tech => (
                  <tr key={tech.id} className="border-t border-gray-50 dark:border-gray-700/50">
                    <td className="py-2 font-medium text-gray-700 dark:text-gray-300">{tech.name}</td>
                    {last7Days.map(d => {
                      const rec = attendance.find(a => a.technicianId === tech.id && a.date === d);
                      const dot = rec ? (rec.status === "Present" ? "bg-emerald-500" : rec.status === "Late" ? "bg-amber-500" : "bg-red-500") : "bg-gray-200 dark:bg-gray-700";
                      return (
                        <td key={d} className="py-2 text-center px-2">
                          <div className={`w-4 h-4 rounded-full mx-auto ${dot}`} title={rec?.status || "No record"} />
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
            <div className="flex items-center gap-4 mt-3">
              {[["bg-emerald-500", "Present"], ["bg-amber-500", "Late"], ["bg-red-500", "Absent"], ["bg-gray-200 dark:bg-gray-700", "No Record"]].map(([c, l]) => (
                <div key={l} className="flex items-center gap-1.5 text-xs text-gray-500"><div className={`w-3 h-3 rounded-full ${c}`} />{l}</div>
              ))}
            </div>
          </div>
        </Card>

        {/* Mark Attendance Modal */}
        <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title="Mark Attendance" size="sm">
          <form onSubmit={handleMark} className="space-y-4">
            <Select label="Technician" value={form.technicianId} onChange={e => setForm(p => ({ ...p, technicianId: e.target.value }))} required
              options={[{ value: "", label: "Select..." }, ...technicians.map(t => ({ value: t.id, label: t.name }))]} />
            <Select label="Status" value={form.status} onChange={e => setForm(p => ({ ...p, status: e.target.value }))}
              options={["Present", "Late", "Absent"]} />
            {form.status !== "Absent" && (
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Check In</label>
                  <input type="time" value={form.checkIn} onChange={e => setForm(p => ({ ...p, checkIn: e.target.value }))}
                    className="w-full px-3 py-2 rounded-xl border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 text-gray-900 dark:text-gray-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Check Out</label>
                  <input type="time" value={form.checkOut} onChange={e => setForm(p => ({ ...p, checkOut: e.target.value }))}
                    className="w-full px-3 py-2 rounded-xl border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 text-gray-900 dark:text-gray-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500" />
                </div>
              </div>
            )}
            <div className="flex gap-3 pt-2">
              <Button type="submit" className="flex-1">Mark Attendance</Button>
              <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
            </div>
          </form>
        </Modal>
      </div>
    </PageTransition>
  );
}
