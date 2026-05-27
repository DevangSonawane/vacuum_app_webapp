// ============================================================
// src/pages/ReportDetail.jsx
// Route: /reports/:id
// Full dedicated detail page — shows all AMC PDF sections
// ============================================================

import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import {
  ArrowLeft, CheckCircle, XCircle, Loader2,
  User, Calendar, Briefcase, Building2,
  Image as ImageIcon, FileText, ClipboardList,
  ChevronRight, Clock, MapPin, Hash, Package,
  AlertTriangle, Wrench, Mail, PenLine, ExternalLink, Download,
  X
} from "lucide-react";
import axios from "axios";
import { useApp } from "../context/AppContext";
import { PageTransition, Badge, Button, useToast, Toast, Card } from "../components/ui";

const API_BASE_URL = "https://vaccumapi-o4ol.onrender.com/api";

const STATUS_STYLES = {
  Pending:  { bg: "bg-amber-50   dark:bg-amber-900/20   border-amber-200  dark:border-amber-800",   text: "text-amber-700  dark:text-amber-300",  dot: "bg-amber-400"   },
  Approved: { bg: "bg-emerald-50 dark:bg-emerald-900/20 border-emerald-200 dark:border-emerald-800", text: "text-emerald-700 dark:text-emerald-300", dot: "bg-emerald-500" },
  Rejected: { bg: "bg-red-50     dark:bg-red-900/20     border-red-200    dark:border-red-800",      text: "text-red-700    dark:text-red-300",     dot: "bg-red-500"     },
};

export default function ReportDetail() {
  const { id }       = useParams();
  const navigate     = useNavigate();
  const { currentUser } = useApp();
  const { toast, showToast } = useToast();

  const [report, setReport]       = useState(null);
  const [loading, setLoading]     = useState(true);
  const [approving, setApproving] = useState(false);
  const [downloading, setDownloading] = useState(false);
  const [selectedImage, setSelectedImage] = useState(null);

  useEffect(() => { fetchReport(); }, [id]);

  const handleDownloadPDF = async () => {
    setDownloading(true);
    try {
      const token = localStorage.getItem("token");
      const res = await axios.get(`${API_BASE_URL}/reports/${id}/pdf`, {
        headers: { Authorization: `Bearer ${token}` },
        responseType: 'blob'
      });
      
      const url = window.URL.createObjectURL(new Blob([res.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `Service_Report_${id}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      showToast("Report download started", "success");
    } catch (err) {
      showToast("Failed to download PDF", "error");
    } finally {
      setDownloading(false);
    }
  };

  const fetchReport = async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem("token");
      const res   = await axios.get(`${API_BASE_URL}/reports/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.data.success) setReport(res.data.data);
      else showToast("Report not found", "error");
    } catch {
      showToast("Failed to load report", "error");
    } finally {
      setLoading(false);
    }
  };

  const updateStatus = async (status) => {
    setApproving(true);
    const token = localStorage.getItem("token");
    try {
      await axios.patch(
        `${API_BASE_URL}/reports/${id}/status`,
        { status },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      showToast(status === "Approved" ? "Report approved!" : "Report rejected", status === "Approved" ? "success" : "error");
      fetchReport();
    } catch (err) {
      showToast(err.response?.data?.message || "Action failed", "error");
    } finally {
      setApproving(false);
    }
  };

  const canApprove = currentUser?.role === "admin";

  // ── Loading skeleton ─────────────────────────────────────
  if (loading) {
    return (
      <PageTransition>
        <div className="p-4 md:p-8 max-w-7xl mx-auto animate-pulse space-y-6">
          <div className="h-8 w-48 bg-gray-200 dark:bg-gray-700 rounded-xl" />
          <div className="h-28 bg-gray-100 dark:bg-gray-800 rounded-2xl" />
          <div className="grid grid-cols-2 gap-4">
            {[...Array(4)].map((_, i) => <div key={i} className="h-24 bg-gray-100 dark:bg-gray-800 rounded-2xl" />)}
          </div>
        </div>
      </PageTransition>
    );
  }

  if (!report) {
    return (
      <PageTransition>
        <div className="p-8 text-center text-gray-400">
          <ClipboardList size={40} className="mx-auto mb-3 opacity-30" />
          <p className="font-medium">Report not found</p>
          <Button className="mt-4" onClick={() => navigate("/reports")}>Back to Reports</Button>
        </div>
      </PageTransition>
    );
  }

  const ss = STATUS_STYLES[report.status] || STATUS_STYLES.Pending;

  return (
    <PageTransition>
      <div className="p-4 md:p-8 max-w-7xl mx-auto space-y-6">

        {/* Back + header */}
        <div className="flex items-start justify-between gap-4">
          <div className="flex items-start gap-4 flex-1 min-w-0">
            <button onClick={() => navigate("/reports")}
              className="mt-1 p-2 rounded-xl text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-800 transition flex-shrink-0">
              <ArrowLeft size={20} />
            </button>
            <div className="flex-1 min-w-0">
              <div className="flex flex-wrap items-center gap-2 mb-1">
                <span className="font-mono text-sm text-blue-600 dark:text-blue-400 font-bold">{report.id}</span>
                <Badge label={report.status} />
              </div>
              <h1 className="text-2xl font-bold text-gray-900 dark:text-white leading-tight">{report.title}</h1>
              <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                {report.company_name || report.client_name || "—"} · {report.job_id}
              </p>
            </div>
          </div>
          
          <Button 
            onClick={handleDownloadPDF} 
            disabled={downloading}
            className="hidden sm:flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white shadow-lg shadow-blue-500/20"
          >
            {downloading ? <Loader2 size={16} className="animate-spin" /> : <Download size={16} />}
            Download PDF
          </Button>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

          {/* ── LEFT: main content ──────────────────────────── */}
          <div className="lg:col-span-2 space-y-6">

            {/* ── PDF Page 1: Client Info ─────────────────────── */}
            <Card className="p-0 overflow-hidden border-gray-100 dark:border-gray-800">
              <div className="p-5 pb-0">
                <SectionLabel icon={ClipboardList} label="Client & Report Info" />
              </div>
              
              <div className="grid grid-cols-2 mt-4 border-t border-gray-100 dark:border-gray-800">
                {[
                  { icon: Briefcase,  label: "Job",           value: report.job_id || "—",    link: report.job_id ? `/jobs/${report.job_id}` : null },
                  { icon: Building2,  label: "Company Name",  value: report.company_name || report.client_name || "—" },
                  { icon: User,       label: "Contact Person", value: report.contact_person || "—" },
                  { icon: User,       label: "Technician",    value: report.technician_name || "—" },
                  { icon: Calendar,   label: "Report Date",   value: report.report_date ? report.report_date.slice(0, 10) : "—" },
                  { icon: Package,    label: "PO Number",     value: report.po_number || "—" },
                  { icon: Wrench,     label: "Model / S/N / Year", value: report.model_serial_installation || "—" },
                  { icon: Clock,      label: "Operating Hrs/Day",  value: report.operating_hours_per_day || "—" },
                  { icon: MapPin,     label: "Location",           value: report.location || "—" },
                ].map((item, idx) => (
                  <div 
                    key={item.label} 
                    className={`p-4 flex items-start gap-3 border-b border-gray-100 dark:border-gray-800 
                      ${idx % 2 === 0 ? "border-r" : ""} 
                      ${idx >= 8 ? "border-b-0" : ""}
                      hover:bg-gray-50/50 dark:hover:bg-gray-800/50 transition-colors`}
                  >
                    <div className="w-8 h-8 rounded-lg bg-gray-50 dark:bg-gray-700 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <item.icon size={13} className="text-gray-500 dark:text-gray-400" />
                    </div>
                    <div className="min-w-0">
                      <p className="text-[10px] text-gray-400 uppercase tracking-wide font-bold">{item.label}</p>
                      {item.link ? (
                        <button onClick={() => navigate(item.link)} className="text-sm font-semibold text-blue-600 dark:text-blue-400 hover:underline flex items-center gap-1 truncate">
                          {item.value} <ChevronRight size={11} />
                        </button>
                      ) : (
                        <p className="text-sm font-semibold text-gray-800 dark:text-white truncate">{item.value}</p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
              {report.application_process_description && (
                <div className="p-5 border-t border-gray-100 dark:border-gray-800">
                  <p className="text-[10px] text-gray-400 uppercase tracking-wide font-bold mb-1">Application / Process Description</p>
                  <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">{report.application_process_description}</p>
                </div>
              )}
              {(report.client_email || report.serial_no) && (
                <div className="p-5 pt-0 flex flex-wrap gap-4">
                  {report.serial_no && (
                    <span className="flex items-center gap-1.5 text-xs text-gray-500 dark:text-gray-400 font-medium">
                      <Hash size={12} className="text-gray-400" /> S/N: <span className="text-gray-900 dark:text-white">{report.serial_no}</span>
                    </span>
                  )}
                  {report.client_email && (
                    <span className="flex items-center gap-1.5 text-xs text-gray-500 dark:text-gray-400 font-medium">
                      <Mail size={12} className="text-blue-500" /> <span className="text-gray-900 dark:text-white">{report.client_email}</span>
                    </span>
                  )}
                </div>
              )}
            </Card>

            {/* ── PDF Page 1: Checklist ───────────────────────── */}
            {report.checklist_items?.length > 0 && (
              <Card className="p-5">
                <SectionLabel icon={CheckCircle} label="Routine Preventive Maintenance Checklist" />
                <div className="mt-4 space-y-2">
                  {report.checklist_items.map((item, i) => (
                    <div key={i} className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-700/50 rounded-xl">
                      <span className="w-6 h-6 rounded-full bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 text-xs font-bold flex items-center justify-center flex-shrink-0">
                        {item.sr}
                      </span>
                      <p className="flex-1 text-sm text-gray-700 dark:text-gray-300">{item.description}</p>
                      {item.status ? (
                        <span className="text-xs font-semibold text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/20 px-2.5 py-1 rounded-full flex-shrink-0">
                          {item.status}
                        </span>
                      ) : (
                        <span className="text-xs text-gray-300 dark:text-gray-600 px-2.5 py-1 flex-shrink-0">—</span>
                      )}
                    </div>
                  ))}
                </div>
              </Card>
            )}

            {/* ── PDF Page 2: Issue Observations ─────────────── */}
            {report.issue_observations?.length > 0 && (
              <Card className="p-5">
                <SectionLabel icon={AlertTriangle} label="Detailed Issue — Observation — Impact Matrix" />
                <div className="mt-4 overflow-x-auto">
                  <table className="w-full text-xs">
                    <thead>
                      <tr className="bg-gray-50 dark:bg-gray-700/50">
                        <th className="text-left p-3 rounded-l-xl text-gray-500 dark:text-gray-400 font-semibold uppercase tracking-wide">SR</th>
                        <th className="text-left p-3 text-gray-500 dark:text-gray-400 font-semibold uppercase tracking-wide">Issue</th>
                        <th className="text-left p-3 text-gray-500 dark:text-gray-400 font-semibold uppercase tracking-wide">Observation</th>
                        <th className="text-left p-3 text-gray-500 dark:text-gray-400 font-semibold uppercase tracking-wide">Impact on Pump</th>
                        <th className="text-left p-3 text-gray-500 dark:text-gray-400 font-semibold uppercase tracking-wide">Severity</th>
                        <th className="text-left p-3 rounded-r-xl text-gray-500 dark:text-gray-400 font-semibold uppercase tracking-wide">Recommended Spares</th>
                      </tr>
                    </thead>
                    <tbody>
                      {report.issue_observations.map((obs, i) => (
                        <tr key={i} className="border-b border-gray-100 dark:border-gray-700/50 hover:bg-gray-50 dark:hover:bg-gray-700/30 transition">
                          <td className="p-3 text-gray-500 dark:text-gray-400">{obs.sr || i + 1}</td>
                          <td className="p-3 font-semibold text-gray-800 dark:text-white">{obs.issue || "—"}</td>
                          <td className="p-3 text-gray-700 dark:text-gray-300">{obs.observation || "—"}</td>
                          <td className="p-3 text-gray-700 dark:text-gray-300">{obs.impact_on_pump || "—"}</td>
                          <td className="p-3">
                            {obs.severity ? (
                              <span className={`font-bold px-2 py-0.5 rounded-full
                                ${obs.severity === "High" ? "bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400" :
                                  obs.severity === "Med"  ? "bg-amber-100 text-amber-600 dark:bg-amber-900/30 dark:text-amber-400" :
                                  "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"}`}>
                                {obs.severity}
                              </span>
                            ) : "—"}
                          </td>
                          <td className="p-3 text-gray-700 dark:text-gray-300">{obs.recommended_spares || "—"}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </Card>
            )}



            {/* ── PDF Page 4: Mandatory Spares ───────────────── */}
            {report.mandatory_spares?.length > 0 && (
              <Card className="p-5">
                <SectionLabel icon={Package} label="Mandatory Spares — AMC Compliance Matrix" />
                <div className="mt-4 overflow-x-auto">
                  <table className="w-full text-xs">
                    <thead>
                      <tr className="bg-gray-50 dark:bg-gray-700/50">
                        <th className="text-left p-3 rounded-l-xl text-gray-500 dark:text-gray-400 font-semibold uppercase tracking-wide">Spare Name</th>
                        <th className="text-left p-3 text-gray-500 dark:text-gray-400 font-semibold uppercase tracking-wide">Pump Model</th>
                        <th className="text-left p-3 rounded-r-xl text-gray-500 dark:text-gray-400 font-semibold uppercase tracking-wide">Total To Order</th>
                      </tr>
                    </thead>
                    <tbody>
                      {report.mandatory_spares.map((s, i) => (
                        <tr key={i} className="border-b border-gray-100 dark:border-gray-700/50">
                          <td className="p-3 text-gray-800 dark:text-white font-medium">{s.spare_name || "—"}</td>
                          <td className="p-3 text-gray-600 dark:text-gray-300">{s.pump_model || "—"}</td>
                          <td className="p-3 text-gray-600 dark:text-gray-300">{s.total_to_order || "—"}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                <div className="mt-4 p-3 bg-blue-50 dark:bg-blue-900/10 rounded-xl">
                  <p className="text-xs font-bold text-blue-700 dark:text-blue-400 mb-1">Client Obligations</p>
                  <p className="text-xs text-blue-700 dark:text-blue-300 leading-relaxed">
                    The client shall ensure the timely procurement and availability of all mandatory spares to ensure uninterrupted operation and effective AMC service.
                  </p>
                </div>
              </Card>
            )}



            {/* ── Technical Reports ───────────────────────────── */}
            {report.technical_reports?.length > 0 && (
              <Card className="p-5">
                <SectionLabel icon={FileText} label={`Technical Reports (${report.technical_reports.length})`} />
                <div className="space-y-2 mt-4">
                  {report.technical_reports.map(doc => (
                    <a key={doc.id} href={doc.file_url} target="_blank" rel="noopener noreferrer"
                      className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-700/50 rounded-xl hover:bg-blue-50 dark:hover:bg-blue-900/20 transition group">
                      <div className="w-9 h-9 rounded-xl bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center flex-shrink-0">
                        <FileText size={15} className="text-blue-600 dark:text-blue-400" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-semibold text-gray-800 dark:text-white truncate">{doc.file_name}</p>
                        {doc.file_size_bytes && <p className="text-xs text-gray-400">{(doc.file_size_bytes / 1024).toFixed(0)} KB</p>}
                      </div>
                      <ExternalLink size={13} className="text-gray-400 group-hover:text-blue-500 flex-shrink-0" />
                    </a>
                  ))}
                </div>
              </Card>
            )}
          </div>

          {/* ── RIGHT: status & actions ─────────────────────── */}
          <div className="space-y-5">

            {/* Status */}
            <Card className={`p-5 border ${ss.bg}`}>
              <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Status</p>
              <div className={`inline-flex items-center gap-2 px-4 py-2 rounded-xl font-bold text-sm ${ss.bg} ${ss.text}`}>
                <span className={`w-2 h-2 rounded-full ${ss.dot}`} />
                {report.status}
              </div>
              {report.approved_at && (
                <p className="text-xs text-gray-400 mt-2">
                  Reviewed: {report.approved_at.slice(0, 10)}
                </p>
              )}
            </Card>

            {/* Approve / Reject */}
            {canApprove && report.status === "Pending" && (
              <Card className="p-5">
                <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Review</p>
                <div className="space-y-2">
                  <Button className="w-full bg-emerald-600 hover:bg-emerald-700" onClick={() => updateStatus("Approved")} disabled={approving}>
                    {approving ? <Loader2 size={14} className="animate-spin mr-1" /> : <CheckCircle size={14} className="mr-1" />}
                    Approve Report
                  </Button>
                  <Button variant="danger" className="w-full" onClick={() => updateStatus("Rejected")} disabled={approving}>
                    <XCircle size={14} className="mr-1" /> Reject Report
                  </Button>
                </div>
              </Card>
            )}

            {/* Linked Job */}
            {report.job_id && (
              <Card className="p-5">
                <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Linked Job</p>
                <button onClick={() => navigate(`/jobs/${report.job_id}`)}
                  className="w-full flex items-center gap-3 bg-gray-50 dark:bg-gray-700/50 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-xl px-4 py-3 transition">
                  <div className="w-8 h-8 rounded-lg bg-blue-50 dark:bg-blue-900/30 flex items-center justify-center flex-shrink-0">
                    <Briefcase size={13} className="text-blue-500" />
                  </div>
                  <div className="flex-1 text-left">
                    <p className="font-mono text-xs text-blue-500">{report.job_id}</p>
                    <p className="text-sm font-medium text-gray-800 dark:text-white truncate">{report.job_title || "View Job"}</p>
                  </div>
                  <ChevronRight size={15} className="text-gray-400 flex-shrink-0" />
                </button>
              </Card>
            )}

            {/* Quick stats */}
            <Card className="p-5">
              <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Summary</p>
              <div className="space-y-3">
                {[
                  { label: "Checklist Items",  value: report.checklist_items?.length ?? 0 },
                  { label: "Issues Recorded",  value: report.issue_observations?.length ?? 0 },
                  { label: "Mandatory Spares", value: report.mandatory_spares?.length ?? 0 },
                  { label: "Photos",           value: report.images?.length ?? 0 },
                  { label: "Tech Documents",   value: report.technical_reports?.length ?? 0 },
                ].map(item => (
                  <div key={item.label} className="flex items-center justify-between">
                    <span className="text-sm text-gray-500 dark:text-gray-400">{item.label}</span>
                    <span className="text-sm font-bold text-gray-900 dark:text-white">{item.value}</span>
                  </div>
                ))}
              </div>
            </Card>

            {/* ── Findings / Recommendations ─────────────────── */}
            {(report.findings || report.recommendations || report.comments) && (
              <Card className="p-5 space-y-4">
                <SectionLabel icon={FileText} label="Findings & Recommendations" />
                {report.findings && (
                  <div>
                    <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Findings</p>
                    <div className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-3">
                      <p className="text-xs text-gray-700 dark:text-gray-300 leading-relaxed whitespace-pre-wrap">{report.findings}</p>
                    </div>
                  </div>
                )}
                {report.recommendations && (
                  <div>
                    <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Recommendations</p>
                    <div className="bg-blue-50 dark:bg-blue-900/20 rounded-xl p-3">
                      <p className="text-xs text-gray-700 dark:text-gray-300 leading-relaxed whitespace-pre-wrap">{report.recommendations}</p>
                    </div>
                  </div>
                )}
                {report.comments && (
                  <div>
                    <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Comments</p>
                    <div className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-3">
                      <p className="text-xs text-gray-700 dark:text-gray-300 leading-relaxed whitespace-pre-wrap">{report.comments}</p>
                    </div>
                  </div>
                )}
              </Card>
            )}

            {/* ── Signatures ──────────────────────────────────── */}
            {(report.vdt_representative_name || report.client_representative_name) && (
              <Card className="p-5">
                <SectionLabel icon={PenLine} label="Signatures" />
                <div className="space-y-3 mt-4">
                  <div className="border border-gray-200 dark:border-gray-700 rounded-xl p-3">
                    <p className="text-[10px] font-bold text-gray-400 uppercase tracking-wide mb-1">VDT Rep</p>
                    <p className="text-xs font-semibold text-gray-800 dark:text-white">{report.vdt_representative_name || "—"}</p>
                  </div>
                  <div className="border border-gray-200 dark:border-gray-700 rounded-xl p-3">
                    <p className="text-[10px] font-bold text-gray-400 uppercase tracking-wide mb-1">Client Rep</p>
                    <p className="text-xs font-semibold text-gray-800 dark:text-white">{report.client_representative_name || "—"}</p>
                  </div>
                </div>
              </Card>
            )}

            {/* ── PDF Page 3: Remarks ─────────────────────────── */}
            {report.remarks && (
              <Card className="p-5">
                <SectionLabel icon={PenLine} label="Remarks" />
                <div className="mt-3 bg-amber-50 dark:bg-amber-900/10 rounded-xl p-4">
                  <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed whitespace-pre-wrap">{report.remarks}</p>
                </div>
              </Card>
            )}

            {/* ── Photos ──────────────────────────────────────── */}
            <Card className="p-5">
              <SectionLabel icon={ImageIcon} label={`Attached Photos${report.images?.length > 0 ? ` (${report.images.length})` : ""}`} />
              {report.images?.length > 0 ? (
                <div className="grid grid-cols-3 sm:grid-cols-4 gap-3 mt-4">
                  {report.images.map(img => (
                    <div key={img.id} onClick={() => setSelectedImage(img)} className="group cursor-pointer">
                      <div className="aspect-square rounded-xl overflow-hidden bg-gray-100 dark:bg-gray-700 hover:opacity-80 transition group-hover:ring-2 group-hover:ring-blue-500">
                        <img src={img.file_url} alt={img.file_name} className="w-full h-full object-cover" />
                      </div>
                      <p className="text-[10px] text-gray-400 truncate mt-1">{img.file_name}</p>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="flex flex-col items-center justify-center py-8 text-gray-300 dark:text-gray-600 mt-3">
                  <ImageIcon size={28} className="mb-2 opacity-40" />
                  <p className="text-sm">No photos attached</p>
                </div>
              )}
            </Card>
          </div>
        </div>
      </div>

      {/* Lightbox Modal */}
      <AnimatePresence>
        {selectedImage && (
          <motion.div 
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            onClick={() => setSelectedImage(null)}
            className="fixed inset-0 z-[200] bg-black/90 backdrop-blur-sm flex items-center justify-center p-4 cursor-zoom-out"
          >
            <motion.div 
              initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.9, opacity: 0 }}
              className="relative max-w-5xl max-h-[90vh]"
            >
              <img src={selectedImage.file_url} alt="" className="rounded-2xl shadow-2xl max-h-[85vh] object-contain" />
              <div className="absolute top-4 right-4 flex gap-2">
                <a href={selectedImage.file_url} download target="_blank" rel="noreferrer"
                   className="p-2 bg-white/10 hover:bg-white/20 rounded-full text-white transition backdrop-blur-md">
                  <Download size={20} />
                </a>
                <button onClick={() => setSelectedImage(null)} 
                        className="p-2 bg-white/10 hover:bg-white/20 rounded-full text-white transition backdrop-blur-md">
                  <X size={20} />
                </button>
              </div>
              <div className="mt-4 text-center">
                <p className="text-white font-medium">{selectedImage.file_name}</p>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {toast && <Toast message={toast.message} type={toast.type} />}
    </PageTransition>
  );
}

// ── Helper ────────────────────────────────────────────────────
function SectionLabel({ icon: Icon, label }) {
  return (
    <div className="flex items-center gap-2">
      <Icon size={14} className="text-gray-400 dark:text-gray-500" />
      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest">{label}</p>
    </div>
  );
}