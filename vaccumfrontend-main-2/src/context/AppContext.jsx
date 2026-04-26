import { createContext, useContext, useState, useEffect } from "react";
import { TECHNICIANS, CLIENTS, JOBS, REPORTS, QUOTATIONS, AMC_CONTRACTS, ATTENDANCE, ACTIVITY_LOG, EMAIL_SETTINGS } from "../data/mockData";
import { useSelector } from "react-redux";

const AppContext = createContext();

export function AppProvider({ children }) {
  const { user: currentUser } = useSelector((state) => state.auth);
  
  // Initialize darkMode from localStorage
  const [darkMode, setDarkMode] = useState(() => {
    const saved = localStorage.getItem("darkMode");
    return saved ? JSON.parse(saved) : false;
  });

  const [technicians, setTechnicians] = useState(TECHNICIANS);
  const [clients, setClients] = useState(CLIENTS);
  const [jobs, setJobs] = useState(JOBS);
  const [reports, setReports] = useState(REPORTS);
  const [quotations, setQuotations] = useState(QUOTATIONS);
  const [amcContracts, setAmcContracts] = useState(AMC_CONTRACTS);
  const [attendance, setAttendance] = useState(ATTENDANCE);
  const [activityLog, setActivityLog] = useState(ACTIVITY_LOG);
  const [emailSettings, setEmailSettings] = useState(EMAIL_SETTINGS);
  const [searchQuery, setSearchQuery] = useState("");

  useEffect(() => {
    // Persist to localStorage whenever darkMode changes
    localStorage.setItem("darkMode", JSON.stringify(darkMode));
    
    if (darkMode) {
      document.documentElement.classList.add("dark");
    } else {
      document.documentElement.classList.remove("dark");
    }
  }, [darkMode]);

  const addActivity = (type, action) => {
    setActivityLog(prev => [{
      id: Date.now(), type, action,
      user: currentUser?.name || "System",
      timestamp: new Date().toLocaleString("en-IN", { dateStyle: "short", timeStyle: "short" })
    }, ...prev]);
  };

  // CRUD helpers
  const addTechnician = (t) => { const n = { ...t, id: Date.now(), jobsCompleted: 0, rating: 0 }; setTechnicians(p => [...p, n]); addActivity("technician", `Technician ${t.name} added`); };
  const updateTechnician = (id, data) => { setTechnicians(p => p.map(t => t.id === id ? { ...t, ...data } : t)); addActivity("technician", `Technician updated`); };
  const deleteTechnician = (id) => { const t = technicians.find(x => x.id === id); setTechnicians(p => p.filter(x => x.id !== id)); addActivity("technician", `Technician ${t?.name} removed`); };

  const addClient = (c) => { const n = { ...c, id: Date.now(), joinDate: new Date().toISOString().split("T")[0] }; setClients(p => [...p, n]); addActivity("client", `Client ${c.name} added`); };
  const updateClient = (id, data) => { setClients(p => p.map(c => c.id === id ? { ...c, ...data } : c)); addActivity("client", `Client updated`); };
  const deleteClient = (id) => { const c = clients.find(x => x.id === id); setClients(p => p.filter(x => x.id !== id)); addActivity("client", `Client ${c?.name} removed`); };

  const addJob = (j) => { const n = { ...j, id: `JOB-${String(Date.now()).slice(-4)}`, status: "Raised", raisedDate: new Date().toISOString().split("T")[0], images: [] }; setJobs(p => [...p, n]); addActivity("job", `Job ${n.id} raised`); };
  const updateJob = (id, data) => { setJobs(p => p.map(j => j.id === id ? { ...j, ...data } : j)); addActivity("job", `Job ${id} updated to ${data.status || "updated"}`); };

  const addReport = (r) => { const n = { ...r, id: `RPT-${String(Date.now()).slice(-4)}`, date: new Date().toISOString().split("T")[0], status: "Pending", images: [] }; setReports(p => [...p, n]); addActivity("report", `Report ${n.id} submitted`); };
  const updateReport = (id, data) => { setReports(p => p.map(r => r.id === id ? { ...r, ...data } : r)); addActivity("report", `Report ${id} ${data.status || "updated"}`); };

  const addQuotation = (q) => { const n = { ...q, id: `QT-${String(Date.now()).slice(-4)}`, createdDate: new Date().toISOString().split("T")[0], status: "Pending" }; setQuotations(p => [...p, n]); addActivity("quotation", `Quotation ${n.id} created`); };
  const updateQuotation = (id, data) => { setQuotations(p => p.map(q => q.id === id ? { ...q, ...data } : q)); addActivity("quotation", `Quotation ${id} updated`); };

  const addAmc = (a) => { const n = { ...a, id: `AMC-${String(Date.now()).slice(-4)}`, status: "Active" }; setAmcContracts(p => [...p, n]); addActivity("amc", `AMC ${n.id} created`); };
  const updateAmc = (id, data) => { setAmcContracts(p => p.map(a => a.id === id ? { ...a, ...data } : a)); };

  const markAttendance = (technicianId, data) => { setAttendance(p => [...p, { id: Date.now(), technicianId, ...data }]); };

  return (
    <AppContext.Provider value={{
      darkMode, setDarkMode, currentUser,
      technicians, clients, jobs, reports, quotations, amcContracts, attendance, activityLog, emailSettings, setEmailSettings,
      addTechnician, updateTechnician, deleteTechnician,
      addClient, updateClient, deleteClient,
      addJob, updateJob,
      addReport, updateReport,
      addQuotation, updateQuotation,
      addAmc, updateAmc,
      markAttendance, addActivity,
      searchQuery, setSearchQuery,
    }}>
      {children}
    </AppContext.Provider>
  );
}

export const useApp = () => useContext(AppContext);
