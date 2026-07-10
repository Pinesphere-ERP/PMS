import { 
  AlertTriangle,
  Clock,
  Ban,
  ShieldAlert,
  Send,
  Eye,
  RefreshCw
} from 'lucide-react';

const kpiStats = [
  { name: 'Renewals Due in 3 Days', value: '18', icon: AlertTriangle, color: 'text-orange-500', bg: 'bg-orange-50' },
  { name: 'Grace Period', value: '5', icon: Clock, color: 'text-yellow-600', bg: 'bg-yellow-50' },
  { name: 'Expired', value: '12', icon: Ban, color: 'text-red-500', bg: 'bg-red-50' },
  { name: 'Enforcement Pending', value: '4', icon: ShieldAlert, color: 'text-purple-600', bg: 'bg-purple-50' },
];

const timelineData = {
  upcoming: [
    { id: 1, property: 'Sunset Villa', plan: 'Basic', expiry: 'Tomorrow', payment: 'Auto-charge scheduled' },
    { id: 2, property: 'Oceanside Resort', plan: 'Pro', expiry: 'In 2 days', payment: 'Manual renewal required' },
  ],
  grace: [
    { id: 3, property: 'Mountain Inn', plan: 'Pro', expiry: 'Expired 2 days ago', graceRemaining: '3 days left' },
  ],
  expired: [
    { id: 4, property: 'City Lights Hostel', plan: 'Basic', expiry: 'Expired 7 days ago', status: 'Enforcement Required' },
  ]
};

const enforcementTable = [
  { id: '1', property: 'City Lights Hostel', plan: 'Basic', expiry: '2024-12-25', grace: '0', status: 'Enforcement Pending', reminderSent: '3 times', payment: 'Failed' },
  { id: '2', property: 'Grand Plaza Hotel (Old Branch)', plan: 'Enterprise', expiry: '2024-12-20', grace: '0', status: 'Suspended', reminderSent: '5 times', payment: 'Unpaid' },
];

export default function RenewalManagement() {
  return (
    <div className="space-y-8 animate-slide-up">
      <div>
        <h1 className="text-2xl font-semibold text-gray-900 tracking-tight">Renewal Management</h1>
        <p className="text-sm text-gray-500 mt-1">Monitor upcoming renewals, grace periods, and enforcement actions.</p>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {kpiStats.map((stat) => (
          <div key={stat.name} className="saas-card p-5 flex items-start space-x-4">
            <div className={`p-2.5 rounded-lg ${stat.bg}`}>
              <stat.icon className={`h-5 w-5 ${stat.color}`} />
            </div>
            <div>
              <p className="text-xs font-medium text-gray-500 uppercase tracking-wider">{stat.name}</p>
              <h3 className="text-2xl font-bold text-gray-900 mt-1">{stat.value}</h3>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Timeline Section */}
        <div className="lg:col-span-1 space-y-6">
          <h3 className="text-lg font-semibold text-gray-900">Action Timeline</h3>
          
          <div className="space-y-6">
            {/* Upcoming */}
            <div>
              <h4 className="text-sm font-semibold text-orange-600 mb-3 flex items-center">
                <AlertTriangle className="h-4 w-4 mr-1.5" /> Due in 3 Days
              </h4>
              <div className="space-y-3">
                {timelineData.upcoming.map(item => (
                  <div key={item.id} className="saas-card p-4 border-l-4 border-l-orange-400">
                    <div className="flex justify-between items-start">
                      <p className="text-sm font-medium text-gray-900">{item.property}</p>
                      <span className="text-xs text-gray-500 bg-gray-100 px-2 py-0.5 rounded">{item.plan}</span>
                    </div>
                    <p className="text-xs text-gray-500 mt-1">Expiry: {item.expiry}</p>
                    <p className="text-xs text-orange-600 mt-1">{item.payment}</p>
                  </div>
                ))}
              </div>
            </div>

            {/* Grace Period */}
            <div>
              <h4 className="text-sm font-semibold text-yellow-600 mb-3 flex items-center">
                <Clock className="h-4 w-4 mr-1.5" /> Grace Period
              </h4>
              <div className="space-y-3">
                {timelineData.grace.map(item => (
                  <div key={item.id} className="saas-card p-4 border-l-4 border-l-yellow-400">
                    <div className="flex justify-between items-start">
                      <p className="text-sm font-medium text-gray-900">{item.property}</p>
                      <span className="text-xs text-gray-500 bg-gray-100 px-2 py-0.5 rounded">{item.plan}</span>
                    </div>
                    <p className="text-xs text-gray-500 mt-1">{item.expiry}</p>
                    <p className="text-xs font-medium text-yellow-600 mt-1">Grace: {item.graceRemaining}</p>
                  </div>
                ))}
              </div>
            </div>

            {/* Expired */}
            <div>
              <h4 className="text-sm font-semibold text-red-600 mb-3 flex items-center">
                <Ban className="h-4 w-4 mr-1.5" /> Expired
              </h4>
              <div className="space-y-3">
                {timelineData.expired.map(item => (
                  <div key={item.id} className="saas-card p-4 border-l-4 border-l-red-500">
                    <div className="flex justify-between items-start">
                      <p className="text-sm font-medium text-gray-900">{item.property}</p>
                      <span className="text-xs text-gray-500 bg-gray-100 px-2 py-0.5 rounded">{item.plan}</span>
                    </div>
                    <p className="text-xs text-gray-500 mt-1">{item.expiry}</p>
                    <p className="text-xs font-medium text-red-600 mt-1">{item.status}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Enforcement Table Section */}
        <div className="lg:col-span-2 space-y-4">
          <h3 className="text-lg font-semibold text-gray-900">Enforcement Action Required</h3>
          <div className="saas-card overflow-hidden">
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Property</th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Reminders</th>
                    <th className="relative px-6 py-3"><span className="sr-only">Actions</span></th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {enforcementTable.map((row) => (
                    <tr key={row.id} className="hover:bg-gray-50/50">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900">{row.property}</div>
                        <div className="text-xs text-gray-500">Expired: {row.expiry}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`status-badge ${row.status === 'Suspended' ? 'status-error' : 'status-pending'}`}>
                          {row.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {row.reminderSent}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium space-x-2">
                        <button className="text-gray-400 hover:text-pine p-1 rounded transition-colors" title="Send Reminder">
                          <Send className="h-4 w-4" />
                        </button>
                        <button className="text-gray-400 hover:text-pine p-1 rounded transition-colors" title="View Subscription">
                          <Eye className="h-4 w-4" />
                        </button>
                        <button className="text-gray-400 hover:text-pine p-1 rounded transition-colors" title="Manual Renew">
                          <RefreshCw className="h-4 w-4" />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
