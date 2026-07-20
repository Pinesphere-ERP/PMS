import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Users, Building2, Plus, Search, Phone, Mail, 
  ChevronRight, AlertCircle, Loader2, Eye, Briefcase,
  Hash, User, Shield, RefreshCw, Crown
} from 'lucide-react';
import { ownerService } from '../../services/ownerService';
import CreateOwnerModal from './CreateOwnerModal';

const ROLE_COLORS = {
  'text-emerald-400': 'bg-emerald-400/10 border-emerald-400/20',
};

export default function OwnerList() {
  const navigate = useNavigate();
  const [owners, setOwners] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [refreshKey, setRefreshKey] = useState(0);

  useEffect(() => {
    const fetchOwners = async () => {
      try {
        setLoading(true);
        setError(null);
        const data = await ownerService.getOwners();
        setOwners(Array.isArray(data) ? data : []);
      } catch (err) {
        setError(err.message || 'Failed to load owners');
      } finally {
        setLoading(false);
      }
    };
    fetchOwners();
  }, [refreshKey]);

  const filtered = owners.filter(o =>
    [o.full_name, o.email, o.mobile_number, o.designation]
      .filter(Boolean)
      .some(v => v.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  const handleOwnerCreated = () => {
    setShowCreateModal(false);
    setRefreshKey(k => k + 1);
  };

  return (
    <div className="min-h-screen">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <div className="w-8 h-8 rounded-lg bg-amber-500/10 border border-amber-500/20 flex items-center justify-center">
              <Crown className="w-4 h-4 text-amber-400" />
            </div>
            <h1 className="text-2xl font-bold text-gray-900">Owner Management</h1>
          </div>
          <p className="text-sm text-gray-500 ml-10">
            Create and manage property owners. Owners are created first, then properties are assigned to them.
          </p>
        </div>
        <button
          onClick={() => setShowCreateModal(true)}
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-amber-500 hover:bg-amber-600 text-white text-sm font-semibold rounded-xl shadow-sm transition-all duration-200 hover:shadow-md active:scale-95"
        >
          <Plus className="w-4 h-4" />
          Create Owner
        </button>
      </div>

      {/* Stats Row */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6">
        {[
          { label: 'Total Owners', value: owners.length, icon: Crown, color: 'text-amber-500', bg: 'bg-amber-50' },
          { label: 'With Properties', value: owners.filter(o => o.property_count > 0).length, icon: Building2, color: 'text-emerald-600', bg: 'bg-emerald-50' },
          { label: 'No Property Yet', value: owners.filter(o => o.property_count === 0).length, icon: AlertCircle, color: 'text-orange-500', bg: 'bg-orange-50' },
          { label: 'Total Properties', value: owners.reduce((acc, o) => acc + (o.property_count || 0), 0), icon: Building2, color: 'text-indigo-600', bg: 'bg-indigo-50' },
        ].map((stat) => (
          <div key={stat.label} className="bg-white rounded-xl border border-gray-200 p-4 shadow-sm">
            <div className="flex items-center gap-2 mb-2">
              <div className={`w-7 h-7 rounded-lg ${stat.bg} flex items-center justify-center`}>
                <stat.icon className={`w-4 h-4 ${stat.color}`} />
              </div>
              <span className="text-xs font-medium text-gray-500">{stat.label}</span>
            </div>
            <p className="text-2xl font-bold text-gray-900">{loading ? '—' : stat.value}</p>
          </div>
        ))}
      </div>

      {/* Search */}
      <div className="relative mb-4">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input
          type="text"
          placeholder="Search owners by name, email, mobile..."
          value={searchTerm}
          onChange={e => setSearchTerm(e.target.value)}
          className="w-full pl-10 pr-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-amber-500/30 focus:border-amber-400 bg-white"
        />
      </div>

      {/* Owner Table */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-20">
            <Loader2 className="w-8 h-8 text-amber-500 animate-spin" />
          </div>
        ) : error ? (
          <div className="p-8 text-center">
            <AlertCircle className="w-10 h-10 text-red-400 mx-auto mb-3" />
            <p className="text-red-600 font-medium">{error}</p>
            <button
              onClick={() => setRefreshKey(k => k + 1)}
              className="mt-4 inline-flex items-center gap-2 text-sm text-gray-500 hover:text-gray-700"
            >
              <RefreshCw className="w-4 h-4" /> Retry
            </button>
          </div>
        ) : filtered.length === 0 ? (
          <div className="py-20 text-center">
            <Crown className="w-12 h-12 text-gray-200 mx-auto mb-4" />
            <p className="text-gray-500 font-medium">
              {searchTerm ? 'No owners match your search' : 'No owners yet'}
            </p>
            {!searchTerm && (
              <p className="text-sm text-gray-400 mt-1 mb-6">
                Create your first owner to get started
              </p>
            )}
            {!searchTerm && (
              <button
                onClick={() => setShowCreateModal(true)}
                className="inline-flex items-center gap-2 px-4 py-2 bg-amber-500 text-white text-sm font-semibold rounded-lg hover:bg-amber-600 transition"
              >
                <Plus className="w-4 h-4" /> Create Owner
              </button>
            )}
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50/60">
                  <th className="px-6 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Owner</th>
                  <th className="px-6 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Contact</th>
                  <th className="px-6 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">PAN</th>
                  <th className="px-6 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Properties</th>
                  <th className="px-6 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
                  <th className="w-12"></th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {filtered.map((owner) => (
                  <tr
                    key={owner.owner_id}
                    onClick={() => navigate(`/owners/${owner.owner_id}`)}
                    className="hover:bg-amber-50/40 cursor-pointer transition-colors group"
                  >
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-full bg-gradient-to-br from-amber-400 to-orange-500 flex items-center justify-center text-white text-sm font-bold flex-shrink-0 shadow-sm">
                          {owner.full_name?.charAt(0)?.toUpperCase() || 'O'}
                        </div>
                        <div>
                          <p className="font-semibold text-gray-900 text-sm">{owner.full_name}</p>
                          {owner.designation && (
                            <p className="text-xs text-gray-400">{owner.designation}</p>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="space-y-1">
                        <div className="flex items-center gap-1.5 text-sm text-gray-600">
                          <Mail className="w-3.5 h-3.5 text-gray-400 flex-shrink-0" />
                          <span className="truncate max-w-[180px]">{owner.email || '—'}</span>
                        </div>
                        <div className="flex items-center gap-1.5 text-sm text-gray-600">
                          <Phone className="w-3.5 h-3.5 text-gray-400 flex-shrink-0" />
                          {owner.mobile_number || '—'}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="font-mono text-xs text-gray-600 bg-gray-100 px-2 py-1 rounded">
                        {owner.pan_number || 'N/A'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        <span className={`inline-flex items-center gap-1 text-xs font-semibold px-2.5 py-1 rounded-full border ${
                          owner.property_count > 0
                            ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                            : 'bg-orange-50 text-orange-600 border-orange-200'
                        }`}>
                          <Building2 className="w-3 h-3" />
                          {owner.property_count} {owner.property_count === 1 ? 'Property' : 'Properties'}
                        </span>
                        {owner.property_count === 0 && (
                          <span className="text-xs text-orange-500 font-medium">No property assigned</span>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="inline-flex items-center text-xs font-semibold px-2 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200">
                        Active
                      </span>
                    </td>
                    <td className="px-4 py-4 text-right">
                      <ChevronRight className="w-4 h-4 text-gray-300 group-hover:text-amber-500 transition-colors" />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Create Owner Modal */}
      {showCreateModal && (
        <CreateOwnerModal
          onClose={() => setShowCreateModal(false)}
          onCreated={handleOwnerCreated}
        />
      )}
    </div>
  );
}
