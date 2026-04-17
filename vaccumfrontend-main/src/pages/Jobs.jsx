import { useState } from "react";
import { motion } from "framer-motion";
import { Plus, Briefcase, ArrowRight, Calendar, User } from "lucide-react";
import { useApp } from "../context/AppContext";
import { PageTransition, Card, Badge, Button, Modal, Input, Select, Textarea, SectionHeader, EmptyState, useToast, Toast } from "../components/ui";

const STATUSES = ["Raised", "Assigned", "In Progress", "Closed"];
const PRIORITIES = ["Low", "Medium", "High", "Critical"];
const CATEGORIES = ["Maintenance", "Repair", "Installation", "Inspection"];
const EMPTY = { title: "", clientId: "", technicianId: "", priority: "Medium", category: "Maintenance", description: "", scheduledDate: "", amount: "" };

const STATUS_FLOW = { Raised: "Assigned", Assigned: "In Progress", "In Progress": "Closed" };
const STATUS_COLOR = {
  Raised: "border-l-purple-500",
  Assigned: "border-l-blue-500",
  "In Progress": "border-l-amber-500",
  Closed: "border-l-emerald-500",
};

export default function Jobs() {
  const { jobs, clients, technicians, addJob, updateJob, currentUser } = useApp();
  const { toast, showToast } = useToast();
  const [filter, setFilter] = useState("All");
  const [modalOpen, setModalOpen] = useState(false);
  const [detailJob, setDetailJob] = useState(null);
  const [form, setForm] = useState(EMPTY);

  const filtered = jobs.filter(j => filter === "All" || j.status === filter);
  const f = field => e => setForm(p => ({ ...p, [field]: e.target.value }));

  const handleSubmit = e => {
    e.preventDefault();
    addJob(form);
    setModalOpen(false);
    showToast("Work order raised!");
    setForm(EMPTY);
  };

  const advanceStatus = (job) => {
    const next = STATUS_FLOW[job.status];
    if (!next) return;
    updateJob(job.id, { status: next, ...(next === "Closed" ? { closedDate: new Date().toISOString().split("T")[0] } : {}) });
    showToast(`Job moved to ${next}`);
  };

  const canRaise = currentUser?.role !== "Technician";

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-7xl mx-auto">
        <SectionHeader
          title="Work Orders"
          subtitle={`${jobs.filter(j => j.status !== "Closed").length} active orders`}
          action={canRaise && <Button onClick={() => setModalOpen(true)}><Plus size={16} /> Raise Job</Button>}
        />

        {/* Pipeline filter tabs */}
        <div className="flex gap-2 mb-5 overflow-x-auto pb-1">
          {["All", ...STATUSES].map(s => (
            <button key={s} onClick={() => setFilter(s)}
              className={`px-4 py-1.5 rounded-xl text-xs font-semibold whitespace-nowrap transition ${filter === s ? "bg-blue-600 text-white" : "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"}`}
            >
              {s} {s !== "All" && <span className="ml-1 bg-white/20 px-1 rounded">{jobs.filter(j => j.status === s).length}</span>}
            </button>
          ))}
        </div>

        {/* Kanban board for desktop, list for mobile */}
        {filter === "All" ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {STATUSES.map(status => (
              <div key={status}>
                <div className="flex items-center gap-2 mb-3">
                  <Badge label={status} />
                  <span className="text-xs text-gray-400 font-medium">{jobs.filter(j => j.status === status).length}</span>
                </div>
                <div className="space-y-3">
                  {jobs.filter(j => j.status === status).map(job => (
                    <JobCard key={job.id} job={job} clients={clients} technicians={technicians}
                      onDetail={() => setDetailJob(job)} onAdvance={() => advanceStatus(job)} currentUser={currentUser} />
                  ))}
                  {jobs.filter(j => j.status === status).length === 0 && (
                    <div className="text-center py-8 text-gray-300 dark:text-gray-600 text-sm border-2 border-dashed border-gray-200 dark:border-gray-700 rounded-xl">Empty</div>
                  )}
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="space-y-3">
            {filtered.length === 0 ? <EmptyState icon={Briefcase} title="No jobs found" description="No jobs in this status." /> :
              filtered.map(job => (
                <JobCard key={job.id} job={job} clients={clients} technicians={technicians}
                  onDetail={() => setDetailJob(job)} onAdvance={() => advanceStatus(job)} currentUser={currentUser} horizontal />
              ))
            }
          </div>
        )}

        {/* Raise Job Modal */}
        <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title="Raise New Work Order" size="lg">
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <Input label="Job Title" value={form.title} onChange={f("title")} required className="col-span-2" />
              <Select label="Client" value={form.clientId} onChange={f("clientId")} required
                options={[{ value: "", label: "Select client..." }, ...clients.map(c => ({ value: c.id, label: c.name }))]} />
              <Select label="Assign Technician" value={form.technicianId} onChange={f("technicianId")}
                options={[{ value: "", label: "Not assigned yet" }, ...technicians.filter(t => t.status === "Active").map(t => ({ value: t.id, label: t.name }))]} />
              <Select label="Priority" value={form.priority} onChange={f("priority")} options={PRIORITIES} />
              <Select label="Category" value={form.category} onChange={f("category")} options={CATEGORIES} />
              <Input label="Scheduled Date" type="date" value={form.scheduledDate} onChange={f("scheduledDate")} />
              <Input label="Amount (₹)" type="number" value={form.amount} onChange={f("amount")} />
              <Textarea label="Description" value={form.description} onChange={f("description")} className="col-span-2" />
            </div>
            <div className="flex gap-3 pt-2">
              <Button type="submit" className="flex-1">Raise Work Order</Button>
              <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
            </div>
          </form>
        </Modal>

        {/* Detail Modal */}
        {detailJob && (
          <Modal isOpen={!!detailJob} onClose={() => setDetailJob(null)} title={`${detailJob.id} — ${detailJob.title}`} size="lg">
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                {[
                  { label: "Status", value: <Badge label={detailJob.status} /> },
                  { label: "Priority", value: <Badge label={detailJob.priority} /> },
                  { label: "Client", value: clients.find(c => c.id === detailJob.clientId)?.name || "—" },
                  { label: "Technician", value: technicians.find(t => t.id === detailJob.technicianId)?.name || "Not Assigned" },
                  { label: "Category", value: detailJob.category },
                  { label: "Amount", value: `₹${Number(detailJob.amount).toLocaleString()}` },
                  { label: "Raised", value: detailJob.raisedDate },
                  { label: "Scheduled", value: detailJob.scheduledDate || "—" },
                ].map(item => (
                  <div key={item.label}>
                    <p className="text-xs text-gray-400 mb-0.5">{item.label}</p>
                    <p className="text-sm font-medium text-gray-800 dark:text-gray-200">{item.value}</p>
                  </div>
                ))}
              </div>
              <div className="pt-2 border-t border-gray-100 dark:border-gray-700">
                <p className="text-xs text-gray-400 mb-1">Description</p>
                <p className="text-sm text-gray-700 dark:text-gray-300">{detailJob.description || "No description."}</p>
              </div>

              {/* Status pipeline */}
              <div className="flex items-center gap-1 pt-2">
                {STATUSES.map((s, i) => (
                  <div key={s} className="flex items-center gap-1 flex-1 min-w-0">
                    <div className={`flex-1 text-center py-1.5 rounded-lg text-xs font-semibold truncate ${STATUSES.indexOf(detailJob.status) >= i ? "bg-blue-600 text-white" : "bg-gray-100 dark:bg-gray-700 text-gray-500"}`}>{s}</div>
                    {i < STATUSES.length - 1 && <ArrowRight size={12} className="text-gray-300 flex-shrink-0" />}
                  </div>
                ))}
              </div>

              {STATUS_FLOW[detailJob.status] && (
                <Button onClick={() => { advanceStatus(detailJob); setDetailJob(p => ({ ...p, status: STATUS_FLOW[p.status] })); }} className="w-full">
                  Advance to {STATUS_FLOW[detailJob.status]} <ArrowRight size={16} />
                </Button>
              )}
            </div>
          </Modal>
        )}

        {toast && <Toast {...toast} onClose={() => {}} />}
      </div>
    </PageTransition>
  );
}

function JobCard({ job, clients, technicians, onDetail, onAdvance, currentUser, horizontal = false }) {
  const client = clients.find(c => c.id === job.clientId);
  const tech = technicians.find(t => t.id === job.technicianId);
  return (
    <motion.div whileHover={{ y: -2 }} onClick={onDetail}
      className={`bg-white dark:bg-gray-800 rounded-xl shadow-sm border-l-4 border border-gray-100 dark:border-gray-700 p-4 cursor-pointer transition-all hover:shadow-md ${STATUS_COLOR[job.status]} ${horizontal ? "flex items-center gap-4" : ""}`}
    >
      <div className={horizontal ? "flex-1" : ""}>
        <div className="flex items-start justify-between gap-2 mb-2">
          <div>
            <p className="font-mono text-xs text-blue-500 dark:text-blue-400">{job.id}</p>
            <p className="font-semibold text-gray-800 dark:text-white text-sm mt-0.5">{job.title}</p>
          </div>
          <Badge label={job.priority} />
        </div>
        <div className="space-y-1 text-xs text-gray-500 dark:text-gray-400">
          <div className="flex items-center gap-1.5"><User size={11} />{client?.name || "—"}</div>
          {tech && <div className="flex items-center gap-1.5"><User size={11} className="text-blue-400" />{tech.name}</div>}
          {job.scheduledDate && <div className="flex items-center gap-1.5"><Calendar size={11} />{job.scheduledDate}</div>}
        </div>
      </div>
      {horizontal && (
        <div className="flex items-center gap-2 flex-shrink-0">
          <Badge label={job.status} />
          <span className="font-bold text-gray-800 dark:text-white text-sm">₹{Number(job.amount).toLocaleString()}</span>
        </div>
      )}
    </motion.div>
  );
}
