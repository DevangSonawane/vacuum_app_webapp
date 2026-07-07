import { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import {
  Plus, ShieldCheck, Calendar, RefreshCw, AlertTriangle,
  X, Building2, DollarSign, Clock, ChevronRight,
  Loader2, ExternalLink, Pencil, Trash2, Package, MapPin, Search, CheckCircle,
  MoreVertical, Eye,
} from "lucide-react";
import axios from "axios";
import { useApp } from "../context/AppContext";
import {
  PageTransition, Card, Badge, Button, Modal, Input,
  Select, DatePicker, SectionHeader, EmptyState, useToast, Toast
} from "../components/ui";

const API_BASE_URL = "https://apivdti.asynk.in/api";

function ClientAutocomplete({ clients, value, onChange, required, className = "" }) {
  const [query, setQuery] = useState("");
  const [focused, setFocused] = useState(false);
  const ref = useRef();
  const inputRef = useRef();

  useEffect(() => {
    const handler = (e) => { if (ref.current && !ref.current.contains(e.target)) setFocused(false); };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const selected = clients.find(c => c.id === value || String(c.id) === String(value));
  const q = query.toLowerCase();
  const filtered = q
    ? clients.filter(c =>
        c.name?.toLowerCase().includes(q) ||
        c.address?.toLowerCase().includes(q) ||
        c.contact_person?.toLowerCase().includes(q) ||
        c.phone?.includes(query)
      )
    : clients;

  const handleSelect = (c) => {
    onChange(c.id);
    setQuery(c.name);
    setFocused(false);
  };

  const handleClear = () => {
    onChange("");
    setQuery("");
    inputRef.current?.focus();
  };

  const displayQuery = focused ? query : (selected ? selected.name : query);

  return (
    <div className={`relative ${className}`} ref={ref}>
      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
        Client{required && <span className="text-red-500 ml-1">*</span>}
      </label>

      <div className="relative">
        <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
        <input
          ref={inputRef}
          type="text"
          value={displayQuery}
          onChange={(e) => { setQuery(e.target.value); setFocused(true); if (value) onChange(""); }}
          onFocus={() => setFocused(true)}
          placeholder="Type to search clients..."
          className={`w-full pl-9 pr-9 py-2 rounded-xl border text-sm transition-all ${
            focused
              ? "border-blue-500 ring-2 ring-blue-500/20 bg-white dark:bg-gray-800"
              : "border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700"
          } text-gray-900 dark:text-gray-100 focus:outline-none`}
        />
        {(query || value) && (
          <button type="button" onClick={handleClear} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200">
            <X size={14} />
          </button>
        )}
      </div>

      <AnimatePresence>
        {focused && (
          <motion.div
            initial={{ opacity: 0, y: 4, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 4, scale: 0.98 }}
            transition={{ duration: 0.1 }}
            className="absolute z-[100] left-0 right-0 mt-1 bg-white dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-xl shadow-xl overflow-hidden"
          >
            <div className="max-h-64 overflow-y-auto py-1 custom-scrollbar">
              {filtered.length === 0 ? (
                <div className="px-4 py-4 text-sm text-gray-400 text-center">No clients found</div>
              ) : (
                filtered.map((c) => {
                  const isSelected = String(c.id) === String(value);
                  return (
                    <div
                      key={c.id}
                      onClick={() => handleSelect(c)}
                      className={`px-4 py-3 cursor-pointer transition-colors ${
                        isSelected
                          ? "bg-blue-50 dark:bg-blue-900/20"
                          : "hover:bg-gray-50 dark:hover:bg-gray-700/50"
                      }`}
                    >
                      <div className="flex items-center justify-between gap-2">
                        <div className="flex items-center gap-2.5 min-w-0">
                          <div className="w-8 h-8 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center flex-shrink-0">
                            <Building2 size={14} className="text-blue-600 dark:text-blue-400" />
                          </div>
                          <div className="min-w-0">
                            <p className={`text-sm font-medium truncate ${isSelected ? "text-blue-600 dark:text-blue-400" : "text-gray-900 dark:text-gray-100"}`}>
                              {c.name}
                            </p>
                            {c.address && (
                              <p className="text-xs text-gray-400 truncate flex items-center gap-1 mt-0.5">
                                <MapPin size={10} className="flex-shrink-0" /> {c.address}
                              </p>
                            )}
                          </div>
                        </div>
                        {isSelected && <CheckCircle size={14} className="text-blue-500 flex-shrink-0" />}
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

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

const STATUS_GRAD = {
  Active:          "from-blue-500   to-blue-700",
  "Expiring Soon": "from-orange-500 to-orange-700",
  Expired:         "from-gray-400   to-gray-600",
};

const EMPTY_FORM = {
  client_id:             "",
  title:                 "",
  po_number:             "",
  start_date:            "",
  end_date:              "",
  value:                 "",
  renewal_reminder_days: 30,
  services_raw:          "",
  last_service_date:     "",
  next_service_date:     "",
  visit_count:           "",
  pumps_count:           "",
  per_pump_price:        "",
  total_price:           "",
  gst_percent:           "",
};

export default function AMC() {
  const navigate = useNavigate();
  const { currentUser } = useApp();
  const { toast, showToast } = useToast();

  const [contracts, setContracts] = useState([]);
  const [clients, setClients]     = useState([]);
  const [loading, setLoading]     = useState(true);
  const [statusFilter, setStatusFilter] = useState("All");
  const [search, setSearch] = useState("");

  const [modalOpen, setModalOpen]   = useState(false);
  const [editId, setEditId]         = useState(null);
  const [form, setForm]             = useState(EMPTY_FORM);
  const [submitting, setSubmitting] = useState(false);
  const [menuOpen, setMenuOpen]     = useState(null);

  const [deleteId, setDeleteId] = useState(null);

  useEffect(() => { fetchContracts(); fetchClients(); }, []);
  useEffect(() => { fetchContracts(); }, [statusFilter, search]);

  const fetchContracts = async () => {
    setLoading(true);
    try {
      const token  = localStorage.getItem("token");
      const params = { limit: 100 };
      if (statusFilter !== "All") params.status = statusFilter;
      if (search) params.search = search;
      const res = await axios.get(`${API_BASE_URL}/amc`, {
        headers: { Authorization: `Bearer ${token}` }, params,
      });
      if (res.data.success) setContracts(res.data.data || []);
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to fetch contracts", "error");
    } finally {
      setLoading(false);
    }
  };

  const fetchClients = async () => {
    try {
      const token = localStorage.getItem("token");
      const res   = await axios.get(`${API_BASE_URL}/clients`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.data.success) setClients(res.data.data || []);
    } catch {}
  };

  const f = (field) => (e) => {
    const value = e.target.value;
    setForm(prev => {
      const updated = { ...prev, [field]: value };
      if (field === 'pumps_count' || field === 'per_pump_price') {
        const pumps = parseFloat(updated.pumps_count) || 0;
        const perPump = parseFloat(updated.per_pump_price) || 0;
        updated.total_price = pumps * perPump;
      }
      if (field === 'total_price' || field === 'gst_percent' || field === 'pumps_count' || field === 'per_pump_price') {
        const total = parseFloat(updated.total_price) || 0;
        const gst = parseFloat(updated.gst_percent) || 0;
        updated.value = total + (total * gst / 100);
      }
      return updated;
    });
  };

  const openAdd = () => { setForm(EMPTY_FORM); setEditId(null); setModalOpen(true); };

  const openEdit = (amc) => {
    setMenuOpen(null);
    setForm({
      client_id: amc.client_id || "", title: amc.title || "", po_number: amc.po_number || "",
      start_date: amc.start_date?.slice(0, 10) || "", end_date: amc.end_date?.slice(0, 10) || "",
      value: amc.value || "", renewal_reminder_days: amc.renewal_reminder_days || 30,
      services_raw: (amc.services || []).join(", "),
      last_service_date: amc.last_service_date?.slice(0, 10) || "",
      next_service_date: amc.next_service_date?.slice(0, 10) || "",
      visit_count: amc.visit_count || "", pumps_count: amc.pumps_count || "",
      per_pump_price: amc.per_pump_price || "", total_price: amc.total_price || "",
      gst_percent: amc.gst_percent || "",
    });
    setEditId(amc.id);
    setModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    const token    = localStorage.getItem("token");
    const services = form.services_raw ? form.services_raw.split(",").map(s => s.trim()).filter(Boolean) : [];

    if (form.last_service_date) {
      const start = form.start_date;
      const end   = form.end_date;
      if (start && form.last_service_date < start) { showToast("Last service date cannot be before the start date", "error"); setSubmitting(false); return; }
      if (end && form.last_service_date > end) { showToast("Last service date cannot be after the end date", "error"); setSubmitting(false); return; }
    }

    try {
      const payload = {
        title: form.title.trim(), value: parseFloat(form.value),
        renewal_reminder_days: parseInt(form.renewal_reminder_days), services,
        po_number: form.po_number.trim() || undefined,
        visit_count: form.visit_count ? parseInt(form.visit_count) : undefined,
        pumps_count: form.pumps_count ? parseInt(form.pumps_count) : undefined,
        per_pump_price: form.per_pump_price ? parseFloat(form.per_pump_price) : undefined,
        total_price: form.total_price ? parseFloat(form.total_price) : undefined,
        gst_percent: form.gst_percent ? parseFloat(form.gst_percent) : undefined,
      };

      if (editId) {
        if (form.end_date)          payload.end_date          = form.end_date;
        if (form.last_service_date) payload.last_service_date = form.last_service_date;
        if (form.next_service_date) payload.next_service_date = form.next_service_date;
        await axios.put(`${API_BASE_URL}/amc/${editId}`, payload, { headers: { Authorization: `Bearer ${token}` } });
        showToast("AMC contract updated!");
      } else {
        payload.client_id  = parseInt(form.client_id);
        payload.start_date = form.start_date;
        payload.end_date   = form.end_date;
        if (form.last_service_date) payload.last_service_date = form.last_service_date;
        if (form.next_service_date) payload.next_service_date = form.next_service_date;
        await axios.post(`${API_BASE_URL}/amc`, payload, { headers: { Authorization: `Bearer ${token}` } });
        showToast("AMC contract created! Confirmation email sent to client.");
      }
      setModalOpen(false);
      fetchContracts();
    } catch (err) {
      showToast(err.response?.data?.message || "Operation failed", "error");
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async () => {
    try {
      const token = localStorage.getItem("token");
      await axios.delete(`${API_BASE_URL}/amc/${deleteId}`, { headers: { Authorization: `Bearer ${token}` } });
      showToast("AMC contract deleted", "error");
      setDeleteId(null);
      fetchContracts();
    } catch (err) {
      showToast(err.response?.data?.message || "Delete failed", "error");
      setDeleteId(null);
    }
  };

  const canEdit    = !["technician", "labour"].includes(currentUser?.role);
  const totalValue = contracts.reduce((s, a) => s + Number(a.value || 0), 0);
  const STATUS_TABS = ["All", "Active", "Expiring Soon", "Expired"];

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-7xl mx-auto">
        <SectionHeader
          title="AMC Contracts"
          subtitle={`Total portfolio: ₹${(totalValue / 100000).toFixed(1)}L`}
          action={canEdit && <Button onClick={openAdd}><Plus size={16} /> New AMC</Button>}
        />

        {/* Summary tiles */}
        <div className="grid grid-cols-3 gap-4 mb-5">
          {[
            { label: "Active",        color: "text-blue-600",   bg: "bg-blue-50   dark:bg-blue-900/20" },
            { label: "Expiring Soon", color: "text-orange-600", bg: "bg-orange-50 dark:bg-orange-900/20" },
            { label: "Expired",       color: "text-gray-500",   bg: "bg-gray-50   dark:bg-gray-700/50" },
          ].map(s => (
            <div key={s.label} className={`${s.bg} rounded-2xl p-4 text-center`}>
              <p className={`text-2xl font-bold ${s.color} font-display`}>{contracts.filter(a => a.status === s.label).length}</p>
              <p className="text-xs text-gray-500 dark:text-gray-400 font-medium mt-0.5">{s.label}</p>
            </div>
          ))}
        </div>

        {/* Search + Filter */}
        <div className="flex flex-wrap gap-2 mb-5 items-center">
          <div className="relative flex-1 min-w-48 max-w-sm">
            <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search AMC contracts..."
              className="w-full pl-3 pr-3 py-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-800 dark:text-gray-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 transition" />
          </div>
          {STATUS_TABS.map(s => (
            <button key={s} onClick={() => setStatusFilter(s)}
              className={`px-4 py-1.5 rounded-xl text-xs font-semibold transition ${statusFilter === s ? "bg-blue-600 text-white" : "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"}`}
            >{s}</button>
          ))}
        </div>

        {/* Cards */}
        {loading ? (
          <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
            {[...Array(3)].map((_, i) => (
              <div key={i} className="bg-white dark:bg-gray-800 rounded-2xl overflow-hidden border border-gray-100 dark:border-gray-700 animate-pulse">
                <div className="h-1.5 bg-gray-200 dark:bg-gray-700" />
                <div className="p-5 space-y-3">
                  <div className="h-4 w-3/4 bg-gray-200 dark:bg-gray-700 rounded" />
                  <div className="h-3 w-1/2 bg-gray-100 dark:bg-gray-800 rounded" />
                  <div className="grid grid-cols-2 gap-3"><div className="h-16 bg-gray-100 dark:bg-gray-800 rounded-xl" /><div className="h-16 bg-gray-100 dark:bg-gray-800 rounded-xl" /></div>
                </div>
              </div>
            ))}
          </div>
        ) : contracts.length === 0 ? (
          <EmptyState icon={ShieldCheck} title="No AMC contracts" description="Create annual maintenance contracts for clients." />
        ) : (
          <div className="grid gap-4 grid-cols-1 lg:grid-cols-2 xl:grid-cols-3">
            {contracts.map((amc, i) => {
              const daysLeft = amc.days_left ?? Math.ceil((new Date(amc.end_date) - new Date()) / 86400000);
              return (
                <motion.div key={amc.id} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}>
                  <Card hover className="overflow-hidden cursor-pointer" onClick={() => navigate(`/amc/${amc.id}`)}>
                    <div className={`h-1.5 bg-gradient-to-r ${STATUS_GRAD[amc.status] || STATUS_GRAD.Expired}`} />
                    <div className="p-5">
                      <div className="flex items-start justify-between mb-3">
                        <div className="min-w-0 flex-1">
                          <p className="font-mono text-xs text-blue-500">{amc.id}</p>
                          <p className="font-bold text-gray-900 dark:text-white text-sm mt-0.5 truncate">{amc.title}</p>
                          <p className="text-xs text-gray-500 dark:text-gray-400">{amc.client_name}</p>
                        </div>
                        <div className="flex items-center gap-1 flex-shrink-0" onClick={(e) => e.stopPropagation()}>
                          <Badge label={amc.status} />
                          {canEdit && (
                            <div className="relative">
                              <button onClick={() => setMenuOpen(menuOpen === amc.id ? null : amc.id)}
                                className="p-1.5 rounded-lg text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition">
                                <MoreVertical size={16} />
                              </button>
                              <AnimatePresence>
                                {menuOpen === amc.id && (
                                  <ActionMenu onClose={() => setMenuOpen(null)} items={[
                                    { label: "View", icon: Eye, onClick: () => { setMenuOpen(null); navigate(`/amc/${amc.id}`); } },
                                    { label: "Edit", icon: Pencil, onClick: () => openEdit(amc) },
                                    { label: "Delete", icon: Trash2, danger: true, onClick: () => { setMenuOpen(null); setDeleteId(amc.id); } },
                                  ]} />
                                )}
                              </AnimatePresence>
                            </div>
                          )}
                        </div>
                      </div>

                      {amc.po_number && (
                        <div className="mb-3">
                          <span className="inline-flex items-center gap-1 text-xs bg-purple-50 dark:bg-purple-900/20 text-purple-600 dark:text-purple-400 px-2.5 py-1 rounded-full font-medium">
                            <Package size={11} /> {amc.po_number}
                          </span>
                        </div>
                      )}

                      <div className="grid grid-cols-2 gap-3 mb-4">
                        <div className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-3">
                          <p className="text-xs text-gray-400">Contract Value</p>
                          <p className="font-bold text-blue-600 dark:text-blue-400 text-base">₹{Number(amc.value).toLocaleString()}</p>
                        </div>
                        <div className={`rounded-xl p-3 ${daysLeft < 60 && daysLeft > 0 ? "bg-orange-50 dark:bg-orange-900/20" : "bg-gray-50 dark:bg-gray-700/50"}`}>
                          <p className="text-xs text-gray-400">Days Left</p>
                          <p className={`font-bold text-base ${daysLeft < 60 && daysLeft > 0 ? "text-orange-600" : daysLeft <= 0 ? "text-red-500" : "text-gray-800 dark:text-gray-200"}`}>
                            {daysLeft > 0 ? daysLeft : "Expired"}
                          </p>
                        </div>
                      </div>

                      <div className="space-y-1.5 text-xs text-gray-500 dark:text-gray-400">
                        <div className="flex items-center gap-2"><Calendar size={12} />{amc.start_date?.slice(0, 10)} → {amc.end_date?.slice(0, 10)}</div>
                        {amc.last_service_date && <div className="flex items-center gap-2"><Clock size={12} />Last service: {amc.last_service_date.slice(0, 10)}</div>}
                        {amc.next_service_date && <div className="flex items-center gap-2"><RefreshCw size={12} />Next service: {amc.next_service_date.slice(0, 10)}</div>}
                        {amc.status === "Expiring Soon" && <div className="flex items-center gap-2 text-orange-500 font-semibold"><AlertTriangle size={12} /> Renewal: {amc.renewal_reminder_days}d before</div>}
                      </div>

                      {amc.services?.length > 0 && (
                        <div className="mt-3 pt-3 border-t border-gray-100 dark:border-gray-700">
                          <div className="flex flex-wrap gap-1">
                            {amc.services.slice(0, 3).map(s => <span key={s} className="bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 text-xs px-2 py-0.5 rounded-full">{s}</span>)}
                            {amc.services.length > 3 && <span className="text-xs text-gray-400">+{amc.services.length - 3} more</span>}
                          </div>
                        </div>
                      )}
                    </div>
                  </Card>
                </motion.div>
              );
            })}
          </div>
        )}

        {/* Create Modal (Add only — edit moved to detail page) */}
        <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title="New AMC Contract" size="lg">
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <ClientAutocomplete clients={clients} value={form.client_id} onChange={(id) => setForm(p => ({ ...p, client_id: id }))} required className="col-span-2" />
              <Input label="Contract Title" value={form.title} onChange={f("title")} required className="col-span-2" />
              <Input label="PO Number" value={form.po_number} onChange={f("po_number")} placeholder="PO-2025-001" className="col-span-2" />
              <DatePicker label="Start Date" value={form.start_date} onChange={f("start_date")} required />
              <DatePicker label="End Date" value={form.end_date} onChange={f("end_date")} required />
              <DatePicker label="Last Service Date" value={form.last_service_date} onChange={f("last_service_date")} />
              <DatePicker label="Next Service Date" value={form.next_service_date} onChange={f("next_service_date")} />
              <Select label="Renewal Reminder (days)" value={form.renewal_reminder_days} onChange={f("renewal_reminder_days")} className="col-span-2"
                options={[{ value: 15, label: "15 days" }, { value: 30, label: "30 days" }, { value: 60, label: "60 days" }, { value: 90, label: "90 days" }]} />
              <div className="col-span-2">
                <Input label="Services Covered (comma-separated)" value={form.services_raw} onChange={f("services_raw")} placeholder="HVAC Servicing, Filter Replacement, Emergency Support" />
              </div>
              <Input label="Visit Count" type="number" value={form.visit_count} onChange={f("visit_count")} />
              <Input label="Pumps Count" type="number" value={form.pumps_count} onChange={f("pumps_count")} />
              <Input label="Per Pump Price (₹)" type="number" value={form.per_pump_price} onChange={f("per_pump_price")} />
              <Input label="Total Price (₹)" type="number" value={form.total_price} readOnly />
              <Input label="GST Percent" type="number" value={form.gst_percent} onChange={f("gst_percent")} />
              <Input label="Contract Value (₹)" type="number" value={form.value} readOnly className="col-span-2" required />
            </div>
            <div className="bg-blue-50 dark:bg-blue-900/10 rounded-xl p-3">
              <p className="text-xs text-blue-600 dark:text-blue-400 font-semibold mb-1">📧 Automatic Emails</p>
              <p className="text-xs text-gray-500 dark:text-gray-400">On creation — confirmation email sent to the client. Renewal reminder and service reminders are sent automatically by the system.</p>
            </div>
            <div className="flex gap-3 pt-2">
              <Button type="submit" className="flex-1" disabled={submitting}>{submitting ? "Saving…" : "Create AMC"}</Button>
              <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
            </div>
          </form>
        </Modal>

        {/* Delete confirm */}
        <Modal isOpen={!!deleteId} onClose={() => setDeleteId(null)} title="Confirm Delete" size="sm">
          <p className="text-gray-600 dark:text-gray-300 text-sm mb-5">Delete this AMC contract permanently?</p>
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