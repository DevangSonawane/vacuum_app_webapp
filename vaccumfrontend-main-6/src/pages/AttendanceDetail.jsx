import { useState, useEffect, useCallback } from "react";
import { useParams, useLocation, useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import axios from "axios";
import {
  ArrowLeft, Calendar, LogIn, LogOut, Clock,
  FileText, RotateCcw, ClipboardList, ChevronLeft,
  ChevronRight, Loader2, AlertCircle, Mail, Phone,
  Building2, User, RefreshCw,
} from "lucide-react";
import { PageTransition, Badge, Button, Card } from "../components/ui";

const API = "https://vaccumapi-o4ol.onrender.com/api";
const today = new Date().toISOString().split("T")[0];

function formatDate(str) {
  if (!str) return "—";
  try {
    if (str.includes("T")) return new Date(str).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" });
    if (str.includes("/")) {
      const [d, m, y] = str.split("/");
      return new Date(`${y}-${m}-${d}`).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" });
    }
    return new Date(str).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" });
  } catch { return str; }
}

function getInitials(name) {
  if (!name) return "?";
  return name.split(" ").map(n => n[0]).slice(0, 2).join("").toUpperCase();
}

function shiftDate(dateStr, days) {
  const d = new Date(dateStr);
  d.setDate(d.getDate() + days);
  return d.toISOString().split("T")[0];
}

const STATUS_STYLE = {
  present:  { bg: "from-emerald-500 to-emerald-600", light: "bg-emerald-50 dark:bg-emerald-900/20", border: "border-emerald-200 dark:border-emerald-700", text: "text-emerald-700 dark:text-emerald-400", dot: "bg-emerald-500", ring: "ring-emerald-400/30" },
  absent:   { bg: "from-red-500 to-red-600",         light: "bg-red-50 dark:bg-red-900/20",         border: "border-red-200 dark:border-red-700",         text: "text-red-700 dark:text-red-400",         dot: "bg-red-500",     ring: "ring-red-400/30" },
  late:     { bg: "from-amber-500 to-amber-600",     light: "bg-amber-50 dark:bg-amber-900/20",     border: "border-amber-200 dark:border-amber-700",     text: "text-amber-700 dark:text-amber-400",     dot: "bg-amber-500",   ring: "ring-amber-400/30" },
  "half day":{ bg: "from-amber-500 to-orange-500",  light: "bg-amber-50 dark:bg-amber-900/20",     border: "border-amber-200 dark:border-amber-700",     text: "text-amber-700 dark:text-amber-400",     dot: "bg-amber-500",   ring: "ring-amber-400/30" },
  leave:    { bg: "from-blue-500 to-blue-600",       light: "bg-blue-50 dark:bg-blue-900/20",       border: "border-blue-200 dark:border-blue-700",       text: "text-blue-700 dark:text-blue-400",       dot: "bg-blue-500",    ring: "ring-blue-400/30" },
  default:  { bg: "from-gray-400 to-gray-500",       light: "bg-gray-50 dark:bg-gray-700/40",       border: "border-gray-200 dark:border-gray-600",       text: "text-gray-500 dark:text-gray-400",       dot: "bg-gray-400",    ring: "ring-gray-400/20" },
};

function getStatusStyle(description) {
  const d = (description || "").toLowerCase();
  if (d === "present") return STATUS_STYLE.present;
  if (d === "absent")  return STATUS_STYLE.absent;
  if (d.includes("half")) return STATUS_STYLE["half day"];
  if (d.includes("late")) return STATUS_STYLE.late;
  if (d.includes("leave")) return STATUS_STYLE.leave;
  return STATUS_STYLE.default;
}

function InfoCard({ icon: Icon, label, value, iconBg = "bg-blue-100 dark:bg-blue-900/30", iconColor = "text-blue-600 dark:text-blue-400" }) {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 p-4 flex items-center gap-3 shadow-sm">
      <div className={`p-2.5 rounded-xl ${iconBg} flex-shrink-0`}>
        <Icon size={16} className={iconColor} />
      </div>
      <div className="min-w-0">
        <p className="text-xs font-medium text-gray-400 dark:text-gray-500">{label}</p>
        <p className="text-sm font-bold text-gray-800 dark:text-gray-200 font-mono truncate">{value || "—"}</p>
      </div>
    </div>
  );
}

export default function AttendanceDetail() {
  const { employee_id } = useParams();
  const location = useLocation();
  const navigate = useNavigate();

  const [employee, setEmployee] = useState(location.state?.employee || null);
  const [empLoading, setEmpLoading] = useState(!location.state?.employee);

  const [date, setDate] = useState(today);
  const [attendance, setAttendance] = useState(null);
  const [attLoading, setAttLoading] = useState(false);
  const [attError, setAttError] = useState(null);

  // Fetch employee from API if not passed via router state
  useEffect(() => {
    if (employee) return;
    setEmpLoading(true);
    axios.get(`${API}/attendance/people/${employee_id}`)
      .then(({ data }) => setEmployee(data.employee))
      .catch(() => {})
      .finally(() => setEmpLoading(false));
  }, [employee_id, employee]);

  // Fetch attendance whenever date or employee changes
  const fetchAttendance = useCallback(async (email, d) => {
    if (!email || !d) return;
    setAttLoading(true);
    setAttError(null);
    setAttendance(null);
    try {
      const { data } = await axios.get(`${API}/attendance/fetch`, {
        params: { email, date: d, employee_type: "employee" },
      });
      setAttendance(data.attendance?.data || null);
    } catch (err) {
      setAttError(err.response?.data?.error?.message || "Failed to fetch attendance");
    } finally {
      setAttLoading(false);
    }
  }, []);

  useEffect(() => {
    if (employee?.email) fetchAttendance(employee.email, date);
  }, [employee, date, fetchAttendance]);

  const canGoNext = date < today;

  const s = getStatusStyle(attendance?.status?.description);
  const hasRequest = attendance?.["requested-status"]?.description || attendance?.["requested-check-in"] || attendance?.["requested-check-out"];

  if (empLoading) {
    return (
      <PageTransition>
        <div className="flex items-center justify-center h-64 gap-3 text-gray-400">
          <Loader2 size={20} className="animate-spin" />
          <span className="text-sm">Loading employee…</span>
        </div>
      </PageTransition>
    );
  }

  return (
    <div className="p-4 md:p-6 max-w-7xl mx-auto">
      {/* Back button */}
      <button
        onClick={() => navigate("/attendance")}
        className="flex items-center gap-2 text-sm font-medium text-gray-500 hover:text-gray-900 dark:text-gray-400 dark:hover:text-white transition mb-5"
      >
        <ArrowLeft size={16} />
        Back to Employees
      </button>

      {/* Employee header card */}
      {employee && (
        <Card className="p-5 mb-6">
          <div className="flex flex-col sm:flex-row sm:items-center gap-4">
            <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center text-white text-xl font-bold flex-shrink-0">
              {getInitials(employee.name)}
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex flex-wrap items-center gap-2 mb-1">
                <h1 className="text-xl font-bold text-gray-900 dark:text-white font-display">{employee.name}</h1>
                <Badge label={employee.is_active ? "Active" : "Inactive"} />
              </div>
              <p className="text-sm text-gray-500 dark:text-gray-400 font-medium">
                {[employee.title, employee.department].filter(Boolean).join(" · ")}
              </p>
              <div className="flex flex-wrap items-center gap-4 mt-2">
                {employee.email && (
                  <span className="flex items-center gap-1.5 text-xs text-gray-400">
                    <Mail size={12} /> {employee.email}
                  </span>
                )}
                {employee.phone_number && (
                  <span className="flex items-center gap-1.5 text-xs text-gray-400">
                    <Phone size={12} /> {employee.phone_number}
                  </span>
                )}
                <span className="flex items-center gap-1.5 text-xs text-gray-400">
                  <User size={12} /> ID: {employee.employee_id}
                </span>
              </div>
            </div>
            <div className="text-right flex-shrink-0">
              <p className="text-xs text-gray-400">Hired</p>
              <p className="text-sm font-semibold text-gray-700 dark:text-gray-300">{formatDate(employee.date_of_hiring)}</p>
              {employee.annual_ctc && (
                <>
                  <p className="text-xs text-gray-400 mt-1">Annual CTC</p>
                  <p className="text-sm font-semibold text-gray-700 dark:text-gray-300">₹{Number(employee.annual_ctc).toLocaleString("en-IN")}</p>
                </>
              )}
            </div>
          </div>
        </Card>
      )}

      {/* Date navigation */}
      <div className="flex items-center gap-3 mb-5">
        <div className="flex items-center gap-1 bg-white dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-2xl p-1 shadow-sm">
          <button
            onClick={() => setDate(d => shiftDate(d, -1))}
            className="p-2 rounded-xl hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-500 transition"
          >
            <ChevronLeft size={16} />
          </button>
          <div className="flex items-center gap-2 px-2">
            <Calendar size={15} className="text-blue-500" />
            <input
              type="date"
              value={date}
              max={today}
              onChange={e => e.target.value && setDate(e.target.value)}
              className="text-sm font-bold text-gray-800 dark:text-gray-200 bg-transparent focus:outline-none cursor-pointer"
            />
          </div>
          <button
            onClick={() => canGoNext && setDate(d => shiftDate(d, 1))}
            disabled={!canGoNext}
            className="p-2 rounded-xl hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-500 disabled:opacity-30 disabled:cursor-not-allowed transition"
          >
            <ChevronRight size={16} />
          </button>
        </div>

        <button
          onClick={() => setDate(today)}
          className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition ${date === today ? "bg-blue-600 text-white" : "bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-600 text-gray-600 dark:text-gray-300 hover:border-blue-400"}`}
        >
          Today
        </button>

        <button
          onClick={() => employee?.email && fetchAttendance(employee.email, date)}
          className="p-2 rounded-xl bg-white dark:bg-gray-800 border border-gray-100 dark:border-gray-700 text-gray-400 hover:text-blue-600 hover:border-blue-300 transition shadow-sm"
          title="Refresh"
        >
          <RefreshCw size={15} />
        </button>

        <span className="text-sm font-medium text-gray-500 dark:text-gray-400 ml-1">
          {new Date(date).toLocaleDateString("en-IN", { weekday: "long", day: "numeric", month: "long", year: "numeric" })}
        </span>
      </div>

      {/* Content area */}
      <AnimatePresence mode="wait">
        {attLoading && (
          <motion.div key="loading" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            className="flex flex-col items-center justify-center py-24 gap-3 text-gray-400">
            <Loader2 size={24} className="animate-spin text-blue-500" />
            <p className="text-sm">Fetching attendance for {formatDate(date)}…</p>
          </motion.div>
        )}

        {!attLoading && attError && (
          <motion.div key="error" initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }}>
            <div className="flex items-center gap-3 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-700 rounded-2xl text-red-700 dark:text-red-400">
              <AlertCircle size={18} className="flex-shrink-0" />
              <div>
                <p className="font-semibold text-sm">Could not load attendance</p>
                <p className="text-xs mt-0.5 opacity-80">{attError}</p>
              </div>
            </div>
          </motion.div>
        )}

        {!attLoading && !attError && attendance && (
          <motion.div key={date} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} className="space-y-4">

            {/* Status hero */}
            <div className={`rounded-3xl overflow-hidden border ${s.border} shadow-sm`}>
              <div className={`bg-gradient-to-r ${s.bg} p-5 flex items-center gap-4`}>
                <div className="w-14 h-14 rounded-2xl bg-white/20 ring-4 ring-white/30 flex items-center justify-center flex-shrink-0">
                  <div className="w-6 h-6 rounded-full bg-white/90" />
                </div>
                <div className="flex-1">
                  <p className="text-white/70 text-xs font-semibold uppercase tracking-widest">Attendance Status</p>
                  <p className="text-white text-3xl font-bold capitalize mt-0.5 font-display">
                    {attendance.status?.description || "Unknown"}
                  </p>
                  {attendance.status?.code != null && (
                    <p className="text-white/60 text-xs mt-1">Status code: {attendance.status.code}</p>
                  )}
                </div>
                <div className="text-right hidden sm:block">
                  <p className="text-white/60 text-xs">Employee ID</p>
                  <p className="text-white font-bold text-lg">#{attendance["employee-id"]}</p>
                  <p className="text-white/60 text-xs mt-1">Type</p>
                  <p className="text-white font-semibold text-sm capitalize">{attendance["employee-type"]}</p>
                </div>
              </div>
              <div className={`${s.light} px-5 py-3 flex items-center gap-2`}>
                <ClipboardList size={13} className={s.text} />
                <span className={`text-xs font-semibold ${s.text}`}>
                  {formatDate(attendance.date)}
                </span>
              </div>
            </div>

            {/* Check-in / Check-out */}
            <div className="grid grid-cols-2 gap-4">
              <InfoCard
                icon={LogIn}
                label="Check In"
                value={attendance["check-in"]}
                iconBg="bg-emerald-100 dark:bg-emerald-900/30"
                iconColor="text-emerald-600 dark:text-emerald-400"
              />
              <InfoCard
                icon={LogOut}
                label="Check Out"
                value={attendance["check-out"]}
                iconBg="bg-red-100 dark:bg-red-900/30"
                iconColor="text-red-500 dark:text-red-400"
              />
            </div>

            {/* Leave type + Remarks */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 p-4 shadow-sm">
                <div className="flex items-center gap-2 mb-2">
                  <div className="p-2 rounded-xl bg-blue-100 dark:bg-blue-900/30">
                    <Clock size={14} className="text-blue-600 dark:text-blue-400" />
                  </div>
                  <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide">Leave Type</p>
                </div>
                <p className="text-lg font-bold text-gray-800 dark:text-gray-200 capitalize">
                  {attendance["leave-type"]?.description || "—"}
                </p>
                {attendance["leave-type"]?.code != null && (
                  <p className="text-xs text-gray-400 mt-1">Code: {attendance["leave-type"].code}</p>
                )}
              </div>

              <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 p-4 shadow-sm">
                <div className="flex items-center gap-2 mb-2">
                  <div className="p-2 rounded-xl bg-purple-100 dark:bg-purple-900/30">
                    <FileText size={14} className="text-purple-600 dark:text-purple-400" />
                  </div>
                  <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide">Remarks</p>
                </div>
                <p className="text-sm font-semibold text-gray-800 dark:text-gray-200">
                  {attendance.remarks || "No remarks"}
                </p>
              </div>
            </div>

            {/* Requested changes */}
            {hasRequest && (
              <motion.div initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }}
                className="bg-amber-50 dark:bg-amber-900/10 border border-amber-200 dark:border-amber-700/50 rounded-2xl p-5">
                <div className="flex items-center gap-2 mb-4">
                  <div className="p-2 bg-amber-100 dark:bg-amber-800/40 rounded-xl">
                    <RotateCcw size={14} className="text-amber-600 dark:text-amber-400" />
                  </div>
                  <p className="text-sm font-bold text-amber-800 dark:text-amber-300">Requested Changes</p>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-xs text-gray-400 mb-1">Requested Status</p>
                    <p className="text-sm font-bold text-gray-800 dark:text-gray-200 capitalize">
                      {attendance["requested-status"]?.description || "—"}
                    </p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-400 mb-1">Requested Leave Type</p>
                    <p className="text-sm font-bold text-gray-800 dark:text-gray-200 capitalize">
                      {attendance["requested-leave-type"]?.description || "—"}
                    </p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-400 mb-1">Requested Check In</p>
                    <p className="text-sm font-bold text-gray-800 dark:text-gray-200 font-mono">
                      {attendance["requested-check-in"] || "—"}
                    </p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-400 mb-1">Requested Check Out</p>
                    <p className="text-sm font-bold text-gray-800 dark:text-gray-200 font-mono">
                      {attendance["requested-check-out"] || "—"}
                    </p>
                  </div>
                </div>
              </motion.div>
            )}
          </motion.div>
        )}

        {!attLoading && !attError && !attendance && (
          <motion.div key="empty" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            className="flex flex-col items-center justify-center py-20 text-center">
            <div className="p-5 bg-gray-100 dark:bg-gray-700/50 rounded-2xl mb-4">
              <Calendar size={28} className="text-gray-400" />
            </div>
            <p className="font-semibold text-gray-600 dark:text-gray-300">No attendance record</p>
            <p className="text-sm text-gray-400 mt-1">No data found for {formatDate(date)}</p>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
