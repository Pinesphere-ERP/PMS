import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Smartphone,
  CheckCircle2,
  Clock,
  Ban,
  AlertTriangle,
  Lock,
  Unlock,
  Power,
  Edit3,
  UserCheck,
  ShieldAlert,
  Plus,
  BatteryCharging,
  WifiOff,
  ArrowUpRight,
  BellRing,
  Trash2,
  Loader2,
  AlertCircle
} from 'lucide-react';
import { deviceService } from '../../services/deviceService';

export default function MyDevicesPanel() {
  const [searchTerm, setSearchTerm] = useState('');
  
  // API State
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [devices, setDevices] = useState([]);

  useEffect(() => {
    const fetchMyDevices = async () => {
      setLoading(true);
      try {
        const data = await deviceService.getMyDevices();
        setDevices(Array.isArray(data) ? data : (data.data || []));
        setError(null);
      } catch (err) {
        setError(err.message || 'Failed to fetch my devices');
      } finally {
        setLoading(false);
      }
    };
    fetchMyDevices();
  }, []);

  const filteredDevices = devices.filter(dev => 
    (dev.name && dev.name.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (dev.model && dev.model.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (dev.primaryUser && dev.primaryUser.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (dev.uid && dev.uid.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  return (
    <div className="space-y-6 animate-slide-up relative min-h-[400px]">
      <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center space-y-4 sm:space-y-0">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 tracking-tight">My Devices</h1>
          <p className="text-sm text-gray-500 mt-1">Manage the mobile devices assigned to your properties.</p>
        </div>
        <div className="flex space-x-3">
          <button className="saas-button-primary">
            <Plus className="h-4 w-4 mr-2" />
            Add New Device
          </button>
        </div>
      </div>

      <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-100 flex items-center justify-between">
        <div className="flex items-center space-x-4">
          <div className="bg-pine/10 p-3 rounded-lg">
            <BellRing className="h-5 w-5 text-pine" />
          </div>
          <div>
            <h3 className="text-sm font-semibold text-gray-900">Device Licenses</h3>
            <p className="text-xs text-gray-500 mt-0.5">You are using 3 of 5 allowed devices on your current plan.</p>
          </div>
        </div>
        <button className="text-sm text-pine font-medium hover:text-pine-dark flex items-center">
          Upgrade Plan <ArrowUpRight className="h-4 w-4 ml-1" />
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 relative min-h-[200px]">
        {loading && (
          <div className="absolute inset-0 flex flex-col items-center justify-center bg-gray-50/80 z-10 rounded-xl">
             <Loader2 className="h-8 w-8 text-pine animate-spin mb-2" />
             <p className="text-gray-500 text-sm">Loading your devices...</p>
          </div>
        )}

        {error && !loading && (
          <div className="absolute inset-0 flex flex-col items-center justify-center bg-gray-50/80 z-10 rounded-xl">
             <AlertCircle className="h-8 w-8 text-red-500 mb-2" />
             <p className="text-gray-800 text-sm font-medium">Failed to load devices</p>
             <p className="text-gray-500 text-xs mt-1 max-w-sm text-center">{error}</p>
          </div>
        )}

        {!loading && !error && filteredDevices.length === 0 && (
          <div className="col-span-full p-8 text-center bg-white rounded-xl shadow-sm border border-gray-100">
            <Smartphone className="h-12 w-12 text-gray-300 mx-auto mb-3" />
            <p className="text-gray-500 text-sm">You haven't registered any devices yet.</p>
            <button className="mt-4 text-sm text-pine font-medium hover:text-pine-dark">Register a Device</button>
          </div>
        )}

        {filteredDevices.map((dev, idx) => (
          <div key={dev.id || idx} className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden hover:shadow-md transition-shadow">
            <div className="p-5 border-b border-gray-100 bg-gray-50/30">
              <div className="flex justify-between items-start">
                <div className="flex items-center">
                  <div className={`h-10 w-10 rounded-lg flex items-center justify-center ${
                    dev.status === 'active' ? 'bg-green-50 text-green-600' :
                    dev.status === 'pending_approval' ? 'bg-yellow-50 text-yellow-600' :
                    'bg-gray-100 text-gray-500'
                  }`}>
                    <Smartphone className="h-5 w-5" />
                  </div>
                  <div className="ml-3">
                    <h3 className="text-sm font-bold text-gray-900">{dev.name}</h3>
                    <p className="text-xs text-gray-500 mt-0.5">{dev.model}</p>
                  </div>
                </div>
                <div className="flex space-x-1">
                  <button className="p-1.5 text-gray-400 hover:text-pine hover:bg-pine/10 rounded-md transition-colors"><Edit3 className="h-4 w-4" /></button>
                </div>
              </div>
            </div>

            <div className="p-5 space-y-4">
              <div className="flex justify-between items-center text-sm">
                <span className="text-gray-500 flex items-center"><UserCheck className="h-4 w-4 mr-2 text-gray-400"/> Primary User</span>
                <span className="font-medium text-gray-900">{dev.primaryUser || 'Unassigned'}</span>
              </div>
              <div className="flex justify-between items-center text-sm">
                <span className="text-gray-500 flex items-center"><ShieldAlert className="h-4 w-4 mr-2 text-gray-400"/> Status</span>
                <span className="font-medium">
                  {dev.status === 'active' && <span className="text-green-600 flex items-center"><CheckCircle2 className="w-4 h-4 mr-1"/> Active</span>}
                  {dev.status === 'pending_approval' && <span className="text-yellow-600 flex items-center"><Clock className="w-4 h-4 mr-1"/> Pending Appr.</span>}
                </span>
              </div>
              <div className="flex justify-between items-center text-sm">
                <span className="text-gray-500 flex items-center"><BatteryCharging className="h-4 w-4 mr-2 text-gray-400"/> Battery</span>
                <span className={`font-medium ${dev.battery < 20 ? 'text-red-500' : 'text-gray-900'}`}>{dev.battery}%</span>
              </div>
              <div className="flex justify-between items-center text-sm border-t border-gray-50 pt-3">
                <span className="text-gray-500 flex items-center">Last Sync</span>
                <span className={`font-medium text-xs ${dev.lastSync?.includes('ALERT') ? 'text-red-600 font-bold' : 'text-gray-900'}`}>{dev.lastSync}</span>
              </div>
            </div>

            <div className="px-5 py-3 bg-gray-50 flex gap-2 justify-between border-t border-gray-100">
              <button className="text-xs text-gray-600 font-medium hover:text-gray-900 flex items-center">
                View Details
              </button>
              <button className="text-xs text-red-600 font-medium hover:text-red-700 flex items-center">
                <Trash2 className="h-3 w-3 mr-1" /> Unregister
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
