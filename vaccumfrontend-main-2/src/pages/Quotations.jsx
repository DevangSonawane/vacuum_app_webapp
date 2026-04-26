import { useState } from "react";
import { motion } from "framer-motion";
import { Plus, DollarSign, Trash2, Check, X, FileText } from "lucide-react";
import { useApp } from "../context/AppContext";
import { PageTransition, Card, Badge, Button, Modal, Input, Select, SectionHeader, EmptyState, useToast, Toast } from "../components/ui";

const EMPTY_FORM = { clientId: "", title: "", validTill: "", items: [{ description: "", qty: 1, rate: "", total: 0 }] };

export default function Quotations() {
  const { quotations, clients, addQuotation, updateQuotation, currentUser } = useApp();
  const { toast, showToast } = useToast();
  const [modalOpen, setModalOpen] = useState(false);
  const [detailQ, setDetailQ] = useState(null);
  const [form, setForm] = useState(EMPTY_FORM);

  const canEdit = currentUser?.role !== "Technician";

  const updateItem = (i, field, val) => {
    setForm(p => {
      const items = [...p.items];
      items[i] = { ...items[i], [field]: val };
      if (field === "qty" || field === "rate") items[i].total = Number(items[i].qty) * Number(items[i].rate);
      return { ...p, items };
    });
  };
  const addItem = () => setForm(p => ({ ...p, items: [...p.items, { description: "", qty: 1, rate: "", total: 0 }] }));
  const removeItem = i => setForm(p => ({ ...p, items: p.items.filter((_, idx) => idx !== i) }));
  const totalAmount = form.items.reduce((s, it) => s + Number(it.total), 0);

  const handleSubmit = e => {
    e.preventDefault();
    addQuotation({ ...form, amount: totalAmount });
    setModalOpen(false);
    showToast("Quotation created!");
    setForm(EMPTY_FORM);
  };

  const changeStatus = (id, status) => {
    updateQuotation(id, { status });
    showToast(`Quotation ${status.toLowerCase()}`, status === "Approved" ? "success" : "error");
    if (detailQ?.id === id) setDetailQ(p => ({ ...p, status }));
  };

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-7xl mx-auto">
        <SectionHeader
          title="Quotations"
          subtitle={`${quotations.filter(q => q.status === "Pending").length} pending approval`}
          action={canEdit && <Button onClick={() => setModalOpen(true)}><Plus size={16} /> New Quotation</Button>}
        />

        {quotations.length === 0 ? (
          <EmptyState icon={DollarSign} title="No quotations yet" description="Create a quotation for a client." />
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
            {quotations.map((q, i) => {
              const client = clients.find(c => c.id === q.clientId);
              return (
                <motion.div key={q.id} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.06 }}>
                  <Card hover className="p-5" onClick={() => setDetailQ(q)}>
                    <div className="flex items-start justify-between mb-2">
                      <div>
                        <p className="font-mono text-xs text-blue-500">{q.id}</p>
                        <p className="font-bold text-gray-900 dark:text-white text-sm mt-0.5">{q.title}</p>
                        <p className="text-xs text-gray-500 dark:text-gray-400">{client?.name}</p>
                      </div>
                      <Badge label={q.status} />
                    </div>
                    <div className="mt-4 pt-3 border-t border-gray-100 dark:border-gray-700 flex items-center justify-between">
                      <div>
                        <p className="text-2xl font-bold text-blue-600 dark:text-blue-400 font-display">₹{q.amount.toLocaleString()}</p>
                        <p className="text-xs text-gray-400 mt-0.5">Valid till {q.validTill}</p>
                      </div>
                      {canEdit && q.status === "Pending" && (
                        <div className="flex gap-2" onClick={e => e.stopPropagation()}>
                          <button onClick={() => changeStatus(q.id, "Approved")}
                            className="p-2 bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 rounded-lg hover:bg-emerald-100 transition"><Check size={16} /></button>
                          <button onClick={() => changeStatus(q.id, "Rejected")}
                            className="p-2 bg-red-50 dark:bg-red-900/20 text-red-500 rounded-lg hover:bg-red-100 transition"><X size={16} /></button>
                        </div>
                      )}
                    </div>
                  </Card>
                </motion.div>
              );
            })}
          </div>
        )}

        {/* New Quotation Modal */}
        <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title="Create Quotation" size="xl">
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <Select label="Client" value={form.clientId} onChange={e => setForm(p => ({ ...p, clientId: e.target.value }))} required
                options={[{ value: "", label: "Select client..." }, ...clients.map(c => ({ value: c.id, label: c.name }))]} />
              <Input label="Quotation Title" value={form.title} onChange={e => setForm(p => ({ ...p, title: e.target.value }))} required />
              <Input label="Valid Till" type="date" value={form.validTill} onChange={e => setForm(p => ({ ...p, validTill: e.target.value }))} className="col-span-2" />
            </div>

            {/* Line Items */}
            <div>
              <p className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">Line Items</p>
              <div className="space-y-2">
                {form.items.map((item, i) => (
                  <div key={i} className="grid grid-cols-12 gap-2 items-end">
                    <div className="col-span-5">
                      {i === 0 && <p className="text-xs text-gray-400 mb-1">Description</p>}
                      <input value={item.description} onChange={e => updateItem(i, "description", e.target.value)} placeholder="Service description"
                        className="w-full px-3 py-2 rounded-lg border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 text-sm text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500" />
                    </div>
                    <div className="col-span-2">
                      {i === 0 && <p className="text-xs text-gray-400 mb-1">Qty</p>}
                      <input type="number" value={item.qty} onChange={e => updateItem(i, "qty", e.target.value)} min="1"
                        className="w-full px-3 py-2 rounded-lg border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 text-sm text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500" />
                    </div>
                    <div className="col-span-2">
                      {i === 0 && <p className="text-xs text-gray-400 mb-1">Rate (₹)</p>}
                      <input type="number" value={item.rate} onChange={e => updateItem(i, "rate", e.target.value)}
                        className="w-full px-3 py-2 rounded-lg border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 text-sm text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500" />
                    </div>
                    <div className="col-span-2">
                      {i === 0 && <p className="text-xs text-gray-400 mb-1">Total</p>}
                      <div className="px-3 py-2 rounded-lg bg-blue-50 dark:bg-blue-900/20 text-sm font-semibold text-blue-700 dark:text-blue-300">₹{Number(item.total).toLocaleString()}</div>
                    </div>
                    <div className="col-span-1 flex justify-center">
                      {form.items.length > 1 && (
                        <button type="button" onClick={() => removeItem(i)} className="text-red-400 hover:text-red-600 mt-1"><X size={16} /></button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
              <button type="button" onClick={addItem} className="mt-2 text-sm text-blue-600 hover:text-blue-700 font-semibold flex items-center gap-1"><Plus size={14} /> Add Item</button>
            </div>

            <div className="flex items-center justify-between pt-3 border-t border-gray-100 dark:border-gray-700">
              <div>
                <p className="text-xs text-gray-400">Total Amount</p>
                <p className="text-2xl font-bold text-blue-600 font-display">₹{totalAmount.toLocaleString()}</p>
              </div>
              <div className="flex gap-3">
                <Button type="submit">Create Quotation</Button>
                <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
              </div>
            </div>
          </form>
        </Modal>

        {/* Detail Modal */}
        {detailQ && (
          <Modal isOpen={!!detailQ} onClose={() => setDetailQ(null)} title={detailQ.title} size="lg">
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div><p className="text-xs text-gray-400">ID</p><p className="font-mono font-semibold text-blue-600">{detailQ.id}</p></div>
                <div><p className="text-xs text-gray-400">Status</p><Badge label={detailQ.status} /></div>
                <div><p className="text-xs text-gray-400">Client</p><p className="font-medium text-gray-800 dark:text-gray-200">{clients.find(c => c.id === detailQ.clientId)?.name}</p></div>
                <div><p className="text-xs text-gray-400">Valid Till</p><p className="font-medium text-gray-800 dark:text-gray-200">{detailQ.validTill}</p></div>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead><tr className="border-b border-gray-100 dark:border-gray-700">
                    <th className="text-left py-2 text-xs text-gray-400">Description</th>
                    <th className="text-right py-2 text-xs text-gray-400">Qty</th>
                    <th className="text-right py-2 text-xs text-gray-400">Rate</th>
                    <th className="text-right py-2 text-xs text-gray-400">Total</th>
                  </tr></thead>
                  <tbody>
                    {detailQ.items?.map((item, i) => (
                      <tr key={i} className="border-b border-gray-50 dark:border-gray-700/50">
                        <td className="py-2 text-gray-700 dark:text-gray-300">{item.description}</td>
                        <td className="py-2 text-right text-gray-600 dark:text-gray-400">{item.qty}</td>
                        <td className="py-2 text-right text-gray-600 dark:text-gray-400">₹{Number(item.rate).toLocaleString()}</td>
                        <td className="py-2 text-right font-semibold text-gray-800 dark:text-gray-200">₹{Number(item.total).toLocaleString()}</td>
                      </tr>
                    ))}
                  </tbody>
                  <tfoot><tr>
                    <td colSpan={3} className="pt-3 text-right font-bold text-gray-700 dark:text-gray-300">Grand Total</td>
                    <td className="pt-3 text-right text-xl font-bold text-blue-600 font-display">₹{detailQ.amount.toLocaleString()}</td>
                  </tr></tfoot>
                </table>
              </div>
            </div>
          </Modal>
        )}

        {toast && <Toast {...toast} onClose={() => {}} />}
      </div>
    </PageTransition>
  );
}
