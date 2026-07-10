import { useState } from 'react';
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
  Database
} from 'lucide-react';

const kpiStats = [
  { name: 'Total Registered Devices', value: '1,426', icon: Smartphone, color: 'text-pine-DEFAULT', bg: 'bg-pine-50' },
  { name: 'Pending Approval', value: '18', icon: Clock, color: 'text-yellow-600', bg: 'bg-yellow-50' },
  { name: 'Active & Synced', value: '1,310', icon: CheckCircle2, color: 'text-green-600', bg: 'bg-green-50' },
  { name: 'Locked / Disabled', value: '42', icon: Lock, color: 'text-purple-600', bg: 'bg-purple-50' },
  { name: 'Offline (> 24h)', value: '48', icon: WifiOff, color: 'text-amber-600', bg: 'bg-amber-50' },
  { name: 'Failed Syncs (24h)', value: '8', icon: AlertTriangle, color: 'text-red-600', bg: 'bg-red-50' },
];

const mockDevices = [
  { 
    id: 'dev_101', 
    name: 'Reception Front Desk Pad', 
    model: 'Samsung Galaxy Tab S9', 
    uid: 'a89c-44e1-bb20-99f1', 
    property: 'Grand Plaza Hotel', 
    owner: 'John Doe', 
    primaryUser: 'Alicia (Receptionist)', 
    osVersion: 'Android 14', 
    appVersion: 'v1.0.4', 
    status: 'active', 
    approvalStatus: 'approved', 
    lastSync: '2 mins ago', 
    lastLogin: 'Today, 08:30 AM', 
    battery: 94, 
    plan: 'Enterprise (8/10 used)',
    registeredAt: '2026-05-12'
  },
  { 
    id: 'dev_102', 
    name: 'Housekeeping Mobile #2', 
    model: 'Samsung M35 5G', 
    uid: 'b72d-11c3-ff88-22a4', 
    property: 'Sea View Resort', 
    owner: 'Jane Smith', 
    primaryUser: 'Carlos (Supervisor)', 
    osVersion: 'Android 13', 
    appVersion: 'v1.0.3', 
    status: 'pending_approval', 
    approvalStatus: 'pending', 
    lastSync: '10 mins ago', 
    lastLogin: 'Never', 
    battery: 78, 
    plan: 'Pro (5/5 used - CEILING)',
    registeredAt: '2026-07-10'
  },
  { 
    id: 'dev_103', 
    name: 'POS Bar Terminal', 
    model: 'Lenovo Tab M10 Plus', 
    uid: 'c55e-99f0-aa12-33d5', 
    property: 'City Lights Hostel', 
    owner: 'Mike Johnson', 
    primaryUser: 'Dave (Bartender)', 
    osVersion: 'Android 12', 
    appVersion: 'v1.0.2', 
    status: 'locked', 
    approvalStatus: 'approved', 
    lastSync: '2 days ago', 
    lastLogin: 'July 8, 11:20 PM', 
    battery: 45, 
    plan: 'Basic (3/3 used)',
    registeredAt: '2026-04-20'
  },
  { 
    id: 'dev_104', 
    name: 'Manager Audit Phone', 
    model: 'Google Pixel 8', 
    uid: 'd11a-33e4-cc77-55b8', 
    property: 'Mountain Inn', 
    owner: 'Sarah Wilson', 
    primaryUser: 'Sarah Wilson', 
    osVersion: 'Android 14', 
    appVersion: 'v1.0.4', 
    status: 'disabled', 
    approvalStatus: 'approved', 
    lastSync: '5 hours ago', 
    lastLogin: 'Yesterday, 06:15 PM', 
    battery: 88, 
    plan: 'Pro (2/5 used)',
    registeredAt: '2026-06-01'
  },
  { 
    id: 'dev_105', 
    name: 'Staff Kiosk #4 (Revoked)', 
    model: 'Redmi Pad SE', 
    uid: 'e99b-66a7-dd33-88e9', 
    property: 'Grand Plaza Hotel', 
    owner: 'John Doe', 
    primaryUser: 'Resigned Staff', 
    osVersion: 'Android 13', 
    appVersion: 'v1.0.1', 
    status: 'revoked', 
    approvalStatus: 'rejected', 
    lastSync: '1 week ago', 
    lastLogin: 'July 1, 04:00 PM', 
    battery: 12, 
    plan: 'Enterprise (8/10 used)',
    registeredAt: '2026-03-15'
  }
];

export default function GlobalDeviceConsole() {
  const [devices, setDevices] = useState(mockDevices);
  const [selectedDevice, setSelectedDevice] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [activeTab, setActiveTab] = useState('overview');
  const [actionModal, setActionModal] = useState({ open: false, type: '', device: null, input: '' });

  const filteredDevices = devices.filter(d => {
    const matchesSearch = d.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          d.property.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          d.uid.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          d.primaryUser.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'ALL' || d.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const handleActionClick = (type, device) => {
    if (type === 'forceSync') {
      alert(`Forced sync request queued for device: ${device.name} (${device.uid}). Mobile app will check in within 60 seconds.`);
      return;
    }
    setActionModal({ open: true, type, device, input: device.name });
  };

  const confirmAction = () => {
    const { type, device, input } = actionModal;
    let newStatus = device.status;
    let newName = device.name;
    let newApproval = device.approvalStatus;

    if (type === 'approve') {
      if (device.plan.includes('CEILING')) {
        alert('Cannot approve! Device limit reached for this property\'s subscription plan. Please deactivate another device or request the owner to upgrade their plan.');
        return;
      }
      newStatus = 'active';
      newApproval = 'approved';
    } else if (type === 'reject') {
      newStatus = 'rejected';
      newApproval = 'rejected';
    } else if (type === 'lock') {
      newStatus = 'locked';
    } else if (type === 'unlock') {
      newStatus = 'active';
    } else if (type === 'disable') {
      newStatus = 'disabled';
    } else if (type === 'enable') {
      newStatus = 'active';
    } else if (type === 'logout') {
      alert(`Force logout command queued for ${device.name}. Session token will be invalidated on next check-in.`);
      setActionModal({ open: false, type: '', device: null, input: '' });
      return;
    } else if (type === 'rename') {
      newName = input || device.name;
    } else if (type === 'transfer') {
      alert(`Device ${device.name} reassigned to staff ID: ${input}.`);
      setActionModal({ open: false, type: '', device: null, input: '' });
      return;
    } else if (type === 'revoke') {
      newStatus = 'revoked';
      newApproval = 'rejected';
      alert(`WARNING: License for ${device.name} revoked! Remote wipe and lockout command queued.`);
    }

    setDevices(devices.map(d => d.id === device.id ? { ...d, status: newStatus, approvalStatus: newApproval, name: newName } : d));
    if (selectedDevice && selectedDevice.id === device.id) {
      setSelectedDevice({ ...selectedDevice, status: newStatus, approvalStatus: newApproval, name: newName });
    }
    setActionModal({ open: false, type: '', device: null, input: '' });
  };

  return (
    <div className="space-y-6 animate-fade-in relative pb-16">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 tracking-tight flex items-center gap-2">
            <Smartphone className="h-6 w-6 text-pine-DEFAULT" />
            Global Device Management Console
          </h1>
          <p className="text-sm text-gray-500 mt-1">
            Central monitoring, licensing control, and security lockdown for all offline-first hardware devices across properties.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button 
            onClick={() => alert('Global diagnostics report downloading as CSV/JSON...')}
            className="flex items-center px-4 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 transition-colors"
          >
            <Download className="h-4 w-4 mr-2 text-gray-500" />
            Export Audit Logs
          </button>
          <button 
            onClick={() => alert('Broadcasting force sync ping to all active tenant nodes...')}
            className="flex items-center px-4 py-2 bg-pine-DEFAULT text-white rounded-lg shadow-sm text-sm font-medium hover:bg-pine-600 transition-colors"
          >
            <RefreshCw className="h-4 w-4 mr-2" />
            Broadcast Sync Check
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-6 gap-4">
        {kpiStats.map((stat) => (
          <div key={stat.name} className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm flex flex-col justify-between hover:shadow-md transition-shadow">
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold uppercase tracking-wider text-gray-400">{stat.name}</span>
              <div className={`p-2 rounded-lg ${stat.bg}`}>
                <stat.icon className={`h-5 w-5 ${stat.color}`} />
              </div>
            </div>
            <div className="mt-4 flex items-baseline justify-between">
              <span className="text-2xl font-bold text-gray-900">{stat.value}</span>
            </div>
          </div>
        ))}
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm flex flex-col sm:flex-row gap-4 justify-between items-center">
        <div className="flex flex-wrap items-center gap-2 w-full sm:w-auto">
          <span className="text-sm font-medium text-gray-500 mr-2 flex items-center gap-1">
            <Filter className="h-4 w-4" /> Filter Status:
          </span>
          {['ALL', 'active', 'pending_approval', 'locked', 'disabled', 'revoked'].map((status) => (
            <button
              key={status}
              onClick={() => setStatusFilter(status)}
              className={`px-3 py-1.5 rounded-full text-xs font-medium capitalize transition-all ${
                statusFilter === status
                  ? 'bg-pine-DEFAULT text-white shadow-sm'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              {status.replace('_', ' ')}
            </button>
          ))}
        </div>

        <div className="relative w-full sm:w-80">
          <Search className="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
          <input
            type="text"
            placeholder="Search device, property, UID, user..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pine-DEFAULT focus:border-transparent"
          />
        </div>
      </div>

      {/* Devices Directory Table */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Device & Model</th>
                <th className="px-6 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Property & Owner</th>
                <th className="px-6 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Primary Staff</th>
                <th className="px-6 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Status & Approval</th>
                <th className="px-6 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Sync Health & Battery</th>
                <th className="px-6 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Plan Limit</th>
                <th className="px-6 py-3.5 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 bg-white">
              {filteredDevices.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-gray-500">
                    No devices match your search or filter criteria.
                  </td>
                </tr>
              ) : (
                filteredDevices.map((device) => (
                  <tr 
                    key={device.id} 
                    className="hover:bg-gray-50/80 transition-colors cursor-pointer"
                    onClick={() => setSelectedDevice(device)}
                  >
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className="h-10 w-10 flex-shrink-0 rounded-lg bg-pine-50 border border-pine-100 flex items-center justify-center text-pine-DEFAULT font-bold text-xs">
                          <Smartphone className="h-5 w-5" />
                        </div>
                        <div className="ml-4">
                          <div className="text-sm font-semibold text-gray-900">{device.name}</div>
                          <div className="text-xs text-gray-500">{device.model} • UID: <span className="font-mono text-gray-600">{device.uid}</span></div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">{device.property}</div>
                      <div className="text-xs text-gray-500">Owner: {device.owner}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900 font-medium">{device.primaryUser}</div>
                      <div className="text-xs text-gray-500">{device.appVersion} ({device.osVersion})</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium capitalize ${
                        device.status === 'active' ? 'bg-green-100 text-green-800 border border-green-200' :
                        device.status === 'pending_approval' ? 'bg-yellow-100 text-yellow-800 border border-yellow-200' :
                        device.status === 'locked' ? 'bg-purple-100 text-purple-800 border border-purple-200' :
                        device.status === 'disabled' ? 'bg-gray-100 text-gray-800 border border-gray-200' :
                        'bg-red-100 text-red-800 border border-red-200'
                      }`}>
                        {device.status.replace('_', ' ')}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center gap-2">
                        <BatteryCharging className={`h-4 w-4 ${device.battery > 40 ? 'text-green-600' : device.battery > 20 ? 'text-amber-500' : 'text-red-500'}`} />
                        <span className="text-xs font-semibold text-gray-700">{device.battery}%</span>
                        <span className="text-gray-300">|</span>
                        <span className="text-xs text-gray-500">{device.lastSync}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`text-xs font-medium ${device.plan.includes('CEILING') ? 'text-red-600 font-bold bg-red-50 px-2 py-0.5 rounded border border-red-200' : 'text-gray-600'}`}>
                        {device.plan}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium" onClick={(e) => e.stopPropagation()}>
                      <div className="flex justify-end items-center space-x-2">
                        {device.status === 'pending_approval' ? (
                          <>
                            <button 
                              onClick={() => handleActionClick('approve', device)}
                              className="px-2.5 py-1 bg-green-600 text-white text-xs font-medium rounded hover:bg-green-700 shadow-sm"
                            >
                              Approve
                            </button>
                            <button 
                              onClick={() => handleActionClick('reject', device)}
                              className="px-2.5 py-1 bg-red-600 text-white text-xs font-medium rounded hover:bg-red-700 shadow-sm"
                            >
                              Reject
                            </button>
                          </>
                        ) : device.status === 'active' ? (
                          <>
                            <button 
                              onClick={() => handleActionClick('lock', device)}
                              title="Lock Device"
                              className="p-1.5 text-purple-600 hover:bg-purple-50 rounded"
                            >
                              <Lock className="h-4 w-4" />
                            </button>
                            <button 
                              onClick={() => handleActionClick('forceSync', device)}
                              title="Force Sync Check"
                              className="p-1.5 text-pine-DEFAULT hover:bg-pine-50 rounded"
                            >
                              <RefreshCw className="h-4 w-4" />
                            </button>
                          </>
                        ) : device.status === 'locked' ? (
                          <button 
                            onClick={() => handleActionClick('unlock', device)}
                            className="px-2.5 py-1 bg-purple-600 text-white text-xs font-medium rounded hover:bg-purple-700 shadow-sm flex items-center gap-1"
                          >
                            <Unlock className="h-3 w-3" /> Unlock
                          </button>
                        ) : null}
                        <button 
                          onClick={() => handleActionClick('rename', device)}
                          title="Rename / Actions"
                          className="p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded"
                        >
                          <MoreVertical className="h-4 w-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Slide-over Inspection Drawer */}
      {selectedDevice && (
        <div className="fixed inset-0 z-50 overflow-hidden bg-black/40 backdrop-blur-xs flex justify-end animate-fade-in">
          <div className="w-full max-w-2xl bg-white h-full shadow-2xl flex flex-col justify-between overflow-y-auto border-l border-gray-200">
            <div>
              {/* Drawer Header */}
              <div className="p-6 bg-pine-900 text-white flex items-center justify-between">
                <div>
                  <span className="text-xs uppercase tracking-wider text-pine-300 font-semibold">Device Diagnostic Inspection</span>
                  <h2 className="text-xl font-bold mt-1 flex items-center gap-2">
                    <Smartphone className="h-5 w-5 text-pine-300" />
                    {selectedDevice.name}
                  </h2>
                  <p className="text-xs text-pine-200 mt-0.5">Hardware UID: {selectedDevice.uid} • {selectedDevice.model}</p>
                </div>
                <button 
                  onClick={() => setSelectedDevice(null)}
                  className="p-2 text-pine-200 hover:text-white hover:bg-pine-800 rounded-full transition-colors"
                >
                  <X className="h-6 w-6" />
                </button>
              </div>

              {/* Drawer Navigation Tabs */}
              <div className="flex border-b border-gray-200 px-6 bg-gray-50">
                {['overview', 'timeline', 'license'].map((tab) => (
                  <button
                    key={tab}
                    onClick={() => setActiveTab(tab)}
                    className={`py-3 px-4 text-xs font-bold uppercase tracking-wider border-b-2 transition-all ${
                      activeTab === tab
                        ? 'border-pine-DEFAULT text-pine-DEFAULT bg-white'
                        : 'border-transparent text-gray-500 hover:text-gray-700'
                    }`}
                  >
                    {tab === 'overview' ? 'Hardware Overview' : tab === 'timeline' ? 'Audit & Sync Timeline' : 'License Cryptography'}
                  </button>
                ))}
              </div>

              {/* Tab 1: Overview */}
              {activeTab === 'overview' && (
                <div className="p-6 space-y-6">
                  <div className="grid grid-cols-2 gap-4">
                    <div className="p-4 bg-gray-50 rounded-xl border border-gray-200">
                      <span className="text-xs text-gray-400 font-semibold uppercase">Assigned Property</span>
                      <p className="text-sm font-bold text-gray-900 mt-1">{selectedDevice.property}</p>
                      <p className="text-xs text-gray-500">Owner: {selectedDevice.owner}</p>
                    </div>
                    <div className="p-4 bg-gray-50 rounded-xl border border-gray-200">
                      <span className="text-xs text-gray-400 font-semibold uppercase">Primary Staff Operator</span>
                      <p className="text-sm font-bold text-gray-900 mt-1">{selectedDevice.primaryUser}</p>
                      <p className="text-xs text-gray-500">Last Active: {selectedDevice.lastLogin}</p>
                    </div>
                    <div className="p-4 bg-gray-50 rounded-xl border border-gray-200">
                      <span className="text-xs text-gray-400 font-semibold uppercase">Operating System</span>
                      <p className="text-sm font-bold text-gray-900 mt-1">{selectedDevice.osVersion}</p>
                      <p className="text-xs text-gray-500">App Build: {selectedDevice.appVersion}</p>
                    </div>
                    <div className="p-4 bg-gray-50 rounded-xl border border-gray-200">
                      <span className="text-xs text-gray-400 font-semibold uppercase">Subscription Plan Ceiling</span>
                      <p className="text-sm font-bold text-gray-900 mt-1">{selectedDevice.plan}</p>
                      <p className="text-xs text-gray-500">Registered: {selectedDevice.registeredAt}</p>
                    </div>
                  </div>

                  {/* Quick Action Controls */}
                  <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-xs space-y-3">
                    <h3 className="text-xs font-bold uppercase tracking-wider text-gray-500">Security & Operational Actions</h3>
                    <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                      {selectedDevice.status === 'active' ? (
                        <>
                          <button 
                            onClick={() => handleActionClick('lock', selectedDevice)}
                            className="px-3 py-2 bg-purple-50 text-purple-700 border border-purple-200 rounded-lg text-xs font-semibold hover:bg-purple-100 flex items-center justify-center gap-1.5"
                          >
                            <Lock className="h-3.5 w-3.5" /> Lock Device
                          </button>
                          <button 
                            onClick={() => handleActionClick('logout', selectedDevice)}
                            className="px-3 py-2 bg-amber-50 text-amber-700 border border-amber-200 rounded-lg text-xs font-semibold hover:bg-amber-100 flex items-center justify-center gap-1.5"
                          >
                            <Power className="h-3.5 w-3.5" /> Force Logout
                          </button>
                          <button 
                            onClick={() => handleActionClick('disable', selectedDevice)}
                            className="px-3 py-2 bg-gray-100 text-gray-700 border border-gray-300 rounded-lg text-xs font-semibold hover:bg-gray-200 flex items-center justify-center gap-1.5"
                          >
                            <Ban className="h-3.5 w-3.5" /> Disable
                          </button>
                        </>
                      ) : selectedDevice.status === 'locked' ? (
                        <button 
                          onClick={() => handleActionClick('unlock', selectedDevice)}
                          className="px-3 py-2 bg-green-50 text-green-700 border border-green-200 rounded-lg text-xs font-semibold hover:bg-green-100 flex items-center justify-center gap-1.5"
                        >
                          <Unlock className="h-3.5 w-3.5" /> Unlock Device
                        </button>
                      ) : null}
                      <button 
                        onClick={() => handleActionClick('rename', selectedDevice)}
                        className="px-3 py-2 bg-blue-50 text-blue-700 border border-blue-200 rounded-lg text-xs font-semibold hover:bg-blue-100 flex items-center justify-center gap-1.5"
                      >
                        <Edit3 className="h-3.5 w-3.5" /> Rename
                      </button>
                      <button 
                        onClick={() => handleActionClick('transfer', selectedDevice)}
                        className="px-3 py-2 bg-indigo-50 text-indigo-700 border border-indigo-200 rounded-lg text-xs font-semibold hover:bg-indigo-100 flex items-center justify-center gap-1.5"
                      >
                        <UserCheck className="h-3.5 w-3.5" /> Transfer Staff
                      </button>
                      {selectedDevice.status !== 'revoked' && (
                        <button 
                          onClick={() => handleActionClick('revoke', selectedDevice)}
                          className="px-3 py-2 bg-red-50 text-red-700 border border-red-200 rounded-lg text-xs font-semibold hover:bg-red-100 flex items-center justify-center gap-1.5 col-span-2 sm:col-span-1"
                        >
                          <ShieldAlert className="h-3.5 w-3.5" /> Revoke & Wipe
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              )}

              {/* Tab 2: Audit & Sync Timeline */}
              {activeTab === 'timeline' && (
                <div className="p-6 space-y-4">
                  <h3 className="text-xs font-bold uppercase tracking-wider text-gray-500">Immutable Audit & Sync History</h3>
                  <div className="space-y-3">
                    {[
                      { time: 'Today, 10:15 AM', type: 'SYNC_CHECKIN', status: 'Success', detail: 'Pushed 14 bookings, pulled 2 room status updates. Battery: 94%.' },
                      { time: 'Yesterday, 06:00 PM', type: 'HEARTBEAT', status: 'Synced', detail: 'Background sync check. No delta records required.' },
                      { time: 'May 14, 2026, 09:12 AM', type: 'APPROVED', status: 'Approved', detail: 'Approved by John Doe (Property Owner). License token generated.' },
                      { time: 'May 12, 2026, 02:45 PM', type: 'REGISTERED', status: 'Pending Approval', detail: 'Initial hardware handshake from Samsung Galaxy Tab S9 (UID: a89c-44e1-bb20-99f1).' }
                    ].map((log, idx) => (
                      <div key={idx} className="p-3 bg-gray-50 rounded-xl border border-gray-200 flex items-start gap-3">
                        <div className="p-2 bg-white rounded-lg border border-gray-200 text-pine-DEFAULT mt-0.5">
                          <History className="h-4 w-4" />
                        </div>
                        <div className="flex-1">
                          <div className="flex items-center justify-between">
                            <span className="text-xs font-bold text-gray-800">{log.type}</span>
                            <span className="text-xs text-gray-400">{log.time}</span>
                          </div>
                          <p className="text-xs text-gray-600 mt-1">{log.detail}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Tab 3: License */}
              {activeTab === 'license' && (
                <div className="p-6 space-y-4">
                  <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl flex items-center gap-3">
                    <Key className="h-6 w-6 text-emerald-600 flex-shrink-0" />
                    <div>
                      <h4 className="text-sm font-bold text-emerald-900">Cryptographically Signed Offline Token</h4>
                      <p className="text-xs text-emerald-700 mt-0.5">Verifiable on-device via RSA/HMAC signature without active internet connection.</p>
                    </div>
                  </div>
                  <div className="p-4 bg-gray-900 rounded-xl font-mono text-xs text-gray-300 space-y-2 overflow-x-auto">
                    <div><span className="text-gray-500">LICENSE CODE:</span> PINE-STAY-88B12A4F</div>
                    <div><span className="text-gray-500">EXPIRES AT:</span> 2027-05-12T23:59:59Z</div>
                    <div><span className="text-gray-500">MAX DEVICES ALLOWED:</span> 10</div>
                    <div><span className="text-gray-500">DIGITAL SIGNATURE (HMAC-SHA256):</span></div>
                    <div className="text-emerald-400 break-all">3f88a91b2c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f</div>
                  </div>
                </div>
              )}
            </div>

            {/* Drawer Footer */}
            <div className="p-6 bg-gray-50 border-t border-gray-200 flex justify-end">
              <button
                onClick={() => setSelectedDevice(null)}
                className="px-5 py-2 bg-gray-200 text-gray-800 rounded-lg text-sm font-semibold hover:bg-gray-300 transition-colors"
              >
                Close Drawer
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Action Modal */}
      {actionModal.open && (
        <div className="fixed inset-0 z-50 overflow-hidden bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 animate-fade-in">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-gray-200 space-y-4">
            <h3 className="text-lg font-bold text-gray-900 capitalize flex items-center gap-2">
              <Edit3 className="h-5 w-5 text-pine-DEFAULT" />
              {actionModal.type} Device: {actionModal.device.name}
            </h3>
            
            {actionModal.type === 'rename' && (
              <div>
                <label className="block text-xs font-semibold text-gray-500 uppercase mb-1">New Display Label</label>
                <input
                  type="text"
                  value={actionModal.input}
                  onChange={(e) => setActionModal({ ...actionModal, input: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-pine-DEFAULT"
                />
              </div>
            )}

            {actionModal.type === 'transfer' && (
              <div>
                <label className="block text-xs font-semibold text-gray-500 uppercase mb-1">Target Staff User ID or Email</label>
                <input
                  type="text"
                  placeholder="e.g. staff_reception_02@hotel.com"
                  onChange={(e) => setActionModal({ ...actionModal, input: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-pine-DEFAULT"
                />
              </div>
            )}

            {(actionModal.type === 'approve' || actionModal.type === 'reject' || actionModal.type === 'lock' || actionModal.type === 'disable') && (
              <p className="text-sm text-gray-600">
                Are you sure you want to perform action <span className="font-bold text-gray-900 uppercase">{actionModal.type}</span> on <span className="font-semibold">{actionModal.device.name}</span>?
              </p>
            )}

            <div className="flex justify-end space-x-3 pt-4 border-t border-gray-100">
              <button
                onClick={() => setActionModal({ open: false, type: '', device: null, input: '' })}
                className="px-4 py-2 border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={confirmAction}
                className="px-4 py-2 bg-pine-DEFAULT text-white rounded-lg text-sm font-medium hover:bg-pine-600 shadow-sm"
              >
                Confirm Action
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
