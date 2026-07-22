import { useState, useEffect } from 'react';
import { 
  ShieldAlert, 
  Search, 
  Filter, 
  RefreshCw,
  Database,
  User,
  Settings,
  MoreVertical
} from 'lucide-react';
import { fetchAPI } from '../../services/api';
import DataTable from '../../components/ui/DataTable';

const AuditLogs = () => {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchLogs();
  }, []);

  const fetchLogs = async () => {
    setLoading(true);
    try {
      const response = await fetchAPI('/audit');
      setLogs(Array.isArray(response) ? response : (response.items || []));
    } catch (error) {
      console.error('Failed to fetch audit logs:', error);
    }
    setLoading(false);
  };

  const getActionColor = (action) => {
    if (action.includes('DELETE') || action.includes('REVOKE')) return 'text-red-600 bg-red-50';
    if (action.includes('CREATE') || action.includes('REGISTER')) return 'text-green-600 bg-green-50';
    if (action.includes('LOGIN_FAILED')) return 'text-orange-600 bg-orange-50';
    return 'text-blue-600 bg-blue-50';
  };

  const columns = [
    {
      header: 'Timestamp',
      accessor: 'timestamp',
      sortable: true,
      render: (row) => <span className="text-sm text-gray-500">{new Date(row.timestamp).toLocaleString()}</span>
    },
    {
      header: 'Action',
      accessor: 'action_type',
      sortable: true,
      render: (row) => (
        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getActionColor(row.action_type || '')}`}>
          {row.action_type}
        </span>
      )
    },
    {
      header: 'Module',
      accessor: 'module_name',
      sortable: true,
      render: (row) => <span className="text-sm text-gray-900 font-medium">{row.module_name}</span>
    },
    {
      header: 'Entity',
      accessor: 'target_entity',
      sortable: true,
      render: (row) => <span className="text-sm text-gray-500">{row.target_entity}</span>
    },
    {
      header: 'User ID',
      accessor: 'user_id',
      sortable: true,
      render: (row) => <span className="text-sm text-gray-500">{row.user_id || 'System'}</span>
    }
  ];

  const actions = (
    <button 
      onClick={fetchLogs}
      className="p-2 text-gray-500 hover:text-gray-700 bg-white border border-gray-200 rounded-lg shadow-sm"
    >
      <RefreshCw className="w-5 h-5" />
    </button>
  );

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <ShieldAlert className="w-6 h-6 text-pine" />
            System Audit Logs
          </h1>
          <p className="text-gray-500 text-sm mt-1">Immutable record of all system activities</p>
        </div>
      </div>

      <DataTable 
        columns={columns}
        data={logs}
        loading={loading}
        emptyStateMessage="No audit logs found."
        searchPlaceholder="Search logs..."
        actions={actions}
      />
    </div>
  );
};

export default AuditLogs;
