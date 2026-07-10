import { useState, useRef, useEffect } from 'react';
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
  ArrowRight
} from 'lucide-react';

const mockKPIs = [
  { name: 'Renewals Today', value: '8', icon: AlertTriangle, color: 'text-orange-500', bg: 'bg-orange-50' },
  { name: 'Next 7 Days', value: '24', icon: CalendarDays, color: 'text-blue-500', bg: 'bg-blue-50' },
  { name: 'Grace Period', value: '5', icon: Clock, color: 'text-yellow-600', bg: 'bg-yellow-50' },
  { name: 'Enforcement Pending', value: '2', icon: ShieldAlert, color: 'text-purple-600', bg: 'bg-purple-50' },
  { name: 'Renewed Today', value: '12', icon: CheckCircle2, color: 'text-green-500', bg: 'bg-green-50' },
  { name: 'Success Rate', value: '78%', icon: Activity, color: 'text-pine', bg: 'bg-pine/10' },
];

const mockUpcoming = [
  { id: 1, property: 'Sunset Villa', owner: 'Robert Brown', mobile: '+1 555-0105', plan: 'Basic', expiryDate: 'Today', daysRemaining: 0, amount: '$199.00', reminderStatus: 'Sent' },
  { id: 2, property: 'Oceanside Resort', owner: 'Jane Smith', mobile: '+1 555-0102', plan: 'Enterprise', expiryDate: 'Tomorrow', daysRemaining: 1, amount: '$999.00', reminderStatus: 'Pending' },
  { id: 3, property: 'Lakeview Cabins', owner: 'Alice Cooper', mobile: '+1 555-0110', plan: 'Professional', expiryDate: 'In 3 Days', daysRemaining: 3, amount: '$499.00', reminderStatus: 'Pending' },
];

const mockGrace = [
  { id: 4, property: 'Mountain Inn', plan: 'Professional', graceDay: 1, amountDue: '$499.00', reminderCount: 2, lastReminder: 'Today 09:00 AM', contactStatus: 'Contacted' },
  { id: 5, property: 'Valley Lodge', plan: 'Basic', graceDay: 3, amountDue: '$199.00', reminderCount: 4, lastReminder: 'Yesterday 04:30 PM', contactStatus: 'Not Contacted' },
  { id: 6, property: 'Desert Oasis', plan: 'Enterprise', graceDay: 5, amountDue: '$999.00', reminderCount: 5, lastReminder: 'Today 08:15 AM', contactStatus: 'Contacted' },
];

const mockEnforcement = [
  { id: 7, property: 'City Lights Hostel', plan: 'Basic', expiredOn: '2025-06-25', graceEndDate: '2025-06-30', daysOverdue: 10, outstandingAmount: '$199.00', status: 'Applied' },
  { id: 8, property: 'Grand Plaza Hotel (Old Branch)', plan: 'Enterprise', expiredOn: '2025-07-01', graceEndDate: '2025-07-06', daysOverdue: 4, outstandingAmount: '$1999.00', status: 'Pending' },
];

const mockReminders = [
  { id: 9, date: 'Today 09:00 AM', property: 'Mountain Inn', type: 'WhatsApp', sentBy: 'System', status: 'Delivered', response: 'Pending' },
  { id: 10, date: 'Today 08:15 AM', property: 'Desert Oasis', type: 'Call', sentBy: 'Admin (Sarah)', status: 'Answered', response: 'Promised Payment' },
  { id: 11, date: 'Yesterday 04:30 PM', property: 'Valley Lodge', type: 'Email', sentBy: 'System', status: 'Failed', response: '-' },
  { id: 12, date: 'Yesterday 10:00 AM', property: 'Sunset Villa', type: 'SMS', sentBy: 'System', status: 'Delivered', response: 'Paid' },
];

const ActionDropdown = ({ property, actions, onAction }) => {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleAction = (actionKey) => {
    setIsOpen(false);
    onAction(actionKey, property);
  };

  return (
    <div className="relative" ref={dropdownRef}>
      <button 
        onClick={(e) => { e.stopPropagation(); setIsOpen(!isOpen); }}
        className="text-gray-400 hover:text-gray-900 p-1 rounded-full hover:bg-gray-100 transition-colors"
      >
        <MoreVertical className="h-5 w-5" />
      </button>
      
      {isOpen && (
        <div className="absolute right-0 mt-2 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 z-20">
          <div className="py-1" role="menu">
            {actions.map((act, idx) => (
              <button 
                key={idx} 
                onClick={(e) => { e.stopPropagation(); handleAction(act.key); }} 
                className={`flex items-center w-full px-4 py-2 text-sm hover:bg-gray-100 ${act.danger ? 'text-red-600' : 'text-gray-700'}`}
              >
                <act.icon className={`mr-3 h-4 w-4 ${act.danger ? 'text-red-600' : 'text-gray-400'}`} /> {act.label}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default function RenewalManagement() {
  const [activeTab, setActiveTab] = useState('upcoming');
  const [searchQuery, setSearchQuery] = useState('');

  const handleAction = (actionKey, property) => {
    console.log(`Action: ${actionKey} on property: ${property.property}`);
  };

  const upcomingActions = [
    { key: 'view', label: 'View Property', icon: Eye },
    { key: 'remind', label: 'Send Reminder', icon: Send },
    { key: 'whatsapp', label: 'WhatsApp Reminder', icon: MessageCircle },
    { key: 'call', label: 'Call Owner', icon: Phone },
    { key: 'renew', label: 'Renew Subscription', icon: RefreshCw },
  ];

  const graceActions = [
    { key: 'remind', label: 'Send Reminder', icon: Send },
    { key: 'payment_link', label: 'Send Payment Link', icon: FileText },
    { key: 'call', label: 'Call Owner', icon: Phone },
    { key: 'extend', label: 'Extend Grace Period', icon: Clock },
    { key: 'renew', label: 'Renew Subscription', icon: RefreshCw },
  ];

  const enforcementActions = [
    { key: 'disable', label: 'Disable Property', icon: Ban, danger: true },
    { key: 'extend', label: 'Extend Subscription', icon: Clock },
    { key: 'remove', label: 'Remove Enforcement', icon: ShieldAlert },
    { key: 'invoice', label: 'Generate Invoice', icon: FileText },
    { key: 'contact', label: 'Contact Owner', icon: Phone },
  ];

  const renderVisualDayIndicator = (day) => {
    return (
      <div className="flex items-center space-x-1">
        {[1, 2, 3, 4, 5].map((d) => (
          <div 
            key={d} 
            className={`h-2.5 w-2.5 rounded-full ${
              d > day ? 'bg-gray-200' : 
              day <= 2 ? 'bg-green-500' : 
              day === 3 ? 'bg-yellow-400' : 
              day === 4 ? 'bg-orange-500' : 'bg-red-500'
            }`}
            title={`Day ${d}`}
          />
        ))}
        <span className="ml-2 text-xs font-medium text-gray-500">Day {day}</span>
      </div>
    );
  };

  return (
    <div className="space-y-6 animate-slide-up pb-20">
      <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center space-y-4 sm:space-y-0">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 tracking-tight">Renewal Management</h1>
          <p className="text-sm text-gray-500 mt-1">Proactively monitor subscriptions, grace periods, and enforcement.</p>
        </div>
        <div className="flex space-x-3">
          <button className="saas-button-secondary">
            <Send className="h-4 w-4 mr-2" /> Bulk Reminders
          </button>
          <button className="saas-button-secondary">
            <FileText className="h-4 w-4 mr-2" /> Export Report
          </button>
          <button className="saas-button-primary">
            <RefreshCw className="h-4 w-4 mr-2" /> Generate Invoices
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        {mockKPIs.map((stat) => (
          <div key={stat.name} className="saas-card p-4">
            <div className="flex justify-between items-start">
              <p className="text-sm font-medium text-gray-500 truncate">{stat.name}</p>
              <stat.icon className={`h-4 w-4 ${stat.color}`} />
            </div>
            <p className="mt-2 text-2xl font-semibold text-gray-900">{stat.value}</p>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm space-y-4">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="relative flex-1">
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <ListFilter className="h-4 w-4 text-gray-400" />
            </div>
            <input
              type="text"
              className="saas-input pl-9 w-full"
              placeholder="Search property name or owner..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
          <div className="flex flex-wrap gap-2">
            <select className="saas-select text-sm py-2">
              <option value="">Date Range: All</option>
              <option value="today">Today</option>
              <option value="tomorrow">Tomorrow</option>
              <option value="this_week">This Week</option>
              <option value="next_week">Next Week</option>
            </select>
            <select className="saas-select text-sm py-2">
              <option value="">Status: All</option>
              <option value="upcoming">Upcoming</option>
              <option value="grace">Grace Period</option>
              <option value="overdue">Overdue</option>
              <option value="renewed">Renewed</option>
            </select>
            <select className="saas-select text-sm py-2 hidden sm:block">
              <option value="">Property Type</option>
              <option value="Hotel">Hotel</option>
              <option value="Resort">Resort</option>
            </select>
          </div>
        </div>
      </div>

      {/* Tab Navigation */}
      <div className="border-b border-gray-200">
        <nav className="-mb-px flex space-x-8">
          <button
            onClick={() => setActiveTab('upcoming')}
            className={`whitespace-nowrap pb-4 px-1 border-b-2 font-medium text-sm ${
              activeTab === 'upcoming' ? 'border-pine text-pine' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            Upcoming Renewals
          </button>
          <button
            onClick={() => setActiveTab('grace')}
            className={`whitespace-nowrap pb-4 px-1 border-b-2 font-medium text-sm ${
              activeTab === 'grace' ? 'border-pine text-pine' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            Grace Period
            <span className="ml-2 bg-yellow-100 text-yellow-800 py-0.5 px-2 rounded-full text-xs">5</span>
          </button>
          <button
            onClick={() => setActiveTab('enforcement')}
            className={`whitespace-nowrap pb-4 px-1 border-b-2 font-medium text-sm ${
              activeTab === 'enforcement' ? 'border-pine text-pine' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            Enforcement Queue
            <span className="ml-2 bg-red-100 text-red-800 py-0.5 px-2 rounded-full text-xs">2</span>
          </button>
          <button
            onClick={() => setActiveTab('activity')}
            className={`whitespace-nowrap pb-4 px-1 border-b-2 font-medium text-sm ${
              activeTab === 'activity' ? 'border-pine text-pine' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            Reminder Activity
          </button>
          <button
            onClick={() => setActiveTab('calendar')}
            className={`whitespace-nowrap pb-4 px-1 border-b-2 font-medium text-sm ${
              activeTab === 'calendar' ? 'border-pine text-pine' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            Calendar View
          </button>
        </nav>
      </div>

      {/* Tab Content */}
      <div className="saas-card overflow-hidden">
        {/* Upcoming Renewals Tab */}
        {activeTab === 'upcoming' && (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Property</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Expiry</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Amount</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Reminder</th>
                  <th className="relative px-6 py-3"><span className="sr-only">Actions</span></th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {mockUpcoming.map((item) => (
                  <tr key={item.id} className="hover:bg-gray-50/50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">{item.property}</div>
                      <div className="text-xs text-gray-500">{item.owner} • {item.mobile}</div>
                      <span className="inline-flex items-center px-2 py-0.5 mt-1 rounded text-[10px] font-medium bg-gray-100 text-gray-800">{item.plan}</span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className={`text-sm font-medium ${item.daysRemaining === 0 ? 'text-red-600' : 'text-gray-900'}`}>{item.expiryDate}</div>
                      <div className="text-xs text-gray-500">{item.daysRemaining} days left</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 font-medium">
                      {item.amount}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex items-center px-2 py-1 rounded-md text-xs font-medium ${item.reminderStatus === 'Sent' ? 'bg-green-50 text-green-700 ring-1 ring-green-600/20' : 'bg-yellow-50 text-yellow-700 ring-1 ring-yellow-600/20'}`}>
                        {item.reminderStatus}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <ActionDropdown property={item} actions={upcomingActions} onAction={handleAction} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Grace Period Tab */}
        {activeTab === 'grace' && (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Property</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Grace Day</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Amount Due</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Contact Status</th>
                  <th className="relative px-6 py-3"><span className="sr-only">Actions</span></th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {mockGrace.map((item) => (
                  <tr key={item.id} className="hover:bg-gray-50/50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">{item.property}</div>
                      <span className="inline-flex items-center px-2 py-0.5 mt-1 rounded text-[10px] font-medium bg-gray-100 text-gray-800">{item.plan}</span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {renderVisualDayIndicator(item.graceDay)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-red-600 font-medium">
                      {item.amountDue}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">{item.contactStatus}</div>
                      <div className="text-xs text-gray-500">{item.reminderCount} Reminders • Last: {item.lastReminder}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <ActionDropdown property={item} actions={graceActions} onAction={handleAction} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Enforcement Queue Tab */}
        {activeTab === 'enforcement' && (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Property</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Overdue Timeline</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Amount Due</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Enforcement Status</th>
                  <th className="relative px-6 py-3"><span className="sr-only">Actions</span></th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {mockEnforcement.map((item) => (
                  <tr key={item.id} className="hover:bg-gray-50/50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">{item.property}</div>
                      <span className="inline-flex items-center px-2 py-0.5 mt-1 rounded text-[10px] font-medium bg-gray-100 text-gray-800">{item.plan}</span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-red-600">{item.daysOverdue} Days Overdue</div>
                      <div className="text-xs text-gray-500 mt-1">Expired: {item.expiredOn}</div>
                      <div className="text-xs text-gray-500">Grace Ended: {item.graceEndDate}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 font-medium">
                      {item.outstandingAmount}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex items-center px-2 py-1 rounded-md text-xs font-medium ${item.status === 'Applied' ? 'bg-red-50 text-red-700 ring-1 ring-red-600/20' : 'bg-yellow-50 text-yellow-700 ring-1 ring-yellow-600/20'}`}>
                        {item.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <ActionDropdown property={item} actions={enforcementActions} onAction={handleAction} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Reminder Activity Tab */}
        {activeTab === 'activity' && (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Date</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Property</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Reminder Type</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Sent By</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Status & Response</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {mockReminders.map((item) => (
                  <tr key={item.id} className="hover:bg-gray-50/50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {item.date}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {item.property}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="inline-flex items-center text-sm text-gray-700">
                        {item.type === 'WhatsApp' ? <MessageCircle className="h-4 w-4 mr-2 text-green-500" /> : 
                         item.type === 'Call' ? <Phone className="h-4 w-4 mr-2 text-blue-500" /> : 
                         item.type === 'Email' ? <Mail className="h-4 w-4 mr-2 text-gray-500" /> :
                         <Smartphone className="h-4 w-4 mr-2 text-gray-500" />}
                        {item.type}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {item.sentBy}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex flex-col space-y-1">
                        <span className={`text-xs font-medium ${item.status === 'Delivered' || item.status === 'Answered' ? 'text-green-600' : 'text-red-600'}`}>
                          {item.status}
                        </span>
                        <span className="text-xs text-gray-500">Response: {item.response}</span>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Calendar View Tab */}
        {activeTab === 'calendar' && (
          <div className="p-6">
            <div className="mb-6 flex justify-between items-center">
              <h3 className="text-lg font-semibold text-gray-900">July 2026</h3>
              <div className="flex space-x-2">
                <button className="p-1.5 rounded-md border border-gray-200 hover:bg-gray-50"><ArrowRight className="h-4 w-4 rotate-180" /></button>
                <button className="p-1.5 rounded-md border border-gray-200 hover:bg-gray-50"><ArrowRight className="h-4 w-4" /></button>
              </div>
            </div>
            
            <div className="grid grid-cols-7 gap-px bg-gray-200 rounded-lg overflow-hidden border border-gray-200">
              {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(day => (
                <div key={day} className="bg-gray-50 py-2 text-center text-xs font-semibold text-gray-500 uppercase tracking-wider">
                  {day}
                </div>
              ))}
              
              {/* Dummy Calendar Grid for Mockup */}
              {Array.from({ length: 31 }).map((_, i) => {
                const day = i + 1;
                // Mock some renewals on specific dates
                const hasRenewal = [10, 12, 15, 25].includes(day);
                const isToday = day === 10;
                
                return (
                  <div key={i} className={`bg-white min-h-[100px] p-2 hover:bg-gray-50 ${isToday ? 'bg-pine/5' : ''}`}>
                    <div className={`text-sm font-medium ${isToday ? 'text-pine' : 'text-gray-900'}`}>{day}</div>
                    {hasRenewal && (
                      <div className="mt-2 space-y-1">
                        <div className="text-[10px] bg-orange-100 text-orange-800 px-1.5 py-0.5 rounded truncate" title="Sunset Villa">Sunset Villa</div>
                        {day === 12 && <div className="text-[10px] bg-blue-100 text-blue-800 px-1.5 py-0.5 rounded truncate" title="Oceanside Resort">Oceanside Resort</div>}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
