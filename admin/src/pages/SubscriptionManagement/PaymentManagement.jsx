import { 
  Search, 
  Filter, 
  Download, 
  ExternalLink,
  DollarSign,
  ArrowUpRight,
  Clock
} from 'lucide-react';

const kpiStats = [
  { name: 'Revenue Today', value: '$1,250.00', icon: DollarSign, color: 'text-green-600', bg: 'bg-green-50' },
  { name: 'Revenue This Month', value: '$42,500.00', icon: ArrowUpRight, color: 'text-pine-DEFAULT', bg: 'bg-pine-50' },
  { name: 'Pending Payments', value: '3', icon: Clock, color: 'text-yellow-600', bg: 'bg-yellow-50' },
];

const mockPayments = [
  { id: 'INV-2025-001', property: 'Grand Plaza Hotel', plan: 'Pro Plan', amount: '$499.00', method: 'Credit Card (••• 4242)', date: '2025-01-01', status: 'Paid' },
  { id: 'INV-2025-002', property: 'Sea View Resort', plan: 'Enterprise', amount: '$999.00', method: 'Bank Transfer', date: '2025-01-02', status: 'Paid' },
  { id: 'INV-2025-003', property: 'City Lights Hostel', plan: 'Basic', amount: '$199.00', method: 'Credit Card (••• 1234)', date: '2025-01-03', status: 'Failed' },
  { id: 'INV-2025-004', property: 'Mountain Inn', plan: 'Pro Plan', amount: '$499.00', method: '-', date: '2025-01-04', status: 'Pending' },
];

export default function PaymentManagement() {
  return (
    <div className="space-y-6 animate-slide-up">
      <div>
        <h1 className="text-2xl font-semibold text-gray-900 tracking-tight">Payment Management</h1>
        <p className="text-sm text-gray-500 mt-1">Track subscription payments, invoices, and revenue.</p>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        {kpiStats.map((stat) => (
          <div key={stat.name} className="saas-card p-5 flex items-start space-x-4">
            <div className={`p-2.5 rounded-lg ${stat.bg}`}>
              <stat.icon className={`h-5 w-5 ${stat.color}`} />
            </div>
            <div>
              <p className="text-sm font-medium text-gray-500">{stat.name}</p>
              <h3 className="text-2xl font-bold text-gray-900 mt-1">{stat.value}</h3>
            </div>
          </div>
        ))}
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
            placeholder="Search invoice or property..."
          />
        </div>
        <div className="flex space-x-3">
          <button className="saas-button-secondary">
            <Filter className="h-4 w-4 mr-2 text-gray-500" />
            Date Range
          </button>
          <button className="saas-button-secondary">
            <Filter className="h-4 w-4 mr-2 text-gray-500" />
            Status
          </button>
        </div>
      </div>

      {/* Payment Table */}
      <div className="saas-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th scope="col" className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Invoice</th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Property & Plan</th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Amount</th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Method</th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Date</th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
                <th scope="col" className="relative px-6 py-3"><span className="sr-only">Actions</span></th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {mockPayments.map((payment) => (
                <tr key={payment.id} className="hover:bg-gray-50/50 transition-colors">
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-pine">
                    {payment.id}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{payment.property}</div>
                    <div className="text-sm text-gray-500">{payment.plan}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    {payment.amount}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {payment.method}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {payment.date}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`status-badge ${
                      payment.status === 'Paid' ? 'status-active' :
                      payment.status === 'Failed' ? 'status-error' : 'status-pending'
                    }`}>
                      {payment.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium space-x-2">
                    <button className="text-gray-400 hover:text-pine p-1 rounded transition-colors" title="Download Invoice">
                      <Download className="h-4 w-4" />
                    </button>
                    <button className="text-gray-400 hover:text-pine p-1 rounded transition-colors" title="View Receipt">
                      <ExternalLink className="h-4 w-4" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
