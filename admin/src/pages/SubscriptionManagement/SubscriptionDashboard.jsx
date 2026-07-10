import { 
  Building2, 
  AlertCircle, 
  CheckCircle2, 
  Clock, 
  Ban, 
  CreditCard,
  DollarSign,
  CalendarDays
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

const kpiStats = [
  { name: 'Total Active Subscriptions', value: '842', icon: CheckCircle2, color: 'text-green-600', bg: 'bg-green-50' },
  { name: 'Expiring in Next 3 Days', value: '18', icon: AlertCircle, color: 'text-orange-500', bg: 'bg-orange-50' },
  { name: 'Grace Period Properties', value: '5', icon: Clock, color: 'text-yellow-600', bg: 'bg-yellow-50' },
  { name: 'Expired Subscriptions', value: '12', icon: Ban, color: 'text-red-500', bg: 'bg-red-50' },
  { name: 'Monthly Revenue', value: '$42,500', icon: DollarSign, color: 'text-pine-DEFAULT', bg: 'bg-pine-50' },
  { name: 'Pending Renewals', value: '24', icon: CalendarDays, color: 'text-indigo-500', bg: 'bg-indigo-50' },
];

const pieData = [
  { name: 'Pro Plan', value: 400, color: '#8aa356' },
  { name: 'Basic Plan', value: 300, color: '#5f703a' },
  { name: 'Enterprise', value: 142, color: '#2f2e2a' },
];

const barData = [
  { name: 'Jan', revenue: 38000 },
  { name: 'Feb', revenue: 39500 },
  { name: 'Mar', revenue: 41000 },
  { name: 'Apr', revenue: 42500 },
];

const recentActivities = [
  { id: 1, action: 'Subscription Renewed', subject: 'Grand Plaza Hotel', time: '2 mins ago', amount: '$499.00', status: 'Success' },
  { id: 2, action: 'Payment Received', subject: 'Sea View Resort', time: '1 hour ago', amount: '$199.00', status: 'Success' },
  { id: 3, action: 'Property Disabled', subject: 'City Lights Hostel', time: '3 hours ago', amount: '-', status: 'Expired' },
  { id: 4, action: 'Upcoming Expiration', subject: 'Mountain Inn', time: '5 hours ago', amount: '-', status: 'Warning' },
];

export default function SubscriptionDashboard() {
  return (
    <div className="space-y-6 animate-slide-up">
      <div>
        <h1 className="text-2xl font-semibold text-gray-900 tracking-tight">Subscription Dashboard</h1>
        <p className="text-sm text-gray-500 mt-1">Overview of subscription health across all onboarded properties.</p>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {kpiStats.map((stat, i) => (
          <div key={stat.name} className="saas-card p-5 flex items-start space-x-4">
            <div className={`p-2.5 rounded-lg ${stat.bg}`}>
              <stat.icon className={`h-5 w-5 ${stat.color}`} />
            </div>
            <div>
              <p className="text-sm font-medium text-gray-500">{stat.name}</p>
              <h3 className="text-2xl font-bold text-gray-900 mt-1">{stat.value}</h3>
            </div>
          </div>
        ))}
      </div>

      {/* Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Status Distribution */}
        <div className="saas-card p-5">
          <h3 className="text-sm font-semibold text-gray-900 mb-4">Plan Distribution</h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={pieData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={80}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {pieData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="flex justify-center space-x-4 mt-2">
            {pieData.map(item => (
              <div key={item.name} className="flex items-center text-xs text-gray-500">
                <span className="w-3 h-3 rounded-full mr-2" style={{ backgroundColor: item.color }}></span>
                {item.name}
              </div>
            ))}
          </div>
        </div>

        {/* Monthly Revenue */}
        <div className="saas-card p-5">
          <h3 className="text-sm font-semibold text-gray-900 mb-4">Monthly Revenue</h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={barData}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E5E7EB" />
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#6B7280' }} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#6B7280' }} dx={-10} tickFormatter={(val) => `$${val/1000}k`} />
                <Tooltip cursor={{ fill: '#F9FAFB' }} />
                <Bar dataKey="revenue" fill="#8aa356" radius={[4, 4, 0, 0]} barSize={40} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Recent Activities */}
      <div className="saas-card overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100 flex justify-between items-center">
          <h3 className="text-sm font-semibold text-gray-900">Recent Activities</h3>
          <button className="text-sm text-pine font-medium hover:text-pine-dark transition-colors">View All</button>
        </div>
        <ul className="divide-y divide-gray-100">
          {recentActivities.map((activity) => (
            <li key={activity.id} className="px-5 py-4 hover:bg-gray-50/50 transition-colors">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-900">{activity.action}</p>
                  <p className="text-xs text-gray-500 mt-0.5">{activity.subject} • {activity.time}</p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-medium text-gray-900">{activity.amount}</p>
                  <span className={`inline-block mt-1 status-badge ${
                    activity.status === 'Success' ? 'status-active' :
                    activity.status === 'Warning' ? 'status-pending' : 'status-error'
                  }`}>
                    {activity.status}
                  </span>
                </div>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
