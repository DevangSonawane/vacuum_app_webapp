// ============================================================
// src/pages/ReportDetail.jsx
// Full dedicated detail page for a single report
// Route: /reports/:id
// ============================================================

import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import {
  ArrowLeft, CheckCircle, XCircle, Loader2,
  User, Calendar, Briefcase, Building2,
  Image as ImageIcon, FileText, ClipboardList,
  ChevronRight, AlertCircle, Clock
} from "lucide-react";
import axios from "axios";
import { useApp } from "../context/AppContext";
import {
  PageTransition, Badge, Button, useToast, Toast, Card
} from "../components/ui";

const API_BASE_URL = "https://vaccumapi.onrender.com/api";

const STATUS_STYLES = {
  Pending:  { bg: "bg-amber-50   dark:bg-amber-900/20   border-amber-200  dark:border-amber-800",   text: "text-amber-700  dark:text-amber-300",  dot: "bg-amber-400"   },
  Approved: { bg: "bg-emerald-50 dark:bg-emerald-900/20 border-emerald-200 dark:border-emerald-800", text: "text-emerald-700 dark:text-emerald-300", dot: "bg-emerald-500" },
  Rejected: { bg: "bg-red-50     dark:bg-red-900/20     border-red-200    dark:border-red-800",      text: "text-red-700    dark:text-red-300",     dot: "bg-red-500"     },
};

export default function ReportDetail() {
  const { id }      = useParams();
  const navigate    = useNavigate();
  const { currentUser } = useApp();
  const { toast, showToast } = useToast();

  const [report, setReport]   = useState(null);
  const [loading, setLoading] = useState(true);
  const [approving, setApproving] = useState(false);

  useEffect(() => { fetchReport(); }, [id]);

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

  // ── Approve / Reject ──────────────────────────────────────
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

  if (loading) {
    return (
      <PageTransition>
        <div className="p-4 md:p-8 max-w-5xl mx-auto">
          <div className="animate-pulse space-y-6">
            <div className="h-8 w-48 bg-gray-200 dark:bg-gray-700 rounded-xl" />
            <div className="h-28 bg-gray-100 dark:bg-gray-800 rounded-2xl" />
            <div className="grid grid-cols-2 gap-4">
              {[...Array(4)].map((_, i) => <div key={i} className="h-24 bg-gray-100 dark:bg-gray-800 rounded-2xl" />)}
            </div>
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
      <div className="p-4 md:p-8 max-w-5xl mx-auto space-y-6">

        {/* Back + header */}
        <div className="flex items-start gap-4">
          <button
            onClick={() => navigate("/reports")}
            className="mt-1 p-2 rounded-xl text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-800 transition flex-shrink-0"
          >
            <ArrowLeft size={20} />
          </button>
          <div className="flex-1 min-w-0">
            <div className="flex flex-wrap items-center gap-2 mb-1">
              <span className="font-mono text-sm text-blue-600 dark:text-blue-400 font-bold">{report.id}</span>
              <Badge label={report.status} />
            </div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white leading-tight">{report.title}</h1>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
              {report.client_name || "—"} · {report.job_id}
            </p>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

          {/* Left — content */}
          <div className="lg:col-span-2 space-y-6">

            {/* Meta info */}
            <Card className="p-5">
              <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-4">Report Info</p>
              <div className="grid grid-cols-2 gap-4">
                {[
                  { icon: Briefcase,    label: "Job",          value: report.job_id    || "—",  link: report.job_id ? `/jobs/${report.job_id}` : null },
                  { icon: FileText,     label: "Job Title",    value: report.job_title || "—" },
                  { icon: Building2,    label: "Client",       value: report.client_name || "—" },
                  { icon: User,         label: "Technician",   value: report.technician_name || "—" },
                  { icon: Calendar,     label: "Report Date",  value: report.report_date    ? report.report_date.slice(0, 10)    : "—" },
                  { icon: Clock,        label: "Approved At",  value: report.approved_at    ? report.approved_at.slice(0, 10)    : "—" },
                ].map(item => (
                  <div key={item.label} className="flex items-start gap-3">
                    <div className="w-8 h-8 rounded-lg bg-gray-50 dark:bg-gray-700 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <item.icon size={14} className="text-gray-500 dark:text-gray-400" />
                    </div>
                    <div>
                      <p className="text-[10px] text-gray-400 uppercase tracking-wide">{item.label}</p>
                      {item.link ? (
                        <button
                          onClick={() => navigate(item.link)}
                          className="text-sm font-semibold text-blue-600 dark:text-blue-400 hover:underline flex items-center gap-1"
                        >
                          {item.value} <ChevronRight size={12} />
                        </button>
                      ) : (
                        <p className="text-sm font-semibold text-gray-800 dark:text-white">{item.value}</p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </Card>

            {/* Findings */}
            <Card className="p-5">
              <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Findings</p>
              {report.findings ? (
                <div className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-4">
                  <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed whitespace-pre-wrap">
                    {report.findings}
                  </p>
                </div>
              ) : (
                <p className="text-sm text-gray-400 italic">No findings recorded.</p>
              )}
            </Card>

            {/* Recommendations */}
            <Card className="p-5">
              <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Recommendations</p>
              {report.recommendations ? (
                <div className="bg-blue-50 dark:bg-blue-900/20 rounded-xl p-4">
                  <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed whitespace-pre-wrap">
                    {report.recommendations}
                  </p>
                </div>
              ) : (
                <p className="text-sm text-gray-400 italic">No recommendations recorded.</p>
              )}
            </Card>

            {/* Attached Photos */}
            <Card className="p-5">
              <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-4">
                Attached Photos {report.images?.length > 0 && `(${report.images.length})`}
              </p>
              {report.images?.length > 0 ? (
                <div className="grid grid-cols-3 sm:grid-cols-4 gap-3">
                  {report.images.map(img => (
                    <a key={img.id} href={img.file_url} target="_blank" rel="noopener noreferrer" className="group">
                      <div className="aspect-square rounded-xl overflow-hidden bg-gray-100 dark:bg-gray-700 hover:opacity-80 transition ring-0 group-hover:ring-2 group-hover:ring-blue-500">
                        <img
                          src={img.file_url}
                          alt={img.file_name}
                          className="w-full h-full object-cover"
                        />
                      </div>
                      <p className="text-[10px] text-gray-400 truncate mt-1">{img.file_name}</p>
                    </a>
                  ))}
                </div>
              ) : (
                <div className="flex flex-col items-center justify-center py-10 text-gray-300 dark:text-gray-600">
                  <ImageIcon size={32} className="mb-2 opacity-40" />
                  <p className="text-sm">No photos attached</p>
                </div>
              )}
            </Card>
          </div>

          {/* Right — status + actions */}
          <div className="space-y-5">

            {/* Status card */}
            <Card className={`p-5 border ${ss.bg}`}>
              <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Status</p>
              <div className={`inline-flex items-center gap-2 px-4 py-2 rounded-xl font-bold text-sm ${ss.bg} ${ss.text}`}>
                <span className={`w-2 h-2 rounded-full ${ss.dot}`} />
                {report.status}
              </div>
            </Card>

            {/* Approve / Reject actions — admin + pending only */}
            {canApprove && report.status === "Pending" && (
              <Card className="p-5">
                <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Review</p>
                <div className="space-y-2">
                  <Button
                    className="w-full bg-emerald-600 hover:bg-emerald-700"
                    onClick={() => updateStatus("Approved")}
                    disabled={approving}
                  >
                    {approving
                      ? <Loader2 size={15} className="animate-spin mr-2" />
                      : <CheckCircle size={15} className="mr-2" />
                    }
                    Approve Report
                  </Button>
                  <Button
                    variant="danger"
                    className="w-full"
                    onClick={() => updateStatus("Rejected")}
                    disabled={approving}
                  >
                    <XCircle size={15} className="mr-2" /> Reject Report
                  </Button>
                </div>
              </Card>
            )}

            {report.status === "Approved" && (
              <Card className="p-5 border border-emerald-200 dark:border-emerald-800 bg-emerald-50 dark:bg-emerald-900/20">
                <div className="flex items-center gap-2 text-emerald-700 dark:text-emerald-300">
                  <CheckCircle size={17} />
                  <p className="font-semibold text-sm">Approved</p>
                </div>
                {report.approved_at && (
                  <p className="text-xs text-emerald-600 dark:text-emerald-400 mt-1 ml-7">
                    {report.approved_at.slice(0, 10)}
                  </p>
                )}
              </Card>
            )}

            {report.status === "Rejected" && (
              <Card className="p-5 border border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-900/20">
                <div className="flex items-center gap-2 text-red-700 dark:text-red-300">
                  <XCircle size={17} />
                  <p className="font-semibold text-sm">Rejected</p>
                </div>
                {report.approved_at && (
                  <p className="text-xs text-red-600 dark:text-red-400 mt-1 ml-7">
                    {report.approved_at.slice(0, 10)}
                  </p>
                )}
              </Card>
            )}

            {/* Navigate to linked job */}
            {report.job_id && (
              <Card className="p-5">
                <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Linked Job</p>
                <button
                  onClick={() => navigate(`/jobs/${report.job_id}`)}
                  className="w-full flex items-center gap-3 bg-gray-50 dark:bg-gray-700/50 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-xl px-4 py-3 transition"
                >
                  <div className="w-8 h-8 rounded-lg bg-blue-50 dark:bg-blue-900/30 flex items-center justify-center flex-shrink-0">
                    <Briefcase size={14} className="text-blue-500" />
                  </div>
                  <div className="flex-1 text-left">
                    <p className="font-mono text-xs text-blue-500">{report.job_id}</p>
                    <p className="text-sm font-medium text-gray-800 dark:text-white truncate">{report.job_title || "View Job"}</p>
                  </div>
                  <ChevronRight size={16} className="text-gray-400 flex-shrink-0" />
                </button>
              </Card>
            )}

            {/* Quick stats */}
            <Card className="p-5">
              <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Quick Stats</p>
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-500 dark:text-gray-400">Photos</span>
                  <span className="text-sm font-bold text-gray-900 dark:text-white">{report.images?.length ?? 0}</span>
                </div>
              </div>
            </Card>
          </div>
        </div>
      </div>

      {toast && <Toast message={toast.message} type={toast.type} />}
    </PageTransition>
  );
}
