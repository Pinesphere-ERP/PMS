import { useState } from 'react';
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
  HelpCircle
} from 'lucide-react';

const mockDiagnosticDevices = [
  { 
    id: 'diag_1', 
    name: 'Reception Front Desk Pad', 
    model: 'Samsung Galaxy Tab S9', 
    uid: 'a89c-44e1-bb20-99f1', 
    property: 'Grand Plaza Hotel', 
    mobile: '+1 234 567 8901', 
    osVersion: 'Android 14', 
    appVersion: 'v1.0.4', 
    syncStatus: 'HEALTHY', 
    lastSync: '2 mins ago', 
    battery: 94,
    syncAttempts: [
      { time: '10:14 AM', status: 'SUCCESS', records: '14 pushed / 2 pulled', error: null },
      { time: '10:00 AM', status: 'SUCCESS', records: '0 pushed / 0 pulled', error: null },
      { time: '09:45 AM', status: 'SUCCESS', records: '5 pushed / 1 pulled', error: null }
    ]
  },
  { 
    id: 'diag_2', 
    name: 'POS Bar Pad #1', 
    model: 'Lenovo Tab M10 Plus', 
    uid: 'c55e-99f0-aa12-33d5', 
    property: 'City Lights Hostel', 
    mobile: '+1 555 123 4567', 
    osVersion: 'Android 12', 
    appVersion: 'v1.0.2', 
    syncStatus: 'SYNC_ERROR', 
    lastSync: '48 hours ago', 
    battery: 24,
    syncAttempts: [
      { time: 'July 8, 11:20 PM', status: 'FAILED', records: '0 pushed / 0 pulled', error: 'HTTP 408 Request Timeout: Network connection dropped during delta upload' },
      { time: 'July 8, 11:05 PM', status: 'FAILED', records: '0 pushed / 0 pulled', error: 'DatabaseLockException: SQLite file temporarily busy during housekeeping sweep' },
      { time: 'July 8, 10:50 PM', status: 'SUCCESS', records: '18 pushed / 4 pulled', error: null }
    ]
  },
  { 
    id: 'diag_3', 
    name: 'Housekeeping Mobile #2', 
    model: 'Samsung M35 5G', 
    uid: 'b72d-11c3-ff88-22a4', 
    property: 'Sea View Resort', 
    mobile: '+1 987 654 3210', 
    osVersion: 'Android 13', 
    appVersion: 'v1.0.3', 
    syncStatus: 'HEALTHY', 
    lastSync: '10 mins ago', 
    battery: 78,
    syncAttempts: [
      { time: '10:02 AM', status: 'SUCCESS', records: '6 pushed / 12 pulled', error: null }
    ]
  }
];

export default function DeviceDiagnosticsPanel() {
  const [searchTerm, setSearchTerm] = useState('');
  const [devices] = useState(mockDiagnosticDevices);
  const [selectedDiag, setSelectedDiag] = useState(mockDiagnosticDevices[1]); // Default to the error one
  const [chatDrawerOpen, setChatDrawerOpen] = useState(false);
  const [chatMessages, setChatMessages] = useState([
    { sender: 'System', text: 'Automated diagnostic channel initialized for device c55e-99f0-aa12-33d5.', time: '10:15 AM' },
    { sender: 'Support Engineer', text: 'Hi Mike, I see your POS Bar Pad had a network drop two days ago. Could you verify if the tablet is still connected to the bar WiFi network?', time: '10:16 AM' }
  ]);
  const [newMessage, setNewMessage] = useState('');

  const filtered = devices.filter(d => 
    d.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    d.property.toLowerCase().includes(searchTerm.toLowerCase()) ||
    d.uid.toLowerCase().includes(searchTerm.toLowerCase()) ||
    d.mobile.includes(searchTerm)
  );

  const handleSendChat = (e) => {
    e.preventDefault();
    if (!newMessage.trim()) return;
    setChatMessages([...chatMessages, { sender: 'Support Engineer', text: newMessage, time: 'Just now' }]);
    setNewMessage('');
  };

  return (
    <div className="space-y-6 animate-fade-in relative pb-16">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 tracking-tight flex items-center gap-2">
            <Activity className="h-6 w-6 text-pine-DEFAULT" />
            Device Diagnostics Console (Support Role)
          </h1>
          <p className="text-sm text-gray-500 mt-1">
            Troubleshoot offline sync failures, inspect network transmission errors, and trigger non-destructive diagnostics.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="inline-flex items-center px-3 py-1.5 rounded-full text-xs font-bold bg-blue-50 text-blue-700 border border-blue-200">
            <Shield className="h-3.5 w-3.5 mr-1" />
            Support Role Access Matrix
          </span>
        </div>
      </div>

      {/* Role Enforcement Notice Banner */}
      <div className="bg-slate-900 text-slate-100 p-4 rounded-xl border border-slate-800 flex items-center justify-between gap-4 shadow-sm">
        <div className="flex items-center gap-3">
          <HelpCircle className="h-5 w-5 text-amber-400 flex-shrink-0" />
          <p className="text-xs sm:text-sm">
            <strong className="text-amber-400 font-semibold">Security Matrix Enforcement:</strong> As a Support Engineer, you can inspect telemetry, re-issue tokens (`Reset License`), and trigger forced syncs. Actions modifying ownership (`Approve`, `Reject`, `Revoke License`, `Subscription Changes`) are strictly disabled per compliance rules.
          </p>
        </div>
      </div>

      {/* Search Bar */}
      <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm flex items-center justify-between">
        <div className="relative w-full max-w-lg">
          <Search className="absolute left-3.5 top-3 h-4 w-4 text-gray-400" />
          <input
            type="text"
            placeholder="Search by Device UID, Property Name, or Customer Mobile Number (+1 555...)"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pine-DEFAULT"
          />
        </div>
        <span className="text-xs text-gray-400 hidden md:block">Showing {filtered.length} hardware units</span>
      </div>

      {/* Diagnostic Workspace Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column: Device Selector List */}
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden lg:col-span-1 flex flex-col h-[600px]">
          <div className="p-4 border-b border-gray-200 bg-gray-50 font-bold text-xs uppercase tracking-wider text-gray-600">
            Hardware Units Directory
          </div>
          <div className="divide-y divide-gray-200 overflow-y-auto flex-1">
            {filtered.map((device) => (
              <div
                key={device.id}
                onClick={() => setSelectedDiag(device)}
                className={`p-4 cursor-pointer transition-colors ${
                  selectedDiag?.id === device.id ? 'bg-pine-50/80 border-l-4 border-l-pine-DEFAULT' : 'hover:bg-gray-50'
                }`}
              >
                <div className="flex items-center justify-between">
                  <span className="text-sm font-bold text-gray-900">{device.name}</span>
                  <span className={`px-2 py-0.5 rounded text-[10px] font-extrabold uppercase ${
                    device.syncStatus === 'HEALTHY' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                  }`}>
                    {device.syncStatus}
                  </span>
                </div>
                <p className="text-xs text-gray-600 mt-1 font-medium">{device.property}</p>
                <p className="text-[11px] text-gray-400 mt-0.5">UID: {device.uid} • Mobile: {device.mobile}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Right Column: Detailed Telemetry & Diagnostic Actions */}
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden lg:col-span-2 flex flex-col h-[600px]">
          {selectedDiag ? (
            <div className="flex-1 overflow-y-auto flex flex-col justify-between p-6">
              <div className="space-y-6">
                {/* Device Info & Status Banner */}
                <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between pb-4 border-b border-gray-200 gap-4">
                  <div>
                    <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
                      <Smartphone className="h-5 w-5 text-pine-DEFAULT" />
                      {selectedDiag.name}
                    </h2>
                    <p className="text-xs text-gray-500 mt-0.5">
                      Property: <strong className="text-gray-700">{selectedDiag.property}</strong> • Contact: {selectedDiag.mobile}
                    </p>
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => alert(`Forced sync ping transmitted to ${selectedDiag.uid}. Expect telemetry update in 30 seconds.`)}
                      className="px-3 py-1.5 bg-pine-DEFAULT text-white rounded-lg text-xs font-semibold hover:bg-pine-600 shadow-sm flex items-center gap-1.5"
                    >
                      <RefreshCw className="h-3.5 w-3.5" /> Force Sync Ping
                    </button>
                    <button
                      onClick={() => alert(`Re-issuing offline verification token for ${selectedDiag.uid}...`)}
                      className="px-3 py-1.5 bg-blue-50 text-blue-700 border border-blue-200 rounded-lg text-xs font-semibold hover:bg-blue-100 flex items-center gap-1.5"
                    >
                      Reset License Token
                    </button>
                    <button
                      onClick={() => setChatDrawerOpen(true)}
                      className="px-3 py-1.5 bg-gray-900 text-white rounded-lg text-xs font-semibold hover:bg-gray-800 flex items-center gap-1.5 shadow-sm"
                    >
                      <MessageSquare className="h-3.5 w-3.5" /> Customer Chat
                    </button>
                  </div>
                </div>

                {/* Hardware Spec Cards */}
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                  <div className="p-3 bg-gray-50 rounded-lg border border-gray-200">
                    <span className="text-[10px] uppercase font-bold text-gray-400">Hardware Model</span>
                    <p className="text-xs font-bold text-gray-800 mt-1">{selectedDiag.model}</p>
                  </div>
                  <div className="p-3 bg-gray-50 rounded-lg border border-gray-200">
                    <span className="text-[10px] uppercase font-bold text-gray-400">OS / App Build</span>
                    <p className="text-xs font-bold text-gray-800 mt-1">{selectedDiag.osVersion} / {selectedDiag.appVersion}</p>
                  </div>
                  <div className="p-3 bg-gray-50 rounded-lg border border-gray-200">
                    <span className="text-[10px] uppercase font-bold text-gray-400">Battery & Health</span>
                    <p className="text-xs font-bold text-gray-800 mt-1">{selectedDiag.battery}% Charged</p>
                  </div>
                  <div className="p-3 bg-gray-50 rounded-lg border border-gray-200">
                    <span className="text-[10px] uppercase font-bold text-gray-400">Last Telemetry</span>
                    <p className="text-xs font-bold text-gray-800 mt-1">{selectedDiag.lastSync}</p>
                  </div>
                </div>

                {/* Sync Attempts & exact Error Log Inspector */}
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <h3 className="text-xs font-bold uppercase tracking-wider text-gray-500 flex items-center gap-1.5">
                      <History className="h-4 w-4 text-gray-400" />
                      Recent Sync Attempts Log (Last 10 cycles)
                    </h3>
                    <button
                      onClick={() => alert('Diagnostic JSON bundle generated and downloaded.')}
                      className="text-xs text-pine-DEFAULT font-semibold hover:underline flex items-center gap-1"
                    >
                      <FileText className="h-3.5 w-3.5" /> Download Telemetry Bundle
                    </button>
                  </div>

                  <div className="space-y-2">
                    {selectedDiag.syncAttempts.map((attempt, idx) => (
                      <div key={idx} className={`p-3 rounded-xl border ${
                        attempt.status === 'SUCCESS' ? 'bg-green-50/50 border-green-200' : 'bg-red-50/80 border-red-200'
                      }`}>
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            {attempt.status === 'SUCCESS' ? (
                              <CheckCircle className="h-4 w-4 text-green-600" />
                            ) : (
                              <XCircle className="h-4 w-4 text-red-600" />
                            )}
                            <span className="text-xs font-bold text-gray-900">{attempt.status}</span>
                            <span className="text-xs text-gray-500 font-mono">({attempt.records})</span>
                          </div>
                          <span className="text-xs text-gray-400">{attempt.time}</span>
                        </div>
                        {attempt.error && (
                          <div className="mt-2 p-2.5 bg-white rounded-lg border border-red-200 text-xs text-red-700 font-mono flex items-start gap-2">
                            <AlertCircle className="h-4 w-4 text-red-500 flex-shrink-0 mt-0.5" />
                            <div className="break-all">{attempt.error}</div>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {/* Disabled Actions Bar (Role Enforcement Visual Proof) */}
              <div className="pt-4 border-t border-gray-200 flex items-center justify-between bg-gray-50/50 p-3 rounded-xl mt-4">
                <span className="text-xs font-semibold text-gray-500">
                  Restricted Administrative Controls (Disabled per Role Access Matrix):
                </span>
                <div className="flex items-center space-x-2">
                  <button disabled className="px-2.5 py-1 bg-gray-200 text-gray-400 rounded text-xs font-medium cursor-not-allowed">
                    Approve / Reject
                  </button>
                  <button disabled className="px-2.5 py-1 bg-gray-200 text-gray-400 rounded text-xs font-medium cursor-not-allowed">
                    Revoke License
                  </button>
                </div>
              </div>
            </div>
          ) : (
            <div className="flex-1 flex items-center justify-center text-gray-400 text-sm">
              Select a hardware unit from the left directory to inspect diagnostic telemetry.
            </div>
          )}
        </div>
      </div>

      {/* Simulated Customer Support Chat Drawer */}
      {chatDrawerOpen && (
        <div className="fixed inset-0 z-50 overflow-hidden bg-black/40 backdrop-blur-xs flex justify-end animate-fade-in">
          <div className="w-full max-w-md bg-white h-full shadow-2xl flex flex-col justify-between border-l border-gray-200">
            {/* Header */}
            <div className="p-5 bg-gray-900 text-white flex items-center justify-between">
              <div>
                <span className="text-[10px] uppercase tracking-wider font-bold text-pine-400">Direct Customer Diagnostics Channel</span>
                <h3 className="text-base font-bold flex items-center gap-2 mt-0.5">
                  <MessageSquare className="h-4 w-4 text-pine-400" />
                  Chat: {selectedDiag?.property}
                </h3>
              </div>
              <button 
                onClick={() => setChatDrawerOpen(false)}
                className="p-1.5 text-gray-400 hover:text-white rounded-full transition-colors"
              >
                ×
              </button>
            </div>

            {/* Messages Feed */}
            <div className="flex-1 overflow-y-auto p-4 space-y-3 bg-gray-50">
              {chatMessages.map((msg, idx) => (
                <div key={idx} className={`p-3 rounded-xl max-w-[85%] ${
                  msg.sender === 'Support Engineer' 
                    ? 'bg-pine-DEFAULT text-white ml-auto rounded-tr-none' 
                    : 'bg-white text-gray-800 border border-gray-200 mr-auto rounded-tl-none'
                }`}>
                  <div className="flex items-center justify-between text-[10px] opacity-75 mb-1 gap-4">
                    <span className="font-bold">{msg.sender}</span>
                    <span>{msg.time}</span>
                  </div>
                  <p className="text-xs leading-relaxed">{msg.text}</p>
                </div>
              ))}
            </div>

            {/* Input Form */}
            <form onSubmit={handleSendChat} className="p-4 bg-white border-t border-gray-200 flex items-center gap-2">
              <input
                type="text"
                placeholder="Type diagnostic instruction or query to property owner..."
                value={newMessage}
                onChange={(e) => setNewMessage(e.target.value)}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-pine-DEFAULT"
              />
              <button
                type="submit"
                className="p-2 bg-pine-DEFAULT text-white rounded-lg hover:bg-pine-600 transition-colors shadow-sm"
              >
                <Send className="h-4 w-4" />
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
