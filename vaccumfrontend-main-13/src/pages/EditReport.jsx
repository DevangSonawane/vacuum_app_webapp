// ============================================================
// src/pages/EditReport.jsx
// Route: /reports/:id/edit
// 5-step edit form — mirrors CreateReport flow, pre-populates
// all data from GET /api/reports/:id, submits via PUT.
// ============================================================

import { useState, useEffect, useRef } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import {
  ArrowLeft, Plus, Trash2, ChevronDown, ChevronUp,
  Loader2, FileText, FileCheck, AlertCircle,
  Paperclip, Image as ImageIcon,
  X, CheckCircle, Mail, ClipboardList,
  Wrench, AlertTriangle, Package, PenLine, Camera,
  ExternalLink,
} from "lucide-react";
import axios from "axios";
import { useApp } from "../context/AppContext";
import {
  PageTransition, Card, Button, Input, Select,
  Textarea, useToast, Toast
} from "../components/ui";

const API_BASE_URL = "https://api.vdtil.com/api";

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

const DEFAULT_SPARES = [
  { spare_name: "Complete set of Gaskets",        pump_model: "", total_to_order: "" },
  { spare_name: "Complete set of Valve Gasket",   pump_model: "", total_to_order: "" },
  { spare_name: "Complete set of Valve Spring",   pump_model: "", total_to_order: "" },
  { spare_name: "Complete set of Valve Screw",    pump_model: "", total_to_order: "" },
  { spare_name: "Complete set of Oil Connectors", pump_model: "", total_to_order: "" },
  { spare_name: "Ferrule / Insert / Reducer set", pump_model: "", total_to_order: "" },
  { spare_name: "Nylon Tubing Set",               pump_model: "", total_to_order: "" },
];

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

const ISSUE_TYPES = ["Low Vaccum", "Abnormal Sound", "Excessive Oil", "No Lubrication"];

const STEPS = [
  { id: 1, label: "Client Info",    icon: ClipboardList },
  { id: 2, label: "Checklist",      icon: CheckCircle   },
  { id: 3, label: "Issues",         icon: AlertTriangle },
  { id: 4, label: "Spares",         icon: Package       },
  { id: 5, label: "Remarks",        icon: PenLine       },
];

export default function EditReport() {
  const { id }   = useParams();
  const navigate = useNavigate();
  const { toast, showToast } = useToast();
  const { currentUser } = useApp();
  const isTechnician = currentUser?.role?.toLowerCase() === "technician";

  const [loadingReport, setLoadingReport] = useState(true);
  const [step, setStep]                   = useState(1);
  const [jobs, setJobs]                   = useState([]);
  const [technicians, setTechnicians]     = useState([]);
  const [clients, setClients]             = useState([]);
  const [amcContracts, setAmcContracts]   = useState([]);
  const [expandedIssueTypes, setExpandedIssueTypes] = useState(ISSUE_TYPES);
  const [submitting, setSubmitting]       = useState(false);

  const [form, setForm] = useState({
    job_id: "", title: "", technician_id: "", report_date: "",
    po_number: "", serial_no: "",
    client_id: "", client_name: "", client_email: "",
    company_name: "", contact_person: "", location: "",
    model_serial_installation: "",
    operating_hours_per_day: "",
    application_process_description: "",
    findings: "", recommendations: "", comments: "",
    remarks: "",
    vdt_representative_name: "", client_representative_name: "",
  });

  const [checklist, setChecklist]             = useState(DEFAULT_CHECKLIST);
  const [issues, setIssues]                   = useState([]);
  const [spares, setSpares]                   = useState(DEFAULT_SPARES);
  const [techFiles, setTechFiles]             = useState([]);
  const [uploadingTech, setUploadingTech]     = useState(false);
  const [previewImages, setPreviewImages]     = useState([]);
  const [existingImages, setExistingImages]   = useState([]);
  const [attachPickerOpen, setAttachPickerOpen] = useState(false);

  const techRef        = useRef();
  const imgRef         = useRef();
  const cameraRef      = useRef();
  const attachPickerRef = useRef();

  // ── Fetch report + lookup data on mount ──────────────────
  useEffect(() => {
    fetchLookups();
    fetchReport();
  }, [id]);

  useEffect(() => {
    const handler = (e) => {
      if (attachPickerRef.current && !attachPickerRef.current.contains(e.target)) {
        setAttachPickerOpen(false);
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const fetchLookups = async () => {
    const token = localStorage.getItem("token");
    const headers = { Authorization: `Bearer ${token}` };
    try {
      const [jobsRes, techRes, clientsRes, amcRes] = await Promise.all([
        axios.get(`${API_BASE_URL}/jobs`,        { headers, params: { limit: 200 } }),
        axios.get(`${API_BASE_URL}/technicians`, { headers, params: { limit: 100 } }),
        axios.get(`${API_BASE_URL}/clients`,     { headers, params: { limit: 100 } }),
        axios.get(`${API_BASE_URL}/amc`,         { headers, params: { limit: 200 } }),
      ]);
      if (jobsRes.data.success)    setJobs(jobsRes.data.data || []);
      if (techRes.data.success)    setTechnicians(techRes.data.data || []);
      if (clientsRes.data.success) setClients(clientsRes.data.data || []);
      if (amcRes.data.success)     setAmcContracts(amcRes.data.data || []);
    } catch {}
  };

  const fetchReport = async () => {
    setLoadingReport(true);
    try {
      const token = localStorage.getItem("token");
      const res = await axios.get(`${API_BASE_URL}/reports/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.data.success) throw new Error("Not found");
      const r = res.data.data;

      setForm({
        job_id:          r.job_id         ? String(r.job_id)         : "",
        title:           r.title          || "",
        technician_id:   r.technicians?.[0]?.id ? String(r.technicians[0].id) : (r.technician_id ? String(r.technician_id) : ""),
        report_date:     r.report_date    ? r.report_date.slice(0, 10) : "",
        po_number:       r.po_number      || "",
        serial_no:       r.serial_no      || "",
        client_id:       r.client_id      ? String(r.client_id) : "",
        client_name:     r.client_name    || "",
        client_email:    r.client_email   || "",
        company_name:    r.company_name   || "",
        contact_person:  r.contact_person || "",
        location:        r.location       || "",
        model_serial_installation:        r.model_serial_installation        || "",
        operating_hours_per_day:          r.operating_hours_per_day          || "",
        application_process_description:  r.application_process_description  || "",
        findings:        r.findings       || "",
        recommendations: r.recommendations || "",
        comments:        r.comments       || "",
        remarks:         r.remarks        || "",
        vdt_representative_name:    r.vdt_representative_name    || "",
        client_representative_name: r.client_representative_name || "",
      });

      // Pre-populate checklist — match by sr number
      setChecklist(DEFAULT_CHECKLIST.map(item => {
        const existing = r.checklist_items?.find(ci => ci.sr === item.sr);
        return existing ? { ...item, status: existing.status || "" } : item;
      }));

      // Pre-populate issues (enables highlight matching)
      if (r.issue_observations?.length > 0) {
        setIssues(r.issue_observations.map((obs, idx) => ({ ...obs, sr: obs.sr ?? idx + 1 })));
      }

      // Pre-populate spares from report data
      if (r.mandatory_spares?.length > 0) {
        setSpares(r.mandatory_spares.map(s => ({
          spare_name: s.spare_name || "", pump_model: s.pump_model || "", total_to_order: s.total_to_order || ""
        })));
      }

      // Pre-populate existing attachments — separate images vs docs
      const allFiles = r.technical_reports || [];
      const imgFiles = allFiles.filter(f => f.mime_type?.startsWith("image/"));
      const docFiles = allFiles.filter(f => !f.mime_type?.startsWith("image/"));

      setExistingImages(imgFiles);
      if (docFiles.length > 0) {
        setTechFiles(docFiles.map(doc => ({
          file: null, name: doc.file_name, file_name: doc.file_name, file_url: doc.file_url,
          mime_type: doc.mime_type, file_size_bytes: doc.file_size_bytes,
          uploading: false, uploaded: true, existing: true,
        })));
      }
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to load report", "error");
      navigate("/reports");
    } finally {
      setLoadingReport(false);
    }
  };

  // ── Checklist helpers ─────────────────────────────────────
  const setChecklistStatus = (idx, status) => {
    setChecklist(p => p.map((item, i) => i === idx ? { ...item, status } : item));
  };

  // ── Issue helpers ─────────────────────────────────────────
  const toggleIssueRow = (issueType, rowData) => {
    const isSelected = issues.some(i => i.issue === issueType && i.observation === rowData.observation);
    if (isSelected) {
      setIssues(p => p.filter(i => !(i.issue === issueType && i.observation === rowData.observation)));
    } else {
      setIssues(p => {
        const newIssues = [...p.filter(i => i.issue || i.observation), { ...rowData, issue: issueType, sr: p.length + 1 }];
        return newIssues;
      });
    }
  };

  // ── Spare helpers ─────────────────────────────────────────
  const addSpare = () => setSpares(p => [...p, { spare_name: "", pump_model: "", total_to_order: "" }]);
  const removeSpare = (idx) => setSpares(p => p.filter((_, i) => i !== idx));
  const setSpareField = (idx, field, val) => {
    setSpares(p => p.map((item, i) => i === idx ? { ...item, [field]: val } : item));
  };

  // ── Tech file upload ──────────────────────────────────────
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
      const res = await axios.post(`${API_BASE_URL}/upload/report-files`, fd, {
        headers: { Authorization: `Bearer ${token}` }
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
      showToast("Failed to upload document", "error");
    } finally {
      setUploadingTech(false);
    }
  };

  const removeTechFile = (idx) => setTechFiles(p => p.filter((_, i) => i !== idx));

  // ── Image helpers ─────────────────────────────────────────
  const handleImageSelect = async (e) => {
    const files = Array.from(e.target.files);
    if (!files.length) return;
    e.target.value = "";
    const newEntries = files.map(file => ({
      file, preview: URL.createObjectURL(file),
      uploading: true, uploaded: false,
      file_name: null, file_url: null,
      mime_type: file.type, file_size_bytes: file.size, error: null,
    }));
    setPreviewImages(p => [...p, ...newEntries]);
    const token = localStorage.getItem("token");
    const fd = new FormData();
    files.forEach(f => fd.append("files", f));
    try {
      const res = await axios.post(`${API_BASE_URL}/upload/report-files`, fd, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const uploaded = res.data.data || [];
      setPreviewImages(prev => {
        const startIdx = prev.length - files.length;
        return prev.map((entry, i) => {
          if (i < startIdx) return entry;
          const up = uploaded[i - startIdx];
          if (up) return { ...entry, uploading: false, uploaded: true, file_name: up.file_name, file_url: up.file_url, mime_type: up.mime_type, file_size_bytes: up.file_size_bytes };
          return { ...entry, uploading: false, error: "Failed" };
        });
      });
    } catch {
      setPreviewImages(prev => prev.map((e, i) => i >= prev.length - files.length ? { ...e, uploading: false, error: "Upload failed" } : e));
      showToast("Failed to upload photos", "error");
    }
  };
  const removeImage = (idx) => setPreviewImages(p => p.filter((_, i) => i !== idx));

  // ── Validation ────────────────────────────────────────────
  const validateStep = () => {
    if (step === 1) {
      if (!form.title.trim())        return showToast("Please enter a report title.", "error"),       false;
      if (!form.company_name.trim()) return showToast("Please enter the company name.", "error"),     false;
    }
    return true;
  };

  const nextStep = () => { if (validateStep()) { setStep(s => Math.min(s + 1, 5)); window.scrollTo({ top: 0, behavior: "smooth" }); } };
  const prevStep = () => { setStep(s => Math.max(s - 1, 1)); window.scrollTo({ top: 0, behavior: "smooth" }); };

  // ── Submit (PUT) ──────────────────────────────────────────
  const handleSubmit = async () => {
    if (uploadingTech || previewImages.some(f => f.uploading)) return showToast("Please wait for files to finish uploading.", "error");
    const failedUploads = [...techFiles, ...previewImages].filter(f => f.error);
    if (failedUploads.length) return showToast("Some files failed to upload. Remove them and retry.", "error");

    setSubmitting(true);
    const token = localStorage.getItem("token");

    try {
      // Build unified technical_reports: existing images + existing docs + new docs + new images
      const technical_reports = [
        ...existingImages.map(f => ({
          file_name: f.file_name, file_url: f.file_url,
          mime_type: f.mime_type, file_size_bytes: f.file_size_bytes || null,
        })),
        ...techFiles.filter(f => f.uploaded && f.file_url).map(f => ({
          file_name: f.file_name || f.name, file_url: f.file_url,
          mime_type: f.mime_type || "application/octet-stream", file_size_bytes: f.file_size_bytes || null,
        })),
        ...previewImages.filter(f => f.uploaded && f.file_url).map(f => ({
          file_name: f.file_name || f.file?.name || "photo.jpg", file_url: f.file_url,
          mime_type: f.mime_type || "image/jpeg", file_size_bytes: f.file_size_bytes || null,
        })),
      ];

      const payload = {
        title:           form.title.trim()      || undefined,
        technician_id:   form.technician_id     ? parseInt(form.technician_id) : undefined,
        job_id:          form.job_id            || undefined,
        report_date:     form.report_date       || undefined,
        po_number:       form.po_number         || undefined,
        serial_no:       form.serial_no         || undefined,
        client_id:       form.client_id         ? parseInt(form.client_id) : undefined,
        client_name:     form.client_name       || undefined,
        client_email:    form.client_email      || undefined,
        company_name:    form.company_name      || undefined,
        contact_person:  form.contact_person    || undefined,
        location:        form.location          || undefined,
        model_serial_installation:        form.model_serial_installation        || undefined,
        operating_hours_per_day:          form.operating_hours_per_day          || undefined,
        application_process_description:  form.application_process_description  || undefined,
        findings:        form.findings          || undefined,
        recommendations: form.recommendations   || undefined,
        comments:        form.comments          || undefined,
        remarks:         form.remarks           || undefined,
        vdt_representative_name:    form.vdt_representative_name    || undefined,
        client_representative_name: form.client_representative_name || undefined,
        checklist_items:    checklist.filter(c => c.status),
        issue_observations: issues.filter(i => i.issue || i.observation),
        mandatory_spares:   spares.filter(s => s.spare_name),
        technical_reports,
      };

      await axios.put(`${API_BASE_URL}/reports/${id}`, payload, {
        headers: { Authorization: `Bearer ${token}` }
      });

      showToast("Report updated successfully!", "success");
      navigate(`/reports/${id}`);
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to update report", "error");
    } finally {
      setSubmitting(false);
    }
  };

  const f  = (field) => form[field];
  const sf = (field) => (e) => setForm(p => ({ ...p, [field]: e.target.value }));

  // ── Loading skeleton ──────────────────────────────────────
  if (loadingReport) {
    return (
      <PageTransition>
        <div className="p-4 md:p-8 max-w-7xl mx-auto space-y-6">
          <div className="flex items-start gap-4">
            <div className="w-10 h-10 rounded-xl bg-gray-200 dark:bg-gray-700 animate-pulse" />
            <div className="space-y-2">
              <div className="h-5 w-40 bg-gray-200 dark:bg-gray-700 rounded animate-pulse" />
              <div className="h-3 w-56 bg-gray-100 dark:bg-gray-800 rounded animate-pulse" />
            </div>
          </div>
          <div className="h-12 bg-gray-100 dark:bg-gray-800 rounded-2xl animate-pulse" />
          <div className="h-64 bg-gray-100 dark:bg-gray-800 rounded-2xl animate-pulse" />
        </div>
      </PageTransition>
    );
  }

  return (
    <PageTransition>
      <div className="p-4 md:p-8 max-w-7xl mx-auto space-y-6">

        {/* Header */}
        <div className="flex items-start gap-4 mb-6">
          <button onClick={() => navigate(`/reports/${id}`)}
            className="mt-1 p-2 rounded-xl text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-800 transition flex-shrink-0">
            <ArrowLeft size={20} />
          </button>
          <div className="flex-1 min-w-0">
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white leading-tight">Edit Report</h1>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1 font-mono">{id}</p>
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

        {/* Mobile-only top navigation */}
        <div className="flex items-center justify-between sm:hidden mb-4">
          <Button variant="secondary" onClick={prevStep} disabled={step === 1}>
            <ArrowLeft size={14} /> Previous
          </Button>
          {step < 5
            ? <Button onClick={nextStep}>Next <ChevronDown size={14} className="rotate-[-90deg]" /></Button>
            : (
              <Button onClick={handleSubmit} disabled={submitting || uploadingTech || previewImages.some(f => f.uploading)}
                className="bg-emerald-600 hover:bg-emerald-700 px-6">
                {submitting
                  ? <><Loader2 size={14} className="animate-spin" /> Saving…</>
                  : <><CheckCircle size={14} /> Save</>
                }
              </Button>
            )
          }
        </div>

        <AnimatePresence mode="wait">

          {/* ── STEP 1: Client Info ───────────────────────────── */}
          {step === 1 && (
            <motion.div key="step1" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}>
              <Card className="p-6 space-y-5">
                <SectionTitle icon={ClipboardList} label="Step 1 — Client & Report Info" color="blue" />

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {(() => {
                    const visibleJobs = isTechnician && currentUser?.id
                      ? jobs.filter(j => j.technicians?.some(t => String(t.id) === String(currentUser.id)))
                      : jobs;
                    return (
                      <Select label="Linked Job" value={f("job_id")}
                        onChange={e => {
                          const jobId = e.target.value;
                          const selectedJob = jobs.find(j => String(j.id) === jobId);
                          const autoTechId = isTechnician && currentUser?.id
                            ? String(currentUser.id)
                            : (selectedJob?.technicians?.[0]?.id ? String(selectedJob.technicians[0].id) : undefined);
                          setForm(p => ({
                            ...p,
                            job_id: jobId,
                            technician_id: autoTechId ?? p.technician_id,
                          }));
                        }}
                        options={[{ value: "", label: "Select job..." }, ...visibleJobs.map(j => ({ value: j.id, label: `${j.id} — ${j.title}` }))]}
                      />
                    );
                  })()}
                  {(() => {
                    if (isTechnician) {
                      return (
                        <div className="space-y-1">
                          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">Technician</label>
                          <div className="w-full px-3 py-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-gray-100 text-sm font-semibold">
                            {currentUser?.name || "You"}
                          </div>
                        </div>
                      );
                    }
                    const selectedJob = jobs.find(j => String(j.id) === form.job_id);
                    const jobTechs = selectedJob?.technicians;
                    const techOptions = jobTechs?.length > 0
                      ? jobTechs.map(t => ({ value: t.id, label: t.name }))
                      : technicians.map(t => ({ value: t.id, label: t.name }));
                    return (
                      <Select label="Technician" value={f("technician_id")} onChange={sf("technician_id")}
                        options={[{ value: "", label: "Select technician..." }, ...techOptions]}
                      />
                    );
                  })()}
                </div>

                <Input label="Report Title *" value={f("title")} onChange={sf("title")} required placeholder="Quarterly AMC Service — Italvacuum Pump" />

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <Input label="Report Date" type="date" value={f("report_date")} onChange={sf("report_date")} />
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
                </div>

                <Input label="Serial No." value={f("serial_no")} onChange={sf("serial_no")} placeholder="VCP-2023-7842" />

                <div className="border-t border-gray-100 dark:border-gray-700 pt-4">
                  <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-4">Client Info</p>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <Select label="Client" value={f("client_id")}
                      onChange={e => {
                        const clientId = e.target.value;
                        const client = clients.find(cl => String(cl.id) === String(clientId));
                        setForm(p => ({
                          ...p,
                          client_id: clientId,
                          client_name: client?.name || p.client_name,
                          client_email: client?.email || p.client_email,
                          company_name: client?.name || p.company_name,
                          contact_person: client?.contact_person || p.contact_person,
                          location: client?.address || p.location,
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
                  <div className="mt-4">
                    <Input label="Location / Address" value={f("location")} onChange={sf("location")} placeholder="Plot No. 123, GIDC Sachin, Surat" />
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

          {/* ── STEP 2: Checklist ─────────────────────────────── */}
          {step === 2 && (
            <motion.div key="step2" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}>
              <Card className="p-6">
                <SectionTitle icon={CheckCircle} label="Step 2 — Routine Preventive Maintenance Checklist" color="emerald" />
                <p className="text-xs text-gray-400 mb-5 mt-1">Previously selected statuses are highlighted. Click to change.</p>

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
                              <button key={o} type="button" onClick={() => setChecklistStatus(idx, o)}
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

          {/* ── STEP 3: Issue Observations ────────────────────── */}
          {step === 3 && (
            <motion.div key="step3" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}>
              <Card className="p-6">
                <SectionTitle icon={AlertTriangle} label="Step 3 — Detailed Issue - Observation - Impact Matrix" color="orange" />
                <p className="text-xs text-gray-400 mb-6 mt-1">Previously selected rows are highlighted. Click to toggle.</p>

                <div className="space-y-8">
                  {ISSUE_TYPES.map((issueType, typeIdx) => {
                    const rows = ISSUE_DATA[issueType] || [];
                    const isExpanded = expandedIssueTypes.includes(issueType);
                    return (
                      <div key={issueType} className="border border-gray-200 dark:border-gray-700 rounded-2xl overflow-hidden shadow-sm">
                        <div
                          onClick={() => setExpandedIssueTypes(p => p.includes(issueType) ? p.filter(t => t !== issueType) : [...p, issueType])}
                          className="flex items-center justify-between px-5 py-4 bg-gray-50 dark:bg-gray-800 cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                        >
                          <div className="flex items-center gap-3">
                            <span className="w-8 h-8 rounded-xl bg-orange-100 dark:bg-orange-900/30 text-orange-600 dark:text-orange-400 flex items-center justify-center font-bold text-sm">
                              {typeIdx + 1}
                            </span>
                            <h3 className="font-bold text-gray-900 dark:text-white uppercase tracking-wider">{issueType}</h3>
                            <span className="text-[10px] bg-gray-200 dark:bg-gray-700 text-gray-500 px-2 py-0.5 rounded-full font-bold">
                              {rows.length} OPTIONS
                            </span>
                          </div>
                          {isExpanded ? <ChevronUp size={18} className="text-gray-400" /> : <ChevronDown size={18} className="text-gray-400" />}
                        </div>

                        {isExpanded && (
                          <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse">
                              <thead>
                                <tr className="bg-gray-50 dark:bg-gray-900/50 border-b border-gray-100 dark:border-gray-800">
                                  <th className="p-4 text-[10px] font-bold text-gray-400 uppercase tracking-widest text-center w-12">SR</th>
                                  <th className="p-4 text-[10px] font-bold text-gray-400 uppercase tracking-widest">Observation</th>
                                  <th className="p-4 text-[10px] font-bold text-gray-400 uppercase tracking-widest">Impact on Pump</th>
                                  <th className="p-4 text-[10px] font-bold text-gray-400 uppercase tracking-widest text-center w-24">Severity</th>
                                  <th className="p-4 text-[10px] font-bold text-gray-400 uppercase tracking-widest">Recommended Spares</th>
                                </tr>
                              </thead>
                              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                                {rows.map((row, rowIdx) => {
                                  const isSelected = issues.some(i => i.issue === issueType && i.observation === row.observation);
                                  return (
                                    <tr key={rowIdx} onClick={() => toggleIssueRow(issueType, row)}
                                      className={`group cursor-pointer transition-all hover:bg-orange-50/30 dark:hover:bg-orange-900/10
                                        ${isSelected ? "bg-orange-50/50 dark:bg-orange-900/20" : ""}`}
                                    >
                                      <td className="p-4 text-center">
                                        <div className={`w-6 h-6 mx-auto rounded-lg flex items-center justify-center text-[10px] font-bold transition-all
                                          ${isSelected
                                            ? "bg-orange-600 text-white shadow-lg shadow-orange-500/30"
                                            : "bg-gray-100 dark:bg-gray-700 text-gray-400 group-hover:bg-orange-200 group-hover:text-orange-700"}`}
                                        >
                                          {rowIdx + 1}
                                        </div>
                                      </td>
                                      <td className={`p-4 text-sm transition-colors ${isSelected ? "font-bold text-gray-900 dark:text-white" : "text-gray-600 dark:text-gray-400"}`}>
                                        {row.observation}
                                      </td>
                                      <td className={`p-4 text-sm transition-colors ${isSelected ? "text-gray-800 dark:text-gray-200" : "text-gray-500 dark:text-gray-500"}`}>
                                        {row.impact_on_pump}
                                      </td>
                                      <td className="p-4 text-center">
                                        <span className={`inline-block px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest transition-all
                                          ${isSelected
                                            ? row.severity === "High" ? "bg-red-500 text-white shadow-sm" :
                                              row.severity === "Med"  ? "bg-amber-500 text-white shadow-sm" :
                                                                        "bg-emerald-500 text-white shadow-sm"
                                            : "bg-gray-100 dark:bg-gray-700 text-gray-400"}`}
                                        >
                                          {row.severity}
                                        </span>
                                      </td>
                                      <td className={`p-4 text-sm transition-colors ${isSelected ? "text-blue-600 dark:text-blue-400 font-semibold" : "text-gray-500 dark:text-gray-500"}`}>
                                        {row.recommended_spares}
                                      </td>
                                    </tr>
                                  );
                                })}
                              </tbody>
                            </table>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>

                <div className="mt-8 flex items-center gap-3 p-4 bg-blue-50 dark:bg-blue-900/10 border border-blue-100 dark:border-blue-800 rounded-2xl">
                  <div className="w-10 h-10 rounded-xl bg-blue-600 flex items-center justify-center flex-shrink-0 text-white">
                    <CheckCircle size={20} />
                  </div>
                  <div>
                    <p className="text-sm font-bold text-blue-900 dark:text-blue-200">{issues.length} Issues Selected</p>
                    <p className="text-xs text-blue-700 dark:text-blue-400">Selected observations will be mapped into the PDF matrix.</p>
                  </div>
                </div>
              </Card>
            </motion.div>
          )}

          {/* ── STEP 4: Mandatory Spares ──────────────────────── */}
          {step === 4 && (
            <motion.div key="step4" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}>
              <Card className="p-6">
                <div className="flex items-center justify-between mb-5">
                  <SectionTitle icon={Package} label="Step 4 — Mandatory Spares (AMC Compliance Matrix)" color="purple" />
                  <Button variant="secondary" size="sm" onClick={addSpare}>
                    <Plus size={13} /> Add Spare
                  </Button>
                </div>
                <p className="text-xs text-gray-400 mb-5 -mt-3">Specify pump model and quantity for each spare.</p>

                <div className="space-y-3">
                  <div className="grid grid-cols-12 gap-2 px-2">
                    <p className="col-span-5 text-xs font-bold text-gray-400 uppercase tracking-wide">Spare Name</p>
                    <p className="col-span-3 text-xs font-bold text-gray-400 uppercase tracking-wide">Pump Model</p>
                    <p className="col-span-3 text-xs font-bold text-gray-400 uppercase tracking-wide">Qty to Order</p>
                    <div className="col-span-1" />
                  </div>

                  {spares.map((spare, idx) => (
                    <div key={idx} className="grid grid-cols-12 gap-2 items-center p-2 bg-gray-50 dark:bg-gray-700/50 rounded-xl">
                      <input value={spare.spare_name} onChange={e => setSpareField(idx, "spare_name", e.target.value)} placeholder="Spare name"
                        className="col-span-5 text-sm px-3 py-1.5 rounded-xl border border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500" />
                      <input value={spare.pump_model} onChange={e => setSpareField(idx, "pump_model", e.target.value)} placeholder="Model"
                        className="col-span-3 text-sm px-3 py-1.5 rounded-xl border border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500" />
                      <input value={spare.total_to_order} onChange={e => setSpareField(idx, "total_to_order", e.target.value)} placeholder="Qty"
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
                    <li>If mandatory spares are not available, the visit may be restricted to inspection only.</li>
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
                  <Textarea label="Remarks" value={f("remarks")} onChange={sf("remarks")} rows={3} placeholder="Additional remarks or observations from the visit…" />
                  <Textarea label="Comments" value={f("comments")} onChange={sf("comments")} rows={2} placeholder="Additional notes or customer requests…" />

                  <div className="border-t border-gray-100 dark:border-gray-700 pt-4">
                    <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Signatures</p>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      <Input label="VDT Representative Name" value={f("vdt_representative_name")} onChange={sf("vdt_representative_name")} placeholder="Suresh Patil" />
                      <Input label="Client Representative Name" value={f("client_representative_name")} onChange={sf("client_representative_name")} placeholder="Rajesh Mehta" />
                    </div>
                  </div>
                </Card>

                {/* Existing images (read-only grid) */}
                {existingImages.length > 0 && (
                  <Card className="p-6">
                    <p className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3 flex items-center gap-2">
                      <ImageIcon size={14} className="text-gray-500" /> Existing Photos ({existingImages.length})
                    </p>
                    <div className="grid grid-cols-3 gap-3">
                      {existingImages.map((img, idx) => (
                        <div key={idx} className="relative group">
                          <a href={img.file_url} target="_blank" rel="noopener noreferrer"
                            className="aspect-square rounded-xl overflow-hidden bg-gray-100 dark:bg-gray-700 block hover:opacity-90 transition">
                            <img src={img.file_url} alt={img.file_name} className="w-full h-full object-cover" />
                          </a>
                          <button type="button"
                            onClick={() => setExistingImages(p => p.filter((_, i) => i !== idx))}
                            className="absolute -top-1.5 -right-1.5 w-5 h-5 bg-red-500 text-white rounded-full flex items-center justify-center shadow opacity-0 group-hover:opacity-100 transition">
                            <X size={10} />
                          </button>
                        </div>
                      ))}
                    </div>
                    <p className="text-xs text-gray-400 mt-2">Click × to remove an existing photo from this report.</p>
                  </Card>
                )}

                {/* Attachments — Documents + Photos unified */}
                <Card className="p-6">
                  <p className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-1 flex items-center gap-2">
                    <Paperclip size={14} className="text-gray-500" /> Add New Attachments
                  </p>
                  <p className="text-xs text-gray-400 mb-3">Documents, reports, or photos</p>

                  <div className="relative" ref={attachPickerRef}>
                    <div onClick={() => setAttachPickerOpen(p => !p)}
                      className="border-2 border-dashed border-gray-200 dark:border-gray-600 rounded-xl p-4 text-center cursor-pointer hover:border-blue-400 dark:hover:border-blue-500 hover:bg-blue-50/40 dark:hover:bg-blue-900/10 transition group">
                      <div className="w-9 h-9 rounded-xl bg-gray-100 dark:bg-gray-700 flex items-center justify-center mx-auto mb-2 group-hover:bg-blue-100 dark:group-hover:bg-blue-900/30 transition">
                        <Plus size={18} className="text-gray-400 group-hover:text-blue-500 transition" />
                      </div>
                      <p className="text-xs text-gray-400 group-hover:text-blue-500 transition font-medium">Add attachment</p>
                    </div>

                    {attachPickerOpen && (
                      <div className="absolute top-full left-0 right-0 mt-2 bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 shadow-xl z-30 overflow-hidden">
                        <button type="button"
                          onClick={() => { techRef.current?.click(); setAttachPickerOpen(false); }}
                          className="w-full flex items-center gap-3 px-4 py-3.5 hover:bg-gray-50 dark:hover:bg-gray-700/60 transition text-left">
                          <div className="w-9 h-9 rounded-xl bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center flex-shrink-0">
                            <FileText size={15} className="text-blue-600 dark:text-blue-400" />
                          </div>
                          <div>
                            <p className="text-sm font-semibold text-gray-800 dark:text-gray-100">Upload Document</p>
                            <p className="text-xs text-gray-400">PDF, DOCX, XLSX…</p>
                          </div>
                        </button>
                        <div className="border-t border-gray-100 dark:border-gray-700" />
                        <button type="button"
                          onClick={() => { imgRef.current?.click(); setAttachPickerOpen(false); }}
                          className="w-full flex items-center gap-3 px-4 py-3.5 hover:bg-gray-50 dark:hover:bg-gray-700/60 transition text-left">
                          <div className="w-9 h-9 rounded-xl bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center flex-shrink-0">
                            <ImageIcon size={15} className="text-purple-600 dark:text-purple-400" />
                          </div>
                          <div>
                            <p className="text-sm font-semibold text-gray-800 dark:text-gray-100">Upload Photo</p>
                            <p className="text-xs text-gray-400">From gallery</p>
                          </div>
                        </button>
                        <div className="border-t border-gray-100 dark:border-gray-700" />
                        <button type="button"
                          onClick={() => { cameraRef.current?.click(); setAttachPickerOpen(false); }}
                          className="w-full flex items-center gap-3 px-4 py-3.5 hover:bg-gray-50 dark:hover:bg-gray-700/60 transition text-left">
                          <div className="w-9 h-9 rounded-xl bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center flex-shrink-0">
                            <Camera size={15} className="text-amber-600 dark:text-amber-400" />
                          </div>
                          <div>
                            <p className="text-sm font-semibold text-gray-800 dark:text-gray-100">Take Photo</p>
                            <p className="text-xs text-gray-400">Opens camera</p>
                          </div>
                        </button>
                      </div>
                    )}
                  </div>

                  <input ref={techRef} type="file" multiple className="hidden" onChange={handleTechFileSelect} />
                  <input ref={imgRef} type="file" accept="image/*" multiple className="hidden" onChange={handleImageSelect} />
                  <input ref={cameraRef} type="file" accept="image/*" capture="environment" className="hidden" onChange={handleImageSelect} />

                  {/* Document list */}
                  {techFiles.length > 0 && (
                    <div className="space-y-2 mt-3">
                      {techFiles.map((file, idx) => (
                        <div key={idx} className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700/50 rounded-xl border border-gray-200 dark:border-gray-600">
                          <div className="flex items-center gap-3 min-w-0">
                            <div className="w-8 h-8 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center flex-shrink-0">
                              {file.uploading ? <Loader2 size={14} className="animate-spin text-blue-600" /> :
                               file.uploaded  ? <FileCheck size={14} className="text-emerald-600" /> :
                               file.error     ? <AlertCircle size={14} className="text-red-500" /> :
                                                <FileText size={14} className="text-blue-600" />}
                            </div>
                            <div className="min-w-0">
                              <p className="text-sm font-medium text-gray-900 dark:text-gray-100 truncate">{file.name || file.file_name}</p>
                              <p className="text-xs text-gray-400">
                                {file.existing ? "Existing" : file.uploading ? "Uploading..." : file.uploaded ? "Uploaded" : file.error || "Ready"}
                              </p>
                            </div>
                          </div>
                          <div className="flex items-center gap-2 flex-shrink-0 ml-2">
                            {file.existing && file.file_url && (
                              <a href={file.file_url} target="_blank" rel="noopener noreferrer" className="text-blue-400 hover:text-blue-600 transition">
                                <ExternalLink size={13} />
                              </a>
                            )}
                            {!file.uploading && (
                              <button type="button" onClick={() => removeTechFile(idx)} className="text-red-400 hover:text-red-600 transition">
                                <Trash2 size={14} />
                              </button>
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}

                  {/* New photo grid */}
                  {previewImages.length > 0 && (
                    <div className="grid grid-cols-3 gap-3 mt-3">
                      {previewImages.map((img, idx) => (
                        <div key={idx} className="relative group">
                          <div className="aspect-square rounded-xl overflow-hidden bg-gray-100 dark:bg-gray-700">
                            <img src={img.preview} alt="" className="w-full h-full object-cover" />
                          </div>
                          {img.uploading && (
                            <div className="absolute inset-0 rounded-xl bg-black/50 flex items-center justify-center">
                              <Loader2 size={20} className="animate-spin text-white" />
                            </div>
                          )}
                          {img.uploaded && img.file_url && !img.uploading && (
                            <div className="absolute bottom-1.5 right-1.5 w-5 h-5 bg-emerald-500 rounded-full flex items-center justify-center shadow">
                              <CheckCircle size={12} className="text-white" />
                            </div>
                          )}
                          {img.error && (
                            <div className="absolute inset-0 rounded-xl bg-red-500/20 flex items-center justify-center">
                              <AlertCircle size={16} className="text-red-500" />
                            </div>
                          )}
                          {!img.uploading && (
                            <button type="button" onClick={() => removeImage(idx)}
                              className="absolute -top-1.5 -right-1.5 w-5 h-5 bg-red-500 text-white rounded-full flex items-center justify-center shadow opacity-0 group-hover:opacity-100 transition">
                              <X size={10} />
                            </button>
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
              <Button onClick={handleSubmit} disabled={submitting || uploadingTech || previewImages.some(f => f.uploading)}
                className="bg-emerald-600 hover:bg-emerald-700 px-8">
                {submitting
                  ? <><Loader2 size={14} className="animate-spin" /> Saving…</>
                  : <><CheckCircle size={14} /> Save Changes</>
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
