import { useState, useRef, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { 
  Search, Filter, Download, ExternalLink, DollarSign, ArrowUpRight, 
  Clock, AlertTriangle, FileText, CheckCircle2, TrendingUp, RefreshCw, 
  Send, X, CreditCard, ShieldCheck, PieChart as PieChartIcon, BarChart2,
  MoreVertical, Eye, Loader2, AlertCircle
} from 'lucide-react';
import { 
  LineChart, Line, BarChart, Bar, PieChart, Pie, Cell, 
  XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer 
} from 'recharts';
import { paymentService } from '../../services/paymentService';

const COLORS = ['#059669', '#3b82f6', '#8b5cf6', '#f59e0b', '#ef4444'];

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

  // API State
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  const [kpis, setKpis] = useState([]);
  const [dashboardData, setDashboardData] = useState({
    monthlyTrend: [],
    planRevenue: [],
    methodRevenue: [],
    outstanding: []
  });
  const [transactions, setTransactions] = useState([]);
  const [pendingDues, setPendingDues] = useState([]);
  const [invoices, setInvoices] = useState([]);

  useEffect(() => {
    const loadData = async () => {
      setLoading(true);
      setError(null);
      try {
        if (activeTab === 'overview') {
          const [kpisRes, dashRes] = await Promise.all([
            paymentService.getKPIs(),
            paymentService.getDashboardData()
          ]);
          setKpis(kpisRes?.data || []);
          setDashboardData(dashRes?.data || {
            monthlyTrend: [], planRevenue: [], methodRevenue: [], outstanding: []
          });
        } else if (activeTab === 'transactions') {
          const res = await paymentService.getTransactions();
          setTransactions(Array.isArray(res) ? res : res.data || []);
        } else if (activeTab === 'pending') {
          const res = await paymentService.getPendingDues();
          setPendingDues(Array.isArray(res) ? res : res.data || []);
        } else if (activeTab === 'invoices') {
          const res = await paymentService.getInvoices();
          setInvoices(Array.isArray(res) ? res : res.data || []);
        }
      } catch (err) {
        setError(err.message || `Failed to load ${activeTab} data`);
        console.error('API Error:', err);
      } finally {
        setLoading(false);
      }
    };
    loadData();
  }, [activeTab]);

  const handleOpenDrawer = (tx) => {
    setSelectedTx(tx);
    setTimeout(() => setIsDrawerOpen(true), 10);
  };

  const handleCloseDrawer = () => {
    setIsDrawerOpen(false);
    setTimeout(() => setSelectedTx(null), 300);
  };

  const handleAction = async (key, item) => {
    if (key === 'view') {
      handleOpenDrawer(item);
    } else if (key === 'remind') {
      try {
        await paymentService.sendReminder(item.id);
        alert('Reminder sent!');
      } catch (e) {
        alert('Failed to send reminder: ' + e.message);
      }
    } else if (key === 'link') {
      try {
        await paymentService.sendPaymentLink(item.id);
        alert('Payment link sent!');
      } catch (e) {
        alert('Failed to send link: ' + e.message);
      }
    } else if (key === 'mark_paid') {
      try {
        await paymentService.markAsPaid(item.id);
        // Optimistically remove from pending array
        setPendingDues(prev => prev.filter(due => due.id !== item.id));
      } catch (e) {
        alert('Failed to mark as paid: ' + e.message);
      }
    } else {
      console.log(`Action: ${key} on ${item.property || item.id}`);
    }
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

  const mapIcon = (iconName) => {
    const icons = { DollarSign, TrendingUp, Clock, AlertTriangle, FileText, ArrowUpRight, CheckCircle2 };
    return icons[iconName] || DollarSign;
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
        {kpis.length > 0 ? kpis.map((stat) => {
          const Icon = mapIcon(stat.icon);
          return (
            <div key={stat.name} className="saas-card p-4">
              <div className="flex justify-between items-start">
                <p className="text-xs font-medium text-gray-500 truncate">{stat.name}</p>
                <Icon className={`h-4 w-4 ${stat.color}`} />
              </div>
              <p className="mt-2 text-lg lg:text-xl font-bold text-gray-900 truncate">{stat.value}</p>
            </div>
          )
        }) : (
          <div className="col-span-full saas-card p-4 text-center text-sm text-gray-500">
            {loading ? 'Loading metrics...' : 'No metrics available'}
          </div>
        )}
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
      <div className="min-h-[400px] relative">
        {loading && (
          <div className="absolute inset-0 flex flex-col items-center justify-center bg-white/80 z-10 min-h-[300px]">
             <Loader2 className="h-8 w-8 text-pine animate-spin mb-2" />
             <p className="text-gray-500 text-sm">Loading data...</p>
          </div>
        )}

        {error && !loading && (
          <div className="absolute inset-0 flex flex-col items-center justify-center bg-white/80 z-10 min-h-[300px]">
             <AlertCircle className="h-8 w-8 text-red-500 mb-2" />
             <p className="text-gray-800 text-sm font-medium">Failed to load {activeTab}</p>
             <p className="text-gray-500 text-xs mt-1 max-w-sm text-center">{error}</p>
          </div>
        )}

        {/* OVERVIEW CHARTS */}
        {activeTab === 'overview' && !error && !loading && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8 mt-4">

            <div className="saas-card p-5">
              <h3 className="text-sm font-semibold text-gray-900 mb-4 flex items-center">
                <TrendingUp className="h-4 w-4 mr-2 text-gray-500"/> Monthly Revenue Trend
              </h3>
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={dashboardData.monthlyTrend}>
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
                  <BarChart data={dashboardData.planRevenue}>
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
                    <Pie data={dashboardData.methodRevenue} cx="50%" cy="50%" innerRadius={60} outerRadius={80} paddingAngle={5} dataKey="value">
                      {dashboardData.methodRevenue?.map((entry, index) => (
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
                  <BarChart data={dashboardData.outstanding} layout="vertical">
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
        {activeTab === 'transactions' && !error && !loading && (
          <div className="saas-card overflow-hidden">
            <div className="p-4 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
              <div className="relative max-w-sm w-full">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input type="text" placeholder="Search payments..." className="saas-input pl-9 w-full bg-white" />
              </div>
              <button className="saas-button-secondary"><Filter className="h-4 w-4 mr-2"/> Filters</button>
            </div>
            <div className="overflow-x-auto">
              {transactions.length === 0 ? (
                <div className="p-8 text-center text-sm text-gray-500">No transactions found.</div>
              ) : (
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
                    {transactions.map((tx) => (
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
              )}
            </div>
          </div>
        )}

        {/* PENDING DUES TAB */}
        {activeTab === 'pending' && !error && !loading && (
          <div className="saas-card overflow-hidden">
             <div className="overflow-x-auto">
              {pendingDues.length === 0 ? (
                <div className="p-8 text-center text-sm text-gray-500">No pending dues found.</div>
              ) : (
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
                    {pendingDues.map((due) => (
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
              )}
            </div>
          </div>
        )}

        {/* INVOICES TAB */}
        {activeTab === 'invoices' && !error && !loading && (
          <div className="saas-card overflow-hidden">
             <div className="overflow-x-auto">
              {invoices.length === 0 ? (
                <div className="p-8 text-center text-sm text-gray-500">No invoices found.</div>
              ) : (
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
                    {invoices.map((inv) => (
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
              )}
            </div>
          </div>
        )}
      </div>

      {/* Payment Details Slide-over Drawer */}
      {createPortal(
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
                      <p className="text-xs text-gray-500 mt-0.5">RCPT-{selectedTx.paymentId?.split('-')[1]} • {selectedTx.date}</p>
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
                        <p className="text-xs text-gray-500">System • {selectedTx.date?.split(' ')[0]} 08:00 AM</p>
                      </div>
                      <div className="relative">
                        <div className="absolute -left-[21px] top-1 h-3 w-3 bg-gray-200 rounded-full border-2 border-white"></div>
                        <p className="text-sm font-medium text-gray-900">Payment Link Sent</p>
                        <p className="text-xs text-gray-500">System • {selectedTx.date?.split(' ')[0]} 08:05 AM</p>
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
      </>,
        document.body
      )}
    </div>
  );
}
