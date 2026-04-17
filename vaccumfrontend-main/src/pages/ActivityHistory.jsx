import { motion } from "framer-motion";
import { History, Briefcase, Users, DollarSign, ShieldCheck, FileText, UserCog } from "lucide-react";
import { useApp } from "../context/AppContext";
import { PageTransition, Card, SectionHeader, EmptyState } from "../components/ui";

const TYPE_ICONS = {
  job: { icon: Briefcase, color: "bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400" },
  client: { icon: Users, color: "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400" },
  quotation: { icon: DollarSign, color: "bg-amber-100 dark:bg-amber-900/30 text-amber-600 dark:text-amber-400" },
  amc: { icon: ShieldCheck, color: "bg-purple-100 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400" },
  report: { icon: FileText, color: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400" },
  technician: { icon: UserCog, color: "bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400" },
};

export default function ActivityHistory() {
  const { activityLog, searchQuery, jobs, clients, technicians, quotations, amcContracts } = useApp();

  // Global search results
  const hasSearch = searchQuery.length > 1;
  const q = searchQuery.toLowerCase();

  const searchResults = hasSearch ? [
    ...jobs.filter(j => j.id.toLowerCase().includes(q) || j.title.toLowerCase().includes(q)).map(j => ({ type: "job", label: j.id, detail: j.title, sub: j.status })),
    ...clients.filter(c => c.name.toLowerCase().includes(q) || c.contact.toLowerCase().includes(q)).map(c => ({ type: "client", label: c.name, detail: c.contact, sub: c.type })),
    ...technicians.filter(t => t.name.toLowerCase().includes(q) || t.specialization.toLowerCase().includes(q)).map(t => ({ type: "technician", label: t.name, detail: t.specialization, sub: t.status })),
    ...quotations.filter(qt => qt.id.toLowerCase().includes(q) || qt.title.toLowerCase().includes(q)).map(qt => ({ type: "quotation", label: qt.id, detail: qt.title, sub: qt.status })),
    ...amcContracts.filter(a => a.id.toLowerCase().includes(q) || a.title.toLowerCase().includes(q)).map(a => ({ type: "amc", label: a.id, detail: a.title, sub: a.status })),
  ] : [];

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-4xl mx-auto">
        <SectionHeader title={hasSearch ? `Search Results` : "Activity History"} subtitle={hasSearch ? `${searchResults.length} results for "${searchQuery}"` : `${activityLog.length} recent activities`} />

        {/* Search Results */}
        {hasSearch && (
          <div className="mb-8">
            {searchResults.length === 0 ? (
              <EmptyState icon={History} title="No results found" description={`No matches for "${searchQuery}"`} />
            ) : (
              <div className="space-y-2">
                {searchResults.map((r, i) => {
                  const { icon: Icon, color } = TYPE_ICONS[r.type] || TYPE_ICONS.report;
                  return (
                    <motion.div key={i} initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: i * 0.04 }}>
                      <Card className="p-4 flex items-center gap-4">
                        <div className={`p-2 rounded-xl ${color}`}><Icon size={18} /></div>
                        <div className="flex-1">
                          <p className="font-semibold text-gray-800 dark:text-gray-200 text-sm">{r.label}</p>
                          <p className="text-xs text-gray-500 dark:text-gray-400">{r.detail}</p>
                        </div>
                        <span className="text-xs bg-gray-100 dark:bg-gray-700 text-gray-500 dark:text-gray-400 px-2.5 py-1 rounded-full capitalize font-medium">{r.type}</span>
                        <span className="text-xs text-gray-400">{r.sub}</span>
                      </Card>
                    </motion.div>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {/* Activity Feed */}
        {!hasSearch && (
          <Card className="p-5">
            <div className="relative">
              {/* Timeline line */}
              <div className="absolute left-6 top-0 bottom-0 w-px bg-gray-100 dark:bg-gray-700" />
              <div className="space-y-1">
                {activityLog.map((log, i) => {
                  const { icon: Icon, color } = TYPE_ICONS[log.type] || TYPE_ICONS.report;
                  return (
                    <motion.div key={log.id} initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: i * 0.04 }}
                      className="flex gap-4 py-3 relative">
                      <div className={`w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0 relative z-10 ${color}`}>
                        <Icon size={18} />
                      </div>
                      <div className="flex-1 min-w-0 pt-2">
                        <p className="text-sm font-medium text-gray-800 dark:text-gray-200">{log.action}</p>
                        <div className="flex items-center gap-2 mt-0.5">
                          <span className="text-xs text-blue-600 dark:text-blue-400 font-semibold">{log.user}</span>
                          <span className="text-xs text-gray-400">·</span>
                          <span className="text-xs text-gray-400">{log.timestamp}</span>
                        </div>
                      </div>
                      <div className={`self-start mt-2 text-xs px-2 py-0.5 rounded-full capitalize font-medium border ${
                        log.type === "job" ? "border-blue-200 text-blue-600 bg-blue-50 dark:border-blue-800 dark:bg-blue-900/20 dark:text-blue-400" :
                        log.type === "client" ? "border-emerald-200 text-emerald-600 bg-emerald-50 dark:border-emerald-800 dark:bg-emerald-900/20 dark:text-emerald-400" :
                        "border-gray-200 text-gray-500 bg-gray-50 dark:border-gray-700 dark:bg-gray-700 dark:text-gray-400"
                      }`}>{log.type}</div>
                    </motion.div>
                  );
                })}
              </div>
            </div>
          </Card>
        )}
      </div>
    </PageTransition>
  );
}
