import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import {
  Plus, ShieldCheck, Calendar, RefreshCw, AlertTriangle,
  X, Building2, DollarSign, Clock, ChevronRight,
  Loader2, ExternalLink, Pencil, Trash2, Package
} from "lucide-react";
import axios from "axios";
import { useApp } from "../context/AppContext";
import {
  PageTransition, Card, Badge, Button, Modal, Input,
  Select, SectionHeader, EmptyState, useToast, Toast
} from "../components/ui";

const API_BASE_URL = "https://vaccumapi.onrender.com/api";

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
  next_service_date:     "",
};

export default function AMC() {
  const { currentUser } = useApp();
  const navigate        = useNavigate();
  const { toast, showToast } = useToast();

  const [contracts, setContracts] = useState([]);
  const [clients, setClients]     = useState([]);
  const [loading, setLoading]     = useState(true);
  const [statusFilter, setStatusFilter] = useState("All");

  const [modalOpen, setModalOpen]   = useState(false);
  const [editId, setEditId]         = useState(null);
  const [form, setForm]             = useState(EMPTY_FORM);
  const [submitting, setSubmitting] = useState(false);

  const [detail, setDetail]               = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);

  const [deleteId, setDeleteId] = useState(null);

  useEffect(() => { fetchContracts(); fetchClients(); }, []);
  useEffect(() => { fetchContracts(); }, [statusFilter]);

  // ── Fetch ─────────────────────────────────────────────────
  const fetchContracts = async () => {
    setLoading(true);
    try {
      const token  = localStorage.getItem("token");
      const params = { limit: 100 };
      if (statusFilter !== "All") params.status = statusFilter;
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
        headers: { Authorization: `Bearer ${token}` }, params: { limit: 100 },
      });
      if (res.data.success) setClients(res.data.data || []);
    } catch {}
  };

  const openDetail = async (amc) => {
    setDetail({ ...amc });
    setDetailLoading(true);
    try {
      const token = localStorage.getItem("token");
      const res   = await axios.get(`${API_BASE_URL}/amc/${amc.id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.data.success) setDetail(res.data.data);
    } catch {
      showToast("Could not load full details.", "error");
    } finally {
      setDetailLoading(false);
    }
  };

  const f = (field) => (e) => setForm(p => ({ ...p, [field]: e.target.value }));

  const openAdd = () => {
    setForm(EMPTY_FORM);
    setEditId(null);
    setModalOpen(true);
  };

  const openEdit = (amc) => {
    setForm({
      client_id:             amc.client_id             || "",
      title:                 amc.title                 || "",
      po_number:             amc.po_number             || "",
      start_date:            amc.start_date?.slice(0, 10) || "",
      end_date:              amc.end_date?.slice(0, 10)   || "",
      value:                 amc.value                 || "",
      renewal_reminder_days: amc.renewal_reminder_days || 30,
      services_raw:          (amc.services || []).join(", "),
      next_service_date:     amc.next_service_date?.slice(0, 10) || "",
    });
    setEditId(amc.id);
    setModalOpen(true);
  };

  // ── Create / Update ───────────────────────────────────────
  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    const token    = localStorage.getItem("token");
    const services = form.services_raw
      ? form.services_raw.split(",").map(s => s.trim()).filter(Boolean)
      : [];

    try {
      const payload = {
        title:                 form.title.trim(),
        value:                 parseFloat(form.value),
        renewal_reminder_days: parseInt(form.renewal_reminder_days),
        services,
        po_number:             form.po_number.trim() || undefined,
      };

      if (editId) {
        if (form.end_date)          payload.end_date          = form.end_date;
        if (form.next_service_date) payload.next_service_date = form.next_service_date;
        await axios.put(`${API_BASE_URL}/amc/${editId}`, payload, {
          headers: { Authorization: `Bearer ${token}` },
        });
        showToast("AMC contract updated!");
        if (detail?.id === editId) openDetail({ id: editId });
      } else {
        payload.client_id  = parseInt(form.client_id);
        payload.start_date = form.start_date;
        payload.end_date   = form.end_date;
        if (form.next_service_date) payload.next_service_date = form.next_service_date;
        await axios.post(`${API_BASE_URL}/amc`, payload, {
          headers: { Authorization: `Bearer ${token}` },
        });
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

  // ── Delete ────────────────────────────────────────────────
  const handleDelete = async () => {
    const token = localStorage.getItem("token");
    try {
      await axios.delete(`${API_BASE_URL}/amc/${deleteId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      showToast("AMC contract deleted", "error");
      if (detail?.id === deleteId) setDetail(null);
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
            { label: "Active",        color: "text-blue-600",   bg: "bg-blue-50   dark:bg-blue-900/20"   },
            { label: "Expiring Soon", color: "text-orange-600", bg: "bg-orange-50 dark:bg-orange-900/20" },
            { label: "Expired",       color: "text-gray-500",   bg: "bg-gray-50   dark:bg-gray-700/50"   },
          ].map(s => (
            <div key={s.label} className={`${s.bg} rounded-2xl p-4 text-center`}>
              <p className={`text-2xl font-bold ${s.color} font-display`}>
                {contracts.filter(a => a.status === s.label).length}
              </p>
              <p className="text-xs text-gray-500 dark:text-gray-400 font-medium mt-0.5">{s.label}</p>
            </div>
          ))}
        </div>

        {/* Filter tabs */}
        <div className="flex gap-2 mb-5 flex-wrap">
          {STATUS_TABS.map(s => (
            <button key={s} onClick={() => setStatusFilter(s)}
              className={`px-4 py-1.5 rounded-xl text-xs font-semibold transition
                ${statusFilter === s ? "bg-blue-600 text-white" : "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"}`}
            >{s}</button>
          ))}
        </div>

        {/* List + Detail */}
        <div className={`flex gap-5 ${detail ? "items-start" : ""}`}>

          {/* Cards */}
          <div className={detail ? "flex-1 min-w-0" : "w-full"}>
            {loading ? (
              <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
                {[...Array(3)].map((_, i) => (
                  <div key={i} className="bg-white dark:bg-gray-800 rounded-2xl overflow-hidden border border-gray-100 dark:border-gray-700 animate-pulse">
                    <div className="h-1.5 bg-gray-200 dark:bg-gray-700" />
                    <div className="p-5 space-y-3">
                      <div className="h-4 w-3/4 bg-gray-200 dark:bg-gray-700 rounded" />
                      <div className="h-3 w-1/2 bg-gray-100 dark:bg-gray-800 rounded" />
                      <div className="grid grid-cols-2 gap-3">
                        <div className="h-16 bg-gray-100 dark:bg-gray-800 rounded-xl" />
                        <div className="h-16 bg-gray-100 dark:bg-gray-800 rounded-xl" />
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : contracts.length === 0 ? (
              <EmptyState icon={ShieldCheck} title="No AMC contracts" description="Create annual maintenance contracts for clients." />
            ) : (
              <div className={`grid gap-4 ${detail ? "grid-cols-1" : "grid-cols-1 lg:grid-cols-2 xl:grid-cols-3"}`}>
                {contracts.map((amc, i) => {
                  const daysLeft = amc.days_left ?? Math.ceil((new Date(amc.end_date) - new Date()) / 86400000);
                  return (
                    <motion.div key={amc.id} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}>
                      <Card
                        hover
                        className={`overflow-hidden cursor-pointer ${detail?.id === amc.id ? "ring-2 ring-blue-500 ring-offset-2" : ""}`}
                        onClick={() => openDetail(amc)}
                      >
                        <div className={`h-1.5 bg-gradient-to-r ${STATUS_GRAD[amc.status] || STATUS_GRAD.Expired}`} />
                        <div className="p-5">
                          <div className="flex items-start justify-between mb-3">
                            <div>
                              <p className="font-mono text-xs text-blue-500">{amc.id}</p>
                              <p className="font-bold text-gray-900 dark:text-white text-sm mt-0.5">{amc.title}</p>
                              <p className="text-xs text-gray-500 dark:text-gray-400">{amc.client_name}</p>
                            </div>
                            <Badge label={amc.status} />
                          </div>

                          {/* PO Number badge */}
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
                            <div className="flex items-center gap-2">
                              <Calendar size={12} />
                              {amc.start_date?.slice(0, 10)} → {amc.end_date?.slice(0, 10)}
                            </div>
                            {amc.next_service_date && (
                              <div className="flex items-center gap-2">
                                <RefreshCw size={12} />
                                Next service: {amc.next_service_date.slice(0, 10)}
                              </div>
                            )}
                            {amc.status === "Expiring Soon" && (
                              <div className="flex items-center gap-2 text-orange-500 font-semibold">
                                <AlertTriangle size={12} /> Renewal reminder: {amc.renewal_reminder_days}d before
                              </div>
                            )}
                          </div>

                          {amc.services?.length > 0 && (
                            <div className="mt-3 pt-3 border-t border-gray-100 dark:border-gray-700">
                              <div className="flex flex-wrap gap-1">
                                {amc.services.slice(0, 3).map(s => (
                                  <span key={s} className="bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 text-xs px-2 py-0.5 rounded-full">{s}</span>
                                ))}
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
          </div>

          {/* Detail panel */}
          <AnimatePresence>
            {detail && (
              <motion.div
                key="amc-detail"
                initial={{ opacity: 0, x: 40 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 40 }}
                transition={{ type: "spring", damping: 28, stiffness: 280 }}
                className="w-full lg:w-96 flex-shrink-0 bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 shadow-lg overflow-hidden sticky top-4"
              >
                <div className={`h-1.5 bg-gradient-to-r ${STATUS_GRAD[detail.status] || STATUS_GRAD.Expired}`} />
                <div className="p-5 border-b border-gray-100 dark:border-gray-700">
                  <div className="flex items-start justify-between">
                    <div>
                      <p className="font-mono text-xs text-blue-500 font-bold">{detail.id}</p>
                      <p className="font-bold text-gray-900 dark:text-white mt-0.5">{detail.title}</p>
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">{detail.client_name}</p>
                    </div>
                    <button onClick={() => setDetail(null)} className="p-1.5 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 rounded-lg transition">
                      <X size={16} />
                    </button>
                  </div>
                  <div className="flex items-center gap-2 mt-3 flex-wrap">
                    <Badge label={detail.status} />
                    {detail.po_number && (
                      <span className="inline-flex items-center gap-1 text-xs bg-purple-50 dark:bg-purple-900/20 text-purple-600 dark:text-purple-400 px-2 py-0.5 rounded-full">
                        <Package size={10} /> {detail.po_number}
                      </span>
                    )}
                    {detailLoading && <Loader2 size={12} className="animate-spin text-gray-400" />}
                  </div>
                </div>

                <div className="p-5 space-y-5 max-h-[calc(100vh-220px)] overflow-y-auto">
                  {/* Value + days */}
                  <div className="grid grid-cols-2 gap-3">
                    <div className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-3">
                      <p className="text-[10px] text-gray-400 uppercase tracking-wide mb-0.5">Value</p>
                      <p className="font-bold text-blue-600 dark:text-blue-400">₹{Number(detail.value || 0).toLocaleString()}</p>
                    </div>
                    <div className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-3">
                      <p className="text-[10px] text-gray-400 uppercase tracking-wide mb-0.5">Days Left</p>
                      <p className={`font-bold ${(detail.days_left ?? 0) < 60 ? "text-orange-600" : "text-gray-800 dark:text-white"}`}>
                        {detail.days_left ?? "—"}
                      </p>
                    </div>
                  </div>

                  {/* Dates */}
                  <div className="space-y-2.5">
                    <p className="text-xs font-bold text-gray-400 uppercase tracking-widest">Contract Period</p>
                    {[
                      { label: "Start Date",    value: detail.start_date?.slice(0, 10) },
                      { label: "End Date",      value: detail.end_date?.slice(0, 10) },
                      { label: "Next Service",  value: detail.next_service_date?.slice(0, 10) },
                      { label: "Renewal Alert", value: `${detail.renewal_reminder_days} days before expiry` },
                    ].map(item => (
                      <div key={item.label} className="flex items-center justify-between">
                        <span className="text-xs text-gray-500 dark:text-gray-400">{item.label}</span>
                        <span className="text-xs font-semibold text-gray-800 dark:text-white">{item.value || "—"}</span>
                      </div>
                    ))}
                  </div>

                  {/* Services */}
                  {detail.services?.length > 0 && (
                    <div>
                      <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">Services Covered</p>
                      <div className="flex flex-wrap gap-1.5">
                        {detail.services.map(s => (
                          <span key={s} className="bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 text-xs px-2.5 py-1 rounded-full font-medium">{s}</span>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Email reminders info */}
                  <div className="bg-blue-50 dark:bg-blue-900/10 rounded-xl p-3 space-y-1.5">
                    <p className="text-xs font-bold text-blue-600 dark:text-blue-400 uppercase tracking-wide">Auto Email Reminders</p>
                    <p className="text-xs text-gray-500 dark:text-gray-400">✉️ Creation confirmation sent to client</p>
                    <p className="text-xs text-gray-500 dark:text-gray-400">⚠️ Renewal reminder {detail.renewal_reminder_days} days before expiry</p>
                    {detail.next_service_date && <p className="text-xs text-gray-500 dark:text-gray-400">🔔 Service reminder 10 days before {detail.next_service_date?.slice(0, 10)}</p>}
                  </div>

                  {/* Actions */}
                  {canEdit && (
                    <div className="flex gap-2 pt-1">
                      <Button className="flex-1" onClick={() => openEdit(detail)}>
                        <Pencil size={14} className="mr-1.5" /> Edit
                      </Button>
                      <Button variant="danger" onClick={() => setDeleteId(detail.id)}>
                        <Trash2 size={14} />
                      </Button>
                    </div>
                  )}
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* Create / Edit Modal */}
        <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editId ? "Edit AMC Contract" : "New AMC Contract"} size="lg">
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              {!editId && (
                <Select label="Client" value={form.client_id} onChange={f("client_id")} required className="col-span-2"
                  options={[{ value: "", label: "Select client..." }, ...clients.map(c => ({ value: c.id, label: c.name }))]} />
              )}
              <Input label="Contract Title" value={form.title} onChange={f("title")} required className="col-span-2" />
              <Input
                label="PO Number"
                value={form.po_number}
                onChange={f("po_number")}
                placeholder="PO-2025-001"
                className="col-span-2"
              />
              {!editId && <Input label="Start Date" type="date" value={form.start_date} onChange={f("start_date")} required />}
              <Input label="End Date"   type="date" value={form.end_date}   onChange={f("end_date")}   required={!editId} />
              <Input label="Contract Value (₹)" type="number" value={form.value} onChange={f("value")} required />
              <Input label="Next Service Date"  type="date"   value={form.next_service_date} onChange={f("next_service_date")} />
              <Select label="Renewal Reminder (days)" value={form.renewal_reminder_days} onChange={f("renewal_reminder_days")} className="col-span-2"
                options={[{ value: 15, label: "15 days" }, { value: 30, label: "30 days" }, { value: 60, label: "60 days" }, { value: 90, label: "90 days" }]} />
              <div className="col-span-2">
                <Input label="Services Covered (comma-separated)" value={form.services_raw} onChange={f("services_raw")}
                  placeholder="HVAC Servicing, Filter Replacement, Emergency Support" />
              </div>
            </div>

            {!editId && (
              <div className="bg-blue-50 dark:bg-blue-900/10 rounded-xl p-3">
                <p className="text-xs text-blue-600 dark:text-blue-400 font-semibold mb-1">📧 Automatic Emails</p>
                <p className="text-xs text-gray-500 dark:text-gray-400">On creation — confirmation email sent to the client. Renewal reminder and service reminders are sent automatically by the system.</p>
              </div>
            )}

            <div className="flex gap-3 pt-2">
              <Button type="submit" className="flex-1" disabled={submitting}>
                {submitting ? "Saving…" : (editId ? "Update AMC" : "Create AMC")}
              </Button>
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