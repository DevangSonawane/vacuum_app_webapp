import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import { Mail, Save, Send, Loader2, RefreshCw } from "lucide-react";
import axios from "axios";
import { PageTransition, Card, Button, Input, SectionHeader, useToast, Toast } from "../components/ui";

const API_BASE_URL = "https://api.vdtil.com/api";

const NOTIF_LABELS = {
  job_raised:          { label: "New Job Raised",            desc: "When a new job/visit is created" },
  job_assigned:        { label: "Job Assigned to Technician",desc: "When a job is assigned to a technician" },
  job_completed:       { label: "Job Completed / Closed",    desc: "When a job is marked as closed" },
  report_submitted:    { label: "Report Submitted",          desc: "When a technician submits a report" },
  report_approved:     { label: "Report Approved",           desc: "When a report is approved by manager" },
  amc_created:         { label: "AMC Contract Created",      desc: "When a new AMC contract is created" },
  amc_renewal:         { label: "AMC Renewal Reminder",      desc: "Automatic reminder before AMC expiry" },
  amc_service_reminder:{ label: "AMC Service Reminder",      desc: "Reminder before upcoming AMC service date" },
  quotation_sent:      { label: "Quotation Created",         desc: "When a quotation is generated" },
};

export default function EmailSettings() {
  const { toast, showToast } = useToast();

  const [loading, setLoading]   = useState(true);
  const [saving, setSaving]     = useState(false);
  const [testing, setTesting]   = useState(false);
  const [testEmail, setTestEmail] = useState("");

  const [settings, setSettings] = useState({
    smtp_host:     "",
    smtp_port:     587,
    from_email:    "",
    from_name:     "",
    smtp_password: "",
    notifications: {},
  });

  useEffect(() => { fetchSettings(); }, []);

  const fetchSettings = async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem("token");
      const res = await axios.get(`${API_BASE_URL}/email-settings`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.data.success) {
        const d = res.data.data;
        setSettings({
          smtp_host:     d.smtp_host     || "",
          smtp_port:     d.smtp_port     || 587,
          from_email:    d.from_email    || "",
          from_name:     d.from_name     || "",
          smtp_password: "",
          notifications: d.notifications || {},
        });
      }
    } catch {
      showToast("Failed to load email settings", "error");
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const token = localStorage.getItem("token");
      const payload = {
        smtp_host:     settings.smtp_host,
        smtp_port:     Number(settings.smtp_port),
        from_email:    settings.from_email,
        from_name:     settings.from_name,
        notifications: settings.notifications,
      };
      if (settings.smtp_password) payload.smtp_password = settings.smtp_password;

      await axios.put(`${API_BASE_URL}/email-settings`, payload, {
        headers: { Authorization: `Bearer ${token}` },
      });
      showToast("Email settings saved!");
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to save settings", "error");
    } finally {
      setSaving(false);
    }
  };

  const handleTestEmail = async () => {
    if (!testEmail) { showToast("Enter an email address to send a test", "error"); return; }
    setTesting(true);
    try {
      const token = localStorage.getItem("token");
      await axios.post(`${API_BASE_URL}/email-settings/test`, { to: testEmail }, {
        headers: { Authorization: `Bearer ${token}` },
      });
      showToast("Test email sent!");
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to send test email", "error");
    } finally {
      setTesting(false);
    }
  };

  const f = (field) => (e) => setSettings(p => ({ ...p, [field]: e.target.value }));

  const toggleNotif = (key) => setSettings(p => ({
    ...p,
    notifications: { ...p.notifications, [key]: !p.notifications[key] },
  }));

  if (loading) {
    return (
      <PageTransition>
        <div className="p-4 md:p-6 max-w-4xl mx-auto">
          <SectionHeader title="Email Notification Settings" subtitle="Configure SMTP and notification triggers" />
          <div className="space-y-5">
            {[...Array(3)].map((_, i) => (
              <div key={i} className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 p-5 animate-pulse">
                <div className="h-5 w-48 bg-gray-200 dark:bg-gray-700 rounded mb-4" />
                <div className="grid grid-cols-2 gap-4">
                  <div className="h-10 bg-gray-100 dark:bg-gray-800 rounded-xl" />
                  <div className="h-10 bg-gray-100 dark:bg-gray-800 rounded-xl" />
                </div>
              </div>
            ))}
          </div>
        </div>
      </PageTransition>
    );
  }

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-4xl mx-auto">
        <SectionHeader title="Email Notification Settings" subtitle="Configure SMTP and notification triggers" />

        <div className="space-y-5">
          {/* SMTP Config */}
          <Card className="p-5">
            <div className="flex items-center gap-2 mb-4">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Mail size={18} className="text-blue-600 dark:text-blue-400" />
              </div>
              <h3 className="font-bold text-gray-800 dark:text-white">SMTP Configuration</h3>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Input label="SMTP Host" value={settings.smtp_host} onChange={f("smtp_host")} placeholder="smtp.gmail.com" />
              <Input label="SMTP Port" type="number" value={settings.smtp_port} onChange={f("smtp_port")} placeholder="587" />
              <Input label="From Email" type="email" value={settings.from_email} onChange={f("from_email")} placeholder="noreply@company.com" />
              <Input label="From Name" value={settings.from_name} onChange={f("from_name")} placeholder="VDTI Service Hub" />
              <div className="sm:col-span-2">
                <Input label="SMTP Password / App Password" type="password" value={settings.smtp_password} onChange={f("smtp_password")} placeholder="Leave blank to keep current password" />
              </div>
            </div>

            {/* Test email */}
            <div className="mt-4 pt-4 border-t border-gray-100 dark:border-gray-700">
              <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2">Send Test Email</p>
              <div className="flex gap-2">
                <div className="flex-1">
                  <input
                    type="email"
                    value={testEmail}
                    onChange={e => setTestEmail(e.target.value)}
                    placeholder="recipient@example.com"
                    className="w-full px-3 py-2 rounded-xl border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 text-gray-900 dark:text-gray-100 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
                  />
                </div>
                <Button variant="outline" onClick={handleTestEmail} disabled={testing}>
                  {testing ? <><Loader2 size={14} className="animate-spin" /> Sending…</> : <><Send size={14} /> Send Test</>}
                </Button>
              </div>
            </div>
          </Card>

          {/* Notification Triggers */}
          <Card className="p-5">
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-bold text-gray-800 dark:text-white">Notification Triggers</h3>
              <p className="text-xs text-gray-400">Toggle which events send email notifications</p>
            </div>
            <div className="space-y-2">
              {Object.entries(NOTIF_LABELS).map(([key, meta]) => {
                const enabled = !!settings.notifications[key];
                return (
                  <motion.div
                    key={key}
                    className="flex items-center justify-between p-3 rounded-xl bg-gray-50 dark:bg-gray-700/50 hover:bg-gray-100 dark:hover:bg-gray-700 transition"
                  >
                    <div>
                      <p className="font-medium text-gray-800 dark:text-gray-200 text-sm">{meta.label}</p>
                      <p className="text-xs text-gray-400 mt-0.5">{meta.desc}</p>
                    </div>
                    <button
                      onClick={() => toggleNotif(key)}
                      className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors duration-200 focus:outline-none flex-shrink-0 ml-3 ${
                        enabled ? "bg-blue-600" : "bg-gray-300 dark:bg-gray-600"
                      }`}
                    >
                      <motion.span
                        animate={{ x: enabled ? 20 : 2 }}
                        transition={{ type: "spring", stiffness: 500, damping: 30 }}
                        className="inline-block h-4 w-4 rounded-full bg-white shadow-sm"
                      />
                    </button>
                  </motion.div>
                );
              })}
            </div>
          </Card>

          {/* Email Template Preview */}
          <Card className="p-5">
            <h3 className="font-bold text-gray-800 dark:text-white mb-3">Email Template Preview</h3>
            <div className="border border-gray-200 dark:border-gray-600 rounded-xl overflow-hidden">
              <div className="bg-blue-600 px-5 py-4">
                <p className="text-white font-bold text-lg">{settings.from_name || "VDTI Service Hub"} Notification</p>
                <p className="text-blue-200 text-sm">Vacuum Drying Technology India LLP</p>
              </div>
              <div className="p-5 bg-white dark:bg-gray-700">
                <p className="text-gray-700 dark:text-gray-300 text-sm mb-3">Dear <strong>Recipient</strong>,</p>
                <p className="text-gray-700 dark:text-gray-300 text-sm mb-3">
                  A new <strong>Work Order (JOB-XXXX)</strong> has been raised and assigned to you. Please review the details and proceed accordingly.
                </p>
                <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-3 mb-3">
                  <p className="text-xs font-semibold text-blue-600 mb-1">Job Details</p>
                  <p className="text-xs text-gray-600 dark:text-gray-400">Job ID: JOB-XXXX</p>
                  <p className="text-xs text-gray-600 dark:text-gray-400">Client: Client Name</p>
                  <p className="text-xs text-gray-600 dark:text-gray-400">Scheduled: DD-MM-YYYY</p>
                </div>
                <p className="text-gray-500 dark:text-gray-400 text-xs">
                  This is an automated notification from {settings.from_email || "notifications@vdti.com"}.
                </p>
              </div>
            </div>
          </Card>

          <div className="flex justify-end gap-3">
            <Button variant="secondary" onClick={fetchSettings}><RefreshCw size={15} /> Reload</Button>
            <Button onClick={handleSave} size="lg" disabled={saving}>
              {saving ? <><Loader2 size={16} className="animate-spin" /> Saving…</> : <><Save size={16} /> Save Settings</>}
            </Button>
          </div>
        </div>

        {toast && <Toast {...toast} onClose={() => {}} />}
      </div>
    </PageTransition>
  );
}
