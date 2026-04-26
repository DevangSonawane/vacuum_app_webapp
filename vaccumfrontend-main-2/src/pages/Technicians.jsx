import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import { Plus, Pencil, Trash2, Star, UserCog, Phone, Mail, Search, Loader2, Eye, EyeOff } from "lucide-react";
import axios from "axios";
import { useApp } from "../context/AppContext";
import { PageTransition, Card, Badge, Avatar, Button, Modal, Input, Select, SectionHeader, EmptyState, useToast, Toast } from "../components/ui";

const API_BASE_URL = 'https://vaccumapi.onrender.com/api';

const EMPTY_FORM = {
  name:           "",
  email:          "",
  phone:          "",
  specialization: "",
  status:         "Active",
  join_date:      "",
  password:       "",
};

const SPECIALIZATIONS = ["ITR"];
const STATUSES        = ["Active", "On Leave", "Inactive"];

export default function Technicians() {
  const { currentUser } = useApp();
  const { toast, showToast } = useToast();

  const [technicians, setTechnicians] = useState([]);
  const [loading, setLoading]         = useState(true);
  const [search, setSearch]           = useState("");
  const [modalOpen, setModalOpen]     = useState(false);
  const [editId, setEditId]           = useState(null);
  const [form, setForm]               = useState(EMPTY_FORM);
  const [formLoading, setFormLoading] = useState(false);  // loading indicator inside modal while fetching by ID
  const [deleteId, setDeleteId]       = useState(null);
  const [submitting, setSubmitting]   = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  useEffect(() => { fetchTechnicians(); }, []);

  // ── Fetch list ────────────────────────────────────────────
  const fetchTechnicians = async (searchTerm = "") => {
    setLoading(true);
    try {
      const token  = localStorage.getItem('token');
      const params = { limit: 50 };
      if (searchTerm) params.search = searchTerm;

      const res = await axios.get(`${API_BASE_URL}/technicians`, {
        headers: { Authorization: `Bearer ${token}` },
        params,
      });
      if (res.data.success) {
        setTechnicians(res.data.data || []);
      }
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to fetch technicians", "error");
    } finally {
      setLoading(false);
    }
  };

  // Debounced search
  useEffect(() => {
    const t = setTimeout(() => fetchTechnicians(search), 400);
    return () => clearTimeout(t);
  }, [search]);

  // ── Open Add modal ────────────────────────────────────────
  const openAdd = () => {
    setForm(EMPTY_FORM);
    setEditId(null);
    setShowPassword(false);
    setModalOpen(true);
  };

  // ── Open Edit modal — fetch full record by ID first ───────
  // Per requirement: use GET /technicians/:id before populating form
  const openEdit = async (tech) => {
    setEditId(tech.id);
    setShowPassword(false);
    // Pre-populate with list data immediately so modal opens fast
    setForm({
      name:           tech.name           || "",
      email:          tech.email          || "",
      phone:          tech.phone          || "",
      specialization: tech.specialization || "",
      status:         tech.status         || "Active",
      join_date:      tech.join_date      || "",
      password:       "",
    });
    setModalOpen(true);
    setFormLoading(true);

    try {
      const token = localStorage.getItem('token');
      const res   = await axios.get(`${API_BASE_URL}/technicians/${tech.id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.data.success) {
        const d = res.data.data;
        // Overwrite with fresh server data
        setForm({
          name:           d.name           || "",
          email:          d.email          || "",
          phone:          d.phone          || "",
          specialization: d.specialization || "",
          status:         d.status         || "Active",
          join_date:      d.join_date      || "",
          password:       "",
        });
      }
    } catch (err) {
      // Non-fatal — form is already pre-populated from list row
      showToast("Could not load latest details, using cached data.", "error");
    } finally {
      setFormLoading(false);
    }
  };

  const f = (field) => (e) => setForm(p => ({ ...p, [field]: e.target.value }));

  // ── Create / Update ───────────────────────────────────────
  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    const token = localStorage.getItem('token');

    try {
      if (editId) {
        // PUT /api/technicians/:id — exclude password
        const { password, ...payload } = form;
        await axios.put(`${API_BASE_URL}/technicians/${editId}`, payload, {
          headers: { Authorization: `Bearer ${token}` },
        });
        showToast("Technician updated!");
      } else {
        // POST /api/technicians
        const payload = {
          name:           form.name.trim(),
          phone:          form.phone.trim(),
          specialization: form.specialization,
          status:         form.status,
        };
        if (form.email)     payload.email     = form.email.trim().toLowerCase();
        if (form.join_date) payload.join_date  = form.join_date;
        if (form.password)  payload.password   = form.password;

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

  // ── Delete ────────────────────────────────────────────────
  const confirmDelete = async () => {
    const token = localStorage.getItem('token');
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

  const canEdit    = currentUser?.role !== "technician";
  const activeCount = technicians.filter(t => t.status === "Active").length;

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
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {technicians.map((tech, i) => (
              <motion.div key={tech.id} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}>
                <Card hover className="p-5">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex items-center gap-3">
                      <Avatar initials={tech.avatar || tech.name?.slice(0, 2).toUpperCase() || "??"} size="lg" />
                      <div>
                        <p className="font-bold text-gray-900 dark:text-white text-sm">{tech.name}</p>
                        <p className="text-blue-600 dark:text-blue-400 text-xs font-medium">{tech.specialization}</p>
                      </div>
                    </div>
                    <Badge label={tech.status} />
                  </div>

                  <div className="space-y-1.5 text-xs text-gray-500 dark:text-gray-400 mb-4">
                    {tech.email && <div className="flex items-center gap-2"><Mail size={12} />{tech.email}</div>}
                    <div className="flex items-center gap-2"><Phone size={12} />{tech.phone}</div>
                  </div>

                  <div className="grid grid-cols-3 gap-2 text-center mb-4">
                    {[
                      { label: "Jobs",   value: tech.jobs_completed ?? 0 },
                      { label: "Rating", value: <span className="flex items-center justify-center gap-0.5"><Star size={10} className="text-amber-400 fill-amber-400" />{Number(tech.rating || 0).toFixed(1)}</span> },
                      { label: "Since",  value: tech.join_date ? tech.join_date.slice(0, 4) : "—" },
                    ].map(s => (
                      <div key={s.label} className="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-2">
                        <p className="text-gray-800 dark:text-gray-200 font-bold text-sm">{s.value}</p>
                        <p className="text-gray-400 text-xs">{s.label}</p>
                      </div>
                    ))}
                  </div>

                  {canEdit && (
                    <div className="flex gap-2">
                      <Button variant="secondary" size="sm" onClick={() => openEdit(tech)} className="flex-1">
                        <Pencil size={13} /> Edit
                      </Button>
                      <Button variant="danger" size="sm" onClick={() => setDeleteId(tech.id)}>
                        <Trash2 size={13} />
                      </Button>
                    </div>
                  )}
                </Card>
              </motion.div>
            ))}
          </div>
        )}

        {/* Add / Edit Modal */}
        <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editId ? "Edit Technician" : "Add Technician"}>
          {/* Loading overlay while fetching by ID */}
          {formLoading ? (
            <div className="flex flex-col items-center justify-center py-12 gap-3">
              <Loader2 size={28} className="animate-spin text-blue-500" />
              <p className="text-sm text-gray-500">Loading latest details…</p>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="grid grid-cols-2 gap-3">
                <Input label="Full Name"  value={form.name}  onChange={f("name")}  placeholder="Ravi Kumar" required className="col-span-2" />
                <Input label="Email"      type="email" value={form.email}  onChange={f("email")}  placeholder="ravi@ism.com" />
                <Input label="Phone"      value={form.phone} onChange={f("phone")} placeholder="9876543210" required />
                <Select
                  label="Specialization"
                  value={form.specialization}
                  onChange={f("specialization")}
                  options={["", ...SPECIALIZATIONS].map(s => ({ value: s, label: s || "Select..." }))}
                  required
                />
                <Select label="Status" value={form.status} onChange={f("status")} options={STATUSES} />
                <Input label="Join Date" type="date" value={form.join_date} onChange={f("join_date")} className="col-span-2" />
              </div>

              {/* Password — only on create */}
              {!editId && (
                <div className="space-y-1.5">
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Login Password (optional)
                  </label>
                  <div className="relative">
                    <input
                      type={showPassword ? "text" : "password"}
                      value={form.password}
                      onChange={f("password")}
                      placeholder="Leave blank if no login needed"
                      className="w-full px-3 py-2 rounded-xl border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 text-gray-900 dark:text-gray-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition pr-10"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-white transition-colors"
                    >
                      {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                    </button>
                  </div>
                  <p className="text-xs text-gray-400">
                    If provided, this technician can log in via the mobile app using phone/email + this password.
                  </p>
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
          <p className="text-gray-600 dark:text-gray-300 text-sm mb-5">
            Are you sure you want to remove this technician? This cannot be undone.
          </p>
          <div className="flex gap-3">
            <Button variant="danger" onClick={confirmDelete} className="flex-1">Delete</Button>
            <Button variant="secondary" onClick={() => setDeleteId(null)}>Cancel</Button>
          </div>
        </Modal>

        {toast && <Toast {...toast} onClose={() => {}} />}
      </div>
    </PageTransition>
  );
}