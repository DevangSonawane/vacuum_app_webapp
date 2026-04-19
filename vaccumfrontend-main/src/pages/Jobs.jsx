import { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import {
  Plus, Briefcase, ArrowRight, Calendar, User, X,
  CheckCircle, Loader2, Upload, Image as ImageIcon,
  Trash2, Eye, Camera, ExternalLink
} from "lucide-react";
import axios from "axios";
import { useApp } from "../context/AppContext";
import {
  PageTransition, Card, Badge, Button, Modal, Input,
  Select, Textarea, SectionHeader, EmptyState, useToast, Toast
} from "../components/ui";

const API_BASE_URL = 'https://vaccumapi-production.up.railway.app/api';

const STATUSES   = ["Raised", "Assigned", "In Progress", "Closed"];
const PRIORITIES = ["Low", "Medium", "High", "Critical"];
const CATEGORIES = ["Maintenance", "Repair", "Installation", "Inspection"];

const STATUS_FLOW  = { Raised: "Assigned", Assigned: "In Progress", "In Progress": "Closed" };
const STATUS_COLOR = {
  Raised:        "border-l-purple-500",
  Assigned:      "border-l-blue-500",
  "In Progress": "border-l-amber-500",
  Closed:        "border-l-emerald-500",
};
const STATUS_BG = {
  Raised:        "bg-purple-50  dark:bg-purple-900/20  text-purple-700  dark:text-purple-300",
  Assigned:      "bg-blue-50    dark:bg-blue-900/20    text-blue-700    dark:text-blue-300",
  "In Progress": "bg-amber-50   dark:bg-amber-900/20   text-amber-700   dark:text-amber-300",
  Closed:        "bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-300",
};

const EMPTY_FORM = {
  title: "", client_id: "", technician_id: "",
  priority: "Medium", category: "Maintenance",
  description: "", scheduled_date: "", amount: "",
};

export default function Jobs() {
  const { currentUser } = useApp();
  const navigate = useNavigate();
  const { toast, showToast } = useToast();

  const [jobs, setJobs]               = useState([]);
  const [clients, setClients]         = useState([]);
  const [technicians, setTechnicians] = useState([]);
  const [loading, setLoading]         = useState(true);
  const [filter, setFilter]           = useState("All");

  // Create modal
  const [modalOpen, setModalOpen]     = useState(false);
  const [form, setForm]               = useState(EMPTY_FORM);
  const [submitting, setSubmitting]   = useState(false);

  // Detail panel
  const [detailJob, setDetailJob]         = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);

  // ── Close verification modal (In Progress → Closed) ──────
  const [closeModal, setCloseModal]       = useState(false);
  const [closingJob, setClosingJob]       = useState(null);
  const [verifyImages, setVerifyImages]   = useState([]);   // { file, preview, uploading, uploaded_url, error }
  const [closing, setClosing]             = useState(false);
  const fileRef = useRef();

  useEffect(() => {
    fetchJobs();
    fetchClients();
    fetchTechnicians();
  }, []);

  useEffect(() => { fetchJobs(); }, [filter]);

  // ── Fetch ─────────────────────────────────────────────────
  const fetchJobs = async () => {
    setLoading(true);
    try {
      const token  = localStorage.getItem("token");
      const params = { limit: 100 };
      if (filter !== "All") params.status = filter;
      const res = await axios.get(`${API_BASE_URL}/jobs`, {
        headers: { Authorization: `Bearer ${token}` }, params,
      });
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
      const res   = await axios.get(`${API_BASE_URL}/clients`, {
        headers: { Authorization: `Bearer ${token}` }, params: { limit: 100 },
      });
      if (res.data.success) setClients(res.data.data || []);
    } catch {}
  };

  const fetchTechnicians = async () => {
    try {
      const token = localStorage.getItem("token");
      const res   = await axios.get(`${API_BASE_URL}/technicians`, {
        headers: { Authorization: `Bearer ${token}` },
        params: { limit: 100, status: "Active" },
      });
      if (res.data.success) setTechnicians(res.data.data || []);
    } catch {}
  };

  // ── Open job detail panel — GET /jobs/:id ─────────────────
  const openDetail = async (job) => {
    setDetailJob({ ...job, images: [], reports: [] });
    setDetailLoading(true);
    try {
      const token = localStorage.getItem("token");
      const res   = await axios.get(`${API_BASE_URL}/jobs/${job.id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.data.success) setDetailJob(res.data.data);
    } catch {
      showToast("Could not load full job details.", "error");
    } finally {
      setDetailLoading(false);
    }
  };

  // ── Create job ────────────────────────────────────────────
  const f = (field) => (e) => setForm(p => ({ ...p, [field]: e.target.value }));

  const handleCreate = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    const token = localStorage.getItem("token");
    try {
      const payload = {
        title:     form.title.trim(),
        client_id: parseInt(form.client_id),
        priority:  form.priority,
        category:  form.category,
      };
      if (form.technician_id)  payload.technician_id  = parseInt(form.technician_id);
      if (form.description)    payload.description    = form.description.trim();
      if (form.scheduled_date) payload.scheduled_date = form.scheduled_date;
      if (form.amount)         payload.amount         = parseFloat(form.amount);

      await axios.post(`${API_BASE_URL}/jobs`, payload, {
        headers: { Authorization: `Bearer ${token}` },
      });
      showToast("Work order raised!");
      setModalOpen(false);
      setForm(EMPTY_FORM);
      fetchJobs();
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to raise job", "error");
    } finally {
      setSubmitting(false);
    }
  };

  // ── Advance status (Raised / Assigned) ───────────────────
  // For "In Progress → Closed" we open the verification modal instead
  const advanceStatus = (job) => {
    const next = STATUS_FLOW[job.status];
    if (!next) return;

    if (job.status === "In Progress") {
      // Show image-upload verification before closing
      setClosingJob(job);
      setVerifyImages([]);
      setCloseModal(true);
      return;
    }
    doAdvance(job, next);
  };

  const doAdvance = async (job, next) => {
    const token = localStorage.getItem("token");
    try {
      await axios.patch(
        `${API_BASE_URL}/jobs/${job.id}/status`,
        { status: next },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      showToast(`Job moved to ${next}`);
      fetchJobs();
      if (detailJob?.id === job.id) openDetail({ ...job, status: next });
    } catch (err) {
      showToast(err.response?.data?.message || "Status update failed", "error");
    }
  };

  // ── Close verification: select images ────────────────────
  const handleVerifyImageSelect = (e) => {
    const files = Array.from(e.target.files);
    const newImages = files.map(file => ({
      file,
      preview: URL.createObjectURL(file),
      uploading: false,
      uploaded_url: null,
      uploaded_id: null,
      error: null,
    }));
    setVerifyImages(p => [...p, ...newImages]);
    e.target.value = "";
  };

  const removeVerifyImage = (idx) => {
    setVerifyImages(p => p.filter((_, i) => i !== idx));
  };

  // ── Upload one image to /api/upload then link to job ──────
  const uploadVerifyImage = async (imgObj, idx) => {
    setVerifyImages(p => p.map((im, i) => i === idx ? { ...im, uploading: true, error: null } : im));
    const token = localStorage.getItem("token");
    try {
      const formData = new FormData();
      formData.append("images", imgObj.file);

      const uploadRes = await axios.post(
        `${API_BASE_URL}/upload?entity_type=job&entity_id=${closingJob.id}`,
        formData,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "multipart/form-data",
          },
        }
      );

      const uploaded = uploadRes.data.data?.[0];
      if (!uploaded) throw new Error("Upload response empty");

      // Link image to job
      await axios.post(
        `${API_BASE_URL}/jobs/${closingJob.id}/images`,
        {
          file_name:       uploaded.original_name,
          file_url:        uploaded.file_url,
          mime_type:       uploaded.mime_type || "image/jpeg",
          file_size_bytes: uploaded.file_size_bytes,
        },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      setVerifyImages(p =>
        p.map((im, i) =>
          i === idx
            ? { ...im, uploading: false, uploaded_url: uploaded.file_url, uploaded_id: uploaded.id }
            : im
        )
      );
    } catch (err) {
      setVerifyImages(p =>
        p.map((im, i) =>
          i === idx ? { ...im, uploading: false, error: "Upload failed" } : im
        )
      );
    }
  };

  // ── Upload all pending then close the job ─────────────────
  const handleCloseJob = async () => {
    if (!closingJob) return;
    setClosing(true);

    // Upload any images not yet uploaded
    const pending = verifyImages.map((im, idx) => ({ im, idx })).filter(x => !x.im.uploaded_url && !x.im.uploading);
    await Promise.all(pending.map(({ im, idx }) => uploadVerifyImage(im, idx)));

    // Check for errors
    const hasError = verifyImages.some(im => im.error);
    if (hasError) {
      showToast("Some images failed to upload. Please retry.", "error");
      setClosing(false);
      return;
    }

    // Advance to Closed
    try {
      const token = localStorage.getItem("token");
      await axios.patch(
        `${API_BASE_URL}/jobs/${closingJob.id}/status`,
        { status: "Closed" },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      showToast(`Job ${closingJob.id} closed successfully!`);
      setCloseModal(false);
      setClosingJob(null);
      setVerifyImages([]);
      fetchJobs();
      if (detailJob?.id === closingJob.id) openDetail({ ...closingJob, status: "Closed" });
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to close job", "error");
    } finally {
      setClosing(false);
    }
  };

  const canRaise    = !["technician", "labour"].includes(currentUser?.role);
  const activeCount = jobs.filter(j => j.status !== "Closed").length;
  const filtered    = filter === "All" ? jobs : jobs.filter(j => j.status === filter);

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-7xl mx-auto">
        <SectionHeader
          title="Work Orders"
          subtitle={`${activeCount} active orders`}
          action={canRaise && (
            <Button onClick={() => setModalOpen(true)}><Plus size={16} /> Raise Job</Button>
          )}
        />

        {/* Filter tabs */}
        <div className="flex gap-2 mb-5 overflow-x-auto pb-1">
          {["All", ...STATUSES].map(s => (
            <button key={s} onClick={() => setFilter(s)}
              className={`px-4 py-1.5 rounded-xl text-xs font-semibold whitespace-nowrap transition
                ${filter === s ? "bg-blue-600 text-white" : "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"}`}
            >
              {s}
              {s !== "All" && (
                <span className="ml-1 bg-white/20 px-1 rounded">
                  {jobs.filter(j => j.status === s).length}
                </span>
              )}
            </button>
          ))}
        </div>

        {/* List + Detail */}
        <div className={`flex gap-5 ${detailJob ? "items-start" : ""}`}>

          {/* Job list / kanban */}
          <div className={detailJob ? "flex-1 min-w-0" : "w-full"}>
            {loading ? (
              <div className="space-y-3">
                {[...Array(5)].map((_, i) => (
                  <div key={i} className="bg-white dark:bg-gray-800 rounded-xl p-4 border border-gray-100 dark:border-gray-700 animate-pulse">
                    <div className="flex items-start justify-between mb-3">
                      <div className="space-y-2">
                        <div className="h-3 w-16 bg-gray-200 dark:bg-gray-700 rounded" />
                        <div className="h-4 w-48 bg-gray-200 dark:bg-gray-700 rounded" />
                      </div>
                      <div className="h-5 w-14 bg-gray-100 dark:bg-gray-800 rounded-full" />
                    </div>
                    <div className="h-3 w-28 bg-gray-100 dark:bg-gray-800 rounded" />
                  </div>
                ))}
              </div>
            ) : filter === "All" ? (
              /* Kanban */
              <div className={`grid gap-4 ${detailJob ? "grid-cols-2" : "grid-cols-1 sm:grid-cols-2 lg:grid-cols-4"}`}>
                {STATUSES.map(status => (
                  <div key={status}>
                    <div className="flex items-center gap-2 mb-3">
                      <Badge label={status} />
                      <span className="text-xs text-gray-400 font-medium">
                        {jobs.filter(j => j.status === status).length}
                      </span>
                    </div>
                    <div className="space-y-3">
                      {jobs.filter(j => j.status === status).map(job => (
                        <JobCard
                          key={job.id} job={job}
                          isSelected={detailJob?.id === job.id}
                          onDetail={() => openDetail(job)}
                          onAdvance={() => advanceStatus(job)}
                          canRaise={canRaise}
                        />
                      ))}
                      {jobs.filter(j => j.status === status).length === 0 && (
                        <div className="text-center py-8 text-gray-300 dark:text-gray-600 text-sm border-2 border-dashed border-gray-200 dark:border-gray-700 rounded-xl">
                          Empty
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            ) : filtered.length === 0 ? (
              <EmptyState icon={Briefcase} title="No jobs found" description="No jobs in this status." />
            ) : (
              <div className="space-y-3">
                {filtered.map(job => (
                  <JobCard
                    key={job.id} job={job} horizontal
                    isSelected={detailJob?.id === job.id}
                    onDetail={() => openDetail(job)}
                    onAdvance={() => advanceStatus(job)}
                    canRaise={canRaise}
                  />
                ))}
              </div>
            )}
          </div>

          {/* Detail Panel */}
          <AnimatePresence>
            {detailJob && (
              <motion.div
                key="job-detail"
                initial={{ opacity: 0, x: 40 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 40 }}
                transition={{ type: "spring", damping: 28, stiffness: 280 }}
                className="w-full lg:w-96 flex-shrink-0 bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 shadow-lg overflow-hidden sticky top-4"
              >
                {/* Header */}
                <div className={`p-5 border-b border-gray-100 dark:border-gray-700 ${STATUS_BG[detailJob.status] || ""}`}>
                  <div className="flex items-start justify-between">
                    <div>
                      <p className="font-mono text-xs text-blue-600 dark:text-blue-400 font-bold">{detailJob.id}</p>
                      <p className="font-bold text-gray-900 dark:text-white mt-0.5 leading-snug">{detailJob.title}</p>
                    </div>
                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => navigate(`/jobs/${detailJob.id}`)}
                        className="p-1.5 text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 hover:bg-white/50 dark:hover:bg-gray-700/50 rounded-lg transition"
                        title="Open full detail page"
                      >
                        <ExternalLink size={15} />
                      </button>
                      <button
                        onClick={() => setDetailJob(null)}
                        className="p-1.5 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 hover:bg-white/50 dark:hover:bg-gray-700/50 rounded-lg transition"
                      >
                        <X size={16} />
                      </button>
                    </div>
                  </div>
                  <div className="flex items-center gap-2 mt-3 flex-wrap">
                    <Badge label={detailJob.status} />
                    <Badge label={detailJob.priority} />
                    <span className="text-xs text-gray-500 dark:text-gray-400">{detailJob.category}</span>
                  </div>
                </div>

                <div className="p-5 space-y-5 max-h-[calc(100vh-220px)] overflow-y-auto">

                  {detailLoading && (
                    <div className="flex items-center gap-2 text-sm text-gray-400">
                      <Loader2 size={14} className="animate-spin" /> Loading details…
                    </div>
                  )}

                  {/* Key info grid */}
                  <div className="grid grid-cols-2 gap-2">
                    {[
                      { label: "Client",    value: detailJob.client_name     || "—" },
                      { label: "Technician",value: detailJob.technician_name || "Not Assigned" },
                      { label: "Amount",    value: `₹${Number(detailJob.amount || 0).toLocaleString()}` },
                      { label: "Raised",    value: detailJob.raised_date     ? detailJob.raised_date.slice(0, 10)     : "—" },
                      { label: "Scheduled", value: detailJob.scheduled_date  ? detailJob.scheduled_date.slice(0, 10)  : "—" },
                      { label: "Closed",    value: detailJob.closed_date     ? detailJob.closed_date.slice(0, 10)     : "—" },
                    ].map(item => (
                      <div key={item.label} className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-3">
                        <p className="text-[10px] text-gray-400 uppercase tracking-wide mb-0.5">{item.label}</p>
                        <p className="text-sm font-semibold text-gray-800 dark:text-white truncate">{item.value}</p>
                      </div>
                    ))}
                  </div>

                  {/* Description */}
                  {detailJob.description && (
                    <div>
                      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Description</p>
                      <p className="text-sm text-gray-600 dark:text-gray-300 leading-relaxed">{detailJob.description}</p>
                    </div>
                  )}

                  {/* Pipeline */}
                  <div>
                    <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Pipeline</p>
                    <div className="flex items-center gap-1">
                      {STATUSES.map((s, i) => (
                        <div key={s} className="flex items-center gap-1 flex-1 min-w-0">
                          <div className={`flex-1 text-center py-1.5 rounded-lg text-[10px] font-bold truncate
                            ${STATUSES.indexOf(detailJob.status) >= i
                              ? "bg-blue-600 text-white"
                              : "bg-gray-100 dark:bg-gray-700 text-gray-400"}`}
                          >
                            {s}
                          </div>
                          {i < STATUSES.length - 1 && (
                            <ArrowRight size={10} className="text-gray-300 flex-shrink-0" />
                          )}
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Verification images (attached photos) */}
                  {detailJob.images?.length > 0 && (
                    <div>
                      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">
                        Verification Photos ({detailJob.images.length})
                      </p>
                      <div className="grid grid-cols-3 gap-2">
                        {detailJob.images.map(img => (
                          <a key={img.id} href={img.file_url} target="_blank" rel="noopener noreferrer">
                            <div className="aspect-square rounded-lg bg-gray-100 dark:bg-gray-700 overflow-hidden hover:opacity-80 transition">
                              <img
                                src={img.file_url}
                                alt={img.file_name}
                                className="w-full h-full object-cover"
                              />
                            </div>
                          </a>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Linked Reports */}
                  {detailJob.reports?.length > 0 && (
                    <div>
                      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">
                        Reports ({detailJob.reports.length})
                      </p>
                      <div className="space-y-2">
                        {detailJob.reports.map(r => (
                          <div
                            key={r.id}
                            className="flex items-center justify-between bg-gray-50 dark:bg-gray-700/50 rounded-xl px-3 py-2.5"
                          >
                            <div>
                              <p className="text-xs font-mono text-blue-500">{r.id}</p>
                              <p className="text-sm font-medium text-gray-800 dark:text-white">{r.title}</p>
                            </div>
                            <Badge label={r.status} />
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Advance button */}
                  {STATUS_FLOW[detailJob.status] && canRaise && (
                    <Button
                      className="w-full"
                      onClick={() => advanceStatus(detailJob)}
                    >
                      {detailJob.status === "In Progress" ? (
                        <><Camera size={15} className="mr-2" /> Close Job with Verification</>
                      ) : (
                        <>Advance to {STATUS_FLOW[detailJob.status]} <ArrowRight size={15} className="ml-2" /></>
                      )}
                    </Button>
                  )}

                  {detailJob.status === "Closed" && (
                    <div className="flex items-center gap-2 text-sm text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/20 rounded-xl px-4 py-3">
                      <CheckCircle size={16} /> This job is closed.
                    </div>
                  )}
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* ── Raise Job Modal ────────────────────────────────── */}
        <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title="Raise New Work Order" size="lg">
          <form onSubmit={handleCreate} className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <Input label="Job Title" value={form.title} onChange={f("title")} required className="col-span-2" />
              <Select
                label="Client" value={form.client_id} onChange={f("client_id")} required
                options={[{ value: "", label: "Select client..." }, ...clients.map(c => ({ value: c.id, label: c.name }))]}
              />
              <Select
                label="Assign Technician" value={form.technician_id} onChange={f("technician_id")}
                options={[{ value: "", label: "Not assigned yet" }, ...technicians.map(t => ({ value: t.id, label: t.name }))]}
              />
              <Select label="Priority" value={form.priority} onChange={f("priority")} options={PRIORITIES} />
              <Select label="Category" value={form.category} onChange={f("category")} options={CATEGORIES} />
              <Input label="Scheduled Date" type="date" value={form.scheduled_date} onChange={f("scheduled_date")} />
              <Input label="Amount (₹)"     type="number" value={form.amount}        onChange={f("amount")} />
              <Textarea
                label="Description"
                value={form.description}
                onChange={f("description")}
                className="col-span-2"
              />
            </div>
            <div className="flex gap-3 pt-2">
              <Button type="submit" className="flex-1" disabled={submitting}>
                {submitting ? "Raising…" : "Raise Work Order"}
              </Button>
              <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
            </div>
          </form>
        </Modal>

        {/* ── Close Job Verification Modal ───────────────────── */}
        <Modal
          isOpen={closeModal}
          onClose={() => { if (!closing) { setCloseModal(false); setClosingJob(null); setVerifyImages([]); } }}
          title="Close Job — Add Verification Photos"
          size="lg"
        >
          <div className="space-y-5">
            {/* Info banner */}
            <div className="flex items-start gap-3 bg-amber-50 dark:bg-amber-900/20 rounded-xl px-4 py-3">
              <Camera size={18} className="text-amber-500 flex-shrink-0 mt-0.5" />
              <div>
                <p className="text-sm font-semibold text-amber-700 dark:text-amber-300">
                  Upload completion photos before closing
                </p>
                <p className="text-xs text-amber-600 dark:text-amber-400 mt-0.5">
                  Photos are attached to the job as verification. You can close without photos if needed.
                </p>
              </div>
            </div>

            {/* Job summary */}
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

            {/* Image upload zone */}
            <div>
              <div
                onClick={() => fileRef.current?.click()}
                className="border-2 border-dashed border-gray-200 dark:border-gray-600 rounded-xl p-6 text-center cursor-pointer hover:border-blue-400 dark:hover:border-blue-500 transition group"
              >
                <Upload size={28} className="mx-auto text-gray-300 dark:text-gray-500 mb-2 group-hover:text-blue-400 transition" />
                <p className="text-sm font-medium text-gray-500 dark:text-gray-400">Click to add photos</p>
                <p className="text-xs text-gray-400 dark:text-gray-500 mt-1">JPEG, PNG, WebP — max 10 MB each</p>
                <input
                  ref={fileRef}
                  type="file"
                  accept="image/jpeg,image/png,image/webp"
                  multiple
                  className="hidden"
                  onChange={handleVerifyImageSelect}
                />
              </div>

              {/* Image previews */}
              {verifyImages.length > 0 && (
                <div className="grid grid-cols-3 gap-3 mt-4">
                  {verifyImages.map((img, idx) => (
                    <div key={idx} className="relative group">
                      <div className="aspect-square rounded-xl overflow-hidden bg-gray-100 dark:bg-gray-700">
                        <img
                          src={img.preview}
                          alt={img.file.name}
                          className="w-full h-full object-cover"
                        />
                      </div>

                      {/* Status overlay */}
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

                      {/* Remove button */}
                      {!img.uploading && !img.uploaded_url && (
                        <button
                          type="button"
                          onClick={() => removeVerifyImage(idx)}
                          className="absolute -top-1.5 -right-1.5 w-5 h-5 bg-red-500 text-white rounded-full flex items-center justify-center text-xs shadow opacity-0 group-hover:opacity-100 transition"
                        >
                          <X size={10} />
                        </button>
                      )}

                      {/* File name */}
                      <p className="text-[10px] text-gray-400 truncate mt-1 px-0.5">
                        {img.file.name}
                      </p>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Action buttons */}
            <div className="flex gap-3 pt-2">
              <Button
                variant="secondary"
                className="flex-1"
                onClick={() => { setCloseModal(false); setClosingJob(null); setVerifyImages([]); }}
                disabled={closing}
              >
                Cancel
              </Button>
              <Button
                className="flex-1 bg-emerald-600 hover:bg-emerald-700"
                onClick={handleCloseJob}
                disabled={closing}
              >
                {closing ? (
                  <><Loader2 size={15} className="animate-spin mr-2" />Closing…</>
                ) : (
                  <><CheckCircle size={15} className="mr-2" />Close Job</>
                )}
              </Button>
            </div>
          </div>
        </Modal>

        {toast && <Toast {...toast} onClose={() => {}} />}
      </div>
    </PageTransition>
  );
}

// ── Job Card component ────────────────────────────────────────
function JobCard({ job, onDetail, onAdvance, canRaise, isSelected = false, horizontal = false }) {
  return (
    <motion.div
      whileHover={{ y: -2 }}
      onClick={onDetail}
      className={`bg-white dark:bg-gray-800 rounded-xl shadow-sm border-l-4 border border-gray-100 dark:border-gray-700 p-4 cursor-pointer transition-all hover:shadow-md
        ${STATUS_COLOR[job.status]}
        ${horizontal ? "flex items-center gap-4" : ""}
        ${isSelected ? "ring-2 ring-blue-500 ring-offset-2" : ""}`}
    >
      <div className={horizontal ? "flex-1" : ""}>
        <div className="flex items-start justify-between gap-2 mb-2">
          <div>
            <p className="font-mono text-xs text-blue-500 dark:text-blue-400">{job.id}</p>
            <p className="font-semibold text-gray-800 dark:text-white text-sm mt-0.5">{job.title}</p>
          </div>
          <Badge label={job.priority} />
        </div>
        <div className="space-y-1 text-xs text-gray-500 dark:text-gray-400">
          {job.client_name     && <div className="flex items-center gap-1.5"><User     size={11} />{job.client_name}</div>}
          {job.technician_name && <div className="flex items-center gap-1.5"><User     size={11} className="text-blue-400" />{job.technician_name}</div>}
          {job.scheduled_date  && <div className="flex items-center gap-1.5"><Calendar size={11} />{job.scheduled_date?.slice(0, 10)}</div>}
        </div>
      </div>
      {horizontal && (
        <div className="flex items-center gap-2 flex-shrink-0">
          <Badge label={job.status} />
          <span className="font-bold text-gray-800 dark:text-white text-sm">
            ₹{Number(job.amount || 0).toLocaleString()}
          </span>
        </div>
      )}
    </motion.div>
  );
}