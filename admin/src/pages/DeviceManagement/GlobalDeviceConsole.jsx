import { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { 
  Smartphone,
  CheckCircle2,
  Clock,
  Ban,
  AlertTriangle,
  RefreshCw,
  Search,
  Filter,
  MoreVertical,
  X,
  Lock,
  Unlock,
  Power,
  Edit3,
  UserCheck,
  ShieldAlert,
  Download,
  Plus,
  BatteryCharging,
  WifiOff,
  History,
  Key,
  Database,
  Loader2,
  AlertCircle
} from 'lucide-react';
import { deviceService } from '../../services/deviceService';

const fallbackKpiStats = [
  { name: 'Total Registered Devices', value: '0', icon: Smartphone, color: 'text-pine-DEFAULT', bg: 'bg-pine-50' },
  { name: 'Pending Approval', value: '0', icon: Clock, color: 'text-yellow-600', bg: 'bg-yellow-50' },
  { name: 'Active & Synced', value: '0', icon: CheckCircle2, color: 'text-green-600', bg: 'bg-green-50' },
  { name: 'Locked / Disabled', value: '0', icon: Lock, color: 'text-purple-600', bg: 'bg-purple-50' },
  { name: 'Offline (> 24h)', value: '0', icon: WifiOff, color: 'text-amber-600', bg: 'bg-amber-50' },
  { name: 'Failed Syncs (24h)', value: '0', icon: AlertTriangle, color: 'text-red-600', bg: 'bg-red-50' },
];

export default function GlobalDeviceConsole() {
  const [selectedDevice, setSelectedDevice] = useState(null);
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  // API State
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [devices, setDevices] = useState([]);
  const [kpis, setKpis] = useState([]);

  useEffect(() => {
    const loadConsoleData = async () => {
      setLoading(true);
      try {
        const [devicesRes, kpisRes] = await Promise.all([
          deviceService.getGlobalDevices(),
          deviceService.getGlobalKPIs()
        ]);
        setDevices(Array.isArray(devicesRes) ? devicesRes : (devicesRes.data || []));
        setKpis(kpisRes.length ? kpisRes : fallbackKpiStats);
        setError(null);
      } catch (err) {
        setError(err.message || 'Failed to load device console data');
        setKpis(fallbackKpiStats);
      } finally {
        setLoading(false);
      }
    };
    loadConsoleData();
  }, []);

  const handleOpenDrawer = (dev) => {
    setSelectedDevice(dev);
    setTimeout(() => setIsDrawerOpen(true), 10);
  };

  const handleCloseDrawer = () => {
    setIsDrawerOpen(false);
    setTimeout(() => setSelectedDevice(null), 300);
  };

  const handleAction = async (action, deviceId) => {
    try {
      if (action === 'approve') {
        await deviceService.approveDevice(deviceId);
      } else if (action === 'lock') {
        await deviceService.lockDevice(deviceId);
      } else if (action === 'unlock') {
        await deviceService.unlockDevice(deviceId);
      } else if (action === 'sync') {
        await deviceService.triggerSync(deviceId);
      }
      alert(`Successfully executed ${action} on device ${deviceId}`);
    } catch (e) {
      alert(`Failed to execute ${action}: ${e.message}`);
    }
  };

  const filteredDevices = devices.filter(dev => 
    (dev.name && dev.name.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (dev.model && dev.model.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (dev.property && dev.property.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (dev.uid && dev.uid.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  return (
    <div className="space-y-6 animate-slide-up relative">
      <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center space-y-4 sm:space-y-0">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 tracking-tight">Global Device Console</h1>
          <p className="text-sm text-gray-500 mt-1">Monitor, manage, and audit all mobile devices deployed across properties.</p>
        </div>
        <div className="flex space-x-3">
          <button className="saas-button-secondary">
            <Download className="h-4 w-4 mr-2" />
            Export CSV
          </button>
          <button className="saas-button-primary">
            <Plus className="h-4 w-4 mr-2" />
            Register Device
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        {kpis.map((stat, idx) => {
          const Icon = typeof stat.icon === 'string' ? Smartphone : (stat.icon || Smartphone);
          return (
            <div key={idx} className="saas-card p-4">
              <div className="flex justify-between items-start">
                <p className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider line-clamp-2">{stat.name}</p>
                <Icon className={`h-4 w-4 ${stat.color || 'text-gray-500'}`} />
              </div>
              <p className="mt-2 text-xl font-bold text-gray-900">{stat.value}</p>
            </div>
          );
        })}
      </div>

      {/* Main Table Area */}
      <div className="saas-card overflow-hidden relative min-h-[400px]">
        <div className="p-4 border-b border-gray-100 flex flex-col sm:flex-row gap-4 justify-between bg-gray-50/50">
          <div className="relative flex-1 max-w-md">
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <Search className="h-4 w-4 text-gray-400" />
            </div>
            <input
              type="text"
              className="saas-input pl-9 bg-white"
              placeholder="Search by device name, model, property, or UID..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <div className="flex gap-2">
            <button className="saas-button-secondary"><Filter className="h-4 w-4 mr-2"/> Filters</button>
            <button className="saas-button-secondary"><RefreshCw className="h-4 w-4 mr-2"/> Refresh</button>
          </div>
        </div>

        {loading && (
          <div className="absolute inset-0 flex flex-col items-center justify-center bg-white/80 z-10">
             <Loader2 className="h-8 w-8 text-pine animate-spin mb-2" />
             <p className="text-gray-500 text-sm">Loading devices...</p>
          </div>
        )}

        {error && !loading && (
          <div className="absolute inset-0 flex flex-col items-center justify-center bg-white/80 z-10">
             <AlertCircle className="h-8 w-8 text-red-500 mb-2" />
             <p className="text-gray-800 text-sm font-medium">Failed to load devices</p>
             <p className="text-gray-500 text-xs mt-1 max-w-sm text-center">{error}</p>
          </div>
        )}

        <div className="overflow-x-auto">
          {!loading && !error && filteredDevices.length === 0 ? (
            <div className="p-8 text-center text-sm text-gray-500">No devices found.</div>
          ) : (
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-white">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Device & Model</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Property</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Status & Battery</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Last Sync</th>
                  <th className="relative px-6 py-3"><span className="sr-only">Actions</span></th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-100">
                {filteredDevices.map((dev, idx) => (
                  <tr key={dev.id || idx} className="hover:bg-gray-50/80 transition cursor-pointer" onClick={() => handleOpenDrawer(dev)}>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className="h-10 w-10 flex-shrink-0 rounded-lg bg-gray-100 flex items-center justify-center">
                          <Smartphone className="h-5 w-5 text-gray-600" />
                        </div>
                        <div className="ml-4">
                          <div className="text-sm font-medium text-gray-900">{dev.name}</div>
                          <div className="text-xs text-gray-500">{dev.model} • <span className="font-mono text-[10px]">{dev.uid}</span></div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">{dev.property}</div>
                      <div className="text-xs text-gray-500 flex items-center mt-0.5">
                        <UserCheck className="h-3 w-3 mr-1"/> {dev.primaryUser || 'Unassigned'}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center space-x-2">
                        {dev.status === 'active' && <span className="inline-flex items-center px-2 py-0.5 rounded text-[11px] font-medium bg-green-100 text-green-800"><CheckCircle2 className="w-3 h-3 mr-1"/> Active</span>}
                        {dev.status === 'pending_approval' && <span className="inline-flex items-center px-2 py-0.5 rounded text-[11px] font-medium bg-yellow-100 text-yellow-800"><Clock className="w-3 h-3 mr-1"/> Pending</span>}
                        {dev.status === 'locked' && <span className="inline-flex items-center px-2 py-0.5 rounded text-[11px] font-medium bg-red-100 text-red-800"><Lock className="w-3 h-3 mr-1"/> Locked</span>}
                        
                        <span className="flex items-center text-xs text-gray-500 ml-2 border border-gray-200 rounded px-1.5 py-0.5">
                          <BatteryCharging className={`h-3 w-3 mr-1 ${dev.battery < 20 ? 'text-red-500' : 'text-green-500'}`} />
                          {dev.battery}%
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">{dev.lastSync}</div>
                      <div className="text-xs text-gray-500">{dev.appVersion}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <button className="text-gray-400 hover:text-gray-900 p-2 rounded-full hover:bg-gray-100 transition-colors" onClick={(e) => { e.stopPropagation(); handleOpenDrawer(dev); }}>
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
          Showing {filteredDevices.length} records
        </div>
      </div>

      {/* Slide-over Drawer */}
      {createPortal(
        <>
        <div className={`saas-drawer-overlay ${isDrawerOpen ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'}`} onClick={handleCloseDrawer} />
        <div className={`saas-drawer flex flex-col w-[450px] max-w-full ${isDrawerOpen ? 'translate-x-0' : 'translate-x-full'}`}>
          {selectedDevice && (
            <>
              <div className="px-6 py-5 border-b border-gray-100 flex items-start justify-between bg-gray-50/50 shrink-0">
                <div className="flex items-center">
                  <div className="h-12 w-12 rounded-xl bg-white border border-gray-200 shadow-sm flex items-center justify-center">
                    <Smartphone className="h-6 w-6 text-gray-600" />
                  </div>
                  <div className="ml-4">
                    <h2 className="text-lg font-bold text-gray-900">{selectedDevice.name}</h2>
                    <p className="text-sm text-gray-500 mt-1">{selectedDevice.model}</p>
                  </div>
                </div>
                <button onClick={handleCloseDrawer} className="p-2 text-gray-400 hover:text-gray-900 hover:bg-gray-100 rounded-full transition-colors">
                  <X className="h-5 w-5" />
                </button>
              </div>

              <div className="p-6 space-y-6 flex-1 overflow-y-auto">
                <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-4 space-y-3 text-sm">
                  <div className="flex justify-between items-center pb-3 border-b border-gray-50">
                    <span className="text-gray-500">Hardware UID</span>
                    <span className="font-mono text-gray-900 font-medium bg-gray-100 px-2 py-0.5 rounded">{selectedDevice.uid}</span>
                  </div>
                  <div className="flex justify-between items-center pb-3 border-b border-gray-50">
                    <span className="text-gray-500">Property Assigned</span>
                    <span className="font-medium text-gray-900">{selectedDevice.property}</span>
                  </div>
                  <div className="flex justify-between items-center pb-3 border-b border-gray-50">
                    <span className="text-gray-500">OS Version</span>
                    <span className="font-medium text-gray-900">{selectedDevice.osVersion}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-500">App Version</span>
                    <span className="font-medium text-gray-900">{selectedDevice.appVersion}</span>
                  </div>
                </div>

                <div>
                  <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3">Security & Status</h3>
                  <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-4 space-y-3 text-sm">
                    <div className="flex justify-between items-center">
                      <span className="text-gray-500 flex items-center"><ShieldAlert className="h-4 w-4 mr-2 text-gray-400"/> Approval Status</span>
                      <span className="font-medium text-gray-900 capitalize">{selectedDevice.approvalStatus}</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-gray-500 flex items-center"><Lock className="h-4 w-4 mr-2 text-gray-400"/> Remote Lock</span>
                      <span className="font-medium text-gray-900">{selectedDevice.status === 'locked' ? 'Locked' : 'Unlocked'}</span>
                    </div>
                  </div>
                </div>
              </div>
              
              <div className="p-6 bg-white border-t border-gray-200 flex flex-col space-y-2 shrink-0 shadow-[0_-4px_6px_-1px_rgba(0,0,0,0.05)]">
                {selectedDevice.status === 'pending_approval' && (
                  <button onClick={() => handleAction('approve', selectedDevice.id)} className="saas-button-primary w-full justify-center">Approve Device</button>
                )}
                {selectedDevice.status === 'active' && (
                  <button onClick={() => handleAction('lock', selectedDevice.id)} className="saas-button-secondary w-full justify-center text-red-600 hover:bg-red-50 border-red-200">
                    <Lock className="h-4 w-4 mr-2"/> Lock Device Remotely
                  </button>
                )}
                {selectedDevice.status === 'locked' && (
                  <button onClick={() => handleAction('unlock', selectedDevice.id)} className="saas-button-secondary w-full justify-center">
                    <Unlock className="h-4 w-4 mr-2"/> Unlock Device
                  </button>
                )}
              </div>
            </>
          )}
        </div>
      </>,
        document.body
      )}
    </div>
  );
}
