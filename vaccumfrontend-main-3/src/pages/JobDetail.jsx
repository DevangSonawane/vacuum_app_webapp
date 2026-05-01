// ============================================================
// src/pages/JobDetail.jsx
// Full dedicated detail page for a single job
// Route: /jobs/:id
// ============================================================

import { useState, useEffect, useRef } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import {
  ArrowLeft, ArrowRight, Calendar, User, DollarSign,
  Tag, Briefcase, Camera, CheckCircle, Loader2,
  Upload, X, Image as ImageIcon, FileText,
  Clock, MapPin, AlertCircle, Star, Building2,
  ClipboardList, ChevronRight, Pencil
} from "lucide-react";
import axios from "axios";
import { useApp } from "../context/AppContext";
import {
  PageTransition, Badge, Button, useToast, Toast, Card
} from "../components/ui";

const API_BASE_URL = "https://vaccumapi.onrender.com/api";

const STATUSES  = ["Raised", "Assigned", "In Progress", "Closed"];
const STATUS_FLOW = {
  Raised:        "Assigned",
  Assigned:      "In Progress",
  "In Progress": "Closed",
};
const STATUS_COLORS = {
  Raised:        { bar: "bg-purple-500",  light: "bg-purple-50  dark:bg-purple-900/20  border-purple-200 dark:border-purple-800",  text: "text-purple-700 dark:text-purple-300" },
  Assigned:      { bar: "bg-blue-500",    light: "bg-blue-50    dark:bg-blue-900/20    border-blue-200   dark:border-blue-800",    text: "text-blue-700   dark:text-blue-300"   },
  "In Progress": { bar: "bg-amber-500",   light: "bg-amber-50   dark:bg-amber-900/20   border-amber-200  dark:border-amber-800",   text: "text-amber-700  dark:text-amber-300"  },
  Closed:        { bar: "bg-emerald-500", light: "bg-emerald-50 dark:bg-emerald-900/20 border-emerald-200 dark:border-emerald-800", text: "text-emerald-700 dark:text-emerald-300" },
};
const PRIORITY_COLORS = {
  Low:      "text-gray-600   bg-gray-100   dark:bg-gray-700   dark:text-gray-300",
  Medium:   "text-blue-700   bg-blue-100   dark:bg-blue-900/30  dark:text-blue-300",
  High:     "text-orange-700 bg-orange-100 dark:bg-orange-900/30 dark:text-orange-300",
  Critical: "text-red-700    bg-red-100    dark:bg-red-900/30   dark:text-red-300",
};

export default function JobDetail() {
  const { id }      = useParams();
  const navigate    = useNavigate();
  const { currentUser } = useApp();
  const { toast, showToast } = useToast();

  const [job, setJob]         = useState(null);
  const [loading, setLoading] = useState(true);

  // Close verification
  const [closeModal, setCloseModal]     = useState(false);
  const [verifyImages, setVerifyImages] = useState([]);
  const [closing, setClosing]           = useState(false);
  const fileRef = useRef();

  // Advance non-close
  const [advancing, setAdvancing] = useState(false);

  useEffect(() => { fetchJob(); }, [id]);

  const fetchJob = async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem("token");
      const res   = await axios.get(`${API_BASE_URL}/jobs/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.data.success) setJob(res.data.data);
      else showToast("Job not found", "error");
    } catch {
      showToast("Failed to load job", "error");
    } finally {
      setLoading(false);
    }
  };

  // ── Advance status (non-close) ────────────────────────────
  const advanceStatus = async () => {
    const next = STATUS_FLOW[job.status];
    if (!next || job.status === "In Progress") return;
    setAdvancing(true);
    const token = localStorage.getItem("token");
    try {
      await axios.patch(
        `${API_BASE_URL}/jobs/${id}/status`,
        { status: next },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      showToast(`Job moved to ${next}`);
      fetchJob();
    } catch (err) {
      showToast(err.response?.data?.message || "Status update failed", "error");
    } finally {
      setAdvancing(false);
    }
  };

  // ── Verification images ───────────────────────────────────
  const handleImageSelect = (e) => {
    const files = Array.from(e.target.files);
    setVerifyImages(p => [
      ...p,
      ...files.map(file => ({
        file,
        preview:      URL.createObjectURL(file),
        uploading:    false,
        uploaded_url: null,
        error:        null,
      })),
    ]);
    e.target.value = "";
  };

  const removeImage = (idx) => setVerifyImages(p => p.filter((_, i) => i !== idx));

  const uploadOne = async (imgObj, idx) => {
    setVerifyImages(p => p.map((im, i) => i === idx ? { ...im, uploading: true, error: null } : im));
    const token = localStorage.getItem("token");
    try {
      const fd = new FormData();
      fd.append("images", imgObj.file);
      const uploadRes = await axios.post(
        `${API_BASE_URL}/upload?entity_type=job&entity_id=${id}`,
        fd,
        { headers: { Authorization: `Bearer ${token}`, "Content-Type": "multipart/form-data" } }
      );
      const up = uploadRes.data.data?.[0];
      if (!up) throw new Error("Empty upload");

      await axios.post(
        `${API_BASE_URL}/jobs/${id}/images`,
        { file_name: up.original_name, file_url: up.file_url, mime_type: up.mime_type || "image/jpeg", file_size_bytes: up.file_size_bytes },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setVerifyImages(p => p.map((im, i) => i === idx ? { ...im, uploading: false, uploaded_url: up.file_url } : im));
    } catch {
      setVerifyImages(p => p.map((im, i) => i === idx ? { ...im, uploading: false, error: "Failed" } : im));
    }
  };

  const handleCloseJob = async () => {
    setClosing(true);
    const pending = verifyImages.map((im, idx) => ({ im, idx })).filter(x => !x.im.uploaded_url && !x.im.uploading);
    await Promise.all(pending.map(({ im, idx }) => uploadOne(im, idx)));

    if (verifyImages.some(im => im.error)) {
      showToast("Some images failed. Please retry.", "error");
      setClosing(false);
      return;
    }
    const token = localStorage.getItem("token");
    try {
      await axios.patch(
        `${API_BASE_URL}/jobs/${id}/status`,
        { status: "Closed" },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      showToast("Job closed successfully!");
      setCloseModal(false);
      setVerifyImages([]);
      fetchJob();
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to close job", "error");
    } finally {
      setClosing(false);
    }
  };

  const canAct = !["labour"].includes(currentUser?.role);

  if (loading) {
    return (
      <PageTransition>
        <div className="p-4 md:p-8 max-w-5xl mx-auto">
          <div className="animate-pulse space-y-6">
            <div className="h-8 w-48 bg-gray-200 dark:bg-gray-700 rounded-xl" />
            <div className="h-32 bg-gray-100 dark:bg-gray-800 rounded-2xl" />
            <div className="grid grid-cols-3 gap-4">
              {[...Array(3)].map((_, i) => <div key={i} className="h-24 bg-gray-100 dark:bg-gray-800 rounded-2xl" />)}
            </div>
          </div>
        </div>
      </PageTransition>
    );
  }

  if (!job) {
    return (
      <PageTransition>
        <div className="p-8 text-center text-gray-400">
          <Briefcase size={40} className="mx-auto mb-3 opacity-30" />
          <p className="font-medium">Job not found</p>
          <Button className="mt-4" onClick={() => navigate("/jobs")}>Back to Jobs</Button>
        </div>
      </PageTransition>
    );
  }

  const sc        = STATUS_COLORS[job.status] || STATUS_COLORS.Raised;
  const stepIdx   = STATUSES.indexOf(job.status);
  const nextStatus = STATUS_FLOW[job.status];

  return (
    <PageTransition>
      <div className="p-4 md:p-8 max-w-5xl mx-auto space-y-6">

        {/* Back + header */}
        <div className="flex items-start gap-4">
          <button
            onClick={() => navigate("/jobs")}
            className="mt-1 p-2 rounded-xl text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-800 transition flex-shrink-0"
          >
            <ArrowLeft size={20} />
          </button>
          <div className="flex-1 min-w-0">
            <div className="flex flex-wrap items-center gap-2 mb-1">
              <span className="font-mono text-sm text-blue-600 dark:text-blue-400 font-bold">{job.id}</span>
              <Badge label={job.status} />
              <Badge label={job.priority} />
              <span className={`text-xs px-2 py-0.5 rounded-full font-semibold ${PRIORITY_COLORS[job.priority] || ""}`}>{job.category}</span>
            </div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white leading-tight">{job.title}</h1>
          </div>
        </div>

        {/* Pipeline bar */}
        <Card className="p-5">
          <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Pipeline</p>
          <div className="flex items-center gap-0">
            {STATUSES.map((s, i) => {
              const done    = i <= stepIdx;
              const current = i === stepIdx;
              return (
                <div key={s} className="flex items-center gap-0 flex-1 min-w-0">
                  <div className={`flex-1 py-2 px-3 text-center text-[11px] font-bold truncate rounded-lg transition-all
                    ${done ? (current ? `${sc.bar} text-white shadow-sm` : "bg-gray-300 dark:bg-gray-600 text-white") : "bg-gray-100 dark:bg-gray-700 text-gray-400"}`}>
                    {s}
                  </div>
                  {i < STATUSES.length - 1 && (
                    <ArrowRight size={14} className={`flex-shrink-0 mx-1 ${i < stepIdx ? "text-gray-400" : "text-gray-200 dark:text-gray-600"}`} />
                  )}
                </div>
              );
            })}
          </div>
        </Card>

        {/* Main grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

          {/* Left — main info */}
          <div className="lg:col-span-2 space-y-6">

            {/* Key info */}
            <Card className="p-5">
              <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-4">Job Details</p>
              <div className="grid grid-cols-2 gap-4">
                {[
                  { icon: Building2, label: "Client",         value: job.client_name     || "—" },
                  { icon: User,      label: "Technician",     value: job.technician_name || "Not Assigned" },
                  { icon: DollarSign,label: "Amount",         value: `₹${Number(job.amount || 0).toLocaleString()}` },
                  { icon: Tag,       label: "Category",       value: job.category        || "—" },
                  { icon: Calendar,  label: "Raised",         value: job.raised_date     ? job.raised_date.slice(0, 10)     : "—" },
                  { icon: Calendar,  label: "Scheduled",      value: job.scheduled_date  ? job.scheduled_date.slice(0, 10)  : "—" },
                  { icon: Calendar,  label: "Closed",         value: job.closed_date     ? job.closed_date.slice(0, 10)     : "—" },
                  { icon: AlertCircle,label: "Priority",      value: job.priority        || "—" },
                ].map(item => (
                  <div key={item.label} className="flex items-start gap-3">
                    <div className="w-8 h-8 rounded-lg bg-gray-50 dark:bg-gray-700 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <item.icon size={14} className="text-gray-500 dark:text-gray-400" />
                    </div>
                    <div>
                      <p className="text-[10px] text-gray-400 uppercase tracking-wide">{item.label}</p>
                      <p className="text-sm font-semibold text-gray-800 dark:text-white">{item.value}</p>
                    </div>
                  </div>
                ))}
              </div>
            </Card>

            {/* Description */}
            {job.description && (
              <Card className="p-5">
                <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Description</p>
                <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed whitespace-pre-wrap">{job.description}</p>
              </Card>
            )}

            {/* Verification Photos */}
            <Card className="p-5">
              <div className="flex items-center justify-between mb-4">
                <p className="text-xs font-bold text-gray-400 uppercase tracking-widest">
                  Verification Photos {job.images?.length > 0 && `(${job.images.length})`}
                </p>
              </div>
              {job.images?.length > 0 ? (
                <div className="grid grid-cols-3 sm:grid-cols-4 gap-3">
                  {job.images.map(img => (
                    <a key={img.id} href={img.file_url} target="_blank" rel="noopener noreferrer" className="group">
                      <div className="aspect-square rounded-xl overflow-hidden bg-gray-100 dark:bg-gray-700 hover:opacity-80 transition ring-0 group-hover:ring-2 group-hover:ring-blue-500">
                        <img src={img.file_url} alt={img.file_name} className="w-full h-full object-cover" />
                      </div>
                      <p className="text-[10px] text-gray-400 truncate mt-1">{img.file_name}</p>
                    </a>
                  ))}
                </div>
              ) : (
                <div className="flex flex-col items-center justify-center py-10 text-gray-300 dark:text-gray-600">
                  <ImageIcon size={32} className="mb-2 opacity-40" />
                  <p className="text-sm">No photos attached yet</p>
                </div>
              )}
            </Card>

            {/* Linked Reports */}
            <Card className="p-5">
              <div className="flex items-center justify-between mb-4">
                <p className="text-xs font-bold text-gray-400 uppercase tracking-widest">
                  Linked Reports {job.reports?.length > 0 && `(${job.reports.length})`}
                </p>
                <button
                  onClick={() => navigate(`/reports`)}
                  className="text-xs text-blue-500 hover:text-blue-600 font-semibold flex items-center gap-1"
                >
                  View all <ChevronRight size={12} />
                </button>
              </div>
              {job.reports?.length > 0 ? (
                <div className="space-y-2">
                  {job.reports.map(r => (
                    <div
                      key={r.id}
                      onClick={() => navigate(`/reports/${r.id}`)}
                      className="flex items-center justify-between bg-gray-50 dark:bg-gray-700/50 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-xl px-4 py-3 cursor-pointer transition"
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-lg bg-blue-50 dark:bg-blue-900/30 flex items-center justify-center">
                          <ClipboardList size={14} className="text-blue-500" />
                        </div>
                        <div>
                          <p className="font-mono text-xs text-blue-500">{r.id}</p>
                          <p className="text-sm font-medium text-gray-800 dark:text-white">{r.title}</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        <Badge label={r.status} />
                        <ChevronRight size={14} className="text-gray-400" />
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="flex flex-col items-center justify-center py-10 text-gray-300 dark:text-gray-600">
                  <FileText size={32} className="mb-2 opacity-40" />
                  <p className="text-sm">No reports yet</p>
                </div>
              )}
            </Card>
          </div>

          {/* Right — actions + status */}
          <div className="space-y-5">

            {/* Status card */}
            <Card className={`p-5 border ${sc.light}`}>
              <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Current Status</p>
              <div className={`inline-flex items-center gap-2 px-4 py-2 rounded-xl font-bold text-sm ${sc.light} ${sc.text}`}>
                <span className={`w-2 h-2 rounded-full ${sc.bar}`} />
                {job.status}
              </div>
            </Card>

            {/* Action card */}
            {canAct && job.status !== "Closed" && (
              <Card className="p-5">
                <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Actions</p>
                {job.status === "In Progress" ? (
                  <Button
                    className="w-full bg-emerald-600 hover:bg-emerald-700"
                    onClick={() => { setVerifyImages([]); setCloseModal(true); }}
                  >
                    <Camera size={16} className="mr-2" /> Close with Verification
                  </Button>
                ) : nextStatus ? (
                  <Button className="w-full" onClick={advanceStatus} disabled={advancing}>
                    {advancing
                      ? <><Loader2 size={15} className="animate-spin mr-2" />Updating…</>
                      : <>Advance to {nextStatus} <ArrowRight size={15} className="ml-2" /></>
                    }
                  </Button>
                ) : null}
              </Card>
            )}

            {job.status === "Closed" && (
              <Card className="p-5 border border-emerald-200 dark:border-emerald-800 bg-emerald-50 dark:bg-emerald-900/20">
                <div className="flex items-center gap-2 text-emerald-700 dark:text-emerald-300">
                  <CheckCircle size={18} />
                  <p className="font-semibold text-sm">Job Completed</p>
                </div>
                {job.closed_date && (
                  <p className="text-xs text-emerald-600 dark:text-emerald-400 mt-1 ml-7">
                    Closed on {job.closed_date.slice(0, 10)}
                  </p>
                )}
              </Card>
            )}

            {/* Quick stats */}
            <Card className="p-5">
              <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Quick Stats</p>
              <div className="space-y-3">
                {[
                  { label: "Photos",  value: job.images?.length  ?? 0 },
                  { label: "Reports", value: job.reports?.length ?? 0 },
                ].map(s => (
                  <div key={s.label} className="flex items-center justify-between">
                    <span className="text-sm text-gray-500 dark:text-gray-400">{s.label}</span>
                    <span className="text-sm font-bold text-gray-900 dark:text-white">{s.value}</span>
                  </div>
                ))}
              </div>
            </Card>
          </div>
        </div>
      </div>

      {/* ── Close Verification Modal ───────────────────────── */}
      {closeModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="absolute inset-0 bg-black/50 backdrop-blur-sm"
            onClick={() => { if (!closing) setCloseModal(false); }}
          />
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            className="relative w-full max-w-lg bg-white dark:bg-gray-900 rounded-3xl shadow-2xl overflow-hidden max-h-[90vh] overflow-y-auto"
          >
            <div className="p-6 border-b border-gray-100 dark:border-gray-800 flex items-center justify-between">
              <div>
                <h2 className="text-lg font-bold text-gray-900 dark:text-white">Close Job — Verification</h2>
                <p className="text-sm text-gray-500 dark:text-gray-400">Upload completion photos before closing</p>
              </div>
              <button onClick={() => { if (!closing) setCloseModal(false); }} className="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-white">
                <X size={20} />
              </button>
            </div>

            <div className="p-6 space-y-5">
              {/* Amber banner */}
              <div className="flex items-start gap-3 bg-amber-50 dark:bg-amber-900/20 rounded-xl px-4 py-3">
                <Camera size={17} className="text-amber-500 flex-shrink-0 mt-0.5" />
                <p className="text-sm text-amber-700 dark:text-amber-300">
                  Photos are optional but recommended for job verification. You can close without photos.
                </p>
              </div>

              {/* Job pill */}
              <div className="flex items-center gap-3 bg-gray-50 dark:bg-gray-800 rounded-xl px-4 py-3">
                <Briefcase size={16} className="text-blue-500 flex-shrink-0" />
                <div>
                  <p className="font-mono text-xs text-blue-500">{job.id}</p>
                  <p className="text-sm font-semibold text-gray-800 dark:text-white">{job.title}</p>
                </div>
              </div>

              {/* Upload zone */}
              <div
                onClick={() => fileRef.current?.click()}
                className="border-2 border-dashed border-gray-200 dark:border-gray-700 rounded-xl p-6 text-center cursor-pointer hover:border-blue-400 dark:hover:border-blue-500 transition group"
              >
                <Upload size={28} className="mx-auto text-gray-300 dark:text-gray-500 mb-2 group-hover:text-blue-400 transition" />
                <p className="text-sm font-medium text-gray-500 dark:text-gray-400">Click to add photos</p>
                <p className="text-xs text-gray-400 mt-1">JPEG, PNG, WebP — max 10 MB each</p>
                <input
                  ref={fileRef}
                  type="file"
                  accept="image/jpeg,image/png,image/webp"
                  multiple
                  className="hidden"
                  onChange={handleImageSelect}
                />
              </div>

              {/* Image grid */}
              {verifyImages.length > 0 && (
                <div className="grid grid-cols-3 gap-3">
                  {verifyImages.map((img, idx) => (
                    <div key={idx} className="relative group">
                      <div className="aspect-square rounded-xl overflow-hidden bg-gray-100 dark:bg-gray-700">
                        <img src={img.preview} alt={img.file.name} className="w-full h-full object-cover" />
                      </div>
                      {img.uploading && (
                        <div className="absolute inset-0 rounded-xl bg-black/40 flex items-center justify-center">
                          <Loader2 size={20} className="animate-spin text-white" />
                        </div>
                      )}
                      {img.uploaded_url && (
                        <div className="absolute inset-0 rounded-xl bg-emerald-500/20 flex items-center justify-center">
                          <CheckCircle size={20} className="text-emerald-500" />
                        </div>
                      )}
                      {img.error && (
                        <div className="absolute inset-0 rounded-xl bg-red-500/20 flex items-center justify-center">
                          <p className="text-xs text-red-500 font-bold px-1 text-center">{img.error}</p>
                        </div>
                      )}
                      {!img.uploading && !img.uploaded_url && (
                        <button
                          type="button"
                          onClick={() => removeImage(idx)}
                          className="absolute -top-1.5 -right-1.5 w-5 h-5 bg-red-500 text-white rounded-full flex items-center justify-center text-xs shadow opacity-0 group-hover:opacity-100 transition"
                        >
                          <X size={10} />
                        </button>
                      )}
                      <p className="text-[10px] text-gray-400 truncate mt-1 px-0.5">{img.file.name}</p>
                    </div>
                  ))}
                </div>
              )}

              {/* Buttons */}
              <div className="flex gap-3 pt-2">
                <Button
                  variant="secondary"
                  className="flex-1"
                  onClick={() => { setCloseModal(false); setVerifyImages([]); }}
                  disabled={closing}
                >
                  Cancel
                </Button>
                <Button
                  className="flex-1 bg-emerald-600 hover:bg-emerald-700"
                  onClick={handleCloseJob}
                  disabled={closing}
                >
                  {closing
                    ? <><Loader2 size={15} className="animate-spin mr-2" />Closing…</>
                    : <><CheckCircle size={15} className="mr-2" />Close Job</>
                  }
                </Button>
              </div>
            </div>
          </motion.div>
        </div>
      )}

      {toast && <Toast message={toast.message} type={toast.type} />}
    </PageTransition>
  );
}