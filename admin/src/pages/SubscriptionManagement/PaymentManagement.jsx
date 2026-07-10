import { useState, useRef, useEffect } from 'react';
import { 
  Search, Filter, Download, ExternalLink, DollarSign, ArrowUpRight, 
  Clock, AlertTriangle, FileText, CheckCircle2, TrendingUp, RefreshCw, 
  Send, X, CreditCard, ShieldCheck, PieChart as PieChartIcon, BarChart2,
  MoreVertical, Eye
} from 'lucide-react';
import { 
  LineChart, Line, BarChart, Bar, PieChart, Pie, Cell, 
  XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer 
} from 'recharts';

const mockKPIs = [
  { name: 'Total Revenue', value: '₹ 48,75,000', icon: DollarSign, color: 'text-green-600', bg: 'bg-green-50' },
  { name: 'Monthly Revenue', value: '₹ 5,20,000', icon: TrendingUp, color: 'text-pine', bg: 'bg-pine/10' },
  { name: 'Pending Collections', value: '₹ 1,45,000', icon: Clock, color: 'text-yellow-600', bg: 'bg-yellow-50' },
  { name: 'Failed Payments', value: '12', icon: AlertTriangle, color: 'text-red-500', bg: 'bg-red-50' },
  { name: 'Total Invoices', value: '285', icon: FileText, color: 'text-blue-500', bg: 'bg-blue-50' },
  { name: 'Avg Sub Value', value: '₹ 17,500', icon: ArrowUpRight, color: 'text-purple-600', bg: 'bg-purple-50' },
  { name: 'Collection Rate', value: '92%', icon: CheckCircle2, color: 'text-emerald-500', bg: 'bg-emerald-50' },
];

const mockMonthlyTrend = [
  { month: 'Jan', revenue: 380000 },
  { month: 'Feb', revenue: 420000 },
  { month: 'Mar', revenue: 390000 },
  { month: 'Apr', revenue: 450000 },
  { month: 'May', revenue: 510000 },
  { month: 'Jun', revenue: 520000 },
];

const mockPlanRevenue = [
  { plan: 'Basic', revenue: 1500000 },
  { plan: 'Professional', revenue: 2200000 },
  { plan: 'Enterprise', revenue: 1175000 },
];

const mockMethodRevenue = [
  { name: 'UPI', value: 45 },
  { name: 'Credit Card', value: 30 },
  { name: 'Net Banking', value: 15 },
  { name: 'Debit Card', value: 10 },
];
const COLORS = ['#059669', '#3b82f6', '#8b5cf6', '#f59e0b', '#ef4444'];

const mockOutstanding = [
  { name: 'Revenue Health', collected: 4875000, pending: 145000 },
];

const mockTransactions = [
  { id: '1', paymentId: 'PAY-88219', invoice: 'INV-2026-042', property: 'Grand Plaza Hotel', owner: 'John Doe', plan: 'Professional', billingCycle: 'Yearly', amount: '₹ 49,900', method: 'Credit Card', date: '2026-07-10 10:23 AM', status: 'Successful', collectedBy: 'System', bankRef: 'HDFC123456789' },
  { id: '2', paymentId: 'PAY-88220', invoice: 'INV-2026-043', property: 'Sea View Resort', owner: 'Jane Smith', plan: 'Enterprise', billingCycle: 'Yearly', amount: '₹ 99,900', method: 'UPI', date: '2026-07-09 14:15 PM', status: 'Processing', collectedBy: 'System', bankRef: 'UPI987654321' },
  { id: '3', paymentId: 'PAY-88221', invoice: 'INV-2026-044', property: 'City Lights Hostel', owner: 'Mike Johnson', plan: 'Basic', billingCycle: 'Monthly', amount: '₹ 1,990', method: 'Debit Card', date: '2026-07-09 09:00 AM', status: 'Failed', collectedBy: 'System', bankRef: 'SBI456123' },
];

const mockPendingDues = [
  { id: '4', property: 'Mountain Inn', plan: 'Professional', dueDate: '2026-07-05', amountDue: '₹ 49,900', daysOverdue: 5, reminderStatus: 'Sent Today' },
  { id: '5', property: 'Valley Lodge', plan: 'Basic', dueDate: '2026-07-01', amountDue: '₹ 19,900', daysOverdue: 9, reminderStatus: 'Sent 3 times' },
];

const mockInvoices = [
  { id: 'INV-2026-042', property: 'Grand Plaza Hotel', plan: 'Professional', date: '2026-07-01', dueDate: '2026-07-10', amount: '₹ 49,900', gst: '₹ 8,982', status: 'Paid' },
  { id: 'INV-2026-044', property: 'City Lights Hostel', plan: 'Basic', date: '2026-07-01', dueDate: '2026-07-05', amount: '₹ 1,990', gst: '₹ 358', status: 'Overdue' },
];

const ActionDropdown = ({ actions, onAction, item }) => {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="relative" ref={dropdownRef}>
      <button 
        onClick={(e) => { e.stopPropagation(); setIsOpen(!isOpen); }}
        className="text-gray-400 hover:text-gray-900 p-1 rounded-full hover:bg-gray-100 transition-colors"
      >
        <MoreVertical className="h-5 w-5" />
      </button>
      
      {isOpen && (
        <div className="absolute right-0 mt-2 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 z-20">
          <div className="py-1">
            {actions.map((act, idx) => (
              <button 
                key={idx} 
                onClick={(e) => { e.stopPropagation(); setIsOpen(false); onAction(act.key, item); }} 
                className="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
              >
                <act.icon className="mr-3 h-4 w-4 text-gray-400" /> {act.label}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default function PaymentManagement() {
  const [activeTab, setActiveTab] = useState('overview');
  const [selectedTx, setSelectedTx] = useState(null);
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);

  const handleOpenDrawer = (tx) => {
    setSelectedTx(tx);
    setTimeout(() => setIsDrawerOpen(true), 10);
  };

  const handleCloseDrawer = () => {
    setIsDrawerOpen(false);
    setTimeout(() => setSelectedTx(null), 300);
  };

  const handleAction = (key, item) => {
    if (key === 'view') handleOpenDrawer(item);
    else console.log(`Action: ${key} on ${item.property || item.id}`);
  };

  const getStatusBadge = (status) => {
    switch(status) {
      case 'Successful': case 'Paid': return 'status-active';
      case 'Processing': case 'Pending': return 'status-pending';
      case 'Failed': case 'Overdue': case 'Cancelled': return 'status-error';
      case 'Refunded': return 'bg-gray-100 text-gray-800 border-gray-200';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className="space-y-6 animate-slide-up pb-20 relative">
      <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center space-y-4 sm:space-y-0">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 tracking-tight">Payment Management</h1>
          <p className="text-sm text-gray-500 mt-1">Monitor, verify, and manage all subscription payments and revenue.</p>
        </div>
        <div className="flex flex-wrap gap-2">
          <button className="saas-button-secondary">
            <Download className="h-4 w-4 mr-2" /> Revenue Report
          </button>
          <button className="saas-button-secondary">
            <Download className="h-4 w-4 mr-2" /> GST Report
          </button>
          <button className="saas-button-primary">
            <FileText className="h-4 w-4 mr-2" /> Generate Invoice
          </button>
        </div>
      </div>

      {/* KPIs */}
      <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-4">
        {mockKPIs.map((stat) => (
          <div key={stat.name} className="saas-card p-4">
            <div className="flex justify-between items-start">
              <p className="text-xs font-medium text-gray-500 truncate">{stat.name}</p>
              <stat.icon className={`h-4 w-4 ${stat.color}`} />
            </div>
            <p className="mt-2 text-lg lg:text-xl font-bold text-gray-900 truncate">{stat.value}</p>
          </div>
        ))}
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200 mt-8">
        <nav className="-mb-px flex space-x-8 overflow-x-auto">
          {['overview', 'transactions', 'pending', 'invoices'].map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`whitespace-nowrap pb-4 px-1 border-b-2 font-medium text-sm capitalize ${
                activeTab === tab ? 'border-pine text-pine' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              {tab === 'pending' ? 'Pending Dues' : tab}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab Content */}
      <div className="min-h-[400px]">
        {/* OVERVIEW CHARTS */}
        {activeTab === 'overview' && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8 mt-4">

            <div className="saas-card p-5">
              <h3 className="text-sm font-semibold text-gray-900 mb-4 flex items-center">
                <TrendingUp className="h-4 w-4 mr-2 text-gray-500"/> Monthly Revenue Trend
              </h3>
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={mockMonthlyTrend}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e5e7eb" />
                    <XAxis dataKey="month" axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#6b7280'}} />
                    <YAxis axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#6b7280'}} tickFormatter={(val) => `₹${val/1000}k`} />
                    <Tooltip cursor={{stroke: '#e5e7eb', strokeWidth: 1}} contentStyle={{borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}} />
                    <Line type="monotone" dataKey="revenue" stroke="#059669" strokeWidth={3} dot={{r: 4, strokeWidth: 2}} activeDot={{r: 6}} />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            </div>

            <div className="saas-card p-5">
              <h3 className="text-sm font-semibold text-gray-900 mb-4 flex items-center">
                <BarChart2 className="h-4 w-4 mr-2 text-gray-500"/> Revenue by Plan
              </h3>
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={mockPlanRevenue}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e5e7eb" />
                    <XAxis dataKey="plan" axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#6b7280'}} />
                    <YAxis axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#6b7280'}} tickFormatter={(val) => `₹${val/100000}L`} />
                    <Tooltip cursor={{fill: '#f9fafb'}} contentStyle={{borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}} />
                    <Bar dataKey="revenue" fill="#3b82f6" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>

            <div className="saas-card p-5">
              <h3 className="text-sm font-semibold text-gray-900 mb-4 flex items-center">
                <PieChartIcon className="h-4 w-4 mr-2 text-gray-500"/> Payment Methods
              </h3>
              <div className="h-64 flex justify-center items-center">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie data={mockMethodRevenue} cx="50%" cy="50%" innerRadius={60} outerRadius={80} paddingAngle={5} dataKey="value">
                      {mockMethodRevenue.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip contentStyle={{borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}} />
                    <Legend iconType="circle" wrapperStyle={{fontSize: '12px'}} />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </div>

            <div className="saas-card p-5">
              <h3 className="text-sm font-semibold text-gray-900 mb-4 flex items-center">
                <DollarSign className="h-4 w-4 mr-2 text-gray-500"/> Collected vs Outstanding
              </h3>
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={mockOutstanding} layout="vertical">
                    <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="#e5e7eb" />
                    <XAxis type="number" axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#6b7280'}} tickFormatter={(val) => `₹${val/100000}L`} />
                    <YAxis dataKey="name" type="category" axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#6b7280'}} />
                    <Tooltip cursor={{fill: '#f9fafb'}} contentStyle={{borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}} />
                    <Legend iconType="circle" wrapperStyle={{fontSize: '12px'}} />
                    <Bar dataKey="collected" stackId="a" fill="#059669" radius={[0, 0, 0, 0]} name="Collected" />
                    <Bar dataKey="pending" stackId="a" fill="#ef4444" radius={[0, 4, 4, 0]} name="Pending" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          </div>
        )}

        {/* TRANSACTIONS TAB */}
        {activeTab === 'transactions' && (
          <div className="saas-card overflow-hidden">
            <div className="p-4 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
              <div className="relative max-w-sm w-full">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input type="text" placeholder="Search payments..." className="saas-input pl-9 w-full bg-white" />
              </div>
              <button className="saas-button-secondary"><Filter className="h-4 w-4 mr-2"/> Filters</button>
            </div>
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Payment Info</th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Property</th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Amount & Method</th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Status</th>
                    <th className="relative px-6 py-3"><span className="sr-only">Actions</span></th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {mockTransactions.map((tx) => (
                    <tr key={tx.id} className="hover:bg-gray-50/50 cursor-pointer" onClick={() => handleOpenDrawer(tx)}>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900">{tx.paymentId}</div>
                        <div className="text-xs text-gray-500 mt-0.5">{tx.date}</div>
                        <div className="text-xs text-gray-400 mt-0.5 font-mono">Inv: {tx.invoice}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900">{tx.property}</div>
                        <div className="text-xs text-gray-500 mt-0.5">{tx.owner}</div>
                        <span className="inline-flex items-center px-2 py-0.5 mt-1 rounded text-[10px] font-medium bg-gray-100 text-gray-800">{tx.plan}</span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-semibold text-gray-900">{tx.amount}</div>
                        <div className="text-xs text-gray-500 mt-1 flex items-center">
                          <CreditCard className="h-3 w-3 mr-1"/> {tx.method}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`status-badge ${getStatusBadge(tx.status)}`}>{tx.status}</span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <ActionDropdown 
                          item={tx} 
                          onAction={handleAction}
                          actions={[
                            { key: 'view', label: 'View Details', icon: Eye },
                            { key: 'receipt', label: 'Download Receipt', icon: Download },
                            { key: 'invoice', label: 'View Invoice', icon: FileText }
                          ]} 
                        />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* PENDING DUES TAB */}
        {activeTab === 'pending' && (
          <div className="saas-card overflow-hidden">
             <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Property</th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Due Date</th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Amount Due</th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Reminder Status</th>
                    <th className="relative px-6 py-3"><span className="sr-only">Actions</span></th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {mockPendingDues.map((due) => (
                    <tr key={due.id} className="hover:bg-gray-50/50">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900">{due.property}</div>
                        <div className="text-xs text-gray-500">{due.plan}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-red-600 font-medium">{due.daysOverdue} Days Overdue</div>
                        <div className="text-xs text-gray-500">Due: {due.dueDate}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-semibold text-gray-900">
                        {due.amountDue}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className="text-xs text-gray-600 bg-gray-100 px-2 py-1 rounded">{due.reminderStatus}</span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <ActionDropdown 
                          item={due} 
                          onAction={handleAction}
                          actions={[
                            { key: 'remind', label: 'Send Reminder', icon: Send },
                            { key: 'link', label: 'Send Payment Link', icon: ExternalLink },
                            { key: 'mark_paid', label: 'Mark as Paid', icon: CheckCircle2 }
                          ]} 
                        />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* INVOICES TAB */}
        {activeTab === 'invoices' && (
          <div className="saas-card overflow-hidden">
             <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Invoice Number</th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Property</th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Dates</th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Amount</th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Status</th>
                    <th className="relative px-6 py-3"><span className="sr-only">Actions</span></th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {mockInvoices.map((inv) => (
                    <tr key={inv.id} className="hover:bg-gray-50/50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-mono font-medium text-pine">
                        {inv.id}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900">{inv.property}</div>
                        <div className="text-xs text-gray-500">{inv.plan}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-xs text-gray-900">Issued: {inv.date}</div>
                        <div className="text-xs text-gray-500">Due: {inv.dueDate}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-semibold text-gray-900">{inv.amount}</div>
                        <div className="text-xs text-gray-500">Inc. GST: {inv.gst}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`status-badge ${getStatusBadge(inv.status)}`}>{inv.status}</span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <ActionDropdown 
                          item={inv} 
                          onAction={handleAction}
                          actions={[
                            { key: 'view', label: 'View Invoice', icon: Eye },
                            { key: 'download', label: 'Download PDF', icon: Download },
                            { key: 'email', label: 'Email Invoice', icon: Send }
                          ]} 
                        />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      {/* Payment Details Slide-over Drawer */}
      <>
        <div 
          className={`saas-drawer-overlay ${isDrawerOpen ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'}`} 
          onClick={handleCloseDrawer} 
        />
        <div className={`saas-drawer flex flex-col w-[500px] max-w-full ${isDrawerOpen ? 'translate-x-0' : 'translate-x-full'}`}>
          {selectedTx && (
            <>
              <div className="px-6 py-5 border-b border-gray-100 flex items-center justify-between bg-gray-50/50 shrink-0 z-10">
                <div>
                  <h2 className="text-lg font-semibold text-gray-900 flex items-center">
                    {selectedTx.paymentId}
                    <span className={`ml-3 status-badge ${getStatusBadge(selectedTx.status)}`}>{selectedTx.status}</span>
                  </h2>
                  <p className="text-sm text-gray-500 mt-1">{selectedTx.date}</p>
                </div>
                <button onClick={handleCloseDrawer} className="p-2 text-gray-400 hover:text-gray-900 hover:bg-gray-100 rounded-full transition-colors">
                  <X className="h-5 w-5" />
                </button>
              </div>

              <div className="p-6 space-y-8 flex-1 overflow-y-auto">
                {/* 1. Payment Information */}
                <section>
                  <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-4">Payment Information</h3>
                  <div className="bg-white rounded-xl p-4 border border-gray-100 shadow-sm space-y-3 text-sm">
                    <div className="flex justify-between">
                      <span className="text-gray-500">Property</span>
                      <span className="font-medium text-gray-900">{selectedTx.property}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">Owner</span>
                      <span className="font-medium text-gray-900">{selectedTx.owner}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">Subscription Plan</span>
                      <span className="font-medium text-gray-900">{selectedTx.plan} ({selectedTx.billingCycle})</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">Invoice Number</span>
                      <span className="font-mono text-pine font-medium">{selectedTx.invoice}</span>
                    </div>
                    <div className="pt-3 border-t border-gray-100 flex justify-between items-center mt-1">
                      <span className="text-gray-900 font-semibold">Total Amount</span>
                      <span className="text-lg font-bold text-gray-900">{selectedTx.amount}</span>
                    </div>
                  </div>
                </section>

                {/* 2. Transaction Details */}
                <section>
                  <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-4">Transaction Details</h3>
                  <div className="space-y-3 text-sm">
                    <div className="flex items-center">
                      <span className="text-gray-500 w-1/3">Method</span>
                      <span className="font-medium text-gray-900 flex items-center"><CreditCard className="h-4 w-4 mr-2 text-gray-400"/> {selectedTx.method}</span>
                    </div>
                    <div className="flex items-center">
                      <span className="text-gray-500 w-1/3">Bank Reference</span>
                      <span className="font-medium text-gray-900 font-mono text-xs bg-gray-100 px-2 py-0.5 rounded">{selectedTx.bankRef}</span>
                    </div>
                    <div className="flex items-center">
                      <span className="text-gray-500 w-1/3">Gateway Status</span>
                      <span className="font-medium text-green-600 flex items-center"><ShieldCheck className="h-4 w-4 mr-1"/> Verified</span>
                    </div>
                  </div>
                </section>

                <hr className="border-gray-100" />

                {/* 3. Receipt */}
                <section>
                  <div className="flex justify-between items-center bg-gray-50 p-4 rounded-xl border border-gray-100">
                    <div>
                      <h4 className="text-sm font-semibold text-gray-900">Receipt Details</h4>
                      <p className="text-xs text-gray-500 mt-0.5">RCPT-{selectedTx.paymentId.split('-')[1]} • {selectedTx.date}</p>
                    </div>
                    <button className="text-pine hover:text-pine-dark bg-pine/10 p-2 rounded-lg transition-colors">
                      <Download className="h-5 w-5" />
                    </button>
                  </div>
                </section>

                {/* 4. Audit Trail */}
                <section>
                  <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-4 flex items-center">
                    <Clock className="h-4 w-4 mr-2" /> Audit Trail
                  </h3>
                  <div className="space-y-4 pl-2">
                    <div className="relative border-l-2 border-gray-200 pl-4 space-y-6">
                      <div className="relative">
                        <div className="absolute -left-[21px] top-1 h-3 w-3 bg-gray-200 rounded-full border-2 border-white"></div>
                        <p className="text-sm font-medium text-gray-900">Invoice Generated</p>
                        <p className="text-xs text-gray-500">System • {selectedTx.date.split(' ')[0]} 08:00 AM</p>
                      </div>
                      <div className="relative">
                        <div className="absolute -left-[21px] top-1 h-3 w-3 bg-gray-200 rounded-full border-2 border-white"></div>
                        <p className="text-sm font-medium text-gray-900">Payment Link Sent</p>
                        <p className="text-xs text-gray-500">System • {selectedTx.date.split(' ')[0]} 08:05 AM</p>
                      </div>
                      <div className="relative">
                        <div className="absolute -left-[21px] top-1 h-3 w-3 bg-pine rounded-full border-2 border-white"></div>
                        <p className="text-sm font-medium text-gray-900">Payment Completed</p>
                        <p className="text-xs text-gray-500">Owner • {selectedTx.date}</p>
                      </div>
                    </div>
                  </div>
                </section>

              </div>
              
              <div className="p-6 bg-white border-t border-gray-200 flex space-x-3 shrink-0 shadow-[0_-4px_6px_-1px_rgba(0,0,0,0.05)]">
                <button className="saas-button-secondary flex-1">
                  Download Invoice
                </button>
                <button className="saas-button-primary flex-1">
                  Send Receipt
                </button>
              </div>
            </>
          )}
        </div>
      </>
    </div>
  );
}
