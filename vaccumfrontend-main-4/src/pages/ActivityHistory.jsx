import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import {
  History, Briefcase, Users, ShieldCheck, FileText,
  UserCog, User, Mail, RefreshCw, ChevronRight, Loader2,
  Search, Bell, CheckCheck, Trash2, Wifi, WifiOff,
  Briefcase as JobIcon, ClipboardList, AlertTriangle
} from "lucide-react";
import axios from "axios";
import { useNotifications } from "../context/NotificationContext";
import {
  PageTransition, Card, SectionHeader, EmptyState, Button, useToast, Toast
} from "../components/ui";

const API_BASE_URL = "https://vaccumapi.onrender.com/api";

// ── Activity log — type meta ──────────────────────────────────
const TYPE_META = {
  job:           { icon: Briefcase,    color: "bg-blue-100    dark:bg-blue-900/30    text-blue-600    dark:text-blue-400"    },
  client:        { icon: Users,        color: "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400" },
  amc:           { icon: ShieldCheck,  color: "bg-purple-100  dark:bg-purple-900/30  text-purple-600  dark:text-purple-400"  },
  report:        { icon: FileText,     color: "bg-gray-100    dark:bg-gray-700       text-gray-600    dark:text-gray-400"    },
  technician:    { icon: UserCog,      color: "bg-red-100     dark:bg-red-900/30     text-red-600     dark:text-red-400"     },
  user:          { icon: User,         color: "bg-indigo-100  dark:bg-indigo-900/30  text-indigo-600  dark:text-indigo-400"  },
  email_settings:{ icon: Mail,         color: "bg-cyan-100    dark:bg-cyan-900/30    text-cyan-600    dark:text-cyan-400"    },
};
const TYPE_FILTERS = ["All", "job", "client", "report", "technician", "amc", "user"];

// ── Notification event — colour dot ──────────────────────────
const EVENT_DOT = {
  job_raised:       "bg-blue-500",
  job_status:       "bg-amber-500",
  report_submitted: "bg-gray-400",
  report_reviewed:  "bg-emerald-500",
  amc_expiring:     "bg-orange-500",
  amc_created:      "bg-blue-500",
  notification:     "bg-blue-400",
};
const EVENT_ICON_COLOR = {
  job_raised:       "bg-blue-100    dark:bg-blue-900/30    text-blue-600",
  job_status:       "bg-amber-100   dark:bg-amber-900/30   text-amber-600",
  report_submitted: "bg-gray-100    dark:bg-gray-700       text-gray-600",
  report_reviewed:  "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600",
  amc_expiring:     "bg-orange-100  dark:bg-orange-900/30  text-orange-600",
  amc_created:      "bg-blue-100    dark:bg-blue-900/30    text-blue-600",
};
const EVENT_ICON = {
  job_raised:       JobIcon,
  job_status:       JobIcon,
  report_submitted: ClipboardList,
  report_reviewed:  ClipboardList,
  amc_expiring:     AlertTriangle,
  amc_created:      ShieldCheck,
};

function relativeTime(iso) {
  try {
    const diff = Date.now() - new Date(iso).getTime();
    const m    = Math.floor(diff / 60000);
    if (m < 1)   return "just now";
    if (m < 60)  return `${m}m ago`;
    const h = Math.floor(m / 60);
    if (h < 24)  return `${h}h ago`;
    const d = Math.floor(h / 24);
    return d === 1 ? "yesterday" : `${d}d ago`;
  } catch { return ""; }
}

function formatTime(ts) {
  if (!ts) return "—";
  try {
    return new Date(ts).toLocaleString("en-IN", {
      dateStyle: "medium", timeStyle: "short",
    });
  } catch { return ts; }
}

// ─────────────────────────────────────────────────────────────
// Main Component
// ─────────────────────────────────────────────────────────────
export default function ActivityHistory() {
  const navigate = useNavigate();
  const { toast, showToast } = useToast();

  // ── Tab state ─────────────────────────────────────────────
  const [activeTab, setActiveTab] = useState("activity"); // "activity" | "notifications"

  // ── Activity state ────────────────────────────────────────
  const [logs, setLogs]               = useState([]);
  const [loading, setLoading]         = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [pagination, setPagination]   = useState(null);
  const [page, setPage]               = useState(1);
  const [typeFilter, setTypeFilter]   = useState("All");
  const [search, setSearch]           = useState("");

  // ── Notifications state ───────────────────────────────────
  const {
    notifications,
    unreadCount,
    connected,
    markAllRead,
    markRead,
    clearAll,
  } = useNotifications();

  // Filter for notification tab
  const [notifFilter, setNotifFilter] = useState("all"); // "all" | "unread"

  // ── Fetch activity logs ───────────────────────────────────
  useEffect(() => {
    setPage(1);
    setLogs([]);
    fetchLogs(1, true);
  }, [typeFilter]);

  const fetchLogs = async (pageNum = 1, reset = false) => {
    if (pageNum === 1) setLoading(true);
    else setLoadingMore(true);

    try {
      const token  = localStorage.getItem("token");
      const params = { page: pageNum, limit: 30 };
      if (typeFilter !== "All") params.type = typeFilter;

      const res = await axios.get(`${API_BASE_URL}/activity`, {
        headers: { Authorization: `Bearer ${token}` }, params,
      });

      if (res.data.success) {
        const newLogs = res.data.data || [];
        setLogs(prev => reset ? newLogs : [...prev, ...newLogs]);
        setPagination(res.data.pagination);
      }
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to fetch activity", "error");
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  };

  const loadMore = () => {
    const next = page + 1;
    setPage(next);
    fetchLogs(next);
  };

  const handleRowClick = (log) => {
    if (!log.entity_id || !log.entity_type) return;
    const paths = { job: `/jobs/${log.entity_id}`, report: `/reports/${log.entity_id}` };
    const path  = paths[log.entity_type];
    if (path) navigate(path);
  };

  // Client-side search on fetched logs
  const filteredLogs = search.length > 1
    ? logs.filter(l =>
        l.action?.toLowerCase().includes(search.toLowerCase()) ||
        (l.entity_id || "").toLowerCase().includes(search.toLowerCase()) ||
        (l.performed_by?.name || "").toLowerCase().includes(search.toLowerCase())
      )
    : logs;

  const hasMore = pagination && pagination.page < pagination.total_pages;

  // Filtered notifications
  const filteredNotifs = notifFilter === "unread"
    ? notifications.filter(n => !n.read)
    : notifications;

  // Navigate from notification to entity detail
  const handleNotifClick = (notif) => {
    markRead(notif.id);
    if (!notif.entity_type || !notif.entity_id) return;
    const paths = {
      job:    `/jobs/${notif.entity_id}`,
      report: `/reports/${notif.entity_id}`,
      amc:    `/amc`,
    };
    const path = paths[notif.entity_type];
    if (path) navigate(path);
  };

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-8xl mx-auto">

        {/* Page header */}
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">History</h1>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-0.5">
              Activity logs and in-app notifications
            </p>
          </div>
          {activeTab === "activity" && (
            <Button variant="secondary" onClick={() => { setPage(1); setLogs([]); fetchLogs(1, true); }}>
              <RefreshCw size={14} className="mr-1.5" /> Refresh
            </Button>
          )}
        </div>

        {/* ── Tab switcher ─────────────────────────────────── */}
        <div className="flex gap-1 mb-6 bg-gray-100 dark:bg-gray-800 p-1 rounded-2xl w-fit">
          {[
            { key: "activity",      label: "Activity Log",   icon: History },
            { key: "notifications", label: "Notifications",  icon: Bell,   badge: unreadCount },
          ].map(tab => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={`flex items-center gap-2 px-5 py-2.5 rounded-xl text-sm font-semibold transition-all relative
                ${activeTab === tab.key
                  ? "bg-white dark:bg-gray-700 text-gray-900 dark:text-white shadow-sm"
                  : "text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200"
                }`}
            >
              <tab.icon size={16} />
              {tab.label}
              {tab.badge > 0 && (
                <motion.span
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  className="absolute -top-1 -right-1 min-w-[18px] h-[18px] bg-red-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center px-1"
                >
                  {tab.badge > 9 ? "9+" : tab.badge}
                </motion.span>
              )}
            </button>
          ))}
        </div>

        <AnimatePresence mode="wait">

          {/* ══════════════════════════════════════════════════
              TAB 1: ACTIVITY LOG
          ══════════════════════════════════════════════════ */}
          {activeTab === "activity" && (
            <motion.div
              key="activity"
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -8 }}
              transition={{ duration: 0.18 }}
            >
              {/* Filters */}
              <div className="flex flex-wrap gap-3 mb-5">
                <div className="relative flex-1 min-w-56 max-w-xs">
                  <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                  <input
                    value={search}
                    onChange={e => setSearch(e.target.value)}
                    placeholder="Search activities…"
                    className="w-full pl-9 pr-3 py-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-800 dark:text-gray-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
                  />
                </div>
                <div className="flex gap-1 flex-wrap">
                  {TYPE_FILTERS.map(t => (
                    <button key={t} onClick={() => setTypeFilter(t)}
                      className={`px-3 py-1.5 rounded-xl text-xs font-semibold capitalize transition
                        ${typeFilter === t
                          ? "bg-blue-600 text-white"
                          : "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"
                        }`}
                    >
                      {t}
                    </button>
                  ))}
                </div>
              </div>

              {/* Activity feed */}
              {loading ? (
                <div className="space-y-2">
                  {[...Array(8)].map((_, i) => (
                    <div key={i} className="flex gap-4 p-4 bg-white dark:bg-gray-800 rounded-xl border border-gray-100 dark:border-gray-700 animate-pulse">
                      <div className="w-10 h-10 rounded-xl bg-gray-200 dark:bg-gray-700 flex-shrink-0" />
                      <div className="flex-1 space-y-2 pt-1">
                        <div className="h-4 w-3/4 bg-gray-200 dark:bg-gray-700 rounded" />
                        <div className="h-3 w-1/3 bg-gray-100 dark:bg-gray-800 rounded" />
                      </div>
                    </div>
                  ))}
                </div>
              ) : filteredLogs.length === 0 ? (
                <EmptyState
                  icon={History}
                  title="No activities found"
                  description="No activity logs match your current filter."
                />
              ) : (
                <Card className="p-5">
                  <div className="relative">
                    <div className="absolute left-6 top-0 bottom-0 w-px bg-gray-100 dark:bg-gray-700" />
                    <div className="space-y-0">
                      {filteredLogs.map((log, i) => {
                        const meta      = TYPE_META[log.type] || TYPE_META.report;
                        const Icon      = meta.icon;
                        const clickable = ["job", "report"].includes(log.entity_type);

                        return (
                          <motion.div
                            key={log.id}
                            initial={{ opacity: 0, x: -10 }}
                            animate={{ opacity: 1, x: 0 }}
                            transition={{ delay: Math.min(i * 0.03, 0.3) }}
                            onClick={() => handleRowClick(log)}
                            className={`flex gap-4 py-3.5 relative ${clickable ? "cursor-pointer group" : ""}`}
                          >
                            <div className={`w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0 relative z-10 ${meta.color} ${clickable ? "group-hover:scale-105 transition-transform" : ""}`}>
                              <Icon size={18} />
                            </div>
                            <div className="flex-1 min-w-0 pt-2">
                              <p className="text-sm font-medium text-gray-800 dark:text-gray-200 leading-snug">
                                {log.action}
                              </p>
                              <div className="flex items-center gap-2 mt-0.5 flex-wrap">
                                {log.performed_by?.name && (
                                  <span className="text-xs text-blue-600 dark:text-blue-400 font-semibold">
                                    {log.performed_by.name}
                                  </span>
                                )}
                                <span className="text-xs text-gray-400">·</span>
                                <span className="text-xs text-gray-400">{formatTime(log.performed_at)}</span>
                              </div>
                            </div>
                            <div className="flex items-start gap-1.5 mt-2 flex-shrink-0">
                              <span className={`text-[10px] px-2 py-0.5 rounded-full capitalize font-semibold border ${
                                log.type === "job"        ? "border-blue-200    text-blue-600    bg-blue-50    dark:border-blue-800    dark:bg-blue-900/20    dark:text-blue-400"    :
                                log.type === "client"     ? "border-emerald-200 text-emerald-600 bg-emerald-50 dark:border-emerald-800 dark:bg-emerald-900/20 dark:text-emerald-400" :
                                log.type === "report"     ? "border-gray-200    text-gray-500    bg-gray-50    dark:border-gray-700    dark:bg-gray-700       dark:text-gray-400"    :
                                log.type === "amc"        ? "border-purple-200  text-purple-600  bg-purple-50  dark:border-purple-800  dark:bg-purple-900/20  dark:text-purple-400"  :
                                log.type === "technician" ? "border-red-200     text-red-600     bg-red-50     dark:border-red-800     dark:bg-red-900/20     dark:text-red-400"     :
                                                            "border-gray-200    text-gray-500    bg-gray-50    dark:border-gray-700    dark:bg-gray-700       dark:text-gray-400"
                              }`}>
                                {log.type}
                              </span>
                              {clickable && (
                                <ChevronRight size={14} className="text-gray-300 group-hover:text-blue-500 transition mt-0.5" />
                              )}
                            </div>
                          </motion.div>
                        );
                      })}
                    </div>
                  </div>
                </Card>
              )}

              {/* Load more */}
              {!loading && hasMore && (
                <div className="mt-4 text-center">
                  <Button variant="secondary" onClick={loadMore} disabled={loadingMore}>
                    {loadingMore
                      ? <><Loader2 size={14} className="animate-spin mr-2" />Loading…</>
                      : "Load More"}
                  </Button>
                </div>
              )}
              {pagination && !loading && (
                <p className="text-center text-xs text-gray-400 mt-3">
                  Showing {logs.length} of {pagination.total} activities
                </p>
              )}
            </motion.div>
          )}

          {/* ══════════════════════════════════════════════════
              TAB 2: NOTIFICATIONS
          ══════════════════════════════════════════════════ */}
          {activeTab === "notifications" && (
            <motion.div
              key="notifications"
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -8 }}
              transition={{ duration: 0.18 }}
            >
              {/* Notifications toolbar */}
              <div className="flex items-center justify-between mb-5 flex-wrap gap-3">
                {/* Filter: all / unread */}
                <div className="flex gap-1">
                  {[
                    { key: "all",    label: "All" },
                    { key: "unread", label: `Unread${unreadCount > 0 ? ` (${unreadCount})` : ""}` },
                  ].map(f => (
                    <button key={f.key} onClick={() => setNotifFilter(f.key)}
                      className={`px-4 py-1.5 rounded-xl text-xs font-semibold transition
                        ${notifFilter === f.key
                          ? "bg-blue-600 text-white"
                          : "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"
                        }`}
                    >
                      {f.label}
                    </button>
                  ))}
                </div>

                {/* WS status + actions */}
                <div className="flex items-center gap-3">
                  {/* Connection indicator */}
                  <div className={`flex items-center gap-1.5 text-xs font-semibold px-3 py-1.5 rounded-xl
                    ${connected
                      ? "bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400"
                      : "bg-gray-100  dark:bg-gray-700       text-gray-500    dark:text-gray-400"
                    }`}
                  >
                    {connected
                      ? <><Wifi size={12} /> Live</>
                      : <><WifiOff size={12} /> Offline</>
                    }
                  </div>

                  {notifications.length > 0 && (
                    <>
                      <Button
                        variant="secondary"
                        onClick={markAllRead}
                        className="text-xs py-1.5 px-3 h-auto"
                      >
                        <CheckCheck size={14} className="mr-1.5" /> Mark all read
                      </Button>
                      <Button
                        variant="danger"
                        onClick={clearAll}
                        className="text-xs py-1.5 px-3 h-auto"
                      >
                        <Trash2 size={14} className="mr-1.5" /> Clear all
                      </Button>
                    </>
                  )}
                </div>
              </div>

              {/* Notifications list */}
              {filteredNotifs.length === 0 ? (
                <EmptyState
                  icon={Bell}
                  title={notifFilter === "unread" ? "No unread notifications" : "No notifications yet"}
                  description={
                    notifFilter === "unread"
                      ? "You're all caught up!"
                      : "Notifications from jobs, reports, and AMC contracts will appear here."
                  }
                />
              ) : (
                <div className="space-y-2">
                  {filteredNotifs.map((notif, i) => {
                    const dotColor    = EVENT_DOT[notif.event]         || "bg-gray-400";
                    const iconColor   = EVENT_ICON_COLOR[notif.event]  || "bg-gray-100 dark:bg-gray-700 text-gray-600";
                    const IconComp    = EVENT_ICON[notif.event]        || Bell;
                    const isClickable = !!notif.entity_type && ["job", "report", "amc"].includes(notif.entity_type);

                    return (
                      <motion.div
                        key={notif.id}
                        initial={{ opacity: 0, y: 8 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: Math.min(i * 0.03, 0.25) }}
                        onClick={() => handleNotifClick(notif)}
                        className={`flex items-start gap-4 p-4 bg-white dark:bg-gray-800 rounded-2xl border transition-all
                          ${notif.read
                            ? "border-gray-100 dark:border-gray-700 opacity-70"
                            : "border-blue-100 dark:border-blue-900/50 bg-blue-50/30 dark:bg-blue-900/10 shadow-sm"
                          }
                          ${isClickable ? "cursor-pointer hover:shadow-md hover:-translate-y-0.5" : ""}`}
                      >
                        {/* Icon with colour */}
                        <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${iconColor}`}>
                          <IconComp size={18} />
                        </div>

                        {/* Content */}
                        <div className="flex-1 min-w-0">
                          <div className="flex items-start justify-between gap-2">
                            <p className={`text-sm font-semibold leading-snug ${notif.read ? "text-gray-600 dark:text-gray-300" : "text-gray-900 dark:text-white"}`}>
                              {notif.title}
                            </p>
                            {/* Unread dot */}
                            {!notif.read && (
                              <span className={`w-2 h-2 rounded-full flex-shrink-0 mt-1.5 ${dotColor}`} />
                            )}
                          </div>
                          <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5 leading-relaxed">
                            {notif.message}
                          </p>
                          <div className="flex items-center gap-3 mt-2">
                            <span className="text-[11px] text-gray-400">{relativeTime(notif.ts)}</span>
                            {notif.entity_id && (
                              <span className="text-[11px] font-mono text-blue-500 dark:text-blue-400">
                                {notif.entity_id}
                              </span>
                            )}
                            {isClickable && (
                              <span className="text-[11px] text-blue-500 flex items-center gap-0.5">
                                View <ChevronRight size={11} />
                              </span>
                            )}
                          </div>
                        </div>
                      </motion.div>
                    );
                  })}
                </div>
              )}

              {/* Summary footer */}
              {notifications.length > 0 && (
                <p className="text-center text-xs text-gray-400 mt-4">
                  {notifications.length} notification{notifications.length !== 1 ? "s" : ""} total
                  {unreadCount > 0 && ` · ${unreadCount} unread`}
                </p>
              )}
            </motion.div>
          )}

        </AnimatePresence>

        {toast && <Toast {...toast} onClose={() => {}} />}
      </div>
    </PageTransition>
  );
}