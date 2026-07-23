import { useState, useEffect } from 'react';
import { fetchAPI } from '../../services/api';
import { BarChart3, TrendingUp, Users, Building2, Wallet, CalendarDays, IndianRupee } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from 'recharts';

const COLORS = ['#059669', '#3B82F6', '#F59E0B', '#EF4444', '#8B5CF6', '#EC4899', '#06B6D4'];

export default function GlobalReports() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const loadSummary = async () => {
      try {
        setLoading(true);
        const res = await fetchAPI('/reports/global-summary');
        setData(res);
      } catch (err) {
        setError(err.message || 'Failed to load global summary');
      } finally {
        setLoading(false);
      }
    };
    loadSummary();
  }, []);

  if (loading) return (
    <div className="flex h-screen items-center justify-center">
      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-500"></div>
    </div>
  );

  if (error) return (
    <div className="p-6 text-red-500">
      Error: {error}
    </div>
  );

  if (!data) return null;

  const occupancyData = data.properties?.map(p => ({ name: p.property_name, occupancy: p.occupancy_pct })) || [];
  const revenueData = data.properties?.map(p => ({ name: p.property_name, revenue: p.revenue })) || [];

  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-slate-800">Global Analytics Summary</h1>
          <p className="text-slate-500 text-sm mt-1">Platform-wide performance and metrics</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard 
          icon={<Building2 className="w-6 h-6" />}
          label="Total Properties" 
          value={data.total_properties}
          color="emerald" 
        />
        <StatCard 
          icon={<Users className="w-6 h-6" />}
          label="Avg Occupancy" 
          value={`${data.avg_occupancy_pct ?? 0}%`}
          color="blue" 
        />
        <StatCard 
          icon={<IndianRupee className="w-6 h-6" />}
          label="Total Revenue" 
          value={`₹${(data.total_revenue ?? 0).toLocaleString()}`}
          color="indigo" 
        />
        <StatCard 
          icon={<Wallet className="w-6 h-6" />}
          label="Total Outstanding" 
          value={`₹${(data.total_outstanding ?? 0).toLocaleString()}`}
          color="purple" 
        />
      </div>

      {occupancyData.length > 0 && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="bg-white rounded-xl shadow-sm border border-slate-100 p-6">
            <h3 className="text-lg font-semibold text-slate-800 mb-4">Occupancy by Property</h3>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={occupancyData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" />
                <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip formatter={(val) => `${val}%`} />
                <Bar dataKey="occupancy" fill="#059669" radius={[4, 4, 0, 0]} name="Occupancy %" />
              </BarChart>
            </ResponsiveContainer>
          </div>

          <div className="bg-white rounded-xl shadow-sm border border-slate-100 p-6">
            <h3 className="text-lg font-semibold text-slate-800 mb-4">Revenue by Property</h3>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={revenueData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" />
                <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip formatter={(val) => `₹${val.toLocaleString()}`} />
                <Bar dataKey="revenue" fill="#3B82F6" radius={[4, 4, 0, 0]} name="Revenue" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}

      <div className="bg-white rounded-xl shadow-sm border border-slate-100 p-6">
        <h3 className="text-lg font-semibold text-slate-800 mb-4 flex items-center">
          <Building2 className="w-5 h-5 mr-2 text-slate-400" />
          Property Performance Breakdown
        </h3>
        
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-100 text-sm font-medium text-slate-500">
                <th className="py-3 px-4">Property Name</th>
                <th className="py-3 px-4 text-right">Total Rooms</th>
                <th className="py-3 px-4 text-right">Occupancy %</th>
                <th className="py-3 px-4 text-right">Revenue</th>
                <th className="py-3 px-4 text-right">Outstanding</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {data.properties && data.properties.map((prop) => (
                <tr key={prop.property_id} className="hover:bg-slate-50 transition-colors">
                  <td className="py-3 px-4 font-medium text-slate-700">
                    {prop.property_name}
                  </td>
                  <td className="py-3 px-4 text-right text-slate-600">
                    {prop.total_rooms}
                  </td>
                  <td className="py-3 px-4 text-right">
                    <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                      prop.occupancy_pct >= 80 ? 'bg-emerald-50 text-emerald-700' : 
                      prop.occupancy_pct >= 50 ? 'bg-amber-50 text-amber-700' : 
                      'bg-red-50 text-red-700'
                    }`}>
                      {prop.occupancy_pct}%
                    </span>
                  </td>
                  <td className="py-3 px-4 text-right text-slate-600">
                    ₹{(prop.revenue ?? 0).toLocaleString()}
                  </td>
                  <td className="py-3 px-4 text-right text-slate-600">
                    ₹{(prop.outstanding ?? 0).toLocaleString()}
                  </td>
                </tr>
              ))}
              {(!data.properties || data.properties.length === 0) && (
                <tr>
                  <td colSpan="5" className="py-8 text-center text-slate-500">
                    No property data available.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

function StatCard({ icon, label, value, color }) {
  const colorClasses = {
    emerald: 'bg-emerald-50 text-emerald-600',
    blue: 'bg-blue-50 text-blue-600',
    purple: 'bg-purple-50 text-purple-600',
    indigo: 'bg-indigo-50 text-indigo-600',
  };

  return (
    <div className="bg-white p-6 rounded-xl border border-slate-100 shadow-sm flex items-start space-x-4">
      <div className={`p-3 rounded-xl ${colorClasses[color]}`}>
        {icon}
      </div>
      <div>
        <p className="text-sm font-medium text-slate-500 mb-1">{label}</p>
        <h4 className="text-2xl font-bold text-slate-800">{value}</h4>
      </div>
    </div>
  );
}
