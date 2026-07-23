import { useState, useEffect } from 'react';
import { fetchAPI } from '../../services/api';
import KPICard from '../../components/reports/KPICard';
import ExportButton from '../../components/reports/ExportButton';
import ReportGuard from '../../components/reports/ReportGuard';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { Calendar, TrendingUp, BedDouble, IndianRupee, Receipt, ArrowUpRight, ArrowDownRight } from 'lucide-react';

function MonthlyReportInner() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const now = new Date();
  const [month, setMonth] = useState(now.getMonth() + 1);
  const [year, setYear] = useState(now.getFullYear());
  const [propertyId, setPropertyId] = useState('');

  useEffect(() => { loadReport(); }, [month, year, propertyId]);

  const loadReport = async () => {
    if (!propertyId) { setLoading(false); return; }
    setLoading(true);
    try {
      const res = await fetchAPI(`/reports/monthly?property_id=${propertyId}&month=${month}&year=${year}`);
      setData(res);
    } catch (err) { setError(err.message); } finally { setLoading(false); }
  };

  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-slate-800">Monthly Report</h1>
          <p className="text-slate-500 text-sm mt-1">Monthly performance overview</p>
        </div>
        <ExportButton reportType="monthly" params={{ property_id: propertyId, month, year }} />
      </div>

      <div className="flex flex-wrap items-end gap-3 bg-white p-4 rounded-xl border border-slate-100 shadow-sm">
        <div>
          <label className="block text-xs font-medium text-slate-500 mb-1">Month</label>
          <select value={month} onChange={(e) => setMonth(Number(e.target.value))} className="saas-input text-sm">
            {Array.from({ length: 12 }, (_, i) => <option key={i + 1} value={i + 1}>{new Date(0, i).toLocaleString('default', { month: 'long' })}</option>)}
          </select>
        </div>
        <div>
          <label className="block text-xs font-medium text-slate-500 mb-1">Year</label>
          <select value={year} onChange={(e) => setYear(Number(e.target.value))} className="saas-input text-sm">
            {[2024, 2025, 2026, 2027].map(y => <option key={y} value={y}>{y}</option>)}
          </select>
        </div>
        <div>
          <label className="block text-xs font-medium text-slate-500 mb-1">Property ID</label>
          <input type="text" value={propertyId} onChange={(e) => setPropertyId(e.target.value)} placeholder="Enter property ID" className="saas-input text-sm" />
        </div>
      </div>

      {loading && <div className="flex justify-center py-12"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-500" /></div>}
      {error && <div className="bg-red-50 border border-red-200 rounded-xl p-4 text-red-600 text-sm">{error}</div>}

      {data && (
        <>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <KPICard icon={<Calendar className="w-5 h-5" />} label="Total Bookings" value={data.total_bookings} color="blue" />
            <KPICard icon={<BedDouble className="w-5 h-5" />} label="Occupancy" value={`${data.occupancy_pct}%`} color="emerald" />
            <KPICard icon={<IndianRupee className="w-5 h-5" />} label="Total Revenue" value={`₹${data.total_revenue?.toLocaleString()}`} color="indigo" />
            <KPICard icon={<Receipt className="w-5 h-5" />} label="Total Expenses" value={`₹${data.total_expenses?.toLocaleString()}`} color="red" />
            <KPICard
              icon={data.revenue_growth_pct >= 0 ? <ArrowUpRight className="w-5 h-5" /> : <ArrowDownRight className="w-5 h-5" />}
              label="Revenue Growth"
              value={`${data.revenue_growth_pct}%`}
              color={data.revenue_growth_pct >= 0 ? 'emerald' : 'red'}
              subtext="vs previous month"
            />
            <KPICard icon={<IndianRupee className="w-5 h-5" />} label="Outstanding" value={`₹${data.total_outstanding?.toLocaleString()}`} color="amber" />
          </div>

          {data.daily_revenue_trend && data.daily_revenue_trend.length > 0 && (
            <div className="bg-white rounded-xl border border-slate-100 shadow-sm p-6">
              <h3 className="text-lg font-semibold text-slate-800 mb-4 flex items-center gap-2">
                <TrendingUp className="w-5 h-5 text-slate-400" /> Daily Revenue Trend
              </h3>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={data.daily_revenue_trend}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" />
                  <XAxis dataKey="date" tick={{ fontSize: 12 }} />
                  <YAxis tick={{ fontSize: 12 }} />
                  <Tooltip formatter={(val) => [`₹${val.toLocaleString()}`, 'Revenue']} />
                  <Line type="monotone" dataKey="revenue" stroke="#059669" strokeWidth={2} dot={false} />
                </LineChart>
              </ResponsiveContainer>
            </div>
          )}
        </>
      )}
    </div>
  );
}

export default function MonthlyReport() {
  return <ReportGuard reportType="monthly"><MonthlyReportInner /></ReportGuard>;
}
