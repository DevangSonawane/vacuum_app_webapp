import { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import {
  Plus, ClipboardList, CheckCircle, XCircle, X,
  Upload, Loader2, Image as ImageIcon, FileText,
  Calendar, User, Briefcase, Eye, ExternalLink
} from "lucide-react";
import axios from "axios";
import { useApp } from "../context/AppContext";
import {
  PageTransition, Card, Badge, Button, Modal, Input,
  Select, Textarea, SectionHeader, EmptyState, useToast, Toast
} from "../components/ui";

const API_BASE_URL = 'https://vaccumapi-production.up.railway.app/api';

const EMPTY_FORM = {
  job_id:          "",
  title:           "",
  findings:        "",
  recommendations: "",
  technician_id:   "",
};

export default function Reports() {
  const { currentUser } = useApp();
  const navigate = useNavigate();
  const { toast, showToast } = useToast();

  const [reports, setReports]         = useState([]);
  const [jobs, setJobs]               = useState([]);
  const [technicians, setTechnicians] = useState([]);
  const [loading, setLoading]         = useState(true);
  const [statusFilter, setStatusFilter] = useState("All");

  // Submit modal
  const [modalOpen, setModalOpen]     = useState(false);
  const [form, setForm]               = useState(EMPTY_FORM);
  const [previewImages, setPreviewImages] = useState([]);  // { file, preview, uploading, uploaded_url, error }
  const [submitting, setSubmitting]   = useState(false);
  const fileRef                       = useRef();

  // Detail panel
  const [detailReport, setDetailReport]       = useState(null);
  const [detailLoading, setDetailLoading]     = useState(false);
  const [approving, setApproving]             = useState(false);

  useEffect(() => {
    fetchReports();
    fetchJobs();
    fetchTechnicians();
  }, []);

  useEffect(() => { fetchReports(); }, [statusFilter]);

  // ── Fetch reports list ────────────────────────────────────
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

  // ── Open detail — GET /reports/:id ───────────────────────
  const openDetail = async (report) => {
    setDetailReport({ ...report, images: [] });
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

  // ── Image upload helpers ──────────────────────────────────
  const handleImageSelect = (e) => {
    const files = Array.from(e.target.files);
    const newImgs = files.map(file => ({
      file,
      preview:      URL.createObjectURL(file),
      uploading:    false,
      uploaded_url: null,
      uploaded_id:  null,
      error:        null,
    }));
    setPreviewImages(p => [...p, ...newImgs]);
    e.target.value = "";
  };

  const removeImage = (idx) => {
    setPreviewImages(p => p.filter((_, i) => i !== idx));
  };

  // Upload one image to /api/upload, returns { file_name, file_url, mime_type }
  const uploadOneImage = async (imgObj, reportId) => {
    const token = localStorage.getItem("token");
    const formData = new FormData();
    formData.append("images", imgObj.file);

    const uploadRes = await axios.post(
      `${API_BASE_URL}/upload?entity_type=report&entity_id=${reportId}`,
      formData,
      { headers: { Authorization: `Bearer ${token}`, "Content-Type": "multipart/form-data" } }
    );
    const uploaded = uploadRes.data.data?.[0];
    if (!uploaded) throw new Error("Empty upload response");
    return uploaded;
  };

  // ── Submit report ─────────────────────────────────────────
  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.job_id)        return showToast("Please select a linked job.", "error");
    if (!form.technician_id) return showToast("Please select the technician.", "error");

    setSubmitting(true);
    const token = localStorage.getItem("token");

    try {
      // 1. Create report
      const res = await axios.post(`${API_BASE_URL}/reports`, {
        job_id:          form.job_id,
        title:           form.title.trim(),
        findings:        form.findings || undefined,
        recommendations: form.recommendations || undefined,
        technician_id:   parseInt(form.technician_id),
      }, { headers: { Authorization: `Bearer ${token}` } });

      const reportId = res.data.data?.id;

      // 2. Upload and link images one by one
      if (previewImages.length > 0 && reportId) {
        setPreviewImages(p => p.map(im => ({ ...im, uploading: true })));

        for (let idx = 0; idx < previewImages.length; idx++) {
          try {
            const uploaded = await uploadOneImage(previewImages[idx], reportId);

            // Link to report
            await axios.post(
              `${API_BASE_URL}/reports/${reportId}/images`,
              {
                file_name:       uploaded.original_name,
                file_url:        uploaded.file_url,
                mime_type:       uploaded.mime_type || "image/jpeg",
                file_size_bytes: uploaded.file_size_bytes,
              },
              { headers: { Authorization: `Bearer ${token}` } }
            );

            setPreviewImages(p =>
              p.map((im, i) =>
                i === idx ? { ...im, uploading: false, uploaded_url: uploaded.file_url } : im
              )
            );
          } catch {
            setPreviewImages(p =>
              p.map((im, i) =>
                i === idx ? { ...im, uploading: false, error: "Failed" } : im
              )
            );
          }
        }
      }

      showToast("Report submitted successfully!");
      setModalOpen(false);
      setForm(EMPTY_FORM);
      setPreviewImages([]);
      fetchReports();
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to submit report", "error");
    } finally {
      setSubmitting(false);
    }
  };

  // ── Approve / Reject ──────────────────────────────────────
  const updateStatus = async (reportId, status) => {
    setApproving(true);
    const token = localStorage.getItem("token");
    try {
      await axios.patch(
        `${API_BASE_URL}/reports/${reportId}/status`,
        { status },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      showToast(
        status === "Approved" ? "Report approved!" : "Report rejected",
        status === "Approved" ? "success" : "error"
      );
      fetchReports();
      // Refresh detail panel if open
      if (detailReport?.id === reportId) {
        setDetailReport(p => ({ ...p, status }));
      }
    } catch (err) {
      showToast(err.response?.data?.message || "Action failed", "error");
    } finally {
      setApproving(false);
    }
  };

  const canApprove = currentUser?.role === "admin";
  const filteredReports = reports;  // server-filtered via statusFilter

  const STATUS_TABS = ["All", "Pending", "Approved", "Rejected"];

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-7xl mx-auto">
        <SectionHeader
          title="Inspection & Service Reports"
          subtitle={`${reports.length} reports`}
          action={<Button onClick={() => setModalOpen(true)}><Plus size={16} /> New Report</Button>}
        />

        {/* Status filter tabs */}
        <div className="flex gap-2 mb-5 flex-wrap">
          {STATUS_TABS.map(s => (
            <button key={s} onClick={() => setStatusFilter(s)}
              className={`px-4 py-1.5 rounded-xl text-xs font-semibold transition
                ${statusFilter === s
                  ? "bg-blue-600 text-white"
                  : "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"}`}
            >
              {s}
              {s !== "All" && (
                <span className="ml-1 bg-white/20 px-1 rounded">
                  {reports.filter(r => r.status === s).length}
                </span>
              )}
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
                      <div className="space-y-2">
                        <div className="h-3 w-16 bg-gray-200 dark:bg-gray-700 rounded" />
                        <div className="h-4 w-40 bg-gray-200 dark:bg-gray-700 rounded" />
                      </div>
                      <div className="h-5 w-16 bg-gray-100 dark:bg-gray-800 rounded-full" />
                    </div>
                    <div className="h-16 bg-gray-100 dark:bg-gray-800 rounded-xl" />
                  </div>
                ))}
              </div>
            ) : filteredReports.length === 0 ? (
              <EmptyState icon={ClipboardList} title="No reports found" description="Submit a service report after completing a job." />
            ) : (
              <div className={`grid gap-4 ${detailReport ? "grid-cols-1" : "grid-cols-1 lg:grid-cols-2"}`}>
                {filteredReports.map((r, i) => (
                  <motion.div
                    key={r.id}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: i * 0.04 }}
                  >
                    <Card
                      hover
                      className={`p-5 cursor-pointer ${detailReport?.id === r.id ? "ring-2 ring-blue-500 ring-offset-2" : ""}`}
                      onClick={() => openDetail(r)}
                    >
                      {/* Card header */}
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

                      {/* Findings preview */}
                      {r.findings && (
                        <div className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-3 mb-3">
                          <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 mb-1">Findings</p>
                          <p className="text-sm text-gray-700 dark:text-gray-300 line-clamp-2">{r.findings}</p>
                        </div>
                      )}

                      {/* Images preview (count badge) */}
                      {r.image_count > 0 && (
                        <div className="flex items-center gap-1.5 text-xs text-gray-400 mb-3">
                          <ImageIcon size={12} />
                          <span>{r.image_count} photo{r.image_count !== 1 ? "s" : ""}</span>
                        </div>
                      )}

                      {/* Footer */}
                      <div className="flex items-center justify-between text-xs text-gray-400">
                        <span>
                          {r.technician_name || "—"} · {r.report_date ? r.report_date.slice(0, 10) : "—"}
                        </span>

                        {/* Approve / Reject — admin only, pending only */}
                        {canApprove && r.status === "Pending" && (
                          <div
                            className="flex gap-2"
                            onClick={e => e.stopPropagation()}
                          >
                            <button
                              onClick={() => updateStatus(r.id, "Approved")}
                              disabled={approving}
                              className="flex items-center gap-1 text-emerald-600 hover:text-emerald-700 font-semibold disabled:opacity-50"
                            >
                              <CheckCircle size={14} /> Approve
                            </button>
                            <button
                              onClick={() => updateStatus(r.id, "Rejected")}
                              disabled={approving}
                              className="flex items-center gap-1 text-red-500 hover:text-red-600 font-semibold disabled:opacity-50"
                            >
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

          {/* ── Detail Panel ─────────────────────────────── */}
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
                {/* Header */}
                <div className="p-5 border-b border-gray-100 dark:border-gray-700 bg-gradient-to-br from-slate-700 to-slate-900">
                  <div className="flex items-start justify-between">
                    <div>
                      <p className="font-mono text-xs text-blue-400 font-bold">{detailReport.id}</p>
                      <p className="font-bold text-white mt-0.5 leading-snug">{detailReport.title}</p>
                    </div>
                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => navigate(`/reports/${detailReport.id}`)}
                        className="p-1.5 text-white/60 hover:text-white hover:bg-white/10 rounded-lg transition"
                        title="Open full detail page"
                      >
                        <ExternalLink size={15} />
                      </button>
                      <button
                        onClick={() => setDetailReport(null)}
                        className="p-1.5 text-white/60 hover:text-white hover:bg-white/10 rounded-lg transition"
                      >
                        <X size={16} />
                      </button>
                    </div>
                  </div>
                  <div className="flex items-center gap-2 mt-3">
                    <Badge label={detailReport.status} />
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
                      { label: "Job",        value: detailReport.job_id || "—" },
                      { label: "Job Title",  value: detailReport.job_title || "—" },
                      { label: "Client",     value: detailReport.client_name || "—" },
                      { label: "Technician", value: detailReport.technician_name || "—" },
                      { label: "Date",       value: detailReport.report_date ? detailReport.report_date.slice(0, 10) : "—" },
                      { label: "Approved At",value: detailReport.approved_at ? detailReport.approved_at.slice(0, 10) : "—" },
                    ].map(item => (
                      <div key={item.label} className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-3">
                        <p className="text-[10px] text-gray-400 uppercase tracking-wide mb-0.5">{item.label}</p>
                        <p className="text-sm font-semibold text-gray-800 dark:text-white truncate">{item.value}</p>
                      </div>
                    ))}
                  </div>

                  {/* Findings */}
                  {detailReport.findings && (
                    <div>
                      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Findings</p>
                      <div className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-4">
                        <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed whitespace-pre-wrap">
                          {detailReport.findings}
                        </p>
                      </div>
                    </div>
                  )}

                  {/* Recommendations */}
                  {detailReport.recommendations && (
                    <div>
                      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Recommendations</p>
                      <div className="bg-blue-50 dark:bg-blue-900/20 rounded-xl p-4">
                        <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed whitespace-pre-wrap">
                          {detailReport.recommendations}
                        </p>
                      </div>
                    </div>
                  )}

                  {/* Attached Images */}
                  {detailReport.images?.length > 0 && (
                    <div>
                      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">
                        Attached Photos ({detailReport.images.length})
                      </p>
                      <div className="grid grid-cols-3 gap-2">
                        {detailReport.images.map(img => (
                          <a key={img.id} href={img.file_url} target="_blank" rel="noopener noreferrer">
                            <div className="aspect-square rounded-xl overflow-hidden bg-gray-100 dark:bg-gray-700 hover:opacity-80 transition">
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

                  {/* Approve / Reject buttons */}
                  {canApprove && detailReport.status === "Pending" && (
                    <div className="flex gap-2 pt-1">
                      <Button
                        className="flex-1 bg-emerald-600 hover:bg-emerald-700"
                        onClick={() => updateStatus(detailReport.id, "Approved")}
                        disabled={approving}
                      >
                        {approving ? <Loader2 size={14} className="animate-spin mr-1" /> : <CheckCircle size={14} className="mr-1" />}
                        Approve
                      </Button>
                      <Button
                        variant="danger"
                        className="flex-1"
                        onClick={() => updateStatus(detailReport.id, "Rejected")}
                        disabled={approving}
                      >
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
        <Modal isOpen={modalOpen} onClose={() => { if (!submitting) { setModalOpen(false); setPreviewImages([]); }}} title="Submit Service Report" size="lg">
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Job selector */}
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

            {/* Technician selector */}
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

            <Input
              label="Report Title"
              value={form.title}
              onChange={e => setForm(p => ({ ...p, title: e.target.value }))}
              required
              placeholder="HVAC Servicing Report"
            />

            <Textarea
              label="Findings"
              value={form.findings}
              onChange={e => setForm(p => ({ ...p, findings: e.target.value }))}
              rows={3}
              placeholder="Describe what was found during inspection…"
            />

            <Textarea
              label="Recommendations"
              value={form.recommendations}
              onChange={e => setForm(p => ({ ...p, recommendations: e.target.value }))}
              rows={2}
              placeholder="Suggested follow-up actions…"
            />

            {/* Image upload */}
            <div>
              <p className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Attach Photos</p>
              <div
                onClick={() => fileRef.current?.click()}
                className="border-2 border-dashed border-gray-200 dark:border-gray-600 rounded-xl p-4 text-center cursor-pointer hover:border-blue-400 transition group"
              >
                <Upload size={22} className="mx-auto text-gray-300 dark:text-gray-500 mb-1 group-hover:text-blue-400 transition" />
                <p className="text-xs text-gray-400">Click to upload photos</p>
                <input
                  ref={fileRef}
                  type="file"
                  accept="image/jpeg,image/png,image/webp"
                  multiple
                  className="hidden"
                  onChange={handleImageSelect}
                />
              </div>

              {previewImages.length > 0 && (
                <div className="flex flex-wrap gap-2 mt-3">
                  {previewImages.map((img, idx) => (
                    <div key={idx} className="relative group">
                      <img
                        src={img.preview}
                        alt={img.file.name}
                        className="w-16 h-16 object-cover rounded-xl border border-gray-200 dark:border-gray-600"
                      />
                      {img.uploading && (
                        <div className="absolute inset-0 rounded-xl bg-black/40 flex items-center justify-center">
                          <Loader2 size={14} className="animate-spin text-white" />
                        </div>
                      )}
                      {img.uploaded_url && (
                        <div className="absolute inset-0 rounded-xl bg-emerald-500/20 flex items-center justify-center">
                          <CheckCircle size={14} className="text-emerald-500" />
                        </div>
                      )}
                      {!img.uploading && !img.uploaded_url && (
                        <button
                          type="button"
                          onClick={() => removeImage(idx)}
                          className="absolute -top-1 -right-1 w-4 h-4 bg-red-500 text-white rounded-full flex items-center justify-center text-xs shadow opacity-0 group-hover:opacity-100 transition"
                        >
                          <X size={8} />
                        </button>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="flex gap-3 pt-2">
              <Button type="submit" className="flex-1" disabled={submitting}>
                {submitting ? (
                  <><Loader2 size={14} className="animate-spin mr-2" />Submitting…</>
                ) : "Submit Report"}
              </Button>
              <Button variant="secondary" onClick={() => { setModalOpen(false); setPreviewImages([]); }} disabled={submitting}>
                Cancel
              </Button>
            </div>
          </form>
        </Modal>

        {toast && <Toast {...toast} onClose={() => {}} />}
      </div>
    </PageTransition>
  );
}