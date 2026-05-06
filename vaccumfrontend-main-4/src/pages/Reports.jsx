// ============================================================
// src/pages/Reports.jsx
// Route: /reports
// List + detail panel. "New Report" navigates to CreateReport.
// ============================================================

import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import {
  Plus, ClipboardList, CheckCircle, XCircle, X,
  Loader2, Image as ImageIcon, FileText,
  Calendar, User, ExternalLink,
  Hash, MapPin, Package, Mail,
  AlertTriangle, Wrench, ChevronRight
} from "lucide-react";
import axios from "axios";
import { useApp } from "../context/AppContext";
import {
  PageTransition, Card, Badge, Button, useToast, Toast, EmptyState, SectionHeader
} from "../components/ui";

const API_BASE_URL = "https://vaccumapi.onrender.com/api";

export default function Reports() {
  const { currentUser } = useApp();
  const navigate        = useNavigate();
  const { toast, showToast } = useToast();

  const [reports, setReports]         = useState([]);
  const [loading, setLoading]         = useState(true);
  const [statusFilter, setStatusFilter] = useState("All");
  const [detailReport, setDetailReport]   = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [approving, setApproving]         = useState(false);

  useEffect(() => { fetchReports(); }, [statusFilter]);

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

  const openDetail = async (report) => {
    setDetailReport({ ...report, images: [], technical_reports: [], checklist_items: [], issue_observations: [], mandatory_spares: [] });
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

  const canApprove  = currentUser?.role === "admin";
  const STATUS_TABS = ["All", "Pending", "Approved", "Rejected"];

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-7xl mx-auto">
        <SectionHeader
          title="AMC Service Reports"
          subtitle={`${reports.length} report${reports.length !== 1 ? "s" : ""}`}
          action={
            <Button onClick={() => navigate("/reports/create")}>
              <Plus size={16} /> New Report
            </Button>
          }
        />

        {/* Status filter tabs */}
        <div className="flex gap-2 mb-5 flex-wrap">
          {STATUS_TABS.map(s => (
            <button key={s} onClick={() => setStatusFilter(s)}
              className={`px-4 py-1.5 rounded-xl text-xs font-semibold transition
                ${statusFilter === s
                  ? "bg-blue-600 text-white"
                  : "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"}`}>
              {s}
              {s !== "All" && (
                <span className="ml-1.5 bg-white/20 dark:bg-black/20 px-1.5 rounded-full">
                  {reports.filter(r => r.status === s).length}
                </span>
              )}
            </button>
          ))}
        </div>

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
              <EmptyState icon={ClipboardList} title="No reports found" description="Create a new AMC Service Report to get started." />
            ) : (
              <div className={`grid gap-4 ${detailReport ? "grid-cols-1" : "grid-cols-1 lg:grid-cols-2"}`}>
                {reports.map((r, i) => (
                  <motion.div key={r.id} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.04 }}>
                    <Card hover
                      className={`p-5 cursor-pointer ${detailReport?.id === r.id ? "ring-2 ring-blue-500 ring-offset-2" : ""}`}
                      onClick={() => navigate(`/reports/${r.id}`)}>

                      <div className="flex items-start justify-between mb-2">
                        <div>
                          <p className="font-mono text-xs text-blue-500 dark:text-blue-400">{r.id}</p>
                          <p className="font-bold text-gray-900 dark:text-white text-sm mt-0.5">{r.title}</p>
                          <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                            {r.company_name || r.client_name || r.job_title || "—"}
                          </p>
                        </div>
                        <Badge label={r.status} />
                      </div>

                      {/* Tags */}
                      <div className="flex flex-wrap gap-1.5 mb-3">
                        {r.po_number && (
                          <span className="inline-flex items-center gap-1 text-xs bg-purple-50 dark:bg-purple-900/20 text-purple-600 dark:text-purple-400 px-2 py-0.5 rounded-full">
                            <Package size={9} /> {r.po_number}
                          </span>
                        )}
                        {r.location && (
                          <span className="inline-flex items-center gap-1 text-xs bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400 px-2 py-0.5 rounded-full">
                            <MapPin size={9} /> {r.location}
                          </span>
                        )}
                        {r.serial_no && (
                          <span className="inline-flex items-center gap-1 text-xs bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 px-2 py-0.5 rounded-full">
                            <Hash size={9} /> {r.serial_no}
                          </span>
                        )}
                        {r.model_serial_installation && (
                          <span className="inline-flex items-center gap-1 text-xs bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 px-2 py-0.5 rounded-full">
                            <Wrench size={9} /> {r.model_serial_installation}
                          </span>
                        )}
                      </div>

                      {/* Stats row */}
                      <div className="flex items-center gap-3 flex-wrap mb-3">
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
                              <CheckCircle size={13} /> Approve
                            </button>
                            <button onClick={() => updateStatus(r.id, "Rejected")} disabled={approving}
                              className="flex items-center gap-1 text-red-500 hover:text-red-600 font-semibold disabled:opacity-50">
                              <XCircle size={13} /> Reject
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

          {/* ── Detail Panel ───────────────────────────────────── */}
          <AnimatePresence>
            {detailReport && (
              <motion.div
                key="detail"
                initial={{ opacity: 0, x: 40 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 40 }}
                transition={{ type: "spring", damping: 28, stiffness: 280 }}
                className="w-full lg:w-[400px] flex-shrink-0 bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 shadow-lg overflow-hidden sticky top-4"
              >
                {/* Panel header */}
                <div className="p-5 border-b border-gray-100 dark:border-gray-700 bg-gradient-to-br from-slate-700 to-slate-900">
                  <div className="flex items-start justify-between">
                    <div className="flex-1 min-w-0 mr-2">
                      <p className="font-mono text-xs text-blue-400 font-bold">{detailReport.id}</p>
                      <p className="font-bold text-white mt-0.5 leading-snug truncate">{detailReport.title}</p>
                      <p className="text-slate-300 text-xs mt-0.5">{detailReport.company_name || detailReport.client_name || "—"}</p>
                    </div>
                    <div className="flex items-center gap-1 flex-shrink-0">
                      <button onClick={() => navigate(`/reports/${detailReport.id}`)}
                        className="p-1.5 text-white/60 hover:text-white hover:bg-white/10 rounded-lg transition" title="Full page">
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
                        <Package size={9} /> {detailReport.po_number}
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
                      { label: "Job",         value: detailReport.job_id             || "—" },
                      { label: "Date",        value: detailReport.report_date ? detailReport.report_date.slice(0, 10) : "—" },
                      { label: "Technician",  value: detailReport.technician_name    || "—" },
                      { label: "Contact",     value: detailReport.contact_person     || detailReport.client_name || "—" },
                      { label: "Model/S/N",   value: detailReport.model_serial_installation || "—" },
                      { label: "Hrs/Day",     value: detailReport.operating_hours_per_day   || "—" },
                    ].map(item => (
                      <div key={item.label} className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-3">
                        <p className="text-[10px] text-gray-400 uppercase tracking-wide mb-0.5">{item.label}</p>
                        <p className="text-xs font-semibold text-gray-800 dark:text-white truncate">{item.value}</p>
                      </div>
                    ))}
                  </div>

                  {/* Checklist summary */}
                  {detailReport.checklist_items?.length > 0 && (
                    <div>
                      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">
                        Checklist ({detailReport.checklist_items.length} items)
                      </p>
                      <div className="space-y-1.5">
                        {detailReport.checklist_items.map((item, i) => (
                          <div key={i} className="flex items-center justify-between text-xs bg-gray-50 dark:bg-gray-700/50 rounded-lg px-3 py-2">
                            <span className="text-gray-600 dark:text-gray-300 truncate flex-1 mr-2">{item.sr}. {item.description}</span>
                            {item.status && (
                              <span className="font-semibold text-emerald-600 dark:text-emerald-400 flex-shrink-0">{item.status}</span>
                            )}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Issues summary */}
                  {detailReport.issue_observations?.length > 0 && (
                    <div>
                      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">
                        <AlertTriangle size={11} className="inline mr-1" />
                        Issues ({detailReport.issue_observations.length})
                      </p>
                      <div className="space-y-1.5">
                        {detailReport.issue_observations.map((obs, i) => (
                          <div key={i} className="bg-gray-50 dark:bg-gray-700/50 rounded-lg px-3 py-2">
                            <div className="flex items-center justify-between mb-0.5">
                              <span className="text-xs font-semibold text-gray-700 dark:text-gray-300">{obs.issue || "—"}</span>
                              {obs.severity && (
                                <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded-full
                                  ${obs.severity === "High" ? "bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400" :
                                    obs.severity === "Med"  ? "bg-amber-100 text-amber-600 dark:bg-amber-900/30 dark:text-amber-400" :
                                    "bg-green-100 text-green-600"}`}>
                                  {obs.severity}
                                </span>
                              )}
                            </div>
                            {obs.observation && <p className="text-[11px] text-gray-500 dark:text-gray-400">{obs.observation}</p>}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Spares summary */}
                  {detailReport.mandatory_spares?.length > 0 && (
                    <div>
                      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">
                        Mandatory Spares ({detailReport.mandatory_spares.length})
                      </p>
                      <div className="space-y-1.5">
                        {detailReport.mandatory_spares.map((s, i) => (
                          <div key={i} className="flex items-center justify-between text-xs bg-gray-50 dark:bg-gray-700/50 rounded-lg px-3 py-2">
                            <span className="text-gray-700 dark:text-gray-300 truncate flex-1">{s.spare_name}</span>
                            {s.total_to_order && <span className="text-gray-500 ml-2 flex-shrink-0">Qty: {s.total_to_order}</span>}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Remarks */}
                  {detailReport.remarks && (
                    <div>
                      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Remarks</p>
                      <div className="bg-amber-50 dark:bg-amber-900/10 rounded-xl p-3">
                        <p className="text-xs text-gray-700 dark:text-gray-300 leading-relaxed whitespace-pre-wrap">{detailReport.remarks}</p>
                      </div>
                    </div>
                  )}

                  {/* Findings */}
                  {detailReport.findings && (
                    <div>
                      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Findings</p>
                      <div className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-3">
                        <p className="text-xs text-gray-700 dark:text-gray-300 leading-relaxed whitespace-pre-wrap">{detailReport.findings}</p>
                      </div>
                    </div>
                  )}

                  {/* Technical docs */}
                  {detailReport.technical_reports?.length > 0 && (
                    <div>
                      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">
                        Technical Reports ({detailReport.technical_reports.length})
                      </p>
                      <div className="space-y-2">
                        {detailReport.technical_reports.map(doc => (
                          <a key={doc.id} href={doc.file_url} target="_blank" rel="noopener noreferrer"
                            className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-700/50 rounded-xl hover:bg-blue-50 dark:hover:bg-blue-900/20 transition group">
                            <div className="w-7 h-7 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center flex-shrink-0">
                              <FileText size={13} className="text-blue-600 dark:text-blue-400" />
                            </div>
                            <div className="flex-1 min-w-0">
                              <p className="text-xs font-semibold text-gray-800 dark:text-white truncate">{doc.file_name}</p>
                              {doc.file_size_bytes && <p className="text-[10px] text-gray-400">{(doc.file_size_bytes / 1024).toFixed(0)} KB</p>}
                            </div>
                            <ExternalLink size={11} className="text-gray-400 group-hover:text-blue-500 flex-shrink-0" />
                          </a>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Approve / Reject */}
                  {canApprove && detailReport.status === "Pending" && (
                    <div className="flex gap-2 pt-1">
                      <Button className="flex-1 bg-emerald-600 hover:bg-emerald-700" onClick={() => updateStatus(detailReport.id, "Approved")} disabled={approving}>
                        {approving ? <Loader2 size={13} className="animate-spin" /> : <CheckCircle size={13} />} Approve
                      </Button>
                      <Button variant="danger" className="flex-1" onClick={() => updateStatus(detailReport.id, "Rejected")} disabled={approving}>
                        <XCircle size={13} /> Reject
                      </Button>
                    </div>
                  )}

                  {/* View full page button */}
                  <button onClick={() => navigate(`/reports/${detailReport.id}`)}
                    className="w-full flex items-center justify-center gap-2 text-xs text-blue-500 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 font-semibold py-2 transition">
                    View Full Report Page <ChevronRight size={13} />
                  </button>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>

      {toast && <Toast {...toast} onClose={() => {}} />}
    </PageTransition>
  );
}