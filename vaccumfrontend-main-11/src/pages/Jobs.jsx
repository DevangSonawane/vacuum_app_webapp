import { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion"; // motion used as motion.div — ESLint false positive
import {
  Plus, Briefcase, ArrowRight, Calendar, User, X,
  CheckCircle, Loader2, Upload, MoreVertical, Eye,
  Camera, ShieldCheck, Download, Building2, MapPin, Search, UserCog, Trash2, AlertTriangle,
} from "lucide-react";
import axios from "axios";
import { useApp } from "../context/AppContext";
import {
  PageTransition, Card, Badge, Button, Modal, Input,
  Select, DatePicker, Textarea, SectionHeader, EmptyState, useToast, Toast,
} from "../components/ui";

const API_BASE_URL = "https://api.vdtil.com/api";

const STATUSES   = ["Raised", "Assigned", "In Progress", "Closed"];
const PRIORITIES = ["Low", "Medium", "High", "Critical"];
const CATEGORIES = ["Service", "AMC Visit", "Breakdown", "Installation & Commissioning", "Inspection"];

const STATUS_FLOW    = { Raised: "Assigned", Assigned: "In Progress", "In Progress": "Closed" };
const ITEMS_PER_PAGE = 15;

const STATUS_DOT = {
  Raised:        "bg-purple-500",
  Assigned:      "bg-blue-500",
  "In Progress": "bg-amber-500",
  Closed:        "bg-emerald-500",
};
const PRIORITY_COLORS = {
  Low:      "bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-300",
  Medium:   "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300",
  High:     "bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-300",
  Critical: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300",
};

const EMPTY_FORM = {
  title: "", client_id: "", technician_id: "",
  priority: "Medium", category: "Maintenance",
  description: "", scheduled_date: "", amount: "",
  amc_id: "",
};

// eslint-disable-next-line no-unused-vars
function AutocompleteInput({ items, value, onChange, label, required, placeholder, icon: Icon, subField, className = "" }) {
  const [query, setQuery] = useState("");
  const [focused, setFocused] = useState(false);
  const containerRef = useRef();
  const inputRef = useRef();

  useEffect(() => {
    const handler = (e) => { if (containerRef.current && !containerRef.current.contains(e.target)) setFocused(false); };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const selected = items.find(c => c.id === value || String(c.id) === String(value));
  const q = query.toLowerCase();
  const filtered = q
    ? items.filter(c => c.name?.toLowerCase().includes(q) || (subField && c[subField]?.toLowerCase().includes(q)) || c.phone?.includes(query))
    : items;

  const handleSelect = (c) => { onChange(c.id); setQuery(c.name); setFocused(false); };
  const handleClear = () => { onChange(""); setQuery(""); inputRef.current?.focus(); };
  const displayQuery = focused ? query : (selected ? selected.name : query);

  return (
    <div className={`relative ${className}`} ref={containerRef}>
      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
        {label}{required && <span className="text-red-500 ml-1">*</span>}
      </label>
      <div className="relative">
        <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
        <input
          ref={inputRef}
          type="text"
          value={displayQuery}
          onChange={(e) => { setQuery(e.target.value); setFocused(true); if (value) onChange(""); }}
          onFocus={() => setFocused(true)}
          placeholder={placeholder || `Search ${label?.toLowerCase()}...`}
          className={`w-full pl-9 pr-9 py-2 rounded-xl border text-sm transition-all ${
            focused ? "border-blue-500 ring-2 ring-blue-500/20 bg-white dark:bg-gray-800" : "border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700"
          } text-gray-900 dark:text-gray-100 focus:outline-none`}
        />
        {(query || value) && (
          <button type="button" onClick={handleClear} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200">
            <X size={14} />
          </button>
        )}
      </div>
      <AnimatePresence>
        {focused && (
          <motion.div
            initial={{ opacity: 0, y: 4, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 4, scale: 0.98 }}
            transition={{ duration: 0.1 }}
            className="absolute z-[100] left-0 right-0 mt-1 bg-white dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-xl shadow-xl overflow-hidden"
          >
            <div className="max-h-64 overflow-y-auto py-1 custom-scrollbar">
              {filtered.length === 0 ? (
                <div className="px-4 py-4 text-sm text-gray-400 text-center">No results found</div>
              ) : (
                filtered.map((c) => {
                  const isSelected = String(c.id) === String(value);
                  return (
                    <div key={c.id} onClick={() => handleSelect(c)}
                      className={`px-4 py-3 cursor-pointer transition-colors ${isSelected ? "bg-blue-50 dark:bg-blue-900/20" : "hover:bg-gray-50 dark:hover:bg-gray-700/50"}`}
                    >
                      <div className="flex items-center justify-between gap-2">
                        <div className="flex items-center gap-2.5 min-w-0">
                          <div className="w-8 h-8 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center flex-shrink-0">
                            <Icon size={14} className="text-blue-600 dark:text-blue-400" />
                          </div>
                          <div className="min-w-0">
                            <p className={`text-sm font-medium truncate ${isSelected ? "text-blue-600 dark:text-blue-400" : "text-gray-900 dark:text-gray-100"}`}>{c.name}</p>
                            {subField && c[subField] && (
                              <p className="text-xs text-gray-400 truncate flex items-center gap-1 mt-0.5">
                                <MapPin size={10} className="flex-shrink-0" /> {c[subField]}
                              </p>
                            )}
                          </div>
                        </div>
                        {isSelected && <CheckCircle size={14} className="text-blue-500 flex-shrink-0" />}
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

function ActionMenu({ items, onClose }) {
  const ref = useRef();
  useEffect(() => {
    const handler = (e) => { if (ref.current && !ref.current.contains(e.target)) onClose(); };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, [onClose]);

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, scale: 0.95, y: -4 }}
      animate={{ opacity: 1, scale: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.95, y: -4 }}
      transition={{ duration: 0.1 }}
      className="absolute right-0 top-full mt-1 z-50 w-44 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl shadow-xl py-1 overflow-hidden"
    >
      {items.map((item) => (
        <button
          key={item.label}
          onClick={item.onClick}
          className={`w-full flex items-center gap-2.5 px-3.5 py-2.5 text-sm font-medium transition-colors ${
            item.danger
              ? "text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20"
              : "text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700/50"
          }`}
        >
          <item.icon size={14} />
          {item.label}
        </button>
      ))}
    </motion.div>
  );
}

export default function Jobs() {
  const { currentUser } = useApp();
  const navigate = useNavigate();
  const { toast, showToast } = useToast();

  const [jobs, setJobs]               = useState([]);
  const [clients, setClients]         = useState([]);
  const [technicians, setTechnicians] = useState([]);
  const [amcContracts, setAmcContracts] = useState([]);
  const [loading, setLoading]         = useState(true);
  const [filter, setFilter]           = useState("All");
  const [menuOpen, setMenuOpen]       = useState(null);

  const [modalOpen, setModalOpen]   = useState(false);
  const [form, setForm]             = useState(EMPTY_FORM);
  const [submitting, setSubmitting] = useState(false);

  const [closeModal, setCloseModal]     = useState(false);
  const [closingJob, setClosingJob]     = useState(null);
  const [verifyImages, setVerifyImages] = useState([]);
  const [closing, setClosing]           = useState(false);
  const fileRef = useRef();

  const [deleteJob, setDeleteJob] = useState(null);
  const [deleting, setDeleting]   = useState(false);
  const [page, setPage]           = useState(1);

  // Export
  const [exportOpen, setExportOpen]       = useState(false);
  const [exporting, setExporting]         = useState(false);
  const now = new Date();
  const [exportMonth, setExportMonth]     = useState(now.getMonth() + 1);
  const [exportYear, setExportYear]       = useState(now.getFullYear());
  const [exportTechId, setExportTechId]   = useState("");
  const [exportStatus, setExportStatus]   = useState("");
  const [exportCategory, setExportCategory] = useState("");

  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => { fetchJobs(); fetchClients(); fetchTechnicians(); fetchAmcContracts(); }, []);

  // Reset to page 1 whenever the active tab changes
  useEffect(() => { setPage(1); }, [filter]);

  const fetchJobs = async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem("token");
      // Always fetch all jobs so every tab's count is correct; filtering is done client-side
      const url = (currentUser?.role === "technician" && currentUser?.id)
        ? `${API_BASE_URL}/jobs/by-user/${currentUser.id}`
        : `${API_BASE_URL}/jobs`;
      const res = await axios.get(url, { headers: { Authorization: `Bearer ${token}` }, params: { limit: 500 } });
      if (res.data.success) setJobs(res.data.data || []);
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to fetch jobs", "error");
    } finally {
      setLoading(false);
    }
  };

  const fetchClients = async () => {
    try {
      const token = localStorage.getItem("token");
      const res = await axios.get(`${API_BASE_URL}/clients`, { headers: { Authorization: `Bearer ${token}` } });
      if (res.data.success) setClients(res.data.data || []);
    } catch { /* ignore */ }
  };

  const fetchTechnicians = async () => {
    try {
      const token = localStorage.getItem("token");
      const res = await axios.get(`${API_BASE_URL}/technicians`, { headers: { Authorization: `Bearer ${token}` }, params: { limit: 200 } });
      if (res.data.success) setTechnicians(res.data.data || []);
    } catch { /* ignore */ }
  };

  const fetchAmcContracts = async () => {
    try {
      const token = localStorage.getItem("token");
      const res = await axios.get(`${API_BASE_URL}/amc`, { headers: { Authorization: `Bearer ${token}` }, params: { limit: 200 } });
      if (res.data.success) setAmcContracts(res.data.data || []);
    } catch { /* ignore */ }
  };

  const f = (field) => (e) => setForm(p => ({ ...p, [field]: e.target.value }));

  const handleCreate = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const token = localStorage.getItem("token");
      const payload = { title: form.title.trim(), client_id: parseInt(form.client_id), priority: form.priority, category: form.category };
      if (form.technician_id)  payload.technician_id  = parseInt(form.technician_id);
      if (form.description)    payload.description    = form.description.trim();
      if (form.scheduled_date) payload.scheduled_date = form.scheduled_date;
      if (form.amount)         payload.amount         = parseFloat(form.amount);
      if (form.amc_id)         payload.amc_id         = form.amc_id;

      await axios.post(`${API_BASE_URL}/jobs`, payload, { headers: { Authorization: `Bearer ${token}` } });
      showToast("Visit scheduled!");
      setModalOpen(false);
      setForm(EMPTY_FORM);
      fetchJobs();
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to raise job", "error");
    } finally {
      setSubmitting(false);
    }
  };

  const advanceStatus = (job) => {
    setMenuOpen(null);
    const next = STATUS_FLOW[job.status];
    if (!next) return;
    if (job.status === "In Progress") {
      setClosingJob(job);
      setVerifyImages([]);
      setCloseModal(true);
      return;
    }
    doAdvance(job, next);
  };

  const doAdvance = async (job, next) => {
    try {
      const token = localStorage.getItem("token");
      await axios.patch(`${API_BASE_URL}/jobs/${job.id}/status`, { status: next }, { headers: { Authorization: `Bearer ${token}` } });
      showToast(`Job moved to ${next}`);
      fetchJobs();
    } catch (err) {
      showToast(err.response?.data?.message || "Status update failed", "error");
    }
  };

  const handleVerifyImageSelect = (e) => {
    const files = Array.from(e.target.files);
    setVerifyImages(p => [...p, ...files.map(file => ({ file, preview: URL.createObjectURL(file), uploading: false, uploaded_url: null, error: null }))]);
    e.target.value = "";
  };

  const removeVerifyImage = (idx) => setVerifyImages(p => p.filter((_, i) => i !== idx));

  const uploadVerifyImage = async (imgObj, idx) => {
    setVerifyImages(p => p.map((im, i) => i === idx ? { ...im, uploading: true, error: null } : im));
    try {
      const token = localStorage.getItem("token");
      const fd = new FormData();
      fd.append("images", imgObj.file);
      const uploadRes = await axios.post(`${API_BASE_URL}/upload?entity_type=job&entity_id=${closingJob.id}`, fd, {
        headers: { Authorization: `Bearer ${token}`, "Content-Type": "multipart/form-data" },
      });
      const uploaded = uploadRes.data.data?.[0];
      if (!uploaded) throw new Error("Upload response empty");
      await axios.post(`${API_BASE_URL}/jobs/${closingJob.id}/images`, {
        file_name: uploaded.original_name, file_url: uploaded.file_url,
        mime_type: uploaded.mime_type || "image/jpeg", file_size_bytes: uploaded.file_size_bytes,
      }, { headers: { Authorization: `Bearer ${token}` } });
      setVerifyImages(p => p.map((im, i) => i === idx ? { ...im, uploading: false, uploaded_url: uploaded.file_url } : im));
    } catch {
      setVerifyImages(p => p.map((im, i) => i === idx ? { ...im, uploading: false, error: "Upload failed" } : im));
    }
  };

  const handleCloseJob = async () => {
    if (!closingJob) return;
    setClosing(true);
    const pending = verifyImages.map((im, idx) => ({ im, idx })).filter(x => !x.im.uploaded_url && !x.im.uploading);
    await Promise.all(pending.map(({ im, idx }) => uploadVerifyImage(im, idx)));
    if (verifyImages.some(im => im.error)) { showToast("Some images failed. Please retry.", "error"); setClosing(false); return; }
    try {
      const token = localStorage.getItem("token");
      await axios.patch(`${API_BASE_URL}/jobs/${closingJob.id}/status`, { status: "Closed" }, { headers: { Authorization: `Bearer ${token}` } });
      showToast(`Job ${closingJob.id} closed!`);
      setCloseModal(false); setClosingJob(null); setVerifyImages([]);
      fetchJobs();
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to close job", "error");
    } finally {
      setClosing(false);
    }
  };

  const handleExport = async () => {
    setExporting(true);
    try {
      const token = localStorage.getItem("token");
      const params = { month: exportMonth, year: exportYear };
      if (exportTechId)   params.technician_id = exportTechId;
      if (exportStatus)   params.status        = exportStatus;
      if (exportCategory) params.category      = exportCategory;

      const res = await axios.get(`${API_BASE_URL}/reports/visit-schedule/excel`, {
        headers: { Authorization: `Bearer ${token}` },
        params,
        responseType: "blob",
      });

      const url  = window.URL.createObjectURL(new Blob([res.data]));
      const a    = document.createElement("a");
      a.href     = url;
      a.download = `visit-schedule-${exportYear}-${String(exportMonth).padStart(2, "0")}.xlsx`;
      a.click();
      window.URL.revokeObjectURL(url);
      showToast("Excel downloaded!");
      setExportOpen(false);
    } catch (err) {
      showToast(err.response?.data?.message || "Export failed", "error");
    } finally {
      setExporting(false);
    }
  };

  const canRaise = !["technician", "labour"].includes(currentUser?.role);
  const isAdmin  = currentUser?.role?.toLowerCase() === "admin";

  const handleDelete = (job) => {
    setMenuOpen(null);
    setDeleteJob(job);
  };

  const confirmDelete = async () => {
    if (!deleteJob) return;
    setDeleting(true);
    try {
      const token = localStorage.getItem("token");
      await axios.delete(`${API_BASE_URL}/jobs/${deleteJob.id}`, { headers: { Authorization: `Bearer ${token}` } });
      showToast("Job deleted");
      setDeleteJob(null);
      fetchJobs();
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to delete job", "error");
    } finally {
      setDeleting(false);
    }
  };

  const activeCount    = jobs.filter(j => j.status !== "Closed").length;
  const filtered       = filter === "All" ? jobs : jobs.filter(j => j.status === filter);
  const totalPages     = Math.max(1, Math.ceil(filtered.length / ITEMS_PER_PAGE));
  const paginatedJobs  = filtered.slice((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE);

  const statusCounts = {};
  STATUSES.forEach(s => { statusCounts[s] = jobs.filter(j => j.status === s).length; });

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-7xl mx-auto">
        <SectionHeader
          title="Visit Scheduled"
          subtitle={`${activeCount} active of ${jobs.length} total`}
          action={<div className="flex gap-2">
            <Button variant="secondary" onClick={() => setExportOpen(true)}><Download size={15} /> Export</Button>
            {canRaise && <Button onClick={() => setModalOpen(true)}><Plus size={16} /> Raise Job</Button>}
          </div>}
        />

        {/* Status tabs */}
        <div className="flex border-b border-gray-200 dark:border-gray-700 mb-5 overflow-x-auto">
          {["All", ...STATUSES].map(s => {
            const count = s === "All" ? jobs.length : statusCounts[s];
            return (
              <button key={s} onClick={() => setFilter(s)}
                className={`relative flex items-center gap-1.5 px-4 py-2.5 text-sm font-semibold whitespace-nowrap transition-colors ${
                  filter === s
                    ? "text-blue-600 dark:text-blue-400"
                    : "text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300"
                }`}
              >
                {s !== "All" && <span className={`w-2 h-2 rounded-full flex-shrink-0 ${STATUS_DOT[s]}`} />}
                {s}
                <span className={`text-[11px] px-1.5 py-0.5 rounded-full font-medium tabular-nums min-w-[18px] text-center ${
                  filter === s
                    ? "bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400"
                    : "bg-gray-100 dark:bg-gray-700 text-gray-500 dark:text-gray-400"
                }`}>{loading ? "·" : count}</span>
                {filter === s && <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-blue-600 dark:bg-blue-400 rounded-t-sm" />}
              </button>
            );
          })}
        </div>

        {/* Content */}
        {loading ? (
          <div className="space-y-2">
            {[...Array(6)].map((_, i) => (
              <div key={i} className="bg-white dark:bg-gray-800 rounded-xl p-4 border border-gray-100 dark:border-gray-700 animate-pulse flex items-center gap-3">
                <div className="w-1 h-14 bg-gray-200 dark:bg-gray-700 rounded-full flex-shrink-0" />
                <div className="flex-1 space-y-2">
                  <div className="flex gap-2 items-center">
                    <div className="h-3 w-14 bg-gray-200 dark:bg-gray-700 rounded" />
                    <div className="h-3 w-10 bg-gray-200 dark:bg-gray-700 rounded" />
                  </div>
                  <div className="h-4 w-2/3 bg-gray-200 dark:bg-gray-700 rounded" />
                  <div className="h-3 w-1/2 bg-gray-100 dark:bg-gray-800 rounded" />
                </div>
                <div className="h-5 w-20 bg-gray-200 dark:bg-gray-700 rounded-full flex-shrink-0" />
              </div>
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <EmptyState icon={Briefcase} title="No jobs found" description={filter === "All" ? "Raise a new job to get started." : `No jobs with status "${filter}".`} />
        ) : (
          <div className="space-y-2">
            {paginatedJobs.map((job, i) => (
              <motion.div key={job.id} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.025 }}>
                <Card hover className="p-4 cursor-pointer" onClick={() => navigate(`/jobs/${job.id}`)}>
                  <div className="flex items-center gap-3">
                    {/* Status bar */}
                    <div className={`w-1 self-stretch rounded-full flex-shrink-0 ${STATUS_DOT[job.status]}`} />

                    {/* Main content */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-start justify-between gap-3">
                        <div className="min-w-0 flex-1">
                          <div className="flex items-center gap-2 flex-wrap mb-0.5">
                            <span className="font-mono text-xs text-blue-500 dark:text-blue-400 font-bold">{job.id}</span>
                            <span className={`text-[10px] px-2 py-0.5 rounded-full font-bold ${PRIORITY_COLORS[job.priority] || PRIORITY_COLORS.Medium}`}>{job.priority}</span>
                            {job.category && (
                              <span className="hidden sm:inline text-[10px] px-2 py-0.5 rounded-full font-medium bg-gray-100 dark:bg-gray-700 text-gray-500 dark:text-gray-400">{job.category}</span>
                            )}
                          </div>
                          <p className="font-semibold text-gray-900 dark:text-white text-sm truncate">{job.title}</p>
                        </div>

                        {/* Right side */}
                        <div className="flex items-center gap-2 flex-shrink-0" onClick={e => e.stopPropagation()}>
                          <Badge label={job.status} />
                          {job.amount > 0 && (
                            <span className="text-sm font-bold text-gray-900 dark:text-white hidden sm:block">₹{Number(job.amount).toLocaleString()}</span>
                          )}
                          {canRaise && (
                            <div className="relative">
                              <button
                                onClick={() => setMenuOpen(menuOpen === job.id ? null : job.id)}
                                className="p-1.5 rounded-lg text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition"
                              >
                                <MoreVertical size={15} />
                              </button>
                              <AnimatePresence>
                                {menuOpen === job.id && (
                                  <ActionMenu onClose={() => setMenuOpen(null)} items={[
                                    { label: "View Details", icon: Eye, onClick: () => { setMenuOpen(null); navigate(`/jobs/${job.id}`); } },
                                    ...(STATUS_FLOW[job.status] ? [{
                                      label: job.status === "In Progress" ? "Close Job" : `Move to ${STATUS_FLOW[job.status]}`,
                                      icon: job.status === "In Progress" ? Camera : ArrowRight,
                                      onClick: () => advanceStatus(job),
                                    }] : []),
                                    ...(isAdmin && ["Raised", "Assigned"].includes(job.status) ? [{
                                      label: "Delete", icon: Trash2, danger: true,
                                      onClick: () => handleDelete(job),
                                    }] : []),
                                  ]} />
                                )}
                              </AnimatePresence>
                            </div>
                          )}
                        </div>
                      </div>

                      {/* Meta row */}
                      <div className="flex flex-wrap items-center gap-x-4 gap-y-1 mt-1.5 text-xs text-gray-500 dark:text-gray-400">
                        {job.client_name && <span className="flex items-center gap-1.5"><User size={11} className="flex-shrink-0" />{job.client_name}</span>}
                        {job.technician_name && <span className="flex items-center gap-1.5"><User size={11} className="text-blue-400 flex-shrink-0" />{job.technician_name}</span>}
                        {job.scheduled_date && <span className="flex items-center gap-1.5"><Calendar size={11} className="flex-shrink-0" />{job.scheduled_date.slice(0, 10)}</span>}
                        {job.amc_id && (
                          <span className="flex items-center gap-1.5 text-purple-500 font-medium">
                            <ShieldCheck size={11} className="flex-shrink-0" />{job.amc_title || "AMC"}
                          </span>
                        )}
                        {job.amount > 0 && (
                          <span className="sm:hidden font-bold text-gray-900 dark:text-white">₹{Number(job.amount).toLocaleString()}</span>
                        )}
                      </div>
                    </div>
                  </div>
                </Card>
              </motion.div>
            ))}
          </div>
        )}

        {/* Pagination */}
        {!loading && filtered.length > ITEMS_PER_PAGE && (
          <div className="mt-6 pt-5 border-t border-gray-100 dark:border-gray-700 flex flex-col sm:flex-row items-center justify-between gap-3">
            <p className="text-sm text-gray-500 dark:text-gray-400">
              Showing{" "}
              <span className="font-semibold text-gray-900 dark:text-white">{(page - 1) * ITEMS_PER_PAGE + 1}</span>
              {" – "}
              <span className="font-semibold text-gray-900 dark:text-white">{Math.min(page * ITEMS_PER_PAGE, filtered.length)}</span>
              {" of "}
              <span className="font-semibold text-gray-900 dark:text-white">{filtered.length}</span>
            </p>
            <div className="flex items-center gap-1">
              <button
                onClick={() => setPage(p => Math.max(1, p - 1))}
                disabled={page === 1}
                className="px-3 py-1.5 rounded-lg text-sm font-medium border border-gray-200 dark:border-gray-600 text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-40 disabled:cursor-not-allowed transition"
              >
                ← Prev
              </button>
              {Array.from({ length: totalPages }, (_, i) => i + 1)
                .filter(pg => pg === 1 || pg === totalPages || Math.abs(pg - page) <= 1)
                .reduce((acc, pg, idx, arr) => {
                  if (idx > 0 && pg - arr[idx - 1] > 1) acc.push("…");
                  acc.push(pg);
                  return acc;
                }, [])
                .map((item, idx) =>
                  item === "…" ? (
                    <span key={`ellipsis-${idx}`} className="w-8 text-center text-gray-400 text-sm">…</span>
                  ) : (
                    <button
                      key={item}
                      onClick={() => setPage(item)}
                      className={`w-8 h-8 rounded-lg text-sm font-medium transition-all ${
                        page === item
                          ? "bg-blue-600 text-white"
                          : "text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
                      }`}
                    >
                      {item}
                    </button>
                  )
                )}
              <button
                onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="px-3 py-1.5 rounded-lg text-sm font-medium border border-gray-200 dark:border-gray-600 text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-40 disabled:cursor-not-allowed transition"
              >
                Next →
              </button>
            </div>
          </div>
        )}

        {/* Raise Job Modal */}
        <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title="Schedule New Visit" size="lg">
          <form onSubmit={handleCreate} className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <Input label="Job Title" value={form.title} onChange={f("title")} required className="col-span-2" />
              <AutocompleteInput
                items={clients} value={form.client_id}
                onChange={(id) => setForm(p => ({ ...p, client_id: id }))}
                label="Client" required placeholder="Search clients..."
                icon={Building2} subField="address"
              />
              <AutocompleteInput
                items={technicians} value={form.technician_id}
                onChange={(id) => setForm(p => ({ ...p, technician_id: id }))}
                label="Assign Technician" placeholder="Search technicians..."
                icon={UserCog} subField="specialization"
              />
              <Select label="Priority" value={form.priority} onChange={f("priority")} options={PRIORITIES} />
              <Select label="Category" value={form.category} onChange={f("category")} options={CATEGORIES} />
              <DatePicker label="Scheduled Date" value={form.scheduled_date} onChange={f("scheduled_date")} />
              <Input label="Amount (₹)" type="number" value={form.amount} onChange={f("amount")} />
              <div className="col-span-2">
                <Select label="Linked AMC Contract" placeholder="— Not linked —" value={form.amc_id}
                  onChange={e => setForm(p => ({ ...p, amc_id: e.target.value }))} searchable
                  options={amcContracts.map(a => ({ value: a.id, label: `${a.id}${a.po_number ? ` | PO: ${a.po_number}` : ""} — ${a.title}` }))} />
                {form.amc_id && (() => {
                  const sel = amcContracts.find(a => a.id === form.amc_id);
                  if (!sel) return null;
                  return (
                    <div className="mt-2 flex flex-wrap gap-2 items-center">
                      {sel.po_number && <span className="inline-flex items-center gap-1 text-xs bg-purple-50 dark:bg-purple-900/20 text-purple-600 dark:text-purple-400 px-2.5 py-1 rounded-full font-medium">PO: {sel.po_number}</span>}
                      <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${sel.status === "Active" ? "bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600" : sel.status === "Expiring Soon" ? "bg-amber-50 dark:bg-amber-900/20 text-amber-600" : "bg-gray-100 dark:bg-gray-700 text-gray-500"}`}>{sel.status}</span>
                      {sel.end_date && <span className="text-xs text-gray-400">Expires: {sel.end_date.slice(0, 10)}</span>}
                    </div>
                  );
                })()}
              </div>
              <Textarea label="Description" value={form.description} onChange={f("description")} className="col-span-2" />
            </div>
            <div className="flex gap-3 pt-2">
              <Button type="submit" className="flex-1" disabled={submitting}>{submitting ? "Raising…" : "Schedule Visit"}</Button>
              <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
            </div>
          </form>
        </Modal>

        {/* Close Job Verification Modal */}
        <Modal isOpen={closeModal} onClose={() => { if (!closing) { setCloseModal(false); setClosingJob(null); setVerifyImages([]); } }} title="Close Job — Verification Photos" size="lg">
          <div className="space-y-5">
            <div className="flex items-start gap-3 bg-amber-50 dark:bg-amber-900/20 rounded-xl px-4 py-3">
              <Camera size={18} className="text-amber-500 flex-shrink-0 mt-0.5" />
              <div>
                <p className="text-sm font-semibold text-amber-700 dark:text-amber-300">Upload completion photos before closing</p>
                <p className="text-xs text-amber-600 dark:text-amber-400 mt-0.5">You can close without photos if needed.</p>
              </div>
            </div>

            {closingJob && (
              <div className="flex items-center gap-3 bg-gray-50 dark:bg-gray-700/50 rounded-xl px-4 py-3">
                <div className="w-9 h-9 rounded-xl bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center flex-shrink-0">
                  <Briefcase size={16} className="text-blue-600" />
                </div>
                <div>
                  <p className="font-mono text-xs text-blue-500">{closingJob.id}</p>
                  <p className="text-sm font-semibold text-gray-800 dark:text-white">{closingJob.title}</p>
                </div>
              </div>
            )}

            <div>
              <div onClick={() => fileRef.current?.click()} className="border-2 border-dashed border-gray-200 dark:border-gray-600 rounded-xl p-6 text-center cursor-pointer hover:border-blue-400 dark:hover:border-blue-500 transition group">
                <Upload size={28} className="mx-auto text-gray-300 dark:text-gray-500 mb-2 group-hover:text-blue-400 transition" />
                <p className="text-sm font-medium text-gray-500 dark:text-gray-400">Click to add photos</p>
                <p className="text-xs text-gray-400 mt-1">JPEG, PNG, WebP — max 10 MB each</p>
                <input ref={fileRef} type="file" accept="image/jpeg,image/png,image/webp" multiple className="hidden" onChange={handleVerifyImageSelect} />
              </div>

              {verifyImages.length > 0 && (
                <div className="grid grid-cols-3 gap-3 mt-4">
                  {verifyImages.map((img, idx) => (
                    <div key={idx} className="relative group">
                      <div className="aspect-square rounded-xl overflow-hidden bg-gray-100 dark:bg-gray-700">
                        <img src={img.preview} alt="" className="w-full h-full object-cover" />
                      </div>
                      {img.uploading && <div className="absolute inset-0 rounded-xl bg-black/40 flex items-center justify-center"><Loader2 size={20} className="animate-spin text-white" /></div>}
                      {img.uploaded_url && <div className="absolute inset-0 rounded-xl bg-emerald-500/20 flex items-center justify-center"><CheckCircle size={20} className="text-emerald-500" /></div>}
                      {img.error && <div className="absolute inset-0 rounded-xl bg-red-500/20 flex items-center justify-center"><p className="text-xs text-red-500 font-bold px-1 text-center">{img.error}</p></div>}
                      {!img.uploading && !img.uploaded_url && (
                        <button type="button" onClick={() => removeVerifyImage(idx)} className="absolute -top-1.5 -right-1.5 w-5 h-5 bg-red-500 text-white rounded-full flex items-center justify-center text-xs shadow opacity-0 group-hover:opacity-100 transition">
                          <X size={10} />
                        </button>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="flex gap-3 pt-2">
              <Button variant="secondary" className="flex-1" onClick={() => { setCloseModal(false); setClosingJob(null); setVerifyImages([]); }} disabled={closing}>Cancel</Button>
              <Button className="flex-1 bg-emerald-600 hover:bg-emerald-700" onClick={handleCloseJob} disabled={closing}>
                {closing ? <><Loader2 size={15} className="animate-spin" /> Closing…</> : <><CheckCircle size={15} /> Close Job</>}
              </Button>
            </div>
          </div>
        </Modal>

        {/* Export Excel Modal */}
        <Modal isOpen={exportOpen} onClose={() => setExportOpen(false)} title="Export Visit Schedule" size="sm">
          <div className="space-y-4">
            <p className="text-sm text-gray-500 dark:text-gray-400">Download an Excel report of scheduled visits for the selected month.</p>
            <div className="grid grid-cols-2 gap-3">
              <Select label="Month" value={exportMonth} onChange={e => setExportMonth(Number(e.target.value))}
                options={[
                  { value: 1, label: "January" }, { value: 2, label: "February" }, { value: 3, label: "March" },
                  { value: 4, label: "April" }, { value: 5, label: "May" }, { value: 6, label: "June" },
                  { value: 7, label: "July" }, { value: 8, label: "August" }, { value: 9, label: "September" },
                  { value: 10, label: "October" }, { value: 11, label: "November" }, { value: 12, label: "December" },
                ]} />
              <Select label="Year" value={exportYear} onChange={e => setExportYear(Number(e.target.value))}
                options={[exportYear - 1, exportYear, exportYear + 1].map(y => ({ value: y, label: String(y) }))} />
              <Select label="Technician" value={exportTechId} onChange={e => setExportTechId(e.target.value)} searchable
                options={[{ value: "", label: "All Technicians" }, ...technicians.map(t => ({ value: t.id, label: t.name }))]} />
              <Select label="Status" value={exportStatus} onChange={e => setExportStatus(e.target.value)}
                options={[{ value: "", label: "All Status" }, ...STATUSES.map(s => ({ value: s, label: s }))]} />
              <Select label="Category" value={exportCategory} onChange={e => setExportCategory(e.target.value)} className="col-span-2"
                options={[{ value: "", label: "All Categories" }, ...CATEGORIES.map(c => ({ value: c, label: c }))]} />
            </div>
            <div className="flex gap-3 pt-2">
              <Button className="flex-1" onClick={handleExport} disabled={exporting}>
                {exporting ? <><Loader2 size={15} className="animate-spin" /> Exporting…</> : <><Download size={15} /> Download Excel</>}
              </Button>
              <Button variant="secondary" onClick={() => setExportOpen(false)}>Cancel</Button>
            </div>
          </div>
        </Modal>

        {/* Delete Confirmation Modal */}
        <Modal isOpen={!!deleteJob} onClose={() => !deleting && setDeleteJob(null)} title="Delete Job" size="sm">
          <div className="space-y-4">
            <div className="flex items-start gap-3 bg-red-50 dark:bg-red-900/20 rounded-xl px-4 py-3">
              <AlertTriangle size={18} className="text-red-500 flex-shrink-0 mt-0.5" />
              <div>
                <p className="text-sm font-semibold text-red-700 dark:text-red-300">This action cannot be undone</p>
                <p className="text-xs text-red-600 dark:text-red-400 mt-0.5">The job will be permanently deleted.</p>
              </div>
            </div>
            {deleteJob && (
              <div className="flex items-center gap-3 bg-gray-50 dark:bg-gray-700/50 rounded-xl px-4 py-3">
                <div className="w-9 h-9 rounded-xl bg-red-100 dark:bg-red-900/30 flex items-center justify-center flex-shrink-0">
                  <Trash2 size={16} className="text-red-500" />
                </div>
                <div className="min-w-0">
                  <p className="font-mono text-xs text-blue-500">{deleteJob.id}</p>
                  <p className="text-sm font-semibold text-gray-800 dark:text-white truncate">{deleteJob.title}</p>
                </div>
              </div>
            )}
            <div className="flex gap-3 pt-1">
              <Button variant="secondary" className="flex-1" onClick={() => setDeleteJob(null)} disabled={deleting}>Cancel</Button>
              <Button
                className="flex-1 bg-red-600 hover:bg-red-700 text-white border-red-600"
                onClick={confirmDelete}
                disabled={deleting}
              >
                {deleting ? <><Loader2 size={15} className="animate-spin" /> Deleting…</> : <><Trash2 size={15} /> Delete Job</>}
              </Button>
            </div>
          </div>
        </Modal>

        {toast && <Toast {...toast} onClose={() => {}} />}
      </div>
    </PageTransition>
  );
}
