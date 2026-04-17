import { useState } from "react";
import { motion } from "framer-motion";
import { Mail, Save, Send } from "lucide-react";
import { useApp } from "../context/AppContext";
import { PageTransition, Card, Button, Input, SectionHeader, useToast, Toast } from "../components/ui";

export default function EmailSettings() {
  const { emailSettings, setEmailSettings } = useApp();
  const { toast, showToast } = useToast();
  const [settings, setSettings] = useState({ ...emailSettings });

  const f = field => e => setSettings(p => ({ ...p, [field]: e.target.value }));
  const toggleNotif = key => setSettings(p => ({ ...p, notifications: { ...p.notifications, [key]: !p.notifications[key] } }));

  const handleSave = () => {
    setEmailSettings(settings);
    showToast("Email settings saved!");
  };

  const NOTIF_LABELS = {
    jobRaised: "New Job Raised",
    jobAssigned: "Job Assigned to Technician",
    jobCompleted: "Job Completed / Closed",
    reportApproved: "Report Approved",
    amcRenewal: "AMC Renewal Reminder",
    quotationSent: "Quotation Created",
  };

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-3xl mx-auto">
        <SectionHeader title="Email Notification Settings" subtitle="Configure SMTP and notification triggers" />

        <div className="space-y-5">
          {/* SMTP Config */}
          <Card className="p-5">
            <div className="flex items-center gap-2 mb-4">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg"><Mail size={18} className="text-blue-600 dark:text-blue-400" /></div>
              <h3 className="font-bold text-gray-800 dark:text-white font-display">SMTP Configuration</h3>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Input label="SMTP Host" value={settings.smtpHost} onChange={f("smtpHost")} placeholder="smtp.gmail.com" />
              <Input label="SMTP Port" value={settings.smtpPort} onChange={f("smtpPort")} placeholder="587" />
              <Input label="From Email" type="email" value={settings.fromEmail} onChange={f("fromEmail")} placeholder="noreply@company.com" />
              <Input label="From Name" value={settings.fromName} onChange={f("fromName")} placeholder="VDTI Service Hub" />
            </div>
            <div className="mt-4 flex gap-3">
              <div className="flex-1">
                <Input label="Email Password / App Password" type="password" value="••••••••••••" onChange={() => {}} />
              </div>
            </div>
            <div className="mt-4 flex gap-3">
              <Button variant="outline" size="sm">
                <Send size={14} /> Send Test Email
              </Button>
            </div>
          </Card>

          {/* Notification Triggers */}
          <Card className="p-5">
            <h3 className="font-bold text-gray-800 dark:text-white font-display mb-4">Notification Triggers</h3>
            <div className="space-y-3">
              {Object.entries(settings.notifications).map(([key, value]) => (
                <motion.div key={key} className="flex items-center justify-between p-3 rounded-xl bg-gray-50 dark:bg-gray-700/50 hover:bg-gray-100 dark:hover:bg-gray-700 transition">
                  <div>
                    <p className="font-medium text-gray-800 dark:text-gray-200 text-sm">{NOTIF_LABELS[key]}</p>
                    <p className="text-xs text-gray-400 mt-0.5">Send email notification when this event occurs</p>
                  </div>
                  <button
                    onClick={() => toggleNotif(key)}
                    className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors duration-200 focus:outline-none ${value ? "bg-blue-600" : "bg-gray-300 dark:bg-gray-600"}`}
                  >
                    <motion.span
                      animate={{ x: value ? 20 : 2 }}
                      transition={{ type: "spring", stiffness: 500, damping: 30 }}
                      className="inline-block h-4 w-4 rounded-full bg-white shadow-sm"
                    />
                  </button>
                </motion.div>
              ))}
            </div>
          </Card>

          {/* Email Template Preview */}
          <Card className="p-5">
            <h3 className="font-bold text-gray-800 dark:text-white font-display mb-3">Email Template Preview</h3>
            <div className="border border-gray-200 dark:border-gray-600 rounded-xl overflow-hidden">
              <div className="bg-blue-600 px-5 py-4">
                <p className="text-white font-bold text-lg">VDTI Service Hub Notification</p>
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
                <p className="text-gray-500 dark:text-gray-400 text-xs">This is an automated notification from {settings.fromName}.</p>
              </div>
            </div>
          </Card>

          <div className="flex justify-end">
            <Button onClick={handleSave} size="lg"><Save size={16} /> Save Settings</Button>
          </div>
        </div>

        {toast && <Toast {...toast} onClose={() => {}} />}
      </div>
    </PageTransition>
  );
}
