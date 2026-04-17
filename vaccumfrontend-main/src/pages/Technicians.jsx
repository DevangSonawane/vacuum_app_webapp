import { useState } from "react";
import { motion } from "framer-motion";
import { Plus, Pencil, Trash2, Star, UserCog, Phone, Mail, Search } from "lucide-react";
import { useApp } from "../context/AppContext";
import { PageTransition, Card, Badge, Avatar, Button, Modal, Input, Select, SectionHeader, EmptyState, useToast, Toast } from "../components/ui";

const EMPTY_FORM = { name: "", email: "", phone: "", specialization: "", status: "Active", joinDate: "", avatar: "" };
const SPECIALIZATIONS = ["HVAC", "Electrical", "Plumbing", "Carpentry", "Generator", "Civil", "IT"];
const STATUSES = ["Active", "On Leave", "Inactive"];

export default function Technicians() {
  const { technicians, addTechnician, updateTechnician, deleteTechnician, currentUser } = useApp();
  const { toast, showToast } = useToast();
  const [search, setSearch] = useState("");
  const [modalOpen, setModalOpen] = useState(false);
  const [editId, setEditId] = useState(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [deleteId, setDeleteId] = useState(null);

  const filtered = technicians.filter(t =>
    t.name.toLowerCase().includes(search.toLowerCase()) ||
    t.specialization.toLowerCase().includes(search.toLowerCase())
  );

  const openAdd = () => { setForm(EMPTY_FORM); setEditId(null); setModalOpen(true); };
  const openEdit = (t) => { setForm({ ...t }); setEditId(t.id); setModalOpen(true); };
  const f = (field) => (e) => setForm(p => ({ ...p, [field]: e.target.value }));

  const handleSubmit = (e) => {
    e.preventDefault();
    const initials = form.name.split(" ").map(w => w[0]).join("").toUpperCase().slice(0, 2);
    if (editId) { updateTechnician(editId, { ...form, avatar: initials }); showToast("Technician updated!"); }
    else { addTechnician({ ...form, avatar: initials }); showToast("Technician added!"); }
    setModalOpen(false);
  };

  const confirmDelete = () => {
    deleteTechnician(deleteId);
    setDeleteId(null);
    showToast("Technician removed", "error");
  };

  const canEdit = currentUser?.role !== "Technician";

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-7xl mx-auto">
        <SectionHeader
          title="Technicians"
          subtitle={`${technicians.filter(t => t.status === "Active").length} active of ${technicians.length} total`}
          action={canEdit && <Button onClick={openAdd}><Plus size={16} /> Add Technician</Button>}
        />

        {/* Search */}
        <div className="relative mb-5 max-w-sm">
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search technicians..."
            className="w-full pl-9 pr-3 py-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-800 dark:text-gray-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 transition" />
        </div>

        {filtered.length === 0 ? (
          <EmptyState icon={UserCog} title="No technicians found" description="Try a different search or add a new technician." />
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {filtered.map((tech, i) => (
              <motion.div key={tech.id} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}>
                <Card hover className="p-5">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex items-center gap-3">
                      <Avatar initials={tech.avatar} size="lg" />
                      <div>
                        <p className="font-bold text-gray-900 dark:text-white text-sm">{tech.name}</p>
                        <p className="text-blue-600 dark:text-blue-400 text-xs font-medium">{tech.specialization}</p>
                      </div>
                    </div>
                    <Badge label={tech.status} />
                  </div>

                  <div className="space-y-1.5 text-xs text-gray-500 dark:text-gray-400 mb-4">
                    <div className="flex items-center gap-2"><Mail size={12} />{tech.email}</div>
                    <div className="flex items-center gap-2"><Phone size={12} />{tech.phone}</div>
                  </div>

                  <div className="grid grid-cols-3 gap-2 text-center mb-4">
                    {[
                      { label: "Jobs", value: tech.jobsCompleted },
                      { label: "Rating", value: <span className="flex items-center justify-center gap-0.5"><Star size={10} className="text-amber-400 fill-amber-400" />{tech.rating}</span> },
                      { label: "Since", value: tech.joinDate?.slice(0, 4) },
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

        {/* Add/Edit Modal */}
        <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editId ? "Edit Technician" : "Add Technician"}>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <Input label="Full Name" value={form.name} onChange={f("name")} placeholder="Ravi Kumar" required className="col-span-2" />
              <Input label="Email" type="email" value={form.email} onChange={f("email")} placeholder="ravi@ism.com" required />
              <Input label="Phone" value={form.phone} onChange={f("phone")} placeholder="9876543210" required />
              <Select label="Specialization" value={form.specialization} onChange={f("specialization")} options={["", ...SPECIALIZATIONS].map(s => ({ value: s, label: s || "Select..." }))} required />
              <Select label="Status" value={form.status} onChange={f("status")} options={STATUSES} />
              <Input label="Join Date" type="date" value={form.joinDate} onChange={f("joinDate")} className="col-span-2" />
            </div>
            <div className="flex gap-3 pt-2">
              <Button type="submit" className="flex-1">{editId ? "Update" : "Add"} Technician</Button>
              <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
            </div>
          </form>
        </Modal>

        {/* Delete confirm */}
        <Modal isOpen={!!deleteId} onClose={() => setDeleteId(null)} title="Confirm Delete" size="sm">
          <p className="text-gray-600 dark:text-gray-300 text-sm mb-5">Are you sure you want to remove this technician? This cannot be undone.</p>
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
