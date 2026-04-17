import { useState, useEffect } from "react";
import { AnimatePresence } from "framer-motion";
import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { getMe } from "./store/authSlice";
import { AppProvider } from "./context/AppContext";
import Sidebar, { TopBar } from "./components/Sidebar";
import Login from "./pages/Login";
import ForgotPassword from "./pages/ForgotPassword";
import Profile from "./pages/Profile";
import SettingsPage from "./pages/Settings";
import UserManagement from "./pages/UserManagement";
import Dashboard from "./pages/Dashboard";
import Technicians from "./pages/Technicians";
import Clients from "./pages/Clients";
import Jobs from "./pages/Jobs";
import Reports from "./pages/Reports";
import Quotations from "./pages/Quotations";
import AMC from "./pages/AMC";
import Attendance from "./pages/Attendance";
import EmailSettings from "./pages/EmailSettings";
import ActivityHistory from "./pages/ActivityHistory";
import { PageLoader, PageTransition } from "./components/ui";

// Protected Layout Component
const ProtectedLayout = ({ children, adminOnly = false, sidebarOpen, setSidebarOpen }) => {
  const { isAuthenticated, user: currentUser } = useSelector((state) => state.auth);
  const location = useLocation();

  if (!isAuthenticated) return <Navigate to="/login" />;
  // if (adminOnly && currentUser?.role?.toLowerCase() !== "admin") return <Navigate to="/" />;

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
  const [appReady, setAppAppReady] = useState(false);
  const [isNavigating, setIsNavigating] = useState(false);

  useEffect(() => {
    const initAuth = async () => {
      if (localStorage.getItem('token')) {
        await dispatch(getMe());
      }
      setAppAppReady(true);
    };
    initAuth();
  }, [dispatch]);

  // Handle route change loading effect
  useEffect(() => {
    setIsNavigating(true);
    const timer = setTimeout(() => setIsNavigating(false), 600); // Minimum loader time
    return () => clearTimeout(timer);
  }, [location.pathname]);

  if (loading || !appReady) {
    return <PageLoader />;
  }

  return (
    <>
      <AnimatePresence>
        {isNavigating && <PageLoader />}
      </AnimatePresence>
      <Routes>
        <Route path="/login" element={!isAuthenticated ? <Login /> : <Navigate to="/" />} />
      <Route path="/forgot-password" element={!isAuthenticated ? <ForgotPassword /> : <Navigate to="/" />} />
      
      <Route path="/" element={<ProtectedLayout sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen}><Dashboard /></ProtectedLayout>} />
      <Route path="/technicians" element={<ProtectedLayout sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen}><Technicians /></ProtectedLayout>} />
      <Route path="/clients" element={<ProtectedLayout sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen}><Clients /></ProtectedLayout>} />
      <Route path="/jobs" element={<ProtectedLayout sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen}><Jobs /></ProtectedLayout>} />
      <Route path="/reports" element={<ProtectedLayout sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen}><Reports /></ProtectedLayout>} />
      <Route path="/quotations" element={<ProtectedLayout sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen}><Quotations /></ProtectedLayout>} />
      <Route path="/amc" element={<ProtectedLayout sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen}><AMC /></ProtectedLayout>} />
      <Route path="/attendance" element={<ProtectedLayout sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen}><Attendance /></ProtectedLayout>} />
      <Route path="/email" element={<ProtectedLayout sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen} adminOnly><EmailSettings /></ProtectedLayout>} />
      <Route path="/activity" element={<ProtectedLayout sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen}><ActivityHistory /></ProtectedLayout>} />
      <Route path="/profile" element={<ProtectedLayout sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen}><Profile /></ProtectedLayout>} />
      <Route path="/settings" element={<ProtectedLayout sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen}><SettingsPage /></ProtectedLayout>} />
      <Route path="/users" element={<ProtectedLayout sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen} adminOnly><UserManagement /></ProtectedLayout>} />
      
      <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </>
  );
}

export default function App() {
  return (
    <AppProvider>
      <Router>
        <AppContent />
      </Router>
    </AppProvider>
  );
}
