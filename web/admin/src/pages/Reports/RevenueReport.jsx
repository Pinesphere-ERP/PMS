import { useState, useEffect } from 'react';
import { fetchAPI } from '../../services/api';
import KPICard from '../../components/reports/KPICard';
import DateRangeFilter from '../../components/reports/DateRangeFilter';
import ExportButton from '../../components/reports/ExportButton';
import ReportGuard from '../../components/reports/ReportGuard';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend, BarChart, Bar } from 'recharts';
import { IndianRupee, TrendingUp, Receipt, Tags } from 'lucide-react';

const COLORS = ['#059669', '#3B82F6', '#F59E0B', '#EF4444', '#8B5CF6', '#EC4899', '#06B6D4'];

function RevenueReportInner() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filters, setFilters] = useState({ startDate: '', endDate: '' });
  const [propertyId, setPropertyId] = useState('');

  const loadReport = async () => {
    if (!propertyId || !filters.startDate || !filters.endDate) { setLoading(false); return; }
    setLoading(true);
    try {
      const res = await fetchAPI(`/reports/revenue?property_id=${propertyId}&start_date=${filters.startDate}&end_date=${filters.endDate}`);
      setData(res);
    } catch (err) { setError(err.message); } finally { setLoading(false); }
  };

  useEffect(() => { loadReport(); }, [filters, propertyId]);

  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-slate-800">Revenue Report</h1>
          <p className="text-slate-500 text-sm mt-1">Revenue breakdown and trends</p>
        </div>
        <ExportButton reportType="revenue" params={{ property_id: propertyId, start_date: filters.startDate, end_date: filters.endDate }} />
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
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <KPICard icon={<IndianRupee className="w-5 h-5" />} label="Total Revenue" value={`₹${data.total_revenue?.toLocaleString()}`} color="emerald" />
            <KPICard icon={<Receipt className="w-5 h-5" />} label="Taxes Collected" value={`₹${data.taxes_collected?.toLocaleString()}`} color="blue" />
            <KPICard icon={<Tags className="w-5 h-5" />} label="Discounts Given" value={`₹${data.discounts_given?.toLocaleString()}`} color="amber" />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {data.daily_revenue_trend?.length > 0 && (
              <div className="bg-white rounded-xl border border-slate-100 shadow-sm p-6">
                <h3 className="text-lg font-semibold text-slate-800 mb-4 flex items-center gap-2"><TrendingUp className="w-5 h-5 text-slate-400" /> Daily Revenue Trend</h3>
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={data.daily_revenue_trend}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" />
                    <XAxis dataKey="date" tick={{ fontSize: 11 }} />
                    <YAxis tick={{ fontSize: 11 }} />
                    <Tooltip formatter={(val) => [`₹${val.toLocaleString()}`, 'Revenue']} />
                    <Line type="monotone" dataKey="revenue" stroke="#059669" strokeWidth={2} dot={false} />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            )}

            {data.by_payment_method?.length > 0 && (
              <div className="bg-white rounded-xl border border-slate-100 shadow-sm p-6">
                <h3 className="text-lg font-semibold text-slate-800 mb-4">Revenue by Payment Method</h3>
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie data={data.by_payment_method} dataKey="revenue" nameKey="method" cx="50%" cy="50%" outerRadius={100} label>
                      {data.by_payment_method.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                    </Pie>
                    <Tooltip formatter={(val) => `₹${val.toLocaleString()}`} />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            )}
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {data.by_room_type?.length > 0 && (
              <div className="bg-white rounded-xl border border-slate-100 shadow-sm p-6">
                <h3 className="text-lg font-semibold text-slate-800 mb-4">Revenue by Room Type</h3>
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={data.by_room_type}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" />
                    <XAxis dataKey="room_type" tick={{ fontSize: 11 }} />
                    <YAxis tick={{ fontSize: 11 }} />
                    <Tooltip formatter={(val) => `₹${val.toLocaleString()}`} />
                    <Bar dataKey="revenue" fill="#059669" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}

            {data.by_booking_source?.length > 0 && (
              <div className="bg-white rounded-xl border border-slate-100 shadow-sm p-6">
                <h3 className="text-lg font-semibold text-slate-800 mb-4">Revenue by Booking Source</h3>
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie data={data.by_booking_source} dataKey="revenue" nameKey="source" cx="50%" cy="50%" outerRadius={100} label>
                      {data.by_booking_source.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                    </Pie>
                    <Tooltip formatter={(val) => `₹${val.toLocaleString()}`} />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            )}
          </div>
        </>
      )}
    </div>
  );
}

export default function RevenueReport() {
  return <ReportGuard reportType="revenue"><RevenueReportInner /></ReportGuard>;
}
