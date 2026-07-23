import { useState, useEffect } from 'react';
import { fetchAPI } from '../../services/api';
import KPICard from '../../components/reports/KPICard';
import DateRangeFilter from '../../components/reports/DateRangeFilter';
import ExportButton from '../../components/reports/ExportButton';
import ReportGuard from '../../components/reports/ReportGuard';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { IndianRupee, AlertTriangle, FileText, Clock } from 'lucide-react';

function OutstandingReportInner() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filters, setFilters] = useState({ startDate: '', endDate: '' });
  const [propertyId, setPropertyId] = useState('');

  const loadReport = async () => {
    if (!propertyId || !filters.startDate || !filters.endDate) { setLoading(false); return; }
    setLoading(true);
    try {
      const res = await fetchAPI(`/reports/outstanding?property_id=${propertyId}&start_date=${filters.startDate}&end_date=${filters.endDate}`);
      setData(res);
    } catch (err) { setError(err.message); } finally { setLoading(false); }
  };

  useEffect(() => { loadReport(); }, [filters, propertyId]);

  const ageingData = data?.ageing ? Object.entries(data.ageing).map(([k, v]) => ({ bucket: k, amount: v })) : [];

  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-slate-800">Outstanding Report</h1>
          <p className="text-slate-500 text-sm mt-1">Pending payments and ageing analysis</p>
        </div>
        <ExportButton reportType="outstanding" params={{ property_id: propertyId, start_date: filters.startDate, end_date: filters.endDate }} />
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
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <KPICard icon={<IndianRupee className="w-5 h-5" />} label="Total Outstanding" value={`₹${data.total_outstanding?.toLocaleString()}`} color="red" />
            <KPICard icon={<FileText className="w-5 h-5" />} label="Pending Invoices" value={data.pending_invoices_count} color="amber" />
            <KPICard icon={<Clock className="w-5 h-5" />} label="Overdue Payments" value={data.overdue_count} color="orange" />
          </div>

          {ageingData.length > 0 && (
            <div className="bg-white rounded-xl border border-slate-100 shadow-sm p-6">
              <h3 className="text-lg font-semibold text-slate-800 mb-4 flex items-center gap-2"><AlertTriangle className="w-5 h-5 text-slate-400" /> Ageing Analysis</h3>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={ageingData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" />
                  <XAxis dataKey="bucket" tick={{ fontSize: 12 }} />
                  <YAxis tick={{ fontSize: 12 }} />
                  <Tooltip formatter={(val) => `₹${val.toLocaleString()}`} />
                  <Bar dataKey="amount" fill="#EF4444" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}

          {data.customer_wise?.length > 0 && (
            <div className="bg-white rounded-xl border border-slate-100 shadow-sm p-6">
              <h3 className="text-lg font-semibold text-slate-800 mb-4">Customer-wise Outstanding</h3>
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="border-b border-slate-100 text-sm font-medium text-slate-500">
                      <th className="py-3 px-4">Guest Name</th>
                      <th className="py-3 px-4">Booking Ref</th>
                      <th className="py-3 px-4">Due Date</th>
                      <th className="py-3 px-4 text-right">Amount</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {data.customer_wise.map((c, i) => (
                      <tr key={i} className="hover:bg-slate-50">
                        <td className="py-3 px-4 font-medium text-slate-700">{c.guest_name}</td>
                        <td className="py-3 px-4 text-slate-600 text-sm">{c.booking_ref}</td>
                        <td className="py-3 px-4 text-slate-600 text-sm">{c.due_date}</td>
                        <td className="py-3 px-4 text-right font-medium text-red-600">₹{c.amount?.toLocaleString()}</td>
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

export default function OutstandingReport() {
  return <ReportGuard reportType="outstanding"><OutstandingReportInner /></ReportGuard>;
}
