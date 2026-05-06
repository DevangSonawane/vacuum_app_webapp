// ============================================================
// src/pages/CreateReport.jsx
// Route: /reports/create
// Full AMC Service Report creation — matches the 4-page PDF
// ============================================================

import { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import {
  ArrowLeft, Plus, Trash2, ChevronDown, ChevronUp,
  Loader2, FileText, FileCheck, AlertCircle,
  Paperclip, Upload, Image as ImageIcon,
  X, CheckCircle, Mail, ClipboardList,
  Wrench, AlertTriangle, Package, PenLine
} from "lucide-react";
import axios from "axios";
import {
  PageTransition, Card, Button, Input, Select,
  Textarea, useToast, Toast
} from "../components/ui";

const API_BASE_URL = "https://vaccumapi.onrender.com/api";

// ── Default checklist from PDF Page 1 ──────────────────────
const DEFAULT_CHECKLIST = [
  { sr: 1, description: "Check the oil level in the oil reserves.",                         status: "" },
  { sr: 2, description: "Check the oil level on the Root Compressors (If available).",      status: "" },
  { sr: 3, description: "Check the lubrication circuit.",                                   status: "" },
  { sr: 4, description: "Check the discharge valves.",                                      status: "" },
  { sr: 5, description: "Check & adjust the Gland packing.",                                status: "" },
  { sr: 6, description: "Oil filter cleaning.",                                             status: "" },
  { sr: 7, description: "Greasing of the pump.",                                            status: "" },
  { sr: 8, description: "Check the oil seal Ring.",                                         status: "" },
  { sr: 9, description: "Check & adjustment of the driving belts.",                         status: "" },
];

// Status options per checklist item (from PDF)
const CHECKLIST_STATUS_OPTIONS = {
  1: ["", "OK", "Topped Up"],
  2: ["", "OK", "Topped Up", "NA"],
  3: ["", "Normal", "Leakage", "Blockage"],
  4: ["", "OK", "Cleaned / Replaced", "Spare Required"],
  5: ["", "OK", "Adjusted / Replaced", "Spare Required"],
  6: ["", "OK", "Cleaned / Replaced", "Spare Required"],
  7: ["", "OK", "Done"],
  8: ["", "OK", "Replaced", "Spare Required"],
  9: ["", "OK", "Replaced", "Spare Required"],
};

// Default mandatory spares from PDF Page 4
const DEFAULT_SPARES = [
  { spare_name: "Complete set of Gaskets",        pump_model: "", total_to_order: "" },
  { spare_name: "Complete set of Valve Gasket",   pump_model: "", total_to_order: "" },
  { spare_name: "Complete set of Valve Spring",   pump_model: "", total_to_order: "" },
  { spare_name: "Complete set of Valve Screw",    pump_model: "", total_to_order: "" },
  { spare_name: "Complete set of Oil Connectors", pump_model: "", total_to_order: "" },
  { spare_name: "Ferrule / Insert / Reducer set", pump_model: "", total_to_order: "" },
  { spare_name: "Nylon Tubing Set",               pump_model: "", total_to_order: "" },
];

// ── Issue data from PDF Pages 2 & 3 ──────────────────────────
// Each issue has predefined rows: { observation, impact_on_pump, severity, recommended_spares }
const ISSUE_DATA = {
  "Low Vaccum": [
    { observation: "Valve damage (chock up)",  impact_on_pump: "Overheat",                    severity: "Med",  recommended_spares: "Valve set"             },
    { observation: "Slide valve Damaged",       impact_on_pump: "Abnormal Noise",              severity: "High", recommended_spares: "Slide valve or spring"  },
    { observation: "Piston ring Damaged",       impact_on_pump: "Piston or cylinder damage",   severity: "High", recommended_spares: "Piston ring"            },
    { observation: "Oil seal Damaged",          impact_on_pump: "Oil consumption Vacuum",      severity: "Med",  recommended_spares: "Sealing set"            },
  ],
  "Abnormal Sound": [
    { observation: "Slide valve / Slide Valve spring Damaged", impact_on_pump: "Overheat, Low Vacuum",      severity: "High", recommended_spares: "Slide valve / Slide Valve spring"    },
    { observation: "Shell Bearing Damaged",                    impact_on_pump: "Mechanical Damaged",        severity: "High", recommended_spares: "Shell Bearing"                        },
    { observation: "Piston Pin / Bush Damaged",                impact_on_pump: "Mechanical Damaged",        severity: "High", recommended_spares: "Piston Pin / Bush"                    },
    { observation: "Flywheel / Distrubustion Rod Bearing Damaged", impact_on_pump: "High Vibration",        severity: "High", recommended_spares: "Flywheel / Distrubustion Rod Bearing" },
    { observation: "Distribution Control Pin Damaged",         impact_on_pump: "Lubrication Pump Damage",  severity: "High", recommended_spares: "Distribution Control Pin"             },
    { observation: "Pin For Outer Lever Damaged",              impact_on_pump: "Tie Rod Head Damage",       severity: "High", recommended_spares: "Pin For Outer Lever"                  },
    { observation: "Connecting Rod Damaged",                   impact_on_pump: "Mechanical Damage",         severity: "High", recommended_spares: "Connecting Rod"                       },
    { observation: "Crankshaft Damaged",                       impact_on_pump: "Mechanical Damage",         severity: "High", recommended_spares: "Crank Shaft"                          },
    { observation: "Inner Lever Damaged",                      impact_on_pump: "Slide Valve Damage",        severity: "High", recommended_spares: "Inner Lever"                          },
    { observation: "Cross Head Damaged",                       impact_on_pump: "Mechanical Damage",         severity: "High", recommended_spares: "Cross Head"                           },
  ],
  "Excessive Oil": [
    { observation: "Gland Packing Damaged",         impact_on_pump: "Oil Leakage and Smoke",        severity: "Med",  recommended_spares: "Gland Packing"        },
    { observation: "Oil seal Damaged",              impact_on_pump: "Oil Leakage",                  severity: "High", recommended_spares: "Oil seal"             },
    { observation: "Nylon Tubing Damaged",          impact_on_pump: "Oil Leakage",                  severity: "High", recommended_spares: "Nylon Tubing"         },
    { observation: "Oil connector / Oiler Damaged", impact_on_pump: "Oil Leakage",                  severity: "High", recommended_spares: "Oil connector / Oiler" },
    { observation: "Piston Rod Damaged",            impact_on_pump: "Oil Consumption and Smoke",    severity: "Med",  recommended_spares: "Piston Rod"           },
  ],
  "No Lubrication": [
    { observation: "Oil Filter Chocked / Damaged",  impact_on_pump: "Overheat, Wear and Tare on Cylinder and Piston", severity: "High", recommended_spares: "Oil Filter Choked"    },
    { observation: "Lubrication Pump/ Lever Damaged", impact_on_pump: "Overheat, Wear and Tare on Cylinder and Piston", severity: "High", recommended_spares: "Lubrication Pump / Lever" },
  ],
};

const ISSUE_TYPES    = ["Low Vaccum", "Abnormal Sound", "Excessive Oil", "No Lubrication"];
const SEVERITY_OPTIONS = ["", "Low", "Med", "High"];

const EMPTY_ISSUE = {
  sr: 1, issue: "", observation: "", impact_on_pump: "", severity: "", recommended_spares: ""
};

// ── Step indicator ────────────────────────────────────────────
const STEPS = [
  { id: 1, label: "Client Info",    icon: ClipboardList },
  { id: 2, label: "Checklist",      icon: CheckCircle   },
  { id: 3, label: "Issues",         icon: AlertTriangle },
  { id: 4, label: "Spares",         icon: Package       },
  { id: 5, label: "Remarks",        icon: PenLine       },
];

export default function CreateReport() {
  const navigate = useNavigate();
  const { toast, showToast } = useToast();

  const [step, setStep]               = useState(1);
  const [jobs, setJobs]               = useState([]);
  const [technicians, setTechnicians] = useState([]);
  const [clients, setClients]         = useState([]);
  const [amcContracts, setAmcContracts] = useState([]);
  const [submitting, setSubmitting]   = useState(false);

  // ── Form state ──────────────────────────────────────────
  const [form, setForm] = useState({
    // core
    job_id: "", title: "", technician_id: "",
    po_number: "", serial_no: "",
    // client info (PDF Page 1)
    client_id: "", client_name: "", client_email: "",
    company_name: "", contact_person: "",
    model_serial_installation: "",
    operating_hours_per_day: "",
    application_process_description: "",
    // findings / recommendations / comments
    findings: "", recommendations: "", comments: "",
    // remarks (PDF Page 3)
    remarks: "",
    // signatures (PDF Page 4)
    vdt_representative_name: "", client_representative_name: "",
  });

  // ── PDF section state ───────────────────────────────────
  const [checklist, setChecklist]           = useState(DEFAULT_CHECKLIST);
  const [issues, setIssues]                 = useState([{ ...EMPTY_ISSUE }]);
  const [spares, setSpares]                 = useState(DEFAULT_SPARES);

  // ── File upload state ───────────────────────────────────
  const [techFiles, setTechFiles]           = useState([]);
  const [uploadingTech, setUploadingTech]   = useState(false);
  const [previewImages, setPreviewImages]   = useState([]);
  const techRef = useRef();
  const imgRef  = useRef();

  useEffect(() => {
    fetchJobs(); fetchTechnicians(); fetchClients(); fetchAmcContracts();
  }, []);

  // Auto-fill client when job selected
  useEffect(() => {
    if (form.job_id && clients.length > 0) {
      const job = jobs.find(j => String(j.id) === String(form.job_id));
      if (job) {
        const client = clients.find(c => String(c.id) === String(job.client_id));
        
        setForm(p => ({
          ...p,
          client_id:    client ? String(client.id) : String(job.client_id || ""),
          client_name:  client?.name || (job.client_name !== "Asynk" ? job.client_name : "") || "",
          client_email: client?.email || (job.client_email !== "Asynk" ? job.client_email : "") || "",
          company_name: client?.name || (job.client_name !== "Asynk" ? job.client_name : "") || "",
          contact_person: client?.contact_person || (job.contact_person !== "Asynk" ? job.contact_person : "") || "",
        }));
      }
    }
  }, [form.job_id, jobs, clients]);

  const fetchJobs = async () => {
    try {
      const token = localStorage.getItem("token");
      const res = await axios.get(`${API_BASE_URL}/jobs`, {
        headers: { Authorization: `Bearer ${token}` }, params: { limit: 200 }
      });
      if (res.data.success) setJobs(res.data.data || []);
    } catch {}
  };

  const fetchTechnicians = async () => {
    try {
      const token = localStorage.getItem("token");
      const res = await axios.get(`${API_BASE_URL}/technicians`, {
        headers: { Authorization: `Bearer ${token}` }, params: { limit: 100 }
      });
      if (res.data.success) setTechnicians(res.data.data || []);
    } catch {}
  };

  const fetchClients = async () => {
    try {
      const token = localStorage.getItem("token");
      const res = await axios.get(`${API_BASE_URL}/clients`, {
        headers: { Authorization: `Bearer ${token}` }, params: { limit: 100 }
      });
      if (res.data.success) setClients(res.data.data || []);
    } catch {}
  };

  const fetchAmcContracts = async () => {
    try {
      const token = localStorage.getItem("token");
      const res = await axios.get(`${API_BASE_URL}/amc`, {
        headers: { Authorization: `Bearer ${token}` }, params: { limit: 200 }
      });
      if (res.data.success) setAmcContracts(res.data.data || []);
    } catch {}
  };

  // ── Checklist helpers ───────────────────────────────────
  const setChecklistStatus = (idx, status) => {
    setChecklist(p => p.map((item, i) => i === idx ? { ...item, status } : item));
  };

  // ── Issue helpers ───────────────────────────────────────
  const addIssue = () => {
    setIssues(p => [...p, { ...EMPTY_ISSUE, sr: p.length + 1 }]);
  };
  const removeIssue = (idx) => setIssues(p => p.filter((_, i) => i !== idx));

  // When issue type changes → reset observation/impact/severity/spares
  const setIssueType = (idx, issueType) => {
    setIssues(p => p.map((item, i) =>
      i === idx
        ? { ...item, issue: issueType, observation: "", impact_on_pump: "", severity: "", recommended_spares: "" }
        : item
    ));
  };

  // When observation is selected → auto-fill impact, severity, spares
  const setIssueObservation = (idx, observation) => {
    const issueType = issues[idx].issue;
    const rows      = ISSUE_DATA[issueType] || [];
    const matched   = rows.find(r => r.observation === observation);
    setIssues(p => p.map((item, i) =>
      i === idx
        ? {
            ...item,
            observation,
            impact_on_pump:     matched?.impact_on_pump     || "",
            severity:           matched?.severity           || "",
            recommended_spares: matched?.recommended_spares || "",
          }
        : item
    ));
  };

  const setIssueField = (idx, field, val) => {
    setIssues(p => p.map((item, i) => i === idx ? { ...item, [field]: val } : item));
  };

  // ── Spare helpers ────────────────────────────────────────
  const addSpare = () => setSpares(p => [...p, { spare_name: "", pump_model: "", total_to_order: "" }]);
  const removeSpare = (idx) => setSpares(p => p.filter((_, i) => i !== idx));
  const setSpareField = (idx, field, val) => {
    setSpares(p => p.map((item, i) => i === idx ? { ...item, [field]: val } : item));
  };

  // ── Tech file upload ─────────────────────────────────────
  const handleTechFileSelect = async (e) => {
    const files = Array.from(e.target.files);
    if (!files.length) return;
    e.target.value = "";
    const newEntries = files.map(file => ({
      file, name: file.name, uploading: true, uploaded: false,
      url: null, mime_type: file.type, file_size_bytes: file.size, error: null,
    }));
    setTechFiles(p => [...p, ...newEntries]);
    setUploadingTech(true);
    const token = localStorage.getItem("token");
    const fd = new FormData();
    files.forEach(f => fd.append("files", f));
    try {
      const res = await axios.post(`${API_BASE_URL}/upload/technical-reports`, fd, {
        headers: { Authorization: `Bearer ${token}`, "Content-Type": "multipart/form-data" }
      });
      const uploaded = res.data.data || [];
      setTechFiles(prev => {
        const startIdx = prev.length - files.length;
        return prev.map((entry, i) => {
          if (i < startIdx) return entry;
          const up = uploaded[i - startIdx];
          if (up) return { ...entry, uploading: false, uploaded: true, file_name: up.file_name, file_url: up.file_url, mime_type: up.mime_type, file_size_bytes: up.file_size_bytes };
          return { ...entry, uploading: false, error: "Failed" };
        });
      });
    } catch {
      setTechFiles(prev => prev.map((e, i) => i >= prev.length - files.length ? { ...e, uploading: false, error: "Upload failed" } : e));
      showToast("Failed to upload technical reports", "error");
    } finally {
      setUploadingTech(false);
    }
  };

  const removeTechFile = (idx) => setTechFiles(p => p.filter((_, i) => i !== idx));

  // ── Image helpers ────────────────────────────────────────
  const handleImageSelect = (e) => {
    const files = Array.from(e.target.files);
    setPreviewImages(p => [...p, ...files.map(file => ({
      file, preview: URL.createObjectURL(file), uploading: false, uploaded_url: null, error: null
    }))]);
    e.target.value = "";
  };
  const removeImage = (idx) => setPreviewImages(p => p.filter((_, i) => i !== idx));
  const uploadOneImage = async (imgObj, reportId) => {
    const token = localStorage.getItem("token");
    const fd = new FormData();
    fd.append("images", imgObj.file);
    const res = await axios.post(
      `${API_BASE_URL}/upload?entity_type=report&entity_id=${reportId}`,
      fd, { headers: { Authorization: `Bearer ${token}`, "Content-Type": "multipart/form-data" } }
    );
    const up = res.data.data?.[0];
    if (!up) throw new Error("Empty upload response");
    return up;
  };

  // ── Validation per step ──────────────────────────────────
  const validateStep = () => {
    if (step === 1) {
      if (!form.job_id)        return showToast("Please select a linked job.", "error"),        false;
      if (!form.technician_id) return showToast("Please select the technician.", "error"),      false;
      if (!form.title.trim())  return showToast("Please enter a report title.", "error"),       false;
      if (!form.company_name.trim()) return showToast("Please enter the company name.", "error"), false;
    }
    return true;
  };

  const nextStep = () => { if (validateStep()) setStep(s => Math.min(s + 1, 5)); };
  const prevStep = () => setStep(s => Math.max(s - 1, 1));

  // ── Submit ────────────────────────────────────────────────
  const handleSubmit = async () => {
    if (uploadingTech) return showToast("Please wait for files to finish uploading.", "error");
    const failedUploads = techFiles.filter(f => f.error);
    if (failedUploads.length) return showToast("Some files failed to upload. Remove them and retry.", "error");

    setSubmitting(true);
    const token = localStorage.getItem("token");

    try {
      const technical_reports = techFiles
        .filter(f => f.uploaded && f.file_url)
        .map(f => ({ file_name: f.file_name || f.name, file_url: f.file_url, mime_type: f.mime_type || "application/pdf", file_size_bytes: f.file_size_bytes || null }));

      const payload = {
        job_id:          form.job_id,
        title:           form.title.trim(),
        technician_id:   parseInt(form.technician_id),
        po_number:       form.po_number       || undefined,
        serial_no:       form.serial_no       || undefined,
        client_id:       form.client_id       ? parseInt(form.client_id) : undefined,
        client_name:     form.client_name     || undefined,
        client_email:    form.client_email    || undefined,
        company_name:    form.company_name    || undefined,
        contact_person:  form.contact_person  || undefined,
        model_serial_installation:      form.model_serial_installation      || undefined,
        operating_hours_per_day:        form.operating_hours_per_day        || undefined,
        application_process_description: form.application_process_description || undefined,
        findings:        form.findings        || undefined,
        recommendations: form.recommendations || undefined,
        comments:        form.comments        || undefined,
        remarks:         form.remarks         || undefined,
        vdt_representative_name:    form.vdt_representative_name    || undefined,
        client_representative_name: form.client_representative_name || undefined,
        checklist_items:    checklist.filter(c => c.status),
        issue_observations: issues.filter(i => i.issue || i.observation),
        mandatory_spares:   spares.filter(s => s.spare_name),
        technical_reports,
      };

      const res = await axios.post(`${API_BASE_URL}/reports`, payload, {
        headers: { Authorization: `Bearer ${token}` }
      });

      const reportId = res.data.data?.id;

      // Upload images post-create
      if (previewImages.length > 0 && reportId) {
        setPreviewImages(p => p.map(im => ({ ...im, uploading: true })));
        for (let idx = 0; idx < previewImages.length; idx++) {
          try {
            const uploaded = await uploadOneImage(previewImages[idx], reportId);
            await axios.post(
              `${API_BASE_URL}/reports/${reportId}/images`,
              { file_name: uploaded.original_name, file_url: uploaded.file_url, mime_type: uploaded.mime_type || "image/jpeg", file_size_bytes: uploaded.file_size_bytes },
              { headers: { Authorization: `Bearer ${token}` } }
            );
            setPreviewImages(p => p.map((im, i) => i === idx ? { ...im, uploading: false, uploaded_url: uploaded.file_url } : im));
          } catch {
            setPreviewImages(p => p.map((im, i) => i === idx ? { ...im, uploading: false, error: "Failed" } : im));
          }
        }
      }

      showToast(`Report ${reportId} submitted successfully!${form.client_email ? ` Email sent to ${form.client_email}.` : ""}`);
      navigate("/reports");
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to submit report", "error");
    } finally {
      setSubmitting(false);
    }
  };

  const f = (field) => form[field];
  const sf = (field) => (e) => setForm(p => ({ ...p, [field]: e.target.value }));

  return (
    <PageTransition>
      <div className="p-4 md:p-8 max-w-7xl mx-auto space-y-6">

        {/* Header */}
        <div className="flex items-start gap-4 mb-6">
          <button onClick={() => navigate("/reports")}
            className="mt-1 p-2 rounded-xl text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-800 transition flex-shrink-0">
            <ArrowLeft size={20} />
          </button>
          <div className="flex-1 min-w-0">
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white leading-tight">Service Report</h1>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
              Italvacuum Pump — Vacuum Drying Technology India LLP
            </p>
          </div>
        </div>

        {/* Step indicator */}
        <div className="flex items-center mb-8 overflow-x-auto pb-1">
          {STEPS.map((s, i) => {
            const Icon = s.icon;
            const isActive   = step === s.id;
            const isComplete = step > s.id;
            return (
              <div key={s.id} className="flex items-center flex-shrink-0">
                <button
                  onClick={() => isComplete && setStep(s.id)}
                  className={`flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-semibold transition
                    ${isActive   ? "bg-blue-600 text-white shadow-md shadow-blue-200 dark:shadow-blue-900" :
                      isComplete ? "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400 cursor-pointer hover:bg-emerald-200" :
                                   "bg-gray-100 dark:bg-gray-700 text-gray-400 dark:text-gray-500 cursor-default"}`}
                >
                  {isComplete ? <CheckCircle size={13} /> : <Icon size={13} />}
                  <span className="hidden sm:inline">{s.label}</span>
                  <span className="sm:hidden">{s.id}</span>
                </button>
                {i < STEPS.length - 1 && (
                  <div className={`mx-1 h-px w-6 flex-shrink-0 ${step > s.id ? "bg-emerald-400" : "bg-gray-200 dark:bg-gray-600"}`} />
                )}
              </div>
            );
          })}
        </div>

        {/* ── STEP 1: Client Info (PDF Page 1) ──────────────── */}
        <AnimatePresence mode="wait">
          {step === 1 && (
            <motion.div key="step1" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}>
              <Card className="p-6 space-y-5">
                <SectionTitle icon={ClipboardList} label="Step 1 — Client & Report Info" color="blue" />

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <Select label="Linked Job *" value={f("job_id")}
                    onChange={e => {
                      const jobId = e.target.value;
                      const selectedJob = jobs.find(j => String(j.id) === jobId);
                      const linkedAmc = amcContracts.find(a => String(a.id) === String(selectedJob?.amc_id));
                      setForm(p => ({
                        ...p,
                        job_id: jobId,
                        technician_id: selectedJob?.technician_id || p.technician_id,
                        po_number: linkedAmc?.po_number || p.po_number
                      }));
                    }}
                    required
                    options={[{ value: "", label: "Select job..." }, ...jobs.map(j => ({ value: j.id, label: `${j.id} — ${j.title}` }))]}
                  />
                  <Select label="Technician *" value={f("technician_id")} onChange={sf("technician_id")} required
                    options={[{ value: "", label: "Select technician..." }, ...technicians.map(t => ({ value: t.id, label: t.name }))]}
                  />
                </div>

                <Input label="Report Title *" value={f("title")} onChange={sf("title")} required placeholder="Quarterly AMC Service — Italvacuum Pump" />

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <Select
                    label="PO Number"
                    value={f("po_number")}
                    onChange={sf("po_number")}
                    options={[
                      { value: "", label: "Select PO..." },
                      ...Array.from(new Set(amcContracts.map(a => a.po_number).filter(Boolean)))
                        .map(po => ({ value: po, label: po }))
                    ]}
                  />
                  <Input label="Serial No." value={f("serial_no")} onChange={sf("serial_no")} placeholder="VCP-2023-7842" />
                </div>

                <div className="border-t border-gray-100 dark:border-gray-700 pt-4">
                  <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-4">Client Info (PDF Page 1)</p>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <Select label="Client" value={f("client_id")}
                      onChange={e => {
                        const clientId = e.target.value;
                        const client = clients.find(cl => String(cl.id) === String(clientId));
                        setForm(p => ({
                          ...p,
                          client_id: clientId,
                          client_name: client?.name || "",
                          client_email: client?.email || "",
                          company_name: client?.name || "",
                          contact_person: client?.contact_person || ""
                        }));
                      }}
                      options={[{ value: "", label: "Select client..." }, ...clients.map(c => ({ value: c.id, label: c.name }))]}
                    />
                    <Input label="Client Email" type="email" value={f("client_email")} onChange={sf("client_email")} placeholder="client@company.com" />
                  </div>
                  {form.client_email && (
                    <p className="mt-1.5 text-xs text-blue-500 flex items-center gap-1"><Mail size={11} /> Report email will be sent here on submission.</p>
                  )}

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-4">
                    <Input label="Company Name *" value={f("company_name")} onChange={sf("company_name")} required placeholder="Acme Industries Pvt Ltd" />
                    <Input label="Contact Person" value={f("contact_person")} onChange={sf("contact_person")} placeholder="Rajesh Mehta" />
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-4">
                    <Input label="Model / Serial No. / Installation Year" value={f("model_serial_installation")} onChange={sf("model_serial_installation")} placeholder="ITPUMP-V2 / SN-20034 / 2021" />
                    <Input label="Operating Hours / Day" value={f("operating_hours_per_day")} onChange={sf("operating_hours_per_day")} placeholder="18 hrs" />
                  </div>
                  <div className="mt-4">
                    <Textarea label="Application / Process Description" value={f("application_process_description")} onChange={sf("application_process_description")} rows={2} placeholder="Vacuum drying of pharmaceutical granules" />
                  </div>
                </div>
              </Card>
            </motion.div>
          )}

          {/* ── STEP 2: Checklist (PDF Page 1) ──────────────── */}
          {step === 2 && (
            <motion.div key="step2" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}>
              <Card className="p-6">
                <SectionTitle icon={CheckCircle} label="Step 2 — Routine Preventive Maintenance Checklist" color="emerald" />
                <p className="text-xs text-gray-400 mb-5 mt-1">Select the status for each checklist item from the PDF.</p>

                <div className="space-y-3">
                  {checklist.map((item, idx) => {
                    const opts = CHECKLIST_STATUS_OPTIONS[item.sr] || ["", "OK", "Done"];
                    return (
                      <div key={item.sr} className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-700/50 rounded-xl">
                        <span className="w-6 h-6 rounded-full bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 text-xs font-bold flex items-center justify-center flex-shrink-0">
                          {item.sr}
                        </span>
                        <p className="flex-1 text-sm text-gray-700 dark:text-gray-300">{item.description}</p>
                        <div className="flex flex-wrap gap-1.5">
                          {opts.map(o => {
                            const isSelected = item.status === o;
                            return (
                              <button
                                key={o}
                                type="button"
                                onClick={() => setChecklistStatus(idx, o)}
                                className={`px-3 py-1.5 rounded-lg text-[10px] font-bold uppercase tracking-wider transition-all border
                                  ${isSelected
                                    ? "bg-blue-600 text-white border-blue-600 shadow-md shadow-blue-200 dark:shadow-blue-900/40"
                                    : "bg-white dark:bg-gray-800 text-gray-400 border-gray-100 dark:border-gray-700 hover:border-blue-300 dark:hover:border-blue-500"}`}
                              >
                                {o || "None"}
                              </button>
                            );
                          })}
                        </div>
                      </div>
                    );
                  })}
                </div>

                <div className="mt-5 p-4 bg-amber-50 dark:bg-amber-900/10 border border-amber-200 dark:border-amber-800 rounded-xl">
                  <p className="text-xs font-bold text-amber-700 dark:text-amber-400 mb-2">Site & Environmental Conditions</p>
                  <ul className="text-xs text-amber-700 dark:text-amber-300 space-y-1 list-disc list-inside">
                    <li>Maintain the pump installation area in a clean, dry and workable environment.</li>
                    <li>Ensure proper ventilation, lighting and access for maintenance activities.</li>
                    <li>Prevent the accumulation of dust, chemicals, solvents near the pump.</li>
                    <li>Maintain environmental cleanliness of the pump, motor and accessories at all times.</li>
                  </ul>
                </div>
              </Card>
            </motion.div>
          )}

          {/* ── STEP 3: Issue Observations (PDF Page 2 & 3) ─── */}
          {step === 3 && (
            <motion.div key="step3" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}>
              <Card className="p-6">
                <div className="flex items-center justify-between mb-2">
                  <SectionTitle icon={AlertTriangle} label="Step 3 — Detailed Issue Observation Matrix" color="orange" />
                  <Button variant="secondary" size="sm" onClick={addIssue}>
                    <Plus size={13} /> Add Issue
                  </Button>
                </div>
                <p className="text-xs text-gray-400 mb-5">Record each issue found during inspection (PDF Page 2 & 3). Selecting an observation auto-fills impact, severity and recommended spares.</p>

                <div className="space-y-5">
                  {issues.map((issue, idx) => {
                    // Observations available for selected issue type
                    const observationOptions = issue.issue
                      ? (ISSUE_DATA[issue.issue] || []).map(r => r.observation)
                      : [];

                    // Impact options: all unique impacts for selected issue
                    const impactOptions = issue.issue
                      ? [...new Set((ISSUE_DATA[issue.issue] || []).map(r => r.impact_on_pump))]
                      : [];

                    // Recommended spares options: all unique spares for selected issue
                    const sparesOptions = issue.issue
                      ? [...new Set((ISSUE_DATA[issue.issue] || []).map(r => r.recommended_spares))]
                      : [];

                    return (
                      <div key={idx} className="border border-gray-200 dark:border-gray-700 rounded-2xl overflow-hidden">

                        {/* Issue header */}
                        <div className="flex items-center justify-between px-4 py-3 bg-gray-50 dark:bg-gray-700/60 border-b border-gray-200 dark:border-gray-700">
                          <div className="flex items-center gap-2">
                            <span className={`w-6 h-6 rounded-full text-xs font-bold flex items-center justify-center flex-shrink-0
                              ${issue.severity === "High" ? "bg-red-100 text-red-600 dark:bg-red-900/40 dark:text-red-400" :
                                issue.severity === "Med"  ? "bg-amber-100 text-amber-600 dark:bg-amber-900/40 dark:text-amber-400" :
                                issue.severity === "Low"  ? "bg-green-100 text-green-600 dark:bg-green-900/40 dark:text-green-400" :
                                "bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400"}`}>
                              {idx + 1}
                            </span>
                            <span className="text-xs font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wide">
                              {issue.issue || `Issue #${idx + 1}`}
                            </span>
                            {issue.severity && (
                              <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full
                                ${issue.severity === "High" ? "bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400" :
                                  issue.severity === "Med"  ? "bg-amber-100 text-amber-600 dark:bg-amber-900/30 dark:text-amber-400" :
                                  "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"}`}>
                                {issue.severity}
                              </span>
                            )}
                          </div>
                          {issues.length > 1 && (
                            <button onClick={() => removeIssue(idx)} className="text-red-400 hover:text-red-600 transition p-1">
                              <Trash2 size={14} />
                            </button>
                          )}
                        </div>

                        <div className="p-4 space-y-4">

                          {/* Row 1: Issue Type */}
                          <div>
                            <label className="block text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5">
                              Issue Type <span className="text-red-400">*</span>
                            </label>
                            <div className="flex flex-wrap gap-2">
                              {ISSUE_TYPES.map(t => (
                                <button
                                  key={t}
                                  type="button"
                                  onClick={() => setIssueType(idx, t)}
                                  className={`px-3 py-1.5 rounded-xl text-xs font-semibold border transition-all
                                    ${issue.issue === t
                                      ? "bg-orange-500 text-white border-orange-500 shadow-sm"
                                      : "bg-white dark:bg-gray-800 text-gray-500 dark:text-gray-400 border-gray-200 dark:border-gray-600 hover:border-orange-400 hover:text-orange-500"}`}
                                >
                                  {t}
                                </button>
                              ))}
                            </div>
                          </div>

                          {/* Row 2: Observation (dropdown — unlocked after issue selected) */}
                          <div>
                            <label className="block text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5">
                              Observation
                              {issue.issue && <span className="ml-1 text-gray-400 font-normal">({observationOptions.length} options from PDF)</span>}
                            </label>
                            <select
                              value={issue.observation}
                              onChange={e => setIssueObservation(idx, e.target.value)}
                              disabled={!issue.issue}
                              className={`w-full text-sm px-3 py-2 rounded-xl border transition focus:outline-none focus:ring-2 focus:ring-blue-500
                                ${!issue.issue
                                  ? "bg-gray-100 dark:bg-gray-700/50 text-gray-400 border-gray-200 dark:border-gray-700 cursor-not-allowed"
                                  : issue.observation
                                    ? "bg-blue-50 dark:bg-blue-900/20 border-blue-300 dark:border-blue-700 text-blue-800 dark:text-blue-200 font-medium"
                                    : "bg-gray-50 dark:bg-gray-700 border-gray-200 dark:border-gray-600 text-gray-700 dark:text-gray-300"}`}
                            >
                              <option value="">{issue.issue ? "— Select observation —" : "— Select issue type first —"}</option>
                              {observationOptions.map(o => (
                                <option key={o} value={o}>{o}</option>
                              ))}
                            </select>
                          </div>

                          {/* Row 3: Impact + Severity side by side */}
                          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                            <div>
                              <label className="block text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5">Impact on Pump</label>
                              <select
                                value={issue.impact_on_pump}
                                onChange={e => setIssueField(idx, "impact_on_pump", e.target.value)}
                                disabled={!issue.issue}
                                className={`w-full text-sm px-3 py-2 rounded-xl border transition focus:outline-none focus:ring-2 focus:ring-blue-500
                                  ${!issue.issue
                                    ? "bg-gray-100 dark:bg-gray-700/50 text-gray-400 border-gray-200 dark:border-gray-700 cursor-not-allowed"
                                    : issue.impact_on_pump
                                      ? "bg-purple-50 dark:bg-purple-900/20 border-purple-300 dark:border-purple-700 text-purple-800 dark:text-purple-200 font-medium"
                                      : "bg-gray-50 dark:bg-gray-700 border-gray-200 dark:border-gray-600 text-gray-700 dark:text-gray-300"}`}
                              >
                                <option value="">{issue.issue ? "— Select impact —" : "— Select issue first —"}</option>
                                {impactOptions.map(o => (
                                  <option key={o} value={o}>{o}</option>
                                ))}
                              </select>
                            </div>

                            <div>
                              <label className="block text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5">Severity</label>
                              <div className="flex gap-2">
                                {["Low", "Med", "High"].map(sev => (
                                  <button
                                    key={sev}
                                    type="button"
                                    onClick={() => setIssueField(idx, "severity", sev)}
                                    className={`flex-1 py-2 rounded-xl text-xs font-bold border transition-all
                                      ${issue.severity === sev
                                        ? sev === "High" ? "bg-red-500 text-white border-red-500 shadow-sm" :
                                          sev === "Med"  ? "bg-amber-500 text-white border-amber-500 shadow-sm" :
                                                           "bg-green-500 text-white border-green-500 shadow-sm"
                                        : "bg-white dark:bg-gray-800 text-gray-400 border-gray-200 dark:border-gray-600 hover:border-gray-400"}`}
                                  >
                                    {sev}
                                  </button>
                                ))}
                              </div>
                            </div>
                          </div>

                          {/* Row 4: Recommended Spares (dropdown) */}
                          <div>
                            <label className="block text-xs font-semibold text-gray-600 dark:text-gray-400 mb-1.5">Recommended Spares</label>
                            <select
                              value={issue.recommended_spares}
                              onChange={e => setIssueField(idx, "recommended_spares", e.target.value)}
                              disabled={!issue.issue}
                              className={`w-full text-sm px-3 py-2 rounded-xl border transition focus:outline-none focus:ring-2 focus:ring-blue-500
                                ${!issue.issue
                                  ? "bg-gray-100 dark:bg-gray-700/50 text-gray-400 border-gray-200 dark:border-gray-700 cursor-not-allowed"
                                  : issue.recommended_spares
                                    ? "bg-emerald-50 dark:bg-emerald-900/20 border-emerald-300 dark:border-emerald-700 text-emerald-800 dark:text-emerald-200 font-medium"
                                    : "bg-gray-50 dark:bg-gray-700 border-gray-200 dark:border-gray-600 text-gray-700 dark:text-gray-300"}`}
                            >
                              <option value="">{issue.issue ? "— Select spare —" : "— Select issue first —"}</option>
                              {sparesOptions.map(o => (
                                <option key={o} value={o}>{o}</option>
                              ))}
                            </select>
                          </div>

                          {/* Auto-fill hint */}
                          {issue.observation && (
                            <div className="flex items-center gap-2 text-[11px] text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/20 px-3 py-2 rounded-xl">
                              <CheckCircle size={12} />
                              Auto-filled from PDF data. You can change any value above.
                            </div>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>

                {issues.length === 0 && (
                  <div className="text-center py-8 text-gray-400">
                    <AlertTriangle size={28} className="mx-auto mb-2 opacity-30" />
                    <p className="text-sm">No issues added. Click "Add Issue" to record observations.</p>
                  </div>
                )}
              </Card>
            </motion.div>
          )}

          {/* ── STEP 4: Mandatory Spares (PDF Page 4) ─────────── */}
          {step === 4 && (
            <motion.div key="step4" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}>
              <Card className="p-6">
                <div className="flex items-center justify-between mb-5">
                  <SectionTitle icon={Package} label="Step 4 — Mandatory Spares (AMC Compliance Matrix)" color="purple" />
                  <Button variant="secondary" size="sm" onClick={addSpare}>
                    <Plus size={13} /> Add Spare
                  </Button>
                </div>
                <p className="text-xs text-gray-400 mb-5 -mt-3">Specify pump model and quantity for each spare (PDF Page 4).</p>

                <div className="space-y-3">
                  {/* Header */}
                  <div className="grid grid-cols-12 gap-2 px-2">
                    <p className="col-span-5 text-xs font-bold text-gray-400 uppercase tracking-wide">Spare Name</p>
                    <p className="col-span-3 text-xs font-bold text-gray-400 uppercase tracking-wide">Pump Model</p>
                    <p className="col-span-3 text-xs font-bold text-gray-400 uppercase tracking-wide">Qty to Order</p>
                    <div className="col-span-1" />
                  </div>

                  {spares.map((spare, idx) => (
                    <div key={idx} className="grid grid-cols-12 gap-2 items-center p-2 bg-gray-50 dark:bg-gray-700/50 rounded-xl">
                      <input value={spare.spare_name}
                        onChange={e => setSpareField(idx, "spare_name", e.target.value)}
                        placeholder="Spare name"
                        className="col-span-5 text-sm px-3 py-1.5 rounded-xl border border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500" />
                      <input value={spare.pump_model}
                        onChange={e => setSpareField(idx, "pump_model", e.target.value)}
                        placeholder="Model"
                        className="col-span-3 text-sm px-3 py-1.5 rounded-xl border border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500" />
                      <input value={spare.total_to_order}
                        onChange={e => setSpareField(idx, "total_to_order", e.target.value)}
                        placeholder="Qty"
                        className="col-span-3 text-sm px-3 py-1.5 rounded-xl border border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500" />
                      <button onClick={() => removeSpare(idx)} className="col-span-1 text-red-400 hover:text-red-600 transition flex justify-center">
                        <Trash2 size={14} />
                      </button>
                    </div>
                  ))}
                </div>

                <div className="mt-6 p-4 bg-blue-50 dark:bg-blue-900/10 border border-blue-200 dark:border-blue-800 rounded-xl">
                  <p className="text-xs font-bold text-blue-700 dark:text-blue-400 mb-2">Commercial & Compliance Notes (AMC Aligned)</p>
                  <ol className="text-xs text-blue-700 dark:text-blue-300 space-y-1 list-decimal list-inside">
                    <li>The above-listed spares are MANDATORY / RECOMMENDED and must be PROCURED before the next scheduled maintenance visit.</li>
                    <li>If mandatory spares are not available, the visit may be restricted to inspection only (counted as a PM visit under AMC).</li>
                    <li>Any limitation arising due to non-procurement of spares shall not be attributable to the service provider.</li>
                  </ol>
                </div>
              </Card>
            </motion.div>
          )}

          {/* ── STEP 5: Remarks, Signatures & Attachments ────── */}
          {step === 5 && (
            <motion.div key="step5" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}>
              <div className="space-y-5">
                <Card className="p-6 space-y-5">
                  <SectionTitle icon={PenLine} label="Step 5 — Remarks, Findings & Signatures" color="slate" />

                  <Textarea label="Findings" value={f("findings")} onChange={sf("findings")} rows={3} placeholder="Describe what was found during inspection…" />
                  <Textarea label="Recommendations" value={f("recommendations")} onChange={sf("recommendations")} rows={2} placeholder="Suggested follow-up actions…" />
                  <Textarea label="Remarks (PDF Page 3)" value={f("remarks")} onChange={sf("remarks")} rows={3} placeholder="Additional remarks or observations from the visit…" />
                  <Textarea label="Comments" value={f("comments")} onChange={sf("comments")} rows={2} placeholder="Additional notes or customer requests…" />

                  {/* Signatures */}
                  <div className="border-t border-gray-100 dark:border-gray-700 pt-4">
                    <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Signatures (PDF Page 4)</p>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      <Input label="VDT Representative Name" value={f("vdt_representative_name")} onChange={sf("vdt_representative_name")} placeholder="Suresh Patil" />
                      <Input label="Client Representative Name" value={f("client_representative_name")} onChange={sf("client_representative_name")} placeholder="Rajesh Mehta" />
                    </div>
                  </div>
                </Card>

                {/* Photo Upload */}
                <Card className="p-6">
                  <p className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-1 flex items-center gap-2">
                    <ImageIcon size={14} className="text-blue-500" /> Site Photos
                  </p>
                  <p className="text-xs text-gray-400 mb-3">JPEG, PNG, or WebP</p>
                  <div onClick={() => imgRef.current?.click()}
                    className="border-2 border-dashed border-gray-200 dark:border-gray-600 rounded-xl p-4 text-center cursor-pointer hover:border-blue-400 transition group">
                    <Upload size={20} className="mx-auto text-gray-300 dark:text-gray-500 mb-1 group-hover:text-blue-400 transition" />
                    <p className="text-xs text-gray-400">Click to upload photos</p>
                    <input ref={imgRef} type="file" accept="image/jpeg,image/png,image/webp" multiple className="hidden" onChange={handleImageSelect} />
                  </div>
                  {previewImages.length > 0 && (
                    <div className="flex flex-wrap gap-2 mt-3">
                      {previewImages.map((img, idx) => (
                        <div key={idx} className="relative group">
                          <img src={img.preview} alt="" className="w-16 h-16 object-cover rounded-xl border border-gray-200 dark:border-gray-600" />
                          {img.uploading && <div className="absolute inset-0 rounded-xl bg-black/40 flex items-center justify-center"><Loader2 size={14} className="animate-spin text-white" /></div>}
                          {img.uploaded_url && <div className="absolute inset-0 rounded-xl bg-emerald-500/20 flex items-center justify-center"><CheckCircle size={14} className="text-emerald-500" /></div>}
                          {!img.uploading && !img.uploaded_url && (
                            <button type="button" onClick={() => removeImage(idx)} className="absolute -top-1 -right-1 w-4 h-4 bg-red-500 text-white rounded-full flex items-center justify-center shadow opacity-0 group-hover:opacity-100 transition"><X size={8} /></button>
                          )}
                        </div>
                      ))}
                    </div>
                  )}
                </Card>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Navigation buttons */}
        <div className="flex items-center justify-between mt-6">
          <Button variant="secondary" onClick={prevStep} disabled={step === 1}>
            <ArrowLeft size={14} /> Previous
          </Button>

          {step < 5
            ? <Button onClick={nextStep}>Next <ChevronDown size={14} className="rotate-[-90deg]" /></Button>
            : (
              <Button onClick={handleSubmit} disabled={submitting || uploadingTech}
                className="bg-emerald-600 hover:bg-emerald-700 px-8">
                {submitting
                  ? <><Loader2 size={14} className="animate-spin" /> Submitting…</>
                  : <><CheckCircle size={14} /> Submit Report</>
                }
              </Button>
            )
          }
        </div>

      </div>
      {toast && <Toast {...toast} onClose={() => {}} />}
    </PageTransition>
  );
}

// ── Small helper component ────────────────────────────────────
function SectionTitle({ icon: Icon, label, color = "blue" }) {
  const colors = {
    blue:   "bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400",
    emerald:"bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400",
    orange: "bg-orange-100 dark:bg-orange-900/30 text-orange-600 dark:text-orange-400",
    purple: "bg-purple-100 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400",
    slate:  "bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300",
  };
  return (
    <div className="flex items-center gap-3">
      <div className={`w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0 ${colors[color]}`}>
        <Icon size={15} />
      </div>
      <p className="font-bold text-gray-800 dark:text-white text-sm">{label}</p>
    </div>
  );
}