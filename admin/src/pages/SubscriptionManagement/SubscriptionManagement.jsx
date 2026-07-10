import { useState, useRef, useEffect } from 'react';
import { 
  Search, 
  Filter, 
  MoreVertical, 
  X, 
  CheckCircle2, 
  Ban, 
  ShieldCheck, 
  Calendar,
  CreditCard,
  ChevronRight,
  Smartphone,
  RefreshCw,
  Plus,
  Minus,
  Power,
  Key,
  Activity,
  ArrowUpCircle,
  ArrowDownCircle,
  AlertCircle,
  Trash2,
  FileText,
  MapPin,
  Clock,
  User,
  Phone
} from 'lucide-react';

const mockSubscriptions = [
  { 
    id: '1', 
    propertyName: 'Grand Plaza Hotel', 
    propertyType: 'Hotel',
    propertyId: 'PROP-1001',
    city: 'New York',
    state: 'NY',
    ownerName: 'John Doe', 
    ownerMobile: '+1 555-0101',
    ownerWhatsApp: '+1 555-0101',
    plan: 'Professional', 
    startDate: '2025-01-01', 
    expiryDate: '2026-01-01', 
    remainingDays: 365, 
    billingCycle: 'Yearly',
    status: 'Active', 
    licenseId: 'PS-LIC-2026-00125',
    licenseStatus: 'Valid',
    licenseIssueDate: '2025-01-01',
    deviceLimit: 50,
    registeredDevices: 15,
    lastPayment: '$499.00',
    lastInvoice: 'INV-2025-001',
    nextRenewal: '2026-01-01',
    outstandingAmount: '$0.00',
    primaryDevice: 'Front Desk Terminal 1',
    lastSync: 'Today 09:45 AM',
    deviceStatus: 'Active',
    totalPaid: '$499.00',
    recentActivities: [
      { date: '2025-01-01', action: 'Subscription Created', by: 'System' },
      { date: '2025-01-01', action: 'License Generated', by: 'System' }
    ],
    devicesList: [
      { name: 'Reception Tablet', status: 'Active', lastLogin: 'Today' },
      { name: 'Owner Mobile', status: 'Active', lastLogin: 'Yesterday' }
    ]
  },
  { 
    id: '2', 
    propertyName: 'Sea View Resort', 
    propertyType: 'Resort',
    propertyId: 'PROP-1002',
    city: 'Miami',
    state: 'FL',
    ownerName: 'Jane Smith', 
    ownerMobile: '+1 555-0102',
    ownerWhatsApp: '+1 555-0102',
    plan: 'Enterprise', 
    startDate: '2025-03-15', 
    expiryDate: '2025-09-15', 
    remainingDays: 45, 
    billingCycle: 'Yearly',
    status: 'Active', 
    licenseId: 'PS-LIC-2026-00126',
    licenseStatus: 'Valid',
    licenseIssueDate: '2025-03-15',
    deviceLimit: 100,
    registeredDevices: 42,
    lastPayment: '$999.00',
    lastInvoice: 'INV-2025-002',
    nextRenewal: '2025-09-15',
    outstandingAmount: '$0.00',
    primaryDevice: 'Main Server',
    lastSync: 'Today 10:15 AM',
    deviceStatus: 'Active',
    totalPaid: '$1998.00',
    recentActivities: [
      { date: '2025-03-15', action: 'Renewed', by: 'Admin' },
      { date: '2025-03-15', action: 'License Generated', by: 'System' }
    ],
    devicesList: [
      { name: 'Main Server', status: 'Active', lastLogin: 'Today' },
      { name: 'Manager Phone', status: 'Active', lastLogin: 'Today' },
      { name: 'Backup Device', status: 'Pending Approval', lastLogin: '-' }
    ]
  },
  { 
    id: '3', 
    propertyName: 'City Lights Hostel', 
    propertyType: 'Hostel',
    propertyId: 'PROP-1003',
    city: 'Chicago',
    state: 'IL',
    ownerName: 'Mike Johnson', 
    ownerMobile: '+1 555-0103',
    ownerWhatsApp: '+1 555-0103',
    plan: 'Basic', 
    startDate: '2024-05-10', 
    expiryDate: '2025-05-10', 
    remainingDays: 0, 
    billingCycle: 'Yearly',
    status: 'Expired', 
    licenseId: 'PS-LIC-2025-00080',
    licenseStatus: 'Expired',
    licenseIssueDate: '2024-05-10',
    deviceLimit: 10,
    registeredDevices: 5,
    lastPayment: '$199.00',
    lastInvoice: 'INV-2024-050',
    nextRenewal: '2025-05-10',
    outstandingAmount: '$199.00',
    primaryDevice: 'Reception PC',
    lastSync: 'Yesterday 11:30 PM',
    deviceStatus: 'Inactive',
    totalPaid: '$199.00',
    recentActivities: [
      { date: '2025-05-11', action: 'Subscription Expired', by: 'System' },
    ],
    devicesList: [
      { name: 'Reception PC', status: 'Inactive', lastLogin: 'Yesterday' }
    ]
  },
  { 
    id: '4', 
    propertyName: 'Mountain Inn', 
    propertyType: 'Homestay',
    propertyId: 'PROP-1004',
    city: 'Denver',
    state: 'CO',
    ownerName: 'Sarah Wilson', 
    ownerMobile: '+1 555-0104',
    ownerWhatsApp: '+1 555-0104',
    plan: 'Professional', 
    startDate: '2025-02-20', 
    expiryDate: '2026-02-20', 
    remainingDays: 2, 
    billingCycle: 'Yearly',
    status: 'Grace Period', 
    licenseId: 'PS-LIC-2025-00200',
    licenseStatus: 'Expiring Soon',
    licenseIssueDate: '2025-02-20',
    deviceLimit: 50,
    registeredDevices: 12,
    lastPayment: '$499.00',
    lastInvoice: 'INV-2025-080',
    nextRenewal: '2026-02-20',
    outstandingAmount: '$499.00',
    primaryDevice: 'Front Desk',
    lastSync: 'Today 08:00 AM',
    deviceStatus: 'Active',
    totalPaid: '$499.00',
    recentActivities: [
      { date: '2026-02-18', action: 'Entered Grace Period', by: 'System' },
    ],
    devicesList: [
      { name: 'Front Desk', status: 'Active', lastLogin: 'Today' }
    ]
  },
  { 
    id: '5', 
    propertyName: 'Sunset Villa', 
    propertyType: 'Villa',
    propertyId: 'PROP-1005',
    city: 'Los Angeles',
    state: 'CA',
    ownerName: 'Robert Brown', 
    ownerMobile: '+1 555-0105',
    ownerWhatsApp: '+1 555-0105',
    plan: 'Basic', 
    startDate: '2025-01-10', 
    expiryDate: '2026-01-10', 
    remainingDays: 300, 
    billingCycle: 'Monthly',
    status: 'Disabled', 
    licenseId: 'PS-LIC-2025-00100',
    licenseStatus: 'Revoked',
    licenseIssueDate: '2025-01-10',
    deviceLimit: 5,
    registeredDevices: 2,
    lastPayment: '$19.00',
    lastInvoice: 'INV-2025-010',
    nextRenewal: '2026-01-10',
    outstandingAmount: '$0.00',
    primaryDevice: 'Admin iPad',
    lastSync: '2 Weeks Ago',
    deviceStatus: 'Revoked',
    totalPaid: '$19.00',
    recentActivities: [
      { date: '2025-03-01', action: 'Property Disabled', by: 'Super Admin' },
    ],
    devicesList: [
      { name: 'Admin iPad', status: 'Revoked', lastLogin: '2 Weeks Ago' }
    ]
  },
];

const ActionDropdown = ({ property, onAction }) => {
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

  const handleAction = (action) => {
    setIsOpen(false);
    onAction(action, property);
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
        <div className="absolute right-0 mt-2 w-56 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 z-20">
          <div className="py-1" role="menu">
            <button onClick={(e) => { e.stopPropagation(); handleAction('view'); }} className="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
              <Activity className="mr-3 h-4 w-4 text-gray-400" /> View Details
            </button>
            <div className="border-t border-gray-100 my-1"></div>
            <button onClick={(e) => { e.stopPropagation(); handleAction('upgrade'); }} className="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
              <ArrowUpCircle className="mr-3 h-4 w-4 text-green-500" /> Upgrade Plan
            </button>
            <button onClick={(e) => { e.stopPropagation(); handleAction('downgrade'); }} className="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
              <ArrowDownCircle className="mr-3 h-4 w-4 text-orange-500" /> Downgrade Plan
            </button>
            <button onClick={(e) => { e.stopPropagation(); handleAction('renew'); }} className="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
              <RefreshCw className="mr-3 h-4 w-4 text-blue-500" /> Renew Subscription
            </button>
            <button onClick={(e) => { e.stopPropagation(); handleAction('extend'); }} className="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
              <Calendar className="mr-3 h-4 w-4 text-purple-500" /> Extend Validity
            </button>
            <div className="border-t border-gray-100 my-1"></div>
            <button onClick={(e) => { e.stopPropagation(); handleAction('license'); }} className="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
              <Key className="mr-3 h-4 w-4 text-yellow-600" /> Generate License
            </button>
            <button onClick={(e) => { e.stopPropagation(); handleAction('payments'); }} className="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
              <CreditCard className="mr-3 h-4 w-4 text-gray-400" /> View Payments
            </button>
            <div className="border-t border-gray-100 my-1"></div>
            {property.status === 'Disabled' ? (
              <button onClick={(e) => { e.stopPropagation(); handleAction('enable'); }} className="flex items-center w-full px-4 py-2 text-sm text-green-600 hover:bg-gray-100">
                <CheckCircle2 className="mr-3 h-4 w-4" /> Enable Property
              </button>
            ) : (
              <>
                <button onClick={(e) => { e.stopPropagation(); handleAction('toggle'); }} className="flex items-center w-full px-4 py-2 text-sm text-orange-600 hover:bg-gray-100">
                  <Power className="mr-3 h-4 w-4" /> Toggle Subscription
                </button>
                <button onClick={(e) => { e.stopPropagation(); handleAction('disable'); }} className="flex items-center w-full px-4 py-2 text-sm text-red-600 hover:bg-gray-100">
                  <Ban className="mr-3 h-4 w-4" /> Disable Property
                </button>
              </>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default function SubscriptionManagement() {
  const [selectedProp, setSelectedProp] = useState(null);
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  // KPIs
  const totalSubscriptions = mockSubscriptions.length;
  const activePlans = mockSubscriptions.filter(s => s.status === 'Active' || s.status === 'Grace Period').length;
  const expiredPlans = mockSubscriptions.filter(s => s.status === 'Expired').length;
  const disabledSubscriptions = mockSubscriptions.filter(s => s.status === 'Disabled').length;
  const upgradesThisMonth = 12; // Mock value
  const downgradesThisMonth = 3; // Mock value

  const handleOpenDrawer = (prop) => {
    setSelectedProp(prop);
    setTimeout(() => setIsDrawerOpen(true), 10);
  };

  const handleCloseDrawer = () => {
    setIsDrawerOpen(false);
    setTimeout(() => setSelectedProp(null), 300);
  };

  const handleRowAction = (action, property) => {
    if (action === 'view') {
      handleOpenDrawer(property);
    } else {
      console.log(`Action: ${action} on property: ${property.propertyName}`);
      // Implement specific actions here, e.g. open a modal for Upgrade
      // alert(`Action "${action}" triggered for ${property.propertyName}`);
    }
  };

  const filteredSubscriptions = mockSubscriptions.filter(sub => {
    if (!searchQuery) return true;
    const lowerQuery = searchQuery.toLowerCase();
    return sub.propertyName.toLowerCase().includes(lowerQuery) ||
           sub.ownerName.toLowerCase().includes(lowerQuery) ||
           sub.licenseId.toLowerCase().includes(lowerQuery);
  });

  const getStatusBadge = (status) => {
    switch (status) {
      case 'Active': return 'status-active';
      case 'Expired': return 'status-error';
      case 'Disabled': return 'bg-gray-100 text-gray-800 border-gray-200';
      case 'Grace Period': return 'status-pending';
      default: return 'status-pending';
    }
  };

  return (
    <div className="space-y-6 animate-slide-up relative pb-20">
      <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center space-y-4 sm:space-y-0">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 tracking-tight">Manage Subscriptions</h1>
          <p className="text-sm text-gray-500 mt-1">Manage the complete subscription lifecycle for every onboarded property.</p>
        </div>
      </div>

      {/* KPIs */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        <div className="saas-card p-4">
          <p className="text-sm font-medium text-gray-500 truncate">Total Subscriptions</p>
          <p className="mt-2 text-2xl font-semibold text-gray-900">{totalSubscriptions}</p>
        </div>
        <div className="saas-card p-4">
          <p className="text-sm font-medium text-gray-500 truncate">Active Plans</p>
          <p className="mt-2 text-2xl font-semibold text-green-600">{activePlans}</p>
        </div>
        <div className="saas-card p-4">
          <p className="text-sm font-medium text-gray-500 truncate">Expired Plans</p>
          <p className="mt-2 text-2xl font-semibold text-red-600">{expiredPlans}</p>
        </div>
        <div className="saas-card p-4">
          <p className="text-sm font-medium text-gray-500 truncate">Disabled</p>
          <p className="mt-2 text-2xl font-semibold text-gray-900">{disabledSubscriptions}</p>
        </div>
        <div className="saas-card p-4">
          <p className="text-sm font-medium text-gray-500 truncate">Upgrades This Month</p>
          <p className="mt-2 text-2xl font-semibold text-blue-600">{upgradesThisMonth}</p>
        </div>
        <div className="saas-card p-4">
          <p className="text-sm font-medium text-gray-500 truncate">Downgrades</p>
          <p className="mt-2 text-2xl font-semibold text-orange-600">{downgradesThisMonth}</p>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm space-y-4">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="relative flex-1">
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <Search className="h-4 w-4 text-gray-400" />
            </div>
            <input
              type="text"
              className="saas-input pl-9 w-full"
              placeholder="Search property name, owner, or license ID..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
          <div className="flex flex-wrap gap-2">
            <select className="saas-select text-sm py-2">
              <option value="">All Statuses</option>
              <option value="Active">Active</option>
              <option value="Grace Period">Grace Period</option>
              <option value="Expired">Expired</option>
              <option value="Disabled">Disabled</option>
            </select>
            <select className="saas-select text-sm py-2">
              <option value="">All Plans</option>
              <option value="Basic">Basic</option>
              <option value="Professional">Professional</option>
              <option value="Enterprise">Enterprise</option>
            </select>
            <select className="saas-select text-sm py-2 hidden sm:block">
              <option value="">Billing Cycle</option>
              <option value="Monthly">Monthly</option>
              <option value="Yearly">Yearly</option>
            </select>
            <button className="saas-button-secondary py-2">
              <Filter className="h-4 w-4 mr-2 text-gray-500" />
              More Filters
            </button>
          </div>
        </div>
      </div>

      {/* Data Table */}
      <div className="saas-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th scope="col" className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Property & Owner</th>
                <th scope="col" className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Subscription</th>
                <th scope="col" className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">License & Devices</th>
                <th scope="col" className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Payment</th>
                <th scope="col" className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Health</th>
                <th scope="col" className="relative px-4 py-3"><span className="sr-only">Actions</span></th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredSubscriptions.map((sub) => (
                <tr key={sub.id} className="hover:bg-gray-50/50 cursor-pointer transition-colors" onClick={() => handleOpenDrawer(sub)}>
                  <td className="px-4 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{sub.propertyName}</div>
                    <div className="text-xs text-gray-500 mt-1">{sub.propertyType} • {sub.city}</div>
                    <div className="text-xs text-gray-500 mt-1 flex items-center">
                      <User className="h-3 w-3 mr-1" /> {sub.ownerName}
                    </div>
                  </td>
                  <td className="px-4 py-4 whitespace-nowrap">
                    <div className="flex items-center space-x-2">
                      <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800">
                        {sub.plan}
                      </span>
                      <span className="text-xs text-gray-500">{sub.billingCycle}</span>
                    </div>
                    <div className="text-xs text-gray-500 mt-2">
                      Starts: {sub.startDate}
                    </div>
                    <div className="text-xs text-gray-500 mt-1">
                      Ends: {sub.expiryDate} ({sub.remainingDays} days)
                    </div>
                  </td>
                  <td className="px-4 py-4 whitespace-nowrap">
                    <div className="text-xs font-medium text-gray-900 font-mono">{sub.licenseId}</div>
                    <div className="text-xs text-gray-500 mt-1 flex items-center">
                      <Smartphone className="h-3 w-3 mr-1" /> {sub.registeredDevices} / {sub.deviceLimit} Devices
                    </div>
                    <div className="text-xs text-gray-500 mt-1 flex items-center">
                      <Clock className="h-3 w-3 mr-1" /> Last Sync: {sub.lastSync.split(' ')[0]}
                    </div>
                  </td>
                  <td className="px-4 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">{sub.lastPayment}</div>
                    <div className="text-xs text-gray-500 mt-1">Last: {sub.lastInvoice}</div>
                    <div className="text-xs text-gray-500 mt-1">
                      {sub.outstandingAmount !== '$0.00' ? (
                        <span className="text-red-500 font-medium">Due: {sub.outstandingAmount}</span>
                      ) : 'Paid in full'}
                    </div>
                  </td>
                  <td className="px-4 py-4 whitespace-nowrap">
                    <span className={`status-badge ${getStatusBadge(sub.status)}`}>
                      {sub.status}
                    </span>
                  </td>
                  <td className="px-4 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <ActionDropdown property={sub} onAction={handleRowAction} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Slide-over Drawer */}
      <>
        <div 
          className={`saas-drawer-overlay ${isDrawerOpen ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'}`} 
          onClick={handleCloseDrawer} 
        />
        <div className={`saas-drawer flex flex-col w-[550px] max-w-full ${isDrawerOpen ? 'translate-x-0' : 'translate-x-full'}`}>
          {selectedProp && (
            <>
              <div className="px-6 py-5 border-b border-gray-100 flex items-center justify-between bg-gray-50/50 shrink-0 z-10">
                <div>
                  <h2 className="text-lg font-semibold text-gray-900">{selectedProp.propertyName}</h2>
                  <p className="text-sm text-gray-500">{selectedProp.propertyId}</p>
                </div>
                <button onClick={handleCloseDrawer} className="p-2 text-gray-400 hover:text-gray-900 hover:bg-gray-100 rounded-full transition-colors">
                  <X className="h-5 w-5" />
                </button>
              </div>

              <div className="p-6 space-y-8 flex-1 overflow-y-auto">
                {/* 1. Property Overview */}
                <section>
                  <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-4 flex items-center">
                    <MapPin className="h-4 w-4 mr-2" /> Property Overview
                  </h3>
                  <div className="grid grid-cols-2 gap-y-4 gap-x-6 text-sm">
                    <div>
                      <span className="text-gray-500 block">Property Type</span>
                      <span className="font-medium text-gray-900">{selectedProp.propertyType}</span>
                    </div>
                    <div>
                      <span className="text-gray-500 block">Location</span>
                      <span className="font-medium text-gray-900">{selectedProp.city}, {selectedProp.state}</span>
                    </div>
                    <div>
                      <span className="text-gray-500 block">Owner</span>
                      <span className="font-medium text-gray-900">{selectedProp.ownerName}</span>
                    </div>
                    <div>
                      <span className="text-gray-500 block">WhatsApp</span>
                      <span className="font-medium text-gray-900">{selectedProp.ownerWhatsApp}</span>
                    </div>
                  </div>
                </section>

                <hr className="border-gray-100" />

                {/* 2. Subscription Details */}
                <section>
                  <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-4 flex items-center">
                    <Activity className="h-4 w-4 mr-2" /> Subscription Details
                  </h3>
                  <div className="bg-gray-50 rounded-xl p-4 border border-gray-100 space-y-4">
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-500">Current Plan</span>
                      <span className="text-sm font-medium text-gray-900 bg-white px-2 py-1 rounded border border-gray-200">{selectedProp.plan}</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-500">Billing Cycle</span>
                      <span className="text-sm font-medium text-gray-900">{selectedProp.billingCycle}</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-500">Status</span>
                      <span className={`status-badge ${getStatusBadge(selectedProp.status)}`}>{selectedProp.status}</span>
                    </div>
                    <div className="grid grid-cols-3 gap-4 pt-3 border-t border-gray-200 mt-2">
                      <div>
                        <span className="text-xs text-gray-500 block">Start Date</span>
                        <span className="text-sm font-medium text-gray-900">{selectedProp.startDate}</span>
                      </div>
                      <div>
                        <span className="text-xs text-gray-500 block">Expiry Date</span>
                        <span className="text-sm font-medium text-gray-900">{selectedProp.expiryDate}</span>
                      </div>
                      <div>
                        <span className="text-xs text-gray-500 block">Remaining</span>
                        <span className={`text-sm font-medium ${selectedProp.remainingDays < 30 ? 'text-red-600' : 'text-gray-900'}`}>{selectedProp.remainingDays} Days</span>
                      </div>
                    </div>
                  </div>
                </section>

                {/* 3. License Details */}
                <section>
                  <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-4 flex items-center">
                    <ShieldCheck className="h-4 w-4 mr-2" /> License Details
                  </h3>
                  <div className="space-y-3">
                    <div className="flex items-center text-sm">
                      <span className="text-gray-500 w-1/3">License ID</span>
                      <span className="font-mono text-gray-900 font-medium">{selectedProp.licenseId}</span>
                    </div>
                    <div className="flex items-center text-sm">
                      <span className="text-gray-500 w-1/3">License Status</span>
                      <span className="text-gray-900 font-medium">{selectedProp.licenseStatus}</span>
                    </div>
                    <div className="flex items-center text-sm">
                      <span className="text-gray-500 w-1/3">Last Generated</span>
                      <span className="text-gray-900 font-medium">{selectedProp.licenseIssueDate}</span>
                    </div>
                    <div className="flex items-center text-sm">
                      <span className="text-gray-500 w-1/3">Signature</span>
                      <span className="text-green-600 font-medium flex items-center"><CheckCircle2 className="h-4 w-4 mr-1"/> Valid</span>
                    </div>
                  </div>
                </section>

                <hr className="border-gray-100" />

                {/* 4. Registered Devices */}
                <section>
                  <div className="flex justify-between items-center mb-4">
                    <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider flex items-center">
                      <Smartphone className="h-4 w-4 mr-2" /> Registered Devices
                    </h3>
                    <span className="text-xs font-medium text-gray-500 bg-gray-100 px-2 py-1 rounded-full">
                      {selectedProp.registeredDevices} / {selectedProp.deviceLimit} Allowed
                    </span>
                  </div>
                  
                  <div className="border border-gray-200 rounded-lg overflow-hidden">
                    <table className="min-w-full divide-y divide-gray-200">
                      <thead className="bg-gray-50">
                        <tr>
                          <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Device</th>
                          <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Status</th>
                          <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Last Login</th>
                          <th className="px-4 py-2 text-right text-xs font-medium text-gray-500"></th>
                        </tr>
                      </thead>
                      <tbody className="bg-white divide-y divide-gray-200">
                        {selectedProp.devicesList.map((dev, idx) => (
                          <tr key={idx}>
                            <td className="px-4 py-2 whitespace-nowrap text-sm text-gray-900 font-medium">{dev.name}</td>
                            <td className="px-4 py-2 whitespace-nowrap">
                              <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${dev.status === 'Active' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'}`}>
                                {dev.status}
                              </span>
                            </td>
                            <td className="px-4 py-2 whitespace-nowrap text-sm text-gray-500">{dev.lastLogin}</td>
                            <td className="px-4 py-2 whitespace-nowrap text-right text-sm">
                              <button className="text-red-500 hover:text-red-700">Remove</button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                  <div className="mt-3 flex justify-end">
                     <button className="text-sm text-pine font-medium hover:text-pine-dark flex items-center">
                       <Key className="h-4 w-4 mr-1" /> Regenerate License
                     </button>
                  </div>
                </section>

                <hr className="border-gray-100" />

                {/* 5. Payment Summary */}
                <section>
                  <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-4 flex items-center">
                    <CreditCard className="h-4 w-4 mr-2" /> Payment Summary
                  </h3>
                  <div className="grid grid-cols-2 gap-4 text-sm bg-gray-50 p-4 rounded-xl border border-gray-100">
                    <div>
                      <span className="text-gray-500 block">Total Paid</span>
                      <span className="font-medium text-gray-900">{selectedProp.totalPaid}</span>
                    </div>
                    <div>
                      <span className="text-gray-500 block">Last Payment</span>
                      <span className="font-medium text-gray-900">{selectedProp.lastPayment}</span>
                    </div>
                    <div>
                      <span className="text-gray-500 block">Outstanding</span>
                      <span className={`font-medium ${selectedProp.outstandingAmount !== '$0.00' ? 'text-red-600' : 'text-green-600'}`}>
                        {selectedProp.outstandingAmount}
                      </span>
                    </div>
                    <div>
                      <button className="text-pine font-medium hover:underline text-sm mt-1">View Payment History</button>
                    </div>
                  </div>
                </section>

                {/* 6. Recent Activities */}
                <section>
                  <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-4 flex items-center">
                    <Clock className="h-4 w-4 mr-2" /> Recent Activities
                  </h3>
                  <div className="space-y-4">
                    {selectedProp.recentActivities.map((act, idx) => (
                      <div key={idx} className="flex space-x-3">
                        <div className="mt-1">
                          <div className="h-2 w-2 rounded-full bg-pine"></div>
                        </div>
                        <div>
                          <p className="text-sm text-gray-900 font-medium">{act.action}</p>
                          <p className="text-xs text-gray-500">{act.date} • by {act.by}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </section>
                
              </div>

              {/* Quick Actions Footer */}
              <div className="p-6 bg-white border-t border-gray-200 grid grid-cols-2 gap-3 shrink-0 shadow-[0_-4px_6px_-1px_rgba(0,0,0,0.05)]">
                <button className="saas-button-primary w-full col-span-2 flex items-center justify-center" onClick={() => handleRowAction('renew', selectedProp)}>
                  <RefreshCw className="h-4 w-4 mr-2" /> Renew Subscription
                </button>
                <button className="saas-button-secondary w-full" onClick={() => handleRowAction('upgrade', selectedProp)}>
                  Upgrade Plan
                </button>
                {selectedProp.status === 'Disabled' ? (
                  <button className="saas-button-secondary w-full !text-green-600 hover:!bg-green-50 hover:!border-green-200" onClick={() => handleRowAction('enable', selectedProp)}>
                    Enable Property
                  </button>
                ) : (
                  <button className="saas-button-secondary w-full !text-red-600 hover:!bg-red-50 hover:!border-red-200" onClick={() => handleRowAction('disable', selectedProp)}>
                    Disable Property
                  </button>
                )}
              </div>
            </>
          )}
        </div>
      </>
    </div>
  );
}
