import { useState, useEffect, useRef } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import {
  ArrowLeft, Phone, Mail, Star, Briefcase, Calendar,
  FileText, Download, Eye, Upload, X, Loader2, UserCog,
  CheckCircle, AlertTriangle, Clock, MoreVertical, Pencil,
  Trash2, ChevronLeft, ChevronRight, Plus,
} from "lucide-react";
import axios from "axios";
import { useApp } from "../context/AppContext";
import {
  PageTransition, Badge, Button, Card, Avatar, Select, Input,
  DatePicker, Modal, Textarea, useToast, Toast,
} from "../components/ui";

const API_BASE_URL = "https://apivdti.asynk.in/api";
const DOC_TYPES    = ["Aadhaar Card", "Technician Photo", "WC Policy", "Medical Insurance Policy", "Other"];
const ACCEPTED     = ".pdf,.jpg,.jpeg,.png,.webp,.doc,.docx";
const DOC_PER_PAGE = 10;

const STATUS_STYLES = {
  Active:     { dot: "bg-emerald-500", bg: "bg-emerald-50 dark:bg-emerald-900/20", text: "text-emerald-700 dark:text-emerald-300" },
  "On Leave": { dot: "bg-amber-500",   bg: "bg-amber-50 dark:bg-amber-900/20",   text: "text-amber-700 dark:text-amber-300" },
  Inactive:   { dot: "bg-red-500",     bg: "bg-red-50 dark:bg-red-900/20",       text: "text-red-700 dark:text-red-300" },
};

const EXPIRY_STYLES = {
  expired:       { icon: AlertTriangle, color: "text-red-500",     bg: "bg-red-50 dark:bg-red-900/20",         border: "border-red-200 dark:border-red-800",       label: "Expired" },
  expiring_soon: { icon: Clock,         color: "text-amber-500",   bg: "bg-amber-50 dark:bg-amber-900/20",     border: "border-amber-200 dark:border-amber-800",   label: "Expiring Soon" },
  valid:         { icon: CheckCircle,   color: "text-emerald-500", bg: "bg-emerald-50 dark:bg-emerald-900/20", border: "border-emerald-200 dark:border-emerald-800", label: "Valid" },
};

const JOB_STATUS_COLORS = {
  Raised:        "bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-300",
  Assigned:      "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300",
  "In Progress": "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300",
  Closed:        "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300",
};

function formatDate(raw) {
  if (!raw) return "—";
  const d = new Date(raw);
  if (isNaN(d)) return raw;
  return d.toLocaleDateString("en-IN", { year: "numeric", month: "short", day: "numeric" });
}

let _hsId2 = 0;
function HalfStar({ filled, half, size = 20, color = "#f59e0b" }) {
  const [uid] = useState(() => `hsd${++_hsId2}`);
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <clipPath id={`${uid}l`}><rect x="0" y="0" width="12" height="24" /></clipPath>
        <clipPath id={`${uid}r`}><rect x="12" y="0" width="12" height="24" /></clipPath>
      </defs>
      <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"
        fill={(filled || half) ? color : "none"} stroke={color} strokeWidth="1.5" strokeLinejoin="round" clipPath={`url(#${uid}l)`} />
      <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"
        fill={filled ? color : "none"} stroke={color} strokeWidth="1.5" strokeLinejoin="round" clipPath={`url(#${uid}r)`} />
    </svg>
  );
}

function StarRatingPicker({ value, onChange, size = 28 }) {
  return (
    <div className="flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map((star) => {
        const filled = value >= star;
        const half = !filled && value >= star - 0.5;
        return (
          <div key={star} className="relative cursor-pointer" style={{ width: size, height: size }}>
            <div className="absolute inset-y-0 left-0 w-1/2 z-10" onClick={() => onChange(star - 0.5)} />
            <div className="absolute inset-y-0 right-0 w-1/2 z-10" onClick={() => onChange(star)} />
            <HalfStar filled={filled} half={half} size={size} />
          </div>
        );
      })}
      {value > 0 && <span className="ml-2 text-sm font-bold text-amber-600 dark:text-amber-400">{value}</span>}
    </div>
  );
}

function StarDisplay({ value, size = 14 }) {
  const v = Number(value || 0);
  return (
    <span className="inline-flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map((s) => (
        <HalfStar key={s} filled={v >= s} half={!(v >= s) && v >= s - 0.5} size={size} />
      ))}
    </span>
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
      className="fixed z-[999] w-44 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl shadow-2xl py-1 overflow-hidden"
      style={{ position: "absolute", right: 0, top: "100%", marginTop: 4 }}
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
          <item.icon size={15} />
          {item.label}
        </button>
      ))}
    </motion.div>
  );
}

export default function TechnicianDetail() {
  const { id }      = useParams();
  const navigate    = useNavigate();
  const { currentUser } = useApp();
  const { toast, showToast } = useToast();

  const [tech, setTech]       = useState(null);
  const [loading, setLoading] = useState(true);
  const [tab, setTab]         = useState("documents");

  const [docs, setDocs]               = useState([]);
  const [docsLoading, setDocsLoading] = useState(false);
  const [docPage, setDocPage]         = useState(1);
  const [docMenuOpen, setDocMenuOpen] = useState(null);

  const [uploadOpen, setUploadOpen] = useState(false);
  const [uploading, setUploading]   = useState(false);
  const [docForm, setDocForm]       = useState({ document_type: "", document_name: "", expiry_date: "", notes: "", file: null });
  const docFileRef = useRef();

  const [editDocOpen, setEditDocOpen]       = useState(false);
  const [editDoc, setEditDoc]               = useState(null);
  const [editDocForm, setEditDocForm]       = useState({ document_name: "", expiry_date: "", notes: "" });
  const [editDocSaving, setEditDocSaving]   = useState(false);

  const [deleteDocId, setDeleteDocId] = useState(null);

  // Ratings
  const [ratings, setRatings]               = useState([]);
  const [ratingsLoading, setRatingsLoading] = useState(false);
  const [ratingOpen, setRatingOpen]         = useState(false);
  const [ratingValue, setRatingValue]       = useState(0);
  const [ratingReview, setRatingReview]     = useState("");
  const [ratingSubmitting, setRatingSubmitting] = useState(false);
  const [editRating, setEditRating]         = useState(null);
  const [deleteRatingId, setDeleteRatingId] = useState(null);
  const [ratingMenuOpen, setRatingMenuOpen] = useState(null);

  useEffect(() => { fetchTech(); }, [id]);

  const fetchTech = async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem("token");
      const res = await axios.get(`${API_BASE_URL}/technicians/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.data.success) {
        setTech(res.data.data);
        setDocs(res.data.data.documents || []);
      } else {
        showToast("Technician not found", "error");
      }
    } catch {
      showToast("Failed to load technician", "error");
    } finally {
      setLoading(false);
    }
  };

  const fetchDocs = async () => {
    setDocsLoading(true);
    try {
      const token = localStorage.getItem("token");
      const res = await axios.get(`${API_BASE_URL}/technicians/${id}/documents`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.data.success) setDocs(res.data.data || []);
    } catch {
      showToast("Failed to load documents", "error");
    } finally {
      setDocsLoading(false);
    }
  };

  const handleUploadDoc = async (e) => {
    e.preventDefault();
    if (!docForm.file) { showToast("Please select a file", "error"); return; }
    setUploading(true);
    try {
      const token = localStorage.getItem("token");
      const fd = new FormData();
      fd.append("files", docForm.file);
      const params = new URLSearchParams();
      if (docForm.document_type) params.set("document_type", docForm.document_type);
      if (docForm.document_name) params.set("document_name", docForm.document_name);
      if (docForm.expiry_date)   params.set("expiry_date", docForm.expiry_date);
      if (docForm.notes)         params.set("notes", docForm.notes);

      const uploadRes = await axios.post(
        `${API_BASE_URL}/upload/technician-documents?${params.toString()}`,
        fd,
        { headers: { Authorization: `Bearer ${token}`, "Content-Type": "multipart/form-data" } },
      );
      const uploaded = uploadRes.data.data?.[0] || uploadRes.data.data;

      await axios.post(
        `${API_BASE_URL}/technicians/${id}/documents`,
        {
          document_type: docForm.document_type || undefined,
          document_name: docForm.document_name || uploaded.original_name || docForm.file.name,
          file_name:     uploaded.file_name || uploaded.original_name,
          file_url:      uploaded.file_url,
          mime_type:     uploaded.mime_type || docForm.file.type,
          expiry_date:   docForm.expiry_date || undefined,
          notes:         docForm.notes || undefined,
        },
        { headers: { Authorization: `Bearer ${token}` } },
      );
      showToast("Document uploaded!");
      setUploadOpen(false);
      setDocForm({ document_type: "", document_name: "", expiry_date: "", notes: "", file: null });
      fetchDocs();
    } catch (err) {
      showToast(err.response?.data?.message || "Upload failed", "error");
    } finally {
      setUploading(false);
    }
  };

  const openEditDoc = (doc) => {
    setDocMenuOpen(null);
    setEditDoc(doc);
    setEditDocForm({ document_name: doc.document_name || "", expiry_date: doc.expiry_date ? doc.expiry_date.slice(0, 10) : "", notes: doc.notes || "" });
    setEditDocOpen(true);
  };

  const handleEditDoc = async (e) => {
    e.preventDefault();
    setEditDocSaving(true);
    try {
      const token = localStorage.getItem("token");
      await axios.put(
        `${API_BASE_URL}/technicians/${id}/documents/${editDoc.id}`,
        editDocForm,
        { headers: { Authorization: `Bearer ${token}` } },
      );
      showToast("Document updated!");
      setEditDocOpen(false);
      fetchDocs();
    } catch (err) {
      showToast(err.response?.data?.message || "Update failed", "error");
    } finally {
      setEditDocSaving(false);
    }
  };

  const confirmDeleteDoc = async () => {
    try {
      const token = localStorage.getItem("token");
      await axios.delete(`${API_BASE_URL}/technicians/${id}/documents/${deleteDocId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      showToast("Document deleted");
      setDeleteDocId(null);
      fetchDocs();
    } catch (err) {
      showToast(err.response?.data?.message || "Delete failed", "error");
      setDeleteDocId(null);
    }
  };

  // ── Ratings ──────────────────────────────────────────────
  const fetchRatings = async () => {
    setRatingsLoading(true);
    try {
      const token = localStorage.getItem("token");
      const res = await axios.get(`${API_BASE_URL}/technicians/${id}/ratings`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.data.success) setRatings(res.data.data?.ratings || res.data.data || []);
    } catch {
      showToast("Failed to load ratings", "error");
    } finally {
      setRatingsLoading(false);
    }
  };

  const openAddRating = () => {
    setEditRating(null);
    setRatingValue(0);
    setRatingReview("");
    setRatingOpen(true);
  };

  const openEditRating = (r) => {
    setRatingMenuOpen(null);
    setEditRating(r);
    setRatingValue(r.rating);
    setRatingReview(r.review || "");
    setRatingOpen(true);
  };

  const handleSubmitRating = async (e) => {
    e.preventDefault();
    if (!ratingValue) { showToast("Please select a rating", "error"); return; }
    setRatingSubmitting(true);
    try {
      const token = localStorage.getItem("token");
      if (editRating) {
        await axios.put(
          `${API_BASE_URL}/technicians/${id}/ratings/${editRating.id}`,
          { rating: ratingValue, review: ratingReview || undefined },
          { headers: { Authorization: `Bearer ${token}` } },
        );
        showToast("Rating updated!");
      } else {
        await axios.post(
          `${API_BASE_URL}/technicians/${id}/ratings`,
          { rating: ratingValue, review: ratingReview || undefined },
          { headers: { Authorization: `Bearer ${token}` } },
        );
        showToast("Rating submitted!");
      }
      setRatingOpen(false);
      fetchRatings();
      fetchTech();
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to save rating", "error");
    } finally {
      setRatingSubmitting(false);
    }
  };

  const confirmDeleteRating = async () => {
    try {
      const token = localStorage.getItem("token");
      await axios.delete(`${API_BASE_URL}/technicians/${id}/ratings/${deleteRatingId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      showToast("Rating deleted");
      setDeleteRatingId(null);
      fetchRatings();
      fetchTech();
    } catch (err) {
      showToast(err.response?.data?.message || "Delete failed", "error");
      setDeleteRatingId(null);
    }
  };

  const canEdit = currentUser?.role !== "technician";
  const docTotalPages = Math.max(1, Math.ceil(docs.length / DOC_PER_PAGE));
  const paginatedDocs = docs.slice((docPage - 1) * DOC_PER_PAGE, docPage * DOC_PER_PAGE);

  if (loading) {
    return (
      <PageTransition>
        <div className="p-4 md:p-8 max-w-6xl mx-auto">
          <div className="animate-pulse space-y-6">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-gray-200 dark:bg-gray-700 rounded-xl" />
              <div className="h-7 w-48 bg-gray-200 dark:bg-gray-700 rounded-xl" />
            </div>
            <div className="h-40 bg-gray-100 dark:bg-gray-800 rounded-2xl" />
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {[...Array(4)].map((_, i) => <div key={i} className="h-24 bg-gray-100 dark:bg-gray-800 rounded-2xl" />)}
            </div>
            <div className="h-64 bg-gray-100 dark:bg-gray-800 rounded-2xl" />
          </div>
        </div>
      </PageTransition>
    );
  }

  if (!tech) {
    return (
      <PageTransition>
        <div className="p-8 text-center text-gray-400">
          <UserCog size={40} className="mx-auto mb-3 opacity-30" />
          <p className="font-medium">Technician not found</p>
          <Button className="mt-4" onClick={() => navigate("/technicians")}>Back to Technicians</Button>
        </div>
      </PageTransition>
    );
  }

  const ss = STATUS_STYLES[tech.status] || STATUS_STYLES.Active;

  return (
    <PageTransition>
      <div className="p-4 md:p-8 max-w-6xl mx-auto space-y-5">

        {/* Header */}
        <div className="flex items-start gap-3">
          <button
            onClick={() => navigate("/technicians")}
            className="mt-1 p-2 rounded-xl text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-800 transition flex-shrink-0"
          >
            <ArrowLeft size={20} />
          </button>
          <div className="flex-1 min-w-0">
            <div className="flex flex-wrap items-center gap-3">
              <Avatar initials={tech.avatar || tech.name?.slice(0, 2).toUpperCase() || "??"} size="lg" />
              <div className="min-w-0 flex-1">
                <h1 className="text-xl md:text-2xl font-bold text-gray-900 dark:text-white leading-tight truncate">{tech.name}</h1>
                <p className="text-blue-600 dark:text-blue-400 text-sm font-medium">{tech.specialization}</p>
              </div>
              <div className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-xs md:text-sm font-semibold ${ss.bg} ${ss.text}`}>
                <span className={`w-2 h-2 rounded-full ${ss.dot}`} />
                {tech.status}
              </div>
            </div>
          </div>
        </div>

        {/* Info cards */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          <Card className="p-3 md:p-4">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 md:w-10 md:h-10 rounded-xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center flex-shrink-0">
                <Phone size={16} className="text-blue-500" />
              </div>
              <div className="min-w-0">
                <p className="text-[11px] text-gray-400 font-medium">Phone</p>
                <p className="text-xs md:text-sm font-semibold text-gray-800 dark:text-gray-200 truncate">{tech.phone}</p>
              </div>
            </div>
          </Card>
          <Card className="p-3 md:p-4">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 md:w-10 md:h-10 rounded-xl bg-purple-50 dark:bg-purple-900/20 flex items-center justify-center flex-shrink-0">
                <Mail size={16} className="text-purple-500" />
              </div>
              <div className="min-w-0">
                <p className="text-[11px] text-gray-400 font-medium">Email</p>
                <p className="text-xs md:text-sm font-semibold text-gray-800 dark:text-gray-200 truncate">{tech.email || "—"}</p>
              </div>
            </div>
          </Card>
          <Card className="p-3 md:p-4">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 md:w-10 md:h-10 rounded-xl bg-emerald-50 dark:bg-emerald-900/20 flex items-center justify-center flex-shrink-0">
                <Calendar size={16} className="text-emerald-500" />
              </div>
              <div className="min-w-0">
                <p className="text-[11px] text-gray-400 font-medium">Joined</p>
                <p className="text-xs md:text-sm font-semibold text-gray-800 dark:text-gray-200 truncate">{formatDate(tech.join_date)}</p>
              </div>
            </div>
          </Card>
          <Card className="p-3 md:p-4">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 md:w-10 md:h-10 rounded-xl bg-amber-50 dark:bg-amber-900/20 flex items-center justify-center flex-shrink-0">
                <Star size={16} className="text-amber-500" />
              </div>
              <div className="min-w-0">
                <p className="text-[11px] text-gray-400 font-medium">Rating</p>
                <p className="text-xs md:text-sm font-semibold text-gray-800 dark:text-gray-200">{tech.rating ? `${Number(tech.rating).toFixed(1)} / 5` : "No ratings"}</p>
              </div>
            </div>
          </Card>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {[
            { label: "Jobs Done", value: tech.jobs_completed ?? 0 },
            { label: "Rating", value: <span className="flex items-center justify-center gap-1"><StarDisplay value={tech.rating} size={12} /><span className="text-xs">{Number(tech.rating || 0).toFixed(1)}</span></span> },
            { label: "Documents", value: docs.length },
            { label: "Recent Jobs", value: tech.recent_jobs?.length ?? 0 },
          ].map((s) => (
            <Card key={s.label} className="p-3 md:p-4 text-center">
              <p className="text-xl md:text-2xl font-bold text-gray-900 dark:text-white">{s.value}</p>
              <p className="text-[11px] md:text-xs text-gray-400 mt-0.5">{s.label}</p>
            </Card>
          ))}
        </div>

        {/* Tabs */}
        <div className="flex gap-1 bg-gray-100 dark:bg-gray-800 rounded-xl p-1">
          {[
            { key: "documents", label: "Documents", icon: FileText, count: docs.length },
            { key: "ratings",   label: "Ratings",     icon: Star,     count: ratings.length },
            { key: "jobs",      label: "Recent Jobs", icon: Briefcase, count: tech.recent_jobs?.length },
          ].map((t) => (
            <button
              key={t.key}
              onClick={() => setTab(t.key)}
              className={`flex-1 flex items-center justify-center gap-1.5 py-2.5 px-3 rounded-lg text-xs md:text-sm font-semibold transition-all ${
                tab === t.key
                  ? "bg-white dark:bg-gray-700 text-gray-900 dark:text-white shadow-sm"
                  : "text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200"
              }`}
            >
              <t.icon size={14} />
              <span className="hidden sm:inline">{t.label}</span>
              <span className="sm:hidden">{t.key === "documents" ? "Docs" : t.key === "ratings" ? "Ratings" : "Jobs"}</span>
              {t.count > 0 && (
                <span className={`text-[10px] px-1.5 py-0.5 rounded-full ${
                  tab === t.key ? "bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-300" : "bg-gray-200 text-gray-500 dark:bg-gray-700 dark:text-gray-400"
                }`}>
                  {t.count}
                </span>
              )}
            </button>
          ))}
        </div>

        {/* ── Documents Tab ── */}
        {tab === "documents" && (
          <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="space-y-4">
            {canEdit && (
              <div className="flex justify-end">
                <Button onClick={() => setUploadOpen(true)} size="sm">
                  <Plus size={14} /> Upload Document
                </Button>
              </div>
            )}

            {docsLoading ? (
              <Card className="p-12 flex justify-center">
                <Loader2 size={24} className="animate-spin text-blue-500" />
              </Card>
            ) : docs.length === 0 ? (
              <Card className="p-8 text-center">
                <FileText size={32} className="mx-auto mb-3 text-gray-300 dark:text-gray-600" />
                <p className="text-gray-500 dark:text-gray-400 font-medium">No documents uploaded</p>
                <p className="text-sm text-gray-400 mt-1">Upload Aadhaar, WC Policy, or other documents here.</p>
              </Card>
            ) : (
              <>
                {/* Desktop table */}
                <div className="hidden md:block">
                  <Card>
                    <div className="grid grid-cols-12 gap-3 px-5 py-3 bg-gray-50 dark:bg-gray-800/80 border-b border-gray-100 dark:border-gray-700 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      <div className="col-span-4">Document</div>
                      <div className="col-span-2">Type</div>
                      <div className="col-span-2">Expiry</div>
                      <div className="col-span-2">Status</div>
                      <div className="col-span-2 text-right">Actions</div>
                    </div>
                    <div className="divide-y divide-gray-100 dark:divide-gray-700">
                      {paginatedDocs.map((doc) => {
                        const es = EXPIRY_STYLES[doc.expiry_status] || EXPIRY_STYLES.valid;
                        const ExpiryIcon = es.icon;
                        const isImage = doc.mime_type?.startsWith("image/");

                        return (
                          <div key={doc.id} className="grid grid-cols-12 gap-3 px-5 py-4 items-center hover:bg-gray-50/50 dark:hover:bg-gray-800/30 transition">
                            <div className="col-span-4 flex items-center gap-3 min-w-0">
                              <div className="w-10 h-10 rounded-xl bg-gray-100 dark:bg-gray-700 flex items-center justify-center flex-shrink-0 overflow-hidden">
                                {isImage ? (
                                  <img src={doc.file_url} alt="" className="w-full h-full object-cover rounded-xl" onError={(e) => { e.target.style.display = "none"; e.target.parentNode.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-gray-400"><path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/></svg>'; }} />
                                ) : (
                                  <FileText size={18} className="text-gray-400" />
                                )}
                              </div>
                              <div className="min-w-0">
                                <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">{doc.document_name}</p>
                                <div className="flex items-center gap-2 mt-0.5">
                                  {doc.file_name && <span className="text-[11px] text-gray-400 truncate max-w-[140px]">{doc.file_name}</span>}
                                  {doc.file_size_bytes > 0 && <span className="text-[11px] text-gray-400 flex-shrink-0">{(doc.file_size_bytes / 1024).toFixed(0)} KB</span>}
                                </div>
                              </div>
                            </div>

                            <div className="col-span-2">
                              <span className="inline-flex items-center text-xs font-medium text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/20 px-2 py-0.5 rounded-full">
                                {doc.document_type}
                              </span>
                            </div>

                            <div className="col-span-2">
                              <p className="text-sm text-gray-600 dark:text-gray-300">{formatDate(doc.expiry_date)}</p>
                            </div>

                            <div className="col-span-2">
                              {doc.expiry_date ? (
                                <div className={`inline-flex items-center gap-1.5 text-xs font-medium px-2 py-1 rounded-lg border ${es.bg} ${es.border} ${es.color}`}>
                                  <ExpiryIcon size={12} />
                                  {es.label}
                                </div>
                              ) : (
                                <span className="text-xs text-gray-400">—</span>
                              )}
                            </div>

                            <div className="col-span-2 flex justify-end">
                              <div className="relative" style={{ zIndex: docMenuOpen === doc.id ? 50 : 1 }}>
                                <button
                                  onClick={() => setDocMenuOpen(docMenuOpen === doc.id ? null : doc.id)}
                                  className="p-2 rounded-lg text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition"
                                >
                                  <MoreVertical size={16} />
                                </button>
                                <AnimatePresence>
                                  {docMenuOpen === doc.id && (
                                    <ActionMenu
                                      onClose={() => setDocMenuOpen(null)}
                                      items={[
                                        ...(doc.file_url ? [
                                          { label: "View", icon: Eye, onClick: () => { setDocMenuOpen(null); window.open(doc.file_url, "_blank"); } },
                                          { label: "Download", icon: Download, onClick: () => {
                                            setDocMenuOpen(null);
                                            const a = document.createElement("a"); a.href = doc.file_url; a.download = doc.file_name || "document"; a.click();
                                          }},
                                        ] : []),
                                        ...(canEdit ? [
                                          { label: "Edit", icon: Pencil, onClick: () => openEditDoc(doc) },
                                          { label: "Delete", icon: Trash2, danger: true, onClick: () => { setDocMenuOpen(null); setDeleteDocId(doc.id); } },
                                        ] : []),
                                      ]}
                                    />
                                  )}
                                </AnimatePresence>
                              </div>
                            </div>
                          </div>
                        );
                      })}
                    </div>

                    {docTotalPages > 1 && (
                      <div className="px-5 py-3 border-t border-gray-100 dark:border-gray-700 flex items-center justify-between gap-3">
                        <p className="text-xs text-gray-500 dark:text-gray-400">
                          {(docPage - 1) * DOC_PER_PAGE + 1}–{Math.min(docPage * DOC_PER_PAGE, docs.length)} of {docs.length}
                        </p>
                        <div className="flex gap-1.5">
                          <Button variant="secondary" size="sm" disabled={docPage === 1} onClick={() => setDocPage(p => p - 1)}>
                            <ChevronLeft size={14} />
                          </Button>
                          {[...Array(docTotalPages)].map((_, i) => {
                            const n = i + 1;
                            if (docTotalPages > 5 && (n < docPage - 1 || n > docPage + 1) && n !== 1 && n !== docTotalPages) {
                              if (n === 2 || n === docTotalPages - 1) return <span key={n} className="px-1 text-gray-400 self-center text-xs">...</span>;
                              return null;
                            }
                            return (
                              <button key={n} onClick={() => setDocPage(n)} className={`w-7 h-7 rounded-lg text-xs font-medium transition-all ${docPage === n ? "bg-blue-600 text-white" : "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"}`}>
                                {n}
                              </button>
                            );
                          })}
                          <Button variant="secondary" size="sm" disabled={docPage === docTotalPages} onClick={() => setDocPage(p => p + 1)}>
                            <ChevronRight size={14} />
                          </Button>
                        </div>
                      </div>
                    )}
                  </Card>
                </div>

                {/* Mobile card list */}
                <div className="md:hidden space-y-3">
                  {paginatedDocs.map((doc) => {
                    const es = EXPIRY_STYLES[doc.expiry_status] || EXPIRY_STYLES.valid;
                    const ExpiryIcon = es.icon;
                    const isImage = doc.mime_type?.startsWith("image/");

                    return (
                      <Card key={doc.id} className="p-4">
                        <div className="flex items-start gap-3">
                          <div className="w-12 h-12 rounded-xl bg-gray-100 dark:bg-gray-700 flex items-center justify-center flex-shrink-0 overflow-hidden">
                            {isImage ? (
                              <img src={doc.file_url} alt="" className="w-full h-full object-cover rounded-xl" onError={(e) => { e.target.style.display = "none"; }} />
                            ) : (
                              <FileText size={20} className="text-gray-400" />
                            )}
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-start justify-between gap-2">
                              <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">{doc.document_name}</p>
                              <div className="relative flex-shrink-0" style={{ zIndex: docMenuOpen === doc.id ? 50 : 1 }}>
                                <button
                                  onClick={() => setDocMenuOpen(docMenuOpen === doc.id ? null : doc.id)}
                                  className="p-1.5 rounded-lg text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition"
                                >
                                  <MoreVertical size={16} />
                                </button>
                                <AnimatePresence>
                                  {docMenuOpen === doc.id && (
                                    <ActionMenu
                                      onClose={() => setDocMenuOpen(null)}
                                      items={[
                                        ...(doc.file_url ? [
                                          { label: "View", icon: Eye, onClick: () => { setDocMenuOpen(null); window.open(doc.file_url, "_blank"); } },
                                          { label: "Download", icon: Download, onClick: () => {
                                            setDocMenuOpen(null);
                                            const a = document.createElement("a"); a.href = doc.file_url; a.download = doc.file_name || "document"; a.click();
                                          }},
                                        ] : []),
                                        ...(canEdit ? [
                                          { label: "Edit", icon: Pencil, onClick: () => openEditDoc(doc) },
                                          { label: "Delete", icon: Trash2, danger: true, onClick: () => { setDocMenuOpen(null); setDeleteDocId(doc.id); } },
                                        ] : []),
                                      ]}
                                    />
                                  )}
                                </AnimatePresence>
                              </div>
                            </div>

                            <div className="flex flex-wrap items-center gap-2 mt-1.5">
                              <span className="inline-flex items-center text-[11px] font-medium text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/20 px-2 py-0.5 rounded-full">
                                {doc.document_type}
                              </span>
                              {doc.expiry_date && (
                                <div className={`inline-flex items-center gap-1 text-[11px] font-medium px-1.5 py-0.5 rounded-md border ${es.bg} ${es.border} ${es.color}`}>
                                  <ExpiryIcon size={10} />
                                  {es.label}
                                </div>
                              )}
                            </div>

                            <div className="flex flex-wrap items-center gap-x-3 gap-y-1 mt-2 text-[11px] text-gray-400">
                              {doc.expiry_date && <span>Expiry: {formatDate(doc.expiry_date)}</span>}
                              {doc.file_size_bytes > 0 && <span>{(doc.file_size_bytes / 1024).toFixed(0)} KB</span>}
                              {doc.file_name && <span className="truncate max-w-[150px]">{doc.file_name}</span>}
                            </div>

                            {doc.notes && (
                              <p className="text-[11px] text-gray-400 mt-1.5 line-clamp-2">{doc.notes}</p>
                            )}
                          </div>
                        </div>
                      </Card>
                    );
                  })}

                  {/* Mobile pagination */}
                  {docTotalPages > 1 && (
                    <div className="flex items-center justify-between pt-2">
                      <p className="text-xs text-gray-500">{(docPage - 1) * DOC_PER_PAGE + 1}–{Math.min(docPage * DOC_PER_PAGE, docs.length)} of {docs.length}</p>
                      <div className="flex gap-1.5">
                        <Button variant="secondary" size="sm" disabled={docPage === 1} onClick={() => setDocPage(p => p - 1)}>
                          <ChevronLeft size={14} />
                        </Button>
                        <span className="self-center text-xs font-medium text-gray-600 dark:text-gray-300 px-1">{docPage}/{docTotalPages}</span>
                        <Button variant="secondary" size="sm" disabled={docPage === docTotalPages} onClick={() => setDocPage(p => p + 1)}>
                          <ChevronRight size={14} />
                        </Button>
                      </div>
                    </div>
                  )}
                </div>
              </>
            )}
          </motion.div>
        )}

        {/* ── Ratings Tab ── */}
        {tab === "ratings" && (
          <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="space-y-4"
            onAnimationComplete={() => { if (ratings.length === 0 && !ratingsLoading) fetchRatings(); }}
          >
            <div className="flex items-center justify-between">
              <div>
                <div className="flex items-center gap-2">
                  <StarDisplay value={tech.rating} size={18} />
                  <span className="text-lg font-bold text-gray-900 dark:text-white">{Number(tech.rating || 0).toFixed(1)}</span>
                  <span className="text-sm text-gray-400">/ 5</span>
                </div>
              </div>
              <Button onClick={openAddRating} size="sm">
                <Plus size={14} /> Add Rating
              </Button>
            </div>

            {ratingsLoading ? (
              <Card className="p-12 flex justify-center">
                <Loader2 size={24} className="animate-spin text-blue-500" />
              </Card>
            ) : ratings.length === 0 ? (
              <Card className="p-8 text-center">
                <Star size={32} className="mx-auto mb-3 text-gray-300 dark:text-gray-600" />
                <p className="text-gray-500 dark:text-gray-400 font-medium">No ratings yet</p>
                <p className="text-sm text-gray-400 mt-1">Be the first to rate this technician.</p>
              </Card>
            ) : (
              <div className="space-y-3">
                {ratings.map((r) => (
                  <Card key={r.id} className="p-4">
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex-1 min-w-0">
                        <div className="flex flex-wrap items-center gap-2 mb-1">
                          <StarDisplay value={r.rating} size={14} />
                          <span className="text-sm font-bold text-amber-600 dark:text-amber-400">{r.rating}</span>
                          {r.job_id && (
                            <span className="text-xs font-mono text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/20 px-1.5 py-0.5 rounded">
                              {r.job_id}
                            </span>
                          )}
                        </div>
                        {r.review && (
                          <p className="text-sm text-gray-600 dark:text-gray-300 mt-1">{r.review}</p>
                        )}
                        <div className="flex flex-wrap items-center gap-x-3 gap-y-1 mt-2 text-[11px] text-gray-400">
                          {r.rated_by_name && <span>by {r.rated_by_name}</span>}
                          {r.created_at && <span>{formatDate(r.created_at)}</span>}
                        </div>
                      </div>
                      <div className="relative flex-shrink-0" style={{ zIndex: ratingMenuOpen === r.id ? 50 : 1 }}>
                        <button
                          onClick={() => setRatingMenuOpen(ratingMenuOpen === r.id ? null : r.id)}
                          className="p-1.5 rounded-lg text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition"
                        >
                          <MoreVertical size={16} />
                        </button>
                        <AnimatePresence>
                          {ratingMenuOpen === r.id && (
                            <ActionMenu
                              onClose={() => setRatingMenuOpen(null)}
                              items={[
                                { label: "Edit", icon: Pencil, onClick: () => openEditRating(r) },
                                { label: "Delete", icon: Trash2, danger: true, onClick: () => { setRatingMenuOpen(null); setDeleteRatingId(r.id); } },
                              ]}
                            />
                          )}
                        </AnimatePresence>
                      </div>
                    </div>
                  </Card>
                ))}
              </div>
            )}
          </motion.div>
        )}

        {/* ── Recent Jobs Tab ── */}
        {tab === "jobs" && (
          <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="space-y-3">
            {(!tech.recent_jobs || tech.recent_jobs.length === 0) ? (
              <Card className="p-8 text-center">
                <Briefcase size={32} className="mx-auto mb-3 text-gray-300 dark:text-gray-600" />
                <p className="text-gray-500 dark:text-gray-400 font-medium">No recent jobs</p>
              </Card>
            ) : (
              tech.recent_jobs.map((job) => (
                <Card key={job.id} hover className="p-4 cursor-pointer" onClick={() => navigate(`/jobs/${job.id}`)}>
                  <div className="flex items-center justify-between gap-3">
                    <div className="flex items-center gap-3 min-w-0">
                      <div className="w-10 h-10 rounded-xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center flex-shrink-0">
                        <Briefcase size={16} className="text-blue-500" />
                      </div>
                      <div className="min-w-0">
                        <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">{job.title}</p>
                        <div className="flex items-center gap-2 mt-0.5">
                          <span className="text-xs font-mono text-blue-600 dark:text-blue-400">{job.id}</span>
                          {job.closed_date && (
                            <span className="text-xs text-gray-400 flex items-center gap-1">
                              <Calendar size={10} /> {formatDate(job.closed_date)}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                    <span className={`text-xs px-2.5 py-1 rounded-full font-semibold flex-shrink-0 ${JOB_STATUS_COLORS[job.status] || "bg-gray-100 text-gray-600"}`}>
                      {job.status}
                    </span>
                  </div>
                </Card>
              ))
            )}
          </motion.div>
        )}

        {/* Upload Modal */}
        <Modal isOpen={uploadOpen} onClose={() => setUploadOpen(false)} title="Upload Document">
          <form onSubmit={handleUploadDoc} className="space-y-4">
            <input ref={docFileRef} type="file" accept={ACCEPTED} className="hidden" onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) setDocForm(p => ({ ...p, file, document_name: p.document_name || file.name }));
            }} />
            <div
              onClick={() => docFileRef.current?.click()}
              className={`flex items-center gap-3 p-4 rounded-xl border-2 border-dashed cursor-pointer transition-colors ${
                docForm.file
                  ? "border-emerald-300 dark:border-emerald-700 bg-emerald-50 dark:bg-emerald-900/20"
                  : "border-gray-300 dark:border-gray-600 hover:border-blue-400 dark:hover:border-blue-500"
              }`}
            >
              {docForm.file ? (
                <>
                  <div className="w-10 h-10 rounded-xl bg-emerald-100 dark:bg-emerald-900/40 flex items-center justify-center flex-shrink-0">
                    <CheckCircle size={18} className="text-emerald-600 dark:text-emerald-400" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-800 dark:text-gray-200 truncate">{docForm.file.name}</p>
                    <p className="text-xs text-gray-400">{(docForm.file.size / 1024).toFixed(0)} KB</p>
                  </div>
                  <button type="button" onClick={(e) => { e.stopPropagation(); setDocForm(p => ({ ...p, file: null })); }} className="text-gray-400 hover:text-red-500">
                    <X size={16} />
                  </button>
                </>
              ) : (
                <>
                  <div className="w-10 h-10 rounded-xl bg-blue-50 dark:bg-blue-900/30 flex items-center justify-center flex-shrink-0">
                    <Upload size={18} className="text-blue-500" />
                  </div>
                  <div>
                    <p className="text-sm font-medium text-gray-600 dark:text-gray-300">Click to choose a file</p>
                    <p className="text-xs text-gray-400">PDF, JPG, PNG, WebP, DOC — max 20MB</p>
                  </div>
                </>
              )}
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <Select label="Document Type" value={docForm.document_type} onChange={(e) => setDocForm(p => ({ ...p, document_type: e.target.value }))} options={["", ...DOC_TYPES].map(t => ({ value: t, label: t || "Select type..." }))} searchable />
              <Input label="Document Name" value={docForm.document_name} onChange={(e) => setDocForm(p => ({ ...p, document_name: e.target.value }))} placeholder="e.g. Aadhaar Front" />
              <DatePicker label="Expiry Date" value={docForm.expiry_date} onChange={(e) => setDocForm(p => ({ ...p, expiry_date: e.target.value }))} />
              <Input label="Notes" value={docForm.notes} onChange={(e) => setDocForm(p => ({ ...p, notes: e.target.value }))} placeholder="Optional notes" />
            </div>
            <div className="flex gap-3 pt-2">
              <Button type="submit" className="flex-1" disabled={uploading || !docForm.file}>
                {uploading ? <><Loader2 size={15} className="animate-spin" /> Uploading…</> : <><Upload size={15} /> Upload</>}
              </Button>
              <Button variant="secondary" onClick={() => setUploadOpen(false)}>Cancel</Button>
            </div>
          </form>
        </Modal>

        {/* Edit Document Modal */}
        <Modal isOpen={editDocOpen} onClose={() => setEditDocOpen(false)} title="Edit Document" size="sm">
          <form onSubmit={handleEditDoc} className="space-y-4">
            <Input label="Document Name" value={editDocForm.document_name} onChange={(e) => setEditDocForm(p => ({ ...p, document_name: e.target.value }))} placeholder="Document name" required />
            <DatePicker label="Expiry Date" value={editDocForm.expiry_date} onChange={(e) => setEditDocForm(p => ({ ...p, expiry_date: e.target.value }))} />
            <Input label="Notes" value={editDocForm.notes} onChange={(e) => setEditDocForm(p => ({ ...p, notes: e.target.value }))} placeholder="Optional notes" />
            <div className="flex gap-3 pt-2">
              <Button type="submit" className="flex-1" disabled={editDocSaving}>
                {editDocSaving ? "Saving…" : "Update"}
              </Button>
              <Button variant="secondary" onClick={() => setEditDocOpen(false)}>Cancel</Button>
            </div>
          </form>
        </Modal>

        {/* Delete Document Confirm */}
        <Modal isOpen={!!deleteDocId} onClose={() => setDeleteDocId(null)} title="Delete Document" size="sm">
          <p className="text-gray-600 dark:text-gray-300 text-sm mb-5">Are you sure you want to delete this document? This cannot be undone.</p>
          <div className="flex gap-3">
            <Button variant="danger" onClick={confirmDeleteDoc} className="flex-1">Delete</Button>
            <Button variant="secondary" onClick={() => setDeleteDocId(null)}>Cancel</Button>
          </div>
        </Modal>

        {/* Rating Modal */}
        <Modal isOpen={ratingOpen} onClose={() => setRatingOpen(false)} title={editRating ? "Edit Rating" : `Rate ${tech?.name || "Technician"}`} size="sm">
          <form onSubmit={handleSubmitRating} className="space-y-5">
            <div className="text-center">
              <p className="text-sm text-gray-500 dark:text-gray-400 mb-4">Tap to rate — left half for .5, right half for full star</p>
              <div className="flex justify-center">
                <StarRatingPicker value={ratingValue} onChange={setRatingValue} size={36} />
              </div>
            </div>
            <Textarea
              label="Review (optional)"
              value={ratingReview}
              onChange={(e) => setRatingReview(e.target.value)}
              placeholder="Share your experience..."
              rows={3}
            />
            <div className="flex gap-3">
              <Button type="submit" className="flex-1" disabled={ratingSubmitting || !ratingValue}>
                {ratingSubmitting ? "Saving…" : (editRating ? "Update Rating" : "Submit Rating")}
              </Button>
              <Button variant="secondary" onClick={() => setRatingOpen(false)}>Cancel</Button>
            </div>
          </form>
        </Modal>

        {/* Delete Rating Confirm */}
        <Modal isOpen={!!deleteRatingId} onClose={() => setDeleteRatingId(null)} title="Delete Rating" size="sm">
          <p className="text-gray-600 dark:text-gray-300 text-sm mb-5">Are you sure you want to delete this rating?</p>
          <div className="flex gap-3">
            <Button variant="danger" onClick={confirmDeleteRating} className="flex-1">Delete</Button>
            <Button variant="secondary" onClick={() => setDeleteRatingId(null)}>Cancel</Button>
          </div>
        </Modal>

        {toast && <Toast {...toast} onClose={() => {}} />}
      </div>
    </PageTransition>
  );
}
