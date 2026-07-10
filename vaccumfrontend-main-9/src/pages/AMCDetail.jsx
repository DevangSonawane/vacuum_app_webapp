import { useState, useEffect, useRef } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import {
  ArrowLeft, ShieldCheck, Calendar, Clock, DollarSign,
  Package, RefreshCw, MoreVertical, Pencil, Trash2,
  Loader2, AlertTriangle, Eye, Mail, Bell,
} from "lucide-react";
import axios from "axios";
import { useApp } from "../context/AppContext";
import {
  PageTransition, Badge, Button, Card, Input, Select,
  DatePicker, Modal, useToast, Toast,
} from "../components/ui";

const API_BASE_URL = "https://api.vdtil.com/api";

const STATUS_GRAD = {
  Active:          "from-blue-500 to-blue-700",
  "Expiring Soon": "from-orange-500 to-orange-700",
  Expired:         "from-gray-400 to-gray-600",
};

const STATUS_STYLES = {
  Active:          { dot: "bg-blue-500",   bg: "bg-blue-50 dark:bg-blue-900/20",     text: "text-blue-700 dark:text-blue-300" },
  "Expiring Soon": { dot: "bg-orange-500", bg: "bg-orange-50 dark:bg-orange-900/20", text: "text-orange-700 dark:text-orange-300" },
  Expired:         { dot: "bg-gray-400",   bg: "bg-gray-100 dark:bg-gray-700/50",    text: "text-gray-600 dark:text-gray-400" },
};

function formatDate(raw) {
  if (!raw) return "—";
  const d = new Date(raw);
  if (isNaN(d)) return raw;
  return d.toLocaleDateString("en-IN", { year: "numeric", month: "short", day: "numeric" });
}

function ActionMenu({ items, onClose }) {
  const ref = useRef();
  useEffect(() => {
    const handler = (e) => {
      if (ref.current && !ref.current.contains(e.target)) onClose();
    };
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

export default function AMCDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { currentUser } = useApp();
  const { toast, showToast } = useToast();

  const [amc, setAmc] = useState(null);
  const [loading, setLoading] = useState(true);

  const [menuOpen, setMenuOpen] = useState(false);

  const [editOpen, setEditOpen] = useState(false);
  const [editForm, setEditForm] = useState({});
  const [editSaving, setEditSaving] = useState(false);

  const [deleteOpen, setDeleteOpen] = useState(false);

  useEffect(() => {
    fetchAmc();
  }, [id]);

  const fetchAmc = async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem("token");
      const res = await axios.get(`${API_BASE_URL}/amc/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.data.success) {
        setAmc(res.data.data);
      } else {
        showToast("Contract not found", "error");
      }
    } catch {
      showToast("Failed to load contract", "error");
    } finally {
      setLoading(false);
    }
  };

  const openEdit = () => {
    setMenuOpen(false);
    setEditForm({
      title: amc.title || "",
      po_number: amc.po_number || "",
      end_date: amc.end_date?.slice(0, 10) || "",
      last_service_date: amc.last_service_date?.slice(0, 10) || "",
      next_service_date: amc.next_service_date?.slice(0, 10) || "",
      renewal_reminder_days: amc.renewal_reminder_days || 30,
      services_raw: (amc.services || []).join(", "),
      visit_count: amc.visit_count || "",
      pumps_count: amc.pumps_count || "",
      per_pump_price: amc.per_pump_price || "",
      total_price: amc.total_price || "",
      gst_percent: amc.gst_percent || "",
      value: amc.value || "",
    });
    setEditOpen(true);
  };

  const ef = (field) => (e) => {
    const value = e.target.value;
    setEditForm((prev) => {
      const updated = { ...prev, [field]: value };

      if (field === "pumps_count" || field === "per_pump_price") {
        const pumps = parseFloat(updated.pumps_count) || 0;
        const perPump = parseFloat(updated.per_pump_price) || 0;
        updated.total_price = pumps * perPump;
      }

      if (
        field === "total_price" ||
        field === "gst_percent" ||
        field === "pumps_count" ||
        field === "per_pump_price"
      ) {
        const total = parseFloat(updated.total_price) || 0;
        const gst = parseFloat(updated.gst_percent) || 0;
        const gstAmount = total * (gst / 100);
        updated.value = total + gstAmount;
      }

      return updated;
    });
  };

  const handleEdit = async (e) => {
    e.preventDefault();
    setEditSaving(true);
    try {
      const token = localStorage.getItem("token");
      const services = editForm.services_raw
        ? editForm.services_raw.split(",").map((s) => s.trim()).filter(Boolean)
        : [];

      const payload = {
        title: editForm.title.trim(),
        value: parseFloat(editForm.value),
        renewal_reminder_days: parseInt(editForm.renewal_reminder_days),
        services,
        po_number: editForm.po_number.trim() || undefined,
        visit_count: editForm.visit_count ? parseInt(editForm.visit_count) : undefined,
        pumps_count: editForm.pumps_count ? parseInt(editForm.pumps_count) : undefined,
        per_pump_price: editForm.per_pump_price ? parseFloat(editForm.per_pump_price) : undefined,
        total_price: editForm.total_price ? parseFloat(editForm.total_price) : undefined,
        gst_percent: editForm.gst_percent ? parseFloat(editForm.gst_percent) : undefined,
      };

      if (editForm.end_date) payload.end_date = editForm.end_date;
      if (editForm.last_service_date) payload.last_service_date = editForm.last_service_date;
      if (editForm.next_service_date) payload.next_service_date = editForm.next_service_date;

      await axios.put(`${API_BASE_URL}/amc/${id}`, payload, {
        headers: { Authorization: `Bearer ${token}` },
      });
      showToast("AMC contract updated!");
      setEditOpen(false);
      fetchAmc();
    } catch (err) {
      showToast(err.response?.data?.message || "Update failed", "error");
    } finally {
      setEditSaving(false);
    }
  };

  const handleDelete = async () => {
    try {
      const token = localStorage.getItem("token");
      await axios.delete(`${API_BASE_URL}/amc/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      showToast("AMC contract deleted");
      navigate("/amc");
    } catch (err) {
      showToast(err.response?.data?.message || "Delete failed", "error");
      setDeleteOpen(false);
    }
  };

  const canEdit = !["technician", "labour"].includes(currentUser?.role);

  // ── Loading skeleton ────────────────────────────────────────
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
              {[...Array(4)].map((_, i) => (
                <div key={i} className="h-24 bg-gray-100 dark:bg-gray-800 rounded-2xl" />
              ))}
            </div>
            <div className="h-64 bg-gray-100 dark:bg-gray-800 rounded-2xl" />
          </div>
        </div>
      </PageTransition>
    );
  }

  // ── Not found ───────────────────────────────────────────────
  if (!amc) {
    return (
      <PageTransition>
        <div className="p-8 text-center text-gray-400">
          <ShieldCheck size={40} className="mx-auto mb-3 opacity-30" />
          <p className="font-medium">Contract not found</p>
          <Button className="mt-4" onClick={() => navigate("/amc")}>
            Back to AMC
          </Button>
        </div>
      </PageTransition>
    );
  }

  const ss = STATUS_STYLES[amc.status] || STATUS_STYLES.Active;
  const daysLeft = amc.days_left ?? Math.ceil((new Date(amc.end_date) - new Date()) / 86400000);

  return (
    <PageTransition>
      <div className="p-4 md:p-8 max-w-6xl mx-auto space-y-5">
        {/* Top gradient bar */}
        <div className={`h-1.5 rounded-full bg-gradient-to-r ${STATUS_GRAD[amc.status] || STATUS_GRAD.Expired}`} />

        {/* Header */}
        <div className="flex items-start gap-3">
          <button
            onClick={() => navigate("/amc")}
            className="mt-1 p-2 rounded-xl text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-800 transition flex-shrink-0"
          >
            <ArrowLeft size={20} />
          </button>
          <div className="flex-1 min-w-0">
            <div className="flex flex-wrap items-center gap-3">
              <div className="min-w-0 flex-1">
                <p className="font-mono text-xs text-blue-500 font-bold">{amc.id}</p>
                <h1 className="text-xl md:text-2xl font-bold text-gray-900 dark:text-white leading-tight truncate">
                  {amc.title}
                </h1>
                <p className="text-sm text-gray-500 dark:text-gray-400">{amc.client_name}</p>
              </div>
              <div className="flex items-center gap-2 flex-shrink-0">
                <div
                  className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-xs md:text-sm font-semibold ${ss.bg} ${ss.text}`}
                >
                  <span className={`w-2 h-2 rounded-full ${ss.dot}`} />
                  {amc.status}
                </div>
                {canEdit && (
                  <div className="relative">
                    <button
                      onClick={() => setMenuOpen(!menuOpen)}
                      className="p-2 rounded-xl text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-800 transition"
                    >
                      <MoreVertical size={20} />
                    </button>
                    <AnimatePresence>
                      {menuOpen && (
                        <ActionMenu
                          onClose={() => setMenuOpen(false)}
                          items={[
                            { label: "Edit", icon: Pencil, onClick: openEdit },
                            {
                              label: "Delete",
                              icon: Trash2,
                              danger: true,
                              onClick: () => {
                                setMenuOpen(false);
                                setDeleteOpen(true);
                              },
                            },
                          ]}
                        />
                      )}
                    </AnimatePresence>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Info cards */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          <Card className="p-3 md:p-4">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 md:w-10 md:h-10 rounded-xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center flex-shrink-0">
                <DollarSign size={16} className="text-blue-500" />
              </div>
              <div className="min-w-0">
                <p className="text-[11px] text-gray-400 font-medium">Contract Value</p>
                <p className="text-xs md:text-sm font-semibold text-blue-600 dark:text-blue-400 truncate">
                  ₹{Number(amc.value || 0).toLocaleString()}
                </p>
              </div>
            </div>
          </Card>
          <Card className="p-3 md:p-4">
            <div className="flex items-center gap-3">
              <div
                className={`w-9 h-9 md:w-10 md:h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${
                  daysLeft <= 0
                    ? "bg-red-50 dark:bg-red-900/20"
                    : daysLeft < 60
                    ? "bg-orange-50 dark:bg-orange-900/20"
                    : "bg-emerald-50 dark:bg-emerald-900/20"
                }`}
              >
                <Clock
                  size={16}
                  className={
                    daysLeft <= 0
                      ? "text-red-500"
                      : daysLeft < 60
                      ? "text-orange-500"
                      : "text-emerald-500"
                  }
                />
              </div>
              <div className="min-w-0">
                <p className="text-[11px] text-gray-400 font-medium">Days Left</p>
                <p
                  className={`text-xs md:text-sm font-semibold ${
                    daysLeft <= 0
                      ? "text-red-500"
                      : daysLeft < 60
                      ? "text-orange-600"
                      : "text-gray-800 dark:text-gray-200"
                  }`}
                >
                  {daysLeft > 0 ? daysLeft : "Expired"}
                </p>
              </div>
            </div>
          </Card>
          <Card className="p-3 md:p-4">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 md:w-10 md:h-10 rounded-xl bg-purple-50 dark:bg-purple-900/20 flex items-center justify-center flex-shrink-0">
                <Eye size={16} className="text-purple-500" />
              </div>
              <div className="min-w-0">
                <p className="text-[11px] text-gray-400 font-medium">Visit Count</p>
                <p className="text-xs md:text-sm font-semibold text-gray-800 dark:text-gray-200">
                  {amc.visit_count ?? "—"}
                </p>
              </div>
            </div>
          </Card>
          <Card className="p-3 md:p-4">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 md:w-10 md:h-10 rounded-xl bg-amber-50 dark:bg-amber-900/20 flex items-center justify-center flex-shrink-0">
                <Package size={16} className="text-amber-500" />
              </div>
              <div className="min-w-0">
                <p className="text-[11px] text-gray-400 font-medium">Pumps Count</p>
                <p className="text-xs md:text-sm font-semibold text-gray-800 dark:text-gray-200">
                  {amc.pumps_count ?? "—"}
                </p>
              </div>
            </div>
          </Card>
        </div>

        {/* Contract Details */}
        <Card className="overflow-hidden">
          <div className="px-5 py-3 bg-gray-50 dark:bg-gray-800/80 border-b border-gray-100 dark:border-gray-700">
            <p className="text-xs font-bold text-gray-500 dark:text-gray-400 uppercase tracking-widest">
              Contract Details
            </p>
          </div>
          <div className="p-5 space-y-3">
            {[
              {
                label: "PO Number",
                value: amc.po_number ? (
                  <span className="inline-flex items-center gap-1 text-xs bg-purple-50 dark:bg-purple-900/20 text-purple-600 dark:text-purple-400 px-2.5 py-1 rounded-full font-medium">
                    <Package size={11} /> {amc.po_number}
                  </span>
                ) : (
                  "—"
                ),
              },
              { label: "Start Date", value: formatDate(amc.start_date) },
              { label: "End Date", value: formatDate(amc.end_date) },
              { label: "Last Service Date", value: formatDate(amc.last_service_date) },
              { label: "Next Service Date", value: formatDate(amc.next_service_date) },
              {
                label: "Renewal Alert",
                value: amc.renewal_reminder_days
                  ? `${amc.renewal_reminder_days} days before expiry`
                  : "—",
              },
              {
                label: "Per Pump Price",
                value:
                  amc.per_pump_price != null
                    ? `₹${Number(amc.per_pump_price).toLocaleString()}`
                    : "—",
              },
              {
                label: "Total Price",
                value:
                  amc.total_price != null
                    ? `₹${Number(amc.total_price).toLocaleString()}`
                    : "—",
              },
              {
                label: "GST Percent",
                value: amc.gst_percent != null ? `${amc.gst_percent}%` : "—",
              },
            ].map((item) => (
              <div
                key={item.label}
                className="flex items-center justify-between py-1.5 border-b border-gray-50 dark:border-gray-800 last:border-0"
              >
                <span className="text-sm text-gray-500 dark:text-gray-400">{item.label}</span>
                <span className="text-sm font-semibold text-gray-800 dark:text-white">
                  {item.value}
                </span>
              </div>
            ))}
          </div>
        </Card>

        {/* Services */}
        {amc.services?.length > 0 && (
          <Card className="overflow-hidden">
            <div className="px-5 py-3 bg-gray-50 dark:bg-gray-800/80 border-b border-gray-100 dark:border-gray-700">
              <p className="text-xs font-bold text-gray-500 dark:text-gray-400 uppercase tracking-widest">
                Services Covered
              </p>
            </div>
            <div className="p-5">
              <div className="flex flex-wrap gap-2">
                {amc.services.map((s) => (
                  <span
                    key={s}
                    className="bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 text-xs px-3 py-1.5 rounded-full font-medium"
                  >
                    {s}
                  </span>
                ))}
              </div>
            </div>
          </Card>
        )}

        {/* Email reminders info */}
        <div className="bg-blue-50 dark:bg-blue-900/10 rounded-2xl border border-blue-100 dark:border-blue-900/30 p-4 space-y-2">
          <p className="text-xs font-bold text-blue-600 dark:text-blue-400 uppercase tracking-wide">
            Auto Email Reminders
          </p>
          <p className="text-sm text-gray-600 dark:text-gray-400 flex items-center gap-2">
            <Mail size={14} className="text-blue-500 flex-shrink-0" />
            Creation confirmation sent to client
          </p>
          <p className="text-sm text-gray-600 dark:text-gray-400 flex items-center gap-2">
            <AlertTriangle size={14} className="text-orange-500 flex-shrink-0" />
            Renewal reminder {amc.renewal_reminder_days || 30} days before expiry
          </p>
          {amc.next_service_date && (
            <p className="text-sm text-gray-600 dark:text-gray-400 flex items-center gap-2">
              <Bell size={14} className="text-amber-500 flex-shrink-0" />
              Service reminder before {formatDate(amc.next_service_date)}
            </p>
          )}
        </div>

        {/* Edit Modal */}
        <Modal
          isOpen={editOpen}
          onClose={() => setEditOpen(false)}
          title="Edit AMC Contract"
          size="lg"
        >
          <form onSubmit={handleEdit} className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <Input
                label="Contract Title"
                value={editForm.title}
                onChange={ef("title")}
                required
                className="col-span-2"
              />
              <Input
                label="PO Number"
                value={editForm.po_number}
                onChange={ef("po_number")}
                placeholder="PO-2025-001"
                className="col-span-2"
              />
              <DatePicker
                label="End Date"
                value={editForm.end_date}
                onChange={ef("end_date")}
              />
              <DatePicker
                label="Last Service Date"
                value={editForm.last_service_date}
                onChange={ef("last_service_date")}
              />
              <DatePicker
                label="Next Service Date"
                value={editForm.next_service_date}
                onChange={ef("next_service_date")}
              />
              <Select
                label="Renewal Reminder"
                value={editForm.renewal_reminder_days}
                onChange={ef("renewal_reminder_days")}
                options={[
                  { value: 15, label: "15 days" },
                  { value: 30, label: "30 days" },
                  { value: 60, label: "60 days" },
                  { value: 90, label: "90 days" },
                ]}
              />
              <div className="col-span-2">
                <Input
                  label="Services Covered (comma-separated)"
                  value={editForm.services_raw}
                  onChange={ef("services_raw")}
                  placeholder="HVAC Servicing, Filter Replacement, Emergency Support"
                />
              </div>
              <Input
                label="Visit Count"
                type="number"
                value={editForm.visit_count}
                onChange={ef("visit_count")}
              />
              <Input
                label="Pumps Count"
                type="number"
                value={editForm.pumps_count}
                onChange={ef("pumps_count")}
              />
              <Input
                label="Per Pump Price (₹)"
                type="number"
                value={editForm.per_pump_price}
                onChange={ef("per_pump_price")}
              />
              <Input
                label="Total Price (₹)"
                type="number"
                value={editForm.total_price}
                readOnly
              />
              <Input
                label="GST Percent"
                type="number"
                value={editForm.gst_percent}
                onChange={ef("gst_percent")}
              />
              <Input
                label="Contract Value (₹)"
                type="number"
                value={editForm.value}
                readOnly
              />
            </div>
            <div className="flex gap-3 pt-2">
              <Button type="submit" className="flex-1" disabled={editSaving}>
                {editSaving ? "Saving…" : "Update AMC"}
              </Button>
              <Button variant="secondary" onClick={() => setEditOpen(false)}>
                Cancel
              </Button>
            </div>
          </form>
        </Modal>

        {/* Delete confirmation */}
        <Modal
          isOpen={deleteOpen}
          onClose={() => setDeleteOpen(false)}
          title="Confirm Delete"
          size="sm"
        >
          <p className="text-gray-600 dark:text-gray-300 text-sm mb-5">
            Delete this AMC contract permanently? This action cannot be undone.
          </p>
          <div className="flex gap-3">
            <Button variant="danger" onClick={handleDelete} className="flex-1">
              Delete
            </Button>
            <Button variant="secondary" onClick={() => setDeleteOpen(false)}>
              Cancel
            </Button>
          </div>
        </Modal>

        {toast && <Toast {...toast} onClose={() => {}} />}
      </div>
    </PageTransition>
  );
}
