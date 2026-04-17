import { useState } from "react";
import { motion } from "framer-motion";
import { CheckCircle2, HardHat, Mail, Key, ArrowLeft, ShieldCheck } from "lucide-react";
import { useDispatch, useSelector } from "react-redux";
import { forgotPassword, resetPassword, clearError } from "../store/authSlice";
import { Link, useNavigate } from "react-router-dom";

export default function ForgotPassword() {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const { loading, error, resetToken: devToken } = useSelector((state) => state.auth);
  
  const [step, setStep] = useState(1); // 1: Email, 2: Reset
  const [email, setEmail] = useState("");
  const [token, setToken] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [successMessage, setSuccessMessage] = useState("");

  const handleForgotPassword = async (e) => {
    e.preventDefault();
    dispatch(clearError());
    const result = await dispatch(forgotPassword({ email }));
    if (forgotPassword.fulfilled.match(result)) {
      setStep(2);
      // In development, the token is returned in the response as dev_only_reset_token
      if (result.payload.dev_only_reset_token) {
        setToken(result.payload.dev_only_reset_token);
      }
    }
  };

  const handleResetPassword = async (e) => {
    e.preventDefault();
    dispatch(clearError());
    if (newPassword !== confirmPassword) {
      return; // Should show error UI
    }
    const result = await dispatch(resetPassword({ token, new_password: newPassword, confirm_password: confirmPassword }));
    if (resetPassword.fulfilled.match(result)) {
      setSuccessMessage("Password reset successfully! Redirecting to login...");
      setTimeout(() => navigate("/login"), 3000);
    }
  };

  return (
    <div className="min-h-screen flex bg-white font-sans">
      {/* Left side: branding (Common with Login) */}
      <div className="hidden lg:flex lg:w-[45%] bg-[#0f172a] p-16 text-white flex-col justify-between relative overflow-hidden">
        <div 
          className="absolute inset-0 opacity-10" 
          style={{ 
            backgroundImage: `linear-gradient(#ffffff 1px, transparent 1px), linear-gradient(90deg, #ffffff 1px, transparent 1px)`,
            backgroundSize: '40px 40px' 
          }} 
        />
        
        <div className="relative z-10">
          <div className="w-14 h-14 bg-blue-600 rounded-2xl flex items-center justify-center mb-10 shadow-lg shadow-blue-600/20">
            <HardHat size={32} className="text-white" />
          </div>
          
          <h1 className="text-5xl font-bold mb-6 tracking-tight">VDTI Service Hub</h1>
          <p className="text-blue-200/80 text-xl mb-16 leading-relaxed max-w-md">
            Internal Service Management System for Vacuum Drying Technology India LLP
          </p>
          
          <div className="space-y-10">
            {[
              { title: "Secure Access", desc: "Multi-factor authentication and role-based access control for your data" },
              { title: "Data Recovery", desc: "Easily recover access to your account with secure password reset" },
              { title: "24/7 Support", desc: "Contact IT support if you face any issues accessing the service hub" }
            ].map((item, i) => (
              <div key={i} className="flex gap-5">
                <div className="mt-1 text-blue-500 bg-blue-500/10 p-1.5 rounded-lg h-fit">
                  <CheckCircle2 size={24} />
                </div>
                <div>
                  <h3 className="text-xl font-semibold mb-1.5">{item.title}</h3>
                  <p className="text-blue-200/60 leading-relaxed">{item.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="relative z-10 text-blue-300/40 text-sm">
          © 2024 Vacuum Drying Technology India LLP. All rights reserved.
        </div>
      </div>

      {/* Right side: forgot password form */}
      <div className="w-full lg:w-[55%] flex items-center justify-center p-6 bg-gray-50/50">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="w-full max-w-[480px] bg-white rounded-[32px] p-10 shadow-xl shadow-gray-200/50 border border-gray-100"
        >
          <div className="mb-8">
            <Link to="/login" className="inline-flex items-center gap-2 text-sm font-semibold text-gray-500 hover:text-blue-600 transition-colors">
              <ArrowLeft size={16} />
              Back to Sign In
            </Link>
          </div>

          <div className="text-center mb-10">
            <h2 className="text-3xl font-bold text-gray-900 mb-2">
              {step === 1 ? "Forgot Password?" : "Reset Password"}
            </h2>
            <p className="text-gray-500">
              {step === 1 
                ? "Enter your email address and we'll send you a reset token." 
                : "Enter the reset token and your new password below."}
            </p>
          </div>

          {successMessage ? (
            <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} className="text-green-600 text-sm bg-green-50 p-6 rounded-2xl border border-green-100 flex flex-col items-center text-center gap-4">
              <div className="w-12 h-12 rounded-full bg-green-100 flex items-center justify-center text-green-600">
                <ShieldCheck size={28} />
              </div>
              <p className="font-semibold">{successMessage}</p>
            </motion.div>
          ) : (
            <>
              {step === 1 ? (
                <form onSubmit={handleForgotPassword} className="space-y-6">
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2">Email Address</label>
                    <div className="relative">
                      <input
                        type="email"
                        value={email}
                        onChange={e => setEmail(e.target.value)}
                        placeholder="you@vdti.com"
                        required
                        className="w-full px-5 py-3.5 pl-12 rounded-xl bg-gray-50 border border-gray-200 text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
                      />
                      <div className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400">
                        <Mail size={18} />
                      </div>
                    </div>
                  </div>

                  {error && (
                    <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} className="text-red-600 text-sm bg-red-50 p-4 rounded-xl border border-red-100 flex items-center gap-3">
                      <div className="w-1.5 h-1.5 rounded-full bg-red-600" />
                      {error}
                    </motion.div>
                  )}

                  <motion.button
                    whileTap={{ scale: 0.98 }}
                    type="submit"
                    disabled={loading}
                    className="w-full py-4 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-bold text-base transition-all shadow-lg shadow-blue-600/20 disabled:opacity-70"
                  >
                    {loading ? "Sending..." : "Send Reset Token"}
                  </motion.button>
                </form>
              ) : (
                <form onSubmit={handleResetPassword} className="space-y-6">
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2">Reset Token</label>
                    <div className="relative">
                      <input
                        type="text"
                        value={token}
                        onChange={e => setToken(e.target.value)}
                        placeholder="Paste your token here"
                        required
                        className="w-full px-5 py-3.5 pl-12 rounded-xl bg-gray-50 border border-gray-200 text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
                      />
                      <div className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400">
                        <Key size={18} />
                      </div>
                    </div>
                    {devToken && (
                      <p className="mt-2 text-[10px] text-blue-600 bg-blue-50 p-2 rounded-lg border border-blue-100">
                        Dev Token: <span className="font-mono">{devToken}</span>
                      </p>
                    )}
                  </div>

                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2">New Password</label>
                    <input
                      type="password"
                      value={newPassword}
                      onChange={e => setNewPassword(e.target.value)}
                      placeholder="••••••••"
                      required
                      className="w-full px-5 py-3.5 rounded-xl bg-gray-50 border border-gray-200 text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2">Confirm Password</label>
                    <input
                      type="password"
                      value={confirmPassword}
                      onChange={e => setConfirmPassword(e.target.value)}
                      placeholder="••••••••"
                      required
                      className="w-full px-5 py-3.5 rounded-xl bg-gray-50 border border-gray-200 text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
                    />
                  </div>

                  {newPassword !== confirmPassword && confirmPassword !== "" && (
                    <p className="text-red-600 text-xs">Passwords do not match</p>
                  )}

                  {error && (
                    <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} className="text-red-600 text-sm bg-red-50 p-4 rounded-xl border border-red-100 flex items-center gap-3">
                      <div className="w-1.5 h-1.5 rounded-full bg-red-600" />
                      {error}
                    </motion.div>
                  )}

                  <motion.button
                    whileTap={{ scale: 0.98 }}
                    type="submit"
                    disabled={loading || newPassword !== confirmPassword}
                    className="w-full py-4 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-bold text-base transition-all shadow-lg shadow-blue-600/20 disabled:opacity-70"
                  >
                    {loading ? "Resetting..." : "Reset Password"}
                  </motion.button>
                </form>
              )}
            </>
          )}
        </motion.div>
      </div>
    </div>
  );
}
