import { useState, useEffect } from 'react';
import { fetchAPI } from '../../services/api';
import KPICard from '../../components/reports/KPICard';
import DateRangeFilter from '../../components/reports/DateRangeFilter';
import ExportButton from '../../components/reports/ExportButton';
import ReportGuard from '../../components/reports/ReportGuard';
import { Users, LogIn, LogOut, BedDouble, CalendarX, IndianRupee, Clock, CheckCircle } from 'lucide-react';

function DailyReportInner() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [reportDate, setReportDate] = useState(new Date().toISOString().split('T')[0]);
  const [propertyId, setPropertyId] = useState('');

  useEffect(() => {
    loadReport();
  }, [reportDate, propertyId]);

  const loadReport = async () => {
    if (!propertyId) return;
    setLoading(true);
    try {
      const res = await fetchAPI(`/reports/daily?property_id=${propertyId}&report_date=${reportDate}`);
      setData(res);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-slate-800">Daily Report</h1>
          <p className="text-slate-500 text-sm mt-1">Daily operations summary</p>
        </div>
        <ExportButton reportType="daily" params={{ property_id: propertyId, report_date: reportDate }} />
      </div>

      <div className="flex flex-wrap items-end gap-3 bg-white p-4 rounded-xl border border-slate-100 shadow-sm">
        <div>
          <label className="block text-xs font-medium text-slate-500 mb-1">Date</label>
          <input type="date" value={reportDate} onChange={(e) => setReportDate(e.target.value)} className="saas-input text-sm" />
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
            <KPICard icon={<LogIn className="w-5 h-5" />} label="Check-ins" value={data.total_checkins} color="emerald" />
            <KPICard icon={<LogOut className="w-5 h-5" />} label="Check-outs" value={data.total_checkouts} color="orange" />
            <KPICard icon={<BedDouble className="w-5 h-5" />} label="Occupied Rooms" value={`${data.occupied_rooms} / ${data.total_rooms}`} color="blue" subtext={`${data.occupancy_pct}% occupancy`} />
            <KPICard icon={<CalendarX className="w-5 h-5" />} label="Vacant Rooms" value={data.vacant_rooms} color="red" />
            <KPICard icon={<IndianRupee className="w-5 h-5" />} label="Revenue Collected" value={`₹${data.revenue_collected?.toLocaleString()}`} color="emerald" />
            <KPICard icon={<Clock className="w-5 h-5" />} label="Pending Payments" value={`₹${data.pending_payments?.toLocaleString()}`} color="amber" />
            <KPICard icon={<Users className="w-5 h-5" />} label="New Bookings" value={data.new_bookings} color="indigo" />
            <KPICard icon={<CheckCircle className="w-5 h-5" />} label="Housekeeping Done" value={data.housekeeping_completed} color="teal" subtext={`${data.housekeeping_pending} pending`} />
          </div>

          <div className="bg-white rounded-xl border border-slate-100 shadow-sm p-6">
            <h3 className="text-lg font-semibold text-slate-800 mb-4">Daily Summary</h3>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
              <div className="p-4 bg-slate-50 rounded-lg">
                <div className="text-2xl font-bold text-slate-800">{data.new_bookings}</div>
                <div className="text-xs text-slate-500">New Bookings</div>
              </div>
              <div className="p-4 bg-slate-50 rounded-lg">
                <div className="text-2xl font-bold text-red-600">{data.cancelled_bookings}</div>
                <div className="text-xs text-slate-500">Cancelled</div>
              </div>
              <div className="p-4 bg-slate-50 rounded-lg">
                <div className="text-2xl font-bold text-emerald-600">{data.occupancy_pct}%</div>
                <div className="text-xs text-slate-500">Occupancy Rate</div>
              </div>
              <div className="p-4 bg-slate-50 rounded-lg">
                <div className="text-2xl font-bold text-blue-600">{data.housekeeping_completed}</div>
                <div className="text-xs text-slate-500">Tasks Completed</div>
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  );
}

export default function DailyReport() {
  return <ReportGuard reportType="daily"><DailyReportInner /></ReportGuard>;
}
