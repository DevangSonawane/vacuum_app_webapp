import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  LayoutDashboard, Users, UserCog, Briefcase, ClipboardList,
  FileText, DollarSign, Mail, ShieldCheck, Clock, LogOut,
  ChevronRight, Menu, X, Search, Bell, HardHat,
  User, Settings, Moon, Sun, CheckCheck, Trash2, Wifi, WifiOff,
  CalendarCheck
} from "lucide-react";
import { useDispatch, useSelector } from "react-redux";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { logout } from "../store/authSlice";
import { useApp } from "../context/AppContext";
import { useNotifications } from "../context/NotificationContext";
import { Avatar } from "./ui";

const NAV_ITEMS = [
  { id: "dashboard",   label: "Dashboard",        icon: LayoutDashboard, path: "/"            },
  { id: "technicians", label: "Technicians",       icon: UserCog,         path: "/technicians" },
  { id: "clients",     label: "Clients",           icon: Users,           path: "/clients"     },
  { id: "amc",         label: "AMC Contracts",     icon: ShieldCheck,     path: "/amc"         },
  { id: "jobs",        label: "Visit Scheduled",   icon: CalendarCheck,   path: "/jobs"        },
  { id: "reports",     label: "Service & Reports", icon: ClipboardList,   path: "/reports"     },
  { id: "attendance",  label: "Attendance",        icon: Clock,           path: "/attendance"  },
  { id: "email",       label: "Email Settings",    icon: Mail,            path: "/email",      adminOnly: true },
  { id: "activity",    label: "Activity History",  icon: FileText,        path: "/activity",   adminOnly: true },
  { id: "users",       label: "Users",             icon: Users,           path: "/users",      adminOnly: true },
];

// ── Colour per notification event ────────────────────────────
const NOTIF_DOT = {
  blue:    "bg-blue-500",
  amber:   "bg-amber-500",
  emerald: "bg-emerald-500",
  orange:  "bg-orange-500",
  gray:    "bg-gray-400",
};

// ── Relative time formatter ───────────────────────────────────
function relativeTime(iso) {
  try {
    const diff = Date.now() - new Date(iso).getTime();
    const m    = Math.floor(diff / 60000);
    if (m < 1)   return "just now";
    if (m < 60)  return `${m}m ago`;
    const h = Math.floor(m / 60);
    if (h < 24)  return `${h}h ago`;
    return `${Math.floor(h / 24)}d ago`;
  } catch {
    return "";
  }
}

// ─────────────────────────────────────────────────────────────
// Sidebar
// ─────────────────────────────────────────────────────────────
export default function Sidebar({ sidebarOpen, setSidebarOpen }) {
  const { user: currentUser } = useSelector((state) => state.auth);
  const location              = useLocation();
  const dispatch              = useDispatch();
  const [isLargeScreen, setIsLargeScreen] = useState(window.innerWidth >= 1024);

  useEffect(() => {
    const h = () => setIsLargeScreen(window.innerWidth >= 1024);
    window.addEventListener("resize", h);
    return () => window.removeEventListener("resize", h);
  }, []);

  const isAdmin     = currentUser?.role?.toLowerCase() === "admin";
  const filteredNav = NAV_ITEMS.filter(n => !n.adminOnly || isAdmin);

  return (
    <>
      <AnimatePresence>
        {sidebarOpen && (
          <motion.div
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/50 z-40 lg:hidden"
            onClick={() => setSidebarOpen(false)}
          />
        )}
      </AnimatePresence>

      <motion.aside
        initial={false}
        animate={{ x: isLargeScreen ? 0 : (sidebarOpen ? 0 : -280) }}
        transition={{ type: "spring", damping: 30, stiffness: 300 }}
        className="fixed left-0 top-0 h-full w-64 bg-[#0f172a] z-50 flex flex-col lg:static lg:translate-x-0 lg:z-auto"
      >
        {/* Logo */}
        <div className="p-5 border-b border-white/10 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 bg-blue-600 rounded-xl flex items-center justify-center flex-shrink-0">
              <HardHat size={18} className="text-white" />
            </div>
            <div>
              <p className="text-white font-bold text-sm leading-tight uppercase tracking-wider">VDTI</p>
              <p className="text-blue-400 text-[10px] uppercase tracking-widest font-semibold">Service Hub</p>
            </div>
          </div>
          <button onClick={() => setSidebarOpen(false)} className="lg:hidden text-blue-300 hover:text-white">
            <X size={18} />
          </button>
        </div>

        {/* Nav */}
        <nav className="flex-1 p-3 overflow-y-auto space-y-1">
          {filteredNav.map((item) => {
            const Icon   = item.icon;
            const active = location.pathname === item.path ||
              (item.path !== "/" && location.pathname.startsWith(item.path));
            return (
              <Link
                key={item.id}
                to={item.path}
                onClick={() => setSidebarOpen(false)}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-150 group relative
                  ${active
                    ? "bg-blue-600 text-white shadow-lg shadow-blue-600/30"
                    : "text-blue-200 hover:bg-white/5 hover:text-white"}`}
              >
                <Icon size={20} className={active ? "text-white" : "text-blue-400 group-hover:text-white"} />
                <span className="flex-1 text-left whitespace-nowrap">{item.label}</span>
                {active && <ChevronRight size={14} className="text-blue-300" />}
              </Link>
            );
          })}
        </nav>

        {/* Logout */}
        <div className="p-4 border-t border-white/10">
          <button
            onClick={() => dispatch(logout())}
            className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium text-red-400 hover:bg-red-500/10 hover:text-red-300 transition-all"
          >
            <LogOut size={20} />
            <span className="flex-1 text-left">Sign Out</span>
          </button>
        </div>
      </motion.aside>
    </>
  );
}

// ─────────────────────────────────────────────────────────────
// TopBar — with live notification bell
// ─────────────────────────────────────────────────────────────
export function TopBar({ setSidebarOpen }) {
  const dispatch   = useDispatch();
  const location   = useLocation();
  const navigate   = useNavigate();
  const { user: currentUser }            = useSelector((state) => state.auth);
  const { darkMode, setDarkMode, searchQuery, setSearchQuery } = useApp();
  const { notifications, unreadCount, connected, markAllRead, markRead, clearAll } = useNotifications();

  const [showUserMenu, setShowUserMenu]   = useState(false);
  const [showNotifMenu, setShowNotifMenu] = useState(false);
  const userMenuRef  = useRef(null);
  const notifMenuRef = useRef(null);

  // Close dropdowns on outside click
  useEffect(() => {
    const h = (e) => {
      if (userMenuRef.current  && !userMenuRef.current.contains(e.target))  setShowUserMenu(false);
      if (notifMenuRef.current && !notifMenuRef.current.contains(e.target)) setShowNotifMenu(false);
    };
    document.addEventListener("mousedown", h);
    return () => document.removeEventListener("mousedown", h);
  }, []);

  // Current page label — matches updated NAV_ITEMS
  const currentNavItem = NAV_ITEMS.find(n =>
    n.path === location.pathname ||
    (n.path !== "/" && location.pathname.startsWith(n.path))
  );
  let label = currentNavItem?.label || "Dashboard";
  if (location.pathname === "/profile")             label = "Profile";
  if (location.pathname === "/settings")            label = "Settings";
  if (location.pathname === "/users")               label = "User Management";
  if (location.pathname.startsWith("/jobs/"))       label = "Visit Detail";
  if (location.pathname.startsWith("/reports/"))    label = "Report Detail";

  const getInitials = (user) => {
    if (!user) return "?";
    const f = user.first_name?.[0] || "";
    const l = user.last_name?.[0]  || "";
    return (f + l).toUpperCase() || "?";
  };

  return (
    <header className="sticky top-0 z-30 bg-white/80 dark:bg-gray-950/80 backdrop-blur-md border-b border-gray-100 dark:border-gray-800 px-4 py-3 flex items-center gap-3">
      {/* Mobile hamburger */}
      <button onClick={() => setSidebarOpen(true)} className="lg:hidden text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-white flex-shrink-0">
        <Menu size={22} />
      </button>

      {/* Page title */}
      <h2 className="font-bold text-gray-900 dark:text-white text-lg hidden sm:block mr-2">{label}</h2>

      {/* Search */}
      <div className="flex-1 relative max-w-sm">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
        <input
          type="text"
          value={searchQuery}
          onChange={e => setSearchQuery(e.target.value)}
          placeholder="Search…"
          className="w-full pl-10 pr-4 py-2 rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-900/50 text-gray-900 dark:text-gray-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
        />
      </div>

      <div className="flex items-center gap-1 ml-auto">

        {/* ── Notification Bell ─────────────────────────── */}
        <div className="relative" ref={notifMenuRef}>
          <button
            onClick={() => setShowNotifMenu(p => !p)}
            className="relative p-2 text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-xl transition-all"
            title={connected ? "Connected — live notifications" : "Disconnected"}
          >
            <Bell size={20} />

            {/* Unread badge */}
            {unreadCount > 0 && (
              <motion.span
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                className="absolute top-1.5 right-1.5 min-w-[16px] h-4 bg-red-500 rounded-full text-[10px] font-bold text-white flex items-center justify-center px-0.5 border-2 border-white dark:border-gray-950"
              >
                {unreadCount > 9 ? "9+" : unreadCount}
              </motion.span>
            )}

            {/* WS connected indicator */}
            <span className={`absolute bottom-1.5 right-1.5 w-2 h-2 rounded-full border-2 border-white dark:border-gray-950 ${connected ? "bg-emerald-400" : "bg-gray-400"}`} />
          </button>

          {/* Notification dropdown */}
          <AnimatePresence>
            {showNotifMenu && (
              <motion.div
                initial={{ opacity: 0, y: 10, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: 10, scale: 0.95 }}
                transition={{ duration: 0.15 }}
                className="absolute right-0 mt-2 w-80 bg-white dark:bg-gray-900 rounded-2xl shadow-2xl border border-gray-100 dark:border-gray-800 overflow-hidden"
              >
                {/* Dropdown header */}
                <div className="flex items-center justify-between px-4 py-3 border-b border-gray-100 dark:border-gray-800">
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-bold text-gray-900 dark:text-white">Notifications</p>
                    {connected
                      ? <span className="flex items-center gap-1 text-[10px] text-emerald-500 font-semibold"><Wifi size={10} /> Live</span>
                      : <span className="flex items-center gap-1 text-[10px] text-gray-400 font-semibold"><WifiOff size={10} /> Offline</span>
                    }
                  </div>
                  <div className="flex items-center gap-1">
                    {notifications.length > 0 && (
                      <>
                        <button
                          onClick={markAllRead}
                          className="p-1.5 text-gray-400 hover:text-blue-500 rounded-lg transition"
                          title="Mark all read"
                        >
                          <CheckCheck size={14} />
                        </button>
                        <button
                          onClick={clearAll}
                          className="p-1.5 text-gray-400 hover:text-red-500 rounded-lg transition"
                          title="Clear all"
                        >
                          <Trash2 size={14} />
                        </button>
                      </>
                    )}
                  </div>
                </div>

                {/* Notification list */}
                <div className="max-h-80 overflow-y-auto">
                  {notifications.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-10 text-gray-300 dark:text-gray-600">
                      <Bell size={28} className="mb-2 opacity-40" />
                      <p className="text-xs">No notifications yet</p>
                      {!connected && (
                        <p className="text-[10px] text-gray-400 mt-1">Connecting to server…</p>
                      )}
                    </div>
                  ) : (
                    <div className="divide-y divide-gray-50 dark:divide-gray-800">
                      {notifications.map(n => {
                        const isClickable = !!n.entity_type && ["job", "report", "amc"].includes(n.entity_type);
                        const handleClick = () => {
                          if (!n.read) markRead(n.id);
                          const paths = { job: `/jobs/${n.entity_id}`, report: `/reports/${n.entity_id}`, amc: "/amc" };
                          const path  = isClickable ? paths[n.entity_type] : null;
                          if (path) { navigate(path); setShowNotifMenu(false); }
                        };
                        return (
                          <motion.div
                            key={n.id}
                            initial={{ opacity: 0, x: -10 }}
                            animate={{ opacity: 1, x: 0 }}
                            onClick={handleClick}
                            className={`flex items-start gap-3 px-4 py-3 transition
                              ${n.read ? "opacity-60" : "bg-blue-50/30 dark:bg-blue-900/10"}
                              ${isClickable ? "cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800/50" : "hover:bg-gray-50/50 dark:hover:bg-gray-800/30"}`}
                          >
                            {/* Unread dot or read check */}
                            <div className="flex-shrink-0 mt-1.5">
                              {n.read
                                ? <div className="w-2 h-2 rounded-full bg-gray-200 dark:bg-gray-600" />
                                : <div className={`w-2 h-2 rounded-full ${NOTIF_DOT[n.color] || NOTIF_DOT.gray}`} />
                              }
                            </div>

                            {/* Content */}
                            <div className="flex-1 min-w-0">
                              <p className={`text-xs font-semibold leading-snug ${n.read ? "text-gray-500 dark:text-gray-400" : "text-gray-900 dark:text-white"}`}>
                                {n.title}
                              </p>
                              <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5 leading-snug line-clamp-2">{n.message}</p>
                              <div className="flex items-center gap-2 mt-1">
                                <span className="text-[10px] text-gray-400">{relativeTime(n.ts)}</span>
                                {n.entity_id && <span className="text-[10px] font-mono text-blue-400">{n.entity_id}</span>}
                              </div>
                            </div>

                            {/* Per-item mark read button */}
                            {!n.read && (
                              <button
                                onClick={e => { e.stopPropagation(); markRead(n.id); }}
                                className="flex-shrink-0 mt-1 p-1 text-gray-300 hover:text-blue-500 dark:text-gray-600 dark:hover:text-blue-400 rounded-lg transition"
                                title="Mark as read"
                              >
                                <CheckCheck size={12} />
                              </button>
                            )}
                          </motion.div>
                        );
                      })}
                    </div>
                  )}
                </div>

                {/* View all link */}
                <div className="border-t border-gray-100 dark:border-gray-800 px-4 py-2.5">
                  <button
                    onClick={() => { navigate("/activity"); setShowNotifMenu(false); }}
                    className="w-full text-center text-xs font-semibold text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 transition py-1"
                  >
                    View all notifications →
                  </button>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        <div className="h-6 w-px bg-gray-200 dark:bg-gray-800 mx-1" />

        {/* ── User menu ─────────────────────────────────── */}
        <div className="relative" ref={userMenuRef}>
          <button
            onClick={() => setShowUserMenu(p => !p)}
            className="flex items-center gap-2 p-1 pr-2 rounded-xl hover:bg-gray-100 dark:hover:bg-gray-800 transition-all"
          >
            <Avatar initials={getInitials(currentUser)} size="sm" />
            <div className="hidden md:block text-left">
              <p className="text-xs font-bold text-gray-900 dark:text-white leading-none">
                {currentUser?.first_name} {currentUser?.last_name}
              </p>
              <p className="text-[10px] text-gray-500 dark:text-gray-400 mt-0.5 uppercase tracking-wider">
                {currentUser?.role}
              </p>
            </div>
          </button>

          <AnimatePresence>
            {showUserMenu && (
              <motion.div
                initial={{ opacity: 0, y: 10, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: 10, scale: 0.95 }}
                transition={{ duration: 0.15 }}
                className="absolute right-0 mt-2 w-56 bg-white dark:bg-gray-900 rounded-2xl shadow-xl border border-gray-100 dark:border-gray-800 p-2"
              >
                <div className="px-3 py-2 mb-2 border-b border-gray-50 dark:border-gray-800">
                  <p className="text-sm font-bold text-gray-900 dark:text-white">
                    {currentUser?.first_name} {currentUser?.last_name}
                  </p>
                  <p className="text-xs text-gray-500 dark:text-gray-400 truncate">{currentUser?.email}</p>
                </div>

                <div className="space-y-0.5">
                  {[
                    { to: "/profile",  icon: User,     label: "Profile"  },
                    { to: "/settings", icon: Settings,  label: "Settings" },
                    ...(currentUser?.role?.toLowerCase() === "admin"
                      ? [{ to: "/users", icon: Users, label: "User Management" }]
                      : []),
                  ].map(item => (
                    <Link
                      key={item.to}
                      to={item.to}
                      onClick={() => setShowUserMenu(false)}
                      className="w-full flex items-center gap-3 px-3 py-2 rounded-xl text-sm text-gray-700 dark:text-gray-300 hover:bg-blue-50 dark:hover:bg-blue-900/20 hover:text-blue-600 dark:hover:text-blue-400 transition-all"
                    >
                      <item.icon size={16} />
                      <span>{item.label}</span>
                    </Link>
                  ))}

                  <button
                    onClick={() => setDarkMode(!darkMode)}
                    className="w-full flex items-center justify-between px-3 py-2 rounded-xl text-sm text-gray-700 dark:text-gray-300 hover:bg-blue-50 dark:hover:bg-blue-900/20 hover:text-blue-600 dark:hover:text-blue-400 transition-all"
                  >
                    <div className="flex items-center gap-3">
                      {darkMode ? <Sun size={16} /> : <Moon size={16} />}
                      <span>{darkMode ? "Light Mode" : "Dark Mode"}</span>
                    </div>
                    <div className={`w-8 h-4 rounded-full transition-colors ${darkMode ? "bg-blue-600" : "bg-gray-300"}`} />
                  </button>
                </div>

                <div className="mt-2 pt-2 border-t border-gray-50 dark:border-gray-800">
                  <button
                    onClick={() => dispatch(logout())}
                    className="w-full flex items-center gap-3 px-3 py-2 rounded-xl text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 transition-all"
                  >
                    <LogOut size={16} />
                    <span>Sign Out</span>
                  </button>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>
    </header>
  );
}