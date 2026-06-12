import { useState, useEffect, useCallback } from "react";
import { motion } from "framer-motion";
import { Plus, DollarSign, Trash2, Check, X, FileText, Search, Filter, Calendar as CalendarIcon, ChevronLeft, ChevronRight } from "lucide-react";
import { useApp } from "../context/AppContext";
import { PageTransition, Card, Badge, Button, Modal, Input, Select, DatePicker, SectionHeader, EmptyState, useToast, Toast, PageLoader } from "../components/ui";
import axios from "axios";

const API_BASE_URL = 'https://vaccumapi-o4ol.onrender.com/api';

export default function Quotations() {
  const { clients, currentUser } = useApp();
  const { toast, showToast } = useToast();
  
  if (currentUser?.role?.toLowerCase() !== "admin") {
    return (
      <PageTransition>
        <div className="p-4 md:p-6 max-w-7xl mx-auto flex flex-col items-center justify-center min-h-[60vh]">
          <div className="bg-red-50 dark:bg-red-900/20 p-6 rounded-2xl text-center max-w-md">
            <X size={48} className="text-red-500 mx-auto mb-4" />
            <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-2">Access Denied</h2>
            <p className="text-gray-500 dark:text-gray-400">You do not have permission to view this page. This page is restricted to administrators only.</p>
          </div>
        </div>
      </PageTransition>
    );
  }

  const [detailQ, setDetailQ] = useState(null);
  const canEdit = currentUser?.role?.toLowerCase() === "admin";

  // ERP API State
  const [erpQuotations, setErpQuotations] = useState([]);
  const [loading, setLoading] = useState(false);
  const [totalCount, setTotalCount] = useState(0);
  const [filters, setFilters] = useState({
    page: 1,
    limit: 10,
    status: "",
    from_date: "",
    to_date: "",
    search: "",
  });
  const [debouncedSearch, setDebouncedSearch] = useState("");

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearch(filters.search);
    }, 500);
    return () => clearTimeout(timer);
  }, [filters.search]);

  const fetchErpQuotations = useCallback(async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem("token");
      const params = {
        page: filters.page,
        limit: filters.limit,
      };
      if (filters.status) params.status = filters.status;
      if (filters.from_date) params.from_date = filters.from_date;
      if (filters.to_date) params.to_date = filters.to_date;
      if (debouncedSearch) params.search = debouncedSearch;

      const response = await axios.get(`${API_BASE_URL}/erp/quotations`, { 
        params, 
        headers: { Authorization: `Bearer ${token}` } 
      });
      if (response.data.success) {
        const data = response.data.data || [];
        setErpQuotations(data);
        setTotalCount(response.data.count || data.length);
      }
    } catch (error) {
      console.error("Error fetching ERP quotations:", error);
      showToast("Failed to fetch ERP quotations", "error");
    } finally {
      setLoading(false);
    }
  }, [filters.page, filters.limit, filters.status, filters.from_date, filters.to_date, debouncedSearch, showToast]);

  useEffect(() => {
    fetchErpQuotations();
  }, [fetchErpQuotations]);

  const totalPages = Math.ceil(totalCount / filters.limit);

  return (
    <PageTransition>
      <div className="p-4 md:p-6 max-w-7xl mx-auto">
        <SectionHeader
          title="Quotations"
          subtitle={`${totalCount} total quotations from ERP`}
        />

        {/* Filters Bar */}
        <div className="bg-white dark:bg-gray-800 p-4 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 mb-6 space-y-4 md:space-y-0 md:flex md:items-end md:gap-4">
          <div className="flex-1">
            <Input 
              label="Search" 
              placeholder="Search by ID or Customer..." 
              value={filters.search} 
              onChange={e => setFilters(p => ({ ...p, search: e.target.value, page: 1 }))}
            />
          </div>
          <div className="w-full md:w-48">
            <Select 
              label="Status" 
              value={filters.status} 
              onChange={e => setFilters(p => ({ ...p, status: e.target.value, page: 1 }))}
              options={[
                { value: "", label: "All Status" },
                { value: "Draft", label: "Draft" },
                { value: "Confirmed", label: "Confirmed" },
                { value: "Cancelled", label: "Cancelled" }
              ]}
            />
          </div>
          <div className="w-full md:w-48">
            <DatePicker 
              label="From Date" 
              value={filters.from_date} 
              onChange={e => setFilters(p => ({ ...p, from_date: e.target.value, page: 1 }))}
            />
          </div>
          <div className="w-full md:w-48">
            <DatePicker 
              label="To Date" 
              value={filters.to_date} 
              onChange={e => setFilters(p => ({ ...p, to_date: e.target.value, page: 1 }))}
            />
          </div>
          <Button variant="secondary" onClick={() => setFilters({ page: 1, limit: 10, status: "", from_date: "", to_date: "", search: "" })}>
            Reset
          </Button>
        </div>

        {loading ? (
          <div className="py-20 flex justify-center"><PageLoader /></div>
        ) : erpQuotations.length === 0 ? (
          <EmptyState icon={DollarSign} title="No quotations found" description="Try adjusting your filters or create a new one." />
        ) : (
          <>
            <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
              {erpQuotations.map((q, i) => {
                return (
                  <motion.div key={q.QuotId || q.id} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.06 }}>
                    <Card hover className="p-5" onClick={() => setDetailQ(q)}>
                      <div className="flex items-start justify-between mb-2">
                        <div>
                          <p className="font-mono text-xs text-blue-500">{q.QuotNo || q.id}</p>
                          <p className="font-bold text-gray-900 dark:text-white text-sm mt-0.5">{q.CustName || q.customer_name}</p>
                          <p className="text-xs text-gray-500 dark:text-gray-400">{q.ContactNo || `ID: ${q.customer_id}`}</p>
                        </div>
                        <Badge label={q.status || "Confirmed"} />
                      </div>
                      <div className="mt-4 pt-3 border-t border-gray-100 dark:border-gray-700 flex items-center justify-between">
                        <div>
                          <p className="text-xs text-gray-400 mt-0.5">Date: {q.QuotDate || q.date}</p>
                        </div>
                        {canEdit && (q.status === "Draft" || !q.status) && (
                          <div className="flex gap-2" onClick={e => e.stopPropagation()}>
                            <button onClick={() => showToast("ERP actions not implemented", "info")}
                              className="p-2 bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 rounded-lg hover:bg-emerald-100 transition"><Check size={16} /></button>
                          </div>
                        )}
                      </div>
                    </Card>
                  </motion.div>
                );
              })}
            </div>

            {/* Pagination */}
            <div className="mt-8 pt-6 border-t border-gray-100 dark:border-gray-700 flex flex-col sm:flex-row items-center justify-between gap-4">
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Showing <span className="font-semibold text-gray-900 dark:text-white">{(filters.page - 1) * filters.limit + 1}</span> to <span className="font-semibold text-gray-900 dark:text-white">{Math.min(filters.page * filters.limit, totalCount)}</span> of <span className="font-semibold text-gray-900 dark:text-white">{totalCount}</span> results
              </p>
              <div className="flex gap-2">
                <Button 
                  variant="secondary" 
                  size="sm" 
                  disabled={filters.page === 1}
                  onClick={() => setFilters(p => ({ ...p, page: p.page - 1 }))}
                >
                  <ChevronLeft size={16} /> Previous
                </Button>
                <div className="flex gap-1">
                  {[...Array(totalPages)].map((_, i) => {
                    const pageNum = i + 1;
                    // Only show limited page numbers if there are many
                    if (totalPages > 5 && (pageNum < filters.page - 1 || pageNum > filters.page + 1) && pageNum !== 1 && pageNum !== totalPages) {
                      if (pageNum === 2 || pageNum === totalPages - 1) return <span key={pageNum} className="px-2 text-gray-900 dark:text-white">...</span>;
                      return null;
                    }
                    return (
                      <button
                        key={pageNum}
                        onClick={() => setFilters(p => ({ ...p, page: pageNum }))}
                        className={`w-8 h-8 rounded-lg text-sm font-medium transition-all ${filters.page === pageNum ? "bg-blue-600 text-white" : "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600"}`}
                      >
                        {pageNum}
                      </button>
                    );
                  })}
                </div>
                <Button 
                  variant="secondary" 
                  size="sm" 
                  disabled={filters.page === totalPages}
                  onClick={() => setFilters(p => ({ ...p, page: p.page + 1 }))}
                >
                  Next <ChevronRight size={16} />
                </Button>
              </div>
            </div>
          </>
        )}

        {/* Detail Modal (ERP Data) */}
        {detailQ && (
          <Modal isOpen={!!detailQ} onClose={() => setDetailQ(null)} title={`Quotation: ${detailQ.QuotNo || detailQ.id}`} size="lg">
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div><p className="text-xs text-gray-400">ID</p><p className="font-mono font-semibold text-blue-600">{detailQ.QuotNo || detailQ.id}</p></div>
                <div><p className="text-xs text-gray-400">Status</p><Badge label={detailQ.status || "Confirmed"} /></div>
                <div><p className="text-xs text-gray-400">Customer</p><p className="font-medium text-gray-800 dark:text-gray-200">{detailQ.CustName || detailQ.customer_name} ({detailQ.customer_id || "ERP"})</p></div>
                <div><p className="text-xs text-gray-400">Date</p><p className="font-medium text-gray-800 dark:text-gray-200">{detailQ.QuotDate || detailQ.date}</p></div>
                {detailQ.ContactNo && <div><p className="text-xs text-gray-400">Contact</p><p className="font-medium text-gray-800 dark:text-gray-200">{detailQ.ContactNo}</p></div>}
                {detailQ.Address1 && <div><p className="text-xs text-gray-400">Address</p><p className="font-medium text-gray-800 dark:text-gray-200">{detailQ.Address1}</p></div>}
              </div>
              
              {/* Note: The API example doesn't show items, so we check if they exist */}
              {detailQ.items ? (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead><tr className="border-b border-gray-100 dark:border-gray-700">
                      <th className="text-left py-2 text-xs text-gray-400">Description</th>
                      <th className="text-right py-2 text-xs text-gray-400">Qty</th>
                      <th className="text-right py-2 text-xs text-gray-400">Rate</th>
                      <th className="text-right py-2 text-xs text-gray-400">Total</th>
                    </tr></thead>
                    <tbody>
                      {detailQ.items?.map((item, i) => (
                        <tr key={i} className="border-b border-gray-50 dark:border-gray-700/50">
                          <td className="py-2 text-gray-700 dark:text-gray-300">{item.description}</td>
                          <td className="py-2 text-right text-gray-600 dark:text-gray-400">{item.qty}</td>
                          <td className="py-2 text-right text-gray-600 dark:text-gray-400">₹{Number(item.rate).toLocaleString()}</td>
                          <td className="py-2 text-right font-semibold text-gray-800 dark:text-gray-200">₹{Number(item.total).toLocaleString()}</td>
                        </tr>
                      ))}
                    </tbody>
                    <tfoot><tr>
                      <td colSpan={3} className="pt-3 text-right font-bold text-gray-700 dark:text-gray-300">Grand Total</td>
                      <td className="pt-3 text-right text-xl font-bold text-blue-600 font-display">₹{(detailQ.TotalAmt || detailQ.total_amount || 0).toLocaleString()}</td>
                    </tr></tfoot>
                  </table>
                </div>
              ) : (
                <div className="pt-4 border-t border-gray-100 dark:border-gray-700">
                  {/* <div className="flex justify-between items-center">
                    <p className="font-bold text-gray-700 dark:text-gray-300">Total Amount</p>
                    <p className="text-xl font-bold text-blue-600 font-display">₹{(detailQ.TotalAmt || detailQ.total_amount || 0).toLocaleString()}</p>
                  </div> */}
                </div>
              )}
            </div>
          </Modal>
        )}

        {toast && <Toast {...toast} onClose={() => {}} />}
      </div>
    </PageTransition>
  );
}

