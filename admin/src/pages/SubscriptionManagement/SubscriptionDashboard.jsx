import { useState, useEffect } from 'react';
import { 
  Building2, 
  AlertCircle, 
  CheckCircle2, 
  Clock, 
  Ban, 
  CreditCard,
  DollarSign,
  CalendarDays,
  Loader2
} from 'lucide-react';
import { 
  PieChart, 
  Pie, 
  Cell, 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  LineChart,
  Line
} from 'recharts';
import { subscriptionService } from '../../services/subscriptionService';

const fallbackKpiStats = [
  { name: 'Total Active Subscriptions', value: '0', icon: CheckCircle2, color: 'text-green-600', bg: 'bg-green-50' },
  { name: 'Expiring in Next 3 Days', value: '0', icon: AlertCircle, color: 'text-orange-500', bg: 'bg-orange-50' },
  { name: 'Grace Period Properties', value: '0', icon: Clock, color: 'text-yellow-600', bg: 'bg-yellow-50' },
  { name: 'Expired Subscriptions', value: '0', icon: Ban, color: 'text-red-500', bg: 'bg-red-50' },
  { name: 'Monthly Revenue', value: '$0', icon: DollarSign, color: 'text-pine-DEFAULT', bg: 'bg-pine-50' },
  { name: 'Pending Renewals', value: '0', icon: CalendarDays, color: 'text-indigo-500', bg: 'bg-indigo-50' },
];

export default function SubscriptionDashboard() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [data, setData] = useState({
    kpis: fallbackKpiStats,
    pieData: [],
    barData: [],
    recentActivities: []
  });

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const result = await subscriptionService.getDashboardData();
        setData({
          kpis: result.kpis?.length ? result.kpis : fallbackKpiStats,
          pieData: result.pieData || [],
          barData: result.barData || [],
          recentActivities: result.recentActivities || []
        });
      } catch (err) {
        setError(err.message || 'Failed to fetch dashboard data');
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  if (loading) {
    return (
      <div className="flex justify-center items-center h-[calc(100vh-200px)]">
        <Loader2 className="w-8 h-8 text-pine animate-spin" />
        <span className="ml-3 text-gray-500">Loading Subscription Dashboard...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-[calc(100vh-200px)]">
        <AlertCircle className="h-10 w-10 text-red-500 mb-4" />
        <p className="text-gray-900 font-medium">Failed to load dashboard data</p>
        <p className="text-gray-500 text-sm mt-2">{error}</p>
      </div>
    );
  }

  const { kpis, pieData, barData, recentActivities } = data;

  return (
    <div className="space-y-6 animate-slide-up">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Subscription Overview</h1>
          <p className="text-sm text-gray-500 mt-1">High-level metrics and revenue tracking.</p>
        </div>
        <div className="flex space-x-2">
          <button className="saas-button-secondary">Download Report</button>
          <button className="saas-button-primary">Generate Invoices</button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6">
        {kpis.map((stat, i) => {
          const Icon = typeof stat.icon === 'string' ? CheckCircle2 : (stat.icon || CheckCircle2);
          return (
            <div key={i} className="saas-card p-4 flex flex-col justify-center">
              <div className="flex items-center space-x-3">
                <div className={`p-2 rounded-lg ${stat.bg || 'bg-gray-50'}`}>
                  <Icon className={`h-4 w-4 ${stat.color || 'text-gray-500'}`} />
                </div>
                <p className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider">{stat.name}</p>
              </div>
              <p className="text-2xl font-bold text-gray-900 mt-3">{stat.value}</p>
            </div>
          );
        })}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Revenue Chart */}
        <div className="lg:col-span-2 saas-card p-6">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-lg font-semibold text-gray-900">Revenue Trends</h2>
            <select className="saas-input py-1 text-sm bg-gray-50 border-gray-200">
              <option>Last 6 Months</option>
              <option>This Year</option>
            </select>
          </div>
          <div className="h-72 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={barData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f3f4f6" />
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#6b7280' }} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#6b7280' }} tickFormatter={(value) => `$${value/1000}k`} />
                <Tooltip 
                  cursor={{ fill: '#f9fafb' }}
                  contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                  formatter={(value) => [`$${value.toLocaleString()}`, 'Revenue']}
                />
                <Bar dataKey="revenue" fill="#4a5d23" radius={[4, 4, 0, 0]} maxBarSize={50} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Plan Distribution */}
        <div className="saas-card p-6 flex flex-col">
          <h2 className="text-lg font-semibold text-gray-900 mb-6">Plan Distribution</h2>
          <div className="flex-1 flex justify-center items-center relative min-h-[200px]">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={pieData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={80}
                  paddingAngle={2}
                  dataKey="value"
                  stroke="none"
                >
                  {pieData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip 
                  contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                />
              </PieChart>
            </ResponsiveContainer>
            <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
              <span className="text-2xl font-bold text-gray-900">{pieData.reduce((a, b) => a + b.value, 0)}</span>
              <span className="text-xs text-gray-500 font-medium uppercase tracking-wider mt-1">Total</span>
            </div>
          </div>
          <div className="mt-6 space-y-3">
            {pieData.map(item => (
              <div key={item.name} className="flex justify-between items-center text-sm">
                <div className="flex items-center">
                  <div className="w-3 h-3 rounded-full mr-2" style={{ backgroundColor: item.color }}></div>
                  <span className="text-gray-600 font-medium">{item.name}</span>
                </div>
                <span className="text-gray-900 font-bold">{item.value} <span className="text-gray-400 font-normal text-xs ml-1 relative -top-px">({Math.round((item.value / pieData.reduce((a, b) => a + b.value, 0)) * 100)}%)</span></span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="saas-card overflow-hidden">
        <div className="px-6 py-5 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
          <h2 className="text-lg font-semibold text-gray-900">Recent Financial Activities</h2>
          <button className="text-sm font-medium text-pine hover:text-pine-dark transition-colors">View All</button>
        </div>
        <div className="divide-y divide-gray-100">
          {recentActivities.map((activity) => (
            <div key={activity.id} className="p-4 hover:bg-gray-50 transition-colors flex items-center justify-between group">
              <div className="flex items-center">
                <div className="h-10 w-10 rounded-full bg-pine/10 flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform">
                  <CreditCard className="h-4 w-4 text-pine" />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-semibold text-gray-900">{activity.action}</p>
                  <p className="text-xs text-gray-500 mt-0.5">{activity.subject} • {activity.time}</p>
                </div>
              </div>
              <div className="text-right">
                <p className="text-sm font-bold text-gray-900">{activity.amount}</p>
                <p className="text-xs text-green-600 font-medium mt-0.5 flex items-center justify-end"><CheckCircle2 className="w-3 h-3 mr-1"/> {activity.status}</p>
              </div>
            </div>
          ))}
          {recentActivities.length === 0 && (
            <div className="p-8 text-center text-gray-500">No recent activities found.</div>
          )}
        </div>
      </div>
    </div>
  );
}
