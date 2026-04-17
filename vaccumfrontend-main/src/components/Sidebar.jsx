import { useState, useEffect, useRef } from "react";
import {  motion,AnimatePresence } from "framer-motion";
import {
  LayoutDashboard, Users, UserCog, Briefcase, ClipboardList,
  FileText, DollarSign, Mail, ShieldCheck, Clock, LogOut,
  Wrench, ChevronRight, Menu, X, Search, Bell, HardHat,
  User, Settings, Moon, Sun
} from "lucide-react";
import { useDispatch, useSelector } from "react-redux";
import { Link, useLocation } from "react-router-dom";
import { logout } from "../store/authSlice";
import { useApp } from "../context/AppContext";
import { Avatar } from "./ui";

const NAV_ITEMS = [
  { id: "dashboard", label: "Dashboard", icon: LayoutDashboard, path: "/" },
  { id: "technicians", label: "Technicians", icon: UserCog, path: "/technicians" },
  { id: "clients", label: "Clients", icon: Users, path: "/clients" },
  { id: "jobs", label: "Work Orders", icon: Briefcase, path: "/jobs" },
  { id: "reports", label: "Service Reports", icon: ClipboardList, path: "/reports" },
  { id: "quotations", label: "Quotations", icon: DollarSign, path: "/quotations" },
  { id: "amc", label: "AMC Contracts", icon: ShieldCheck, path: "/amc" },
  { id: "attendance", label: "Attendance", icon: Clock, path: "/attendance" },
  { id: "email", label: "Email Settings", icon: Mail, path: "/email", adminOnly: true },
  { id: "activity", label: "Activity History", icon: FileText, path: "/activity" },
  { id: "users", label: "Users", icon: Users, path: "/users", adminOnly: true },
];

export default function Sidebar({ sidebarOpen, setSidebarOpen }) {
  const { user: currentUser } = useSelector((state) => state.auth);
  const location = useLocation();
  const dispatch = useDispatch();
  const [isLargeScreen, setIsLargeScreen] = useState(window.innerWidth >= 1024);

  useEffect(() => {
    const handleResize = () => setIsLargeScreen(window.innerWidth >= 1024);
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  const isAdmin = currentUser?.role?.toLowerCase() === "admin";
  const filteredNav = NAV_ITEMS.filter(n => !n.adminOnly || isAdmin);

  return (
    <>
      {/* Mobile overlay */}
      <AnimatePresence>
        {sidebarOpen && (
          <motion.div
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/50 z-40 lg:hidden"
            onClick={() => setSidebarOpen(false)}
          />
        )}
      </AnimatePresence>

      {/* Sidebar */}
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
              <p className="text-white font-bold text-sm font-display leading-tight uppercase tracking-wider">VDTI</p>
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
            const Icon = item.icon;
            const active = location.pathname === item.path;
            return (
              <Link
                key={item.id}
                to={item.path}
                onClick={() => setSidebarOpen(false)}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-150 group relative ${
                  active
                    ? "bg-blue-600 text-white shadow-lg shadow-blue-600/30"
                    : "text-blue-200 hover:bg-white/5 hover:text-white"
                }`}
              >
                <Icon size={20} className={active ? "text-white" : "text-blue-400 group-hover:text-white"} />
                <span className="flex-1 text-left whitespace-nowrap">{item.label}</span>
                {active && <ChevronRight size={14} className="text-blue-300" />}
              </Link>
            );
          })}
        </nav>

        {/* Logout at bottom */}
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

// ── Top Bar ───────────────────────────────────────────────────────────────
export function TopBar({ setSidebarOpen }) {
  const dispatch = useDispatch();
  const location = useLocation();
  const { user: currentUser } = useSelector((state) => state.auth);
  const { darkMode, setDarkMode, searchQuery, setSearchQuery } = useApp();
  const [showDropdown, setShowDropdown] = useState(false);
  const dropdownRef = useRef(null);
  
  const currentNavItem = NAV_ITEMS.find(n => n.path === location.pathname);
  let label = currentNavItem?.label || "Dashboard";
  
  // Handle profile/settings/users which might not be in NAV_ITEMS or have different paths
  if (location.pathname === "/profile") label = "Profile";
  if (location.pathname === "/settings") label = "Settings";
  if (location.pathname === "/users") label = "User Management";

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setShowDropdown(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const getInitials = (name) => {
    if (!name) return "";
    const parts = name.split(" ");
    if (parts.length >= 2) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  };

  return (
    <header className="sticky top-0 z-30 bg-white/80 dark:bg-gray-950/80 backdrop-blur-md border-b border-gray-100 dark:border-gray-800 px-4 py-3 flex items-center lg:flex-row-reverse flex-row gap-3">
      {/* Mobile Hamburger - Always first on mobile */}
      <button onClick={() => setSidebarOpen(true)} className="lg:hidden text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-white flex-shrink-0">
        <Menu size={22} />
      </button>
      
      {/* Mobile Order: Hamburger -> Search -> User -> Bell */}
      {/* Desktop Order: Reverse (User -> Bell -> Search -> Title) */}

      <div className="flex items-center gap-2 sm:gap-4 order-3 lg:order-1 flex-shrink-0">
        <div className="relative" ref={dropdownRef}>
          <button 
            onClick={() => setShowDropdown(!showDropdown)}
            className="flex items-center gap-2 p-1 pr-2 rounded-xl hover:bg-gray-100 dark:hover:bg-gray-800 transition-all"
          >
            <Avatar initials={currentUser?.avatar || getInitials(currentUser?.first_name)} size="sm" />
            <div className="hidden md:block text-left">
              <p className="text-xs font-bold text-gray-900 dark:text-white leading-none">{currentUser?.first_name} {currentUser?.last_name}</p>
              <p className="text-[10px] text-gray-500 dark:text-gray-400 mt-1 uppercase tracking-wider">{currentUser?.role}</p>
            </div>
          </button>

          <AnimatePresence>
            {showDropdown && (
              <motion.div
                initial={{ opacity: 0, y: 10, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: 10, scale: 0.95 }}
                className="absolute left-0 lg:left-auto lg:right-0 mt-2 w-56 bg-white dark:bg-gray-900 rounded-2xl shadow-xl border border-gray-100 dark:border-gray-800 p-2 overflow-hidden"
              >
                <div className="px-3 py-2 mb-2 border-b border-gray-50 dark:border-gray-800">
                  <p className="text-sm font-bold text-gray-900 dark:text-white">{currentUser?.first_name} {currentUser?.last_name}</p>
                  <p className="text-xs text-gray-500 dark:text-gray-400 truncate">{currentUser?.email}</p>
                </div>

                <div className="space-y-1">
                  <Link 
                    to="/profile"
                    onClick={() => setShowDropdown(false)}
                    className="w-full flex items-center gap-3 px-3 py-2 rounded-xl text-sm text-gray-700 dark:text-gray-300 hover:bg-blue-50 dark:hover:bg-blue-900/20 hover:text-blue-600 dark:hover:text-blue-400 transition-all"
                  >
                    <User size={18} />
                    <span>Profile</span>
                  </Link>
                  <Link 
                    to="/settings"
                    onClick={() => setShowDropdown(false)}
                    className="w-full flex items-center gap-3 px-3 py-2 rounded-xl text-sm text-gray-700 dark:text-gray-300 hover:bg-blue-50 dark:hover:bg-blue-900/20 hover:text-blue-600 dark:hover:text-blue-400 transition-all"
                  >
                    <Settings size={18} />
                    <span>Settings</span>
                  </Link>
                  {currentUser?.role?.toLowerCase() === "admin" && (
                    <Link 
                      to="/users"
                      onClick={() => setShowDropdown(false)}
                      className="w-full flex items-center gap-3 px-3 py-2 rounded-xl text-sm text-gray-700 dark:text-gray-300 hover:bg-blue-50 dark:hover:bg-blue-900/20 hover:text-blue-600 dark:hover:text-blue-400 transition-all"
                    >
                      <Users size={18} />
                      <span>User Management</span>
                    </Link>
                  )}
                  <button 
                    onClick={() => setDarkMode(!darkMode)}
                    className="w-full flex items-center justify-between px-3 py-2 rounded-xl text-sm text-gray-700 dark:text-gray-300 hover:bg-blue-50 dark:hover:bg-blue-900/20 hover:text-blue-600 dark:hover:text-blue-400 transition-all"
                  >
                    <div className="flex items-center gap-3">
                      {darkMode ? <Sun size={18} /> : <Moon size={18} />}
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
                    <LogOut size={18} />
                    <span>Sign Out</span>
                  </button>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        <div className="h-6 w-px bg-gray-200 dark:bg-gray-800 mx-1 hidden sm:block" />

        <button className="relative p-2 text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-xl transition-all order-4 lg:order-2">
          <Bell size={20} />
          <span className="absolute top-2 right-2 w-4 h-4 bg-red-500 rounded-full text-[10px] font-bold text-white flex items-center justify-center border-2 border-white dark:border-gray-950">3</span>
        </button>
      </div>

      <div className="flex-1 relative max-w-sm ml-0 lg:ml-4 order-2 lg:order-3 min-w-0">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
        <input
          type="text"
          value={searchQuery}
          onChange={e => setSearchQuery(e.target.value)}
          placeholder="Global search..."
          className="w-full pl-10 pr-4 py-2 rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-900/50 text-gray-900 dark:text-gray-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
        />
      </div>

      <h2 className="font-bold text-gray-900 dark:text-white text-lg font-display hidden sm:block order-5 lg:mr-auto">{label}</h2>
    </header>
  );
}
