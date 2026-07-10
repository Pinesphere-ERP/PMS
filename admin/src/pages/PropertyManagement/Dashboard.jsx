import { useState, useEffect } from 'react';
import { 
  Building2, 
  AlertCircle, 
  CheckCircle2, 
  Clock, 
  Ban, 
  CreditCard,
  Plus,
  ArrowUpRight,
  Loader2
} from 'lucide-react';
import { propertyService } from '../../services/propertyService';

const fallbackKpiStats = [
  { name: 'Total Properties', value: '0', icon: Building2, color: 'text-pine-light', glow: 'shadow-pine-light/20' },
  { name: 'Active Properties', value: '0', icon: CheckCircle2, color: 'text-green-400', glow: 'shadow-green-400/20' },
  { name: 'Pending Verification', value: '0', icon: Clock, color: 'text-yellow-400', glow: 'shadow-yellow-400/20' },
  { name: 'Suspended', value: '0', icon: Ban, color: 'text-red-400', glow: 'shadow-red-400/20' },
  { name: 'Expired Subscriptions', value: '0', icon: AlertCircle, color: 'text-orange-400', glow: 'shadow-orange-400/20' },
  { name: 'Active Subscriptions', value: '0', icon: CreditCard, color: 'text-indigo-400', glow: 'shadow-indigo-400/20' },
];

export default function Dashboard() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [data, setData] = useState({
    kpis: fallbackKpiStats,
    recentActivities: []
  });

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setLoading(true);
        const result = await propertyService.getSuperAdminDashboardData();
        setData({
          kpis: result.kpis?.length ? result.kpis : fallbackKpiStats,
          recentActivities: result.recentActivities || []
        });
      } catch (err) {
        setError(err.message || 'Failed to fetch dashboard data');
      } finally {
        setLoading(false);
      }
    };
    fetchDashboardData();
  }, []);

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center h-[calc(100vh-200px)]">
         <Loader2 className="w-8 h-8 text-pine animate-spin mb-4" />
         <span className="text-gray-400">Loading Dashboard...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-[calc(100vh-200px)]">
        <AlertCircle className="h-10 w-10 text-red-500 mb-4" />
        <p className="text-white font-medium">Failed to load dashboard data</p>
        <p className="text-gray-400 text-sm mt-2">{error}</p>
      </div>
    );
  }

  const { kpis, recentActivities } = data;

  return (
    <div className="space-y-8 animate-slide-up">
      <div className="flex justify-between items-end">
        <div>
          <h1 className="text-4xl font-bold text-white mb-2 tracking-tight">Overview</h1>
          <p className="text-gray-400">Welcome back to the Pinesphere Super Admin portal.</p>
        </div>
        <button className="glass-button px-6 py-3 rounded-xl flex items-center font-medium group">
          <Plus className="h-5 w-5 mr-2 group-hover:rotate-90 transition-transform duration-300" />
          Add Property
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 xl:grid-cols-3">
        {kpis.map((stat, i) => {
          const Icon = typeof stat.icon === 'string' ? Building2 : (stat.icon || Building2);
          return (
            <div key={stat.name} className={`glass-card p-6 flex items-start justify-between relative overflow-hidden group`} style={{ animationDelay: `${i * 100}ms` }}>
              {/* Subtle glow effect behind the icon */}
              <div className={`absolute -right-4 -top-4 w-24 h-24 rounded-full blur-2xl opacity-20 bg-current ${stat.color} group-hover:opacity-40 transition-opacity duration-500`}></div>
              
              <div className="z-10">
                <p className="text-sm font-medium text-gray-400 mb-2">{stat.name}</p>
                <h3 className="text-3xl font-bold text-white">{stat.value}</h3>
              </div>
              <div className={`p-3 rounded-xl bg-white/5 backdrop-blur-sm border border-white/10 shadow-lg ${stat.glow} z-10 group-hover:scale-110 transition-transform duration-300`}>
                <Icon className={`h-6 w-6 ${stat.color}`} />
              </div>
            </div>
          );
        })}
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-8">
        {/* Recent Activity Feed */}
        <div className="glass-card p-6 flex flex-col">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-xl font-bold text-white tracking-tight">Recent Activity</h2>
            <button className="text-sm font-medium text-pine-light hover:text-pine transition-colors flex items-center">
              View All <ArrowUpRight className="h-4 w-4 ml-1" />
            </button>
          </div>
          
          <div className="space-y-4 flex-1">
            {recentActivities.length === 0 && <p className="text-gray-400 text-sm">No recent activities found.</p>}
            {recentActivities.map((activity) => (
              <div key={activity.id} className="group p-4 rounded-xl bg-white/5 border border-white/10 hover:bg-white/10 hover:border-white/20 transition-all duration-300 flex items-start justify-between">
                <div>
                  <h4 className="text-sm font-semibold text-white group-hover:text-pine-light transition-colors">{activity.action}</h4>
                  <p className="text-xs text-gray-400 mt-1">{activity.subject} <span className="mx-2 text-gray-600">•</span> {activity.time}</p>
                </div>
                <span className={`px-3 py-1 rounded-full text-xs font-medium border ${activity.badge || 'bg-gray-500/20 text-gray-300 border-gray-500/30'}`}>
                  {activity.status}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Quick Actions (Static for now, but fully styled for Dark Glassmorphism) */}
        <div className="glass-card p-6 flex flex-col">
          <h2 className="text-xl font-bold text-white tracking-tight mb-6">Quick Actions</h2>
          <div className="grid grid-cols-2 gap-4 flex-1">
            <button className="p-4 rounded-xl bg-white/5 border border-white/10 hover:bg-pine/20 hover:border-pine/30 transition-all duration-300 flex flex-col items-center justify-center text-center group">
              <Building2 className="h-8 w-8 text-pine-light mb-3 group-hover:scale-110 transition-transform duration-300" />
              <span className="text-sm font-medium text-white">Review Pending Properties</span>
              <span className="text-xs text-gray-400 mt-1">8 requires attention</span>
            </button>
            <button className="p-4 rounded-xl bg-white/5 border border-white/10 hover:bg-indigo-500/20 hover:border-indigo-500/30 transition-all duration-300 flex flex-col items-center justify-center text-center group">
              <CreditCard className="h-8 w-8 text-indigo-400 mb-3 group-hover:scale-110 transition-transform duration-300" />
              <span className="text-sm font-medium text-white">Process Renewals</span>
              <span className="text-xs text-gray-400 mt-1">12 due this week</span>
            </button>
            <button className="p-4 rounded-xl bg-white/5 border border-white/10 hover:bg-red-500/20 hover:border-red-500/30 transition-all duration-300 flex flex-col items-center justify-center text-center group">
              <Ban className="h-8 w-8 text-red-400 mb-3 group-hover:scale-110 transition-transform duration-300" />
              <span className="text-sm font-medium text-white">Manage Suspensions</span>
              <span className="text-xs text-gray-400 mt-1">4 active suspensions</span>
            </button>
            <button className="p-4 rounded-xl bg-white/5 border border-white/10 hover:bg-blue-500/20 hover:border-blue-500/30 transition-all duration-300 flex flex-col items-center justify-center text-center group">
              <AlertCircle className="h-8 w-8 text-blue-400 mb-3 group-hover:scale-110 transition-transform duration-300" />
              <span className="text-sm font-medium text-white">System Alerts</span>
              <span className="text-xs text-gray-400 mt-1">No critical issues</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
