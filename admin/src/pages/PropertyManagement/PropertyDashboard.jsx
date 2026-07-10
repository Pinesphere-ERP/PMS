import { useState, useEffect } from 'react';
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
  Key,
  RefreshCw,
  Loader2,
  AlertCircle
} from 'lucide-react';
import { propertyService } from '../../services/propertyService';

const fallbackKpiStats = [
  { name: 'Total Properties', value: '0', icon: Building2, color: 'text-pine-DEFAULT', bg: 'bg-pine-50' },
  { name: 'Active', value: '0', icon: CheckCircle2, color: 'text-green-600', bg: 'bg-green-50' },
  { name: 'Pending Verification', value: '0', icon: Clock, color: 'text-yellow-600', bg: 'bg-yellow-50' },
  { name: 'Suspended', value: '0', icon: Ban, color: 'text-red-500', bg: 'bg-red-50' },
];

export default function PropertyDashboard() {
  const navigate = useNavigate();
  const [selectedProp, setSelectedProp] = useState(null);
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  // API State
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [properties, setProperties] = useState([]);
  const [kpis, setKpis] = useState([]);

  useEffect(() => {
    const loadDashboardData = async () => {
      setLoading(true);
      try {
        const [propsRes, kpisRes] = await Promise.all([
          propertyService.getAllProperties(),
          propertyService.getDashboardKPIs()
        ]);
        setProperties(Array.isArray(propsRes) ? propsRes : (propsRes.data || []));
        setKpis(kpisRes.length ? kpisRes : fallbackKpiStats);
        setError(null);
      } catch (err) {
        setError(err.message || 'Failed to load dashboard data');
        setKpis(fallbackKpiStats);
      } finally {
        setLoading(false);
      }
    };
    loadDashboardData();
  }, []);

  const handleOpenDrawer = (prop) => {
    setSelectedProp(prop);
    // slight delay to ensure it renders before transitioning
    setTimeout(() => setIsDrawerOpen(true), 10);
  };

  const handleCloseDrawer = () => {
    setIsDrawerOpen(false);
    setTimeout(() => setSelectedProp(null), 300); // 300ms matches transition duration
  };

  const filteredProperties = properties.filter(prop => 
    (prop.name && prop.name.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (prop.owner && prop.owner.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (prop.mobile && prop.mobile.includes(searchTerm)) ||
    (prop.city && prop.city.toLowerCase().includes(searchTerm.toLowerCase()))
  );

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
        {kpis.map((stat, idx) => {
          // If icon is a string from API, we'd need to map it, but we'll assume it's pre-mapped or we use the component directly if it's the fallback
          const Icon = typeof stat.icon === 'string' ? Building2 : (stat.icon || Building2);
          return (
            <div key={idx} className="saas-card p-5 flex items-start space-x-4">
              <div className={`p-2.5 rounded-lg ${stat.bg || 'bg-gray-50'}`}>
                <Icon className={`h-5 w-5 ${stat.color || 'text-gray-500'}`} />
              </div>
              <div>
                <p className="text-xs font-medium text-gray-500 uppercase tracking-wider">{stat.name}</p>
                <h3 className="text-2xl font-bold text-gray-900 mt-1">{stat.value}</h3>
              </div>
            </div>
          );
        })}
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
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        <div className="flex gap-2">
          <button className="saas-button-secondary"><Filter className="h-4 w-4 mr-2"/> Filter</button>
        </div>
      </div>

      {/* Properties Table */}
      <div className="saas-card overflow-hidden relative min-h-[400px]">
        {loading && (
          <div className="absolute inset-0 flex flex-col items-center justify-center bg-white/80 z-10">
             <Loader2 className="h-8 w-8 text-pine animate-spin mb-2" />
             <p className="text-gray-500 text-sm">Loading properties...</p>
          </div>
        )}

        {error && !loading && (
          <div className="absolute inset-0 flex flex-col items-center justify-center bg-white/80 z-10">
             <AlertCircle className="h-8 w-8 text-red-500 mb-2" />
             <p className="text-gray-800 text-sm font-medium">Failed to load properties</p>
             <p className="text-gray-500 text-xs mt-1 max-w-sm text-center">{error}</p>
          </div>
        )}

        <div className="overflow-x-auto">
          {!loading && !error && filteredProperties.length === 0 ? (
            <div className="p-8 text-center text-sm text-gray-500">No properties found.</div>
          ) : (
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Property Details</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Owner Info</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Location</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                  <th className="relative px-6 py-3"><span className="sr-only">Actions</span></th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredProperties.map((prop) => (
                  <tr key={prop.id || Math.random()} className="hover:bg-gray-50 transition cursor-pointer" onClick={() => handleOpenDrawer(prop)}>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className="h-10 w-10 flex-shrink-0 rounded-lg bg-pine/10 flex items-center justify-center">
                          <Building className="h-5 w-5 text-pine" />
                        </div>
                        <div className="ml-4">
                          <div className="text-sm font-medium text-gray-900">{prop.name || prop.property_name}</div>
                          <div className="text-sm text-gray-500">{prop.business || 'Unknown Business'} • {prop.type || prop.property_type}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">{prop.owner}</div>
                      <div className="text-sm text-gray-500">{prop.mobile}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">{prop.city}</div>
                      <div className="text-xs text-gray-500 mt-1">{prop.rooms || 0} Rooms</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex flex-col space-y-1">
                        <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${prop.verificationStatus === 'Verified' ? 'bg-green-100 text-green-800' : prop.verificationStatus === 'Pending' ? 'bg-yellow-100 text-yellow-800' : 'bg-red-100 text-red-800'}`}>
                          {prop.verificationStatus || 'Unknown'} Verification
                        </span>
                        <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${prop.subscriptionStatus === 'Active' ? 'bg-blue-100 text-blue-800' : 'bg-gray-100 text-gray-800'}`}>
                          {prop.subscriptionStatus || prop.status || 'Unknown'} Sub
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <button className="text-gray-400 hover:text-gray-900 p-2 rounded-full hover:bg-gray-100 transition-colors" onClick={(e) => { e.stopPropagation(); handleOpenDrawer(prop); }}>
                        <MoreVertical className="h-5 w-5" />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
        
        {/* Pagination placeholder */}
        <div className="bg-gray-50 px-6 py-3 border-t border-gray-200 text-sm text-gray-500">
          Showing {filteredProperties.length} records
        </div>
      </div>

      {/* Slide-over Drawer for Property Details */}
      <>
        <div 
          className={`saas-drawer-overlay ${isDrawerOpen ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'}`} 
          onClick={handleCloseDrawer} 
        />
        <div className={`saas-drawer ${isDrawerOpen ? 'translate-x-0' : 'translate-x-full'}`}>
          {selectedProp && (
            <>
              <div className="px-6 py-6 border-b border-gray-100 flex items-start justify-between bg-gray-50/50">
                <div className="flex items-center">
                  <div className="h-12 w-12 rounded-xl bg-white border border-gray-200 shadow-sm flex items-center justify-center">
                    <Building className="h-6 w-6 text-pine" />
                  </div>
                  <div className="ml-4">
                    <h2 className="text-xl font-bold text-gray-900">{selectedProp.name || selectedProp.property_name}</h2>
                    <p className="text-sm text-gray-500 mt-1">{selectedProp.business || 'Unknown Business'} • ID: {selectedProp.id}</p>
                  </div>
                </div>
                <button onClick={handleCloseDrawer} className="p-2 text-gray-400 hover:text-gray-900 hover:bg-gray-100 rounded-full transition-colors">
                  <X className="h-5 w-5" />
                </button>
              </div>

              <div className="p-6 space-y-8 overflow-y-auto" style={{ maxHeight: 'calc(100vh - 160px)' }}>
                {/* Status Banners */}
                <div className="flex gap-4">
                  <div className={`flex-1 p-3 rounded-lg border ${selectedProp.verificationStatus === 'Verified' ? 'bg-green-50 border-green-100' : 'bg-yellow-50 border-yellow-100'}`}>
                    <p className="text-xs font-medium text-gray-500 uppercase">Verification</p>
                    <p className={`text-sm font-bold mt-1 ${selectedProp.verificationStatus === 'Verified' ? 'text-green-700' : 'text-yellow-700'}`}>{selectedProp.verificationStatus || 'Unknown'}</p>
                  </div>
                  <div className="flex-1 p-3 rounded-lg border bg-blue-50 border-blue-100">
                    <p className="text-xs font-medium text-gray-500 uppercase">Subscription</p>
                    <p className="text-sm font-bold mt-1 text-blue-700">{selectedProp.subscriptionStatus || selectedProp.status || 'Unknown'} ({selectedProp.plan || 'Unknown'})</p>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-6">
                  <div>
                    <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3">Owner Details</h3>
                    <div className="space-y-3">
                      <div className="flex items-center text-sm">
                        <FileText className="h-4 w-4 text-gray-400 mr-2" />
                        <span className="text-gray-900 font-medium">{selectedProp.owner}</span>
                      </div>
                      <div className="flex items-center text-sm">
                        <Smartphone className="h-4 w-4 text-gray-400 mr-2" />
                        <span className="text-gray-600">{selectedProp.mobile}</span>
                      </div>
                    </div>
                  </div>
                  
                  <div>
                    <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3">Property Info</h3>
                    <div className="space-y-3">
                      <div className="flex items-center text-sm">
                        <MapPin className="h-4 w-4 text-gray-400 mr-2" />
                        <span className="text-gray-600">{selectedProp.city}</span>
                      </div>
                      <div className="flex items-center text-sm">
                        <Key className="h-4 w-4 text-gray-400 mr-2" />
                        <span className="text-gray-600">{selectedProp.rooms || 0} Rooms • {selectedProp.type || selectedProp.property_type}</span>
                      </div>
                    </div>
                  </div>
                </div>

                <div>
                  <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3 flex items-center justify-between">
                    <span>System Status</span>
                    <span className="text-xs text-gray-500 font-normal">Last Updated: {selectedProp.lastUpdated || 'Unknown'}</span>
                  </h3>
                  <div className="bg-white border border-gray-100 rounded-xl p-4 shadow-sm space-y-4 text-sm">
                    <div className="flex justify-between items-center">
                      <span className="text-gray-500">Onboarding Progress</span>
                      <div className="flex items-center w-32">
                        <div className="w-full bg-gray-200 rounded-full h-2 mr-2">
                          <div className="bg-pine h-2 rounded-full" style={{ width: selectedProp.onboarding || '0%' }}></div>
                        </div>
                        <span className="text-xs font-medium text-gray-700">{selectedProp.onboarding || '0%'}</span>
                      </div>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-gray-500 flex items-center"><RefreshCw className="h-4 w-4 mr-2 text-gray-400"/> Last Device Sync</span>
                      <span className="font-medium text-gray-900">{selectedProp.lastSync || 'Unknown'}</span>
                    </div>
                  </div>
                </div>

                <div className="pt-4 flex gap-3">
                  <button className="saas-button-secondary flex-1 justify-center">View Documents</button>
                  <button className="saas-button-primary flex-1 justify-center" onClick={() => navigate(`/properties/${selectedProp.id}`)}>Full Details</button>
                </div>
              </div>
            </>
          )}
        </div>
      </>
    </div>
  );
}
