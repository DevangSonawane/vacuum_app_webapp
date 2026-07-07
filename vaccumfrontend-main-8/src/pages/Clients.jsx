import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  Plus, Pencil, Trash2, Users, Phone, Mail, MapPin, Building2,
  X, Briefcase, ShieldCheck, TrendingUp, Loader2,
  Calendar, DollarSign, FileText, ChevronLeft, ChevronRight,
  MoreVertical, Eye,
} from "lucide-react";
import axios from "axios";
import { useApp } from "../context/AppContext";
import {
  PageTransition, Card, Badge, Button, Modal, Input, Select,
  SectionHeader, EmptyState, useToast, Toast
} from "../components/ui";

const API_BASE_URL = "https://apivdti.asynk.in/api";

const EMPTY = {
  name:           "",
  contact_person: "",
  email:          "",
  phone:          "",
  address:        "",
  gst_no:         "",
  type:           "Corporate",
  status:         "Active",
  contract_value: "",
};

const TYPES = ["Corporate", "Residential", "Commercial", "Healthcare", "Government"];

const TYPE_COLORS = {
  Corporate:   "bg-blue-100   text-blue-700",
  Residential: "bg-emerald-100 text-emerald-700",
  Commercial:  "bg-purple-100 text-purple-700",
  Healthcare:  "bg-red-100    text-red-700",
  Government:  "bg-amber-100  text-amber-700",
};

function ActionMenu({ items, onClose }) {
  const menuRef = useRef();
  useEffect(() => {
    const handler = (e) => { if (menuRef.current && !menuRef.current.contains(e.target)) onClose(); };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, [onClose]);

  return (
    <motion.div
      ref={menuRef}
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

export default function Clients() {
  const { currentUser } = useApp();
  const { toast, showToast } = useToast();

  const [allClients, setAllClients] = useState([]);
  const [loading, setLoading]       = useState(true);
  const [search, setSearch]         = useState("");
  const [filterType, setFilterType] = useState("All");
  const [page, setPage]             = useState(1);
  const limit = 10;

  const [modalOpen, setModalOpen]   = useState(false);
  const [editId, setEditId]         = useState(null);
  const [form, setForm]             = useState(EMPTY);
  const [submitting, setSubmitting] = useState(false);
  const [deleteId, setDeleteId]     = useState(null);
  const [menuOpen, setMenuOpen]     = useState(null);

  const [detailClient, setDetailClient]   = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);

  // Filter clients client-side
  const filteredClients = allClients.filter(c => {
    const q = search.toLowerCase();
    const matchesSearch = !search ||
      c.name?.toLowerCase().includes(q) ||
      c.contact_person?.toLowerCase().includes(q) ||
      c.email?.toLowerCase().includes(q) ||
      c.phone?.includes(search) ||
      c.address?.toLowerCase().includes(q);
    const matchesType = filterType === "All" || c.type === filterType;
    return matchesSearch && matchesType;
  });

  // Get paginated clients
  const startIndex = (page - 1) * limit;
  const clients = filteredClients.slice(startIndex, startIndex + limit);
  const totalClients = filteredClients.length;
  const totalPages = Math.ceil(totalClients / limit);

  useEffect(() => { 
    fetchClients(); 
  }, []);

  const fetchClients = async () => {
    setLoading(true);
    try {
      const token  = localStorage.getItem("token");
      // Fetch all clients (limit 1000 to get all)
      const res = await axios.get(`${API_BASE_URL}/clients`, {
        headers: { Authorization: `Bearer ${token}` },
        params: { limit: 1000 }
      });
      if (res.data.success) {
        setAllClients(res.data.data || []);
      }
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to fetch clients", "error");
    } finally {
      setLoading(false);
    }
  };

  // Reset page when filters change
  useEffect(() => {
    setPage(1);
  }, [search, filterType]);

  const openDetail = async (client) => {
    setDetailClient({ ...client, stats: null });
    setDetailLoading(true);
    try {
      const token = localStorage.getItem("token");
      const res   = await axios.get(`${API_BASE_URL}/clients/${client.id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.data.success) setDetailClient(res.data.data);
    } catch {
      showToast("Could not load full client details.", "error");
    } finally {
      setDetailLoading(false);
    }
  };

  const f = (field) => (e) => setForm(p => ({ ...p, [field]: e.target.value }));

  const openAdd = () => { setForm(EMPTY); setEditId(null); setModalOpen(true); };

  const openEdit = (c) => {
    setForm({
      name:           c.name           || "",
      contact_person: c.contact_person || "",
      email:          c.email          || "",
      phone:          c.phone          || "",
      address:        c.address        || "",
      gst_no:         c.gst_no         || "",
      type:           c.type           || "Corporate",
      status:         c.status         || "Active",
      contract_value: c.contract_value || "",
    });
    setEditId(c.id);
    setModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    const token = localStorage.getItem("token");
    try {
      const payload = {
        name:           form.name.trim(),
        contact_person: form.contact_person.trim(),
        type:           form.type,
        status:         form.status,
      };
      if (form.email)          payload.email          = form.email.trim().toLowerCase();
      if (form.phone)          payload.phone          = form.phone.trim();
      if (form.address)        payload.address        = form.address.trim();
      if (form.gst_no)         payload.gst_no         = form.gst_no.trim().toUpperCase();
      if (form.contract_value) payload.contract_value = parseFloat(form.contract_value);

      if (editId) {
        await axios.put(`${API_BASE_URL}/clients/${editId}`, payload, {
          headers: { Authorization: `Bearer ${token}` },
        });
        showToast("Client updated!");
        if (detailClient?.id === editId) openDetail({ id: editId });
      } else {
        await axios.post(`${API_BASE_URL}/clients`, payload, {
          headers: { Authorization: `Bearer ${token}` },
        });
        showToast("Client added!");
      }
      setModalOpen(false);
      fetchClients();
    } catch (err) {
      showToast(err.response?.data?.message || "Operation failed", "error");
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async () => {
    const token = localStorage.getItem("token");
    try {
      await axios.delete(`${API_BASE_URL}/clients/${deleteId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      showToast("Client removed", "error");
      if (detailClient?.id === deleteId) setDetailClient(null);
      setDeleteId(null);
      fetchClients();
    } catch (err) {
      showToast(err.response?.data?.message || "Delete failed", "error");
      setDeleteId(null);
    }
  };

  const canEdit     = currentUser?.role !== "technician";
  const activeCount = clients.filter(c => c.status === "Active").length;

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-7xl mx-auto">
        <SectionHeader
          title="Clients"
          subtitle={`${activeCount} active clients`}
          action={canEdit && <Button onClick={openAdd}><Plus size={16} /> Add Client</Button>}
        />

        {/* Filters */}
        <div className="flex flex-wrap gap-2 mb-5">
          <div className="relative flex-1 min-w-48 max-w-xs">
            <input
              value={search}
              onChange={e => { setSearch(e.target.value); setPage(1); }}
              placeholder="Search clients..."
              className="w-full pl-3 pr-3 py-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-800 dark:text-gray-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
            />
          </div>
          <div className="flex gap-1 flex-wrap">
            {["All", ...TYPES].map(t => (
              <button key={t} onClick={() => { setFilterType(t); setPage(1); }}
                className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition ${filterType === t ? "bg-blue-600 text-white" : "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"}`}
              >{t}</button>
            ))}
          </div>
        </div>

        {/* Main layout */}
        <div className={`flex gap-5 transition-all ${detailClient ? "items-start" : ""}`}>
          {/* Client Table */}
          <div className={`${detailClient ? "flex-1 min-w-0" : "w-full"}`}>
            {loading ? (
              <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 animate-pulse">
                <div className="p-5 space-y-4">
                  {[...Array(4)].map((_, i) => (
                    <div key={i} className="flex items-center gap-4">
                      <div className="w-10 h-10 rounded-xl bg-gray-200 dark:bg-gray-700" />
                      <div className="space-y-2 flex-1">
                        <div className="h-4 w-3/4 bg-gray-200 dark:bg-gray-700 rounded" />
                        <div className="h-3 w-1/2 bg-gray-100 dark:bg-gray-800 rounded" />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ) : clients.length === 0 ? (
              <EmptyState icon={Users} title="No clients found" description="Adjust your filters or add a new client." />
            ) : (
              <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-left">
                    <thead className="bg-gray-50 dark:bg-gray-900/50 border-b border-gray-100 dark:border-gray-700">
                      <tr>
                        <th className="px-5 py-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Client</th>
                        <th className="px-5 py-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Contact</th>
                        <th className="px-5 py-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Address</th>
                        <th className="px-5 py-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Type</th>
                        <th className="px-5 py-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Status</th>
                        <th className="px-5 py-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider text-right">Contract Value</th>
                        <th className="px-5 py-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider text-right w-16"></th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100 dark:divide-gray-700">
                      {clients.map((c, i) => (
                        <motion.tr 
                          key={c.id} 
                          initial={{ opacity: 0, y: 20 }} 
                          animate={{ opacity: 1, y: 0 }} 
                          transition={{ delay: i * 0.04 }}
                          onClick={() => openDetail(c)}
                          className={`cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700/30 transition-colors ${detailClient?.id === c.id ? "bg-blue-50 dark:bg-blue-900/10" : ""}`}
                        >
                          <td className="px-5 py-4">
                            <div className="flex items-center gap-3">
                              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-500 to-blue-700 flex items-center justify-center flex-shrink-0">
                                <Building2 size={18} className="text-white" />
                              </div>
                              <div>
                                <p className="font-semibold text-gray-900 dark:text-white text-sm">{c.name}</p>
                                {c.contact_person && <p className="text-xs text-gray-500 dark:text-gray-400">{c.contact_person}</p>}
                              </div>
                            </div>
                          </td>
                          <td className="px-5 py-4">
                            <div className="space-y-1">
                              {c.email && <p className="text-xs text-gray-600 dark:text-gray-300"><Mail size={10} className="inline mr-1" />{c.email}</p>}
                              {c.phone && <p className="text-xs text-gray-600 dark:text-gray-300"><Phone size={10} className="inline mr-1" />{c.phone}</p>}
                            </div>
                          </td>
                          <td className="px-5 py-4">
                            {c.address ? (
                              <div className="flex items-start gap-1.5 max-w-[200px]">
                                <MapPin size={12} className="text-gray-400 mt-0.5 flex-shrink-0" />
                                <p className="text-xs text-gray-600 dark:text-gray-300 line-clamp-2">{c.address}</p>
                              </div>
                            ) : (
                              <span className="text-xs text-gray-400">—</span>
                            )}
                          </td>
                          <td className="px-5 py-4">
                            <span className={`text-xs px-2 py-0.5 rounded-full font-semibold ${TYPE_COLORS[c.type] || "bg-gray-100 text-gray-600"}`}>{c.type}</span>
                          </td>
                          <td className="px-5 py-4">
                            <Badge label={c.status} />
                          </td>
                          <td className="px-5 py-4 text-right">
                            <p className="font-semibold text-gray-900 dark:text-white text-sm">
                              ₹{Number(c.contract_value || 0).toLocaleString()}
                            </p>
                          </td>
                          <td className="px-5 py-4 text-right" onClick={e => e.stopPropagation()}>
                            <div className="relative inline-block">
                              <button
                                onClick={() => setMenuOpen(menuOpen === c.id ? null : c.id)}
                                className="p-1.5 rounded-lg text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition"
                              >
                                <MoreVertical size={16} />
                              </button>
                              <AnimatePresence>
                                {menuOpen === c.id && (
                                  <ActionMenu
                                    onClose={() => setMenuOpen(null)}
                                    items={[
                                      { label: "View", icon: Eye, onClick: () => { setMenuOpen(null); openDetail(c); } },
                                      ...(canEdit ? [
                                        { label: "Edit", icon: Pencil, onClick: () => { setMenuOpen(null); openEdit(c); } },
                                        { label: "Delete", icon: Trash2, danger: true, onClick: () => { setMenuOpen(null); setDeleteId(c.id); } },
                                      ] : []),
                                    ]}
                                  />
                                )}
                              </AnimatePresence>
                            </div>
                          </td>
                        </motion.tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* Pagination */}
            {!loading && clients.length > 0 && (
              <div className="mt-8 pt-6 border-t border-gray-100 dark:border-gray-700 flex flex-col sm:flex-row items-center justify-between gap-4">
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  Showing <span className="font-semibold text-gray-900 dark:text-white">{(page - 1) * limit + 1}</span> to <span className="font-semibold text-gray-900 dark:text-white">{Math.min(page * limit, totalClients)}</span> of <span className="font-semibold text-gray-900 dark:text-white">{totalClients}</span> results
                </p>
                <div className="flex gap-2">
                  <Button variant="secondary" size="sm" disabled={page === 1} onClick={() => setPage(p => p - 1)}>
                    <ChevronLeft size="16" /> Previous
                  </Button>
                  <div className="flex gap-1">
                    {[...Array(totalPages)].map((_, i) => {
                      const pageNum = i + 1;
                      if (totalPages > 5 && (pageNum < page - 1 || pageNum > page + 1) && pageNum !== 1 && pageNum !== totalPages) {
                        if (pageNum === 2 || pageNum === totalPages - 1) return <span key={pageNum} className="px-2 text-gray-900 dark:text-white">...</span>;
                        return null;
                      }
                      return (
                        <button
                          key={pageNum}
                          onClick={() => setPage(pageNum)}
                          className={`w-8 h-8 rounded-lg text-sm font-medium transition-all ${page === pageNum ? "bg-blue-600 text-white" : "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"}`}
                        >
                          {pageNum}
                        </button>
                      );
                    })}
                  </div>
                  <Button variant="secondary" size="sm" disabled={page === totalPages} onClick={() => setPage(p => p + 1)}>
                    Next <ChevronRight size="16" />
                  </Button>
                </div>
              </div>
            )}
          </div>

          {/* Detail Panel */}
          <AnimatePresence>
            {detailClient && (
              <motion.div
                key="detail"
                initial={{ opacity: 0, x: 40 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 40 }}
                transition={{ type: "spring", damping: 28, stiffness: 280 }}
                className="w-full lg:w-96 flex-shrink-0 bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 shadow-lg overflow-hidden sticky top-4"
              >
                {/* Header */}
                <div className="flex items-start justify-between p-5 border-b border-gray-100 dark:border-gray-700 bg-gradient-to-br from-blue-600 to-blue-800">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-xl bg-white/20 flex items-center justify-center flex-shrink-0">
                      <Building2 size={22} className="text-white" />
                    </div>
                    <div>
                      <p className="font-bold text-white">{detailClient.name}</p>
                      <p className="text-blue-200 text-xs">{detailClient.contact_person}</p>
                    </div>
                  </div>
                  <button onClick={() => setDetailClient(null)} className="text-white/70 hover:text-white transition p-1">
                    <X size={18} />
                  </button>
                </div>

                <div className="p-5 space-y-5 max-h-[calc(100vh-200px)] overflow-y-auto">

                  {/* Status + Type */}
                  <div className="flex items-center gap-2 flex-wrap">
                    <Badge label={detailClient.status} />
                    <span className={`text-xs px-2 py-0.5 rounded-full font-semibold ${TYPE_COLORS[detailClient.type] || "bg-gray-100 text-gray-600"}`}>
                      {detailClient.type}
                    </span>
                  </div>

                  {/* Stats */}
                  {detailLoading ? (
                    <div className="flex items-center gap-2 text-sm text-gray-400 py-2">
                      <Loader2 size={16} className="animate-spin" /> Loading stats…
                    </div>
                  ) : detailClient.stats ? (
                    <div className="grid grid-cols-3 gap-2">
                      {[
                        { icon: Briefcase,   label: "Total Jobs",  value: detailClient.stats.total_jobs },
                        { icon: TrendingUp,  label: "Open Jobs",   value: detailClient.stats.open_jobs },
                        { icon: ShieldCheck, label: "Active AMC",  value: detailClient.stats.active_amc_count },
                      ].map(s => (
                        <div key={s.label} className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-3 text-center">
                          <s.icon size={16} className="text-blue-500 mx-auto mb-1" />
                          <p className="font-bold text-gray-900 dark:text-white text-base">{s.value}</p>
                          <p className="text-gray-400 text-[10px] leading-tight">{s.label}</p>
                        </div>
                      ))} 
                    </div>
                  ) : null}

                  {/* Contact */}
                  <div className="space-y-2.5">
                    <p className="text-xs font-bold text-gray-400 uppercase tracking-widest">Contact</p>
                    {detailClient.email && (
                      <div className="flex items-center gap-3 text-sm text-gray-700 dark:text-gray-300">
                        <div className="w-7 h-7 rounded-lg bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center flex-shrink-0">
                          <Mail size={13} className="text-blue-500" />
                        </div>
                        <span className="break-all">{detailClient.email}</span>
                      </div>
                    )}
                    {detailClient.phone && (
                      <div className="flex items-center gap-3 text-sm text-gray-700 dark:text-gray-300">
                        <div className="w-7 h-7 rounded-lg bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center flex-shrink-0">
                          <Phone size={13} className="text-blue-500" />
                        </div>
                        <span>{detailClient.phone}</span>
                      </div>
                    )}
                    {detailClient.address && (
                      <div className="flex items-start gap-3 text-sm text-gray-700 dark:text-gray-300">
                        <div className="w-7 h-7 rounded-lg bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center flex-shrink-0 mt-0.5">
                          <MapPin size={13} className="text-blue-500" />
                        </div>
                        <span className="leading-snug">{detailClient.address}</span>
                      </div>
                    )}
                    {detailClient.gst_no && (
                      <div className="flex items-center gap-3 text-sm text-gray-700 dark:text-gray-300">
                        <div className="w-7 h-7 rounded-lg bg-amber-50 dark:bg-amber-900/20 flex items-center justify-center flex-shrink-0">
                          <FileText size={13} className="text-amber-500" />
                        </div>
                        <span className="font-mono text-xs">GST: {detailClient.gst_no}</span>
                      </div>
                    )}
                  </div>

                  {/* Contract */}
                  <div className="space-y-2.5">
                    <p className="text-xs font-bold text-gray-400 uppercase tracking-widest">Contract</p>
                    <div className="grid grid-cols-2 gap-3">
                      <div className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-3">
                        <div className="flex items-center gap-1.5 mb-1">
                          <DollarSign size={13} className="text-green-500" />
                          <p className="text-xs text-gray-400">Value</p>
                        </div>
                        <p className="font-bold text-gray-900 dark:text-white text-sm">
                          ₹{Number(detailClient.contract_value || 0).toLocaleString()}
                        </p>
                      </div>
                      <div className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-3">
                        <div className="flex items-center gap-1.5 mb-1">
                          <Calendar size={13} className="text-blue-500" />
                          <p className="text-xs text-gray-400">Since</p>
                        </div>
                        <p className="font-bold text-gray-900 dark:text-white text-sm">
                          {detailClient.join_date ? detailClient.join_date.slice(0, 10) : "—"}
                        </p>
                      </div>
                    </div>
                  </div>

                  {/* Actions */}
                  {canEdit && (
                    <div className="flex gap-2 pt-1">
                      <Button className="flex-1" onClick={() => openEdit(detailClient)}>
                        <Pencil size={14} /> Edit
                      </Button>
                      <Button variant="danger" onClick={() => setDeleteId(detailClient.id)}>
                        <Trash2 size={14} />
                      </Button>
                    </div>
                  )}
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* Add / Edit Modal */}
        <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editId ? "Edit Client" : "Add Client"} size="lg">
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <Input label="Company Name"       value={form.name}           onChange={f("name")}           required className="col-span-2" />
              <Input label="Contact Person"     value={form.contact_person} onChange={f("contact_person")} required />
              <Input label="Email"              type="email" value={form.email}  onChange={f("email")} />
              <Input label="Phone"              value={form.phone}          onChange={f("phone")} />
              <Input label="GST No."            value={form.gst_no}         onChange={f("gst_no")}         placeholder="22AAAAA0000A1Z5" />
              <Input label="Contract Value (₹)" type="number" value={form.contract_value} onChange={f("contract_value")} />
              <Select label="Type"   value={form.type}   onChange={f("type")}   options={TYPES} searchable />
              <Select label="Status" value={form.status} onChange={f("status")} options={["Active", "Inactive"]} searchable />
              <Input label="Address" value={form.address} onChange={f("address")} className="col-span-2" />
            </div>
            <div className="flex gap-3 pt-2">
              <Button type="submit" className="flex-1" disabled={submitting}>
                {submitting ? "Saving…" : (editId ? "Update" : "Add")} Client
              </Button>
              <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
            </div>
          </form>
        </Modal>

        {/* Delete confirm */}
        <Modal isOpen={!!deleteId} onClose={() => setDeleteId(null)} title="Confirm Delete" size="sm">
          <p className="text-gray-600 dark:text-gray-300 text-sm mb-5">Remove this client permanently?</p>
          <div className="flex gap-3">
            <Button variant="danger" onClick={handleDelete} className="flex-1">Delete</Button>
            <Button variant="secondary" onClick={() => setDeleteId(null)}>Cancel</Button>
          </div>
        </Modal>

        {toast && <Toast {...toast} onClose={() => {}} />}
      </div>
    </PageTransition>
  );
}