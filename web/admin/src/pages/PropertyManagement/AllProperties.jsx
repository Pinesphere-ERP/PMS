import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Filter, 
  MoreVertical, 
  Eye
} from 'lucide-react';
import { propertyService } from '../../services/propertyService';
import DataTable from '../../components/ui/DataTable';

export default function AllProperties() {
  const navigate = useNavigate();
  const [properties, setProperties] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchProperties = async () => {
      setLoading(true);
      try {
        const data = await propertyService.getAllProperties();
        setProperties(Array.isArray(data) ? data : (data.data || []));
        setError(null);
      } catch (err) {
        setError(err.message || 'Failed to fetch properties');
      } finally {
        setLoading(false);
      }
    };
    fetchProperties();
  }, []);

  const columns = [
    {
      header: 'Property ID',
      accessor: 'id',
      sortable: true,
      render: (row) => <span className="font-medium text-gray-900">{row.id?.substring(0, 8)}...</span>
    },
    {
      header: 'Property Name',
      accessor: 'name',
      sortable: true,
      render: (row) => (
        <div>
          <div className="text-sm font-medium text-gray-900">{row.name || row.property_name}</div>
          <div className="text-sm text-gray-500">{row.type || row.property_type} • {row.rooms || 0} Rooms</div>
        </div>
      )
    },
    {
      header: 'Owner',
      accessor: 'owner',
      sortable: true,
      render: (row) => (
        <div>
          <div className="text-sm text-gray-900">{row.owner}</div>
          <div className="text-sm text-gray-500">{row.mobile}</div>
        </div>
      )
    },
    {
      header: 'City',
      accessor: 'city',
      sortable: true,
      render: (row) => <span className="text-sm text-gray-500">{row.city || 'Unknown'}</span>
    },
    {
      header: 'Status',
      accessor: 'status',
      sortable: true,
      render: (row) => (
        <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${row.status === 'Active' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
          {row.status || 'Unknown'}
        </span>
      )
    },
    {
      header: '',
      accessor: 'actions',
      render: (row) => (
        <div className="flex justify-end space-x-2">
          <button 
            onClick={(e) => {
              e.stopPropagation();
              navigate(`/properties/${row.id}`);
            }}
            className="text-pine hover:text-pine-dark"
            title="View Details"
          >
            <Eye className="h-5 w-5" />
          </button>
          <button className="text-gray-400 hover:text-gray-900" onClick={(e) => e.stopPropagation()}>
            <MoreVertical className="h-5 w-5" />
          </button>
        </div>
      )
    }
  ];

  const actions = (
    <>
      <button className="bg-white border border-gray-300 text-gray-700 px-4 py-2 rounded-md hover:bg-gray-50 flex items-center shadow-sm">
        <Filter className="h-4 w-4 mr-2" /> Filters
      </button>
      <button className="bg-white border border-gray-300 text-gray-700 px-4 py-2 rounded-md hover:bg-gray-50 flex items-center shadow-sm">
        Export
      </button>
      <button className="bg-pine text-white px-4 py-2 rounded-md hover:bg-pine-dark transition shadow-sm font-medium">
        Add Property
      </button>
    </>
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">All Properties</h1>
          <p className="text-sm text-gray-500 mt-1">Manage and view all registered properties.</p>
        </div>
      </div>

      <DataTable 
        columns={columns}
        data={properties}
        loading={loading}
        error={error}
        emptyStateMessage="No properties found."
        searchPlaceholder="Search properties by name, owner, or city..."
        actions={actions}
        onRowClick={(row) => navigate(`/properties/${row.id}`)}
      />
    </div>
  );
}
