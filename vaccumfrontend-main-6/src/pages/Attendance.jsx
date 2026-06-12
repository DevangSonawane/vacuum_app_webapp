import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import axios from "axios";
import {
  Users, Plus, Search, Eye, Pencil, Banknote,
  Loader2, CheckCircle, AlertCircle,
  ChevronRight, Shield, CreditCard,
  Building2, Mail, Phone, User, Calendar, RefreshCw,
} from "lucide-react";
import {
  PageTransition, Card, Badge, Button, Modal, Input,
  SectionHeader, StatCard, useToast, Toast,
} from "../components/ui";

const API = "https://vaccumapi-o4ol.onrender.com/api";

function formatDate(str) {
  if (!str) return "—";
  try {
    if (str.includes("T")) return new Date(str).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" });
    if (str.includes("/")) {
      const [d, m, y] = str.split("/");
      return new Date(`${y}-${m}-${d}`).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" });
    }
    return new Date(str).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" });
  } catch {
    return str;
  }
}

function getInitials(name) {
  if (!name) return "?";
  return name.split(" ").map(n => n[0]).slice(0, 2).join("").toUpperCase();
}

function DetailRow({ label, value, icon: Icon }) {
  return (
    <div className="flex items-start gap-3 py-2.5 border-b border-gray-50 dark:border-gray-700/50 last:border-0">
      {Icon && (
        <div className="mt-0.5 p-1.5 bg-blue-50 dark:bg-blue-900/20 rounded-lg flex-shrink-0">
          <Icon size={13} className="text-blue-500" />
        </div>
      )}
      <div className="flex-1 min-w-0">
        <p className="text-xs text-gray-400 dark:text-gray-500 font-medium">{label}</p>
        <p className="text-sm font-semibold text-gray-800 dark:text-gray-200 truncate">{value || "—"}</p>
      </div>
    </div>
  );
}

const EMPTY_ADD = { open: false, step: 1, employeeIdInput: "", fetching: false, fetchedEmployee: null, fetchError: null, saving: false };
const EMPTY_EDIT_FORM = {
  email: "", title: "", department: "",
  "manager-employee-id": "", "manager-employee-type": "employee",
  "bank-ifsc": "", "bank-account-number": "", pan: "",
  "phone-number": "", "hiring-date": "", state: "", "pt-enabled": false,
  pastSalary: 0, pastExemption: 0, pastTds: 0,
  previousEmployerSalary: 0, previousEmployerTds: 0,
};

export default function Attendance() {
  const navigate = useNavigate();
  const [employees, setEmployees] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const { toast, showToast } = useToast();

  const [addModal, setAddModal] = useState(EMPTY_ADD);
  const [editModal, setEditModal] = useState({ open: false, employee: null, form: EMPTY_EDIT_FORM, saving: false });
  const [salaryModal, setSalaryModal] = useState({ open: false, employee: null, form: { "annual-ctc": "", "custom-salary-structure": false }, saving: false });

  const fetchEmployees = useCallback(async () => {
    setLoading(true);
    try {
      const { data } = await axios.get(`${API}/attendance/people`);
      setEmployees(data.employees || []);
    } catch (err) {
      showToast(err.response?.data?.error?.message || "Failed to load employees", "error");
    } finally {
      setLoading(false);
    }
  }, [showToast]);

  useEffect(() => { fetchEmployees(); }, [fetchEmployees]);


  const handleFetchPreview = async () => {
    const id = addModal.employeeIdInput.trim();
    if (!id) return;
    setAddModal(p => ({ ...p, fetching: true, fetchError: null, fetchedEmployee: null }));
    try {
      const { data } = await axios.get(`${API}/attendance/people/view/${id}`);
      setAddModal(p => ({ ...p, fetching: false, fetchedEmployee: data.employee, step: 2 }));
    } catch (err) {
      setAddModal(p => ({ ...p, fetching: false, fetchError: err.response?.data?.error?.message || "Failed to fetch employee from RazorpayX" }));
    }
  };

  const handleStoreEmployee = async () => {
    setAddModal(p => ({ ...p, saving: true }));
    try {
      await axios.post(`${API}/attendance/people`, {
        employee_id: addModal.employeeIdInput,
        employee: addModal.fetchedEmployee,
      });
      showToast("Employee stored in database successfully", "success");
      setAddModal(EMPTY_ADD);
      fetchEmployees();
    } catch (err) {
      showToast(err.response?.data?.error?.message || "Failed to store employee", "error");
      setAddModal(p => ({ ...p, saving: false }));
    }
  };

  const handleEdit = (emp) => {
    setEditModal({
      open: true,
      employee: emp,
      form: {
        ...EMPTY_EDIT_FORM,
        email: emp.email || "",
        title: emp.title || "",
        department: emp.department || "",
        "manager-employee-id": emp.manager_employee_id || "",
        "bank-ifsc": emp.bank_ifsc || "",
        "bank-account-number": emp.bank_account_number || "",
        pan: emp.pan || "",
        "phone-number": emp.phone_number || "",
        "hiring-date": emp.date_of_hiring || "",
      },
      saving: false,
    });
  };

  const handleSaveEdit = async () => {
    setEditModal(p => ({ ...p, saving: true }));
    try {
      const payload = { ...editModal.form };
      if (payload["manager-employee-id"]) payload["manager-employee-id"] = Number(payload["manager-employee-id"]);
      await axios.put(`${API}/attendance/people/${editModal.employee.employee_id}`, payload);
      showToast("Employee updated successfully", "success");
      setEditModal(p => ({ ...p, open: false }));
      fetchEmployees();
    } catch (err) {
      showToast(err.response?.data?.error?.message || "Failed to update employee", "error");
      setEditModal(p => ({ ...p, saving: false }));
    }
  };

  const handleSalary = (emp) => {
    setSalaryModal({
      open: true,
      employee: emp,
      form: { "annual-ctc": emp.annual_ctc || "", "custom-salary-structure": emp.custom_salary_structure || false },
      saving: false,
    });
  };

  const handleSaveSalary = async () => {
    setSalaryModal(p => ({ ...p, saving: true }));
    try {
      await axios.post(`${API}/attendance/people/${salaryModal.employee.employee_id}/salary`, {
        "annual-ctc": Number(salaryModal.form["annual-ctc"]),
        "custom-salary-structure": salaryModal.form["custom-salary-structure"],
      });
      showToast("Salary updated successfully", "success");
      setSalaryModal(p => ({ ...p, open: false }));
      fetchEmployees();
    } catch (err) {
      showToast(err.response?.data?.error?.message || "Failed to set salary", "error");
      setSalaryModal(p => ({ ...p, saving: false }));
    }
  };

  const filtered = employees.filter(emp =>
    !searchQuery ||
    [emp.name, emp.email, emp.department, emp.title, emp.employee_id]
      .some(f => f?.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  const activeCount = employees.filter(e => e.is_active).length;
  const inactiveCount = employees.filter(e => !e.is_active).length;

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-7xl mx-auto">
        <SectionHeader
          title="Employees"
          subtitle="Manage RazorpayX employee records"
          action={
            <Button onClick={() => setAddModal(p => ({ ...p, open: true }))}>
              <Plus size={16} /> Add Employee
            </Button>
          }
        />

        {/* Stats */}
        <div className="grid grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
          <StatCard title="Total Employees" value={employees.length} icon={Users} color="blue" />
          <StatCard title="Active" value={activeCount} icon={CheckCircle} color="emerald" />
          <StatCard title="Inactive" value={inactiveCount} icon={AlertCircle} color="red" />
        </div>

        {/* Search + Refresh */}
        <div className="flex items-center gap-3 mb-5">
          <div className="relative flex-1 max-w-sm">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
              placeholder="Search by name, email, department…"
              className="w-full pl-9 pr-4 py-2 rounded-xl border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 text-gray-800 dark:text-gray-200 placeholder-gray-400"
            />
          </div>
          <Button variant="secondary" onClick={fetchEmployees}>
            <RefreshCw size={14} /> Refresh
          </Button>
        </div>

        {/* Employee Table */}
        <Card className="overflow-hidden">
          <div className="overflow-x-auto">
            {loading ? (
              <div className="flex items-center justify-center py-24 gap-3 text-gray-400">
                <Loader2 size={20} className="animate-spin" />
                <span className="text-sm">Loading employees…</span>
              </div>
            ) : filtered.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-24 text-center">
                <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-2xl mb-3">
                  <Users size={28} className="text-blue-400" />
                </div>
                <p className="font-semibold text-gray-600 dark:text-gray-300">No employees found</p>
                <p className="text-sm text-gray-400 mt-1">
                  {searchQuery ? "Try a different search term" : "Add an employee using the button above"}
                </p>
              </div>
            ) : (
              <table className="w-full text-sm">
                <thead className="bg-gray-50 dark:bg-gray-700/50">
                  <tr>
                    {["Employee", "Department / Title", "Contact", "Annual CTC", "Status", "Actions"].map(h => (
                      <th key={h} className="text-left py-3 px-4 text-xs text-gray-500 dark:text-gray-400 font-semibold whitespace-nowrap">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((emp, i) => (
                    <motion.tr
                      key={emp.id}
                      initial={{ opacity: 0, y: 8 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: i * 0.04 }}
                      className="border-b border-gray-50 dark:border-gray-700/50 hover:bg-gray-50 dark:hover:bg-gray-700/30 transition"
                    >
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-3"
                         onClick={() => navigate(`/attendance/${emp.employee_id}`, { state: { employee: emp } })}>
                          <div className="w-9 h-9 rounded-full bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center text-white text-xs font-bold flex-shrink-0"
                         
                          >
                            {getInitials(emp.name)}
                          </div>
                          <div>
                            <p className="font-semibold text-gray-800 dark:text-gray-200">{emp.name || "—"}</p>
                            <p className="text-xs text-gray-400">ID: {emp.employee_id}</p>
                          </div>
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <p className="font-medium text-gray-700 dark:text-gray-300">{emp.department || "—"}</p>
                        <p className="text-xs text-gray-400">{emp.title || "—"}</p>
                      </td>
                      <td className="py-3 px-4">
                        <p className="text-gray-700 dark:text-gray-300">{emp.email || "—"}</p>
                        <p className="text-xs text-gray-400">{emp.phone_number || "—"}</p>
                      </td>
                      <td className="py-3 px-4">
                        {emp.annual_ctc ? (
                          <span className="font-semibold text-gray-800 dark:text-gray-200">
                            ₹{Number(emp.annual_ctc).toLocaleString("en-IN")}
                          </span>
                        ) : (
                          <span className="text-xs text-gray-400 italic">Not set</span>
                        )}
                      </td>
                      <td className="py-3 px-4">
                        <Badge label={emp.is_active ? "Active" : "Inactive"} />
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-1">
                          <button
                            onClick={() => navigate(`/attendance/${emp.employee_id}`, { state: { employee: emp } })}
                            title="View attendance"
                            className="p-2 rounded-lg hover:bg-blue-50 dark:hover:bg-blue-900/20 text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 transition"
                          >
                            <Eye size={15} />
                          </button>
                          <button
                            onClick={() => handleEdit(emp)}
                            title="Edit employee"
                            className="p-2 rounded-lg hover:bg-amber-50 dark:hover:bg-amber-900/20 text-gray-400 hover:text-amber-600 dark:hover:text-amber-400 transition"
                          >
                            <Pencil size={15} />
                          </button>
                          <button
                            onClick={() => handleSalary(emp)}
                            title="Set salary"
                            className="p-2 rounded-lg hover:bg-emerald-50 dark:hover:bg-emerald-900/20 text-gray-400 hover:text-emerald-600 dark:hover:text-emerald-400 transition"
                          >
                            <Banknote size={15} />
                          </button>
                        </div>
                      </td>
                    </motion.tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </Card>

        {/* ── ADD EMPLOYEE MODAL ── */}
        <Modal
          isOpen={addModal.open}
          onClose={() => setAddModal(EMPTY_ADD)}
          title={addModal.step === 1 ? "Fetch Employee from RazorpayX" : "Confirm & Store Employee"}
          size="md"
        >
          <AnimatePresence mode="wait">
            {addModal.step === 1 ? (
              <motion.div key="step1" initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -10 }} className="space-y-5">
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  Enter the numeric RazorpayX Employee ID to preview their data before saving to the local database.
                </p>
                <Input
                  label="RazorpayX Employee ID"
                  value={addModal.employeeIdInput}
                  onChange={e => setAddModal(p => ({ ...p, employeeIdInput: e.target.value, fetchError: null }))}
                  placeholder="e.g. 1"
                  required
                />
                {addModal.fetchError && (
                  <div className="flex items-center gap-2 p-3 bg-red-50 dark:bg-red-900/20 rounded-xl text-red-600 dark:text-red-400 text-sm">
                    <AlertCircle size={15} className="flex-shrink-0" />
                    {addModal.fetchError}
                  </div>
                )}
                <div className="flex gap-3 pt-1">
                  <Button
                    onClick={handleFetchPreview}
                    disabled={!addModal.employeeIdInput.trim() || addModal.fetching}
                    className="flex-1"
                  >
                    {addModal.fetching
                      ? <><Loader2 size={15} className="animate-spin" /> Fetching…</>
                      : <><ChevronRight size={15} /> Fetch from RazorpayX</>}
                  </Button>
                  <Button variant="secondary" onClick={() => setAddModal(EMPTY_ADD)}>Cancel</Button>
                </div>
              </motion.div>
            ) : (
              <motion.div key="step2" initial={{ opacity: 0, x: 10 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: 10 }} className="space-y-4">
                <div className="flex items-center gap-2 p-3 bg-emerald-50 dark:bg-emerald-900/20 rounded-xl text-emerald-700 dark:text-emerald-400 text-sm">
                  <CheckCircle size={15} className="flex-shrink-0" />
                  Employee data fetched from RazorpayX. Review and confirm to save.
                </div>

                <div className="bg-gray-50 dark:bg-gray-700/40 rounded-xl p-4">
                  <div className="flex items-center gap-3 mb-4 pb-4 border-b border-gray-100 dark:border-gray-600">
                    <div className="w-12 h-12 rounded-full bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center text-white font-bold text-base flex-shrink-0">
                      {getInitials(addModal.fetchedEmployee?.name)}
                    </div>
                    <div>
                      <h3 className="font-bold text-gray-900 dark:text-white">{addModal.fetchedEmployee?.name}</h3>
                      <p className="text-sm text-gray-500 dark:text-gray-400">
                        {addModal.fetchedEmployee?.title}
                        {addModal.fetchedEmployee?.department ? ` · ${addModal.fetchedEmployee.department}` : ""}
                      </p>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6">
                    <DetailRow label="Employee ID" value={addModal.employeeIdInput} icon={User} />
                    <DetailRow label="Email" value={addModal.fetchedEmployee?.email} icon={Mail} />
                    <DetailRow label="Phone" value={addModal.fetchedEmployee?.phone_number} icon={Phone} />
                    <DetailRow label="Date of Birth" value={formatDate(addModal.fetchedEmployee?.["date-of-birth"])} icon={Calendar} />
                    <DetailRow label="Date of Hiring" value={formatDate(addModal.fetchedEmployee?.["date-of-hiring"])} icon={Calendar} />
                    <DetailRow label="Department" value={addModal.fetchedEmployee?.department} icon={Building2} />
                    <DetailRow label="Manager Email" value={addModal.fetchedEmployee?.["manager-email"]} icon={Mail} />
                    <DetailRow label="PAN" value={addModal.fetchedEmployee?.pan} icon={Shield} />
                    <DetailRow label="Bank IFSC" value={addModal.fetchedEmployee?.["bank-ifsc"]} icon={CreditCard} />
                    <DetailRow label="Bank Account" value={addModal.fetchedEmployee?.["bank-account-number"]} icon={CreditCard} />
                  </div>
                </div>

                <div className="flex gap-3 pt-1">
                  <Button onClick={handleStoreEmployee} disabled={addModal.saving} className="flex-1">
                    {addModal.saving
                      ? <><Loader2 size={15} className="animate-spin" /> Saving…</>
                      : <><CheckCircle size={15} /> Save to Database</>}
                  </Button>
                  <Button variant="secondary" onClick={() => setAddModal(p => ({ ...p, step: 1, fetchedEmployee: null }))}>
                    Back
                  </Button>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </Modal>

        {/* ── EDIT EMPLOYEE MODAL ── */}
        <Modal
          isOpen={editModal.open}
          onClose={() => setEditModal(p => ({ ...p, open: false }))}
          title={`Edit — ${editModal.employee?.name || ""}`}
          size="lg"
        >
          <form onSubmit={e => { e.preventDefault(); handleSaveEdit(); }} className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Input label="Email" value={editModal.form.email} onChange={e => setEditModal(p => ({ ...p, form: { ...p.form, email: e.target.value } }))} placeholder="email@example.com" />
              <Input label="Phone Number" value={editModal.form["phone-number"]} onChange={e => setEditModal(p => ({ ...p, form: { ...p.form, "phone-number": e.target.value } }))} placeholder="9810012345" />
              <Input label="Title" value={editModal.form.title} onChange={e => setEditModal(p => ({ ...p, form: { ...p.form, title: e.target.value } }))} placeholder="Job title" />
              <Input label="Department" value={editModal.form.department} onChange={e => setEditModal(p => ({ ...p, form: { ...p.form, department: e.target.value } }))} placeholder="Department" />
              <Input label="Manager Employee ID" value={editModal.form["manager-employee-id"]} onChange={e => setEditModal(p => ({ ...p, form: { ...p.form, "manager-employee-id": e.target.value } }))} placeholder="127" />
              <Input label="Manager Employee Type" value={editModal.form["manager-employee-type"]} onChange={e => setEditModal(p => ({ ...p, form: { ...p.form, "manager-employee-type": e.target.value } }))} placeholder="employee / contractor" />
              <Input label="Hiring Date" type="date" value={editModal.form["hiring-date"]} onChange={e => setEditModal(p => ({ ...p, form: { ...p.form, "hiring-date": e.target.value } }))} />
              <Input label="State (for PT)" value={editModal.form.state} onChange={e => setEditModal(p => ({ ...p, form: { ...p.form, state: e.target.value } }))} placeholder="e.g. karnataka" />
              <Input label="PAN" value={editModal.form.pan} onChange={e => setEditModal(p => ({ ...p, form: { ...p.form, pan: e.target.value } }))} placeholder="AGCPJ0387P" />
              <Input label="Bank IFSC" value={editModal.form["bank-ifsc"]} onChange={e => setEditModal(p => ({ ...p, form: { ...p.form, "bank-ifsc": e.target.value } }))} placeholder="CORP0002106" />
              <Input label="Bank Account Number" value={editModal.form["bank-account-number"]} onChange={e => setEditModal(p => ({ ...p, form: { ...p.form, "bank-account-number": e.target.value } }))} placeholder="1234567890" />
            </div>

            <div>
              <p className="text-xs font-bold text-gray-400 uppercase tracking-wide mb-3">Previous Employer Details</p>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                {[
                  ["pastSalary", "Past Salary (₹)"],
                  ["pastExemption", "Past Exemption (₹)"],
                  ["pastTds", "Past TDS (₹)"],
                  ["previousEmployerSalary", "Prev Employer Salary (₹)"],
                  ["previousEmployerTds", "Prev Employer TDS (₹)"],
                ].map(([key, lbl]) => (
                  <Input
                    key={key}
                    label={lbl}
                    type="number"
                    value={editModal.form[key]}
                    onChange={e => setEditModal(p => ({ ...p, form: { ...p.form, [key]: Number(e.target.value) } }))}
                  />
                ))}
              </div>
            </div>

            <label className="flex items-center gap-3 cursor-pointer select-none">
              <input
                type="checkbox"
                checked={editModal.form["pt-enabled"]}
                onChange={e => setEditModal(p => ({ ...p, form: { ...p.form, "pt-enabled": e.target.checked } }))}
                className="w-4 h-4 rounded accent-blue-600"
              />
              <span className="text-sm font-medium text-gray-700 dark:text-gray-300">Enable Professional Tax (PT)</span>
            </label>

            <div className="flex gap-3 pt-2">
              <Button type="submit" className="flex-1" disabled={editModal.saving}>
                {editModal.saving ? <><Loader2 size={15} className="animate-spin" /> Saving…</> : "Save Changes"}
              </Button>
              <Button variant="secondary" onClick={() => setEditModal(p => ({ ...p, open: false }))}>Cancel</Button>
            </div>
          </form>
        </Modal>

        {/* ── SET SALARY MODAL ── */}
        <Modal
          isOpen={salaryModal.open}
          onClose={() => setSalaryModal(p => ({ ...p, open: false }))}
          title={`Set Salary — ${salaryModal.employee?.name || ""}`}
          size="sm"
        >
          <form onSubmit={e => { e.preventDefault(); handleSaveSalary(); }} className="space-y-4">
            <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-xl flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-800/40 rounded-xl">
                <Banknote size={18} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-xs text-blue-600 dark:text-blue-400 font-semibold uppercase tracking-wide">Current Annual CTC</p>
                <p className="text-lg font-bold text-blue-900 dark:text-blue-200">
                  {salaryModal.employee?.annual_ctc
                    ? `₹${Number(salaryModal.employee.annual_ctc).toLocaleString("en-IN")}`
                    : "Not set"}
                </p>
              </div>
            </div>

            <Input
              label="Annual CTC (₹)"
              type="number"
              value={salaryModal.form["annual-ctc"]}
              onChange={e => setSalaryModal(p => ({ ...p, form: { ...p.form, "annual-ctc": e.target.value } }))}
              placeholder="600000"
              required
            />

            <label className="flex items-center gap-3 cursor-pointer select-none">
              <input
                type="checkbox"
                checked={salaryModal.form["custom-salary-structure"]}
                onChange={e => setSalaryModal(p => ({ ...p, form: { ...p.form, "custom-salary-structure": e.target.checked } }))}
                className="w-4 h-4 rounded accent-blue-600"
              />
              <span className="text-sm font-medium text-gray-700 dark:text-gray-300">Use Custom Salary Structure</span>
            </label>

            <div className="flex gap-3 pt-2">
              <Button type="submit" className="flex-1" disabled={salaryModal.saving}>
                {salaryModal.saving
                  ? <><Loader2 size={15} className="animate-spin" /> Saving…</>
                  : <><Banknote size={15} /> Set Salary</>}
              </Button>
              <Button variant="secondary" onClick={() => setSalaryModal(p => ({ ...p, open: false }))}>Cancel</Button>
            </div>
          </form>
        </Modal>

        <AnimatePresence>
          {toast && <Toast message={toast.message} type={toast.type} onClose={() => {}} />}
        </AnimatePresence>
      </div>
    </PageTransition>
  );
}
