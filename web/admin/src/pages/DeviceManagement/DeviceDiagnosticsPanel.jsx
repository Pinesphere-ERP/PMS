import { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { 
  Smartphone,
  Search,
  AlertCircle,
  RefreshCw,
  FileText,
  MessageSquare,
  Shield,
  Activity,
  History,
  CheckCircle,
  XCircle,
  Clock,
  Send,
  HelpCircle,
  Loader2,
  X
} from 'lucide-react';
import { deviceService } from '../../services/deviceService';
import DataTable from '../../components/ui/DataTable';

export default function DeviceDiagnosticsPanel() {
  const [selectedDevice, setSelectedDevice] = useState(null);
  const [activeTab, setActiveTab] = useState('sync');
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);

  // API State
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [devices, setDevices] = useState([]);

  useEffect(() => {
    const fetchDiagnostics = async () => {
      setLoading(true);
      try {
        const data = await deviceService.getDiagnostics();
        setDevices(Array.isArray(data) ? data : (data.data || []));
        setError(null);
      } catch (err) {
        setError(err.message || 'Failed to fetch diagnostic data');
      } finally {
        setLoading(false);
      }
    };
    fetchDiagnostics();
  }, []);

  const handleSupportMessage = () => {
    alert(`Sending support message to device: ${selectedDevice.name}`);
  };

  const handleRemoteWipe = () => {
    if (window.confirm(`Are you absolutely sure you want to REMOTE WIPE device ${selectedDevice.name}? This will delete all local app data.`)) {
      alert('Remote wipe command queued.');
    }
  };

  const handleOpenDrawer = (dev) => {
    setSelectedDevice(dev);
    setTimeout(() => setIsDrawerOpen(true), 10);
  };

  const handleCloseDrawer = () => {
    setIsDrawerOpen(false);
    setTimeout(() => setSelectedDevice(null), 300);
  };

  const columns = [
    {
      header: 'Device',
      accessor: 'name',
      sortable: true,
      render: (row) => (
        <div>
          <p className="text-sm font-medium text-gray-900">{row.name}</p>
          <p className="text-xs text-gray-500 mt-0.5">{row.property}</p>
        </div>
      )
    },
    {
      header: 'UID',
      accessor: 'uid',
      sortable: true,
      render: (row) => <span className="font-mono text-xs text-gray-500">{row.uid}</span>
    },
    {
      header: 'Status',
      accessor: 'syncStatus',
      sortable: true,
      render: (row) => (
        <span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium border ${
          row.syncStatus === 'SYNC_ERROR' ? 'bg-red-50 text-red-700 border-red-200' :
          row.syncStatus === 'OFFLINE' ? 'bg-amber-50 text-amber-700 border-amber-200' :
          'bg-emerald-50 text-emerald-700 border-emerald-200'
        }`}>
          {row.syncStatus === 'SYNC_ERROR' ? <AlertCircle className="w-3 h-3" /> :
           row.syncStatus === 'OFFLINE' ? <Clock className="w-3 h-3" /> :
           <CheckCircle className="w-3 h-3" />}
          {row.syncStatus}
        </span>
      )
    },
    {
      header: 'Battery',
      accessor: 'battery',
      sortable: true,
      render: (row) => <span className="text-sm font-medium text-gray-900">{row.battery}%</span>
    },
    {
      header: 'App Version',
      accessor: 'appVersion',
      sortable: true,
      render: (row) => <span className="text-sm text-gray-600">{row.appVersion}</span>
    }
  ];

  return (
    <div className="space-y-6 animate-slide-up h-[calc(100vh-120px)] flex flex-col">
      <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center shrink-0">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 tracking-tight">Device Diagnostics</h1>
          <p className="text-sm text-gray-500 mt-1">Deep-dive into sync logs, errors, and remote troubleshooting.</p>
        </div>
      </div>
      <div className="flex-1">
        <DataTable 
          columns={columns}
          data={devices}
          loading={loading}
          error={error}
          emptyStateMessage="No diagnostics found."
          searchPlaceholder="Search by name, UID, property..."
          onRowClick={handleOpenDrawer}
        />
      </div>
      {/* Drawer */}
      {createPortal(
        <>
          <div className={`saas-drawer-overlay ${isDrawerOpen ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'}`} onClick={handleCloseDrawer} />
          <div className={`saas-drawer flex flex-col w-[600px] max-w-full ${isDrawerOpen ? 'translate-x-0' : 'translate-x-full'}`}>
            {selectedDevice && (
              <>
                <div className="p-6 border-b border-gray-100 flex items-start justify-between bg-gray-50/50 shrink-0">
                  <div className="flex items-center">
                    <div className={`h-12 w-12 rounded-xl flex items-center justify-center ${
                      selectedDevice.syncStatus === 'SYNC_ERROR' ? 'bg-red-50 text-red-600 border border-red-100' :
                      selectedDevice.syncStatus === 'OFFLINE' ? 'bg-amber-50 text-amber-600 border border-amber-100' :
                      'bg-green-50 text-green-600 border border-green-100'
                    }`}>
                      <Smartphone className="h-6 w-6" />
                    </div>
                    <div className="ml-4">
                      <h2 className="text-xl font-bold text-gray-900">{selectedDevice.name}</h2>
                      <div className="flex items-center text-sm text-gray-500 mt-1">
                        <span>{selectedDevice.model}</span>
                        <span className="mx-2">•</span>
                        <span className="font-mono text-xs">{selectedDevice.uid}</span>
                      </div>
                    </div>
                  </div>
                  <div className="flex gap-2">
                    <button className="saas-button-secondary py-1.5 px-3 text-xs"><RefreshCw className="h-3 w-3 mr-1.5"/> Force Sync</button>
                    <button onClick={handleCloseDrawer} className="p-2 text-gray-400 hover:text-gray-900 hover:bg-gray-100 rounded-full transition-colors">
                      <X className="h-5 w-5" />
                    </button>
                  </div>
                </div>

                <div className="px-6 py-6 grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div className="bg-white border border-gray-100 rounded-lg p-3 shadow-sm">
                    <p className="text-[10px] uppercase text-gray-500 font-semibold tracking-wider">Battery</p>
                    <p className="text-lg font-bold text-gray-900 mt-1">{selectedDevice.battery}%</p>
                  </div>
                  <div className="bg-white border border-gray-100 rounded-lg p-3 shadow-sm">
                    <p className="text-[10px] uppercase text-gray-500 font-semibold tracking-wider">App Version</p>
                    <p className="text-lg font-bold text-gray-900 mt-1">{selectedDevice.appVersion}</p>
                  </div>
                  <div className="bg-white border border-gray-100 rounded-lg p-3 shadow-sm">
                    <p className="text-[10px] uppercase text-gray-500 font-semibold tracking-wider">Last Sync</p>
                    <p className="text-sm font-bold text-gray-900 mt-1 line-clamp-1">{selectedDevice.lastSync}</p>
                  </div>
                  <div className="bg-white border border-gray-100 rounded-lg p-3 shadow-sm">
                    <p className="text-[10px] uppercase text-gray-500 font-semibold tracking-wider">Status</p>
                    <p className={`text-sm font-bold mt-1 line-clamp-1 ${
                      selectedDevice.syncStatus === 'SYNC_ERROR' ? 'text-red-600' :
                      selectedDevice.syncStatus === 'OFFLINE' ? 'text-amber-600' :
                      'text-green-600'
                    }`}>{selectedDevice.syncStatus}</p>
                  </div>
                </div>

              {/* Tabs */}
              <div className="px-6 pt-4 border-b border-gray-100 flex gap-6 shrink-0">
                <button 
                  onClick={() => setActiveTab('sync')}
                  className={`pb-3 text-sm font-medium border-b-2 transition-colors ${activeTab === 'sync' ? 'border-pine text-pine' : 'border-transparent text-gray-500 hover:text-gray-700'}`}
                >
                  <div className="flex items-center"><Activity className="h-4 w-4 mr-2"/> Sync History</div>
                </button>
                <button 
                  onClick={() => setActiveTab('actions')}
                  className={`pb-3 text-sm font-medium border-b-2 transition-colors ${activeTab === 'actions' ? 'border-pine text-pine' : 'border-transparent text-gray-500 hover:text-gray-700'}`}
                >
                  <div className="flex items-center"><Shield className="h-4 w-4 mr-2"/> Remote Actions</div>
                </button>
              </div>

              {/* Tab Content */}
              <div className="flex-1 overflow-y-auto p-6 bg-gray-50/30">
                {activeTab === 'sync' && (
                  <div className="space-y-4">
                    <h3 className="text-sm font-semibold text-gray-900">Recent Sync Attempts</h3>
                    
                    <div className="relative border-l border-gray-200 ml-3 space-y-6 pb-4">
                      {selectedDevice.syncAttempts && selectedDevice.syncAttempts.length > 0 ? selectedDevice.syncAttempts.map((attempt, idx) => (
                        <div key={idx} className="relative pl-6">
                          <div className={`absolute -left-1.5 top-1.5 h-3 w-3 rounded-full border-2 border-white ${
                            attempt.status === 'SUCCESS' ? 'bg-green-500' : 'bg-red-500'
                          }`}></div>
                          
                          <div className="bg-white border border-gray-100 rounded-xl p-4 shadow-sm">
                            <div className="flex justify-between items-start mb-2">
                              <div className="flex items-center">
                                <span className={`text-xs font-bold px-2 py-0.5 rounded uppercase ${
                                  attempt.status === 'SUCCESS' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                                }`}>{attempt.status}</span>
                                <span className="text-xs text-gray-500 ml-3 flex items-center"><Clock className="h-3 w-3 mr-1"/> {attempt.time}</span>
                              </div>
                              <span className="text-xs font-medium text-gray-600 bg-gray-50 px-2 py-1 rounded">{attempt.records}</span>
                            </div>
                            
                            {attempt.error && (
                              <div className="mt-3 bg-red-50 border border-red-100 rounded-lg p-3 flex items-start">
                                <XCircle className="h-4 w-4 text-red-500 mt-0.5 mr-2 shrink-0" />
                                <p className="text-xs text-red-700 font-mono break-all">{attempt.error}</p>
                              </div>
                            )}
                          </div>
                        </div>
                      )) : (
                        <p className="text-xs text-gray-500 pl-4">No sync attempts recorded.</p>
                      )}
                    </div>
                  </div>
                )}

                {activeTab === 'actions' && (
                  <div className="space-y-6">
                    <div className="bg-white border border-gray-100 rounded-xl p-5 shadow-sm">
                      <h3 className="text-sm font-semibold text-gray-900 flex items-center mb-4">
                        <MessageSquare className="h-4 w-4 mr-2 text-pine" /> Send Support Message
                      </h3>
                      <p className="text-xs text-gray-500 mb-3">Send a push notification directly to this device's screen. Useful for instructing staff to restart the app or connect to WiFi.</p>
                      <textarea 
                        className="saas-input w-full text-sm min-h-[80px] mb-3" 
                        placeholder="Type your message here..."
                      ></textarea>
                      <button onClick={handleSupportMessage} className="saas-button-primary w-full justify-center"><Send className="h-4 w-4 mr-2"/> Send to Device</button>
                    </div>

                    <div className="bg-white border border-red-100 rounded-xl p-5 shadow-sm relative overflow-hidden">
                      <div className="absolute top-0 left-0 w-1 h-full bg-red-500"></div>
                      <h3 className="text-sm font-semibold text-red-700 flex items-center mb-2">
                        <AlertCircle className="h-4 w-4 mr-2" /> Danger Zone: Remote Wipe
                      </h3>
                      <p className="text-xs text-gray-600 mb-4">
                        This action will immediately command the device to delete all local app data, unsynced offline records, and unregister itself. This action cannot be undone.
                      </p>
                      <button onClick={handleRemoteWipe} className="bg-red-50 text-red-600 border border-red-200 hover:bg-red-100 font-semibold py-2 px-4 rounded-lg w-full transition-colors text-sm">
                        Initiate Remote Wipe
                      </button>
                    </div>
                  </div>
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
