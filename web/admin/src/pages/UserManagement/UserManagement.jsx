import { useState, useEffect } from 'react';
import { fetchAPI } from '../../services/api';
import { 
  Users, Search, Plus, Shield, Mail, Phone, Lock, Hash, Eye, EyeOff, CheckCircle2, Clock
} from 'lucide-react';
import DataTable from '../../components/ui/DataTable';

export default function UserManagement() {
  const [users, setUsers] = useState([]);
  const [roles, setRoles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [properties, setProperties] = useState([]);

  const [formData, setFormData] = useState({
    name: '',
    email: '',
    mobile_number: '',
    username: '',
    password: '',
    role_id: ''
  });

  useEffect(() => {
    fetchUsers();
    fetchRoles();
    fetchProperties();
  }, []);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const res = await fetchAPI('/users?unassigned_only=true'); // Or list all? Let's list all for now
      setUsers(Array.isArray(res) ? res : res.data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const fetchRoles = async () => {
    try {
      const res = await fetchAPI('/users/roles');
      setRoles(Array.isArray(res) ? res : res.data || []);
    } catch (err) {
      console.error(err);
    }
  };

  const fetchProperties = async () => {
    try {
      const res = await fetchAPI('/properties');
      setProperties(Array.isArray(res) ? res : res.data || []);
    } catch (err) {
      console.error(err);
    }
  };

  const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const payload = { ...formData };
      if (!payload.property_id) {
        delete payload.property_id;
      }
      if (!payload.email) delete payload.email;
      if (!payload.username) delete payload.username;
      
      // Fix for the UUID bug: if the role_id is actually a role_code (not a UUID)
      if (payload.role_id && !payload.role_id.includes('-')) {
        payload.role_code = payload.role_id;
        delete payload.role_id;
      }

      await fetchAPI('/users', {
        method: 'POST',
        body: JSON.stringify(payload)
      });
      setShowModal(false);
      setFormData({ name: '', email: '', mobile_number: '', username: '', password: '', role_id: '', property_id: '' });
      fetchUsers();
    } catch (err) {
      alert(err.message || 'Failed to create user');
    }
  };

  const columns = [
    {
      header: 'Name',
      accessor: 'name',
      sortable: true,
      render: (row) => (
        <div>
          <div className="font-medium text-gray-900">{row.name}</div>
          <div className="text-sm text-gray-500">@{row.username || 'N/A'}</div>
        </div>
      )
    },
    {
      header: 'Contact',
      accessor: 'email',
      sortable: true,
      render: (row) => (
        <div>
          <div className="text-sm text-gray-900 flex items-center">
            <Mail className="h-4 w-4 mr-1 text-gray-400" /> {row.email || 'N/A'}
          </div>
          <div className="text-sm text-gray-500 flex items-center mt-1">
            <Phone className="h-4 w-4 mr-1 text-gray-400" /> {row.mobile_number}
          </div>
        </div>
      )
    },
    {
      header: 'Role',
      accessor: 'role_id',
      sortable: true,
      render: (row) => (
        <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800">
          {roles.find(r => r.id === row.role_id)?.role_name || (row.role_id ? String(row.role_id).split('-')[0] : 'N/A')}
        </span>
      )
    },
    {
      header: 'Status',
      accessor: 'status',
      sortable: true,
      render: (row) => (
        <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
          row.status === 'ACTIVE' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
        }`}>
          {row.status}
        </span>
      )
    }
  ];

  const tableActions = (
    <button
      onClick={() => setShowModal(true)}
      className="flex items-center px-4 py-2 bg-pine text-white rounded-lg hover:bg-pine-dark transition shadow-sm"
    >
      <Plus className="h-5 w-5 mr-1" />
      Create User
    </button>
  );

  return (
    <div className="p-6 max-w-7xl mx-auto">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center">
            <Users className="h-6 w-6 mr-2 text-pine" />
            User Management
          </h1>
          <p className="text-gray-500 mt-1">Manage admin users, owners, and staff</p>
        </div>
      </div>
      <div className="flex-1">
        <DataTable 
          columns={columns}
          data={users}
          loading={loading}
          emptyStateMessage="No users found."
          searchPlaceholder="Search users..."
          actions={tableActions}
        />
      </div>

      {showModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <div className="fixed inset-0 transition-opacity" onClick={() => setShowModal(false)}>
              <div className="absolute inset-0 bg-gray-500 opacity-75"></div>
            </div>
            <span className="hidden sm:inline-block sm:align-middle sm:h-screen"></span>
            
            <div className="inline-block align-bottom bg-white rounded-xl text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg w-full">
              <form onSubmit={handleSubmit}>
                <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                  <div className="mb-4">
                    <h3 className="text-lg leading-6 font-medium text-gray-900">Create New User</h3>
                  </div>
                  
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Full Name</label>
                      <input type="text" name="name" required value={formData.name} onChange={handleChange} className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-pine focus:ring-pine sm:text-sm p-2 border" />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700">Mobile</label>
                        <input type="text" name="mobile_number" required value={formData.mobile_number} onChange={handleChange} className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-pine focus:ring-pine sm:text-sm p-2 border" />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700">Email</label>
                        <input type="email" name="email" value={formData.email} onChange={handleChange} className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-pine focus:ring-pine sm:text-sm p-2 border" />
                      </div>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700">Username</label>
                        <input type="text" name="username" value={formData.username} onChange={handleChange} className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-pine focus:ring-pine sm:text-sm p-2 border" />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700">Password</label>
                        <div className="relative mt-1">
                          <input 
                            type={showPassword ? "text" : "password"} 
                            name="password" 
                            required 
                            value={formData.password} 
                            onChange={handleChange} 
                            className="block w-full rounded-md border-gray-300 shadow-sm focus:border-pine focus:ring-pine sm:text-sm p-2 border pr-10" 
                          />
                          <button
                            type="button"
                            onClick={() => setShowPassword(!showPassword)}
                            className="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600 focus:outline-none"
                          >
                            {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                          </button>
                        </div>
                      </div>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700">Role</label>
                        <select name="role_id" required value={formData.role_id} onChange={handleChange} className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-pine focus:ring-pine sm:text-sm p-2 border">
                          <option value="">Select Role</option>
                          {roles.map(r => (
                            <option key={r.id || r.role_code} value={r.id || r.role_code}>{r.role_name}</option>
                          ))}
                        </select>
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700">Property (Optional)</label>
                        <select name="property_id" value={formData.property_id || ''} onChange={handleChange} className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-pine focus:ring-pine sm:text-sm p-2 border">
                          <option value="">No Property / System-wide</option>
                          {properties.map(p => (
                            <option key={p.id} value={p.id}>{p.name}</option>
                          ))}
                        </select>
                      </div>
                    </div>
                  </div>
                </div>
                <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                  <button type="submit" className="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-pine text-base font-medium text-white hover:bg-pine-dark focus:outline-none sm:ml-3 sm:w-auto sm:text-sm">
                    Create
                  </button>
                  <button type="button" onClick={() => setShowModal(false)} className="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm">
                    Cancel
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
