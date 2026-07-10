import { 
  Building2, 
  AlertCircle, 
  CheckCircle2, 
  Clock, 
  Ban, 
  CreditCard,
  Plus,
  ArrowUpRight
} from 'lucide-react';

const kpiStats = [
  { name: 'Total Properties', value: '156', icon: Building2, color: 'text-pine-light', glow: 'shadow-pine-light/20' },
  { name: 'Active Properties', value: '142', icon: CheckCircle2, color: 'text-green-400', glow: 'shadow-green-400/20' },
  { name: 'Pending Verification', value: '8', icon: Clock, color: 'text-yellow-400', glow: 'shadow-yellow-400/20' },
  { name: 'Suspended', value: '4', icon: Ban, color: 'text-red-400', glow: 'shadow-red-400/20' },
  { name: 'Expired Subscriptions', value: '2', icon: AlertCircle, color: 'text-orange-400', glow: 'shadow-orange-400/20' },
  { name: 'Active Subscriptions', value: '154', icon: CreditCard, color: 'text-indigo-400', glow: 'shadow-indigo-400/20' },
];

const recentActivities = [
  { id: 1, action: 'Property Added', subject: 'Grand Plaza Hotel', time: '2 hours ago', status: 'Pending Verification', badge: 'bg-yellow-500/20 text-yellow-300 border-yellow-500/30' },
  { id: 2, action: 'Verification Approved', subject: 'Sea View Resort', time: '4 hours ago', status: 'Active', badge: 'bg-green-500/20 text-green-300 border-green-500/30' },
  { id: 3, action: 'Subscription Renewed', subject: 'Mountain Inn', time: '1 day ago', status: 'Pro Plan', badge: 'bg-pine-light/20 text-pine-light border-pine-light/30' },
  { id: 4, action: 'Property Suspended', subject: 'City Lights Hostel', time: '2 days ago', status: 'Suspended', badge: 'bg-red-500/20 text-red-300 border-red-500/30' },
];

export default function Dashboard() {
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
        {kpiStats.map((stat, i) => (
          <div key={stat.name} className={`glass-card p-6 flex items-start justify-between relative overflow-hidden group`} style={{ animationDelay: `${i * 100}ms` }}>
            {/* Subtle glow effect behind the icon */}
            <div className={`absolute -right-4 -top-4 w-24 h-24 rounded-full blur-2xl opacity-20 bg-current ${stat.color} group-hover:opacity-40 transition-opacity duration-500`}></div>
            
            <div className="z-10">
              <p className="text-sm font-medium text-gray-400 mb-2">{stat.name}</p>
              <h3 className="text-4xl font-bold text-white tracking-tight">{stat.value}</h3>
            </div>
            
            <div className={`p-4 rounded-2xl bg-pine-dark/50 border border-white/5 ${stat.glow} z-10 group-hover:scale-110 transition-transform duration-300`}>
              <stat.icon className={`h-7 w-7 ${stat.color}`} />
            </div>
          </div>
        ))}
      </div>

      {/* Recent Activities */}
      <div className="glass-card overflow-hidden">
        <div className="px-6 py-5 border-b border-pine-muted/20 flex justify-between items-center bg-pine-dark/40">
          <h3 className="text-xl font-semibold text-white">Recent Activities</h3>
          <button className="text-sm text-pine-light hover:text-white flex items-center transition-colors">
            View All <ArrowUpRight className="h-4 w-4 ml-1" />
          </button>
        </div>
        <ul className="divide-y divide-pine-muted/10">
          {recentActivities.map((activity) => (
            <li key={activity.id} className="px-6 py-5 hover:bg-white/5 transition-colors group">
              <div className="flex items-center justify-between">
                <div className="flex flex-col">
                  <p className="text-base font-medium text-white mb-1 group-hover:text-pine-light transition-colors">{activity.action}</p>
                  <p className="text-sm text-gray-400">{activity.subject}</p>
                </div>
                <div className="flex flex-col items-end space-y-2">
                  <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-medium border ${activity.badge}`}>
                    {activity.status}
                  </span>
                  <p className="text-xs text-gray-500">{activity.time}</p>
                </div>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
