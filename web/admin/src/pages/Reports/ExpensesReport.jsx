import { useState, useEffect } from 'react';
import { fetchAPI } from '../../services/api';
import KPICard from '../../components/reports/KPICard';
import DateRangeFilter from '../../components/reports/DateRangeFilter';
import ExportButton from '../../components/reports/ExportButton';
import ReportGuard from '../../components/reports/ReportGuard';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from 'recharts';
import { IndianRupee, Receipt, TrendingUp } from 'lucide-react';

const COLORS = ['#EF4444', '#F59E0B', '#3B82F6', '#8B5CF6', '#059669', '#EC4899', '#06B6D4'];

function ExpensesReportInner() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filters, setFilters] = useState({ startDate: '', endDate: '' });
  const [propertyId, setPropertyId] = useState('');

  const loadReport = async () => {
    if (!propertyId || !filters.startDate || !filters.endDate) return;
    setLoading(true);
    try {
      const res = await fetchAPI(`/reports/expenses?property_id=${propertyId}&start_date=${filters.startDate}&end_date=${filters.endDate}`);
      setData(res);
    } catch (err) { setError(err.message); } finally { setLoading(false); }
  };

  useEffect(() => { loadReport(); }, [filters, propertyId]);

  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-slate-800">Expenses Report</h1>
          <p className="text-slate-500 text-sm mt-1">Property expense breakdown</p>
        </div>
        <ExportButton reportType="expenses" params={{ property_id: propertyId, start_date: filters.startDate, end_date: filters.endDate }} />
      </div>

      <div className="flex flex-wrap items-end gap-3 bg-white p-4 rounded-xl border border-slate-100 shadow-sm">
        <DateRangeFilter onChange={setFilters} />
        <div>
          <label className="block text-xs font-medium text-slate-500 mb-1">Property ID</label>
          <input type="text" value={propertyId} onChange={(e) => setPropertyId(e.target.value)} placeholder="Enter property ID" className="saas-input text-sm" />
        </div>
      </div>

      {loading && <div className="flex justify-center py-12"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-500" /></div>}
      {error && <div className="bg-red-50 border border-red-200 rounded-xl p-4 text-red-600 text-sm">{error}</div>}

      {data && (
        <>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <KPICard icon={<IndianRupee className="w-5 h-5" />} label="Total Expenses" value={`₹${data.total_expenses?.toLocaleString()}`} color="red" />
            <KPICard icon={<Receipt className="w-5 h-5" />} label="Categories" value={data.by_category?.length || 0} color="blue" />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {data.by_category?.length > 0 && (
              <div className="bg-white rounded-xl border border-slate-100 shadow-sm p-6">
                <h3 className="text-lg font-semibold text-slate-800 mb-4">Expenses by Category</h3>
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie data={data.by_category} dataKey="amount" nameKey="category" cx="50%" cy="50%" outerRadius={100} label>
                      {data.by_category.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                    </Pie>
                    <Tooltip formatter={(val) => `₹${val.toLocaleString()}`} />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            )}

            {data.monthly_trend?.length > 0 && (
              <div className="bg-white rounded-xl border border-slate-100 shadow-sm p-6">
                <h3 className="text-lg font-semibold text-slate-800 mb-4 flex items-center gap-2"><TrendingUp className="w-5 h-5 text-slate-400" /> Monthly Expense Trend</h3>
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={data.monthly_trend}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" />
                    <XAxis dataKey="month" tick={{ fontSize: 11 }} />
                    <YAxis tick={{ fontSize: 11 }} />
                    <Tooltip formatter={(val) => `₹${val.toLocaleString()}`} />
                    <Bar dataKey="amount" fill="#EF4444" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}
          </div>

          {data.recent_expenses?.length > 0 && (
            <div className="bg-white rounded-xl border border-slate-100 shadow-sm p-6">
              <h3 className="text-lg font-semibold text-slate-800 mb-4">Recent Expenses</h3>
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="border-b border-slate-100 text-sm font-medium text-slate-500">
                      <th className="py-3 px-4">Date</th>
                      <th className="py-3 px-4">Category</th>
                      <th className="py-3 px-4">Description</th>
                      <th className="py-3 px-4 text-right">Amount</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {data.recent_expenses.map((e, i) => (
                      <tr key={i} className="hover:bg-slate-50">
                        <td className="py-3 px-4 text-slate-600 text-sm">{e.expense_date}</td>
                        <td className="py-3 px-4 text-slate-600 text-sm">{e.category}</td>
                        <td className="py-3 px-4 text-slate-700">{e.description}</td>
                        <td className="py-3 px-4 text-right font-medium text-red-600">₹{e.amount?.toLocaleString()}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}

export default function ExpensesReport() {
  return <ReportGuard reportType="expenses"><ExpensesReportInner /></ReportGuard>;
}
