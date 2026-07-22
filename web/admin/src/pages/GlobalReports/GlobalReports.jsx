import { useState, useEffect } from 'react';
import { fetchAPI } from '../../services/api';
import { BarChart3, TrendingUp, Users, Building2, Wallet, CalendarDays, IndianRupee } from 'lucide-react';

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
          label="Total Users" 
          value={data.total_users}
          color="blue" 
        />
        <StatCard 
          icon={<TrendingUp className="w-6 h-6" />}
          label="Total Active Subscriptions" 
          value={data.total_active_subscriptions}
          color="purple" 
        />
        <StatCard 
          icon={<IndianRupee className="w-6 h-6" />}
          label="Total Platform Revenue" 
          value={`₹${data.total_platform_revenue.toLocaleString()}`}
          color="indigo" 
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Properties by State */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-100 p-6">
          <h3 className="text-lg font-semibold text-slate-800 mb-4 flex items-center">
            <Building2 className="w-5 h-5 mr-2 text-slate-400" />
            Properties by State
          </h3>
          <div className="space-y-4">
            {Object.entries(data.properties_by_state).map(([state, count]) => (
              <div key={state} className="flex justify-between items-center p-3 hover:bg-slate-50 rounded-lg transition-colors">
                <span className="text-slate-600 font-medium">{state || 'Unknown'}</span>
                <span className="bg-emerald-50 text-emerald-700 px-3 py-1 rounded-full text-sm font-medium">
                  {count}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Subscription Tiers */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-100 p-6">
          <h3 className="text-lg font-semibold text-slate-800 mb-4 flex items-center">
            <Wallet className="w-5 h-5 mr-2 text-slate-400" />
            Subscription Tiers
          </h3>
          <div className="space-y-4">
            {Object.entries(data.subscription_tiers_count).map(([tier, count]) => (
              <div key={tier} className="flex justify-between items-center p-3 hover:bg-slate-50 rounded-lg transition-colors">
                <span className="text-slate-600 font-medium capitalize">{tier.replace('_', ' ')}</span>
                <span className="bg-purple-50 text-purple-700 px-3 py-1 rounded-full text-sm font-medium">
                  {count}
                </span>
              </div>
            ))}
          </div>
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
