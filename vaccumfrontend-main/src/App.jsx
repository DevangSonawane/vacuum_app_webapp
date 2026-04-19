import { useState, useEffect } from "react";
import { AnimatePresence } from "framer-motion";
import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { getMe } from "./store/authSlice";
import { AppProvider } from "./context/AppContext";
import { NotificationProvider } from "./context/NotificationContext";
import Sidebar, { TopBar } from "./components/Sidebar";

// Pages
import Login          from "./pages/Login";
import ForgotPassword from "./pages/ForgotPassword";
import Profile        from "./pages/Profile";
import SettingsPage   from "./pages/Settings";
import UserManagement from "./pages/UserManagement";
import Dashboard      from "./pages/Dashboard";
import Technicians    from "./pages/Technicians";
import Clients        from "./pages/Clients";
import Jobs           from "./pages/Jobs";
import JobDetail      from "./pages/JobDetail";
import Reports        from "./pages/Reports";
import ReportDetail   from "./pages/ReportDetail";
import Quotations     from "./pages/Quotations";
import AMC            from "./pages/AMC";
import Attendance     from "./pages/Attendance";
import EmailSettings  from "./pages/EmailSettings";
import ActivityHistory from "./pages/ActivityHistory";
import { PageLoader, PageTransition } from "./components/ui";

// ── Protected layout ──────────────────────────────────────────
const ProtectedLayout = ({ children, sidebarOpen, setSidebarOpen }) => {
  const { isAuthenticated } = useSelector((state) => state.auth);
  const location            = useLocation();
  if (!isAuthenticated) return <Navigate to="/login" />;

  return (
    <div className="flex h-screen bg-gray-50 dark:bg-gray-950 overflow-hidden font-sans">
      <Sidebar sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen} />
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        <TopBar setSidebarOpen={setSidebarOpen} />
        <main className="flex-1 overflow-y-auto">
          <AnimatePresence mode="wait">
            <PageTransition key={location.pathname}>
              {children}
            </PageTransition>
          </AnimatePresence>
        </main>
      </div>
    </div>
  );
};

function AppContent() {
  const dispatch = useDispatch();
  const location = useLocation();
  const { isAuthenticated, loading } = useSelector((state) => state.auth);
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [appReady, setAppReady]       = useState(false);
  const [isNavigating, setIsNavigating] = useState(false);

  useEffect(() => {
    const init = async () => {
      if (localStorage.getItem("token")) await dispatch(getMe());
      setAppReady(true);
    };
    init();
  }, [dispatch]);

  useEffect(() => {
    setIsNavigating(true);
    const t = setTimeout(() => setIsNavigating(false), 500);
    return () => clearTimeout(t);
  }, [location.pathname]);

  if (loading || !appReady) return <PageLoader />;

  // Shorthand wrapper
  const PL = ({ children }) => (
    <ProtectedLayout sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen}>
      {children}
    </ProtectedLayout>
  );

  return (
    <>
      <AnimatePresence>
        {isNavigating && <PageLoader />}
      </AnimatePresence>

      <Routes>
        {/* Public */}
        <Route path="/login"           element={!isAuthenticated ? <Login />          : <Navigate to="/" />} />
        <Route path="/forgot-password" element={!isAuthenticated ? <ForgotPassword /> : <Navigate to="/" />} />

        {/* Dashboard */}
        <Route path="/" element={<PL><Dashboard /></PL>} />

        {/* Core modules */}
        <Route path="/technicians" element={<PL><Technicians /></PL>} />
        <Route path="/clients"     element={<PL><Clients /></PL>} />

        {/* Jobs + detail */}
        <Route path="/jobs"     element={<PL><Jobs /></PL>} />
        <Route path="/jobs/:id" element={<PL><JobDetail /></PL>} />

        {/* Reports + detail */}
        <Route path="/reports"     element={<PL><Reports /></PL>} />
        <Route path="/reports/:id" element={<PL><ReportDetail /></PL>} />

        {/* Other modules */}
        <Route path="/quotations" element={<PL><Quotations /></PL>} />
        <Route path="/amc"        element={<PL><AMC /></PL>} />
        <Route path="/attendance" element={<PL><Attendance /></PL>} />
        <Route path="/activity"   element={<PL><ActivityHistory /></PL>} />

        {/* Admin only */}
        <Route path="/email" element={<PL><EmailSettings /></PL>} />
        <Route path="/users" element={<PL><UserManagement /></PL>} />

        {/* Profile / settings */}
        <Route path="/profile"  element={<PL><Profile /></PL>} />
        <Route path="/settings" element={<PL><SettingsPage /></PL>} />

        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </>
  );
}

export default function App() {
  return (
    // NotificationProvider must be outside AppContent so
    // useWebSocket can call localStorage.getItem("token") only
    // after the user is authenticated (token already stored).
    <AppProvider>
      <NotificationProvider>
        <Router>
          <AppContent />
        </Router>
      </NotificationProvider>
    </AppProvider>
  );
}