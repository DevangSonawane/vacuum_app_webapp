import { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import {
  Plus, ClipboardList, CheckCircle, XCircle, X,
  Upload, Loader2, Image as ImageIcon, FileText,
  Calendar, User, Briefcase, Eye, ExternalLink,
  Hash, MapPin, Tag, MessageSquare, Mail, Package,
  Paperclip, FileCheck, AlertCircle
} from "lucide-react";
import axios from "axios";
import { useApp } from "../context/AppContext";
import {
  PageTransition, Card, Badge, Button, Modal, Input,
  Select, Textarea, SectionHeader, EmptyState, useToast, Toast
} from "../components/ui";

const API_BASE_URL = "https://vaccumapi.onrender.com/api";

const EMPTY_FORM = {
  job_id:          "",
  title:           "",
  findings:        "",
  recommendations: "",
  technician_id:   "",
  po_number:       "",
  location:        "",
  serial_no:       "",
  comments:        "",
  client_id:       "",
  client_name:     "",
  client_email:    "",
};

export default function Reports() {
  const { currentUser } = useApp();
  const navigate = useNavigate();
  const { toast, showToast } = useToast();

  const [reports, setReports]         = useState([]);
  const [jobs, setJobs]               = useState([]);
  const [technicians, setTechnicians] = useState([]);
  const [clients, setClients]         = useState([]);
  const [loading, setLoading]         = useState(true);
  const [statusFilter, setStatusFilter] = useState("All");

  // Submit modal
  const [modalOpen, setModalOpen]   = useState(false);
  const [form, setForm]             = useState(EMPTY_FORM);
  const [submitting, setSubmitting] = useState(false);

  // Photo attachments (existing flow — POST /reports/:id/images)
  const [previewImages, setPreviewImages] = useState([]);
  const imgRef = useRef();

  // Technical report files (new flow — upload first, then embed in body)
  const [techFiles, setTechFiles]         = useState([]); // { file, name, uploading, uploaded, url, error }
  const [uploadingTech, setUploadingTech] = useState(false);
  const techRef = useRef();

  // Detail panel
  const [detailReport, setDetailReport]   = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [approving, setApproving]         = useState(false);

  useEffect(() => {
    fetchReports();
    fetchJobs();
    fetchTechnicians();
    fetchClients();
  }, []);

  useEffect(() => { fetchReports(); }, [statusFilter]);

  // ── When a job is selected, auto-fill client info ──────────
  useEffect(() => {
    if (form.job_id) {
      const job = jobs.find(j => j.id === form.job_id);
      if (job) {
        setForm(p => ({
          ...p,
          client_name:  p.client_name  || job.client_name  || "",
          client_email: p.client_email || job.client_email || "",
          client_id:    p.client_id    || String(job.client_id || ""),
        }));
      }
    }
  }, [form.job_id, jobs]);

  // ── Fetch ─────────────────────────────────────────────────
  const fetchReports = async () => {
    setLoading(true);
    try {
      const token  = localStorage.getItem("token");
      const params = { limit: 100 };
      if (statusFilter !== "All") params.status = statusFilter;
      const res = await axios.get(`${API_BASE_URL}/reports`, {
        headers: { Authorization: `Bearer ${token}` }, params,
      });
      if (res.data.success) setReports(res.data.data || []);
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to fetch reports", "error");
    } finally {
      setLoading(false);
    }
  };

  const fetchJobs = async () => {
    try {
      const token = localStorage.getItem("token");
      const res   = await axios.get(`${API_BASE_URL}/jobs`, {
        headers: { Authorization: `Bearer ${token}` },
        params: { limit: 200 },
      });
      if (res.data.success) setJobs(res.data.data || []);
    } catch {}
  };

  const fetchTechnicians = async () => {
    try {
      const token = localStorage.getItem("token");
      const res   = await axios.get(`${API_BASE_URL}/technicians`, {
        headers: { Authorization: `Bearer ${token}` },
        params: { limit: 100 },
      });
      if (res.data.success) setTechnicians(res.data.data || []);
    } catch {}
  };

  const fetchClients = async () => {
    try {
      const token = localStorage.getItem("token");
      const res   = await axios.get(`${API_BASE_URL}/clients`, {
        headers: { Authorization: `Bearer ${token}` },
        params: { limit: 100 },
      });
      if (res.data.success) setClients(res.data.data || []);
    } catch {}
  };

  // ── Open detail ────────────────────────────────────────────
  const openDetail = async (report) => {
    setDetailReport({ ...report, images: [], technical_reports: [] });
    setDetailLoading(true);
    try {
      const token = localStorage.getItem("token");
      const res   = await axios.get(`${API_BASE_URL}/reports/${report.id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.data.success) setDetailReport(res.data.data);
    } catch {
      showToast("Could not load full report details.", "error");
    } finally {
      setDetailLoading(false);
    }
  };

  // ── Photo upload helpers ───────────────────────────────────
  const handleImageSelect = (e) => {
    const files = Array.from(e.target.files);
    setPreviewImages(p => [
      ...p,
      ...files.map(file => ({ file, preview: URL.createObjectURL(file), uploading: false, uploaded_url: null, error: null })),
    ]);
    e.target.value = "";
  };

  const removeImage = (idx) => setPreviewImages(p => p.filter((_, i) => i !== idx));

  const uploadOneImage = async (imgObj, reportId) => {
    const token = localStorage.getItem("token");
    const fd = new FormData();
    fd.append("images", imgObj.file);
    const res = await axios.post(
      `${API_BASE_URL}/upload?entity_type=report&entity_id=${reportId}`,
      fd, { headers: { Authorization: `Bearer ${token}`, "Content-Type": "multipart/form-data" } }
    );
    const up = res.data.data?.[0];
    if (!up) throw new Error("Empty upload response");
    return up;
  };

  // ── Technical report upload (STEP 1 — before submit) ──────
  const handleTechFileSelect = async (e) => {
    const files = Array.from(e.target.files);
    if (!files.length) return;
    e.target.value = "";

    const newEntries = files.map(file => ({
      file, name: file.name, uploading: true, uploaded: false, url: null, mime_type: file.type, file_size_bytes: file.size, error: null,
    }));

    setTechFiles(p => [...p, ...newEntries]);
    setUploadingTech(true);

    const token = localStorage.getItem("token");
    const fd = new FormData();
    files.forEach(f => fd.append("files", f));

    try {
      const res = await axios.post(
        `${API_BASE_URL}/upload/technical-reports`,
        fd,
        { headers: { Authorization: `Bearer ${token}`, "Content-Type": "multipart/form-data" } }
      );
      const uploaded = res.data.data || [];

      setTechFiles(prev => {
        const startIdx = prev.length - files.length;
        return prev.map((entry, i) => {
          if (i < startIdx) return entry;
          const up = uploaded[i - startIdx];
          if (up) return { ...entry, uploading: false, uploaded: true, url: up.file_url, file_name: up.file_name, file_url: up.file_url, mime_type: up.mime_type, file_size_bytes: up.file_size_bytes };
          return { ...entry, uploading: false, error: "Failed" };
        });
      });
    } catch {
      setTechFiles(prev => prev.map((e, i) => i >= prev.length - files.length ? { ...e, uploading: false, error: "Upload failed" } : e));
      showToast("Failed to upload technical reports", "error");
    } finally {
      setUploadingTech(false);
    }
  };

  const removeTechFile = (idx) => setTechFiles(p => p.filter((_, i) => i !== idx));

  // ── Submit report (STEP 2) ─────────────────────────────────
  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.job_id)        return showToast("Please select a linked job.", "error");
    if (!form.technician_id) return showToast("Please select the technician.", "error");
    if (uploadingTech)       return showToast("Please wait for technical reports to finish uploading.", "error");

    const failedUploads = techFiles.filter(f => f.error);
    if (failedUploads.length) return showToast("Some technical report files failed to upload. Remove them and retry.", "error");

    setSubmitting(true);
    const token = localStorage.getItem("token");

    try {
      // Build technical_reports array from already-uploaded files
      const technical_reports = techFiles
        .filter(f => f.uploaded && f.file_url)
        .map(f => ({
          file_name:       f.file_name || f.name,
          file_url:        f.file_url,
          mime_type:       f.mime_type || "application/pdf",
          file_size_bytes: f.file_size_bytes || null,
        }));

      const payload = {
        job_id:          form.job_id,
        title:           form.title.trim(),
        technician_id:   parseInt(form.technician_id),
        findings:        form.findings        || undefined,
        recommendations: form.recommendations || undefined,
        comments:        form.comments        || undefined,
        po_number:       form.po_number       || undefined,
        location:        form.location        || undefined,
        serial_no:       form.serial_no       || undefined,
        client_id:       form.client_id       ? parseInt(form.client_id)   : undefined,
        client_name:     form.client_name     || undefined,
        client_email:    form.client_email    || undefined,
        technical_reports,
      };

      const res = await axios.post(`${API_BASE_URL}/reports`, payload, {
        headers: { Authorization: `Bearer ${token}` },
      });

      const reportId = res.data.data?.id;

      // Upload and link photos (still done post-create via /images)
      if (previewImages.length > 0 && reportId) {
        setPreviewImages(p => p.map(im => ({ ...im, uploading: true })));
        for (let idx = 0; idx < previewImages.length; idx++) {
          try {
            const uploaded = await uploadOneImage(previewImages[idx], reportId);
            await axios.post(
              `${API_BASE_URL}/reports/${reportId}/images`,
              { file_name: uploaded.original_name, file_url: uploaded.file_url, mime_type: uploaded.mime_type || "image/jpeg", file_size_bytes: uploaded.file_size_bytes },
              { headers: { Authorization: `Bearer ${token}` } }
            );
            setPreviewImages(p => p.map((im, i) => i === idx ? { ...im, uploading: false, uploaded_url: uploaded.file_url } : im));
          } catch {
            setPreviewImages(p => p.map((im, i) => i === idx ? { ...im, uploading: false, error: "Failed" } : im));
          }
        }
      }

      showToast(`Report submitted!${form.client_email ? ` Email sent to ${form.client_email}.` : ""}`);
      setModalOpen(false);
      resetModal();
      fetchReports();
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to submit report", "error");
    } finally {
      setSubmitting(false);
    }
  };

  const resetModal = () => {
    setForm(EMPTY_FORM);
    setPreviewImages([]);
    setTechFiles([]);
  };

  // ── Approve / Reject ───────────────────────────────────────
  const updateStatus = async (reportId, status) => {
    setApproving(true);
    const token = localStorage.getItem("token");
    try {
      await axios.patch(`${API_BASE_URL}/reports/${reportId}/status`, { status }, {
        headers: { Authorization: `Bearer ${token}` },
      });
      showToast(status === "Approved" ? "Report approved!" : "Report rejected", status === "Approved" ? "success" : "error");
      fetchReports();
      if (detailReport?.id === reportId) setDetailReport(p => ({ ...p, status }));
    } catch (err) {
      showToast(err.response?.data?.message || "Action failed", "error");
    } finally {
      setApproving(false);
    }
  };

  const canApprove     = currentUser?.role === "admin";
  const STATUS_TABS    = ["All", "Pending", "Approved", "Rejected"];

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-7xl mx-auto">
        <SectionHeader
          title="Inspection & Service Reports"
          subtitle={`${reports.length} reports`}
          action={<Button onClick={() => { resetModal(); setModalOpen(true); }}><Plus size={16} /> New Report</Button>}
        />

        {/* Status filter tabs */}
        <div className="flex gap-2 mb-5 flex-wrap">
          {STATUS_TABS.map(s => (
            <button key={s} onClick={() => setStatusFilter(s)}
              className={`px-4 py-1.5 rounded-xl text-xs font-semibold transition
                ${statusFilter === s ? "bg-blue-600 text-white" : "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"}`}
            >
              {s}
              {s !== "All" && <span className="ml-1 bg-white/20 px-1 rounded">{reports.filter(r => r.status === s).length}</span>}
            </button>
          ))}
        </div>

        {/* List + Detail */}
        <div className={`flex gap-5 ${detailReport ? "items-start" : ""}`}>

          {/* Reports list */}
          <div className={detailReport ? "flex-1 min-w-0" : "w-full"}>
            {loading ? (
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                {[...Array(4)].map((_, i) => (
                  <div key={i} className="bg-white dark:bg-gray-800 rounded-2xl p-5 border border-gray-100 dark:border-gray-700 animate-pulse">
                    <div className="flex justify-between mb-3">
                      <div className="space-y-2"><div className="h-3 w-16 bg-gray-200 dark:bg-gray-700 rounded" /><div className="h-4 w-40 bg-gray-200 dark:bg-gray-700 rounded" /></div>
                      <div className="h-5 w-16 bg-gray-100 dark:bg-gray-800 rounded-full" />
                    </div>
                    <div className="h-16 bg-gray-100 dark:bg-gray-800 rounded-xl" />
                  </div>
                ))}
              </div>
            ) : reports.length === 0 ? (
              <EmptyState icon={ClipboardList} title="No reports found" description="Submit a service report after completing a job." />
            ) : (
              <div className={`grid gap-4 ${detailReport ? "grid-cols-1" : "grid-cols-1 lg:grid-cols-2"}`}>
                {reports.map((r, i) => (
                  <motion.div key={r.id} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.04 }}>
                    <Card
                      hover
                      className={`p-5 cursor-pointer ${detailReport?.id === r.id ? "ring-2 ring-blue-500 ring-offset-2" : ""}`}
                      onClick={() => openDetail(r)}
                    >
                      <div className="flex items-start justify-between mb-3">
                        <div>
                          <p className="font-mono text-xs text-blue-500 dark:text-blue-400">{r.id}</p>
                          <p className="font-bold text-gray-900 dark:text-white text-sm mt-0.5">{r.title}</p>
                          <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                            {r.client_name || r.job_title || r.job_id || "—"}
                          </p>
                        </div>
                        <Badge label={r.status} />
                      </div>

                      {/* Tags row */}
                      <div className="flex flex-wrap gap-2 mb-3">
                        {r.po_number && (
                          <span className="inline-flex items-center gap-1 text-xs bg-purple-50 dark:bg-purple-900/20 text-purple-600 dark:text-purple-400 px-2 py-0.5 rounded-full">
                            <Package size={10} /> {r.po_number}
                          </span>
                        )}
                        {r.location && (
                          <span className="inline-flex items-center gap-1 text-xs bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400 px-2 py-0.5 rounded-full">
                            <MapPin size={10} /> {r.location}
                          </span>
                        )}
                        {r.serial_no && (
                          <span className="inline-flex items-center gap-1 text-xs bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 px-2 py-0.5 rounded-full">
                            <Hash size={10} /> {r.serial_no}
                          </span>
                        )}
                      </div>

                      {r.findings && (
                        <div className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-3 mb-3">
                          <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 mb-1">Findings</p>
                          <p className="text-sm text-gray-700 dark:text-gray-300 line-clamp-2">{r.findings}</p>
                        </div>
                      )}

                      <div className="flex items-center gap-3 mb-3 flex-wrap">
                        {r.image_count > 0 && (
                          <span className="flex items-center gap-1 text-xs text-gray-400">
                            <ImageIcon size={11} /> {r.image_count} photo{r.image_count !== 1 ? "s" : ""}
                          </span>
                        )}
                        {r.technical_report_count > 0 && (
                          <span className="flex items-center gap-1 text-xs text-blue-500 dark:text-blue-400">
                            <FileText size={11} /> {r.technical_report_count} doc{r.technical_report_count !== 1 ? "s" : ""}
                          </span>
                        )}
                        {r.client_email && (
                          <span className="flex items-center gap-1 text-xs text-gray-400">
                            <Mail size={11} /> {r.client_email}
                          </span>
                        )}
                      </div>

                      <div className="flex items-center justify-between text-xs text-gray-400">
                        <span>{r.technician_name || "—"} · {r.report_date ? r.report_date.slice(0, 10) : "—"}</span>
                        {canApprove && r.status === "Pending" && (
                          <div className="flex gap-2" onClick={e => e.stopPropagation()}>
                            <button onClick={() => updateStatus(r.id, "Approved")} disabled={approving}
                              className="flex items-center gap-1 text-emerald-600 hover:text-emerald-700 font-semibold disabled:opacity-50">
                              <CheckCircle size={14} /> Approve
                            </button>
                            <button onClick={() => updateStatus(r.id, "Rejected")} disabled={approving}
                              className="flex items-center gap-1 text-red-500 hover:text-red-600 font-semibold disabled:opacity-50">
                              <XCircle size={14} /> Reject
                            </button>
                          </div>
                        )}
                      </div>
                    </Card>
                  </motion.div>
                ))}
              </div>
            )}
          </div>

          {/* ── Detail Panel ───────────────────────────────── */}
          <AnimatePresence>
            {detailReport && (
              <motion.div
                key="report-detail"
                initial={{ opacity: 0, x: 40 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 40 }}
                transition={{ type: "spring", damping: 28, stiffness: 280 }}
                className="w-full lg:w-96 flex-shrink-0 bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 shadow-lg overflow-hidden sticky top-4"
              >
                <div className="p-5 border-b border-gray-100 dark:border-gray-700 bg-gradient-to-br from-slate-700 to-slate-900">
                  <div className="flex items-start justify-between">
                    <div>
                      <p className="font-mono text-xs text-blue-400 font-bold">{detailReport.id}</p>
                      <p className="font-bold text-white mt-0.5 leading-snug">{detailReport.title}</p>
                      {detailReport.client_name && <p className="text-slate-300 text-xs mt-0.5">{detailReport.client_name}</p>}
                    </div>
                    <div className="flex items-center gap-1">
                      <button onClick={() => navigate(`/reports/${detailReport.id}`)}
                        className="p-1.5 text-white/60 hover:text-white hover:bg-white/10 rounded-lg transition">
                        <ExternalLink size={15} />
                      </button>
                      <button onClick={() => setDetailReport(null)}
                        className="p-1.5 text-white/60 hover:text-white hover:bg-white/10 rounded-lg transition">
                        <X size={16} />
                      </button>
                    </div>
                  </div>
                  <div className="flex items-center gap-2 mt-3 flex-wrap">
                    <Badge label={detailReport.status} />
                    {detailReport.po_number && (
                      <span className="text-xs bg-white/10 text-white/80 px-2 py-0.5 rounded-full flex items-center gap-1">
                        <Package size={10} /> {detailReport.po_number}
                      </span>
                    )}
                  </div>
                </div>

                <div className="p-5 space-y-5 max-h-[calc(100vh-220px)] overflow-y-auto">
                  {detailLoading && (
                    <div className="flex items-center gap-2 text-sm text-gray-400">
                      <Loader2 size={14} className="animate-spin" /> Loading details…
                    </div>
                  )}

                  {/* Meta grid */}
                  <div className="grid grid-cols-2 gap-2">
                    {[
                      { label: "Job",        value: detailReport.job_id    || "—" },
                      { label: "Date",       value: detailReport.report_date ? detailReport.report_date.slice(0, 10) : "—" },
                      { label: "Technician", value: detailReport.technician_name || "—" },
                      { label: "Client",     value: detailReport.client_name || "—" },
                    ].map(item => (
                      <div key={item.label} className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-3">
                        <p className="text-[10px] text-gray-400 uppercase tracking-wide mb-0.5">{item.label}</p>
                        <p className="text-sm font-semibold text-gray-800 dark:text-white truncate">{item.value}</p>
                      </div>
                    ))}
                  </div>

                  {/* Extra fields */}
                  {(detailReport.location || detailReport.serial_no || detailReport.client_email) && (
                    <div className="space-y-2">
                      {detailReport.location && (
                        <div className="flex items-center gap-2 text-xs text-gray-600 dark:text-gray-300">
                          <MapPin size={12} className="text-emerald-500 flex-shrink-0" />
                          <span>{detailReport.location}</span>
                        </div>
                      )}
                      {detailReport.serial_no && (
                        <div className="flex items-center gap-2 text-xs text-gray-600 dark:text-gray-300">
                          <Hash size={12} className="text-gray-400 flex-shrink-0" />
                          <span>S/N: {detailReport.serial_no}</span>
                        </div>
                      )}
                      {detailReport.client_email && (
                        <div className="flex items-center gap-2 text-xs text-gray-600 dark:text-gray-300">
                          <Mail size={12} className="text-blue-400 flex-shrink-0" />
                          <span className="break-all">{detailReport.client_email}</span>
                        </div>
                      )}
                    </div>
                  )}

                  {detailReport.findings && (
                    <div>
                      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Findings</p>
                      <div className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-4">
                        <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed whitespace-pre-wrap">{detailReport.findings}</p>
                      </div>
                    </div>
                  )}

                  {detailReport.recommendations && (
                    <div>
                      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Recommendations</p>
                      <div className="bg-blue-50 dark:bg-blue-900/20 rounded-xl p-4">
                        <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed whitespace-pre-wrap">{detailReport.recommendations}</p>
                      </div>
                    </div>
                  )}

                  {detailReport.comments && (
                    <div>
                      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Comments</p>
                      <div className="bg-amber-50 dark:bg-amber-900/10 rounded-xl p-4">
                        <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed whitespace-pre-wrap">{detailReport.comments}</p>
                      </div>
                    </div>
                  )}

                  {/* Photos */}
                  {detailReport.images?.length > 0 && (
                    <div>
                      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">
                        Attached Photos ({detailReport.images.length})
                      </p>
                      <div className="grid grid-cols-3 gap-2">
                        {detailReport.images.map(img => (
                          <a key={img.id} href={img.file_url} target="_blank" rel="noopener noreferrer">
                            <div className="aspect-square rounded-xl overflow-hidden bg-gray-100 dark:bg-gray-700 hover:opacity-80 transition">
                              <img src={img.file_url} alt={img.file_name} className="w-full h-full object-cover" />
                            </div>
                          </a>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Technical reports */}
                  {detailReport.technical_reports?.length > 0 && (
                    <div>
                      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">
                        Technical Reports ({detailReport.technical_reports.length})
                      </p>
                      <div className="space-y-2">
                        {detailReport.technical_reports.map(doc => (
                          <a key={doc.id} href={doc.file_url} target="_blank" rel="noopener noreferrer"
                            className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-700/50 rounded-xl hover:bg-blue-50 dark:hover:bg-blue-900/20 transition group">
                            <div className="w-8 h-8 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center flex-shrink-0">
                              <FileText size={15} className="text-blue-600 dark:text-blue-400" />
                            </div>
                            <div className="flex-1 min-w-0">
                              <p className="text-xs font-semibold text-gray-800 dark:text-white truncate">{doc.file_name}</p>
                              {doc.file_size_bytes && <p className="text-[10px] text-gray-400">{(doc.file_size_bytes / 1024).toFixed(0)} KB</p>}
                            </div>
                            <ExternalLink size={12} className="text-gray-400 group-hover:text-blue-500 flex-shrink-0" />
                          </a>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Approve / Reject */}
                  {canApprove && detailReport.status === "Pending" && (
                    <div className="flex gap-2 pt-1">
                      <Button className="flex-1 bg-emerald-600 hover:bg-emerald-700" onClick={() => updateStatus(detailReport.id, "Approved")} disabled={approving}>
                        {approving ? <Loader2 size={14} className="animate-spin mr-1" /> : <CheckCircle size={14} className="mr-1" />} Approve
                      </Button>
                      <Button variant="danger" className="flex-1" onClick={() => updateStatus(detailReport.id, "Rejected")} disabled={approving}>
                        <XCircle size={14} className="mr-1" /> Reject
                      </Button>
                    </div>
                  )}

                  {detailReport.status === "Approved" && (
                    <div className="flex items-center gap-2 text-sm text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/20 rounded-xl px-4 py-3">
                      <CheckCircle size={16} /> Approved report.
                    </div>
                  )}
                  {detailReport.status === "Rejected" && (
                    <div className="flex items-center gap-2 text-sm text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 rounded-xl px-4 py-3">
                      <XCircle size={16} /> Report was rejected.
                    </div>
                  )}
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* ── Submit New Report Modal ─────────────────────── */}
        <Modal
          isOpen={modalOpen}
          onClose={() => { if (!submitting) { setModalOpen(false); resetModal(); } }}
          title="Submit Service Report"
          size="lg"
        >
          <form onSubmit={handleSubmit} className="space-y-5">

            {/* Row 1: Job + Technician */}
            <div className="grid grid-cols-2 gap-3">
              <Select
                label="Linked Job"
                value={form.job_id}
                onChange={e => setForm(p => ({ ...p, job_id: e.target.value }))}
                required
                options={[
                  { value: "", label: "Select job..." },
                  ...jobs.map(j => ({ value: j.id, label: `${j.id} — ${j.title}` })),
                ]}
              />
              <Select
                label="Technician"
                value={form.technician_id}
                onChange={e => setForm(p => ({ ...p, technician_id: e.target.value }))}
                required
                options={[
                  { value: "", label: "Select technician..." },
                  ...technicians.map(t => ({ value: t.id, label: t.name })),
                ]}
              />
            </div>

            {/* Report Title */}
            <Input
              label="Report Title"
              value={form.title}
              onChange={e => setForm(p => ({ ...p, title: e.target.value }))}
              required
              placeholder="Quarterly Vacuum Pump Inspection"
            />

            {/* Row 2: PO Number + Serial No */}
            <div className="grid grid-cols-2 gap-3">
              <Input
                label="PO Number"
                value={form.po_number}
                onChange={e => setForm(p => ({ ...p, po_number: e.target.value }))}
                placeholder="PO-2025-001"
              />
              <Input
                label="Serial No."
                value={form.serial_no}
                onChange={e => setForm(p => ({ ...p, serial_no: e.target.value }))}
                placeholder="VCP-2023-7842"
              />
            </div>

            {/* Location */}
            <Input
              label="Location"
              value={form.location}
              onChange={e => setForm(p => ({ ...p, location: e.target.value }))}
              placeholder="Building B, Floor 2 — Plant Room"
            />

            {/* Divider */}
            <div className="border-t border-gray-100 dark:border-gray-700 pt-1">
              <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Client Info</p>
              <div className="grid grid-cols-2 gap-3">
                <Select
                  label="Client"
                  value={form.client_id}
                  onChange={e => {
                    const c = clients.find(cl => String(cl.id) === e.target.value);
                    setForm(p => ({
                      ...p,
                      client_id:    e.target.value,
                      client_name:  c?.name  || p.client_name,
                      client_email: c?.email || p.client_email,
                    }));
                  }}
                  options={[
                    { value: "", label: "Auto from job..." },
                    ...clients.map(c => ({ value: c.id, label: c.name })),
                  ]}
                />
                <Input
                  label="Client Email"
                  type="email"
                  value={form.client_email}
                  onChange={e => setForm(p => ({ ...p, client_email: e.target.value }))}
                  placeholder="client@company.com"
                />
              </div>
              {form.client_email && (
                <p className="mt-1.5 text-xs text-blue-500 dark:text-blue-400 flex items-center gap-1">
                  <Mail size={11} /> Report email will be sent to this address on submission.
                </p>
              )}
            </div>

            {/* Findings + Recommendations + Comments */}
            <Textarea label="Findings" value={form.findings} onChange={e => setForm(p => ({ ...p, findings: e.target.value }))} rows={3} placeholder="Describe what was found during inspection…" />
            <Textarea label="Recommendations" value={form.recommendations} onChange={e => setForm(p => ({ ...p, recommendations: e.target.value }))} rows={2} placeholder="Suggested follow-up actions…" />
            <Textarea label="Comments" value={form.comments} onChange={e => setForm(p => ({ ...p, comments: e.target.value }))} rows={2} placeholder="Additional notes or customer requests…" />

            {/* Technical Report Upload */}
            <div>
              <p className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2 flex items-center gap-2">
                <FileText size={14} className="text-blue-500" />
                Technical Reports
                <span className="text-xs text-gray-400 font-normal">(PDF, Word, images)</span>
              </p>
              <div
                onClick={() => techRef.current?.click()}
                className="border-2 border-dashed border-gray-200 dark:border-gray-600 rounded-xl p-4 text-center cursor-pointer hover:border-blue-400 transition group"
              >
                {uploadingTech ? (
                  <div className="flex items-center justify-center gap-2 text-blue-500">
                    <Loader2 size={16} className="animate-spin" />
                    <span className="text-xs">Uploading files…</span>
                  </div>
                ) : (
                  <>
                    <Paperclip size={20} className="mx-auto text-gray-300 dark:text-gray-500 mb-1 group-hover:text-blue-400 transition" />
                    <p className="text-xs text-gray-400">Click to attach technical report files</p>
                  </>
                )}
                <input
                  ref={techRef}
                  type="file"
                  accept=".pdf,.doc,.docx,image/jpeg,image/png,image/webp"
                  multiple
                  className="hidden"
                  onChange={handleTechFileSelect}
                />
              </div>

              {techFiles.length > 0 && (
                <div className="mt-3 space-y-2">
                  {techFiles.map((f, idx) => (
                    <div key={idx} className="flex items-center gap-3 p-2.5 bg-gray-50 dark:bg-gray-700/50 rounded-xl">
                      <div className={`w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0 ${f.uploaded ? "bg-emerald-100 dark:bg-emerald-900/30" : f.error ? "bg-red-100 dark:bg-red-900/30" : "bg-blue-100 dark:bg-blue-900/30"}`}>
                        {f.uploading ? <Loader2 size={13} className="animate-spin text-blue-500" /> :
                         f.uploaded  ? <FileCheck size={13} className="text-emerald-600" /> :
                         f.error     ? <AlertCircle size={13} className="text-red-500" /> :
                                       <FileText size={13} className="text-blue-500" />}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-medium text-gray-700 dark:text-gray-300 truncate">{f.name}</p>
                        <p className="text-[10px] text-gray-400">
                          {f.uploading ? "Uploading…" : f.uploaded ? "Ready" : f.error ? f.error : "Pending"}
                        </p>
                      </div>
                      {!f.uploading && (
                        <button type="button" onClick={() => removeTechFile(idx)}
                          className="w-5 h-5 rounded-full bg-gray-200 dark:bg-gray-600 flex items-center justify-center hover:bg-red-100 hover:text-red-500 transition">
                          <X size={10} />
                        </button>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Photo Upload */}
            <div>
              <p className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2 flex items-center gap-2">
                <ImageIcon size={14} className="text-blue-500" />
                Attach Site Photos
              </p>
              <div onClick={() => imgRef.current?.click()}
                className="border-2 border-dashed border-gray-200 dark:border-gray-600 rounded-xl p-4 text-center cursor-pointer hover:border-blue-400 transition group">
                <Upload size={20} className="mx-auto text-gray-300 dark:text-gray-500 mb-1 group-hover:text-blue-400 transition" />
                <p className="text-xs text-gray-400">Click to upload photos (JPEG, PNG, WebP)</p>
                <input ref={imgRef} type="file" accept="image/jpeg,image/png,image/webp" multiple className="hidden" onChange={handleImageSelect} />
              </div>
              {previewImages.length > 0 && (
                <div className="flex flex-wrap gap-2 mt-3">
                  {previewImages.map((img, idx) => (
                    <div key={idx} className="relative group">
                      <img src={img.preview} alt="" className="w-16 h-16 object-cover rounded-xl border border-gray-200 dark:border-gray-600" />
                      {img.uploading && <div className="absolute inset-0 rounded-xl bg-black/40 flex items-center justify-center"><Loader2 size={14} className="animate-spin text-white" /></div>}
                      {img.uploaded_url && <div className="absolute inset-0 rounded-xl bg-emerald-500/20 flex items-center justify-center"><CheckCircle size={14} className="text-emerald-500" /></div>}
                      {!img.uploading && !img.uploaded_url && (
                        <button type="button" onClick={() => removeImage(idx)}
                          className="absolute -top-1 -right-1 w-4 h-4 bg-red-500 text-white rounded-full flex items-center justify-center shadow opacity-0 group-hover:opacity-100 transition">
                          <X size={8} />
                        </button>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="flex gap-3 pt-2">
              <Button type="submit" className="flex-1" disabled={submitting || uploadingTech}>
                {submitting ? <><Loader2 size={14} className="animate-spin mr-2" />Submitting…</> : "Submit Report"}
              </Button>
              <Button variant="secondary" onClick={() => { setModalOpen(false); resetModal(); }} disabled={submitting}>Cancel</Button>
            </div>
          </form>
        </Modal>

        {toast && <Toast {...toast} onClose={() => {}} />}
      </div>
    </PageTransition>
  );
}