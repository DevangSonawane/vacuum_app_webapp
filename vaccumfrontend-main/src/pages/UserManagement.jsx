import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { 
  Users, UserPlus, Search, Edit2, Trash2, Shield, 
  CheckCircle2, XCircle, X, Save,
  Mail, Phone, Eye, EyeOff
} from "lucide-react";
import axios from "axios";
import { PageTransition, Card, Button, Input, useToast, Toast } from "../components/ui";

const API_BASE_URL = 'https://vaccumapi.onrender.com/api';

// All roles as per API doc — technician added
const ROLES = [
  { value: "admin",      label: "Administrator" },
  { value: "manager",    label: "Manager" },
  { value: "engineer",   label: "Engineer" },
  { value: "technician", label: "Technician" },
  { value: "labour",     label: "Labour" },
];

export default function UserManagement() {
  const [users, setUsers]           = useState([]);
  const [pagination, setPagination] = useState(null);
  const [loading, setLoading]       = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [showModal, setShowModal]   = useState(false);
  const [editingUser, setEditingUser] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const { toast, showToast }        = useToast();

  const [formData, setFormData] = useState({
    first_name:   "",
    last_name:    "",
    email:        "",
    phone_number: "",
    role:         "technician",
    is_active:    true,
    password:     "",
  });

  useEffect(() => { fetchUsers(); }, []);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem('token');
      const response = await axios.get(`${API_BASE_URL}/users`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const { success, data, pagination } = response.data;
      if (success) {
        setUsers(data || []);
        setPagination(pagination);
      } else {
        showToast(response.data.message || "Failed to fetch users", "error");
      }
    } catch (error) {
      showToast(error.response?.data?.message || "Failed to fetch users", "error");
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    const token = localStorage.getItem('token');

    try {
      if (editingUser) {
        // PUT /api/users/:id — exclude password from update payload
        const { password, ...updateData } = formData;
        // Normalise phone with +91 prefix if bare number
        if (updateData.phone_number && !updateData.phone_number.startsWith("+")) {
          updateData.phone_number = `+91${updateData.phone_number}`;
        }
        await axios.put(`${API_BASE_URL}/users/${editingUser.id}`, updateData, {
          headers: { Authorization: `Bearer ${token}` }
        });
        showToast("User updated successfully!");
      } else {
        // POST /api/users — admin creates user directly (NOT /auth/register)
        // API requires at least one of email or phone_number
        const payload = {
          first_name:   formData.first_name.trim(),
          last_name:    formData.last_name.trim(),
          password:     formData.password,
          role:         formData.role,
          is_active:    formData.is_active,
        };
        if (formData.email) {
          payload.email = formData.email.trim().toLowerCase();
        }
        if (formData.phone_number) {
          payload.phone_number = formData.phone_number.startsWith("+")
            ? formData.phone_number
            : `+91${formData.phone_number}`;
        }
        await axios.post(`${API_BASE_URL}/auth/register`, payload, {
          headers: { Authorization: `Bearer ${token}` }
        });
        showToast("User created successfully!");
      }
      setShowModal(false);
      fetchUsers();
    } catch (error) {
      showToast(error.response?.data?.message || "Operation failed", "error");
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeactivate = async (id) => {
    if (!window.confirm("Are you sure you want to deactivate this user?")) return;
    const token = localStorage.getItem('token');
    try {
      await axios.delete(`${API_BASE_URL}/users/${id}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      showToast("User deactivated successfully!");
      fetchUsers();
    } catch (error) {
      showToast(error.response?.data?.message || "Deactivation failed", "error");
    }
  };

  const openAddModal = () => {
    setEditingUser(null);
    setFormData({ first_name: "", last_name: "", email: "", phone_number: "", role: "technician", is_active: true, password: "" });
    setShowPassword(false);
    setShowModal(true);
  };

  const openEditModal = (user) => {
    setEditingUser(user);
    setFormData({
      first_name:   user.first_name   || "",
      last_name:    user.last_name    || "",
      email:        user.email        || "",
      phone_number: user.phone_number || "",
      role:         user.role         || "technician",
      is_active:    user.is_active    ?? true,
      password:     "",
    });
    setShowPassword(false);
    setShowModal(true);
  };

  const filteredUsers = Array.isArray(users)
    ? users.filter(u =>
        `${u.first_name || ""} ${u.last_name || ""} ${u.email || ""}`.toLowerCase()
          .includes(searchQuery.toLowerCase())
      )
    : [];

  const getRoleBadgeColor = (role) => {
    const colors = {
      admin:      "bg-purple-50 dark:bg-purple-900/20 text-purple-600 dark:text-purple-400",
      manager:    "bg-blue-50   dark:bg-blue-900/20   text-blue-600   dark:text-blue-400",
      engineer:   "bg-cyan-50   dark:bg-cyan-900/20   text-cyan-600   dark:text-cyan-400",
      technician: "bg-amber-50  dark:bg-amber-900/20  text-amber-600  dark:text-amber-400",
      labour:     "bg-gray-50   dark:bg-gray-900/20   text-gray-600   dark:text-gray-400",
    };
    return colors[role] || colors.labour;
  };

  return (
    <PageTransition>
      <div className="p-4 md:p-8 w-full mx-auto">
        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">User Management</h1>
            <p className="text-gray-500 dark:text-gray-400">Manage system access and user roles</p>
          </div>
          <Button className="flex items-center gap-2" onClick={openAddModal}>
            <UserPlus size={18} />
            Add New User
          </Button>
        </div>

        <Card className="overflow-hidden">
          {/* Search bar */}
          <div className="p-4 border-b border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-900/50">
            <div className="relative max-w-md">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
              <input
                type="text"
                placeholder="Search users..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-sm dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500/20"
              />
            </div>
          </div>

          {/* Table */}
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="text-[10px] font-bold text-gray-400 uppercase tracking-widest border-b border-gray-100 dark:border-gray-800">
                  <th className="px-6 py-4">User</th>
                  <th className="px-6 py-4">Role</th>
                  <th className="px-6 py-4">Contact</th>
                  <th className="px-6 py-4">Status</th>
                  <th className="px-6 py-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
                {loading ? (
                  [...Array(5)].map((_, i) => (
                    <tr key={i} className="animate-pulse">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-xl bg-gray-200 dark:bg-gray-800" />
                          <div className="space-y-2">
                            <div className="h-4 w-24 bg-gray-200 dark:bg-gray-800 rounded" />
                            <div className="h-3 w-32 bg-gray-100 dark:bg-gray-900 rounded" />
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4"><div className="h-4 w-20 bg-gray-100 dark:bg-gray-800 rounded" /></td>
                      <td className="px-6 py-4"><div className="h-4 w-28 bg-gray-100 dark:bg-gray-800 rounded" /></td>
                      <td className="px-6 py-4"><div className="h-6 w-16 bg-gray-100 dark:bg-gray-800 rounded-full" /></td>
                      <td className="px-6 py-4 text-right">
                        <div className="flex justify-end gap-2">
                          <div className="w-8 h-8 bg-gray-100 dark:bg-gray-800 rounded-lg" />
                          <div className="w-8 h-8 bg-gray-100 dark:bg-gray-800 rounded-lg" />
                        </div>
                      </td>
                    </tr>
                  ))
                ) : filteredUsers.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-6 py-16 text-center text-gray-400">
                      <Users size={40} className="mx-auto mb-3 opacity-30" />
                      <p className="font-medium">No users found</p>
                    </td>
                  </tr>
                ) : filteredUsers.map((user) => (
                  <tr key={user.id} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/30 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center text-blue-600 dark:text-blue-400 font-bold text-sm">
                          {(user.first_name?.[0] || "") + (user.last_name?.[0] || "")}
                        </div>
                        <div>
                          <p className="font-semibold text-gray-900 dark:text-white text-sm">
                            {user.first_name} {user.last_name}
                          </p>
                          <p className="text-xs text-gray-400 flex items-center gap-1 mt-0.5">
                            <Mail size={10} /> {user.email || user.phone_number || "—"}
                          </p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-semibold ${getRoleBadgeColor(user.role)}`}>
                        <Shield size={11} />
                        <span className="capitalize">{user.role}</span>
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600 dark:text-gray-400">
                      {user.phone_number || "—"}
                    </td>
                    <td className="px-6 py-4">
                      {user.is_active ? (
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-green-50 dark:bg-green-900/20 text-green-600 dark:text-green-400 text-[10px] font-bold uppercase">
                          <CheckCircle2 size={12} /> Active
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 text-[10px] font-bold uppercase">
                          <XCircle size={12} /> Inactive
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex justify-end gap-2">
                        <button
                          onClick={() => openEditModal(user)}
                          className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-all"
                        >
                          <Edit2 size={16} />
                        </button>
                        <button
                          onClick={() => handleDeactivate(user.id)}
                          className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-all disabled:opacity-30 disabled:cursor-not-allowed"
                          disabled={!user.is_active}
                        >
                          <Trash2 size={16} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>

        {/* Pagination */}
        {pagination && (
          <div className="mt-4 flex items-center justify-between px-2 text-sm text-gray-500">
            <p>Showing {users.length} of {pagination.total} users</p>
            <div className="flex gap-2">
              <Button variant="outline" size="sm" disabled={pagination.page <= 1}>Previous</Button>
              <div className="flex items-center px-3 font-medium text-gray-900 dark:text-white">
                Page {pagination.page} of {pagination.total_pages}
              </div>
              <Button variant="outline" size="sm" disabled={pagination.page >= pagination.total_pages}>Next</Button>
            </div>
          </div>
        )}

        {/* Add / Edit Modal */}
        <AnimatePresence>
          {showModal && (
            <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
              <motion.div
                initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
                className="absolute inset-0 bg-black/50 backdrop-blur-sm"
                onClick={() => setShowModal(false)}
              />
              <motion.div
                initial={{ opacity: 0, scale: 0.95, y: 20 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.95, y: 20 }}
                className="relative w-full max-w-lg bg-white dark:bg-gray-900 rounded-[32px] shadow-2xl overflow-hidden max-h-[90vh] overflow-y-auto"
              >
                {/* Modal Header */}
                <div className="p-8 border-b border-gray-100 dark:border-gray-800 flex justify-between items-center bg-gray-50/50 dark:bg-gray-900/50">
                  <div>
                    <h2 className="text-xl font-bold text-gray-900 dark:text-white">
                      {editingUser ? "Edit User Details" : "Create New User"}
                    </h2>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                      {editingUser ? "Update system access for this user" : "Add a new member to the platform"}
                    </p>
                  </div>
                  <button onClick={() => setShowModal(false)} className="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-white">
                    <X size={20} />
                  </button>
                </div>

                {/* Modal Form */}
                <form onSubmit={handleSubmit} className="p-8 space-y-6">
                  <div className="grid grid-cols-2 gap-4">
                    <Input
                      label="First Name"
                      value={formData.first_name}
                      onChange={e => setFormData({ ...formData, first_name: e.target.value })}
                      required
                    />
                    <Input
                      label="Last Name"
                      value={formData.last_name}
                      onChange={e => setFormData({ ...formData, last_name: e.target.value })}
                      required
                    />
                  </div>

                  <Input
                    label="Email Address"
                    type="email"
                    value={formData.email}
                    onChange={e => setFormData({ ...formData, email: e.target.value })}
                  />

                  {/* Phone with +91 prefix */}
                  <div className="space-y-1.5">
                    <label className="text-sm font-semibold text-gray-700 dark:text-gray-300">Phone Number</label>
                    <div className="relative">
                      <input
                        type="tel"
                        value={formData.phone_number}
                        onChange={e => setFormData({ ...formData, phone_number: e.target.value })}
                        placeholder="9876543210"
                        className="w-full px-5 py-3 pl-16 rounded-xl bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500/20 transition-all"
                      />
                      <div className="absolute left-4 top-1/2 -translate-y-1/2 flex items-center gap-1 text-gray-500">
                        <Phone size={13} />
                        <span className="text-xs font-semibold">+91</span>
                      </div>
                    </div>
                    <p className="text-xs text-gray-400">Provide at least one of email or phone</p>
                  </div>

                  {/* Password — only on create */}
                  {!editingUser && (
                    <div className="space-y-1.5">
                      <label className="text-sm font-semibold text-gray-700 dark:text-gray-300">
                        Password <span className="text-red-500">*</span>
                      </label>
                      <div className="relative">
                        <input
                          type={showPassword ? "text" : "password"}
                          value={formData.password}
                          onChange={e => setFormData({ ...formData, password: e.target.value })}
                          placeholder="Minimum 6 characters"
                          required
                          className="w-full px-5 py-3 rounded-xl bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500/20 transition-all pr-12"
                        />
                        <button
                          type="button"
                          onClick={() => setShowPassword(!showPassword)}
                          className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-white transition-colors"
                        >
                          {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                        </button>
                      </div>
                    </div>
                  )}

                  {/* Role dropdown — includes technician */}
                  <div className="space-y-1.5">
                    <label className="text-sm font-semibold text-gray-700 dark:text-gray-300">User Role</label>
                    <select
                      value={formData.role}
                      onChange={e => setFormData({ ...formData, role: e.target.value })}
                      className="w-full px-5 py-3 rounded-xl bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500/20 transition-all"
                    >
                      {ROLES.map(r => (
                        <option key={r.value} value={r.value}>{r.label}</option>
                      ))}
                    </select>
                    {formData.role === "technician" && !editingUser && (
                      <p className="text-xs text-amber-500">
                        💡 To give this technician a field profile (rating, jobs, specialization), also create them in the Technicians module.
                      </p>
                    )}
                  </div>

                  {/* Account Status toggle */}
                  <div className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700">
                    <div>
                      <p className="text-sm font-bold text-gray-900 dark:text-white">Account Status</p>
                      <p className="text-xs text-gray-500">Allow user to log in and access system</p>
                    </div>
                    <button
                      type="button"
                      onClick={() => setFormData({ ...formData, is_active: !formData.is_active })}
                      className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${formData.is_active ? "bg-green-500" : "bg-gray-300"}`}
                    >
                      <motion.span
                        animate={{ x: formData.is_active ? 22 : 2 }}
                        className="inline-block h-4 w-4 rounded-full bg-white shadow-sm"
                      />
                    </button>
                  </div>

                  <div className="flex gap-3 pt-4">
                    <Button type="button" variant="outline" className="flex-1" onClick={() => setShowModal(false)}>
                      Cancel
                    </Button>
                    <Button type="submit" className="flex-1" disabled={submitting}>
                      <Save size={18} className="mr-2" />
                      {submitting ? "Saving…" : editingUser ? "Update User" : "Create User"}
                    </Button>
                  </div>
                </form>
              </motion.div>
            </div>
          )}
        </AnimatePresence>

        {toast && <Toast message={toast.message} type={toast.type} />}
      </div>
    </PageTransition>
  );
}