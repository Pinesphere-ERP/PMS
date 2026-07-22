import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { fetchAPI } from '../../services/api';
import { 
  ArrowLeft, BedDouble
} from 'lucide-react';
import DataTable from '../../components/ui/DataTable';

export default function PropertyRooms() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [rooms, setRooms] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [propertyName, setPropertyName] = useState('Property');

  useEffect(() => {
    const loadRooms = async () => {
      try {
        setLoading(true);
        // We inject tenantId to fetch the rooms for this specific property
        // The backend super_admin logic bypasses the explicit UserPropertyAccess check
        const response = await fetchAPI(`/inventory/rooms?tenantId=${id}`);
        
        // Sometimes backend returns a list, sometimes { data: [...] }
        const roomsData = Array.isArray(response) ? response : response.data || [];
        setRooms(roomsData);
        setError(null);
      } catch (err) {
        setError(err.message || 'Failed to fetch rooms');
      } finally {
        setLoading(false);
      }
    };
    
    // Attempt to fetch property details for the title
    const loadPropertyDetails = async () => {
      try {
        const prop = await fetchAPI(`/properties/${id}`);
        if (prop && prop.property_name) {
          setPropertyName(prop.property_name);
        } else if (prop && prop.name) {
          setPropertyName(prop.name);
        }
      } catch (e) {
        // Ignore errors, we can just say "Property"
      }
    };

    if (id) {
      loadRooms();
      loadPropertyDetails();
    }
  }, [id]);

  const columns = [
    {
      header: 'Room Number',
      accessor: 'room_number',
      sortable: true,
      render: (row) => <span className="font-bold text-gray-900">{row.room_number}</span>
    },
    {
      header: 'Category',
      accessor: 'category',
      sortable: true,
      render: (row) => <span className="text-sm text-gray-600">{row.category?.name || row.category_id || 'Standard'}</span>
    },
    {
      header: 'Status',
      accessor: 'status',
      sortable: true,
      render: (row) => (
        <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full 
          ${row.status === 'Available' ? 'bg-green-100 text-green-800' : 
            row.status === 'Occupied' ? 'bg-blue-100 text-blue-800' : 
            'bg-red-100 text-red-800'}`}>
          {row.status || 'Unknown'}
        </span>
      )
    },
    {
      header: 'Base Price',
      accessor: 'base_price',
      sortable: true,
      render: (row) => <span className="text-sm text-gray-500">₹{row.base_price || 0}</span>
    }
  ];

  return (
    <div className="space-y-6 max-w-7xl mx-auto p-6">
      <div className="flex items-center space-x-4 mb-4">
        <button 
          onClick={() => navigate(-1)} 
          className="p-2 bg-gray-100 rounded-full hover:bg-gray-200 transition"
        >
          <ArrowLeft className="h-5 w-5 text-gray-700" />
        </button>
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center">
            <BedDouble className="h-6 w-6 mr-2 text-pine" />
            Rooms Data - {propertyName}
          </h1>
          <p className="text-gray-500 mt-1">Cross-property data view based on role matrix.</p>
        </div>
      </div>

      <DataTable 
        columns={columns}
        data={rooms}
        loading={loading}
        error={error}
        emptyStateMessage="No rooms found for this property."
        searchPlaceholder="Search rooms..."
      />
    </div>
  );
}
