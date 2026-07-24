import { useState, useEffect } from 'react';
import { fetchAPI } from '../../services/api';
import KPICard from '../../components/reports/KPICard';
import DateRangeFilter from '../../components/reports/DateRangeFilter';
import ExportButton from '../../components/reports/ExportButton';
import ReportGuard from '../../components/reports/ReportGuard';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from 'recharts';
import { BedDouble, TrendingUp, CalendarCheck } from 'lucide-react';

const COLORS = ['#059669', '#3B82F6', '#F59E0B', '#EF4444', '#8B5CF6', '#EC4899'];

function OccupancyReportInner() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filters, setFilters] = useState({ startDate: '', endDate: '' });
  const [propertyId, setPropertyId] = useState('');

  const loadReport = async () => {
    if (!propertyId || !filters.startDate || !filters.endDate) { setLoading(false); return; }
    setLoading(true);
    try {
      const res = await fetchAPI(`/reports/occupancy?property_id=${propertyId}&start_date=${filters.startDate}&end_date=${filters.endDate}`);
      setData(res);
    } catch (err) { setError(err.message); } finally { setLoading(false); }
  };

  useEffect(() => { loadReport(); }, [filters, propertyId]);

  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-slate-800">Occupancy Report</h1>
          <p className="text-slate-500 text-sm mt-1">Room occupancy analysis</p>
        </div>
        <ExportButton reportType="occupancy" params={{ property_id: propertyId, start_date: filters.startDate, end_date: filters.endDate }} />
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
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <KPICard icon={<BedDouble className="w-5 h-5" />} label="Avg Occupancy" value={`${data.avg_occupancy_pct}%`} color="emerald" />
            <KPICard icon={<BedDouble className="w-5 h-5" />} label="Occupied Room-Nights" value={data.occupied_room_nights} color="blue" subtext={`of ${data.available_room_nights} available`} />
            <KPICard icon={<CalendarCheck className="w-5 h-5" />} label="Reserved Today" value={data.reserved_rooms_today} color="indigo" />
            <KPICard icon={<TrendingUp className="w-5 h-5" />} label="Total Rooms" value={data.total_rooms} color="purple" />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {data.daily_occupancy && data.daily_occupancy.length > 0 && (
              <div className="bg-white rounded-xl border border-slate-100 shadow-sm p-6">
                <h3 className="text-lg font-semibold text-slate-800 mb-4">Occupancy Trend</h3>
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={data.daily_occupancy}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" />
                    <XAxis dataKey="date" tick={{ fontSize: 11 }} />
                    <YAxis tick={{ fontSize: 11 }} />
                    <Tooltip />
                    <Line type="monotone" dataKey="pct" stroke="#059669" strokeWidth={2} name="Occupancy %" dot={false} />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            )}

            {data.by_room_type && data.by_room_type.length > 0 && (
              <div className="bg-white rounded-xl border border-slate-100 shadow-sm p-6">
                <h3 className="text-lg font-semibold text-slate-800 mb-4">By Room Type</h3>
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie data={data.by_room_type} dataKey="count" nameKey="room_type" cx="50%" cy="50%" outerRadius={100} label>
                      {data.by_room_type.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                    </Pie>
                    <Tooltip />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            )}
          </div>

          {data.by_room_type && data.by_room_type.length > 0 && (
            <div className="bg-white rounded-xl border border-slate-100 shadow-sm p-6">
              <h3 className="text-lg font-semibold text-slate-800 mb-4">Room Type Breakdown</h3>
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b border-slate-100 text-sm font-medium text-slate-500">
                    <th className="py-3 px-4">Room Type</th>
                    <th className="py-3 px-4 text-right">Count</th>
                    <th className="py-3 px-4 text-right">Occupancy %</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {data.by_room_type.map((t, i) => (
                    <tr key={i} className="hover:bg-slate-50">
                      <td className="py-3 px-4 font-medium text-slate-700">{t.room_type}</td>
                      <td className="py-3 px-4 text-right text-slate-600">{t.count}</td>
                      <td className="py-3 px-4 text-right text-slate-600">{t.occupancy_pct}%</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </>
      )}
    </div>
  );
}

export default function OccupancyReport() {
  return <ReportGuard reportType="occupancy"><OccupancyReportInner /></ReportGuard>;
}
