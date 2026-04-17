import { useState } from "react";
import { motion } from "framer-motion";
import { Shield, Eye, EyeOff, Wrench, CheckCircle2, HardHat, Mail, Phone } from "lucide-react";
import { useDispatch, useSelector } from "react-redux";
import { login, clearError } from "../store/authSlice";
import { Link } from "react-router-dom";

export default function Login() {
  const dispatch = useDispatch();
  const { loading, error } = useSelector((state) => state.auth);
  const [identifier, setIdentifier] = useState("");
  const [password, setPassword] = useState("");
  const [showPass, setShowPass] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    dispatch(clearError());
    
    const isEmail = identifier.includes('@');
    const credentials = isEmail 
      ? { email: identifier, password } 
      : { phone_number: identifier.startsWith('+') ? identifier : `+91${identifier}`, password };
      
    dispatch(login(credentials));
  };

  return (
    <div className="min-h-screen flex bg-white font-sans">
      {/* Left side: branding */}
      <div className="hidden lg:flex lg:w-[45%] bg-[#0f172a] p-16 text-white flex-col justify-between relative overflow-hidden">
        {/* Grid pattern background */}
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
              { title: "Comprehensive Management", desc: "Manage technicians, clients, jobs, and AMC contracts in one place" },
              { title: "Real-time Tracking", desc: "Track job progress, technician attendance, and service reports" },
              { title: "Analytics & Insights", desc: "Powerful reporting and analytics for data-driven decisions" }
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

      {/* Right side: login form */}
      <div className="w-full lg:w-[55%] flex items-center justify-center p-6 bg-gray-50/50">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="w-full max-w-[480px] bg-white rounded-[32px] p-10 shadow-xl shadow-gray-200/50 border border-gray-100"
        >
          <div className="text-center mb-10">
            <h2 className="text-3xl font-bold text-gray-900 mb-2">Welcome Back</h2>
            <p className="text-gray-500">Sign in to access your dashboard</p>
          </div>

          <form onSubmit={handleLogin} className="space-y-6">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">Email or Phone Number</label>
              <div className="relative">
                <input
                  type="text"
                  value={identifier}
                  onChange={e => setIdentifier(e.target.value)}
                  placeholder="email@vdti.com or 9876543210"
                  required
                  className="w-full px-5 py-3.5 pl-12 rounded-xl bg-gray-50 border border-gray-200 text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
                />
                <div className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400">
                  {identifier.includes('@') ? <Mail size={18} /> : (
                    <div className="flex items-center gap-1 font-semibold text-xs text-gray-500">
                      <Phone size={14} />
                      <span>+91</span>
                    </div>
                  )}
                </div>
              </div>
              {!identifier.includes('@') && identifier.length > 0 && (
                <p className="mt-1 text-[10px] text-gray-400 ml-1">Will be sent as +91{identifier}</p>
              )}
            </div>
            
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">Password</label>
              <div className="relative">
                <input
                  type={showPass ? "text" : "password"}
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                  className="w-full px-5 py-3.5 rounded-xl bg-gray-50 border border-gray-200 text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all pr-12"
                />
                <button 
                  type="button" 
                  onClick={() => setShowPass(!showPass)} 
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
                >
                  {showPass ? <EyeOff size={20} /> : <Eye size={20} />}
                </button>
              </div>
            </div>

            <div className="flex items-center justify-between">
              <label className="flex items-center gap-2 cursor-pointer group">
                <input 
                  type="checkbox" 
                  checked={rememberMe}
                  onChange={e => setRememberMe(e.target.checked)}
                  className="w-4 h-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500" 
                />
                <span className="text-sm text-gray-600 group-hover:text-gray-900 transition-colors">Remember me</span>
              </label>
              <Link to="/forgot-password" size="sm" className="text-sm font-semibold text-blue-600 hover:text-blue-700 transition-colors">
                Forgot password?
              </Link>
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
              {loading ? (
                <div className="flex items-center justify-center gap-2">
                  <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  <span>Signing in...</span>
                </div>
              ) : "Sign In"}
            </motion.button>
          </form>
        </motion.div>
      </div>
    </div>
  );
}
