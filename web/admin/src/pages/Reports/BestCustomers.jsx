import { useState, useEffect } from 'react';
import { fetchAPI } from '../../services/api';
import DateRangeFilter from '../../components/reports/DateRangeFilter';
import ExportButton from '../../components/reports/ExportButton';
import ReportGuard from '../../components/reports/ReportGuard';
import { Star, TrendingUp, Calendar } from 'lucide-react';

function BestCustomersInner() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filters, setFilters] = useState({ startDate: '', endDate: '' });
  const [propertyId, setPropertyId] = useState('');

  const loadReport = async () => {
    if (!propertyId || !filters.startDate || !filters.endDate) { setLoading(false); return; }
    setLoading(true);
    try {
      const res = await fetchAPI(`/reports/best-customers?property_id=${propertyId}&start_date=${filters.startDate}&end_date=${filters.endDate}`);
      setData(res);
    } catch (err) { setError(err.message); } finally { setLoading(false); }
  };

  useEffect(() => { loadReport(); }, [filters, propertyId]);

  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-slate-800">Best Customers</h1>
          <p className="text-slate-500 text-sm mt-1">Top guests by revenue and stays</p>
        </div>
        <ExportButton reportType="best_customers" params={{ property_id: propertyId, start_date: filters.startDate, end_date: filters.endDate }} />
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

      {data && data.customers?.length > 0 && (
        <div className="space-y-3">
          {data.customers.map((c, i) => (
            <div key={c.guest_id || i} className={`bg-white rounded-xl border shadow-sm p-5 flex items-center gap-4 ${i < 3 ? 'border-amber-200' : 'border-slate-100'}`}>
              <div className={`w-10 h-10 rounded-full flex items-center justify-center font-bold text-white ${i === 0 ? 'bg-amber-500' : i === 1 ? 'bg-slate-400' : i === 2 ? 'bg-amber-700' : 'bg-slate-300'}`}>
                {i + 1}
              </div>
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  <h3 className="font-semibold text-slate-800">{c.guest_name}</h3>
                  {i < 3 && <Star className="w-4 h-4 text-amber-500 fill-amber-500" />}
                </div>
                <div className="flex gap-4 text-sm text-slate-500 mt-1">
                  <span>{c.total_bookings} bookings</span>
                  <span>{c.total_nights} nights</span>
                  <span>Avg: ₹{c.avg_booking_value?.toLocaleString()}</span>
                  {c.last_stay_date && <span className="flex items-center gap-1"><Calendar className="w-3 h-3" />{c.last_stay_date}</span>}
                </div>
              </div>
              <div className="text-right">
                <div className="text-lg font-bold text-emerald-600">₹{c.total_revenue?.toLocaleString()}</div>
                <div className="text-xs text-slate-400">total revenue</div>
              </div>
            </div>
          ))}
        </div>
      )}

      {data && data.customers?.length === 0 && (
        <div className="bg-white rounded-xl border border-slate-100 shadow-sm p-12 text-center text-slate-500">
          No customer data available for the selected period.
        </div>
      )}
    </div>
  );
}

export default function BestCustomers() {
  return <ReportGuard reportType="best_customers"><BestCustomersInner /></ReportGuard>;
}
