import { useState, useEffect } from 'react';
import { fetchAPI } from '../../services/api';
import KPICard from '../../components/reports/KPICard';
import DateRangeFilter from '../../components/reports/DateRangeFilter';
import ExportButton from '../../components/reports/ExportButton';
import ReportGuard from '../../components/reports/ReportGuard';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { Users, CheckCircle, Clock, Home, CalendarCheck } from 'lucide-react';

function StaffPerformanceInner() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filters, setFilters] = useState({ startDate: '', endDate: '' });
  const [propertyId, setPropertyId] = useState('');

  const loadReport = async () => {
    if (!propertyId || !filters.startDate || !filters.endDate) { setLoading(false); return; }
    setLoading(true);
    try {
      const res = await fetchAPI(`/reports/staff-performance?property_id=${propertyId}&start_date=${filters.startDate}&end_date=${filters.endDate}`);
      setData(res);
    } catch (err) { setError(err.message); } finally { setLoading(false); }
  };

  useEffect(() => { loadReport(); }, [filters, propertyId]);

  const chartData = data?.staff?.map(s => ({ name: s.staff_name, completed: s.tasks_completed, pending: s.tasks_pending })) || [];

  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-slate-800">Staff Performance</h1>
          <p className="text-slate-500 text-sm mt-1">Task completion and productivity metrics</p>
        </div>
        <ExportButton reportType="staff_performance" params={{ property_id: propertyId, start_date: filters.startDate, end_date: filters.endDate }} />
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
            <KPICard icon={<CheckCircle className="w-5 h-5" />} label="Tasks Completed" value={data.total_tasks_completed} color="emerald" />
            <KPICard icon={<Clock className="w-5 h-5" />} label="Tasks Pending" value={data.total_tasks_pending} color="amber" />
            <KPICard icon={<Users className="w-5 h-5" />} label="Staff Members" value={data.staff?.length || 0} color="blue" />
            <KPICard icon={<Home className="w-5 h-5" />} label="HK Tasks" value={data.staff?.reduce((a, s) => a + (s.housekeeping_tasks || 0), 0)} color="purple" />
          </div>

          {chartData.length > 0 && (
            <div className="bg-white rounded-xl border border-slate-100 shadow-sm p-6">
              <h3 className="text-lg font-semibold text-slate-800 mb-4">Tasks by Staff Member</h3>
              <ResponsiveContainer width="100%" height={350}>
                <BarChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" />
                  <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                  <YAxis tick={{ fontSize: 11 }} />
                  <Tooltip />
                  <Bar dataKey="completed" fill="#059669" radius={[4, 4, 0, 0]} name="Completed" />
                  <Bar dataKey="pending" fill="#F59E0B" radius={[4, 4, 0, 0]} name="Pending" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}

          {data.staff?.length > 0 && (
            <div className="bg-white rounded-xl border border-slate-100 shadow-sm p-6">
              <h3 className="text-lg font-semibold text-slate-800 mb-4">Staff Details</h3>
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="border-b border-slate-100 text-sm font-medium text-slate-500">
                      <th className="py-3 px-4">Staff Name</th>
                      <th className="py-3 px-4">Role</th>
                      <th className="py-3 px-4 text-right">Completed</th>
                      <th className="py-3 px-4 text-right">Pending</th>
                      <th className="py-3 px-4 text-right">HK Tasks</th>
                      <th className="py-3 px-4 text-right">Bookings</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {data.staff.map((s, i) => (
                      <tr key={i} className="hover:bg-slate-50">
                        <td className="py-3 px-4 font-medium text-slate-700">{s.staff_name}</td>
                        <td className="py-3 px-4 text-slate-600">
                          <span className="px-2 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-700">{s.role}</span>
                        </td>
                        <td className="py-3 px-4 text-right text-emerald-600 font-medium">{s.tasks_completed}</td>
                        <td className="py-3 px-4 text-right text-amber-600 font-medium">{s.tasks_pending}</td>
                        <td className="py-3 px-4 text-right text-slate-600">{s.housekeeping_tasks}</td>
                        <td className="py-3 px-4 text-right text-slate-600">{s.bookings_handled}</td>
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

export default function StaffPerformance() {
  return <ReportGuard reportType="staff_performance"><StaffPerformanceInner /></ReportGuard>;
}
