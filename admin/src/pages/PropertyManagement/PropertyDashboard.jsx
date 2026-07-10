import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Building2,
  CheckCircle2,
  Clock,
  Ban,
  Upload,
  Download,
  Plus,
  Search,
  Filter,
  MoreVertical,
  X,
  MapPin,
  FileText,
  Smartphone,
  CreditCard,
  Building,
  Key
} from 'lucide-react';

const kpiStats = [
  { name: 'Total Properties', value: '1,248', icon: Building2, color: 'text-pine-DEFAULT', bg: 'bg-pine-50' },
  { name: 'Active', value: '842', icon: CheckCircle2, color: 'text-green-600', bg: 'bg-green-50' },
  { name: 'Pending Verification', value: '156', icon: Clock, color: 'text-yellow-600', bg: 'bg-yellow-50' },
  { name: 'Suspended', value: '12', icon: Ban, color: 'text-red-500', bg: 'bg-red-50' },
];

const mockProperties = [
  { id: '1', name: 'Grand Plaza Hotel', business: 'Grand Plaza Pvt Ltd', owner: 'John Doe', mobile: '+1 234 567 890', type: 'Hotel', city: 'New York', rooms: 120, plan: 'Pro', subscriptionStatus: 'Active', verificationStatus: 'Verified', onboarding: '100%', lastSync: '2 mins ago', lastUpdated: 'Today' },
  { id: '2', name: 'Sea View Resort', business: 'Oceanic Stays', owner: 'Jane Smith', mobile: '+1 987 654 321', type: 'Resort', city: 'Miami', rooms: 45, plan: 'Enterprise', subscriptionStatus: 'Active', verificationStatus: 'Pending', onboarding: '85%', lastSync: '1 hour ago', lastUpdated: 'Yesterday' },
  { id: '3', name: 'City Lights Hostel', business: 'Urban Backpacker', owner: 'Mike Johnson', mobile: '+1 555 123 456', type: 'Hostel', city: 'Chicago', rooms: 80, plan: 'Basic', subscriptionStatus: 'Expired', verificationStatus: 'Verified', onboarding: '100%', lastSync: '3 days ago', lastUpdated: 'Last week' },
  { id: '4', name: 'Mountain Inn', business: 'Alpine Retreats', owner: 'Sarah Wilson', mobile: '+1 444 789 012', type: 'Boutique', city: 'Denver', rooms: 15, plan: 'Pro', subscriptionStatus: 'Grace Period', verificationStatus: 'Rejected', onboarding: '60%', lastSync: '5 hours ago', lastUpdated: 'Today' },
];

export default function PropertyDashboard() {
  const navigate = useNavigate();
  const [selectedProp, setSelectedProp] = useState(null);

  return (
    <div className="space-y-6 animate-slide-up relative">
      <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center space-y-4 sm:space-y-0">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 tracking-tight">Property Management</h1>
          <p className="text-sm text-gray-500 mt-1">Manage onboarded properties and track verification progress.</p>
        </div>
        <div className="flex space-x-3">
          <button className="saas-button-secondary">
            <Download className="h-4 w-4 mr-2" />
            Export
          </button>
          <button className="saas-button-secondary">
            <Upload className="h-4 w-4 mr-2" />
            Import
          </button>
          <button onClick={() => navigate('/properties/add')} className="saas-button-primary">
            <Plus className="h-4 w-4 mr-2" />
            Add New Property
          </button>
        </div>
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

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1 max-w-md">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <Search className="h-4 w-4 text-gray-400" />
          </div>
          <input
            type="text"
            className="saas-input pl-9"
            placeholder="Search by property, owner, email, or mobile..."
          />
        </div>
        <div className="flex space-x-3 overflow-x-auto pb-1">
          <button className="saas-button-secondary whitespace-nowrap">
            <Filter className="h-4 w-4 mr-2 text-gray-500" /> Type
          </button>
          <button className="saas-button-secondary whitespace-nowrap">
            <Filter className="h-4 w-4 mr-2 text-gray-500" /> Status
          </button>
          <button className="saas-button-secondary whitespace-nowrap">
            <Filter className="h-4 w-4 mr-2 text-gray-500" /> Verification
          </button>
        </div>
      </div>

      {/* Data Table */}
      <div className="saas-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Property & Owner</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Location</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Sub Status</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Verification</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Onboarding</th>
                <th className="relative px-6 py-3"><span className="sr-only">Actions</span></th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {mockProperties.map((prop) => (
                <tr key={prop.id} className="hover:bg-gray-50/50 cursor-pointer transition-colors" onClick={() => setSelectedProp(prop)}>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{prop.name}</div>
                    <div className="text-xs text-gray-500">{prop.owner} • {prop.mobile}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">{prop.city}</div>
                    <div className="text-xs text-gray-500">{prop.type} • {prop.rooms} Rooms</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`status-badge ${
                      prop.subscriptionStatus === 'Active' ? 'status-active' :
                      prop.subscriptionStatus === 'Expired' ? 'status-error' : 'status-pending'
                    }`}>
                      {prop.subscriptionStatus}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`status-badge ${
                      prop.verificationStatus === 'Verified' ? 'status-active' :
                      prop.verificationStatus === 'Rejected' ? 'status-error' : 'status-pending'
                    }`}>
                      {prop.verificationStatus}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center space-x-2">
                      <div className="w-16 h-2 bg-gray-200 rounded-full overflow-hidden">
                        <div 
                          className={`h-full ${prop.onboarding === '100%' ? 'bg-green-500' : 'bg-pine-DEFAULT'}`} 
                          style={{ width: prop.onboarding }} 
                        />
                      </div>
                      <span className="text-xs text-gray-500 font-medium">{prop.onboarding}</span>
                    </div>
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

      {/* Detail Slide-over Drawer */}
      {selectedProp && (
        <>
          <div className="saas-drawer-overlay" onClick={() => setSelectedProp(null)} />
          <div className="saas-drawer flex flex-col w-[500px] max-w-full">
            <div className="px-6 py-5 border-b border-gray-100 flex items-center justify-between bg-white sticky top-0 z-10 shadow-sm">
              <div>
                <h2 className="text-xl font-semibold text-gray-900">{selectedProp.name}</h2>
                <p className="text-sm text-gray-500 mt-0.5">{selectedProp.type} • {selectedProp.city}</p>
              </div>
              <button onClick={() => setSelectedProp(null)} className="p-2 text-gray-400 hover:text-gray-900 hover:bg-gray-100 rounded-full transition-colors">
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="p-6 space-y-8 flex-1 overflow-y-auto">
              {/* Overview */}
              <section>
                <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-4">Overview</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <span className="block text-xs text-gray-500">Owner Name</span>
                    <span className="block text-sm font-medium text-gray-900 mt-0.5">{selectedProp.owner}</span>
                  </div>
                  <div>
                    <span className="block text-xs text-gray-500">Mobile</span>
                    <span className="block text-sm font-medium text-gray-900 mt-0.5">{selectedProp.mobile}</span>
                  </div>
                  <div>
                    <span className="block text-xs text-gray-500">Business Name</span>
                    <span className="block text-sm font-medium text-gray-900 mt-0.5">{selectedProp.business}</span>
                  </div>
                  <div>
                    <span className="block text-xs text-gray-500">Onboarding</span>
                    <span className="block text-sm font-medium text-pine mt-0.5">{selectedProp.onboarding} Complete</span>
                  </div>
                </div>
              </section>

              <hr className="border-gray-100" />

              {/* Status Modules */}
              <div className="grid grid-cols-2 gap-4">
                <div className="saas-card p-4 border border-gray-100 shadow-none">
                  <div className="flex items-center text-sm font-medium text-gray-900 mb-2">
                    <CheckCircle2 className="h-4 w-4 mr-2 text-green-500" /> Verification
                  </div>
                  <span className={`status-badge ${selectedProp.verificationStatus === 'Verified' ? 'status-active' : 'status-pending'}`}>
                    {selectedProp.verificationStatus}
                  </span>
                </div>
                <div className="saas-card p-4 border border-gray-100 shadow-none">
                  <div className="flex items-center text-sm font-medium text-gray-900 mb-2">
                    <CreditCard className="h-4 w-4 mr-2 text-pine" /> Subscription
                  </div>
                  <span className={`status-badge ${selectedProp.subscriptionStatus === 'Active' ? 'status-active' : 'status-error'}`}>
                    {selectedProp.subscriptionStatus} ({selectedProp.plan})
                  </span>
                </div>
              </div>

              {/* Business Info */}
              <section>
                <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-4 flex items-center">
                  <Building className="h-4 w-4 mr-2" /> Business Information
                </h3>
                <div className="bg-gray-50 rounded-xl p-4 border border-gray-100 space-y-3">
                  <div className="flex justify-between">
                    <span className="text-sm text-gray-500">GST Number</span>
                    <span className="text-sm font-mono text-gray-900">29ABCDE1234F1Z5</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-sm text-gray-500">PAN</span>
                    <span className="text-sm font-mono text-gray-900">ABCDE1234F</span>
                  </div>
                </div>
              </section>

              {/* Location */}
              <section>
                <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-4 flex items-center">
                  <MapPin className="h-4 w-4 mr-2" /> Location
                </h3>
                <div className="text-sm text-gray-900 leading-relaxed bg-gray-50 rounded-xl p-4 border border-gray-100">
                  123 Luxury Avenue, Block B<br/>
                  Near Central Park<br/>
                  {selectedProp.city}, NY 10001
                </div>
              </section>

              {/* Documents */}
              <section>
                <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-4 flex items-center">
                  <FileText className="h-4 w-4 mr-2" /> Documents
                </h3>
                <div className="space-y-2">
                  {['GST Certificate.pdf', 'PAN_Card.jpg', 'Trade_License.pdf'].map(doc => (
                    <div key={doc} className="flex items-center justify-between p-3 border border-gray-100 rounded-lg hover:border-gray-200 transition-colors">
                      <div className="flex items-center text-sm text-gray-600">
                        <FileText className="h-4 w-4 mr-2 text-gray-400" />
                        {doc}
                      </div>
                      <button className="text-pine text-xs font-medium hover:underline">View</button>
                    </div>
                  ))}
                </div>
              </section>
            </div>

            {/* Sticky Actions */}
            <div className="p-6 bg-white border-t border-gray-100 grid grid-cols-2 gap-3 sticky bottom-0">
              <button className="saas-button-primary col-span-2">
                Continue Onboarding
              </button>
              <button className="saas-button-secondary">
                Edit Property
              </button>
              <button className="saas-button-secondary !text-red-600 hover:!bg-red-50 hover:!border-red-200">
                Suspend
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
