import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { fetchAPI } from '../../services/api';
import { 
  ArrowLeft, BedDouble, Loader2, AlertCircle
} from 'lucide-react';

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
        const response = await fetchAPI('/inventory/rooms', {
          tenantId: id
        });
        
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

      <div className="bg-white shadow rounded-lg border border-gray-100 overflow-hidden relative min-h-[400px]">
        {loading && (
          <div className="absolute inset-0 flex flex-col items-center justify-center bg-white/80 z-10">
             <Loader2 className="h-8 w-8 text-primary-600 animate-spin mb-2" />
             <p className="text-gray-500 text-sm">Loading interconnected room data...</p>
          </div>
        )}

        {error && !loading && (
          <div className="absolute inset-0 flex flex-col items-center justify-center bg-white/80 z-10">
             <AlertCircle className="h-8 w-8 text-red-500 mb-2" />
             <p className="text-gray-800 text-sm font-medium">Failed to load rooms</p>
             <p className="text-gray-500 text-xs mt-1 max-w-sm text-center">{error}</p>
          </div>
        )}

        <div className="overflow-x-auto">
          {!loading && !error && rooms.length === 0 ? (
            <div className="p-8 text-center text-sm text-gray-500">No rooms found for this property.</div>
          ) : (
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Room Number</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Category</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Base Price</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {rooms.map((room, idx) => (
                  <tr key={room.id || idx} className="hover:bg-gray-50 transition">
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-bold text-gray-900">
                      {room.room_number}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                      {room.category?.name || room.category_id || 'Standard'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full 
                        ${room.status === 'Available' ? 'bg-green-100 text-green-800' : 
                          room.status === 'Occupied' ? 'bg-blue-100 text-blue-800' : 
                          'bg-red-100 text-red-800'}`}>
                        {room.status || 'Unknown'}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      ₹{room.base_price || 0}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
}
