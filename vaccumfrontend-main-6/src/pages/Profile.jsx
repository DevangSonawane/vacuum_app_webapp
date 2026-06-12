import { motion } from "framer-motion";
import { User, Mail, Phone, Shield, Calendar, MapPin, Briefcase, Edit2 } from "lucide-react";
import { useSelector } from "react-redux";
import { PageTransition, Card, Button } from "../components/ui";

export default function Profile({ setActivePage }) {
  const { user: currentUser } = useSelector((state) => state.auth);

  if (!currentUser) return null;

  const getInitials = (name) => {
    if (!name) return "";
    const parts = name.trim().split(/\s+/);
    if (parts.length >= 2) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  };

  const infoItems = [
    { label: "Email Address", value: currentUser.email, icon: Mail },
    { label: "Phone Number", value: currentUser.phone_number || "Not provided", icon: Phone },
    { label: "Role", value: currentUser.role, icon: Shield },
    { label: "Joining Date", value: "January 2024", icon: Calendar },
  ];

  return (
    <PageTransition>
      <div className="p-4 md:p-8 w-full mx-auto">
        <div className="mb-8 flex justify-between items-end">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">My Profile</h1>
            <p className="text-gray-500 dark:text-gray-400">View and manage your personal information</p>
          </div>
          <Button 
            variant="outline" 
            size="sm" 
            className="flex items-center gap-2"
            onClick={() => setActivePage("settings")}
          >
            <Edit2 size={14} />
            Edit Profile
          </Button>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <Card className="lg:col-span-1 p-8 flex flex-col items-center text-center">
            <div className="w-32 h-32 rounded-3xl bg-blue-600 flex items-center justify-center text-white text-4xl font-bold mb-6 shadow-xl shadow-blue-600/20">
              {currentUser.avatar || getInitials(currentUser.name || `${currentUser.first_name || ""} ${currentUser.last_name || ""}`)}
            </div>
            <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-1">
              {currentUser.name || `${currentUser.first_name || ""} ${currentUser.last_name || ""}`}
            </h2>
            <p className="text-sm font-semibold text-blue-600 uppercase tracking-wider mb-6">{currentUser.role}</p>
            
            <div className="w-full pt-6 border-t border-gray-100 dark:border-gray-800">
              <div className="flex justify-between text-sm mb-4">
                <span className="text-gray-500">Status</span>
                <span className="flex items-center gap-1.5 text-green-600 font-bold">
                  <div className="w-2 h-2 rounded-full bg-green-600" />
                  Active
                </span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-500">Member since</span>
                <span className="text-gray-900 dark:text-gray-300 font-semibold">2024</span>
              </div>
            </div>
          </Card>

          <Card className="lg:col-span-2 p-8">
            <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-6">Personal Information</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
              {infoItems.map((item, index) => (
                <div key={index}>
                  <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">{item.label}</p>
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-gray-50 dark:bg-gray-800 rounded-lg text-gray-400">
                      <item.icon size={18} />
                    </div>
                    <p className="text-gray-900 dark:text-gray-200 font-semibold">{item.value}</p>
                  </div>
                </div>
              ))}
            </div>
          </Card>
        </div>
      </div>
    </PageTransition>
  );
}
