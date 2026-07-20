import { useState, useEffect } from 'react';
import { fetchAPI } from '../../services/api';
import { useNavigate } from 'react-router-dom';
import { propertyService } from '../../services/propertyService';
import { 
  ChevronRight, ChevronLeft, Check, UploadCloud, Building2, 
  FileText, MapPin, Camera, Banknote, ShieldCheck, 
  Settings, CheckCircle2, Plus, Trash2, Shield, Clock
} from 'lucide-react';

const steps = [
  { id: 1, name: 'Owner', icon: Building2 },
  { id: 2, name: 'Business', icon: FileText },
  { id: 3, name: 'Property', icon: Building2 },
  { id: 4, name: 'Location', icon: MapPin },
  { id: 5, name: 'Ownership', icon: ShieldCheck },
  { id: 6, name: 'Rooms', icon: Settings },
  { id: 7, name: 'Room Amenities', icon: CheckCircle2 },
  { id: 8, name: 'Hotel Amenities', icon: CheckCircle2 },
  { id: 9, name: 'Photos', icon: Camera },
  { id: 10, name: 'Policies', icon: FileText },
  { id: 11, name: 'Pricing', icon: Banknote },
  { id: 12, name: 'Inventory', icon: Settings },
  { id: 13, name: 'Bank Details', icon: Banknote },
  { id: 14, name: 'Legal Docs', icon: FileText },
  { id: 15, name: 'Verification', icon: Shield },
];

export default function AddPropertyWizard() {
  const navigate = useNavigate();
  const [currentStep, setCurrentStep] = useState(1);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Form State
  const [formData, setFormData] = useState({
    owner_id: '',           // Preferred: link to existing Owner entity
    owner_user_id: '', owner_name: '', owner_designation: '', owner_mobile: '', owner_email: '', owner_pan: '',
    business_type: '', business_name: '', business_reg_number: '', business_gst: '', business_pan: '',
    property_name: '', property_type: '', star_category: '', year_established: '', total_floors: '', total_rooms: '', description: '',
    address: '', city: '', state: '', country: '', pincode: ''
  });

  const [availableOwners, setAvailableOwners] = useState([]);
  const [availableUsers, setAvailableUsers] = useState([]);

  useEffect(() => {
    const loadData = async () => {
      try {
        // Load existing owners for selection (primary method)
        const ownersRes = await fetchAPI('/owners');
        setAvailableOwners(Array.isArray(ownersRes) ? ownersRes : []);
        // Also load OWNER-role users for backwards compatibility
        const usersRes = await fetchAPI('/users?unassigned_only=true&role_code=OWNER');
        setAvailableUsers(Array.isArray(usersRes) ? usersRes : usersRes?.data || []);
      } catch (err) {
        console.error('Failed to load owners/users', err);
      }
    };
    loadData();
  }, []);

  const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

  const handleOwnerEntitySelect = (e) => {
    const ownerId = e.target.value;
    if (ownerId) {
      const selected = availableOwners.find(o => String(o.owner_id) === String(ownerId));
      if (selected) {
        setFormData(prev => ({
          ...prev,
          owner_id: ownerId,
          owner_user_id: '',
          owner_name: selected.full_name || '',
          owner_mobile: selected.mobile_number || '',
          owner_email: selected.email || '',
          owner_pan: selected.pan_number || '',
          owner_designation: selected.designation || '',
        }));
      }
    } else {
      setFormData(prev => ({ ...prev, owner_id: '', owner_name: '', owner_mobile: '', owner_email: '', owner_pan: '', owner_designation: '' }));
    }
  };

  const handleUserSelect = (e) => {
    const userId = e.target.value;
    if (userId) {
      const selectedUser = availableUsers.find(u => String(u.id) === String(userId));
      if (selectedUser) {
        setFormData(prev => ({
          ...prev,
          owner_user_id: userId,
          owner_name: selectedUser.name || '',
          owner_mobile: selectedUser.mobile_number || selectedUser.phone || '',
          owner_email: selectedUser.email || '',
          owner_pan: selectedUser.pan_number || selectedUser.pan || ''
        }));
      }
    } else {
      setFormData(prev => ({
        ...prev,
        owner_user_id: '',
        owner_name: '',
        owner_mobile: '',
        owner_email: '',
        owner_pan: ''
      }));
    }
  };

  // Dynamic Room Categories State
  const [rooms, setRooms] = useState([
    { id: '1', name: 'Deluxe Room', category: 'Deluxe', totalRooms: 10, occupancy: 2, bedType: 'Double', size: '200 sq ft', smoking: false, bathroom: true, balcony: false, view: 'City', ac: true, description: '' }
  ]);

  const addRoom = () => {
    setRooms([...rooms, { id: Date.now().toString(), name: '', category: 'Standard', totalRooms: 0, occupancy: 2, bedType: 'Single', size: '', smoking: false, bathroom: true, balcony: false, view: '', ac: true, description: '' }]);
  };
  const removeRoom = (id) => {
    setRooms(rooms.filter(r => r.id !== id));
  };
  const updateRoom = (id, field, value) => {
    setRooms(rooms.map(r => r.id === id ? { ...r, [field]: value } : r));
  };

  const nextStep = () => setCurrentStep(prev => Math.min(prev + 1, 15));
  const prevStep = () => setCurrentStep(prev => Math.max(prev - 1, 1));

  const handleSubmit = async () => {
    if (!formData.owner_user_id && !formData.owner_name) {
      alert("Please select a User or provide the Owner's Full Name (Step 1).");
      return;
    }
    if (!formData.owner_mobile) {
      alert("Please provide the Owner's Mobile Number (Step 1).");
      return;
    }
    if (!formData.owner_email) {
      alert("Please provide the Owner's Email (Step 1).");
      return;
    }
    if (!formData.business_name) {
      alert("Please provide the Business Name (Step 2).");
      return;
    }
    if (!formData.property_name) {
      alert("Please provide the Property Name (Step 3).");
      return;
    }

    setIsSubmitting(true);
    try {
      // Clean empty fields and parse numbers
      const payload = {};
      Object.keys(formData).forEach(key => {
        if (formData[key] !== '') {
          payload[key] = formData[key];
        }
      });
      
      if (payload.star_category) payload.star_category = parseInt(payload.star_category, 10);
      if (payload.year_established) payload.year_established = parseInt(payload.year_established, 10);
      if (payload.total_floors) payload.total_floors = parseInt(payload.total_floors, 10);
      if (payload.total_rooms) payload.total_rooms = parseInt(payload.total_rooms, 10);
      
      await propertyService.createProperty(payload);
      alert('Property created successfully!');
      navigate('/properties');
    } catch (err) {
      alert('Failed to create property: ' + err.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="max-w-5xl mx-auto space-y-6 animate-fade-in relative pb-24">
      <div>
        <h1 className="text-2xl font-semibold text-gray-900 tracking-tight">Onboard New Property</h1>
        <p className="text-sm text-gray-500 mt-1">Complete the multi-step process to add a new property.</p>
      </div>

      {/* Progress Indicator */}
      <div className="saas-card p-4 overflow-hidden">
        <div className="flex items-center justify-between relative">
          <div className="absolute left-0 top-1/2 transform -translate-y-1/2 w-full h-0.5 bg-gray-100 -z-10"></div>
          {steps.map((step) => {
            const isCompleted = currentStep > step.id;
            const isCurrent = currentStep === step.id;
            return (
              <div key={step.id} className={`flex flex-col items-center ${Math.abs(currentStep - step.id) > 2 && currentStep !== 15 ? 'hidden lg:flex' : 'flex'}`}>
                <div className={`w-7 h-7 rounded-full flex items-center justify-center text-[10px] font-semibold transition-colors duration-300 ${
                  isCompleted ? 'bg-pine text-white' :
                  isCurrent ? 'bg-pine-100 text-pine ring-2 ring-pine ring-offset-2' :
                  'bg-white border-2 border-gray-200 text-gray-400'
                }`}>
                  {isCompleted ? <Check className="w-3 h-3" /> : step.id}
                </div>
                <span className={`text-[9px] mt-1.5 uppercase tracking-wider font-medium ${isCurrent ? 'text-pine' : 'text-gray-400'}`}>
                  {step.name}
                </span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Form Area */}
      <div className="saas-card p-6 sm:p-8 min-h-[500px]">
        {/* Step 1: Owner Registration */}
        {currentStep === 1 && (
          <div className="space-y-6 animate-slide-in-right">
            <div><h2 className="text-lg font-semibold text-gray-900">Owner Registration</h2><p className="text-sm text-gray-500">Primary contact details for the owner.</p></div>

            {/* ── Preferred: Select from existing Owner entities ── */}
            <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 mb-5">
              <p className="text-xs font-semibold text-amber-700 uppercase tracking-wider mb-2">✦ Recommended: Link to Existing Owner</p>
              <p className="text-xs text-amber-600 mb-3">
                Select an owner you already created via Owner Management. This is the preferred multi-tenant flow.
              </p>
              <select
                value={formData.owner_id}
                onChange={handleOwnerEntitySelect}
                className="saas-input bg-white w-full"
              >
                <option value="">-- Select Existing Owner --</option>
                {availableOwners.map(owner => (
                  <option key={owner.owner_id} value={owner.owner_id}>
                    {owner.full_name} · {owner.mobile_number} ({owner.property_count} {owner.property_count === 1 ? 'property' : 'properties'})
                  </option>
                ))}
              </select>
              {availableOwners.length === 0 && (
                <p className="text-xs text-amber-600 mt-2">
                  No owners found. <a href="/owners" className="underline font-semibold">Create an Owner first</a> or fill details below.
                </p>
              )}
            </div>

            <div className="relative flex items-center gap-3 mb-5">
              <div className="flex-1 h-px bg-gray-200" />
              <span className="text-xs text-gray-400 font-medium">OR fill manually</span>
              <div className="flex-1 h-px bg-gray-200" />
            </div>

            <div className={`grid grid-cols-1 sm:grid-cols-2 gap-4 ${formData.owner_id ? 'opacity-40 pointer-events-none' : ''}`}>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Full Name</label><input type="text" name="owner_name" value={formData.owner_name} onChange={handleChange} className="saas-input" placeholder="John Doe" /></div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Designation (Optional)</label>
                <select name="owner_designation" value={formData.owner_designation} onChange={handleChange} className="saas-input bg-white"><option value="">None</option><option value="Owner">Owner</option><option value="Manager">Manager</option><option value="Authorized Representative">Authorized Representative</option></select>
              </div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Mobile Number (Optional)</label><div className="flex space-x-2"><input type="tel" name="owner_mobile" value={formData.owner_mobile} onChange={handleChange} className="saas-input flex-1" placeholder="+91" /><button className="saas-button-secondary">Send OTP</button></div></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Email Address (Optional)</label><div className="flex space-x-2"><input type="email" name="owner_email" value={formData.owner_email} onChange={handleChange} className="saas-input flex-1" placeholder="john@example.com" /><button className="saas-button-secondary">Send OTP</button></div></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">PAN Number (Optional)</label><input type="text" name="owner_pan" value={formData.owner_pan} onChange={handleChange} className="saas-input uppercase" placeholder="ABCDE1234F" /></div>
            </div>
            <div className="border-t border-gray-100 pt-4 mt-4">
              <h3 className="text-sm font-medium text-gray-700 mb-3">Optional Identity Verification</h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="border-2 border-dashed border-gray-200 rounded-lg p-4 flex flex-col items-center justify-center text-center hover:border-pine-light bg-gray-50">
                  <UploadCloud className="h-6 w-6 text-gray-400 mb-2" />
                  <p className="text-xs font-medium text-gray-900">Aadhaar/Gov ID</p>
                  <button className="mt-2 text-xs font-semibold text-pine bg-white border border-pine-200 px-3 py-1 rounded-full shadow-sm hover:bg-pine-50">Browse File</button>
                </div>
                <div className="border-2 border-dashed border-gray-200 rounded-lg p-4 flex flex-col items-center justify-center text-center hover:border-pine-light bg-gray-50">
                  <Camera className="h-6 w-6 text-gray-400 mb-2" />
                  <p className="text-xs font-medium text-gray-900">Selfie Verification</p>
                  <button className="mt-2 text-xs font-semibold text-pine bg-white border border-pine-200 px-3 py-1 rounded-full shadow-sm hover:bg-pine-50">Capture Selfie</button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Step 2: Business Information */}
        {currentStep === 2 && (
          <div className="space-y-6 animate-slide-in-right">
            <div><h2 className="text-lg font-semibold text-gray-900">Business Information</h2><p className="text-sm text-gray-500">Legal business entity details.</p></div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Business Type (Optional)</label>
                <select name="business_type" value={formData.business_type} onChange={handleChange} className="saas-input bg-white"><option value="">None</option><option value="Proprietorship">Proprietorship</option><option value="Private Limited">Private Limited</option><option value="Partnership">Partnership</option><option value="LLP">LLP</option></select>
              </div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Business Name</label><input type="text" name="business_name" value={formData.business_name} onChange={handleChange} className="saas-input" placeholder="Grand Hotels Pvt Ltd" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Registration Number (Optional)</label><input type="text" name="business_reg_number" value={formData.business_reg_number} onChange={handleChange} className="saas-input" placeholder="CIN/LLPIN" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">GST Number (Optional)</label><input type="text" name="business_gst" value={formData.business_gst} onChange={handleChange} className="saas-input uppercase" placeholder="29ABCDE1234F1Z5" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">PAN (Optional)</label><input type="text" name="business_pan" value={formData.business_pan} onChange={handleChange} className="saas-input uppercase" placeholder="ABCDE1234F" /></div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">GST Certificate (Optional)</label>
                <button className="saas-button-secondary w-full justify-start"><UploadCloud className="h-4 w-4 mr-2 text-gray-400"/> Upload PDF/JPG</button>
              </div>
            </div>
          </div>
        )}

        {/* Step 3: Property Information */}
        {currentStep === 3 && (
          <div className="space-y-6 animate-slide-in-right">
            <div><h2 className="text-lg font-semibold text-gray-900">Property Information</h2><p className="text-sm text-gray-500">Basic details of the property.</p></div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="sm:col-span-2"><label className="block text-sm font-medium text-gray-700 mb-1">Property Name</label><input type="text" name="property_name" value={formData.property_name} onChange={handleChange} className="saas-input" placeholder="Grand Plaza Hotel" /></div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Property Type (Optional)</label>
                <select name="property_type" value={formData.property_type} onChange={handleChange} className="saas-input bg-white"><option value="">None</option><option value="Hotel">Hotel</option><option value="Resort">Resort</option><option value="Hostel">Hostel</option><option value="Homestay">Homestay</option></select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Star Category (Optional)</label>
                <select name="star_category" value={formData.star_category} onChange={handleChange} className="saas-input bg-white"><option value="">None / Unrated</option><option value="3">3 Star</option><option value="4">4 Star</option><option value="5">5 Star</option></select>
              </div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Year Established (Optional)</label><input type="number" name="year_established" value={formData.year_established} onChange={handleChange} className="saas-input" placeholder="2010" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Total Floors (Optional)</label><input type="number" name="total_floors" value={formData.total_floors} onChange={handleChange} className="saas-input" placeholder="5" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Total Rooms (Optional)</label><input type="number" name="total_rooms" value={formData.total_rooms} onChange={handleChange} className="saas-input" placeholder="50" /></div>
              <div className="sm:col-span-2"><label className="block text-sm font-medium text-gray-700 mb-1">Description (Optional)</label><textarea name="description" value={formData.description} onChange={handleChange} className="saas-input" rows="3" placeholder="Describe the property..."></textarea></div>
            </div>
          </div>
        )}

        {/* Step 4: Location */}
        {currentStep === 4 && (
          <div className="space-y-6 animate-slide-in-right">
            <div><h2 className="text-lg font-semibold text-gray-900">Property Location</h2><p className="text-sm text-gray-500">Address and Geo-location verification.</p></div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="sm:col-span-2"><label className="block text-sm font-medium text-gray-700 mb-1">Complete Address (Optional)</label><textarea name="address" value={formData.address} onChange={handleChange} className="saas-input" rows="2" placeholder="123 Luxury Avenue"></textarea></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Landmark (Optional)</label><input type="text" className="saas-input" placeholder="Near Central Park" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">City (Optional)</label><input type="text" name="city" value={formData.city} onChange={handleChange} className="saas-input" placeholder="New York" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">State (Optional)</label><input type="text" name="state" value={formData.state} onChange={handleChange} className="saas-input" placeholder="NY" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Country (Optional)</label><input type="text" name="country" value={formData.country} onChange={handleChange} className="saas-input" placeholder="USA" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Pincode (Optional)</label><input type="text" name="pincode" value={formData.pincode} onChange={handleChange} className="saas-input" placeholder="10001" /></div>
            </div>
            <div className="border-t border-gray-100 pt-4 mt-4">
              <h3 className="text-sm font-medium text-gray-700 mb-3">Google Maps & Geo-location</h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div><label className="block text-sm font-medium text-gray-700 mb-1">Google Maps Link (Optional)</label><input type="url" className="saas-input" placeholder="https://maps.google.com/..." /></div>
                <div className="flex items-end"><button className="saas-button-secondary w-full"><MapPin className="h-4 w-4 mr-2"/> Pin Live Location</button></div>
                <div><label className="block text-sm font-medium text-gray-700 mb-1">Latitude (Optional)</label><input type="text" className="saas-input" placeholder="40.7128" /></div>
                <div><label className="block text-sm font-medium text-gray-700 mb-1">Longitude (Optional)</label><input type="text" className="saas-input" placeholder="-74.0060" /></div>
              </div>
            </div>
          </div>
        )}

        {/* Step 5: Ownership */}
        {currentStep === 5 && (
          <div className="space-y-6 animate-slide-in-right">
            <div><h2 className="text-lg font-semibold text-gray-900">Ownership Details</h2><p className="text-sm text-gray-500">Verify property ownership and operational rights.</p></div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Owned / Leased (Optional)</label>
                <select className="saas-input bg-white"><option>None</option><option>Owned</option><option>Leased</option><option>Managed</option></select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Ownership Type (Optional)</label>
                <select className="saas-input bg-white"><option>None</option><option>Individual</option><option>Company</option></select>
              </div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Property Registration Number (Optional)</label><input type="text" className="saas-input" placeholder="REG123456" /></div>
              <div className="sm:col-span-2">
                <label className="block text-sm font-medium text-gray-700 mb-1">Ownership Proof (Optional)</label>
                <select className="saas-input bg-white mb-2"><option>None</option><option>Sale Deed</option><option>Property Ownership Certificate</option><option>Lease Agreement</option><option>Hotel Management Agreement</option></select>
                <div className="border-2 border-dashed border-gray-200 rounded-lg p-6 flex flex-col items-center justify-center text-center hover:border-pine-light bg-gray-50">
                  <UploadCloud className="h-6 w-6 text-gray-400 mb-2" />
                  <p className="text-xs font-medium text-gray-900">Upload Selected Proof Document</p>
                  <button className="mt-2 text-xs font-semibold text-pine bg-white border border-pine-200 px-3 py-1 rounded-full shadow-sm hover:bg-pine-50">Browse File</button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Step 6: Dynamic Room Config */}
        {currentStep === 6 && (
          <div className="space-y-6 animate-slide-in-right">
            <div className="flex justify-between items-center">
              <div><h2 className="text-lg font-semibold text-gray-900">Room Configuration</h2><p className="text-sm text-gray-500">Define the room categories available at your property.</p></div>
              <button onClick={addRoom} className="saas-button-secondary"><Plus className="h-4 w-4 mr-1"/> Add Category</button>
            </div>
            
            <div className="space-y-6">
              {rooms.map((room, index) => (
                <div key={room.id} className="saas-card p-5 border border-gray-200">
                  <div className="flex justify-between items-center mb-4 pb-3 border-b border-gray-100">
                    <h3 className="font-semibold text-gray-900">Category {index + 1}</h3>
                    {rooms.length > 1 && (
                      <button onClick={() => removeRoom(room.id)} className="text-red-500 hover:text-red-700 p-1"><Trash2 className="h-4 w-4" /></button>
                    )}
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    <div><label className="block text-xs font-medium text-gray-700 mb-1">Room Name (Optional)</label>
                      <input type="text" value={room.name} onChange={e => updateRoom(room.id, 'name', e.target.value)} className="saas-input text-sm" placeholder="e.g. Presidential Suite" />
                    </div>
                    <div><label className="block text-xs font-medium text-gray-700 mb-1">Room Category (Optional)</label>
                      <select value={room.category} onChange={e => updateRoom(room.id, 'category', e.target.value)} className="saas-input text-sm bg-white"><option>None</option><option>Standard</option><option>Deluxe</option><option>Executive</option><option>Suite</option></select>
                    </div>
                    <div><label className="block text-xs font-medium text-gray-700 mb-1">Number of Rooms (Optional)</label>
                      <input type="number" value={room.totalRooms} onChange={e => updateRoom(room.id, 'totalRooms', e.target.value)} className="saas-input text-sm" />
                    </div>
                    <div><label className="block text-xs font-medium text-gray-700 mb-1">Max Occupancy (Optional)</label>
                      <input type="number" value={room.occupancy} onChange={e => updateRoom(room.id, 'occupancy', e.target.value)} className="saas-input text-sm" />
                    </div>
                    <div><label className="block text-xs font-medium text-gray-700 mb-1">Bed Type (Optional)</label>
                      <select value={room.bedType} onChange={e => updateRoom(room.id, 'bedType', e.target.value)} className="saas-input text-sm bg-white"><option>None</option><option>Single</option><option>Double</option><option>Queen</option><option>King</option></select>
                    </div>
                    <div><label className="block text-xs font-medium text-gray-700 mb-1">Room Size (Optional)</label>
                      <input type="text" value={room.size} onChange={e => updateRoom(room.id, 'size', e.target.value)} className="saas-input text-sm" placeholder="e.g. 200 sq ft" />
                    </div>
                    
                    <div className="sm:col-span-3 flex space-x-6 text-sm mt-2">
                      <label className="flex items-center"><input type="checkbox" checked={room.ac} onChange={e => updateRoom(room.id, 'ac', e.target.checked)} className="mr-2 text-pine focus:ring-pine" /> AC</label>
                      <label className="flex items-center"><input type="checkbox" checked={room.bathroom} onChange={e => updateRoom(room.id, 'bathroom', e.target.checked)} className="mr-2 text-pine focus:ring-pine" /> Attached Bath</label>
                      <label className="flex items-center"><input type="checkbox" checked={room.balcony} onChange={e => updateRoom(room.id, 'balcony', e.target.checked)} className="mr-2 text-pine focus:ring-pine" /> Balcony</label>
                      <label className="flex items-center"><input type="checkbox" checked={room.smoking} onChange={e => updateRoom(room.id, 'smoking', e.target.checked)} className="mr-2 text-pine focus:ring-pine" /> Smoking Allowed</label>
                    </div>
                    
                    <div className="sm:col-span-3">
                      <label className="block text-xs font-medium text-gray-700 mb-1">Description (Optional)</label>
                      <textarea value={room.description} onChange={e => updateRoom(room.id, 'description', e.target.value)} className="saas-input text-sm" rows="2" placeholder="Room details..."></textarea>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Step 7: Dynamic Room Amenities */}
        {currentStep === 7 && (
          <div className="space-y-6 animate-slide-in-right">
            <div><h2 className="text-lg font-semibold text-gray-900">Room Amenities (Optional)</h2><p className="text-sm text-gray-500">Configure amenities for each room category separately.</p></div>
            <div className="space-y-6">
              {rooms.map(room => (
                <div key={room.id} className="saas-card p-5 border border-gray-200">
                  <h3 className="font-semibold text-gray-900 mb-4 pb-2 border-b border-gray-100">{room.name || room.category || 'Unnamed Room'}</h3>
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-sm">
                    {['WiFi', 'Television', 'Mini Refrigerator', 'Wardrobe', 'Hair Dryer', 'Safe Locker', 'Coffee Maker', 'Work Desk', 'Towels', 'Toiletries', 'Iron', 'Electric Kettle'].map(amenity => (
                      <label key={amenity} className="flex items-center text-gray-700">
                        <input type="checkbox" className="mr-2 text-pine focus:ring-pine rounded border-gray-300" /> {amenity}
                      </label>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Step 8: Hotel Amenities */}
        {currentStep === 8 && (
          <div className="space-y-6 animate-slide-in-right">
            <div><h2 className="text-lg font-semibold text-gray-900">Hotel Amenities (Optional)</h2><p className="text-sm text-gray-500">Select amenities that apply to the entire property.</p></div>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
              {['Free WiFi', 'Parking', 'Restaurant', 'Swimming Pool', 'Gym', 'Spa', 'Lift', 'Reception', 'Power Backup', 'CCTV', 'Laundry', 'Room Service', 'Conference Hall', 'Banquet Hall', 'Airport Pickup', 'Doctor on Call'].map(amenity => (
                <label key={amenity} className="saas-card p-3 flex items-center cursor-pointer hover:border-pine-light transition-colors">
                  <input type="checkbox" className="mr-3 text-pine focus:ring-pine h-4 w-4 rounded border-gray-300" /> 
                  <span className="text-sm text-gray-700 font-medium">{amenity}</span>
                </label>
              ))}
            </div>
          </div>
        )}

        {/* Step 9: Dynamic Photos */}
        {currentStep === 9 && (
          <div className="space-y-6 animate-slide-in-right">
            <div><h2 className="text-lg font-semibold text-gray-900">Property & Room Photos (Optional)</h2><p className="text-sm text-gray-500">Upload high-quality images. Room photos are categorized.</p></div>
            
            {/* Global Photos */}
            <div className="saas-card p-5 border border-gray-200">
              <h3 className="font-semibold text-gray-900 mb-4 pb-2 border-b border-gray-100">Hotel Photos (Exterior & Common)</h3>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
                {['Front View', 'Reception/Lobby', 'Restaurant/Dining', 'Swimming Pool'].map(photoType => (
                  <div key={photoType} className="border border-dashed border-gray-300 rounded-lg h-24 flex flex-col items-center justify-center text-center hover:border-pine-light bg-gray-50 cursor-pointer">
                    <Camera className="h-5 w-5 text-gray-400 mb-1" />
                    <span className="text-[10px] font-medium text-gray-600 px-1">{photoType}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Room Photos */}
            {rooms.map(room => (
              <div key={room.id} className="saas-card p-5 border border-gray-200">
                <h3 className="font-semibold text-gray-900 mb-4 pb-2 border-b border-gray-100">{room.name || room.category} Photos</h3>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
                  {['Bedroom', 'Bathroom', 'Balcony/View', 'Living Area'].map(photoType => (
                    <div key={photoType} className="border border-dashed border-gray-300 rounded-lg h-24 flex flex-col items-center justify-center text-center hover:border-pine-light bg-gray-50 cursor-pointer">
                      <Camera className="h-5 w-5 text-gray-400 mb-1" />
                      <span className="text-[10px] font-medium text-gray-600 px-1">{photoType}</span>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Step 10: Hotel Policies */}
        {currentStep === 10 && (
          <div className="space-y-6 animate-slide-in-right">
            <div><h2 className="text-lg font-semibold text-gray-900">Hotel Policies (Optional)</h2><p className="text-sm text-gray-500">Define operational rules and regulations.</p></div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
              <div className="space-y-4">
                <div><label className="block text-sm font-medium text-gray-700 mb-1">Check-in Time (Optional)</label><input type="time" className="saas-input" /></div>
                <div><label className="block text-sm font-medium text-gray-700 mb-1">Check-out Time (Optional)</label><input type="time" className="saas-input" /></div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Cancellation Policy (Optional)</label>
                  <select className="saas-input"><option>None</option><option>Free before 24hrs</option><option>Non-refundable</option><option>Custom</option></select>
                </div>
              </div>
              <div className="space-y-3">
                {['Couple Friendly', 'Pets Allowed', 'Smoking Allowed', 'Local ID Accepted', 'Unmarried Couples Allowed'].map(policy => (
                  <label key={policy} className="flex items-center p-3 border border-gray-100 rounded-lg bg-gray-50 cursor-pointer">
                    <input type="checkbox" className="mr-3 text-pine focus:ring-pine h-4 w-4 rounded border-gray-300" /> 
                    <span className="text-sm text-gray-700 font-medium">{policy}</span>
                  </label>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Step 11: Dynamic Pricing */}
        {currentStep === 11 && (
          <div className="space-y-6 animate-slide-in-right">
            <div><h2 className="text-lg font-semibold text-gray-900">Pricing Configuration (Optional)</h2><p className="text-sm text-gray-500">Set base prices, taxes, and meal plans per room category.</p></div>
            <div className="space-y-6">
              {rooms.map(room => (
                <div key={room.id} className="saas-card p-5 border border-gray-200">
                  <h3 className="font-semibold text-gray-900 mb-4 pb-2 border-b border-gray-100">{room.name || room.category}</h3>
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    <div><label className="block text-xs font-medium text-gray-700 mb-1">Base Price / Night (Optional)</label><input type="number" className="saas-input text-sm" placeholder="₹" /></div>
                    <div><label className="block text-xs font-medium text-gray-700 mb-1">Weekend Price (Optional)</label><input type="number" className="saas-input text-sm" placeholder="₹" /></div>
                    <div><label className="block text-xs font-medium text-gray-700 mb-1">Extra Adult Charge (Optional)</label><input type="number" className="saas-input text-sm" placeholder="₹" /></div>
                    <div><label className="block text-xs font-medium text-gray-700 mb-1">Extra Child Charge (Optional)</label><input type="number" className="saas-input text-sm" placeholder="₹" /></div>
                    <div><label className="block text-xs font-medium text-gray-700 mb-1">Taxes (GST %) (Optional)</label><select className="saas-input text-sm bg-white"><option>None</option><option>12%</option><option>18%</option><option>Included in Base</option></select></div>
                    <div><label className="block text-xs font-medium text-gray-700 mb-1">Meal Plan (Optional)</label><select className="saas-input text-sm bg-white"><option>None</option><option>EP (Room Only)</option><option>CP (Breakfast)</option><option>MAP (Half Board)</option></select></div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Step 12: Dynamic Inventory */}
        {currentStep === 12 && (
          <div className="space-y-6 animate-slide-in-right">
            <div><h2 className="text-lg font-semibold text-gray-900">Inventory & Availability (Optional)</h2><p className="text-sm text-gray-500">Manage room blocks and stay constraints.</p></div>
            <div className="space-y-6">
              {rooms.map(room => (
                <div key={room.id} className="saas-card p-5 border border-gray-200">
                  <h3 className="font-semibold text-gray-900 mb-4 pb-2 border-b border-gray-100">{room.name || room.category}</h3>
                  <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
                    <div><label className="block text-xs font-medium text-gray-700 mb-1">Total Inventory</label><input type="number" value={room.totalRooms} readOnly className="saas-input text-sm bg-gray-50 text-gray-500" /></div>
                    <div><label className="block text-xs font-medium text-gray-700 mb-1">Daily Available (Optional)</label><input type="number" defaultValue={room.totalRooms} className="saas-input text-sm" /></div>
                    <div><label className="block text-xs font-medium text-gray-700 mb-1">Minimum Stay (Optional)</label><input type="number" defaultValue="" placeholder="e.g. 1" className="saas-input text-sm" /></div>
                    <div><label className="block text-xs font-medium text-gray-700 mb-1">Maximum Stay (Optional)</label><input type="number" defaultValue="" placeholder="e.g. 30" className="saas-input text-sm" /></div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Step 13: Bank Details */}
        {currentStep === 13 && (
          <div className="space-y-6 animate-slide-in-right">
            <div><h2 className="text-lg font-semibold text-gray-900">Bank Details (Optional)</h2><p className="text-sm text-gray-500">Account information for payouts.</p></div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Bank Name</label><input type="text" className="saas-input" placeholder="HDFC Bank" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Account Holder Name</label><input type="text" className="saas-input" placeholder="Grand Hotels Pvt Ltd" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Account Number</label><input type="password" className="saas-input" placeholder="••••••••••••1234" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">IFSC Code</label><input type="text" className="saas-input uppercase" placeholder="HDFC0001234" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">UPI ID (Optional)</label><input type="text" className="saas-input" placeholder="merchant@upi" /></div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Cancelled Cheque</label>
                <button className="saas-button-secondary w-full justify-start"><UploadCloud className="h-4 w-4 mr-2 text-gray-400"/> Upload Image</button>
              </div>
            </div>
          </div>
        )}

        {/* Step 14: Legal Documents & Compliance */}
        {currentStep === 14 && (
          <div className="space-y-6 animate-slide-in-right">
            <div><h2 className="text-lg font-semibold text-gray-900">Legal Documents (Optional)</h2><p className="text-sm text-gray-500">Upload compliance and safety certificates if available.</p></div>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
              {['PAN Card', 'Trade License', 'Fire Safety', 'Occupancy Cert', 'GST Cert', 'Ownership Proof', 'Bank Proof', 'Tourism Reg'].map(doc => (
                <div key={doc} className="border border-dashed border-gray-300 rounded-lg p-4 flex flex-col items-center justify-center text-center hover:border-pine-light bg-gray-50">
                  <FileText className="h-6 w-6 text-gray-400 mb-2" />
                  <p className="text-[11px] font-medium text-gray-900 leading-tight mb-2">{doc}</p>
                  <button className="text-[10px] font-semibold text-pine bg-white border border-pine-200 px-2 py-1 rounded shadow-sm hover:bg-pine-50">Upload (Optional)</button>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Step 15: Verification Summary & Submit */}
        {currentStep === 15 && (
          <div className="space-y-6 animate-slide-in-right">
            <div className="text-center pb-6 border-b border-gray-100">
              <div className="w-16 h-16 bg-blue-50 rounded-full flex items-center justify-center mx-auto mb-4">
                <Shield className="w-8 h-8 text-blue-500" />
              </div>
              <h2 className="text-xl font-semibold text-gray-900">Verification & Submission</h2>
              <p className="text-sm text-gray-500 mt-1">Review the automated checks before final submission to the manual review queue.</p>
            </div>
            
            <div className="max-w-2xl mx-auto space-y-3">
              {[
                { name: 'Mobile OTP Verification', status: 'Pending', color: 'text-yellow-600', icon: Clock },
                { name: 'Email OTP Verification', status: 'Pending', color: 'text-yellow-600', icon: Clock },
                { name: 'PAN Validation', status: 'Pending', color: 'text-yellow-600', icon: Clock },
                { name: 'GST Validation', status: 'Pending', color: 'text-yellow-600', icon: Clock },
                { name: 'Google Maps Geo-location', status: 'Pending', color: 'text-yellow-600', icon: Clock },
                { name: 'Bank Verification (Penny Drop)', status: 'Pending', color: 'text-yellow-600', icon: Clock },
                { name: 'Document Analysis (AI)', status: 'Pending', color: 'text-yellow-600', icon: Clock },
                { name: 'Risk Assessment Score', status: 'Incomplete Data', color: 'text-yellow-600', icon: ShieldCheck },
              ].map(check => (
                <div key={check.name} className="flex items-center justify-between p-3 border border-gray-100 rounded-lg bg-gray-50">
                  <span className="text-sm font-medium text-gray-700">{check.name}</span>
                  <span className={`flex items-center text-sm font-medium ${check.color}`}>
                    <check.icon className="h-4 w-4 mr-1.5" /> {check.status}
                  </span>
                </div>
              ))}
            </div>

            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mt-6 max-w-2xl mx-auto text-sm text-yellow-800 flex">
              <ShieldCheck className="h-5 w-5 mr-2 flex-shrink-0 text-yellow-600" />
              <p>Since most fields are optional, automated verification checks are currently pending. Submitting this property will queue it for manual verification by an administrator.</p>
            </div>
          </div>
        )}
      </div>

      {/* Floating Action Footer */}
      <div className="fixed bottom-0 left-0 lg:left-64 right-0 bg-white border-t border-gray-200 p-4 shadow-saas z-40 flex items-center justify-between px-6 sm:px-10">
        <div className="flex space-x-3">
          <button 
            onClick={prevStep}
            disabled={currentStep === 1}
            className="saas-button-secondary disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <ChevronLeft className="w-4 h-4 mr-1" /> Back
          </button>
          <button 
            onClick={() => {
              if (window.confirm('Are you sure you need to exit from add property?')) {
                navigate('/properties');
              }
            }}
            className="saas-button-secondary text-red-600 hover:bg-red-50 border-red-200"
          >
            Exit
          </button>
        </div>
        
        <div className="flex space-x-3">
          <button className="saas-button-secondary font-medium text-gray-600 hidden sm:block">
            Save as Draft
          </button>
          
          {currentStep < 15 ? (
            <button onClick={nextStep} className="saas-button-primary">
              Continue <ChevronRight className="w-4 h-4 ml-1" />
            </button>
          ) : (
            <button onClick={handleSubmit} disabled={isSubmitting} className="saas-button-primary bg-pine">
              {isSubmitting ? 'Submitting...' : 'Submit Property'}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
