import { useState, useRef } from "react";
import { motion } from "framer-motion";
import { Plus, ClipboardList, Image, CheckCircle, XCircle } from "lucide-react";
import { useApp } from "../context/AppContext";
import { PageTransition, Card, Badge, Button, Modal, Input, Select, Textarea, SectionHeader, EmptyState, useToast, Toast } from "../components/ui";

const EMPTY = { jobId: "", title: "", findings: "", recommendations: "" };

export default function Reports() {
  const { reports, jobs, technicians, clients, addReport, updateReport, currentUser } = useApp();
  const { toast, showToast } = useToast();
  const [modalOpen, setModalOpen] = useState(false);
  const [detailReport, setDetailReport] = useState(null);
  const [form, setForm] = useState(EMPTY);
  const [previewImages, setPreviewImages] = useState([]);
  const fileRef = useRef();

  const f = field => e => setForm(p => ({ ...p, [field]: e.target.value }));

  const handleImageUpload = (e) => {
    const files = Array.from(e.target.files);
    files.forEach(file => {
      const reader = new FileReader();
      reader.onload = ev => setPreviewImages(p => [...p, { name: file.name, url: ev.target.result }]);
      reader.readAsDataURL(file);
    });
  };

  const handleSubmit = e => {
    e.preventDefault();
    addReport({ ...form, technicianId: currentUser?.id || 1, images: previewImages });
    setModalOpen(false);
    showToast("Report submitted!");
    setForm(EMPTY);
    setPreviewImages([]);
  };

  const approve = (id) => { updateReport(id, { status: "Approved" }); showToast("Report approved!"); };
  const reject = (id) => { updateReport(id, { status: "Rejected" }); showToast("Report rejected", "error"); };

  const canApprove = currentUser?.role === "Admin";

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-7xl mx-auto">
        <SectionHeader
          title="Inspection & Service Reports"
          subtitle={`${reports.length} reports submitted`}
          action={<Button onClick={() => setModalOpen(true)}><Plus size={16} /> New Report</Button>}
        />

        {reports.length === 0 ? (
          <EmptyState icon={ClipboardList} title="No reports yet" description="Submit a service report after completing a job." />
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {reports.map((r, i) => {
              const job = jobs.find(j => j.id === r.jobId);
              const tech = technicians.find(t => t.id === r.technicianId);
              const client = job ? clients.find(c => c.id === job.clientId) : null;
              return (
                <motion.div key={r.id} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}>
                  <Card hover className="p-5" onClick={() => setDetailReport(r)}>
                    <div className="flex items-start justify-between mb-3">
                      <div>
                        <p className="font-mono text-xs text-blue-500 dark:text-blue-400">{r.id}</p>
                        <p className="font-bold text-gray-900 dark:text-white text-sm mt-0.5">{r.title}</p>
                        <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">{client?.name || job?.title || "—"}</p>
                      </div>
                      <Badge label={r.status} />
                    </div>
                    <div className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-3 mb-3">
                      <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 mb-1">Findings</p>
                      <p className="text-sm text-gray-700 dark:text-gray-300 line-clamp-2">{r.findings}</p>
                    </div>
                    {r.images?.length > 0 && (
                      <div className="flex gap-2 mb-3">
                        {r.images.slice(0, 3).map((img, idx) => (
                          <img key={idx} src={img.url} alt={img.name} className="w-14 h-14 object-cover rounded-lg border border-gray-200 dark:border-gray-600" />
                        ))}
                        {r.images.length > 3 && <div className="w-14 h-14 rounded-lg bg-gray-100 dark:bg-gray-700 flex items-center justify-center text-xs text-gray-500">+{r.images.length - 3}</div>}
                      </div>
                    )}
                    <div className="flex items-center justify-between text-xs text-gray-400">
                      <span>{tech?.name || "—"} · {r.date}</span>
                      {canApprove && r.status === "Pending" && (
                        <div className="flex gap-2" onClick={e => e.stopPropagation()}>
                          <button onClick={() => approve(r.id)} className="flex items-center gap-1 text-emerald-600 hover:text-emerald-700 font-semibold"><CheckCircle size={14} /> Approve</button>
                          <button onClick={() => reject(r.id)} className="flex items-center gap-1 text-red-500 hover:text-red-600 font-semibold"><XCircle size={14} /> Reject</button>
                        </div>
                      )}
                    </div>
                  </Card>
                </motion.div>
              );
            })}
          </div>
        )}

        {/* New Report Modal */}
        <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title="Submit Service Report" size="lg">
          <form onSubmit={handleSubmit} className="space-y-4">
            <Select label="Linked Job" value={form.jobId} onChange={f("jobId")} required
              options={[{ value: "", label: "Select job..." }, ...jobs.map(j => ({ value: j.id, label: `${j.id} — ${j.title}` }))]} />
            <Input label="Report Title" value={form.title} onChange={f("title")} required placeholder="HVAC Servicing Report" />
            <Textarea label="Findings" value={form.findings} onChange={f("findings")} rows={3} placeholder="Describe what was found during inspection..." />
            <Textarea label="Recommendations" value={form.recommendations} onChange={f("recommendations")} rows={2} placeholder="Suggested follow-up actions..." />

            {/* Image Upload */}
            <div>
              <p className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Attach Images</p>
              <div onClick={() => fileRef.current?.click()}
                className="border-2 border-dashed border-gray-200 dark:border-gray-600 rounded-xl p-4 text-center cursor-pointer hover:border-blue-400 transition">
                <Image size={24} className="mx-auto text-gray-300 dark:text-gray-500 mb-1" />
                <p className="text-xs text-gray-400">Click to upload photos</p>
                <input ref={fileRef} type="file" accept="image/*" multiple className="hidden" onChange={handleImageUpload} />
              </div>
              {previewImages.length > 0 && (
                <div className="flex flex-wrap gap-2 mt-2">
                  {previewImages.map((img, i) => (
                    <div key={i} className="relative">
                      <img src={img.url} alt={img.name} className="w-16 h-16 object-cover rounded-lg" />
                      <button type="button" onClick={() => setPreviewImages(p => p.filter((_, idx) => idx !== i))}
                        className="absolute -top-1 -right-1 bg-red-500 text-white rounded-full w-4 h-4 flex items-center justify-center text-xs">×</button>
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="flex gap-3 pt-2">
              <Button type="submit" className="flex-1">Submit Report</Button>
              <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancel</Button>
            </div>
          </form>
        </Modal>

        {/* Detail Modal */}
        {detailReport && (
          <Modal isOpen={!!detailReport} onClose={() => setDetailReport(null)} title={detailReport.title} size="lg">
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div><p className="text-xs text-gray-400">Report ID</p><p className="font-mono font-semibold text-blue-600">{detailReport.id}</p></div>
                <div><p className="text-xs text-gray-400">Status</p><Badge label={detailReport.status} /></div>
                <div><p className="text-xs text-gray-400">Linked Job</p><p className="font-medium text-gray-800 dark:text-gray-200">{detailReport.jobId}</p></div>
                <div><p className="text-xs text-gray-400">Date</p><p className="font-medium text-gray-800 dark:text-gray-200">{detailReport.date}</p></div>
              </div>
              <div className="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-4">
                <p className="text-xs font-semibold text-gray-500 mb-1">Findings</p>
                <p className="text-sm text-gray-700 dark:text-gray-300">{detailReport.findings}</p>
              </div>
              <div className="bg-blue-50 dark:bg-blue-900/20 rounded-xl p-4">
                <p className="text-xs font-semibold text-blue-600 mb-1">Recommendations</p>
                <p className="text-sm text-gray-700 dark:text-gray-300">{detailReport.recommendations}</p>
              </div>
              {detailReport.images?.length > 0 && (
                <div>
                  <p className="text-xs font-semibold text-gray-500 mb-2">Attached Images ({detailReport.images.length})</p>
                  <div className="flex flex-wrap gap-2">
                    {detailReport.images.map((img, i) => (
                      <img key={i} src={img.url} alt={img.name} className="w-20 h-20 object-cover rounded-xl border border-gray-200 dark:border-gray-600" />
                    ))}
                  </div>
                </div>
              )}
            </div>
          </Modal>
        )}

        {toast && <Toast {...toast} onClose={() => {}} />}
      </div>
    </PageTransition>
  );
}
