import { useState, useEffect } from 'react';
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
  Loader2
} from 'lucide-react';
import { deviceService } from '../../services/deviceService';

export default function DeviceDiagnosticsPanel() {
  const [selectedDevice, setSelectedDevice] = useState(null);
  const [activeTab, setActiveTab] = useState('sync');
  const [searchTerm, setSearchTerm] = useState('');

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
        if (data && data.length > 0) {
          setSelectedDevice(Array.isArray(data) ? data[0] : data.data[0]);
        }
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

  const filteredDevices = devices.filter(dev => 
    (dev.name && dev.name.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (dev.uid && dev.uid.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (dev.property && dev.property.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  return (
    <div className="space-y-6 animate-slide-up h-[calc(100vh-120px)] flex flex-col">
      <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center shrink-0">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 tracking-tight">Device Diagnostics</h1>
          <p className="text-sm text-gray-500 mt-1">Deep-dive into sync logs, errors, and remote troubleshooting.</p>
        </div>
        <div className="flex space-x-3 mt-4 sm:mt-0">
          <div className="relative w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input 
              type="text" 
              placeholder="Search by name, UID..." 
              className="saas-input pl-9 w-full bg-white shadow-sm"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
        </div>
      </div>

      <div className="flex flex-1 gap-6 overflow-hidden min-h-[400px]">
        {/* Left List Pane */}
        <div className="w-1/3 bg-white border border-gray-200 shadow-sm rounded-xl flex flex-col overflow-hidden shrink-0 relative">
          <div className="p-4 border-b border-gray-100 bg-gray-50/50 flex justify-between items-center shrink-0">
            <h2 className="text-sm font-semibold text-gray-700">Diagnostic Queue</h2>
            <button className="text-gray-400 hover:text-pine transition-colors p-1"><RefreshCw className="h-4 w-4" /></button>
          </div>
          
          {loading && (
            <div className="absolute inset-0 flex flex-col items-center justify-center bg-white/80 z-10 mt-14">
               <Loader2 className="h-6 w-6 text-pine animate-spin mb-2" />
               <p className="text-gray-500 text-xs">Loading devices...</p>
            </div>
          )}

          {error && !loading && (
            <div className="absolute inset-0 flex flex-col items-center justify-center bg-white/80 z-10 mt-14">
               <AlertCircle className="h-6 w-6 text-red-500 mb-2" />
               <p className="text-gray-800 text-xs font-medium px-4 text-center">Failed to load diagnostics</p>
            </div>
          )}

          <div className="flex-1 overflow-y-auto p-2 space-y-1">
            {!loading && !error && filteredDevices.length === 0 && (
              <div className="p-4 text-center text-xs text-gray-500">No devices match your search.</div>
            )}
            {filteredDevices.map((dev, idx) => (
              <button 
                key={dev.id || idx}
                onClick={() => setSelectedDevice(dev)}
                className={`w-full text-left p-3 rounded-lg transition-colors border ${
                  selectedDevice?.id === dev.id 
                    ? 'bg-pine-50 border-pine-100 ring-1 ring-pine/20' 
                    : 'bg-white border-transparent hover:bg-gray-50'
                }`}
              >
                <div className="flex justify-between items-start">
                  <div className="truncate pr-2">
                    <p className={`text-sm font-medium truncate ${selectedDevice?.id === dev.id ? 'text-pine-dark' : 'text-gray-900'}`}>{dev.name}</p>
                    <p className="text-xs text-gray-500 mt-0.5 truncate">{dev.property}</p>
                  </div>
                  {dev.syncStatus === 'SYNC_ERROR' ? (
                    <AlertCircle className="h-4 w-4 text-red-500 shrink-0" />
                  ) : dev.syncStatus === 'OFFLINE' ? (
                    <Clock className="h-4 w-4 text-amber-500 shrink-0" />
                  ) : (
                    <CheckCircle className="h-4 w-4 text-green-500 shrink-0" />
                  )}
                </div>
                <div className="flex items-center mt-2 text-[10px] text-gray-400 font-mono">
                  <span>{dev.uid}</span>
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* Right Detail Pane */}
        <div className="flex-1 bg-white border border-gray-200 shadow-sm rounded-xl flex flex-col overflow-hidden">
          {selectedDevice ? (
            <>
              {/* Header */}
              <div className="p-6 border-b border-gray-100 bg-gray-50/30 shrink-0">
                <div className="flex justify-between items-start">
                  <div className="flex items-center">
                    <div className={`h-12 w-12 rounded-xl flex items-center justify-center ${
                      selectedDevice.syncStatus === 'SYNC_ERROR' ? 'bg-red-50 text-red-600' :
                      selectedDevice.syncStatus === 'OFFLINE' ? 'bg-amber-50 text-amber-600' :
                      'bg-green-50 text-green-600'
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
                  </div>
                </div>
                
                <div className="grid grid-cols-4 gap-4 mt-6">
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
          ) : (
            <div className="flex-1 flex flex-col items-center justify-center text-gray-400 p-8">
              <HelpCircle className="h-16 w-16 mb-4 text-gray-200" />
              <p className="text-lg font-medium text-gray-600">No device selected</p>
              <p className="text-sm text-gray-400 mt-2 text-center max-w-sm">Select a device from the diagnostic queue on the left to view detailed logs and perform remote troubleshooting.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
