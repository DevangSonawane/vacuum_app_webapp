import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { ArrowLeft, CheckCircle, Clock, AlertCircle, WifiOff, ServerCrash, FileX, RefreshCw } from "lucide-react";
import axios from "axios";
import { PageTransition } from "../components/ui";

const API_BASE_URL = "https://apivdti.asynk.in/api";

const PRIORITY_COLORS = {
  High:   "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
  Medium: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400",
  Low:    "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400",
};

const STATUS_COLORS = {
  Approved:  "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
  Open:      "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400",
  Cancelled: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
};

function Sk({ className = "" }) {
  return <div className={`animate-pulse rounded-lg bg-gray-200 dark:bg-gray-700 ${className}`} />;
}

function SkeletonPage() {
  return (
    <div className="p-4 md:p-6 max-w-5xl mx-auto space-y-6">
      {/* Back + title */}
      <div className="flex items-center gap-3">
        <Sk className="w-9 h-9 rounded-xl" />
        <div className="space-y-1.5">
          <Sk className="h-6 w-48" />
          <Sk className="h-3.5 w-32" />
        </div>
      </div>

      {/* Badges row */}
      <div className="flex gap-2">
        <Sk className="h-6 w-20 rounded-full" />
        <Sk className="h-6 w-24 rounded-full" />
        <Sk className="h-6 w-16 rounded-full" />
      </div>

      {/* Subject block */}
      <Sk className="h-16 w-full rounded-xl" />

      {/* Info sections */}
      {[1, 2].map(n => (
        <div key={n} className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 p-5 space-y-4">
          <Sk className="h-3.5 w-36" />
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="space-y-1.5">
                <Sk className="h-3 w-20" />
                <Sk className="h-4 w-28" />
              </div>
            ))}
          </div>
        </div>
      ))}

      {/* Items table skeleton */}
      <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 p-5 space-y-3">
        <Sk className="h-3.5 w-24" />
        <div className="space-y-2">
          {Array.from({ length: 4 }).map((_, i) => (
            <Sk key={i} className="h-10 w-full rounded-lg" />
          ))}
        </div>
      </div>
    </div>
  );
}

function InfoField({ label, value }) {
  if (value === null || value === undefined || value === "") return null;
  return (
    <div>
      <p className="text-xs text-gray-400 mb-0.5">{label}</p>
      <p className="text-sm font-medium text-gray-800 dark:text-gray-200">{value}</p>
    </div>
  );
}

function SectionCard({ title, children }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 p-5"
    >
      {title && (
        <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-4">{title}</p>
      )}
      {children}
    </motion.div>
  );
}

const ERP_ERRORS = {
  ERP_TIMEOUT: {
    icon: WifiOff,
    color: "amber",
    title: "ERP Server Timed Out",
    message: "The ERP server did not respond in time.",
    hint: "This is usually a temporary issue. Please try again in a moment, or contact the ERP team if it keeps happening.",
    canRetry: true,
  },
  ERP_ERROR: {
    icon: ServerCrash,
    color: "red",
    title: "ERP Server Error",
    message: "The ERP server returned an unexpected error.",
    hint: "Please contact the ERP team and share the quotation ID so they can investigate.",
    canRetry: true,
  },
  QUOTATION_NOT_FOUND: {
    icon: FileX,
    color: "gray",
    title: "Quotation Not Found",
    message: "This quotation does not exist in the ERP.",
    hint: "The quotation may have been deleted or the ID is incorrect.",
    canRetry: false,
  },
  INTERNAL_ERROR: {
    icon: ServerCrash,
    color: "red",
    title: "Something Went Wrong",
    message: "An internal server error occurred.",
    hint: "Please try again. If the problem persists, contact support.",
    canRetry: true,
  },
};

const COLOR_MAP = {
  amber: {
    bg:   "bg-amber-50 dark:bg-amber-900/20",
    border: "border-amber-200 dark:border-amber-800",
    icon: "text-amber-500",
    title: "text-amber-800 dark:text-amber-300",
    hint: "text-amber-600 dark:text-amber-400",
    btn: "bg-amber-500 hover:bg-amber-600 text-white",
  },
  red: {
    bg:   "bg-red-50 dark:bg-red-900/20",
    border: "border-red-200 dark:border-red-800",
    icon: "text-red-500",
    title: "text-red-800 dark:text-red-300",
    hint: "text-red-600 dark:text-red-400",
    btn: "bg-red-500 hover:bg-red-600 text-white",
  },
  gray: {
    bg:   "bg-gray-50 dark:bg-gray-800",
    border: "border-gray-200 dark:border-gray-700",
    icon: "text-gray-400",
    title: "text-gray-700 dark:text-gray-300",
    hint: "text-gray-500 dark:text-gray-400",
    btn: "bg-gray-500 hover:bg-gray-600 text-white",
  },
};

export default function QuotationDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [errorInfo, setErrorInfo] = useState(null);

  const load = async () => {
    setLoading(true);
    setErrorInfo(null);
    try {
      const token = localStorage.getItem("token");
      const res = await axios.get(`${API_BASE_URL}/erp/quotations/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.data.success) {
        setData(res.data.data);
      } else {
        const code = res.data.error_code;
        setErrorInfo(ERP_ERRORS[code] || { ...ERP_ERRORS.INTERNAL_ERROR, message: res.data.message });
      }
    } catch (e) {
      console.error(e);
      const code = e.response?.data?.error_code;
      const fallbackMsg = e.response?.data?.message || "Failed to load quotation.";
      setErrorInfo(ERP_ERRORS[code] || { ...ERP_ERRORS.INTERNAL_ERROR, message: fallbackMsg });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, [id]);

  if (loading) {
    return (
      <PageTransition>
        <SkeletonPage />
      </PageTransition>
    );
  }

  if (errorInfo || !data) {
    const info = errorInfo || ERP_ERRORS.INTERNAL_ERROR;
    const Icon = info.icon;
    const c = COLOR_MAP[info.color] || COLOR_MAP.red;
    return (
      <PageTransition>
        <div className="p-4 md:p-6 max-w-5xl mx-auto">
          <button
            onClick={() => navigate(-1)}
            className="flex items-center gap-2 text-sm text-gray-500 hover:text-gray-800 dark:hover:text-white mb-8 transition-colors"
          >
            <ArrowLeft size={16} /> Back to Quotations
          </button>
          <div className={`rounded-2xl border ${c.bg} ${c.border} p-8 max-w-lg mx-auto text-center`}>
            <div className={`inline-flex items-center justify-center w-16 h-16 rounded-2xl mb-4 ${c.bg} border ${c.border}`}>
              <Icon size={32} className={c.icon} />
            </div>
            <h2 className={`text-lg font-bold mb-1 ${c.title}`}>{info.title}</h2>
            <p className="text-sm text-gray-600 dark:text-gray-400 mb-2">{info.message}</p>
            <p className={`text-xs mb-6 ${c.hint}`}>{info.hint}</p>
            <div className="flex gap-3 justify-center">
              {info.canRetry && (
                <button
                  onClick={load}
                  className={`flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold transition-colors ${c.btn}`}
                >
                  <RefreshCw size={14} /> Try Again
                </button>
              )}
              <button
                onClick={() => navigate(-1)}
                className="flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold bg-white dark:bg-gray-700 border border-gray-200 dark:border-gray-600 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-600 transition-colors"
              >
                <ArrowLeft size={14} /> Go Back
              </button>
            </div>
          </div>
        </div>
      </PageTransition>
    );
  }

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-5xl mx-auto space-y-5">

        {/* Header */}
        <div className="flex items-start gap-3">
          <button
            onClick={() => navigate(-1)}
            className="mt-0.5 p-2 rounded-xl bg-white dark:bg-gray-800 border border-gray-100 dark:border-gray-700 text-gray-500 hover:text-gray-900 dark:hover:text-white hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors shrink-0"
          >
            <ArrowLeft size={18} />
          </button>
          <div>
            <h1 className="text-xl font-bold text-gray-900 dark:text-white font-mono">{data.quot_no}</h1>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-0.5">{data.customer?.name}</p>
          </div>
        </div>

        {/* Badges */}
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="flex flex-wrap gap-2">
          <span className={`px-3 py-1 rounded-full text-xs font-semibold ${STATUS_COLORS[data.quotation_status] || "bg-gray-100 text-gray-600"}`}>
            {data.quotation_status}
          </span>
          {data.priority && (
            <span className={`px-3 py-1 rounded-full text-xs font-semibold ${PRIORITY_COLORS[data.priority] || "bg-gray-100 text-gray-600"}`}>
              {data.priority} Priority
            </span>
          )}
          {data.category && (
            <span className="px-3 py-1 rounded-full text-xs font-semibold bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400">
              {data.category}
            </span>
          )}
          {data.is_amended && (
            <span className="px-3 py-1 rounded-full text-xs font-semibold bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400">
              Amended
            </span>
          )}
        </motion.div>

        {/* Subject */}
        {data.subject && (
          <motion.div
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-xl border border-blue-100 dark:border-blue-800"
          >
            <p className="text-xs text-blue-400 mb-1">Subject</p>
            <p className="text-sm text-blue-900 dark:text-blue-200">{data.subject}</p>
          </motion.div>
        )}

        {/* Quotation Details */}
        <SectionCard title="Quotation Details">
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            <InfoField label="Quotation No." value={data.quot_no} />
            <InfoField label="Date" value={data.date} />
            <InfoField label="Enquiry No." value={data.enquiry_no} />
            <InfoField label="Enquiry Date" value={data.enquiry_date} />
            <InfoField label="Financial Year" value={data.financial_year} />
            <InfoField label="Currency" value={data.currency} />
            <InfoField label="Plant" value={data.plant} />
            <InfoField label="Sector" value={data.sector} />
            <InfoField label="Enquiry Status" value={data.enquiry_status} />
            {data.version_no != null && <InfoField label="Version" value={`v${data.version_no}`} />}
          </div>
        </SectionCard>

        {/* Customer */}
        <SectionCard title="Customer">
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            <InfoField label="Name" value={data.customer?.name} />
            <InfoField label="Code" value={data.customer?.code} />
            <InfoField label="Kind Attention" value={data.kind_attention} />
            <InfoField label="Email" value={data.email} />
            {data.bill_to?.name && data.bill_to.name !== data.customer?.name && (
              <InfoField label="Bill To" value={data.bill_to.name} />
            )}
            {data.ship_to?.name && data.ship_to.name !== data.customer?.name && (
              <InfoField label="Ship To" value={data.ship_to.name} />
            )}
          </div>
        </SectionCard>

        {/* Prepared / Entered */}
        {(data.prepared_by || data.entered_by) && (
          <SectionCard title="Prepared By">
            <div className="grid grid-cols-2 gap-4">
              <InfoField label="Prepared By" value={data.prepared_by} />
              <InfoField label="Entered By" value={data.entered_by} />
            </div>
          </SectionCard>
        )}

        {/* Authorization */}
        {data.authorization && (data.authorization.auth1_by || data.authorization.auth2_by) && (
          <SectionCard title="Authorization">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {data.authorization.auth1_by && (
                <div className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-700/50 rounded-xl">
                  {data.authorization.auth1_status === "Y"
                    ? <CheckCircle size={18} className="text-emerald-500 shrink-0" />
                    : <Clock size={18} className="text-amber-500 shrink-0" />}
                  <div>
                    <p className="text-xs text-gray-400">Auth 1</p>
                    <p className="text-sm font-semibold text-gray-800 dark:text-gray-200">{data.authorization.auth1_by}</p>
                    {data.authorization.auth1_date && <p className="text-xs text-gray-400">{data.authorization.auth1_date}</p>}
                  </div>
                </div>
              )}
              {data.authorization.auth2_by && (
                <div className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-700/50 rounded-xl">
                  {data.authorization.auth2_status === "Y"
                    ? <CheckCircle size={18} className="text-emerald-500 shrink-0" />
                    : <Clock size={18} className="text-amber-500 shrink-0" />}
                  <div>
                    <p className="text-xs text-gray-400">Auth 2</p>
                    <p className="text-sm font-semibold text-gray-800 dark:text-gray-200">{data.authorization.auth2_by}</p>
                    {data.authorization.auth2_date && <p className="text-xs text-gray-400">{data.authorization.auth2_date}</p>}
                  </div>
                </div>
              )}
            </div>
          </SectionCard>
        )}

        {/* Cancellation */}
        {data.cancel_info && (
          <motion.div
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            className="p-4 bg-red-50 dark:bg-red-900/20 rounded-2xl border border-red-100 dark:border-red-800"
          >
            <div className="flex items-center gap-2 mb-3">
              <AlertCircle size={16} className="text-red-500" />
              <p className="text-sm font-semibold text-red-700 dark:text-red-400">Cancellation</p>
            </div>
            <div className="grid grid-cols-2 gap-3 text-sm">
              {data.cancel_info.cancelled_by && (
                <div><p className="text-xs text-gray-400">Cancelled By</p><p className="font-medium text-gray-800 dark:text-gray-200">{data.cancel_info.cancelled_by}</p></div>
              )}
              {data.cancel_info.cancelled_date && (
                <div><p className="text-xs text-gray-400">Date</p><p className="font-medium text-gray-800 dark:text-gray-200">{data.cancel_info.cancelled_date}</p></div>
              )}
              {data.cancel_info.remark && (
                <div className="col-span-2"><p className="text-xs text-gray-400">Remark</p><p className="font-medium text-gray-800 dark:text-gray-200">{data.cancel_info.remark}</p></div>
              )}
            </div>
          </motion.div>
        )}

        {/* Items */}
        {data.items && data.items.length > 0 && (
          <SectionCard title={`Items (${data.items.length})`}>
            <div className="overflow-x-auto -mx-1">
              <table className="w-full text-sm min-w-[620px]">
                <thead>
                  <tr className="border-b border-gray-100 dark:border-gray-700">
                    <th className="text-left pb-2.5 text-xs text-gray-400 font-medium pr-4">#</th>
                    <th className="text-left pb-2.5 text-xs text-gray-400 font-medium pr-4">Description</th>
                    <th className="text-left pb-2.5 text-xs text-gray-400 font-medium pr-4">Code</th>
                    <th className="text-right pb-2.5 text-xs text-gray-400 font-medium pr-4">Qty</th>
                    <th className="text-right pb-2.5 text-xs text-gray-400 font-medium pr-4">Rate</th>
                    <th className="text-right pb-2.5 text-xs text-gray-400 font-medium">Total</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 dark:divide-gray-700/60">
                  {data.items.map((item, idx) => (
                    <tr key={item.line_id ?? idx} className="hover:bg-gray-50 dark:hover:bg-gray-700/20 transition-colors">
                      <td className="py-3 pr-4 text-gray-400 text-xs">{idx + 1}</td>
                      <td className="py-3 pr-4 text-gray-700 dark:text-gray-300">
                        <p>{item.description}</p>
                        {item.note && <p className="text-xs text-gray-400 mt-0.5">{item.note}</p>}
                        {item.hsn_code && <p className="text-xs text-gray-400 mt-0.5">HSN: {item.hsn_code}</p>}
                      </td>
                      <td className="py-3 pr-4 font-mono text-xs text-blue-500 whitespace-nowrap">{item.item_code}</td>
                      <td className="py-3 pr-4 text-right text-gray-600 dark:text-gray-400 whitespace-nowrap">{item.qty} {item.unit}</td>
                      <td className="py-3 pr-4 text-right text-gray-600 dark:text-gray-400 whitespace-nowrap">₹{Number(item.rate).toLocaleString("en-IN")}</td>
                      <td className="py-3 text-right font-semibold text-gray-800 dark:text-gray-200 whitespace-nowrap">₹{Number(item.total).toLocaleString("en-IN")}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Financial summary */}
            <div className="mt-5 pt-4 border-t border-gray-100 dark:border-gray-700 flex flex-col items-end gap-1.5 text-sm">
              {data.discount_amt > 0 && (
                <div className="flex justify-between w-full max-w-xs text-gray-500">
                  <span>Discount ({data.discount_per}%)</span>
                  <span>- ₹{Number(data.discount_amt).toLocaleString("en-IN")}</span>
                </div>
              )}
              {data.gst?.cgst_amt > 0 && (
                <div className="flex justify-between w-full max-w-xs text-gray-500">
                  <span>CGST ({data.gst.cgst_per}%)</span>
                  <span>₹{Number(data.gst.cgst_amt).toLocaleString("en-IN")}</span>
                </div>
              )}
              {data.gst?.sgst_amt > 0 && (
                <div className="flex justify-between w-full max-w-xs text-gray-500">
                  <span>SGST ({data.gst.sgst_per}%)</span>
                  <span>₹{Number(data.gst.sgst_amt).toLocaleString("en-IN")}</span>
                </div>
              )}
              {data.gst?.igst_amt > 0 && (
                <div className="flex justify-between w-full max-w-xs text-gray-500">
                  <span>IGST ({data.gst.igst_per}%)</span>
                  <span>₹{Number(data.gst.igst_amt).toLocaleString("en-IN")}</span>
                </div>
              )}
              <div className="flex justify-between w-full max-w-xs pt-2 mt-1 border-t border-gray-200 dark:border-gray-600">
                <span className="text-base font-bold text-gray-700 dark:text-gray-300">Net Total</span>
                <span className="text-xl font-bold text-blue-600">₹{Number(data.net_total).toLocaleString("en-IN")}</span>
              </div>
            </div>
          </SectionCard>
        )}
      </div>
    </PageTransition>
  );
}
