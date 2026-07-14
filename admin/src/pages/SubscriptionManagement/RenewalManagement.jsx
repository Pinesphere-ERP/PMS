import { useState, useEffect } from 'react';
import { 
  AlertTriangle,
  Clock,
  Ban,
  ShieldAlert,
  Send,
  Eye,
  RefreshCw,
  MessageCircle,
  Phone,
  FileText,
  CalendarDays,
  ListFilter,
  CheckCircle2,
  Mail,
  Smartphone,
  MoreVertical,
  Activity,
  ArrowRight,
  Loader2,
  AlertCircle,
  Lock
} from 'lucide-react';
import { subscriptionService } from '../../services/subscriptionService';

const fallbackKPIs = [
  { name: 'Renewals Today', value: '0', icon: AlertTriangle, color: 'text-orange-500', bg: 'bg-orange-50' },
  { name: 'Next 7 Days', value: '0', icon: CalendarDays, color: 'text-blue-500', bg: 'bg-blue-50' },
  { name: 'Grace Period', value: '0', icon: Clock, color: 'text-yellow-600', bg: 'bg-yellow-50' },
  { name: 'Enforcement Pending', value: '0', icon: ShieldAlert, color: 'text-purple-600', bg: 'bg-purple-50' },
  { name: 'Renewed Today', value: '0', icon: CheckCircle2, color: 'text-green-500', bg: 'bg-green-50' },
  { name: 'Success Rate', value: '0%', icon: Activity, color: 'text-pine', bg: 'bg-pine/10' },
];

export default function RenewalManagement() {
  const [activeTab, setActiveTab] = useState('upcoming');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [data, setData] = useState({
    kpis: fallbackKPIs,
    upcoming: [],
    grace: [],
    enforcement: [],
    reminders: []
  });

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const result = await subscriptionService.getRenewalData();
        setData({
          kpis: result.kpis?.length ? result.kpis : fallbackKPIs,
          upcoming: result.upcoming || [],
          grace: result.grace || [],
          enforcement: result.enforcement || [],
          reminders: result.reminders || []
        });
      } catch (err) {
        setError(err.message || 'Failed to fetch renewal data');
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  const handleSendReminder = (id, property) => {
    alert(`Triggering manual reminder for ${property} (ID: ${id})`);
  };

  const handleApplyEnforcement = (id, property) => {
    if(window.confirm(`Are you sure you want to enforce lock-out on ${property}?`)) {
      alert(`Enforcement applied to ${property}`);
    }
  };

  const actions = [
    { name: 'Send Mass Reminder', icon: Send },
    { name: 'Run Enforcement Engine', icon: ShieldAlert },
    { name: 'Generate Renewal Report', icon: FileText },
  ];

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center h-[calc(100vh-200px)]">
         <Loader2 className="w-8 h-8 text-pine animate-spin mb-4" />
         <span className="text-gray-500">Loading Renewal Management Data...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-[calc(100vh-200px)]">
        <AlertCircle className="h-10 w-10 text-red-500 mb-4" />
        <p className="text-gray-900 font-medium">Failed to load renewal data</p>
        <p className="text-gray-500 text-sm mt-2">{error}</p>
      </div>
    );
  }

  const { kpis, upcoming, grace, enforcement, reminders } = data;

  return (
    <div className="space-y-6 animate-slide-up">
      <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center space-y-4 sm:space-y-0">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 tracking-tight">Renewal Management</h1>
          <p className="text-sm text-gray-500 mt-1">Track upcoming expiries, manage grace periods, and automate enforcements.</p>
        </div>
        <div className="flex space-x-3">
          {actions.map((act, idx) => (
            <button key={idx} disabled className={`saas-button-${idx === 1 ? 'primary' : 'secondary'} opacity-60 cursor-not-allowed`}>
              <Lock className="h-4 w-4 mr-2" />
              {act.name}
            </button>
          ))}
        </div>
      </div>

      {/* Action Banner */}
      <div className="bg-gradient-to-r from-red-50 to-orange-50 border border-red-100 rounded-xl p-4 flex items-center justify-between shadow-sm">
        <div className="flex items-center">
          <div className="h-10 w-10 rounded-full bg-red-100 flex items-center justify-center">
            <Ban className="h-5 w-5 text-red-600" />
          </div>
          <div className="ml-4">
            <h3 className="text-sm font-bold text-red-900">2 Properties Require Immediate Enforcement</h3>
            <p className="text-xs text-red-700 mt-0.5">Grace period has ended. App access must be restricted.</p>
          </div>
        </div>
        
        <button disabled className="bg-red-600 text-white px-4 py-2 rounded-lg text-sm font-semibold shadow-sm opacity-60 cursor-not-allowed flex items-center">
          <Lock className="h-4 w-4 mr-2" /> Review & Enforce
        </button>
      </div>

      {/* KPI Stats */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        {kpis.map((stat, idx) => {
          const Icon = typeof stat.icon === 'string' ? CalendarDays : (stat.icon || CalendarDays);
          return (
            <div key={idx} className="saas-card p-4 hover:-translate-y-1 transition-transform cursor-pointer">
              <div className="flex justify-between items-start mb-2">
                <div className={`p-2 rounded-lg ${stat.bg}`}>
                  <Icon className={`h-4 w-4 ${stat.color}`} />
                </div>
              </div>
              <h3 className="text-2xl font-bold text-gray-900">{stat.value}</h3>
              <p className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider mt-1">{stat.name}</p>
            </div>
          );
        })}
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        
        {/* Main Work Area */}
        <div className="xl:col-span-2 space-y-6">
          <div className="saas-card overflow-hidden min-h-[400px]">
            {/* Tabs */}
            <div className="flex border-b border-gray-100 px-2 bg-gray-50/50">
              <button 
                onClick={() => setActiveTab('upcoming')}
                className={`px-4 py-4 text-sm font-semibold border-b-2 transition-colors flex items-center ${activeTab === 'upcoming' ? 'border-pine text-pine' : 'border-transparent text-gray-500 hover:text-gray-700'}`}
              >
                <CalendarDays className="w-4 h-4 mr-2"/> Upcoming ({upcoming.length})
              </button>
              <button 
                onClick={() => setActiveTab('grace')}
                className={`px-4 py-4 text-sm font-semibold border-b-2 transition-colors flex items-center ${activeTab === 'grace' ? 'border-yellow-500 text-yellow-600' : 'border-transparent text-gray-500 hover:text-gray-700'}`}
              >
                <Clock className="w-4 h-4 mr-2"/> Grace Period ({grace.length})
              </button>
              <button 
                onClick={() => setActiveTab('enforcement')}
                className={`px-4 py-4 text-sm font-semibold border-b-2 transition-colors flex items-center ${activeTab === 'enforcement' ? 'border-red-500 text-red-600' : 'border-transparent text-gray-500 hover:text-gray-700'}`}
              >
                <ShieldAlert className="w-4 h-4 mr-2"/> Enforcement ({enforcement.length})
              </button>
            </div>

            <div className="p-0">
              {/* UPCOMING TAB */}
              {activeTab === 'upcoming' && (
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-gray-100">
                    <thead className="bg-white">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Property & Plan</th>
                        <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Contact</th>
                        <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Expiry</th>
                        <th className="px-6 py-3 text-right text-xs font-semibold text-gray-500 uppercase">Action</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-50">
                      {upcoming.length === 0 && <tr><td colSpan="4" className="text-center p-4 text-gray-500 text-sm">No upcoming renewals</td></tr>}
                      {upcoming.map((item) => (
                        <tr key={item.id} className="hover:bg-gray-50 transition">
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-sm font-bold text-gray-900">{item.property}</div>
                            <div className="text-xs text-gray-500">{item.plan} • Due: <span className="font-medium text-gray-700">{item.amount}</span></div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-sm text-gray-900">{item.owner}</div>
                            <div className="text-xs text-gray-500 flex items-center mt-0.5"><Phone className="h-3 w-3 mr-1"/> {item.mobile}</div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold ${item.daysRemaining === 0 ? 'bg-orange-100 text-orange-800' : 'bg-blue-100 text-blue-800'}`}>
                              {item.expiryDate}
                            </span>
                            <div className="text-[10px] text-gray-400 mt-1 uppercase tracking-wider">Reminder: {item.reminderStatus}</div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-right">
                            <button disabled className="saas-button-secondary text-xs py-1.5 px-3 opacity-60 cursor-not-allowed flex items-center ml-auto">
                              <Lock className="h-3 w-3 mr-1.5" /> Remind
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}

              {/* GRACE PERIOD TAB */}
              {activeTab === 'grace' && (
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-gray-100">
                    <thead className="bg-yellow-50/50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Property</th>
                        <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Overdue By</th>
                        <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Communication</th>
                        <th className="px-6 py-3 text-right text-xs font-semibold text-gray-500 uppercase">Action</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-50">
                      {grace.length === 0 && <tr><td colSpan="4" className="text-center p-4 text-gray-500 text-sm">No properties in grace period</td></tr>}
                      {grace.map((item) => (
                        <tr key={item.id} className="hover:bg-yellow-50/30 transition">
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-sm font-bold text-gray-900">{item.property}</div>
                            <div className="text-xs text-gray-500">{item.plan} • Due: {item.amountDue}</div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="flex items-center text-yellow-600 font-bold text-sm">
                              <AlertTriangle className="h-4 w-4 mr-1.5" /> Day {item.graceDay} of 7
                            </div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-xs font-medium text-gray-900">{item.reminderCount} Reminders Sent</div>
                            <div className="text-[10px] text-gray-500 mt-0.5">Last: {item.lastReminder}</div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-right">
                            <button disabled className="saas-button-primary bg-yellow-500 text-xs py-1.5 px-3 opacity-60 cursor-not-allowed flex items-center ml-auto">
                              <Lock className="h-3 w-3 mr-1.5" /> Follow Up
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}

              {/* ENFORCEMENT TAB */}
              {activeTab === 'enforcement' && (
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-gray-100">
                    <thead className="bg-red-50/50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Property</th>
                        <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Violation</th>
                        <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">System Status</th>
                        <th className="px-6 py-3 text-right text-xs font-semibold text-gray-500 uppercase">Action</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-50">
                      {enforcement.length === 0 && <tr><td colSpan="4" className="text-center p-4 text-gray-500 text-sm">No properties pending enforcement</td></tr>}
                      {enforcement.map((item) => (
                        <tr key={item.id} className="hover:bg-red-50/30 transition">
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-sm font-bold text-gray-900">{item.property}</div>
                            <div className="text-xs text-red-600 font-medium">Due: {item.outstandingAmount}</div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-sm text-gray-900">{item.daysOverdue} Days Overdue</div>
                            <div className="text-xs text-gray-500">Expired: {item.expiredOn}</div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            {item.status === 'Applied' ? (
                              <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-bold bg-red-100 text-red-800 border border-red-200">
                                <Ban className="h-3 w-3 mr-1" /> Locked Out
                              </span>
                            ) : (
                              <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-bold bg-orange-100 text-orange-800 border border-orange-200 animate-pulse">
                                <Clock className="h-3 w-3 mr-1" /> Pending Enforcement
                              </span>
                            )}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-right">
                            {item.status === 'Pending' ? (
                              <button disabled className="saas-button-primary bg-red-600 text-xs py-1.5 px-3 opacity-60 cursor-not-allowed flex items-center ml-auto">
                                <Lock className="h-3 w-3 mr-1.5" /> Enforce Now
                              </button>
                            ) : (
                              <button disabled className="saas-button-secondary text-xs py-1.5 px-3 opacity-60 cursor-not-allowed flex items-center ml-auto">
                                <Lock className="h-3 w-3 mr-1.5" /> View Details
                              </button>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Right Sidebar */}
        <div className="space-y-6">
          <div className="saas-card p-6">
            <h3 className="text-sm font-bold text-gray-900 mb-4 flex items-center">
              <MessageCircle className="h-4 w-4 mr-2 text-pine" /> Communication Log
            </h3>
            <div className="space-y-4">
              {reminders.length === 0 && <p className="text-sm text-gray-500 text-center">No recent communication logs</p>}
              {reminders.map((item) => (
                <div key={item.id} className="flex gap-3 border-b border-gray-50 pb-4 last:border-0 last:pb-0">
                  <div className={`mt-0.5 h-8 w-8 rounded-full flex items-center justify-center shrink-0 ${
                    item.type === 'WhatsApp' ? 'bg-green-100 text-green-600' :
                    item.type === 'Email' ? 'bg-blue-100 text-blue-600' :
                    'bg-gray-100 text-gray-600'
                  }`}>
                    {item.type === 'WhatsApp' ? <Smartphone className="h-4 w-4" /> : <Mail className="h-4 w-4" />}
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-gray-900">{item.property}</p>
                    <p className="text-xs text-gray-500 mt-0.5 flex items-center">
                      {item.type} • {item.date} 
                      {item.status === 'Delivered' && <CheckCircle2 className="h-3 w-3 text-green-500 ml-1" />}
                    </p>
                  </div>
                </div>
              ))}
            </div>
            <button disabled className="w-full mt-4 text-xs font-semibold text-pine bg-pine/5 py-2 rounded-lg opacity-60 cursor-not-allowed flex items-center justify-center">
              <Lock className="h-4 w-4 mr-2" /> View All Logs
            </button>
          </div>

          <div className="saas-card p-6 relative overflow-hidden">
            <div className="absolute inset-0 bg-white/50 backdrop-blur-[2px] flex flex-col items-center justify-center z-10">
              <div className="bg-white p-3 rounded-full shadow-sm mb-2 border border-gray-100">
                <Lock className="h-5 w-5 text-gray-500" />
              </div>
              <span className="text-xs font-bold text-gray-800">Feature Locked</span>
            </div>
            <h3 className="text-sm font-bold text-gray-900 mb-4 flex items-center">
              <CalendarDays className="h-4 w-4 mr-2 text-pine" /> Expiry Calendar
            </h3>
            <div className="bg-gray-50 rounded-xl border border-gray-100 p-4 text-center">
              <p className="text-sm text-gray-600">Calendar visualization will load from API automatically.</p>
              <button disabled className="mt-4 saas-button-secondary text-xs w-full justify-center opacity-60 cursor-not-allowed flex items-center">
                <Lock className="h-4 w-4 mr-2" /> Open Full Calendar
              </button>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
}
