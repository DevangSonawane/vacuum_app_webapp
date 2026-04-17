import { useState } from "react";
import { motion } from "framer-motion";
import { Plus, Pencil, Trash2, Users, Phone, Mail, MapPin, Building2 } from "lucide-react";
import { useApp } from "../context/AppContext";
import { PageTransition, Card, Badge, Button, Modal, Input, Select, SectionHeader, EmptyState, useToast, Toast } from "../components/ui";

const EMPTY = { name: "", contact: "", email: "", phone: "", address: "", type: "Corporate", status: "Active", contractValue: "" };
const TYPES = ["Corporate", "Residential", "Commercial", "Healthcare", "Government"];

export default function Clients() {
  const { clients, addClient, updateClient, deleteClient, currentUser } = useApp();
  const { toast, showToast } = useToast();
  const [search, setSearch] = useState("");
  const [filterType, setFilterType] = useState("All");
  const [modalOpen, setModalOpen] = useState(false);
  const [editId, setEditId] = useState(null);
  const [form, setForm] = useState(EMPTY);
  const [deleteId, setDeleteId] = useState(null);

  const filtered = clients.filter(c =>
    (filterType === "All" || c.type === filterType) &&
    (c.name.toLowerCase().includes(search.toLowerCase()) || c.contact.toLowerCase().includes(search.toLowerCase()))
  );

  const f = field => e => setForm(p => ({ ...p, [field]: e.target.value }));
  const openAdd = () => { setForm(EMPTY); setEditId(null); setModalOpen(true); };
  const openEdit = c => { setForm({ ...c }); setEditId(c.id); setModalOpen(true); };

  const handleSubmit = e => {
    e.preventDefault();
    if (editId) { updateClient(editId, form); showToast("Client updated!"); }
    else { addClient(form); showToast("Client added!"); }
    setModalOpen(false);
  };

  const typeColors = {
    Corporate: "bg-blue-100 text-blue-700",
    Residential: "bg-emerald-100 text-emerald-700",
    Commercial: "bg-purple-100 text-purple-700",
    Healthcare: "bg-red-100 text-red-700",
    Government: "bg-amber-100 text-amber-700",
  };

  const canEdit = currentUser?.role !== "Technician";

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-7xl mx-auto">
        <SectionHeader
          title="Clients"
          subtitle={`${clients.filter(c => c.status === "Active").length} active clients`}
          action={canEdit && <Button onClick={openAdd}><Plus size={16} /> Add Client</Button>}
        />

        {/* Filters */}
        <div className="flex flex-wrap gap-2 mb-5">
          <div className="relative flex-1 min-w-48 max-w-xs">
            <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search clients..."
              className="w-full pl-3 pr-3 py-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-800 dark:text-gray-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 transition" />
          </div>
          <div className="flex gap-1 flex-wrap">
            {["All", ...TYPES].map(t => (
              <button key={t} onClick={() => setFilterType(t)}
                className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition ${filterType === t ? "bg-blue-600 text-white" : "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"}`}
              >{t}</button>
            ))}
          </div>
        </div>

        {filtered.length === 0 ? (
          <EmptyState icon={Users} title="No clients found" description="Adjust your filters or add a new client." />
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {filtered.map((c, i) => (
              <motion.div key={c.id} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}>
                <Card hover className="p-5">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex items-center gap-3">
                      <div className="w-11 h-11 rounded-xl bg-gradient-to-br from-blue-500 to-blue-700 flex items-center justify-center flex-shrink-0">
                        <Building2 size={20} className="text-white" />
                      </div>
                      <div>
                        <p className="font-bold text-gray-900 dark:text-white">{c.name}</p>
                        <p className="text-gray-500 dark:text-gray-400 text-xs">{c.contact}</p>
                      </div>
                    </div>
                    <div className="flex flex-col items-end gap-1">
                      <Badge label={c.status} />
                      <span className={`text-xs px-2 py-0.5 rounded-full font-semibold ${typeColors[c.type] || "bg-gray-100 text-gray-600"}`}>{c.type}</span>
                    </div>
                  </div>

                  <div className="space-y-1.5 text-xs text-gray-500 dark:text-gray-400 mb-4">
                    <div className="flex items-center gap-2"><Mail size={12} />{c.email}</div>
                    <div className="flex items-center gap-2"><Phone size={12} />{c.phone}</div>
                    <div className="flex items-center gap-2"><MapPin size={12} />{c.address}</div>
                  </div>

                  <div className="flex items-center justify-between pt-3 border-t border-gray-100 dark:border-gray-700">
                    <div>
                      <p className="text-xs text-gray-400">Contract Value</p>
                      <p className="font-bold text-gray-800 dark:text-white text-sm">₹{Number(c.contractValue).toLocaleString()}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-xs text-gray-400">Since</p>
                      <p className="text-sm font-medium text-gray-600 dark:text-gray-300">{c.joinDate}</p>
                    </div>
                    {canEdit && (
                      <div className="flex gap-2">
                        <Button variant="secondary" size="sm" onClick={() => openEdit(c)}><Pencil size={13} /></Button>
                        <Button variant="danger" size="sm" onClick={() => setDeleteId(c.id)}><Trash2 size={13} /></Button>
                      </div>
                    )}
                  </div>
                </Card>
              </motion.div>
            ))}
          </div>
        )}

        <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editId ? "Edit Client" : "Add Client"} size="lg">
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <Input label="Company Name" value={form.name} onChange={f("name")} required className="col-span-2" />
              <Input label="Contact Person" value={form.contact} onChange={f("contact")} required />
              <Input label="Email" type="email" value={form.email} onChange={f("email")} required />
              <Input label="Phone" value={form.phone} onChange={f("phone")} required />
              <Input label="Contract Value (₹)" type="number" value={form.contractValue} onChange={f("contractValue")} />
              <Select label="Type" value={form.type} onChange={f("type")} options={TYPES} />
              <Select label="Status" value={form.status} onChange={f("status")} options={["Active", "Inactive"]} />
              <Input label="Address" value={form.address} onChange={f("address")} className="col-span-2" />
            </div>
            <div className="flex gap-3 pt-2">
              <Button type="submit" className="flex-1">{editId ? "Update" : "Add"} Client</Button>
              <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
            </div>
          </form>
        </Modal>

        <Modal isOpen={!!deleteId} onClose={() => setDeleteId(null)} title="Confirm Delete" size="sm">
          <p className="text-gray-600 dark:text-gray-300 text-sm mb-5">Remove this client permanently?</p>
          <div className="flex gap-3">
            <Button variant="danger" onClick={() => { deleteClient(deleteId); setDeleteId(null); showToast("Client removed", "error"); }} className="flex-1">Delete</Button>
            <Button variant="secondary" onClick={() => setDeleteId(null)}>Cancel</Button>
          </div>
        </Modal>

        {toast && <Toast {...toast} onClose={() => {}} />}
      </div>
    </PageTransition>
  );
}
