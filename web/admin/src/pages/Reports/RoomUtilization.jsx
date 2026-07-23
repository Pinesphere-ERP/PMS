import { useState, useEffect } from 'react';
import { fetchAPI } from '../../services/api';
import DateRangeFilter from '../../components/reports/DateRangeFilter';
import ExportButton from '../../components/reports/ExportButton';
import ReportGuard from '../../components/reports/ReportGuard';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { BedDouble, TrendingUp, TrendingDown } from 'lucide-react';

function RoomUtilizationInner() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filters, setFilters] = useState({ startDate: '', endDate: '' });
  const [propertyId, setPropertyId] = useState('');

  const loadReport = async () => {
    if (!propertyId || !filters.startDate || !filters.endDate) { setLoading(false); return; }
    setLoading(true);
    try {
      const res = await fetchAPI(`/reports/room-utilization?property_id=${propertyId}&start_date=${filters.startDate}&end_date=${filters.endDate}`);
      setData(res);
    } catch (err) { setError(err.message); } finally { setLoading(false); }
  };

  useEffect(() => { loadReport(); }, [filters, propertyId]);

  const chartData = data?.rooms?.map(r => ({ name: r.room_number, occupancy: r.occupancy_pct, revenue: r.revenue })) || [];

  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-slate-800">Room Utilization</h1>
          <p className="text-slate-500 text-sm mt-1">Performance metrics per room</p>
        </div>
        <ExportButton reportType="room_utilization" params={{ property_id: propertyId, start_date: filters.startDate, end_date: filters.endDate }} />
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
          {data.most_utilized && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="bg-emerald-50 border border-emerald-200 rounded-xl p-5 flex items-center gap-3">
                <TrendingUp className="w-6 h-6 text-emerald-600" />
                <div>
                  <div className="text-sm text-emerald-700 font-medium">Most Utilized</div>
                  <div className="text-xl font-bold text-emerald-800">Room {data.most_utilized}</div>
                </div>
              </div>
              <div className="bg-red-50 border border-red-200 rounded-xl p-5 flex items-center gap-3">
                <TrendingDown className="w-6 h-6 text-red-600" />
                <div>
                  <div className="text-sm text-red-700 font-medium">Least Utilized</div>
                  <div className="text-xl font-bold text-red-800">Room {data.least_utilized || 'N/A'}</div>
                </div>
              </div>
            </div>
          )}

          {chartData.length > 0 && (
            <div className="bg-white rounded-xl border border-slate-100 shadow-sm p-6">
              <h3 className="text-lg font-semibold text-slate-800 mb-4">Occupancy by Room</h3>
              <ResponsiveContainer width="100%" height={350}>
                <BarChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" />
                  <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                  <YAxis tick={{ fontSize: 11 }} />
                  <Tooltip formatter={(val, name) => name === 'occupancy' ? `${val}%` : `₹${val.toLocaleString()}`} />
                  <Bar dataKey="occupancy" fill="#3B82F6" radius={[4, 4, 0, 0]} name="Occupancy %" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}

          {data.rooms?.length > 0 && (
            <div className="bg-white rounded-xl border border-slate-100 shadow-sm p-6">
              <h3 className="text-lg font-semibold text-slate-800 mb-4">Room Details</h3>
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="border-b border-slate-100 text-sm font-medium text-slate-500">
                      <th className="py-3 px-4">Room #</th>
                      <th className="py-3 px-4">Type</th>
                      <th className="py-3 px-4 text-right">Bookings</th>
                      <th className="py-3 px-4 text-right">Occupied Nights</th>
                      <th className="py-3 px-4 text-right">Idle Days</th>
                      <th className="py-3 px-4 text-right">Occupancy %</th>
                      <th className="py-3 px-4 text-right">Revenue</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {data.rooms.map((r, i) => (
                      <tr key={i} className="hover:bg-slate-50">
                        <td className="py-3 px-4 font-medium text-slate-700">{r.room_number}</td>
                        <td className="py-3 px-4 text-slate-600">{r.room_type}</td>
                        <td className="py-3 px-4 text-right text-slate-600">{r.total_bookings}</td>
                        <td className="py-3 px-4 text-right text-slate-600">{r.occupied_nights}</td>
                        <td className="py-3 px-4 text-right text-slate-600">{r.idle_days}</td>
                        <td className="py-3 px-4 text-right">
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${r.occupancy_pct >= 70 ? 'bg-emerald-50 text-emerald-700' : r.occupancy_pct >= 40 ? 'bg-amber-50 text-amber-700' : 'bg-red-50 text-red-700'}`}>
                            {r.occupancy_pct}%
                          </span>
                        </td>
                        <td className="py-3 px-4 text-right text-slate-600">₹{r.revenue?.toLocaleString()}</td>
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

export default function RoomUtilization() {
  return <ReportGuard reportType="room_utilization"><RoomUtilizationInner /></ReportGuard>;
}
