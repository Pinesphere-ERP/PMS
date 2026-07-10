import { useState } from 'react';
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
  Trash2
} from 'lucide-react';

const mockOwnerDevices = [
  { 
    id: 'my_dev_1', 
    name: 'Reception Front Desk Pad', 
    model: 'Samsung Galaxy Tab S9', 
    uid: 'a89c-44e1-bb20-99f1', 
    primaryUser: 'Alicia (Receptionist)', 
    osVersion: 'Android 14', 
    appVersion: 'v1.0.4', 
    status: 'active', 
    lastSync: '2 mins ago', 
    battery: 94 
  },
  { 
    id: 'my_dev_2', 
    name: 'Housekeeping Supervisor Tablet', 
    model: 'Samsung M35 5G', 
    uid: 'b72d-11c3-ff88-22a4', 
    primaryUser: 'Carlos (Supervisor)', 
    osVersion: 'Android 13', 
    appVersion: 'v1.0.3', 
    status: 'pending_approval', 
    lastSync: '10 mins ago', 
    battery: 78 
  },
  { 
    id: 'my_dev_3', 
    name: 'POS Bar Pad #1', 
    model: 'Lenovo Tab M10 Plus', 
    uid: 'c55e-99f0-aa12-33d5', 
    primaryUser: 'Dave (Bartender)', 
    osVersion: 'Android 12', 
    appVersion: 'v1.0.2', 
    status: 'active', 
    lastSync: '2 days ago (OFFLINE ALERT)', 
    battery: 24 
  }
];

export default function MyDevicesPanel() {
  const navigate = useNavigate();
  const [devices, setDevices] = useState(mockOwnerDevices);
  const [revokeConfirmModal, setRevokeConfirmModal] = useState({ open: false, device: null, step: 1 });
  const [renameModal, setRenameModal] = useState({ open: false, device: null, newName: '' });

  // Plan stats
  const totalLimit = 5;
  const activeCount = devices.filter(d => d.status === 'active' || d.status === 'locked').length;
  const pendingCount = devices.filter(d => d.status === 'pending_approval').length;
  const offlineCount = devices.filter(d => d.lastSync.includes('days') || d.lastSync.includes('OFFLINE')).length;
  const isAtCeiling = activeCount >= totalLimit;

  const handleApprove = (dev) => {
    if (isAtCeiling) {
      alert(`Device ceiling (${totalLimit}) reached for your Pro Subscription Plan! Please deactivate or revoke an existing hardware device first, or request a limit upgrade.`);
      return;
    }
    setDevices(devices.map(d => d.id === dev.id ? { ...d, status: 'active' } : d));
  };

  const handleReject = (dev) => {
    setDevices(devices.map(d => d.id === dev.id ? { ...d, status: 'rejected' } : d));
  };

  const handleToggleLock = (dev) => {
    const newStatus = dev.status === 'locked' ? 'active' : 'locked';
    setDevices(devices.map(d => d.id === dev.id ? { ...d, status: newStatus } : d));
  };

  const handleRevokeFinal = () => {
    const dev = revokeConfirmModal.device;
    setDevices(devices.map(d => d.id === dev.id ? { ...d, status: 'revoked' } : d));
    setRevokeConfirmModal({ open: false, device: null, step: 1 });
    alert(`License for ${dev.name} immediately revoked! When the hardware unit next connects to internet during sync check-in, its local database and authentication tokens will be securely erased.`);
  };

  return (
    <div className="space-y-6 animate-fade-in relative pb-16">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 tracking-tight flex items-center gap-2">
            <Smartphone className="h-6 w-6 text-pine-DEFAULT" />
            My Devices Panel (Property Owner)
          </h1>
          <p className="text-sm text-gray-500 mt-1">
            Manage your property staff hardware units, approve registrations, and enforce remote device lockouts.
          </p>
        </div>
        <button 
          onClick={() => alert('Opening QR Code & WhatsApp Activation link generator for new staff...')}
          className="flex items-center px-4 py-2 bg-pine-DEFAULT text-white rounded-lg shadow-sm text-sm font-medium hover:bg-pine-600 transition-colors"
        >
          <Plus className="h-4 w-4 mr-2" />
          Add / Invite Staff Device
        </button>
      </div>

      {/* Subscription Plan Usage Meter & Alert Banner */}
      <div className={`p-6 rounded-2xl border ${isAtCeiling ? 'bg-red-50/80 border-red-200' : 'bg-white border-gray-200'} shadow-sm flex flex-col md:flex-row items-center justify-between gap-6`}>
        <div className="space-y-2 flex-1">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-gray-500">Subscription Plan Ceiling Meter</span>
            <span className={`text-sm font-bold ${isAtCeiling ? 'text-red-600' : 'text-pine-DEFAULT'}`}>
              {activeCount} / {totalLimit} Devices Active
            </span>
          </div>
          <div className="w-full bg-gray-200 h-3 rounded-full overflow-hidden">
            <div 
              className={`h-full transition-all duration-500 ${isAtCeiling ? 'bg-red-600' : 'bg-pine-DEFAULT'}`}
              style={{ width: `${(activeCount / totalLimit) * 100}%` }}
            />
          </div>
          <p className="text-xs text-gray-500">
            {isAtCeiling ? (
              <span className="font-semibold text-red-700 flex items-center gap-1 mt-1">
                <AlertTriangle className="h-4 w-4 inline" />
                You have reached your current plan ceiling. New staff devices cannot be approved until you upgrade your subscription or revoke an unused tablet.
              </span>
            ) : (
              `You can register up to ${totalLimit - activeCount} more staff devices under your current Pro Plan.`
            )}
          </p>
        </div>

        <button
          onClick={() => navigate('/subscriptions/manage')}
          className="px-5 py-2.5 bg-gray-900 text-white rounded-xl text-sm font-semibold hover:bg-gray-800 transition-colors flex items-center gap-2 flex-shrink-0 shadow-sm"
        >
          Request Limit Upgrade <ArrowUpRight className="h-4 w-4" />
        </button>
      </div>

      {/* Summary KPI Counters */}
      <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Active Devices</span>
            <div className="text-2xl font-bold text-gray-900 mt-1">{activeCount}</div>
          </div>
          <div className="p-2 bg-green-50 rounded-lg text-green-600">
            <CheckCircle2 className="h-6 w-6" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Pending Approval</span>
            <div className="text-2xl font-bold text-gray-900 mt-1">{pendingCount}</div>
          </div>
          <div className="p-2 bg-yellow-50 rounded-lg text-yellow-600">
            <Clock className="h-6 w-6" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Offline Warning</span>
            <div className="text-2xl font-bold text-gray-900 mt-1">{offlineCount}</div>
          </div>
          <div className="p-2 bg-amber-50 rounded-lg text-amber-600">
            <WifiOff className="h-6 w-6" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Plan Limit</span>
            <div className="text-2xl font-bold text-gray-900 mt-1">{totalLimit} Units</div>
          </div>
          <div className="p-2 bg-pine-50 rounded-lg text-pine-DEFAULT">
            <Smartphone className="h-6 w-6" />
          </div>
        </div>
      </div>

      {/* Alerts Feed */}
      {offlineCount > 0 && (
        <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 flex items-start gap-3">
          <BellRing className="h-5 w-5 text-amber-600 flex-shrink-0 mt-0.5" />
          <div>
            <h4 className="text-sm font-bold text-amber-900">Hardware Offline Alerts</h4>
            <p className="text-xs text-amber-800 mt-0.5">
              1 unit (POS Bar Pad #1) has not synced with cloud servers in over 48 hours. Please check physical connectivity and battery.
            </p>
          </div>
        </div>
      )}

      {/* Scoped Devices List */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
        <div className="p-4 border-b border-gray-200 bg-gray-50/50">
          <h2 className="text-sm font-bold text-gray-800 uppercase tracking-wider">Assigned Staff Hardware Directory</h2>
        </div>
        <div className="divide-y divide-gray-200">
          {devices.map((device) => (
            <div key={device.id} className="p-5 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 hover:bg-gray-50/50 transition-colors">
              <div className="flex items-start gap-4">
                <div className="h-12 w-12 rounded-xl bg-pine-50 border border-pine-100 flex items-center justify-center text-pine-DEFAULT flex-shrink-0">
                  <Smartphone className="h-6 w-6" />
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-base font-bold text-gray-900">{device.name}</span>
                    <span className={`px-2 py-0.5 rounded-full text-xs font-semibold uppercase ${
                      device.status === 'active' ? 'bg-green-100 text-green-800' :
                      device.status === 'pending_approval' ? 'bg-yellow-100 text-yellow-800' :
                      device.status === 'locked' ? 'bg-purple-100 text-purple-800' :
                      'bg-red-100 text-red-800'
                    }`}>
                      {device.status.replace('_', ' ')}
                    </span>
                  </div>
                  <p className="text-xs text-gray-500 mt-1">
                    Assigned Operator: <span className="font-semibold text-gray-700">{device.primaryUser}</span> • {device.model} ({device.appVersion})
                  </p>
                  <div className="flex items-center gap-4 mt-2 text-xs text-gray-500">
                    <span className="flex items-center gap-1">
                      <BatteryCharging className={`h-4 w-4 ${device.battery > 30 ? 'text-green-600' : 'text-red-500'}`} />
                      {device.battery}% Battery
                    </span>
                    <span>Last Sync: <strong className={device.lastSync.includes('OFFLINE') ? 'text-red-600' : 'text-gray-700'}>{device.lastSync}</strong></span>
                    <span className="font-mono text-gray-400">UID: {device.uid}</span>
                  </div>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex items-center flex-wrap gap-2 self-end sm:self-center">
                {device.status === 'pending_approval' ? (
                  <>
                    <button
                      onClick={() => handleApprove(device)}
                      className="px-3 py-1.5 bg-green-600 text-white rounded-lg text-xs font-semibold hover:bg-green-700 shadow-sm"
                    >
                      Approve Device
                    </button>
                    <button
                      onClick={() => handleReject(device)}
                      className="px-3 py-1.5 bg-gray-200 text-gray-800 rounded-lg text-xs font-semibold hover:bg-gray-300"
                    >
                      Reject
                    </button>
                  </>
                ) : device.status !== 'revoked' ? (
                  <>
                    <button
                      onClick={() => handleToggleLock(device)}
                      className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1 border ${
                        device.status === 'locked'
                          ? 'bg-green-50 text-green-700 border-green-200 hover:bg-green-100'
                          : 'bg-purple-50 text-purple-700 border-purple-200 hover:bg-purple-100'
                      }`}
                    >
                      {device.status === 'locked' ? <Unlock className="h-3.5 w-3.5" /> : <Lock className="h-3.5 w-3.5" />}
                      {device.status === 'locked' ? 'Unlock Unit' : 'Temporary Lock'}
                    </button>
                    <button
                      onClick={() => {
                        setRenameModal({ open: true, device, newName: device.name });
                      }}
                      className="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg border border-gray-200"
                      title="Rename Device"
                    >
                      <Edit3 className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => alert(`Force session logout queued for ${device.name}. Staff will be required to re-authenticate with their PIN on next screen transition.`)}
                      className="p-2 text-amber-600 hover:bg-amber-50 rounded-lg border border-amber-200"
                      title="Force Logout Staff Session"
                    >
                      <Power className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => setRevokeConfirmModal({ open: true, device, step: 1 })}
                      className="px-3 py-1.5 bg-red-50 text-red-700 border border-red-200 rounded-lg text-xs font-semibold hover:bg-red-100 flex items-center gap-1"
                    >
                      <ShieldAlert className="h-3.5 w-3.5" /> Revoke & Erase
                    </button>
                  </>
                ) : (
                  <span className="text-xs text-red-600 font-bold bg-red-50 px-3 py-1 rounded-full border border-red-200">
                    License Revoked & Wiped
                  </span>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* 2-Step Resignation / Revoke Confirmation Modal */}
      {revokeConfirmModal.open && (
        <div className="fixed inset-0 z-50 overflow-hidden bg-black/50 backdrop-blur-xs flex items-center justify-center p-4 animate-fade-in">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-red-200 space-y-4">
            <div className="flex items-center gap-3 text-red-600">
              <ShieldAlert className="h-8 w-8 flex-shrink-0" />
              <div>
                <h3 className="text-lg font-bold text-gray-900">
                  {revokeConfirmModal.step === 1 ? 'Confirm License Revocation' : 'STEP 2: Final Data Erase Warning'}
                </h3>
                <p className="text-xs text-red-600 font-semibold uppercase">Security Remote Wipe Protocol</p>
              </div>
            </div>

            {revokeConfirmModal.step === 1 ? (
              <div className="space-y-3 text-sm text-gray-600">
                <p>
                  You are about to revoke the active license token for <strong className="text-gray-900">{revokeConfirmModal.device?.name}</strong> (Assigned to {revokeConfirmModal.device?.primaryUser}).
                </p>
                <div className="p-3 bg-red-50 rounded-xl border border-red-100 text-xs text-red-800 space-y-1">
                  <p><strong>• License Invalidation:</strong> This hardware unit will immediately lose rights to operate offline.</p>
                  <p><strong>• Slot Freed:</strong> Your property device limit meter will regain 1 active slot.</p>
                </div>
              </div>
            ) : (
              <div className="space-y-3 text-sm text-gray-600">
                <p className="font-bold text-red-600">
                  CRITICAL: Remote Database Erase Queued!
                </p>
                <p>
                  To prevent unauthorized data exfiltration after staff resignation (Section 3.5 & 4.3), when <strong className="text-gray-900">{revokeConfirmModal.device?.name}</strong> next connects to internet, the Pinesphere Stay mobile app will automatically execute a complete wipe of its local ObjectBox database (`rooms`, `bookings`, `guest info`).
                </p>
                <p className="text-xs text-gray-500 italic">This action is irreversible once delivered.</p>
              </div>
            )}

            <div className="flex justify-end space-x-3 pt-4 border-t border-gray-100">
              <button
                onClick={() => setRevokeConfirmModal({ open: false, device: null, step: 1 })}
                className="px-4 py-2 border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              {revokeConfirmModal.step === 1 ? (
                <button
                  onClick={() => setRevokeConfirmModal({ ...revokeConfirmModal, step: 2 })}
                  className="px-4 py-2 bg-red-600 text-white rounded-lg text-sm font-semibold hover:bg-red-700 shadow-sm"
                >
                  Proceed to Step 2
                </button>
              ) : (
                <button
                  onClick={handleRevokeFinal}
                  className="px-4 py-2 bg-red-700 text-white rounded-lg text-sm font-bold hover:bg-red-800 shadow-md flex items-center gap-1.5"
                >
                  <Trash2 className="h-4 w-4" /> Yes, Revoke & Erase Database
                </button>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Rename Modal */}
      {renameModal.open && (
        <div className="fixed inset-0 z-50 overflow-hidden bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 animate-fade-in">
          <div className="bg-white rounded-2xl max-w-sm w-full p-6 shadow-2xl border border-gray-200 space-y-4">
            <h3 className="text-base font-bold text-gray-900">Rename Staff Hardware</h3>
            <div>
              <label className="block text-xs font-semibold text-gray-500 uppercase mb-1">New Display Name</label>
              <input
                type="text"
                value={renameModal.newName}
                onChange={(e) => setRenameModal({ ...renameModal, newName: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-pine-DEFAULT"
              />
            </div>
            <div className="flex justify-end space-x-3 pt-2">
              <button
                onClick={() => setRenameModal({ open: false, device: null, newName: '' })}
                className="px-3 py-1.5 border border-gray-300 rounded-lg text-xs font-medium text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  setDevices(devices.map(d => d.id === renameModal.device.id ? { ...d, name: renameModal.newName } : d));
                  setRenameModal({ open: false, device: null, newName: '' });
                }}
                className="px-3 py-1.5 bg-pine-DEFAULT text-white rounded-lg text-xs font-semibold hover:bg-pine-600 shadow-sm"
              >
                Save Name
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
