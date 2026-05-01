import { useState } from "react";
import { motion } from "framer-motion";
import { Settings, Lock, Moon, Sun, ShieldCheck, CheckCircle2, AlertCircle } from "lucide-react";
import { useDispatch, useSelector } from "react-redux";
import { resetPassword, clearError } from "../store/authSlice";
import { PageTransition, Card, Input, Button } from "../components/ui";
import { useApp } from "../context/AppContext";

export default function SettingsPage() {
  const dispatch = useDispatch();
  const { user: currentUser, loading, error } = useSelector((state) => state.auth);
  const { darkMode, setDarkMode } = useApp();
  
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [success, setSuccess] = useState(false);

  const handlePasswordChange = async (e) => {
    e.preventDefault();
    dispatch(clearError());
    setSuccess(false);
    
    if (newPassword !== confirmPassword) return;

    // The reset-password API is used for changing password as well
    // For logged in users, the token would typically be handled by the backend session or a specific token
    // The user mentioned: POST /api/auth/reset-password with token, new_password, confirm_password
    const result = await dispatch(resetPassword({ 
      token: "CURRENT_SESSION", // Backend should handle this for logged-in users or provide a specific token
      new_password: newPassword, 
      confirm_password: confirmPassword 
    }));

    if (resetPassword.fulfilled.match(result)) {
      setSuccess(true);
      setNewPassword("");
      setConfirmPassword("");
    }
  };

  return (
    <PageTransition>
      <div className="p-4 md:p-8 w-full mx-auto">
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Settings</h1>
          <p className="text-gray-500 dark:text-gray-400">Manage your preferences and security</p>
        </div>

        <div className="space-y-8">
          {/* Appearance */}
          <Card className="p-8">
            <div className="flex items-center gap-3 mb-8">
              <div className="p-2 bg-blue-50 dark:bg-blue-900/20 rounded-xl text-blue-600 dark:text-blue-400">
                <Settings size={20} />
              </div>
              <h3 className="text-lg font-bold text-gray-900 dark:text-white">Appearance</h3>
            </div>

            <div className="flex items-center justify-between p-6 bg-gray-50 dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800">
              <div>
                <p className="font-bold text-gray-900 dark:text-white">Dark Mode</p>
                <p className="text-sm text-gray-500">Switch between light and dark themes</p>
              </div>
              <button 
                onClick={() => setDarkMode(!darkMode)}
                className={`relative inline-flex h-8 w-16 items-center rounded-full transition-all duration-300 focus:outline-none ${darkMode ? "bg-blue-600" : "bg-gray-300"}`}
              >
                <motion.div 
                  animate={{ x: darkMode ? 36 : 4 }}
                  className="flex items-center justify-center h-6 w-6 rounded-full bg-white shadow-lg"
                >
                  {darkMode ? <Moon size={14} className="text-blue-600" /> : <Sun size={14} className="text-gray-400" />}
                </motion.div>
              </button>
            </div>
          </Card>

          {/* Security */}
          <Card className="p-8">
            <div className="flex items-center gap-3 mb-8">
              <div className="p-2 bg-red-50 dark:bg-red-900/20 rounded-xl text-red-600 dark:text-red-400">
                <Lock size={20} />
              </div>
              <h3 className="text-lg font-bold text-gray-900 dark:text-white">Security</h3>
            </div>

            <form onSubmit={handlePasswordChange} className="space-y-6 max-w-md">
              <div className="space-y-4">
                <Input 
                  label="New Password" 
                  type="password" 
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                />
                <Input 
                  label="Confirm New Password" 
                  type="password" 
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                />
              </div>

              {newPassword !== confirmPassword && confirmPassword !== "" && (
                <div className="flex items-center gap-2 text-red-600 text-xs font-semibold">
                  <AlertCircle size={14} />
                  <span>Passwords do not match</span>
                </div>
              )}

              {error && (
                <div className="p-4 bg-red-50 dark:bg-red-900/20 border border-red-100 dark:border-red-800 rounded-xl text-red-600 dark:text-red-400 text-sm flex items-center gap-3">
                  <AlertCircle size={18} />
                  {error}
                </div>
              )}

              {success && (
                <div className="p-4 bg-green-50 dark:bg-green-900/20 border border-green-100 dark:border-green-800 rounded-xl text-green-600 dark:text-green-400 text-sm flex items-center gap-3">
                  <CheckCircle2 size={18} />
                  Password changed successfully!
                </div>
              )}

              <Button 
                type="submit" 
                className="w-full sm:w-auto"
                disabled={loading || !newPassword || newPassword !== confirmPassword}
              >
                {loading ? "Updating..." : "Update Password"}
              </Button>
            </form>
          </Card>
        </div>
      </div>
    </PageTransition>
  );
}
