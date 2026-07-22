import { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import {
  ArrowLeft, Building2, User, Phone, Mail, Lock, Hash,
  Shield, Eye, EyeOff, Loader2, CheckCircle2, AlertCircle,
  ChevronRight, Crown, Users
} from 'lucide-react';
import { fetchAPI } from '../../services/api';

const ROLE_ICONS = {
  OWNER:        Crown,
  MANAGER:      Users,
  RECEPTIONIST: Hash,
  HOUSEKEEPING: Shield,
  KITCHEN:      Shield,
  MAINTENANCE:  Shield,
  ACCOUNTANT:   Shield,
  SECURITY:     Shield,
  BROKER:       Shield,
};

const ROLE_COLORS = {
  OWNER:        'from-amber-400 to-orange-500',
  MANAGER:      'from-blue-400 to-indigo-500',
  RECEPTIONIST: 'from-violet-400 to-purple-500',
  HOUSEKEEPING: 'from-teal-400 to-cyan-500',
  KITCHEN:      'from-orange-400 to-red-500',
  MAINTENANCE:  'from-red-400 to-rose-500',
  ACCOUNTANT:   'from-green-400 to-emerald-500',
  SECURITY:     'from-slate-400 to-gray-500',
  BROKER:       'from-pink-400 to-fuchsia-500',
};

export default function CreateUserForProperty() {
  const { id: propertyId } = useParams();
  const navigate = useNavigate();

  const [property, setProperty] = useState(null);
  const [roles, setRoles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState(null);
  const [showPassword, setShowPassword] = useState(false);

  const [form, setForm] = useState({
    name: '',
    mobile_number: '',
    email: '',
    username: '',
    password: '',
    role_id: '',
  });

  useEffect(() => {
    const load = async () => {
      try {
        setLoading(true);
        const [propData, rolesData] = await Promise.all([
          fetchAPI(`/properties/${propertyId}`),
          fetchAPI('/users/roles'),
        ]);
        setProperty(propData);
        // Filter out SUPER_ADMIN from role selection — those users have no property
        setRoles((Array.isArray(rolesData) ? rolesData : []).filter(
          r => r.role_code !== 'SUPER_ADMIN'
        ));
      } catch (e) {
        setError(e.message || 'Failed to load property details');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [propertyId]);

  const handleChange = (e) => {
    setForm(prev => ({ ...prev, [e.target.name]: e.target.value }));
    setError(null);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const payload = {
        ...form,
        property_id: propertyId,  // Always locked to this property
      };
      // Remove empty optional fields
      if (!payload.email) delete payload.email;
      if (!payload.username) delete payload.username;

      // Fix for the UUID bug: if the role_id is actually a role_code (not a UUID)
      if (payload.role_id && !payload.role_id.includes('-')) {
        payload.role_code = payload.role_id;
        delete payload.role_id;
      }

      await fetchAPI('/users', {
        method: 'POST',
        body: JSON.stringify(payload),
      });

      setSuccess(true);
    } catch (err) {
      setError(err.message || 'Failed to create user');
    } finally {
      setSubmitting(false);
    }
  };

  const selectedRole = roles.find(r => r.id === form.role_id);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-64">
        <Loader2 className="w-8 h-8 text-indigo-600 animate-spin" />
      </div>
    );
  }

  if (success) {
    return (
      <div className="max-w-xl mx-auto py-12 text-center">
        <div className="w-20 h-20 rounded-full bg-emerald-50 border-4 border-emerald-200 flex items-center justify-center mx-auto mb-6">
          <CheckCircle2 className="w-10 h-10 text-emerald-500" />
        </div>
        <h2 className="text-2xl font-bold text-gray-900 mb-2">User Created Successfully</h2>
        <p className="text-gray-500 mb-2">
          The new user has been added to <strong>{property?.name}</strong> and is ready to log in.
        </p>
        <div className="flex flex-col sm:flex-row gap-3 justify-center mt-6">
          <button
            onClick={() => {
              setSuccess(false);
              setForm({ name: '', mobile_number: '', email: '', username: '', password: '', role_id: '' });
            }}
            className="px-5 py-2.5 border border-gray-200 rounded-xl text-sm font-medium text-gray-700 hover:bg-gray-50 transition"
          >
            Add Another User
          </button>
          <button
            onClick={() => navigate(`/properties/${propertyId}`, { state: { tab: 'staff' } })}
            className="px-5 py-2.5 bg-indigo-600 text-white rounded-xl text-sm font-semibold hover:bg-indigo-700 transition shadow-sm"
          >
            Back to Property Staff
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto">
      {/* Breadcrumb */}
      <div className="flex items-center gap-2 text-sm text-gray-500 mb-6">
        <Link to="/properties" className="hover:text-gray-700 transition">Properties</Link>
        <ChevronRight className="w-4 h-4" />
        <Link to={`/properties/${propertyId}`} className="hover:text-gray-700 transition">
          {property?.name || 'Property'}
        </Link>
        <ChevronRight className="w-4 h-4" />
        <span className="text-gray-900 font-medium">Create User</span>
      </div>

      {/* Header */}
      <div className="flex items-start gap-3 mb-6">
        <button
          onClick={() => navigate(-1)}
          className="mt-1 p-2 hover:bg-gray-100 rounded-xl text-gray-400 hover:text-gray-600 transition"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Create User</h1>
          <p className="text-sm text-gray-500 mt-1">Add a new staff member to this property</p>
        </div>
      </div>

      {/* Property Lock Banner — this is the KEY feature */}
      <div className="mb-6 flex items-center gap-3 bg-gradient-to-r from-indigo-50 to-violet-50 border border-indigo-200 rounded-2xl px-5 py-4">
        <div className="w-10 h-10 rounded-xl bg-indigo-600 flex items-center justify-center flex-shrink-0 shadow-sm">
          <Building2 className="w-5 h-5 text-white" />
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-xs font-semibold text-indigo-600 uppercase tracking-wider mb-0.5">Current Property</p>
          <p className="text-base font-bold text-gray-900 truncate">{property?.name || '—'}</p>
          <p className="text-xs text-gray-500 truncate">{property?.business} · {property?.type || 'Hotel'}</p>
        </div>
        <div className="flex-shrink-0 flex items-center gap-1.5 text-xs text-indigo-600 bg-indigo-100 border border-indigo-200 px-2.5 py-1 rounded-full font-semibold">
          <Lock className="w-3.5 h-3.5" />
          Read Only
        </div>
      </div>

      {/* Form */}
      <form onSubmit={handleSubmit} className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
        <div className="px-6 py-5 border-b border-gray-100 bg-gray-50/50">
          <h2 className="text-sm font-semibold text-gray-900 flex items-center gap-2">
            <User className="w-4 h-4 text-indigo-500" />
            User Details
          </h2>
        </div>

        <div className="px-6 py-5 space-y-5">
          {/* Role Selection — prominent placement */}
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">
              Role <span className="text-red-400">*</span>
            </label>
            <select
              name="role_id"
              value={form.role_id}
              onChange={handleChange}
              required
              className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400/30 focus:border-indigo-400 bg-white appearance-none"
            >
              <option value="">Select a role…</option>
              {roles.map(r => (
                <option key={r.id} value={r.id}>{r.role_name}</option>
              ))}
            </select>
            {selectedRole && (
              <div className={`mt-2 inline-flex items-center gap-1.5 text-xs font-semibold px-3 py-1 rounded-full bg-gradient-to-r ${ROLE_COLORS[selectedRole.role_code] || 'from-gray-400 to-gray-500'} text-white shadow-sm`}>
                <Shield className="w-3 h-3" />
                {selectedRole.role_name} selected
              </div>
            )}
          </div>

          {/* Name */}
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">
              Full Name <span className="text-red-400">*</span>
            </label>
            <div className="relative">
              <User className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
              <input
                type="text"
                name="name"
                required
                value={form.name}
                onChange={handleChange}
                placeholder="e.g. Anita Sharma"
                className="w-full pl-9 pr-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400/30 focus:border-indigo-400 bg-gray-50/50"
              />
            </div>
          </div>

          {/* Mobile + Email */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Mobile <span className="text-red-400">*</span>
              </label>
              <div className="relative">
                <Phone className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                <input
                  type="tel"
                  name="mobile_number"
                  required
                  value={form.mobile_number}
                  onChange={handleChange}
                  placeholder="+91 9999999999"
                  className="w-full pl-9 pr-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400/30 focus:border-indigo-400 bg-gray-50/50"
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">Email</label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                <input
                  type="email"
                  name="email"
                  value={form.email}
                  onChange={handleChange}
                  placeholder="staff@hotel.com"
                  className="w-full pl-9 pr-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400/30 focus:border-indigo-400 bg-gray-50/50"
                />
              </div>
            </div>
          </div>

          {/* Username + Password */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">Username</label>
              <div className="relative">
                <Hash className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                <input
                  type="text"
                  name="username"
                  value={form.username}
                  onChange={handleChange}
                  placeholder="anita.sharma"
                  className="w-full pl-9 pr-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400/30 focus:border-indigo-400 bg-gray-50/50"
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Password <span className="text-red-400">*</span>
              </label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                <input
                  type={showPassword ? 'text' : 'password'}
                  name="password"
                  required
                  value={form.password}
                  onChange={handleChange}
                  placeholder="Min 6 characters"
                  className="w-full pl-9 pr-10 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400/30 focus:border-indigo-400 bg-gray-50/50"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>
          </div>

          {/* Error */}
          {error && (
            <div className="flex items-center gap-2 bg-red-50 border border-red-200 rounded-xl px-4 py-3 text-sm text-red-600">
              <AlertCircle className="w-4 h-4 flex-shrink-0" />
              {error}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-between px-6 py-4 border-t border-gray-100 bg-gray-50/60">
          <button
            type="button"
            onClick={() => navigate(-1)}
            className="px-4 py-2 text-sm font-medium text-gray-600 hover:text-gray-800 hover:bg-gray-100 rounded-xl transition"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={submitting}
            className="inline-flex items-center gap-2 px-6 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold rounded-xl transition shadow-sm disabled:opacity-60 active:scale-95"
          >
            {submitting ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" /> Creating…
              </>
            ) : (
              <>
                <Users className="w-4 h-4" /> Create User
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
