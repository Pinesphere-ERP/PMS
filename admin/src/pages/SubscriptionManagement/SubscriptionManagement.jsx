import { useState } from 'react';
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
  ChevronRight
} from 'lucide-react';

const mockSubscriptions = [
  { id: '1', property: 'Grand Plaza Hotel', owner: 'John Doe', plan: 'Pro', start: '2025-01-01', expiry: '2026-01-01', days: 365, status: 'Active', devices: 15, lastPayment: '$499.00' },
  { id: '2', property: 'Sea View Resort', owner: 'Jane Smith', plan: 'Enterprise', start: '2025-03-15', expiry: '2025-09-15', days: 45, status: 'Active', devices: 42, lastPayment: '$999.00' },
  { id: '3', property: 'City Lights Hostel', owner: 'Mike Johnson', plan: 'Basic', start: '2024-05-10', expiry: '2025-05-10', days: 0, status: 'Expired', devices: 5, lastPayment: '$199.00' },
  { id: '4', property: 'Mountain Inn', owner: 'Sarah Wilson', plan: 'Pro', start: '2025-02-20', expiry: '2026-02-20', days: 2, status: 'Grace Period', devices: 12, lastPayment: '$499.00' },
];

export default function SubscriptionManagement() {
  const [selectedProp, setSelectedProp] = useState(null);
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);

  const handleOpenDrawer = (prop) => {
    setSelectedProp(prop);
    setTimeout(() => setIsDrawerOpen(true), 10);
  };

  const handleCloseDrawer = () => {
    setIsDrawerOpen(false);
    setTimeout(() => setSelectedProp(null), 300);
  };

  return (
    <div className="space-y-6 animate-slide-up relative">
      <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center space-y-4 sm:space-y-0">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 tracking-tight">Manage Subscriptions</h1>
          <p className="text-sm text-gray-500 mt-1">View and manage property subscriptions, plans, and licenses.</p>
        </div>
        <button className="saas-button-primary hidden">
          New Subscription
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1 max-w-md">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <Search className="h-4 w-4 text-gray-400" />
          </div>
          <input
            type="text"
            className="saas-input pl-9"
            placeholder="Search property or owner..."
          />
        </div>
        <div className="flex space-x-3">
          <button className="saas-button-secondary">
            <Filter className="h-4 w-4 mr-2 text-gray-500" />
            Plan
          </button>
          <button className="saas-button-secondary">
            <Filter className="h-4 w-4 mr-2 text-gray-500" />
            Status
          </button>
        </div>
      </div>

      {/* Data Table */}
      <div className="saas-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th scope="col" className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Property</th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Plan</th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Expiry</th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Devices</th>
                <th scope="col" className="relative px-6 py-3"><span className="sr-only">Actions</span></th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {mockSubscriptions.map((sub) => (
                <tr key={sub.id} className="hover:bg-gray-50/50 cursor-pointer transition-colors" onClick={() => handleOpenDrawer(sub)}>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{sub.property}</div>
                    <div className="text-sm text-gray-500">{sub.owner}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-md text-xs font-medium bg-gray-100 text-gray-800 border border-gray-200">
                      {sub.plan}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`status-badge ${
                      sub.status === 'Active' ? 'status-active' :
                      sub.status === 'Expired' ? 'status-error' : 'status-pending'
                    }`}>
                      {sub.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">{sub.expiry}</div>
                    <div className="text-xs text-gray-500">{sub.days} days left</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {sub.devices}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <button className="text-gray-400 hover:text-gray-900 p-1 rounded-full hover:bg-gray-100 transition-colors">
                      <MoreVertical className="h-5 w-5" />
                    </button>
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
        <div className={`saas-drawer flex flex-col w-[500px] max-w-full ${isDrawerOpen ? 'translate-x-0' : 'translate-x-full'}`}>
          {selectedProp && (
            <>
              <div className="px-6 py-5 border-b border-gray-100 flex items-center justify-between bg-gray-50/50 shrink-0 z-10">
                <div>
                  <h2 className="text-lg font-semibold text-gray-900">{selectedProp.property}</h2>
                  <p className="text-sm text-gray-500">Managed by {selectedProp.owner}</p>
                </div>
                <button onClick={handleCloseDrawer} className="p-2 text-gray-400 hover:text-gray-900 hover:bg-gray-100 rounded-full transition-colors">
                  <X className="h-5 w-5" />
                </button>
              </div>

              <div className="p-6 space-y-8 flex-1 overflow-y-auto">
                {/* Subscription Info */}
                <section>
                  <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-4">Subscription Details</h3>
                  <div className="bg-gray-50 rounded-xl p-4 border border-gray-100 space-y-4">
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-500">Current Plan</span>
                      <span className="text-sm font-medium text-gray-900 bg-white px-2 py-1 rounded border border-gray-200">{selectedProp.plan}</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-500">Status</span>
                      <span className={`status-badge ${selectedProp.status === 'Active' ? 'status-active' : selectedProp.status === 'Expired' ? 'status-error' : 'status-pending'}`}>{selectedProp.status}</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-500">Expiry Date</span>
                      <span className="text-sm font-medium text-gray-900">{selectedProp.expiry}</span>
                    </div>
                  </div>
                </section>

                {/* License Info */}
                <section>
                  <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-4">License Information</h3>
                  <div className="space-y-3">
                    <div className="flex items-center text-sm">
                      <ShieldCheck className="h-4 w-4 text-green-500 mr-2" />
                      <span className="text-gray-600 flex-1">Signature Status</span>
                      <span className="font-medium text-gray-900">Valid</span>
                    </div>
                    <div className="flex items-center text-sm">
                      <Smartphone className="h-4 w-4 text-pine mr-2" />
                      <span className="text-gray-600 flex-1">Device Count</span>
                      <span className="font-medium text-gray-900">{selectedProp.devices} / 50</span>
                    </div>
                  </div>
                </section>

                {/* Payment Summary */}
                <section>
                  <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-4">Payment Summary</h3>
                  <div className="space-y-3">
                    <div className="flex items-center text-sm">
                      <CreditCard className="h-4 w-4 text-gray-400 mr-2" />
                      <span className="text-gray-600 flex-1">Last Payment</span>
                      <span className="font-medium text-gray-900">{selectedProp.lastPayment}</span>
                    </div>
                    <div className="flex items-center text-sm">
                      <Calendar className="h-4 w-4 text-gray-400 mr-2" />
                      <span className="text-gray-600 flex-1">Next Renewal</span>
                      <span className="font-medium text-gray-900">{selectedProp.expiry}</span>
                    </div>
                  </div>
                </section>
              </div>

              {/* Quick Actions Footer */}
              <div className="p-6 bg-gray-50 border-t border-gray-100 grid grid-cols-2 gap-3 shrink-0">
                <button className="saas-button-primary w-full col-span-2">
                  Renew Subscription
                </button>
                <button className="saas-button-secondary w-full">
                  Upgrade Plan
                </button>
                <button className="saas-button-secondary w-full !text-red-600 hover:!bg-red-50 hover:!border-red-200">
                  Disable Property
                </button>
              </div>
            </>
          )}
        </div>
      </>
    </div>
  );
}
