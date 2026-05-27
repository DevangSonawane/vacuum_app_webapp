import { useState, useEffect, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  Plus, Pencil, Trash2, Users, Phone, Mail, MapPin, Building2,
  X, Briefcase, ShieldCheck, TrendingUp, Loader2,
  Calendar, DollarSign, FileText, ChevronLeft, ChevronRight, Search
} from "lucide-react";
import axios from "axios";
import { useApp } from "../context/AppContext";
import {
  PageTransition, Card, Badge, Button, Modal, Input, Select,
  SectionHeader, EmptyState, useToast, Toast, PageLoader
} from "../components/ui";

const API_BASE_URL = "https://vaccumapi-o4ol.onrender.com/api";

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

export default function Clients() {
  const { currentUser } = useApp();
  const { toast, showToast } = useToast();

  const [activeTab, setActiveTab]   = useState("Local"); // "Local" or "ERP"
  const [clients, setClients]       = useState([]);
  const [loading, setLoading]       = useState(true);
  const [totalClients, setTotalClients] = useState(0);
  const [search, setSearch]         = useState("");
  const [filterType, setFilterType] = useState("All");
  const [page, setPage]             = useState(1);
  const limit = 10;

  // ERP State
  const [erpCustomers, setErpCustomers] = useState([]);
  const [erpLoading, setErpLoading]     = useState(false);
  const [erpTotal, setErpTotal]         = useState(0);
  const [erpFilters, setErpFilters]     = useState({
    page: 1,
    limit: 10,
    search: "",
    status: "",
  });
  const [debouncedErpSearch, setDebouncedErpSearch] = useState("");

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedErpSearch(erpFilters.search);
    }, 500);
    return () => clearTimeout(timer);
  }, [erpFilters.search]);

  const [modalOpen, setModalOpen]   = useState(false);
  const [editId, setEditId]         = useState(null);
  const [form, setForm]             = useState(EMPTY);
  const [submitting, setSubmitting] = useState(false);
  const [deleteId, setDeleteId]     = useState(null);

  const [detailClient, setDetailClient]   = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [detailErpCustomer, setDetailErpCustomer] = useState(null);

  useEffect(() => { 
    if (activeTab === "Local") fetchClients(); 
  }, [activeTab]);

  const fetchClients = async (searchTerm = "", type = "All", p = 1) => {
    if (activeTab !== "Local") return;
    setLoading(true);
    try {
      const token  = localStorage.getItem("token");
      const params = { page: p, limit };
      if (searchTerm)     params.search = searchTerm;
      if (type !== "All") params.type   = type;
      const res = await axios.get(`${API_BASE_URL}/clients`, {
        headers: { Authorization: `Bearer ${token}` }, params,
      });
      if (res.data.success) {
        setClients(res.data.data || []);
        setTotalClients(res.data.count || res.data.data?.length || 0);
      }
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to fetch clients", "error");
    } finally {
      setLoading(false);
    }
  };

  const fetchErpCustomers = useCallback(async () => {
    if (activeTab !== "ERP") return;
    setErpLoading(true);
    try {
      const token = localStorage.getItem("token");
      const params = {
        page: erpFilters.page,
        limit: erpFilters.limit,
      };
      if (debouncedErpSearch) params.search = debouncedErpSearch;
      if (erpFilters.status) params.status = erpFilters.status;

      const res = await axios.get(`${API_BASE_URL}/erp/customers`, {
        headers: { Authorization: `Bearer ${token}` },
        params,
      });
      if (res.data.success) {
        const data = res.data.data || [];
        setErpCustomers(data);
        setErpTotal(res.data.count || data.length);
      }
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to fetch ERP customers", "error");
    } finally {
      setErpLoading(false);
    }
  }, [erpFilters.page, erpFilters.limit, erpFilters.status, debouncedErpSearch, activeTab, showToast]);

  useEffect(() => {
    if (activeTab === "ERP") fetchErpCustomers();
  }, [fetchErpCustomers, activeTab]);

  useEffect(() => {
    if (activeTab === "Local") {
      const t = setTimeout(() => fetchClients(search, filterType, page), 400);
      return () => clearTimeout(t);
    }
  }, [search, filterType, activeTab, page]);

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
      fetchClients(search, filterType);
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
      fetchClients(search, filterType);
    } catch (err) {
      showToast(err.response?.data?.message || "Delete failed", "error");
      setDeleteId(null);
    }
  };

  const canEdit     = currentUser?.role !== "technician";
  const activeCount = clients.filter(c => c.status === "Active").length;
  const erpTotalPages = Math.ceil(erpTotal / erpFilters.limit);

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-7xl mx-auto">
        <SectionHeader
          title="Clients"
          subtitle={activeTab === "Local" ? `${activeCount} active local clients` : `${erpTotal} total ERP customers`}
          action={activeTab === "Local" && canEdit && <Button onClick={openAdd}><Plus size={16} /> Add Client</Button>}
        />

        {/* Tab Switcher */}
        <div className="flex gap-2 mb-6 border-b border-gray-100 dark:border-gray-700 pb-px">
          {["Local", "ERP"].map(t => (
            <button
              key={t}
              onClick={() => { setActiveTab(t); setDetailClient(null); }}
              className={`px-6 py-2.5 text-sm font-bold transition-all relative ${activeTab === t ? "text-blue-600" : "text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"}`}
            >
              {t} Clients
              {activeTab === t && <motion.div layoutId="activeTab" className="absolute bottom-0 left-0 right-0 h-0.5 bg-blue-600" />}
            </button>
          ))}
        </div>

        {activeTab === "Local" ? (
          <>
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
              {/* Client Cards */}
              <div className={`${detailClient ? "flex-1 min-w-0" : "w-full"}`}>
                {loading ? (
                  <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                    {[...Array(4)].map((_, i) => (
                      <div key={i} className="bg-white dark:bg-gray-800 rounded-2xl p-5 border border-gray-100 dark:border-gray-700 animate-pulse">
                        <div className="flex items-center gap-3 mb-4">
                          <div className="w-11 h-11 rounded-xl bg-gray-200 dark:bg-gray-700" />
                          <div className="space-y-2 flex-1">
                            <div className="h-4 w-32 bg-gray-200 dark:bg-gray-700 rounded" />
                            <div className="h-3 w-24 bg-gray-100 dark:bg-gray-800 rounded" />
                          </div>
                        </div>
                        <div className="space-y-2">
                          <div className="h-3 w-full bg-gray-100 dark:bg-gray-800 rounded" />
                          <div className="h-3 w-3/4 bg-gray-100 dark:bg-gray-800 rounded" />
                        </div>
                      </div>
                    ))}
                  </div>
                ) : clients.length === 0 ? (
                  <EmptyState icon={Users} title="No clients found" description="Adjust your filters or add a new client." />
                ) : (
                  <div className={`grid gap-4 ${detailClient ? "grid-cols-1" : "grid-cols-1 lg:grid-cols-2"}`}>
                    {clients.map((c, i) => (
                      <motion.div key={c.id} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.04 }}>
                        <Card
                          hover
                          className={`p-5 cursor-pointer transition-all ${detailClient?.id === c.id ? "ring-2 ring-blue-500 ring-offset-2" : ""}`}
                          onClick={() => openDetail(c)}
                        >
                          <div className="flex items-start justify-between mb-3">
                            <div className="flex items-center gap-3">
                              <div className="w-11 h-11 rounded-xl bg-gradient-to-br from-blue-500 to-blue-700 flex items-center justify-center flex-shrink-0">
                                <Building2 size={20} className="text-white" />
                              </div>
                              <div>
                                <p className="font-bold text-gray-900 dark:text-white">{c.name}</p>
                                <p className="text-gray-500 dark:text-gray-400 text-xs">{c.contact_person}</p>
                              </div>
                            </div>
                            <div className="flex flex-col items-end gap-1">
                              <Badge label={c.status} />
                              <span className={`text-xs px-2 py-0.5 rounded-full font-semibold ${TYPE_COLORS[c.type] || "bg-gray-100 text-gray-600"}`}>{c.type}</span>
                            </div>
                          </div>

                          <div className="space-y-1.5 text-xs text-gray-500 dark:text-gray-400 mb-4">
                            {c.email   && <div className="flex items-center gap-2"><Mail   size={12} />{c.email}</div>}
                            {c.phone   && <div className="flex items-center gap-2"><Phone  size={12} />{c.phone}</div>}
                            {c.address && <div className="flex items-center gap-2"><MapPin size={12} />{c.address}</div>}
                            {c.gst_no  && (
                              <div className="flex items-center gap-2">
                                <FileText size={12} />
                                <span className="font-mono">GST: {c.gst_no}</span>
                              </div>
                            )}
                          </div>

                          <div className="flex items-center justify-between pt-3 border-t border-gray-100 dark:border-gray-700">
                            <div>
                              <p className="text-xs text-gray-400">Contract Value</p>
                              <p className="font-bold text-gray-800 dark:text-white text-sm">
                                ₹{Number(c.contract_value || 0).toLocaleString()}
                              </p>
                            </div>
                            <div className="text-right">
                              <p className="text-xs text-gray-400">Since</p>
                              <p className="text-sm font-medium text-gray-600 dark:text-gray-300">
                                {c.join_date ? c.join_date.slice(0, 10) : "—"}
                              </p>
                            </div>
                            {canEdit && (
                              <div className="flex gap-2" onClick={e => e.stopPropagation()}>
                                <Button variant="secondary" size="sm" onClick={() => openEdit(c)}><Pencil size={13} /></Button>
                                <Button variant="danger"    size="sm" onClick={() => setDeleteId(c.id)}><Trash2 size={13} /></Button>
                              </div>
                            )}
                          </div>
                        </Card>
                      </motion.div>
                    ))}
                  </div>
                )}

                {/* Local Pagination */}
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
                        {[...Array(Math.ceil(totalClients / limit))].map((_, i) => {
                          const pageNum = i + 1;
                          const totalPages = Math.ceil(totalClients / limit);
                          if (totalPages > 5 && (pageNum < page - 1 || pageNum > page + 1) && pageNum !== 1 && pageNum !== totalPages) {
                            if (pageNum === 2 || pageNum === totalPages - 1) return <span key={pageNum} className="px-2">...</span>;
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
                      <Button variant="secondary" size="sm" disabled={page === Math.ceil(totalClients / limit)} onClick={() => setPage(p => p + 1)}>
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
                            <Pencil size={14} className="mr-1.5" /> Edit Client
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
          </>
        ) : (
          /* ERP TAB CONTENT */
          <>
            <div className="bg-white dark:bg-gray-800 p-4 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 mb-6 space-y-4 md:space-y-0 md:flex md:items-end md:gap-4">
              <div className="flex-1">
                <Input 
                  label="Search" 
                  placeholder="Search name, phone or email..." 
                  value={erpFilters.search} 
                  onChange={e => setErpFilters(p => ({ ...p, search: e.target.value, page: 1 }))}
                />
              </div>
              <div className="w-full md:w-48">
                <Select 
                  label="Status" 
                  value={erpFilters.status} 
                  onChange={e => setErpFilters(p => ({ ...p, status: e.target.value, page: 1 }))}
                  options={[
                    { value: "", label: "All Status" },
                    { value: "Active", label: "Active" },
                    { value: "Inactive", label: "Inactive" }
                  ]}
                />
              </div>
              <Button variant="secondary" onClick={() => setErpFilters({ page: 1, limit: 10, search: "", status: "" })}>
                Reset
              </Button>
            </div>

            {erpLoading ? (
              <div className="py-20 flex justify-center"><PageLoader /></div>
            ) : erpCustomers.length === 0 ? (
              <EmptyState icon={Users} title="No ERP customers found" description="Try adjusting your filters." />
            ) : (
              <>
                <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
                  {erpCustomers.map((c, i) => (
                    <motion.div key={c.CustId || c.id} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.04 }}>
                      <Card hover className="p-5 cursor-pointer" onClick={() => setDetailErpCustomer(c)}>
                        <div className="flex items-start justify-between mb-3">
                          <div className="flex items-center gap-3">
                            <div className="w-11 h-11 rounded-xl bg-gradient-to-br from-blue-500 to-blue-700 flex items-center justify-center flex-shrink-0">
                              <Building2 size={20} className="text-white" />
                            </div>
                            <div>
                              <p className="font-bold text-gray-900 dark:text-white">{c.CustName || c.name}</p>
                              <p className="text-gray-500 dark:text-gray-400 text-xs">Code: {c.CustCode || c.id}</p>
                            </div>
                          </div>
                          <Badge label={c.status || "Active"} />
                        </div>

                        <div className="space-y-1.5 text-xs text-gray-500 dark:text-gray-400">
                          {(c.EmailId || c.email) && <div className="flex items-center gap-2"><Mail size={12} />{c.EmailId || c.email}</div>}
                          {(c.ContactNo || c.phone) && <div className="flex items-center gap-2"><Phone size={12} />{c.ContactNo || c.phone}</div>}
                          {(c.CustAdd || c.address) && <div className="flex items-center gap-2 line-clamp-1"><MapPin size={12} />{c.CustAdd || c.address}</div>}
                        </div>
                      </Card>
                    </motion.div>
                  ))}
                </div>

                {/* ERP Pagination */}
                <div className="mt-8 pt-6 border-t border-gray-100 dark:border-gray-700 flex flex-col sm:flex-row items-center justify-between gap-4">
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    Showing <span className="font-semibold text-gray-900 dark:text-white">{(erpFilters.page - 1) * erpFilters.limit + 1}</span> to <span className="font-semibold text-gray-900 dark:text-white">{Math.min(erpFilters.page * erpFilters.limit, erpTotal)}</span> of <span className="font-semibold text-gray-900 dark:text-white">{erpTotal}</span> results
                  </p>
                  <div className="flex gap-2">
                    <Button 
                      variant="secondary" 
                      size="sm" 
                      disabled={erpFilters.page === 1}
                      onClick={() => setErpFilters(p => ({ ...p, page: p.page - 1 }))}
                    >
                      <ChevronLeft size={16} /> Previous
                    </Button>
                    <div className="flex gap-1">
                      {[...Array(erpTotalPages)].map((_, i) => {
                        const pageNum = i + 1;
                        if (erpTotalPages > 5 && (pageNum < erpFilters.page - 1 || pageNum > erpFilters.page + 1) && pageNum !== 1 && pageNum !== erpTotalPages) {
                          if (pageNum === 2 || pageNum === erpTotalPages - 1) return <span key={pageNum} className="px-2">...</span>;
                          return null;
                        }
                        return (
                          <button
                            key={pageNum}
                            onClick={() => setErpFilters(p => ({ ...p, page: pageNum }))}
                            className={`w-8 h-8 rounded-lg text-sm font-medium transition-all ${erpFilters.page === pageNum ? "bg-blue-600 text-white" : "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"}`}
                          >
                            {pageNum}
                          </button>
                        );
                      })}
                    </div>
                    <Button 
                      variant="secondary" 
                      size="sm" 
                      disabled={erpFilters.page === erpTotalPages}
                      onClick={() => setErpFilters(p => ({ ...p, page: p.page + 1 }))}
                    >
                      Next <ChevronRight size={16} />
                    </Button>
                  </div>
                </div>
              </>
            )}
          </>
        )}

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
              <Select label="Type"   value={form.type}   onChange={f("type")}   options={TYPES} />
              <Select label="Status" value={form.status} onChange={f("status")} options={["Active", "Inactive"]} />
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

        {/* ERP Detail Modal */}
        {detailErpCustomer && (
          <Modal isOpen={!!detailErpCustomer} onClose={() => setDetailErpCustomer(null)} title={detailErpCustomer.CustName || detailErpCustomer.name} size="lg">
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div><p className="text-xs text-gray-400">Customer ID</p><p className="font-mono font-semibold text-blue-600">{detailErpCustomer.CustId || detailErpCustomer.id}</p></div>
                <div><p className="text-xs text-gray-400">Customer Code</p><p className="font-medium text-gray-800 dark:text-gray-200">{detailErpCustomer.CustCode || "N/A"}</p></div>
                <div><p className="text-xs text-gray-400">Status</p><Badge label={detailErpCustomer.status || "Active"} /></div>
                <div><p className="text-xs text-gray-400">Type ID</p><p className="font-medium text-gray-800 dark:text-gray-200">{detailErpCustomer.CustTypeId}</p></div>
              </div>

              <div className="space-y-2.5 pt-2">
                <p className="text-xs font-bold text-gray-400 uppercase tracking-widest">Contact Information</p>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <div className="flex items-center gap-3 text-sm text-gray-700 dark:text-gray-300">
                    <div className="w-7 h-7 rounded-lg bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center flex-shrink-0">
                      <Mail size={13} className="text-blue-500" />
                    </div>
                    <span className="break-all">{detailErpCustomer.EmailId || detailErpCustomer.email || "N/A"}</span>
                  </div>
                  <div className="flex items-center gap-3 text-sm text-gray-700 dark:text-gray-300">
                    <div className="w-7 h-7 rounded-lg bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center flex-shrink-0">
                      <Phone size={13} className="text-blue-500" />
                    </div>
                    <span>{detailErpCustomer.ContactNo || detailErpCustomer.phone || "N/A"}</span>
                  </div>
                </div>
              </div>

              <div className="space-y-2.5 pt-2">
                <p className="text-xs font-bold text-gray-400 uppercase tracking-widest">Address Information</p>
                <div className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-4 space-y-2">
                  <div className="flex items-start gap-3 text-sm text-gray-700 dark:text-gray-300">
                    <MapPin size={15} className="text-blue-500 mt-0.5 flex-shrink-0" />
                    <div>
                      <p>{detailErpCustomer.CustAdd || detailErpCustomer.address || "N/A"}</p>
                      {detailErpCustomer.CustAdd1 && <p>{detailErpCustomer.CustAdd1}</p>}
                      {detailErpCustomer.CustAdd2 && <p>{detailErpCustomer.CustAdd2}</p>}
                      <p className="mt-1 font-semibold">
                        {detailErpCustomer.PinCode && `Pin: ${detailErpCustomer.PinCode}`}
                        {detailErpCustomer.StateCode && ` | State: ${detailErpCustomer.StateCode}`}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </Modal>
        )}

        {toast && <Toast {...toast} onClose={() => {}} />}
      </div>
    </PageTransition>
  );
}