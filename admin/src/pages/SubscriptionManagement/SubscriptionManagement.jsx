import { useState, useRef, useEffect } from 'react';
import { 
  Search, Filter, MoreVertical, X, CheckCircle2, Ban, ShieldCheck, Calendar,
  CreditCard, ChevronRight, Smartphone, RefreshCw, Plus, Minus, Power, Key,
  Activity, ArrowUpCircle, ArrowDownCircle, AlertCircle, Trash2, FileText,
  MapPin, Clock, User, Phone, Loader2
} from 'lucide-react';
import { subscriptionService } from '../../services/subscriptionService';

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
  
  // API State
  const [subscriptions, setSubscriptions] = useState([]);
  const [kpis, setKpis] = useState({
    totalSubscriptions: 0,
    activePlans: 0,
    expiredPlans: 0,
    disabledSubscriptions: 0,
    upgradesThisMonth: 0,
    downgradesThisMonth: 0
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const loadData = async () => {
      setLoading(true);
      setError(null);
      try {
        const [subsData, kpisData] = await Promise.all([
          subscriptionService.getSubscriptions(),
          subscriptionService.getKPIs()
        ]);
        // Handle array response or object containing array
        setSubscriptions(Array.isArray(subsData) ? subsData : (subsData.data || []));
        setKpis(kpisData || {});
      } catch (err) {
        setError(err.message || 'Failed to load subscription data');
        console.error('Error fetching subscriptions:', err);
      } finally {
        setLoading(false);
      }
    };
    
    loadData();
  }, []);

  const handleOpenDrawer = (prop) => {
    setSelectedProp(prop);
    setTimeout(() => setIsDrawerOpen(true), 10);
  };

  const handleCloseDrawer = () => {
    setIsDrawerOpen(false);
    setTimeout(() => setSelectedProp(null), 300);
  };

  const handleRowAction = async (action, property) => {
    if (action === 'view') {
      handleOpenDrawer(property);
    } else if (action === 'enable' || action === 'disable') {
      try {
        await subscriptionService.toggleSubscriptionStatus(property.id || property.propertyId, action);
        // Refresh data or update local state
      } catch (err) {
        alert(`Failed to ${action} property: ${err.message}`);
      }
    } else {
      console.log(`Action: ${action} on property: ${property.propertyName}`);
    }
  };

  const filteredSubscriptions = subscriptions.filter(sub => {
    if (!searchQuery) return true;
    const lowerQuery = searchQuery.toLowerCase();
    return sub.propertyName?.toLowerCase().includes(lowerQuery) ||
           sub.ownerName?.toLowerCase().includes(lowerQuery) ||
           sub.licenseId?.toLowerCase().includes(lowerQuery);
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
          <p className="mt-2 text-2xl font-semibold text-gray-900">{kpis.totalSubscriptions}</p>
        </div>
        <div className="saas-card p-4">
          <p className="text-sm font-medium text-gray-500 truncate">Active Plans</p>
          <p className="mt-2 text-2xl font-semibold text-green-600">{kpis.activePlans}</p>
        </div>
        <div className="saas-card p-4">
          <p className="text-sm font-medium text-gray-500 truncate">Expired Plans</p>
          <p className="mt-2 text-2xl font-semibold text-red-600">{kpis.expiredPlans}</p>
        </div>
        <div className="saas-card p-4">
          <p className="text-sm font-medium text-gray-500 truncate">Disabled</p>
          <p className="mt-2 text-2xl font-semibold text-gray-900">{kpis.disabledSubscriptions}</p>
        </div>
        <div className="saas-card p-4">
          <p className="text-sm font-medium text-gray-500 truncate">Upgrades This Month</p>
          <p className="mt-2 text-2xl font-semibold text-blue-600">{kpis.upgradesThisMonth}</p>
        </div>
        <div className="saas-card p-4">
          <p className="text-sm font-medium text-gray-500 truncate">Downgrades</p>
          <p className="mt-2 text-2xl font-semibold text-orange-600">{kpis.downgradesThisMonth}</p>
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
        <div className="overflow-x-auto min-h-[300px] relative">
          {loading ? (
            <div className="absolute inset-0 flex flex-col items-center justify-center bg-white/80 z-10">
              <Loader2 className="h-8 w-8 text-pine animate-spin mb-2" />
              <p className="text-gray-500 text-sm">Loading subscriptions...</p>
            </div>
          ) : error ? (
            <div className="absolute inset-0 flex flex-col items-center justify-center bg-white/80 z-10">
              <AlertCircle className="h-8 w-8 text-red-500 mb-2" />
              <p className="text-gray-800 text-sm font-medium">Failed to load data</p>
              <p className="text-gray-500 text-xs mt-1 max-w-sm text-center">{error}</p>
            </div>
          ) : filteredSubscriptions.length === 0 ? (
            <div className="absolute inset-0 flex flex-col items-center justify-center bg-white/80 z-10">
              <p className="text-gray-500 text-sm">No subscriptions found</p>
            </div>
          ) : null}
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
                <tr key={sub.id || sub.propertyId} className="hover:bg-gray-50/50 cursor-pointer transition-colors" onClick={() => handleOpenDrawer(sub)}>
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
                      <Clock className="h-3 w-3 mr-1" /> Last Sync: {sub.lastSync?.split(' ')[0]}
                    </div>
                  </td>
                  <td className="px-4 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">{sub.lastPayment}</div>
                    <div className="text-xs text-gray-500 mt-1">Last: {sub.lastInvoice}</div>
                    <div className="text-xs text-gray-500 mt-1">
                      {sub.outstandingAmount !== '$0.00' && sub.outstandingAmount !== '0' ? (
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
                        {selectedProp.devicesList?.map((dev, idx) => (
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
                    {selectedProp.recentActivities?.map((act, idx) => (
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
