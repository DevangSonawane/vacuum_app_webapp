import { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import {
  Plus, Pencil, Trash2, Star, UserCog, Phone, Mail, Search,
  Loader2, Eye, EyeOff, Upload, FileText, X, CheckCircle,
  MoreVertical, ChevronLeft, ChevronRight,
} from "lucide-react";
import axios from "axios";
import { useApp } from "../context/AppContext";
import {
  PageTransition, Card, Badge, Avatar, Button, Modal, Input,
  Select, DatePicker, SectionHeader, EmptyState, Textarea, useToast, Toast,
} from "../components/ui";

const API_BASE_URL = "https://apivdti.asynk.in/api";
const PER_PAGE = 10;

const EMPTY_FORM = {
  name: "", email: "", phone: "", specialization: "",
  status: "Active", join_date: "", password: "",
};

const SPECIALIZATIONS = ["ITR"];
const STATUSES        = ["Active", "On Leave", "Inactive"];
const DOC_TYPES       = ["Aadhaar Card", "Technician Photo", "WC Policy", "Medical Insurance Policy", "Other"];
const ACCEPTED_TYPES  = ".pdf,.jpg,.jpeg,.png,.webp,.doc,.docx";

let _hsId = 0;
function HalfStar({ filled, half, size = 20, color = "#f59e0b" }) {
  const [uid] = useState(() => `hs${++_hsId}`);
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
        <HalfStar key={s} filled={v >= s} half={!((v >= s)) && v >= s - 0.5} size={size} />
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
      className="absolute right-0 top-full mt-1 z-50 w-40 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl shadow-xl py-1 overflow-hidden"
    >
      {items.map((item) => (
        <button
          key={item.label}
          onClick={item.onClick}
          className={`w-full flex items-center gap-2 px-3 py-2 text-sm transition-colors ${
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

export default function Technicians() {
  const navigate = useNavigate();
  const { currentUser } = useApp();
  const { toast, showToast } = useToast();

  const [technicians, setTechnicians] = useState([]);
  const [loading, setLoading]         = useState(true);
  const [search, setSearch]           = useState("");
  const [page, setPage]               = useState(1);
  const [modalOpen, setModalOpen]     = useState(false);
  const [editId, setEditId]           = useState(null);
  const [form, setForm]               = useState(EMPTY_FORM);
  const [formLoading, setFormLoading] = useState(false);
  const [deleteId, setDeleteId]       = useState(null);
  const [submitting, setSubmitting]   = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [documents, setDocuments]     = useState([]);
  const [menuOpen, setMenuOpen]       = useState(null);
  const docFileRef = useRef();

  // Rating
  const [ratingOpen, setRatingOpen]         = useState(false);
  const [ratingTech, setRatingTech]         = useState(null);
  const [ratingValue, setRatingValue]       = useState(0);
  const [ratingReview, setRatingReview]     = useState("");
  const [ratingSubmitting, setRatingSubmitting] = useState(false);

  useEffect(() => { fetchTechnicians(); }, []);

  const fetchTechnicians = async (searchTerm = "") => {
    setLoading(true);
    try {
      const token  = localStorage.getItem("token");
      const params = { limit: 100 };
      if (searchTerm) params.search = searchTerm;

      const res = await axios.get(`${API_BASE_URL}/technicians`, {
        headers: { Authorization: `Bearer ${token}` },
        params,
      });
      if (res.data.success) setTechnicians(res.data.data || []);
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to fetch technicians", "error");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    setPage(1);
    const t = setTimeout(() => fetchTechnicians(search), 400);
    return () => clearTimeout(t);
  }, [search]);

  // Pagination
  const totalPages    = Math.max(1, Math.ceil(technicians.length / PER_PAGE));
  const paginatedList = technicians.slice((page - 1) * PER_PAGE, page * PER_PAGE);
  const activeCount   = technicians.filter(t => t.status === "Active").length;

  const openAdd = () => {
    setForm(EMPTY_FORM);
    setEditId(null);
    setShowPassword(false);
    setDocuments([]);
    setModalOpen(true);
  };

  const openEdit = async (tech) => {
    setMenuOpen(null);
    setEditId(tech.id);
    setShowPassword(false);
    setForm({
      name: tech.name || "", email: tech.email || "", phone: tech.phone || "",
      specialization: tech.specialization || "", status: tech.status || "Active",
      join_date: tech.join_date || "", password: "",
    });
    setModalOpen(true);
    setFormLoading(true);
    try {
      const token = localStorage.getItem("token");
      const res = await axios.get(`${API_BASE_URL}/technicians/${tech.id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.data.success) {
        const d = res.data.data;
        setForm({
          name: d.name || "", email: d.email || "", phone: d.phone || "",
          specialization: d.specialization || "", status: d.status || "Active",
          join_date: d.join_date || "", password: "",
        });
      }
    } catch {
      showToast("Could not load latest details, using cached data.", "error");
    } finally {
      setFormLoading(false);
    }
  };

  const f = (field) => (e) => setForm(p => ({ ...p, [field]: e.target.value }));

  // Document helpers
  const addDocRow = () =>
    setDocuments(p => [...p, {
      document_type: "", document_name: "", expiry_date: "", notes: "",
      file: null, uploading: false, uploaded: null, error: null,
    }]);

  const updateDoc = (idx, field, value) =>
    setDocuments(p => p.map((d, i) => i === idx ? { ...d, [field]: value } : d));

  const removeDoc = (idx) => setDocuments(p => p.filter((_, i) => i !== idx));

  const pickDocFile = (idx) => {
    const input = docFileRef.current;
    input.onchange = (e) => {
      const file = e.target.files?.[0];
      if (!file) return;
      updateDoc(idx, "file", file);
      if (!documents[idx].document_name) updateDoc(idx, "document_name", file.name);
      input.value = "";
    };
    input.click();
  };

  const uploadDocFile = async (doc) => {
    const token = localStorage.getItem("token");
    const fd = new FormData();
    fd.append("files", doc.file);

    const params = new URLSearchParams();
    if (doc.document_type) params.set("document_type", doc.document_type);
    if (doc.document_name) params.set("document_name", doc.document_name);
    if (doc.expiry_date)   params.set("expiry_date", doc.expiry_date);
    if (doc.notes)         params.set("notes", doc.notes);

    const res = await axios.post(
      `${API_BASE_URL}/upload/technician-documents?${params.toString()}`,
      fd,
      { headers: { Authorization: `Bearer ${token}`, "Content-Type": "multipart/form-data" } },
    );
    return res.data.data?.[0] || res.data.data;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    const token = localStorage.getItem("token");
    try {
      if (editId) {
        const { password: _pw, ...payload } = form;
        await axios.put(`${API_BASE_URL}/technicians/${editId}`, payload, {
          headers: { Authorization: `Bearer ${token}` },
        });
        showToast("Technician updated!");
      } else {
        const uploadedDocs = [];
        for (const doc of documents) {
          if (!doc.file) continue;
          try {
            const uploaded = await uploadDocFile(doc);
            uploadedDocs.push({
              document_type: doc.document_type || undefined,
              document_name: doc.document_name || uploaded.original_name || doc.file.name,
              file_name:     uploaded.file_name || uploaded.original_name,
              file_url:      uploaded.file_url,
              mime_type:     uploaded.mime_type || doc.file.type,
              expiry_date:   doc.expiry_date || undefined,
              notes:         doc.notes || undefined,
            });
          } catch {
            showToast(`Failed to upload "${doc.file.name}"`, "error");
            setSubmitting(false);
            return;
          }
        }
        const payload = {
          name: form.name.trim(), phone: form.phone.trim(),
          specialization: form.specialization, status: form.status,
        };
        if (form.email)     payload.email     = form.email.trim().toLowerCase();
        if (form.join_date) payload.join_date  = form.join_date;
        if (form.password)  payload.password   = form.password;
        if (uploadedDocs.length) payload.documents = uploadedDocs;

        await axios.post(`${API_BASE_URL}/technicians`, payload, {
          headers: { Authorization: `Bearer ${token}` },
        });
        showToast("Technician added!");
      }
      setModalOpen(false);
      fetchTechnicians(search);
    } catch (err) {
      showToast(err.response?.data?.message || "Operation failed", "error");
    } finally {
      setSubmitting(false);
    }
  };

  const confirmDelete = async () => {
    const token = localStorage.getItem("token");
    try {
      await axios.delete(`${API_BASE_URL}/technicians/${deleteId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      showToast("Technician removed", "error");
      setDeleteId(null);
      fetchTechnicians(search);
    } catch (err) {
      showToast(err.response?.data?.message || "Delete failed", "error");
      setDeleteId(null);
    }
  };

  const openRating = (tech) => {
    setMenuOpen(null);
    setRatingTech(tech);
    setRatingValue(0);
    setRatingReview("");
    setRatingOpen(true);
  };

  const handleSubmitRating = async (e) => {
    e.preventDefault();
    if (!ratingValue) { showToast("Please select a rating", "error"); return; }
    setRatingSubmitting(true);
    try {
      const token = localStorage.getItem("token");
      await axios.post(
        `${API_BASE_URL}/technicians/${ratingTech.id}/ratings`,
        { rating: ratingValue, review: ratingReview || undefined },
        { headers: { Authorization: `Bearer ${token}` } },
      );
      showToast("Rating submitted!");
      setRatingOpen(false);
      fetchTechnicians(search);
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to submit rating", "error");
    } finally {
      setRatingSubmitting(false);
    }
  };

  const canEdit = currentUser?.role !== "technician";

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-7xl mx-auto">
        <SectionHeader
          title="Technicians"
          subtitle={`${activeCount} active of ${technicians.length} total`}
          action={canEdit && <Button onClick={openAdd}><Plus size={16} /> Add Technician</Button>}
        />

        {/* Search */}
        <div className="relative mb-5 max-w-sm">
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search technicians..."
            className="w-full pl-9 pr-3 py-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-800 dark:text-gray-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
          />
        </div>

        {/* Cards */}
        {loading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {[...Array(6)].map((_, i) => (
              <div key={i} className="bg-white dark:bg-gray-800 rounded-2xl p-5 border border-gray-100 dark:border-gray-700 animate-pulse">
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-11 h-11 rounded-full bg-gray-200 dark:bg-gray-700" />
                  <div className="space-y-2 flex-1">
                    <div className="h-4 w-28 bg-gray-200 dark:bg-gray-700 rounded" />
                    <div className="h-3 w-20 bg-gray-100 dark:bg-gray-800 rounded" />
                  </div>
                </div>
                <div className="space-y-2">
                  <div className="h-3 w-full bg-gray-100 dark:bg-gray-800 rounded" />
                  <div className="h-3 w-2/3 bg-gray-100 dark:bg-gray-800 rounded" />
                </div>
              </div>
            ))}
          </div>
        ) : technicians.length === 0 ? (
          <EmptyState icon={UserCog} title="No technicians found" description="Try a different search or add a new technician." />
        ) : (
          <>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {paginatedList.map((tech, i) => (
                <motion.div key={tech.id} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.04 }}>
                  <Card hover className="p-5" onClick={() => navigate(`/technicians/${tech.id}`)}>
                    <div className="flex items-start justify-between mb-3">
                      <div className="flex items-center gap-3">
                        <Avatar initials={tech.avatar || tech.name?.slice(0, 2).toUpperCase() || "??"} size="lg" />
                        <div>
                          <p className="font-bold text-gray-900 dark:text-white text-sm">{tech.name}</p>
                          <p className="text-blue-600 dark:text-blue-400 text-xs font-medium">{tech.specialization}</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-1" onClick={(e) => e.stopPropagation()}>
                        <Badge label={tech.status} />
                        {canEdit && (
                          <div className="relative">
                            <button
                              onClick={() => setMenuOpen(menuOpen === tech.id ? null : tech.id)}
                              className="p-1.5 rounded-lg text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition"
                            >
                              <MoreVertical size={16} />
                            </button>
                            <AnimatePresence>
                              {menuOpen === tech.id && (
                                <ActionMenu
                                  onClose={() => setMenuOpen(null)}
                                  items={[
                                    { label: "View", icon: Eye, onClick: () => { setMenuOpen(null); navigate(`/technicians/${tech.id}`); } },
                                    { label: "Rate", icon: Star, onClick: () => openRating(tech) },
                                    { label: "Edit", icon: Pencil, onClick: () => openEdit(tech) },
                                    { label: "Delete", icon: Trash2, danger: true, onClick: () => { setMenuOpen(null); setDeleteId(tech.id); } },
                                  ]}
                                />
                              )}
                            </AnimatePresence>
                          </div>
                        )}
                      </div>
                    </div>

                    <div className="space-y-1.5 text-xs text-gray-500 dark:text-gray-400 mb-4">
                      {tech.email && <div className="flex items-center gap-2"><Mail size={12} />{tech.email}</div>}
                      <div className="flex items-center gap-2"><Phone size={12} />{tech.phone}</div>
                    </div>

                    <div className="grid grid-cols-3 gap-2 text-center">
                      {[
                        { label: "Jobs", value: tech.jobs_completed ?? 0 },
                        { label: "Rating", value: <span className="flex items-center justify-center gap-1"><StarDisplay value={tech.rating} size={10} /><span className="text-[11px]">{Number(tech.rating || 0).toFixed(1)}</span></span> },
                        { label: "Since", value: tech.join_date ? tech.join_date.slice(0, 4) : "—" },
                      ].map(s => (
                        <div key={s.label} className="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-2">
                          <p className="text-gray-800 dark:text-gray-200 font-bold text-sm">{s.value}</p>
                          <p className="text-gray-400 text-xs">{s.label}</p>
                        </div>
                      ))}
                    </div>
                  </Card>
                </motion.div>
              ))}
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
              <div className="mt-6 pt-4 border-t border-gray-100 dark:border-gray-700 flex flex-col sm:flex-row items-center justify-between gap-4">
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  Showing <span className="font-semibold text-gray-900 dark:text-white">{(page - 1) * PER_PAGE + 1}</span> to{" "}
                  <span className="font-semibold text-gray-900 dark:text-white">{Math.min(page * PER_PAGE, technicians.length)}</span> of{" "}
                  <span className="font-semibold text-gray-900 dark:text-white">{technicians.length}</span>
                </p>
                <div className="flex gap-2">
                  <Button variant="secondary" size="sm" disabled={page === 1} onClick={() => setPage(p => p - 1)}>
                    <ChevronLeft size={16} /> Previous
                  </Button>
                  <div className="flex gap-1">
                    {[...Array(totalPages)].map((_, i) => {
                      const n = i + 1;
                      if (totalPages > 5 && (n < page - 1 || n > page + 1) && n !== 1 && n !== totalPages) {
                        if (n === 2 || n === totalPages - 1) return <span key={n} className="px-2 text-gray-400 self-center">...</span>;
                        return null;
                      }
                      return (
                        <button
                          key={n}
                          onClick={() => setPage(n)}
                          className={`w-8 h-8 rounded-lg text-sm font-medium transition-all ${
                            page === n
                              ? "bg-blue-600 text-white"
                              : "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"
                          }`}
                        >
                          {n}
                        </button>
                      );
                    })}
                  </div>
                  <Button variant="secondary" size="sm" disabled={page === totalPages} onClick={() => setPage(p => p + 1)}>
                    Next <ChevronRight size={16} />
                  </Button>
                </div>
              </div>
            )}
          </>
        )}

        {/* Add / Edit Modal */}
        <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editId ? "Edit Technician" : "Add Technician"} size="lg">
          {formLoading ? (
            <div className="flex flex-col items-center justify-center py-12 gap-3">
              <Loader2 size={28} className="animate-spin text-blue-500" />
              <p className="text-sm text-gray-500">Loading latest details…</p>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="grid grid-cols-2 gap-3">
                <Input label="Full Name" value={form.name} onChange={f("name")} placeholder="Ravi Kumar" required className="col-span-2" />
                <Input label="Email" type="email" value={form.email} onChange={f("email")} placeholder="ravi@ism.com" />
                <Input label="Phone" value={form.phone} onChange={f("phone")} placeholder="9876543210" required />
                <Select
                  label="Specialization"
                  value={form.specialization}
                  onChange={f("specialization")}
                  options={["", ...SPECIALIZATIONS].map(s => ({ value: s, label: s || "Select..." }))}
                  required
                  searchable
                />
                <Select label="Status" value={form.status} onChange={f("status")} options={STATUSES} searchable />
                <DatePicker label="Join Date" value={form.join_date} onChange={f("join_date")} className="col-span-2" />
              </div>

              {!editId && (
                <div className="space-y-1.5">
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Login Password (optional)</label>
                  <div className="relative">
                    <input
                      type={showPassword ? "text" : "password"}
                      value={form.password}
                      onChange={f("password")}
                      placeholder="Leave blank if no login needed"
                      className="w-full px-3 py-2 rounded-xl border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 text-gray-900 dark:text-gray-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition pr-10"
                    />
                    <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-white transition-colors">
                      {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                    </button>
                  </div>
                  <p className="text-xs text-gray-400">If provided, this technician can log in via the mobile app using phone/email + this password.</p>
                </div>
              )}

              {!editId && (
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                      Documents <span className="text-gray-400 font-normal">(optional)</span>
                    </label>
                    <button type="button" onClick={addDocRow} className="inline-flex items-center gap-1 text-xs font-medium text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 transition-colors">
                      <Plus size={14} /> Add Document
                    </button>
                  </div>
                  <input ref={docFileRef} type="file" accept={ACCEPTED_TYPES} className="hidden" />
                  <AnimatePresence>
                    {documents.map((doc, idx) => (
                      <motion.div
                        key={idx}
                        initial={{ opacity: 0, height: 0 }}
                        animate={{ opacity: 1, height: "auto" }}
                        exit={{ opacity: 0, height: 0 }}
                        className="relative border border-gray-200 dark:border-gray-700 rounded-xl p-3 bg-gray-50/50 dark:bg-gray-800/50 space-y-3"
                      >
                        <button type="button" onClick={() => removeDoc(idx)} className="absolute top-2 right-2 text-gray-400 hover:text-red-500 transition-colors">
                          <X size={14} />
                        </button>
                        <div
                          onClick={() => pickDocFile(idx)}
                          className={`flex items-center gap-3 p-3 rounded-lg border-2 border-dashed cursor-pointer transition-colors ${
                            doc.file
                              ? "border-emerald-300 dark:border-emerald-700 bg-emerald-50 dark:bg-emerald-900/20"
                              : "border-gray-300 dark:border-gray-600 hover:border-blue-400 dark:hover:border-blue-500 bg-white dark:bg-gray-800"
                          }`}
                        >
                          {doc.file ? (
                            <>
                              <div className="w-8 h-8 rounded-lg bg-emerald-100 dark:bg-emerald-900/40 flex items-center justify-center flex-shrink-0">
                                <CheckCircle size={16} className="text-emerald-600 dark:text-emerald-400" />
                              </div>
                              <div className="flex-1 min-w-0">
                                <p className="text-sm font-medium text-gray-800 dark:text-gray-200 truncate">{doc.file.name}</p>
                                <p className="text-xs text-gray-400">{(doc.file.size / 1024).toFixed(0)} KB</p>
                              </div>
                              <button type="button" onClick={(e) => { e.stopPropagation(); updateDoc(idx, "file", null); }} className="text-gray-400 hover:text-red-500">
                                <X size={14} />
                              </button>
                            </>
                          ) : (
                            <>
                              <div className="w-8 h-8 rounded-lg bg-blue-50 dark:bg-blue-900/30 flex items-center justify-center flex-shrink-0">
                                <Upload size={16} className="text-blue-500" />
                              </div>
                              <div>
                                <p className="text-sm font-medium text-gray-600 dark:text-gray-300">Choose file</p>
                                <p className="text-xs text-gray-400">PDF, JPG, PNG, WebP, DOC — max 20MB</p>
                              </div>
                            </>
                          )}
                        </div>
                        <div className="grid grid-cols-2 gap-2">
                          <Select label="Type" value={doc.document_type} onChange={(e) => updateDoc(idx, "document_type", e.target.value)} options={["", ...DOC_TYPES].map(t => ({ value: t, label: t || "Select type..." }))} searchable />
                          <Input label="Label" value={doc.document_name} onChange={(e) => updateDoc(idx, "document_name", e.target.value)} placeholder="e.g. Aadhaar Front" />
                          <DatePicker label="Expiry Date" value={doc.expiry_date} onChange={(e) => updateDoc(idx, "expiry_date", e.target.value)} />
                          <Input label="Notes" value={doc.notes} onChange={(e) => updateDoc(idx, "notes", e.target.value)} placeholder="Optional notes" />
                        </div>
                      </motion.div>
                    ))}
                  </AnimatePresence>
                  {documents.length === 0 && (
                    <div className="text-center py-4 border-2 border-dashed border-gray-200 dark:border-gray-700 rounded-xl">
                      <FileText size={20} className="mx-auto mb-1.5 text-gray-300 dark:text-gray-600" />
                      <p className="text-xs text-gray-400">No documents added yet</p>
                    </div>
                  )}
                  <p className="text-xs text-gray-400">Accepted: PDF, JPEG, PNG, WebP, DOC, DOCX · Max 20MB each, up to 10 files</p>
                </div>
              )}

              <div className="flex gap-3 pt-2">
                <Button type="submit" className="flex-1" disabled={submitting}>
                  {submitting ? "Saving…" : (editId ? "Update" : "Add")} Technician
                </Button>
                <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
              </div>
            </form>
          )}
        </Modal>

        {/* Delete confirm */}
        <Modal isOpen={!!deleteId} onClose={() => setDeleteId(null)} title="Confirm Delete" size="sm">
          <p className="text-gray-600 dark:text-gray-300 text-sm mb-5">Are you sure you want to remove this technician? This cannot be undone.</p>
          <div className="flex gap-3">
            <Button variant="danger" onClick={confirmDelete} className="flex-1">Delete</Button>
            <Button variant="secondary" onClick={() => setDeleteId(null)}>Cancel</Button>
          </div>
        </Modal>

        {/* Rating modal */}
        <Modal isOpen={ratingOpen} onClose={() => setRatingOpen(false)} title={`Rate ${ratingTech?.name || "Technician"}`} size="sm">
          <form onSubmit={handleSubmitRating} className="space-y-5">
            <div className="text-center">
              <p className="text-sm text-gray-500 dark:text-gray-400 mb-3">How would you rate this technician?</p>
              <div className="flex justify-center">
                <StarRatingPicker value={ratingValue} onChange={setRatingValue} size={32} />
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
                {ratingSubmitting ? "Submitting…" : "Submit Rating"}
              </Button>
              <Button variant="secondary" onClick={() => setRatingOpen(false)}>Cancel</Button>
            </div>
          </form>
        </Modal>

        {toast && <Toast {...toast} onClose={() => {}} />}
      </div>
    </PageTransition>
  );
}
