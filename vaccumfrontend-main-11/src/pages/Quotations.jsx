import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion"; // used in quotation card animations
import { DollarSign, X, ChevronLeft, ChevronRight } from "lucide-react";
import { useApp } from "../context/AppContext";
import { PageTransition, Card, Button, Input, Select, DatePicker, SectionHeader, EmptyState, useToast, Toast } from "../components/ui";
import axios from "axios";

const API_BASE_URL = "https://api.vdtil.com/api";

const PRIORITY_COLORS = {
  High:   "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
  Medium: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400",
  Low:    "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400",
};

const STATUS_COLORS = {
  Approved:  "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
  Open:      "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400",
  Cancelled: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
};

export default function Quotations() {
  const { currentUser } = useApp();
  const { toast, showToast } = useToast();
  const navigate = useNavigate();
  const [quotations, setQuotations]  = useState([]);
  const [loading, setLoading]        = useState(false);
  const [totalCount, setTotalCount]  = useState(0);
  const [filters, setFilters] = useState({
    page: 1, limit: 10,
    status: "", priority: "", category: "",
    from_date: "", to_date: "", search: "",
  });
  const [debouncedSearch, setDebouncedSearch] = useState("");

  useEffect(() => {
    const t = setTimeout(() => setDebouncedSearch(filters.search), 500);
    return () => clearTimeout(t);
  }, [filters.search]);

  const fetchQuotations = useCallback(async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem("token");
      const params = { page: filters.page, limit: filters.limit };
      if (filters.status)    params.status    = filters.status;
      if (filters.priority)  params.priority  = filters.priority;
      if (filters.category)  params.category  = filters.category;
      if (filters.from_date) params.from_date = filters.from_date;
      if (filters.to_date)   params.to_date   = filters.to_date;
      if (debouncedSearch)   params.search    = debouncedSearch;

      const res = await axios.get(`${API_BASE_URL}/erp/local/quotations`, {
        params,
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.data.success) {
        const data = res.data.data || [];
        setQuotations(data);
        const total = res.data.pagination?.total ?? res.data.totalCount ?? res.data.total;
        setTotalCount(total != null ? total : data.length);
      }
    } catch (e) {
      console.error(e);
      showToast("Failed to fetch quotations", "error");
    } finally {
      setLoading(false);
    }
  }, [filters.page, filters.limit, filters.status, filters.priority, filters.category, filters.from_date, filters.to_date, debouncedSearch, showToast]);

  useEffect(() => { fetchQuotations(); }, [fetchQuotations]);

  const totalPages   = Math.max(1, Math.ceil(totalCount / filters.limit));
  const resetFilters = () =>
    setFilters({ page: 1, limit: 10, status: "", priority: "", category: "", from_date: "", to_date: "", search: "" });

  if (currentUser?.role?.toLowerCase() !== "admin") {
    return (
      <PageTransition>
        <div className="p-4 md:p-6 max-w-7xl mx-auto flex flex-col items-center justify-center min-h-[60vh]">
          <div className="bg-red-50 dark:bg-red-900/20 p-6 rounded-2xl text-center max-w-md">
            <X size={48} className="text-red-500 mx-auto mb-4" />
            <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-2">Access Denied</h2>
            <p className="text-gray-500 dark:text-gray-400">This page is restricted to administrators only.</p>
          </div>
        </div>
      </PageTransition>
    );
  }

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-7xl mx-auto">
        <SectionHeader title="Quotations" subtitle={`${totalCount} total quotations`} />

        {/* Filters */}
        <div className="bg-white dark:bg-gray-800 p-4 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 mb-6 flex flex-wrap items-end gap-3">
          <div className="flex-1 min-w-[200px]">
            <Input
              label="Search"
              placeholder="Search by quotation no, customer…"
              value={filters.search}
              onChange={e => setFilters(p => ({ ...p, search: e.target.value, page: 1 }))}
            />
          </div>
          <div className="w-full md:w-36">
            <Select label="Status" value={filters.status}
              onChange={e => setFilters(p => ({ ...p, status: e.target.value, page: 1 }))}
              options={[
                { value: "", label: "All Status" },
                { value: "Open", label: "Open" },
                { value: "Approved", label: "Approved" },
                { value: "Cancelled", label: "Cancelled" },
              ]}
            />
          </div>
          <div className="w-full md:w-36">
            <Select label="Priority" value={filters.priority}
              onChange={e => setFilters(p => ({ ...p, priority: e.target.value, page: 1 }))}
              options={[
                { value: "", label: "All Priority" },
                { value: "High", label: "High" },
                { value: "Medium", label: "Medium" },
                { value: "Low", label: "Low" },
              ]}
            />
          </div>
          <div className="w-full md:w-44">
            <Select label="Category" value={filters.category}
              onChange={e => setFilters(p => ({ ...p, category: e.target.value, page: 1 }))}
              options={[
                { value: "", label: "All Category" },
                { value: "AMC Service", label: "AMC Service" },
                { value: "Spare", label: "Spare" },
                { value: "Accessories", label: "Accessories" },
              ]}
            />
          </div>
          <div className="w-full md:w-40">
            <DatePicker label="From Date" value={filters.from_date}
              onChange={e => setFilters(p => ({ ...p, from_date: e.target.value, page: 1 }))}
            />
          </div>
          <div className="w-full md:w-40">
            <DatePicker label="To Date" value={filters.to_date}
              onChange={e => setFilters(p => ({ ...p, to_date: e.target.value, page: 1 }))}
            />
          </div>
          <Button variant="secondary" onClick={resetFilters}>Reset</Button>
        </div>

        {loading ? (
          <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
            {Array.from({ length: 9 }).map((_, i) => (
              <div key={i} className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 p-5 space-y-3 animate-pulse">
                <div className="flex items-start justify-between gap-2">
                  <div className="space-y-1.5 flex-1">
                    <div className="h-3 w-28 bg-gray-200 dark:bg-gray-700 rounded" />
                    <div className="h-4 w-40 bg-gray-200 dark:bg-gray-700 rounded" />
                    <div className="h-3 w-24 bg-gray-200 dark:bg-gray-700 rounded" />
                  </div>
                  <div className="h-5 w-16 bg-gray-200 dark:bg-gray-700 rounded-full" />
                </div>
                <div className="h-3 w-full bg-gray-200 dark:bg-gray-700 rounded" />
                <div className="h-3 w-3/4 bg-gray-200 dark:bg-gray-700 rounded" />
                <div className="flex gap-2 pt-1">
                  <div className="h-5 w-14 bg-gray-200 dark:bg-gray-700 rounded-full" />
                  <div className="h-5 w-20 bg-gray-200 dark:bg-gray-700 rounded-full" />
                </div>
                <div className="pt-2 border-t border-gray-100 dark:border-gray-700 flex justify-between">
                  <div className="h-3 w-20 bg-gray-200 dark:bg-gray-700 rounded" />
                  <div className="h-4 w-24 bg-gray-200 dark:bg-gray-700 rounded" />
                </div>
              </div>
            ))}
          </div>
        ) : quotations.length === 0 ? (
          <EmptyState icon={DollarSign} title="No quotations found" description="Try adjusting your filters." />
        ) : (
          <>
            <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
              {quotations.map((q, i) => (
                <motion.div key={q.quot_id} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}>
                  <Card hover className="p-5 cursor-pointer" onClick={() => navigate(`/quotations/${q.quot_id}`)}>
                    <div className="flex items-start justify-between gap-2 mb-2">
                      <div className="min-w-0">
                        <p className="font-mono text-xs text-blue-500 mb-0.5">{q.quot_no}</p>
                        <p className="font-bold text-gray-900 dark:text-white text-sm truncate">{q.customer?.name}</p>
                        {q.enquiry_no && <p className="text-xs text-gray-400 mt-0.5">ENQ: {q.enquiry_no}</p>}
                      </div>
                      <span className={`shrink-0 px-2 py-0.5 rounded-full text-xs font-semibold ${STATUS_COLORS[q.quotation_status] || "bg-gray-100 text-gray-600"}`}>
                        {q.quotation_status}
                      </span>
                    </div>

                    {q.subject && (
                      <p className="text-xs text-gray-500 dark:text-gray-400 line-clamp-2 mb-2">{q.subject}</p>
                    )}

                    <div className="flex flex-wrap gap-1.5 mb-3">
                      {q.priority && (
                        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${PRIORITY_COLORS[q.priority] || "bg-gray-100 text-gray-600"}`}>
                          {q.priority}
                        </span>
                      )}
                      {q.category && (
                        <span className="px-2 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400">
                          {q.category}
                        </span>
                      )}
                    </div>

                    <div className="pt-3 border-t border-gray-100 dark:border-gray-700 flex items-center justify-between">
                      <p className="text-xs text-gray-400">{q.date}</p>
                      {q.net_total > 0 && (
                        <p className="text-sm font-bold text-gray-900 dark:text-white">
                          ₹{Number(q.net_total).toLocaleString("en-IN")}
                        </p>
                      )}
                    </div>
                  </Card>
                </motion.div>
              ))}
            </div>

            {/* Pagination */}
            <div className="mt-8 pt-6 border-t border-gray-100 dark:border-gray-700 flex flex-col sm:flex-row items-center justify-between gap-4">
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Showing{" "}
                <span className="font-semibold text-gray-900 dark:text-white">{(filters.page - 1) * filters.limit + 1}</span>
                {" "}to{" "}
                <span className="font-semibold text-gray-900 dark:text-white">{Math.min(filters.page * filters.limit, totalCount)}</span>
                {" "}of{" "}
                <span className="font-semibold text-gray-900 dark:text-white">{totalCount}</span>
              </p>
              <div className="flex gap-2 items-center">
                <Button variant="secondary" size="sm" disabled={filters.page === 1}
                  onClick={() => setFilters(p => ({ ...p, page: p.page - 1 }))}>
                  <ChevronLeft size={16} /> Previous
                </Button>
                <div className="flex gap-1">
                  {[...Array(totalPages)].map((_, i) => {
                    const pg = i + 1;
                    if (totalPages > 7 && Math.abs(pg - filters.page) > 1 && pg !== 1 && pg !== totalPages) {
                      if (pg === 2 || pg === totalPages - 1) return <span key={pg} className="w-8 flex items-center justify-center text-gray-400">…</span>;
                      return null;
                    }
                    return (
                      <button key={pg} onClick={() => setFilters(p => ({ ...p, page: pg }))}
                        className={`w-8 h-8 rounded-lg text-sm font-medium transition-all ${filters.page === pg ? "bg-blue-600 text-white" : "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"}`}>
                        {pg}
                      </button>
                    );
                  })}
                </div>
                <Button variant="secondary" size="sm" disabled={filters.page >= totalPages}
                  onClick={() => setFilters(p => ({ ...p, page: p.page + 1 }))}>
                  Next <ChevronRight size={16} />
                </Button>
              </div>
            </div>
          </>
        )}

        {toast && <Toast {...toast} onClose={() => {}} />}
      </div>
    </PageTransition>
  );
}
