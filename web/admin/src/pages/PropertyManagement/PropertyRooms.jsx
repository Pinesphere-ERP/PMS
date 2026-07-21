import { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { fetchAPI } from '../../services/api';
import { 
  ArrowLeft, BedDouble, Loader2, AlertCircle, Plus, Check, Tag, Sparkles, Upload, FileImage
} from 'lucide-react';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api/v1';

const DEFAULT_FALLBACK_IMAGE = 'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=500&q=80';

const AVAILABLE_AMENITIES = [
  'Free WiFi', 'Air Conditioning', 'TV', 'Attached Bath', 
  'Balcony', 'Room Service', 'Mini Bar', 'Power Backup', 
  'Geyser / Hot Water', 'Tea/Coffee Maker'
];

export default function PropertyRooms() {
  const { id } = useParams();
  const navigate = useNavigate();
  const fileInputRef = useRef(null);

  const [rooms, setRooms] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [propertyName, setPropertyName] = useState('Property');

  // Modal State
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [newRoomNumber, setNewRoomNumber] = useState('');
  const [newRoomType, setNewRoomType] = useState('Deluxe Suite');
  const [newRoomPrice, setNewRoomPrice] = useState('2500');
  const [newRoomDescription, setNewRoomDescription] = useState('');
  const [uploadedImageUrl, setUploadedImageUrl] = useState('');
  const [selectedAmenities, setSelectedAmenities] = useState(['Free WiFi', 'Air Conditioning']);
  const [isCreating, setIsCreating] = useState(false);
  const [isUploadingImage, setIsUploadingImage] = useState(false);

  useEffect(() => {
    const loadRooms = async () => {
      try {
        setLoading(true);
        const response = await fetchAPI('/inventory/rooms', { tenantId: id });
        const roomsData = Array.isArray(response) ? response : response.data || [];
        setRooms(roomsData);
        setError(null);
      } catch (err) {
        setError(err.message || 'Failed to fetch rooms');
      } finally {
        setLoading(false);
      }
    };

    const loadPropertyDetails = async () => {
      try {
        const prop = await fetchAPI(`/properties/${id}`);
        if (prop && (prop.property_name || prop.name)) {
          setPropertyName(prop.property_name || prop.name);
        }
      } catch (e) {}
    };

    if (id) {
      loadRooms();
      loadPropertyDetails();
    }
  }, [id]);

  const toggleAmenity = (amenity) => {
    if (selectedAmenities.includes(amenity)) {
      setSelectedAmenities(selectedAmenities.filter(a => a !== amenity));
    } else {
      setSelectedAmenities([...selectedAmenities, amenity]);
    }
  };

  const handleFileUpload = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    try {
      setIsUploadingImage(true);
      const formData = new FormData();
      formData.append('file', file);

      const token = localStorage.getItem('token');
      const headers = {};
      if (token) headers['Authorization'] = `Bearer ${token}`;

      const res = await fetch(`${API_BASE_URL}/properties/upload`, {
        method: 'POST',
        headers,
        body: formData
      });

      if (!res.ok) throw new Error('Upload failed');
      const data = await res.json();
      if (data && data.url) {
        setUploadedImageUrl(data.url);
      }
    } catch (err) {
      alert(err.message || 'Failed to upload photo file');
    } finally {
      setIsUploadingImage(false);
    }
  };

  const handleAddRoom = async (e) => {
    e.preventDefault();
    if (!newRoomNumber) return;
    try {
      setIsCreating(true);
      await fetchAPI('/properties/rooms', {
        method: 'POST',
        body: JSON.stringify({
          room_number: newRoomNumber,
          type: newRoomType,
          price: parseFloat(newRoomPrice) || 2500,
          resort_id: id,
          description: newRoomDescription,
          image_url: uploadedImageUrl || DEFAULT_FALLBACK_IMAGE,
          amenities: selectedAmenities
        })
      });
      setIsAddModalOpen(false);
      setNewRoomNumber('');
      setNewRoomDescription('');
      setUploadedImageUrl('');
      
      // Reload rooms list
      const response = await fetchAPI('/inventory/rooms', { tenantId: id });
      const roomsData = Array.isArray(response) ? response : response.data || [];
      setRooms(roomsData);
    } catch (err) {
      alert(err.message || 'Failed to create room');
    } finally {
      setIsCreating(false);
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto p-6">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center space-x-4">
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
            <p className="text-gray-500 mt-1">Manage and create property rooms with images, pricing, and amenities.</p>
          </div>
        </div>

        <button
          onClick={() => setIsAddModalOpen(true)}
          className="px-5 py-2.5 bg-pine text-white rounded-xl font-semibold shadow-lg hover:bg-pine-dark transition flex items-center space-x-2"
        >
          <Plus className="h-5 w-5" />
          <span>Add New Room</span>
        </button>
      </div>

      {/* Modern Modal for Adding New Room */}
      {isAddModalOpen && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4 overflow-y-auto">
          <div className="bg-white rounded-2xl max-w-2xl w-full p-6 shadow-2xl space-y-6 my-8 border border-gray-100">
            <div className="flex items-center justify-between pb-4 border-b border-gray-100">
              <div className="flex items-center space-x-2">
                <div className="p-2 bg-pine-50 rounded-lg text-pine">
                  <Sparkles className="h-5 w-5" />
                </div>
                <h3 className="text-xl font-bold text-gray-900">Add New Room to {propertyName}</h3>
              </div>
              <button 
                onClick={() => setIsAddModalOpen(false)}
                className="text-gray-400 hover:text-gray-600 text-lg font-bold"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleAddRoom} className="space-y-5">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold uppercase tracking-wider text-gray-700 mb-1">
                    Room Number / Name *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Room 101 or Villa 1"
                    value={newRoomNumber}
                    onChange={(e) => setNewRoomNumber(e.target.value)}
                    className="w-full px-3.5 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-pine text-sm"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold uppercase tracking-wider text-gray-700 mb-1">
                    Room Type / Category *
                  </label>
                  <select
                    value={newRoomType}
                    onChange={(e) => setNewRoomType(e.target.value)}
                    className="w-full px-3.5 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-pine text-sm bg-white"
                  >
                    <option value="Standard Room">Standard Room</option>
                    <option value="Deluxe Suite">Deluxe Suite</option>
                    <option value="Executive Suite">Executive Suite</option>
                    <option value="Presidential Suite">Presidential Suite</option>
                    <option value="Beach Villa">Beach Villa</option>
                    <option value="Family Suite">Family Suite</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold uppercase tracking-wider text-gray-700 mb-1">
                  Base Price per Night (₹) *
                </label>
                <input
                  type="number"
                  required
                  placeholder="2500"
                  value={newRoomPrice}
                  onChange={(e) => setNewRoomPrice(e.target.value)}
                  className="w-full px-3.5 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-pine text-sm font-semibold"
                />
              </div>

              {/* Exclusive Photo Upload Section */}
              <div>
                <label className="block text-xs font-semibold uppercase tracking-wider text-gray-700 mb-2">
                  Room Photo Upload *
                </label>
                <div className="p-6 bg-gray-50 border-2 border-dashed border-gray-300 rounded-2xl text-center space-y-3 hover:border-pine transition">
                  <input 
                    type="file" 
                    accept="image/*" 
                    ref={fileInputRef} 
                    onChange={handleFileUpload} 
                    className="hidden" 
                  />
                  <div className="flex flex-col items-center justify-center space-y-2">
                    <div className="p-3.5 bg-white rounded-full shadow-md text-pine border border-gray-100">
                      {isUploadingImage ? (
                        <Loader2 className="h-7 w-7 animate-spin text-pine" />
                      ) : (
                        <Upload className="h-7 w-7" />
                      )}
                    </div>
                    <h4 className="text-sm font-bold text-gray-900">
                      {isUploadingImage ? 'Uploading Room Photo...' : 'Click to Upload Room Photo'}
                    </h4>
                    <p className="text-xs text-gray-500">JPG, PNG, or WEBP image files</p>
                  </div>
                  <button
                    type="button"
                    disabled={isUploadingImage}
                    onClick={() => fileInputRef.current?.click()}
                    className="px-5 py-2.5 bg-pine text-white font-semibold rounded-xl text-xs shadow hover:bg-pine-dark transition flex items-center space-x-1.5 mx-auto"
                  >
                    <FileImage className="h-4 w-4 mr-1" />
                    <span>Select Photo from Device</span>
                  </button>
                </div>
              </div>

              {/* Uploaded Photo Preview */}
              {uploadedImageUrl && (
                <div className="flex items-center space-x-4 p-3.5 bg-green-50 border border-green-200 rounded-xl">
                  <img src={uploadedImageUrl} alt="Uploaded Room" className="h-16 w-24 rounded-lg object-cover border border-green-300 shadow-sm" />
                  <div className="flex-1">
                    <span className="text-xs font-bold text-green-800 flex items-center">
                      <Check className="h-4 w-4 mr-1 text-green-600" /> Photo Uploaded Successfully
                    </span>
                    <p className="text-[11px] text-green-700 truncate max-w-xs">{uploadedImageUrl}</p>
                  </div>
                  <button 
                    type="button" 
                    onClick={() => setUploadedImageUrl('')}
                    className="text-xs text-red-600 hover:text-red-800 underline font-medium"
                  >
                    Remove
                  </button>
                </div>
              )}

              {/* Amenities Selection */}
              <div>
                <label className="block text-xs font-semibold uppercase tracking-wider text-gray-700 mb-2 flex items-center">
                  <Tag className="h-4 w-4 mr-1 text-pine" /> Select Room Amenities
                </label>
                <div className="flex flex-wrap gap-2">
                  {AVAILABLE_AMENITIES.map((amenity) => {
                    const isSelected = selectedAmenities.includes(amenity);
                    return (
                      <button
                        type="button"
                        key={amenity}
                        onClick={() => toggleAmenity(amenity)}
                        className={`px-3 py-1.5 rounded-full text-xs font-medium transition flex items-center space-x-1 ${
                          isSelected 
                            ? 'bg-pine text-white shadow-sm' 
                            : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                        }`}
                      >
                        {isSelected && <Check className="h-3 w-3 mr-1" />}
                        <span>{amenity}</span>
                      </button>
                    );
                  })}
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold uppercase tracking-wider text-gray-700 mb-1">
                  Description (Optional)
                </label>
                <textarea
                  rows="2"
                  placeholder="Additional details about room view, balcony, bedding..."
                  value={newRoomDescription}
                  onChange={(e) => setNewRoomDescription(e.target.value)}
                  className="w-full px-3.5 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-pine text-sm"
                />
              </div>

              <div className="flex justify-end space-x-3 pt-3 border-t border-gray-100">
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="px-5 py-2.5 border border-gray-300 text-gray-700 rounded-xl hover:bg-gray-50 font-medium text-sm transition"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isCreating || isUploadingImage}
                  className="px-6 py-2.5 bg-pine text-white rounded-xl hover:bg-pine-dark font-bold text-sm shadow-md transition flex items-center space-x-2 disabled:opacity-50"
                >
                  {isCreating ? (
                    <>
                      <Loader2 className="h-4 w-4 animate-spin" />
                      <span>Creating Room...</span>
                    </>
                  ) : (
                    <span>Save & Add Room</span>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Rooms Table Display */}
      <div className="bg-white shadow-md rounded-2xl border border-gray-100 overflow-hidden relative min-h-[400px]">
        {loading && (
          <div className="absolute inset-0 flex flex-col items-center justify-center bg-white/80 z-10">
             <Loader2 className="h-8 w-8 text-pine animate-spin mb-2" />
             <p className="text-gray-500 text-sm">Loading property rooms...</p>
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
            <div className="p-12 text-center text-sm text-gray-500">No rooms found for this property. Click "+ Add New Room" above to create one.</div>
          ) : (
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3.5 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Room Photo & Number</th>
                  <th className="px-6 py-3.5 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Category / Type</th>
                  <th className="px-6 py-3.5 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Status</th>
                  <th className="px-6 py-3.5 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Base Price</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {rooms.map((room, idx) => (
                  <tr key={room.id || idx} className="hover:bg-gray-50/80 transition">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center space-x-3">
                        <img 
                          src={room.images?.[0] || room.image_url || DEFAULT_FALLBACK_IMAGE} 
                          alt={room.room_number} 
                          className="h-10 w-12 rounded-lg object-cover border border-gray-200 shadow-sm"
                        />
                        <span className="text-sm font-bold text-gray-900">{room.room_number}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-700 font-medium">
                      {room.type || room.category?.name || room.category_id || 'Standard Room'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-2.5 py-1 inline-flex text-xs leading-5 font-semibold rounded-full 
                        ${(room.status || '').toLowerCase() === 'available' || (room.status || '').toLowerCase() === 'vacant' ? 'bg-green-100 text-green-800 border border-green-200' : 
                          (room.status || '').toLowerCase() === 'occupied' ? 'bg-blue-100 text-blue-800 border border-blue-200' : 
                          'bg-amber-100 text-amber-800 border border-amber-200'}`}>
                        {room.status || 'Available'}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-bold text-pine">
                      ₹{room.price || room.base_price || 0} / night
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
