import { useState } from "react";
import { motion } from "framer-motion";
import { Plus, ShieldCheck, Calendar, RefreshCw, AlertTriangle } from "lucide-react";
import { useApp } from "../context/AppContext";
import { PageTransition, Card, Badge, Button, Modal, Input, Select, SectionHeader, EmptyState, useToast, Toast } from "../components/ui";

const EMPTY = { clientId: "", title: "", startDate: "", endDate: "", value: "", renewalReminder: 30, services: "", nextService: "" };

const statusColor = { Active: "from-blue-500 to-blue-700", "Expiring Soon": "from-orange-500 to-orange-700", Expired: "from-gray-400 to-gray-600" };

export default function AMC() {
  const { amcContracts, clients, addAmc, updateAmc, currentUser } = useApp();
  const { toast, showToast } = useToast();
  const [modalOpen, setModalOpen] = useState(false);
  const [form, setForm] = useState(EMPTY);
  const [detailAmc, setDetailAmc] = useState(null);

  const canEdit = currentUser?.role !== "Technician";
  const f = field => e => setForm(p => ({ ...p, [field]: e.target.value }));

  const handleSubmit = e => {
    e.preventDefault();
    addAmc({ ...form, value: Number(form.value), services: form.services.split(",").map(s => s.trim()) });
    setModalOpen(false);
    showToast("AMC contract created!");
    setForm(EMPTY);
  };

  const totalValue = amcContracts.reduce((s, a) => s + Number(a.value), 0);

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-7xl mx-auto">
        <SectionHeader
          title="AMC Contracts"
          subtitle={`Total portfolio: ₹${(totalValue / 100000).toFixed(1)}L`}
          action={canEdit && <Button onClick={() => setModalOpen(true)}><Plus size={16} /> New AMC</Button>}
        />

        {/* Summary Cards */}
        <div className="grid grid-cols-3 gap-4 mb-6">
          {[
            { label: "Active", count: amcContracts.filter(a => a.status === "Active").length, color: "text-blue-600", bg: "bg-blue-50 dark:bg-blue-900/20" },
            { label: "Expiring Soon", count: amcContracts.filter(a => a.status === "Expiring Soon").length, color: "text-orange-600", bg: "bg-orange-50 dark:bg-orange-900/20" },
            { label: "Expired", count: amcContracts.filter(a => a.status === "Expired").length, color: "text-gray-500", bg: "bg-gray-50 dark:bg-gray-700/50" },
          ].map(s => (
            <div key={s.label} className={`${s.bg} rounded-2xl p-4 text-center`}>
              <p className={`text-2xl font-bold ${s.color} font-display`}>{s.count}</p>
              <p className="text-xs text-gray-500 dark:text-gray-400 font-medium mt-0.5">{s.label}</p>
            </div>
          ))}
        </div>

        {amcContracts.length === 0 ? (
          <EmptyState icon={ShieldCheck} title="No AMC contracts" description="Create annual maintenance contracts for clients." />
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
            {amcContracts.map((amc, i) => {
              const client = clients.find(c => c.id === amc.clientId);
              const daysLeft = Math.ceil((new Date(amc.endDate) - new Date()) / (1000 * 60 * 60 * 24));
              return (
                <motion.div key={amc.id} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.06 }}>
                  <Card hover className="overflow-hidden" onClick={() => setDetailAmc(amc)}>
                    <div className={`h-1.5 bg-gradient-to-r ${statusColor[amc.status] || "from-gray-400 to-gray-600"}`} />
                    <div className="p-5">
                      <div className="flex items-start justify-between mb-3">
                        <div>
                          <p className="font-mono text-xs text-blue-500">{amc.id}</p>
                          <p className="font-bold text-gray-900 dark:text-white text-sm mt-0.5">{amc.title}</p>
                          <p className="text-xs text-gray-500 dark:text-gray-400">{client?.name}</p>
                        </div>
                        <Badge label={amc.status} />
                      </div>

                      <div className="grid grid-cols-2 gap-3 mb-4">
                        <div className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-3">
                          <p className="text-xs text-gray-400">Contract Value</p>
                          <p className="font-bold text-blue-600 dark:text-blue-400 text-base font-display">₹{Number(amc.value).toLocaleString()}</p>
                        </div>
                        <div className={`rounded-xl p-3 ${daysLeft < 60 ? "bg-orange-50 dark:bg-orange-900/20" : "bg-gray-50 dark:bg-gray-700/50"}`}>
                          <p className="text-xs text-gray-400">Days Left</p>
                          <p className={`font-bold text-base font-display ${daysLeft < 60 ? "text-orange-600" : "text-gray-800 dark:text-gray-200"}`}>
                            {daysLeft > 0 ? daysLeft : "Expired"}
                          </p>
                        </div>
                      </div>

                      <div className="space-y-2 text-xs text-gray-500 dark:text-gray-400">
                        <div className="flex items-center gap-2"><Calendar size={12} />
                          {amc.startDate} → {amc.endDate}
                        </div>
                        <div className="flex items-center gap-2"><RefreshCw size={12} />
                          Next service: {amc.nextService}
                        </div>
                        {amc.status === "Expiring Soon" && (
                          <div className="flex items-center gap-2 text-orange-500 font-semibold">
                            <AlertTriangle size={12} /> Renewal reminder in {amc.renewalReminder} days
                          </div>
                        )}
                      </div>

                      <div className="mt-3 pt-3 border-t border-gray-100 dark:border-gray-700">
                        <p className="text-xs text-gray-400 mb-1.5">Covered Services</p>
                        <div className="flex flex-wrap gap-1">
                          {amc.services?.map(s => (
                            <span key={s} className="bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 text-xs px-2 py-0.5 rounded-full">{s}</span>
                          ))}
                        </div>
                      </div>
                    </div>
                  </Card>
                </motion.div>
              );
            })}
          </div>
        )}

        <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title="New AMC Contract" size="lg">
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <Select label="Client" value={form.clientId} onChange={f("clientId")} required
                options={[{ value: "", label: "Select client..." }, ...clients.map(c => ({ value: c.id, label: c.name }))]} />
              <Input label="Contract Title" value={form.title} onChange={f("title")} required />
              <Input label="Start Date" type="date" value={form.startDate} onChange={f("startDate")} required />
              <Input label="End Date" type="date" value={form.endDate} onChange={f("endDate")} required />
              <Input label="Contract Value (₹)" type="number" value={form.value} onChange={f("value")} required />
              <Input label="Next Service Date" type="date" value={form.nextService} onChange={f("nextService")} />
              <Select label="Renewal Reminder (days)" value={form.renewalReminder} onChange={f("renewalReminder")}
                options={[{ value: 15, label: "15 days" }, { value: 30, label: "30 days" }, { value: 60, label: "60 days" }]} className="col-span-2" />
              <div className="col-span-2">
                <Input label="Services Covered (comma-separated)" value={form.services} onChange={f("services")} placeholder="HVAC, Electrical, Plumbing" />
              </div>
            </div>
            <div className="flex gap-3 pt-2">
              <Button type="submit" className="flex-1">Create AMC</Button>
              <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
            </div>
          </form>
        </Modal>

        {detailAmc && (
          <Modal isOpen={!!detailAmc} onClose={() => setDetailAmc(null)} title={detailAmc.title} size="lg">
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4 text-sm">
                {[
                  { label: "AMC ID", value: <span className="font-mono text-blue-600">{detailAmc.id}</span> },
                  { label: "Status", value: <Badge label={detailAmc.status} /> },
                  { label: "Client", value: clients.find(c => c.id === detailAmc.clientId)?.name },
                  { label: "Contract Value", value: <span className="font-bold text-blue-600">₹{Number(detailAmc.value).toLocaleString()}</span> },
                  { label: "Start Date", value: detailAmc.startDate },
                  { label: "End Date", value: detailAmc.endDate },
                  { label: "Next Service", value: detailAmc.nextService },
                  { label: "Renewal Reminder", value: `${detailAmc.renewalReminder} days before` },
                ].map(item => (
                  <div key={item.label}><p className="text-xs text-gray-400 mb-0.5">{item.label}</p><p className="font-medium text-gray-800 dark:text-gray-200">{item.value}</p></div>
                ))}
              </div>
              <div><p className="text-xs text-gray-400 mb-2">Services Covered</p>
                <div className="flex flex-wrap gap-2">
                  {detailAmc.services?.map(s => <span key={s} className="bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 px-3 py-1 rounded-full text-sm font-medium">{s}</span>)}
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
