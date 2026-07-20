import React, { useEffect, useState, useCallback } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { propertyService } from '../../services/propertyService';
import { fetchAPI } from '../../services/api';
import {
  Building2, MapPin, User, Mail, Phone, CalendarDays,
  Bed, Layers, Activity, CheckCircle2, AlertCircle, ArrowLeft,
  CreditCard, Loader2, Users, Smartphone, FileText, ClipboardList,
  Plus, Shield, Crown, Tag, Clock, Hash, ChevronRight,
  Settings, BarChart3, Edit, MoreVertical, RefreshCw,
  Wifi, WifiOff, Star, Eye, Lock
} from 'lucide-react';

const TABS = [
  { id: 'overview', label: 'Overview', icon: Activity },
  { id: 'staff', label: 'Staff', icon: Users },
  { id: 'rooms', label: 'Rooms', icon: Bed },
  { id: 'devices', label: 'Devices', icon: Smartphone },
  { id: 'subscription', label: 'Subscription', icon: CreditCard },
  { id: 'audit', label: 'Audit Logs', icon: ClipboardList },
];

const ROLE_BADGE = {
  OWNER:        { bg: 'bg-amber-50', text: 'text-amber-700', border: 'border-amber-200' },
  MANAGER:      { bg: 'bg-blue-50',  text: 'text-blue-700',  border: 'border-blue-200' },
  RECEPTIONIST: { bg: 'bg-violet-50', text: 'text-violet-700', border: 'border-violet-200' },
  HOUSEKEEPING: { bg: 'bg-teal-50',  text: 'text-teal-700',  border: 'border-teal-200' },
  KITCHEN:      { bg: 'bg-orange-50', text: 'text-orange-700', border: 'border-orange-200' },
  MAINTENANCE:  { bg: 'bg-red-50',   text: 'text-red-700',   border: 'border-red-200' },
  ACCOUNTANT:   { bg: 'bg-green-50', text: 'text-green-700', border: 'border-green-200' },
  SECURITY:     { bg: 'bg-slate-50', text: 'text-slate-700', border: 'border-slate-200' },
  BROKER:       { bg: 'bg-pink-50',  text: 'text-pink-700',  border: 'border-pink-200' },
};

function RoleBadge({ roleCode, roleName }) {
  const style = ROLE_BADGE[roleCode] || { bg: 'bg-gray-50', text: 'text-gray-700', border: 'border-gray-200' };
  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold border ${style.bg} ${style.text} ${style.border}`}>
      {roleName || roleCode}
    </span>
  );
}

function InfoRow({ label, value, mono }) {
  return (
    <div className="flex items-start justify-between py-2.5 border-b border-gray-50 last:border-0">
      <span className="text-sm text-gray-500 font-medium">{label}</span>
      <span className={`text-sm text-gray-900 text-right ml-4 ${mono ? 'font-mono text-xs bg-gray-100 px-1.5 py-0.5 rounded' : 'font-medium'}`}>
        {value || '—'}
      </span>
    </div>
  );
}

// ── Tab: Overview ──────────────────────────────────────────────────────────────
function OverviewTab({ property }) {
  const isSubActive = property.subscription?.status?.toLowerCase() === 'active';
  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      {/* Left: Property + Owner info */}
      <div className="lg:col-span-2 space-y-6">
        {/* Property Info */}
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-6">
          <h3 className="text-sm font-semibold text-gray-900 mb-4 flex items-center gap-2">
            <Building2 className="w-4 h-4 text-indigo-500" /> Property Information
          </h3>
          <InfoRow label="Property ID" value={property.id} mono />
          <InfoRow label="Property Type" value={property.type} />
          <InfoRow label="City" value={property.city} />
          <InfoRow label="Total Rooms" value={property.rooms} />
          <InfoRow label="Total Floors" value={property.floors} />
          <InfoRow label="Onboarding Status" value={
            <span className={`inline-flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-full ${
              property.onboarding_status === 'completed'
                ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                : 'bg-amber-50 text-amber-700 border border-amber-200'
            }`}>
              {property.onboarding_status === 'completed'
                ? <CheckCircle2 className="w-3 h-3" />
                : <Clock className="w-3 h-3" />}
              {property.onboarding_status}
            </span>
          } />
          {property.description && (
            <div className="mt-4 pt-4 border-t border-gray-50">
              <p className="text-xs font-semibold text-gray-500 mb-1">Description</p>
              <p className="text-sm text-gray-700 leading-relaxed">{property.description}</p>
            </div>
          )}
        </div>

        {/* Owner Info */}
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-6">
          <h3 className="text-sm font-semibold text-gray-900 mb-4 flex items-center gap-2">
            <Crown className="w-4 h-4 text-amber-500" /> Owner Information
          </h3>
          <InfoRow label="Full Name" value={property.owner} />
          <InfoRow label="Business" value={property.business} />
          <InfoRow label="Email" value={
            property.email
              ? <a href={`mailto:${property.email}`} className="text-indigo-600 hover:underline">{property.email}</a>
              : '—'
          } />
          <InfoRow label="Mobile" value={
            property.mobile
              ? <a href={`tel:${property.mobile}`} className="text-indigo-600 hover:underline">{property.mobile}</a>
              : '—'
          } />
        </div>
      </div>

      {/* Right: Subscription */}
      <div className="space-y-4">
        <div className={`bg-white rounded-xl border shadow-sm p-6 ${isSubActive ? 'border-emerald-200' : 'border-amber-200'}`}>
          <h3 className={`text-sm font-semibold mb-4 flex items-center gap-2 ${isSubActive ? 'text-emerald-700' : 'text-amber-700'}`}>
            <CreditCard className="w-4 h-4" /> Subscription
          </h3>
          {property.subscription?.plan ? (
            <div className="space-y-3">
              <div>
                <p className="text-xs text-gray-500">Current Plan</p>
                <p className="text-lg font-bold text-gray-900 mt-0.5">{property.subscription.plan}</p>
              </div>
              <div className={`flex items-center gap-2 py-2.5 px-3 rounded-lg border ${isSubActive ? 'bg-emerald-50 border-emerald-200' : 'bg-amber-50 border-amber-200'}`}>
                <div className={`w-2 h-2 rounded-full ${isSubActive ? 'bg-emerald-500' : 'bg-amber-500'}`} />
                <span className={`text-sm font-semibold ${isSubActive ? 'text-emerald-700' : 'text-amber-700'}`}>
                  {property.subscription.status}
                </span>
              </div>
              <div>
                <p className="text-xs text-gray-500 flex items-center gap-1">
                  <CalendarDays className="w-3 h-3" /> Valid Until
                </p>
                <p className="text-sm font-semibold text-gray-900 mt-0.5">
                  {property.subscription.expiry
                    ? new Date(property.subscription.expiry).toLocaleDateString(undefined, { year: 'numeric', month: 'long', day: 'numeric' })
                    : '—'}
                </p>
              </div>
            </div>
          ) : (
            <p className="text-sm text-gray-400 italic">No active subscription</p>
          )}
        </div>

        {/* Quick Actions */}
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
          <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">Quick Actions</h3>
          <div className="space-y-2">
            {[
              { label: 'View Rooms', icon: Bed, to: `/properties/${property.id}/rooms` },
              { label: 'Manage Subscription', icon: CreditCard, to: '/subscriptions/manage' },
            ].map(({ label, icon: Icon, to }) => (
              <Link
                key={label}
                to={to}
                className="flex items-center justify-between w-full px-3 py-2.5 rounded-lg hover:bg-gray-50 text-sm font-medium text-gray-700 border border-gray-100 transition group"
              >
                <span className="flex items-center gap-2">
                  <Icon className="w-4 h-4 text-gray-400" />
                  {label}
                </span>
                <ChevronRight className="w-3.5 h-3.5 text-gray-300 group-hover:text-gray-500 transition" />
              </Link>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

// ── Tab: Staff ─────────────────────────────────────────────────────────────────
function StaffTab({ propertyId, propertyName }) {
  const navigate = useNavigate();
  const [staff, setStaff] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [search, setSearch] = useState('');

  useEffect(() => {
    const load = async () => {
      try {
        setLoading(true);
        const data = await fetchAPI(`/properties/${propertyId}/staff`);
        setStaff(Array.isArray(data) ? data : []);
      } catch (e) {
        setError(e.message);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [propertyId]);

  const filtered = staff.filter(s =>
    [s.name, s.email, s.mobile_number, s.role_name, s.username]
      .filter(Boolean)
      .some(v => v.toLowerCase().includes(search.toLowerCase()))
  );

  return (
    <div className="space-y-4">
      {/* Staff Header */}
      <div className="flex items-center justify-between gap-4">
        <div className="relative flex-1">
          <Users className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder="Search staff..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400/30 focus:border-indigo-400 bg-white"
          />
        </div>
        <button
          onClick={() => navigate(`/properties/${propertyId}/users/create`)}
          className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold rounded-xl transition shadow-sm whitespace-nowrap"
        >
          <Plus className="w-4 h-4" />
          Create User
        </button>
      </div>

      {/* Staff Stats */}
      {!loading && !error && (
        <div className="flex gap-3 flex-wrap">
          {Object.entries(
            staff.reduce((acc, s) => {
              acc[s.role_code] = (acc[s.role_code] || 0) + 1;
              return acc;
            }, {})
          ).map(([code, count]) => {
            const style = ROLE_BADGE[code] || { bg: 'bg-gray-50', text: 'text-gray-600', border: 'border-gray-200' };
            return (
              <span key={code} className={`inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full border ${style.bg} ${style.text} ${style.border}`}>
                {count} {code}
              </span>
            );
          })}
        </div>
      )}

      {/* Staff Table */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-16">
            <Loader2 className="w-7 h-7 text-indigo-500 animate-spin" />
          </div>
        ) : error ? (
          <div className="py-12 text-center text-red-500 text-sm">{error}</div>
        ) : filtered.length === 0 ? (
          <div className="py-16 text-center">
            <Users className="w-10 h-10 text-gray-200 mx-auto mb-3" />
            <p className="text-gray-500 font-medium">{search ? 'No staff match search' : 'No staff assigned yet'}</p>
            {!search && (
              <button
                onClick={() => navigate(`/properties/${propertyId}/users/create`)}
                className="mt-4 inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-semibold rounded-lg hover:bg-indigo-700 transition"
              >
                <Plus className="w-4 h-4" /> Add First Staff Member
              </button>
            )}
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50/70 border-b border-gray-100">
              <tr>
                <th className="px-5 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Name</th>
                <th className="px-5 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Role</th>
                <th className="px-5 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Contact</th>
                <th className="px-5 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {filtered.map((s) => (
                <tr key={s.id} className="hover:bg-gray-50/60 transition-colors">
                  <td className="px-5 py-3.5">
                    <div className="flex items-center gap-2.5">
                      <div className="w-8 h-8 rounded-full bg-gradient-to-br from-indigo-400 to-purple-500 flex items-center justify-center text-white text-xs font-bold flex-shrink-0">
                        {s.name?.charAt(0)?.toUpperCase()}
                      </div>
                      <div>
                        <p className="text-sm font-semibold text-gray-900">{s.name}</p>
                        {s.username && <p className="text-xs text-gray-400">@{s.username}</p>}
                      </div>
                    </div>
                  </td>
                  <td className="px-5 py-3.5">
                    <RoleBadge roleCode={s.role_code} roleName={s.role_name} />
                    {s.is_primary_owner && (
                      <span className="ml-1.5 inline-flex items-center gap-0.5 text-xs text-amber-600 font-semibold">
                        <Crown className="w-3 h-3" /> Primary
                      </span>
                    )}
                  </td>
                  <td className="px-5 py-3.5">
                    <div className="text-xs space-y-0.5">
                      {s.email && <div className="flex items-center gap-1 text-gray-600"><Mail className="w-3 h-3 text-gray-400" />{s.email}</div>}
                      {s.mobile_number && <div className="flex items-center gap-1 text-gray-600"><Phone className="w-3 h-3 text-gray-400" />{s.mobile_number}</div>}
                    </div>
                  </td>
                  <td className="px-5 py-3.5">
                    <span className={`inline-flex items-center text-xs font-semibold px-2 py-0.5 rounded-full border ${
                      s.status === 'ACTIVE'
                        ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                        : 'bg-red-50 text-red-600 border-red-200'
                    }`}>
                      {s.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

// ── Tab: Devices ───────────────────────────────────────────────────────────────
function DevicesTab({ propertyId }) {
  const [devices, setDevices] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchAPI(`/devices?property_id=${propertyId}`)
      .then(d => setDevices(Array.isArray(d) ? d : d?.data || []))
      .catch(() => setDevices([]))
      .finally(() => setLoading(false));
  }, [propertyId]);

  if (loading) return <div className="flex justify-center py-16"><Loader2 className="w-7 h-7 text-indigo-500 animate-spin" /></div>;

  return (
    <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
      {devices.length === 0 ? (
        <div className="py-16 text-center">
          <Smartphone className="w-10 h-10 text-gray-200 mx-auto mb-3" />
          <p className="text-gray-500 font-medium">No devices registered</p>
          <p className="text-sm text-gray-400 mt-1">Devices are registered via the mobile app</p>
        </div>
      ) : (
        <table className="w-full">
          <thead className="bg-gray-50/70 border-b border-gray-100">
            <tr>
              <th className="px-5 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Device</th>
              <th className="px-5 py-3 text-left text-xs font-semibold text-gray-500 uppercase">OS</th>
              <th className="px-5 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {devices.map((d) => (
              <tr key={d.id} className="hover:bg-gray-50/60">
                <td className="px-5 py-3.5">
                  <div className="flex items-center gap-2">
                    <Smartphone className="w-4 h-4 text-gray-400" />
                    <div>
                      <p className="text-sm font-semibold text-gray-900">{d.device_name || 'Unnamed Device'}</p>
                      <p className="text-xs text-gray-400 font-mono">{d.device_uid?.substring(0, 16)}…</p>
                    </div>
                  </div>
                </td>
                <td className="px-5 py-3.5 text-sm text-gray-600 capitalize">{d.os_type || '—'}</td>
                <td className="px-5 py-3.5">
                  <span className={`inline-flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-full border ${
                    d.status === 'approved' || d.status === 'active'
                      ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                      : 'bg-amber-50 text-amber-600 border-amber-200'
                  }`}>
                    {d.status === 'approved' || d.status === 'active'
                      ? <Wifi className="w-3 h-3" />
                      : <WifiOff className="w-3 h-3" />}
                    {d.status}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}

// ── Tab: Audit Logs ────────────────────────────────────────────────────────────
function AuditTab({ propertyId }) {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchAPI(`/properties/${propertyId}/audit-logs?limit=30`)
      .then(d => setLogs(Array.isArray(d) ? d : []))
      .catch(() => setLogs([]))
      .finally(() => setLoading(false));
  }, [propertyId]);

  const ACTION_COLORS = {
    Created:    'bg-emerald-100 text-emerald-700',
    Updated:    'bg-blue-100 text-blue-700',
    Deleted:    'bg-red-100 text-red-700',
    user_create: 'bg-violet-100 text-violet-700',
    user_update: 'bg-blue-100 text-blue-700',
    user_deactivate: 'bg-red-100 text-red-700',
    credential_reset: 'bg-orange-100 text-orange-700',
  };

  if (loading) return <div className="flex justify-center py-16"><Loader2 className="w-7 h-7 text-indigo-500 animate-spin" /></div>;

  return (
    <div className="space-y-2">
      {logs.length === 0 ? (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm py-16 text-center">
          <ClipboardList className="w-10 h-10 text-gray-200 mx-auto mb-3" />
          <p className="text-gray-500 font-medium">No audit entries found</p>
        </div>
      ) : logs.map((log) => (
        <div key={log.log_id} className="bg-white rounded-xl border border-gray-100 shadow-sm px-5 py-3.5 flex items-start gap-4">
          <span className={`inline-flex items-center text-xs font-bold px-2 py-0.5 rounded-md mt-0.5 ${ACTION_COLORS[log.action_type] || 'bg-gray-100 text-gray-600'}`}>
            {log.action_type}
          </span>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium text-gray-900">
              {log.module_name && <span className="text-gray-500 font-normal">[{log.module_name}] </span>}
              {log.target_entity}
              {log.target_record_id && (
                <span className="font-mono text-xs text-gray-400 ml-2">#{log.target_record_id.substring(0, 8)}</span>
              )}
            </p>
            <p className="text-xs text-gray-400 mt-0.5">
              by <span className="font-medium text-gray-600">{log.user_name}</span>
              {log.timestamp && (
                <span className="ml-2">
                  · {new Date(log.timestamp).toLocaleString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })}
                </span>
              )}
              {log.ip_address && <span className="ml-2">· {log.ip_address}</span>}
            </p>
          </div>
        </div>
      ))}
    </div>
  );
}

// ── Tab: Subscription ──────────────────────────────────────────────────────────
function SubscriptionTab({ property }) {
  const sub = property.subscription;
  const isActive = sub?.status?.toLowerCase() === 'active';
  return (
    <div className="max-w-2xl">
      <div className={`bg-white rounded-xl border shadow-sm p-6 ${isActive ? 'border-emerald-200' : 'border-amber-200'}`}>
        <div className="flex items-center justify-between mb-6">
          <h3 className="font-semibold text-gray-900 flex items-center gap-2">
            <CreditCard className={`w-5 h-5 ${isActive ? 'text-emerald-600' : 'text-amber-600'}`} />
            Subscription Details
          </h3>
          <span className={`inline-flex items-center gap-1 text-xs font-bold px-2.5 py-1 rounded-full border ${
            isActive ? 'bg-emerald-50 text-emerald-700 border-emerald-200' : 'bg-amber-50 text-amber-700 border-amber-200'
          }`}>
            <div className={`w-1.5 h-1.5 rounded-full ${isActive ? 'bg-emerald-500' : 'bg-amber-500'}`} />
            {sub?.status || 'No Subscription'}
          </span>
        </div>

        {sub ? (
          <div className="space-y-4">
            <InfoRow label="Plan Name" value={sub.plan} />
            <InfoRow label="Status" value={sub.status} />
            <InfoRow label="Valid Until" value={
              sub.expiry
                ? new Date(sub.expiry).toLocaleDateString(undefined, { year: 'numeric', month: 'long', day: 'numeric' })
                : '—'
            } />
          </div>
        ) : (
          <div className="text-center py-8">
            <CreditCard className="w-10 h-10 text-gray-200 mx-auto mb-3" />
            <p className="text-gray-500 font-medium">No active subscription</p>
            <Link
              to="/subscriptions/manage"
              className="mt-4 inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-semibold rounded-lg hover:bg-indigo-700 transition"
            >
              Assign Subscription
            </Link>
          </div>
        )}
      </div>
    </div>
  );
}

// ── Tab: Rooms ─────────────────────────────────────────────────────────────────
function RoomsTab({ propertyId }) {
  const navigate = useNavigate();
  const [rooms, setRooms] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchAPI('/properties/rooms')
      .then(d => setRooms((Array.isArray(d) ? d : []).filter(r => r.resort_id === propertyId)))
      .catch(() => setRooms([]))
      .finally(() => setLoading(false));
  }, [propertyId]);

  if (loading) return <div className="flex justify-center py-16"><Loader2 className="w-7 h-7 text-indigo-500 animate-spin" /></div>;

  return (
    <div className="space-y-4">
      <div className="flex justify-end">
        <Link
          to={`/properties/${propertyId}/rooms`}
          className="inline-flex items-center gap-2 px-4 py-2 border border-gray-200 rounded-xl text-sm font-medium text-gray-700 hover:bg-gray-50 transition"
        >
          <Bed className="w-4 h-4" /> Manage Rooms
          <ChevronRight className="w-4 h-4" />
        </Link>
      </div>

      {rooms.length === 0 ? (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm py-16 text-center">
          <Bed className="w-10 h-10 text-gray-200 mx-auto mb-3" />
          <p className="text-gray-500 font-medium">No rooms configured</p>
          <Link to={`/properties/${propertyId}/rooms`} className="mt-3 inline-flex items-center gap-1 text-sm text-indigo-600 hover:underline">
            Add Rooms <ChevronRight className="w-3.5 h-3.5" />
          </Link>
        </div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
          {rooms.map((room) => (
            <div key={room.id} className="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
              <p className="text-sm font-bold text-gray-900">{room.room_number}</p>
              <p className="text-xs text-gray-500 mt-0.5">{room.type}</p>
              <div className="mt-2 flex items-center justify-between">
                <span className="text-xs font-semibold text-indigo-600">₹{Number(room.price).toLocaleString()}</span>
                <span className={`text-xs font-semibold px-1.5 py-0.5 rounded ${
                  room.status === 'vacant' ? 'bg-emerald-100 text-emerald-700' : 'bg-red-100 text-red-700'
                }`}>
                  {room.status}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

// ── Main PropertyDetails ────────────────────────────────────────────────────────
export default function PropertyDetails() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [property, setProperty] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [activeTab, setActiveTab] = useState('overview');

  useEffect(() => {
    const fetchProperty = async () => {
      try {
        setLoading(true);
        const data = await propertyService.getPropertyDetails(id);
        setProperty(data);
        setError(null);
      } catch (err) {
        setError(err.message || 'Failed to fetch property details.');
      } finally {
        setLoading(false);
      }
    };
    fetchProperty();
  }, [id]);

  if (loading) {
    return (
      <div className="flex justify-center items-center h-96">
        <Loader2 className="w-8 h-8 text-indigo-600 animate-spin" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6">
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl flex items-center gap-3">
          <AlertCircle className="w-5 h-5" />
          <p>{error}</p>
        </div>
      </div>
    );
  }

  if (!property) return null;

  const isActive = property.onboarding_status === 'completed';

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-start justify-between gap-4">
        <div className="flex items-start gap-3">
          <Link
            to="/properties"
            className="mt-1 p-2 hover:bg-gray-100 rounded-xl transition-colors text-gray-400 hover:text-gray-600"
          >
            <ArrowLeft className="w-5 h-5" />
          </Link>
          <div>
            <div className="flex items-center gap-2 flex-wrap">
              <h1 className="text-2xl font-bold text-gray-900">{property.name}</h1>
              <span className={`inline-flex items-center gap-1 text-xs font-semibold px-2.5 py-1 rounded-full border ${
                isActive
                  ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                  : 'bg-amber-50 text-amber-700 border-amber-200'
              }`}>
                {isActive ? <CheckCircle2 className="w-3 h-3" /> : <Clock className="w-3 h-3" />}
                {isActive ? 'Active' : 'Pending'}
              </span>
            </div>
            <p className="text-sm text-gray-500 mt-1 flex items-center gap-2">
              <Building2 className="w-3.5 h-3.5" />
              {property.business} · {property.type || 'Hotel'}
              {property.city && (
                <>
                  <span className="text-gray-300">·</span>
                  <MapPin className="w-3.5 h-3.5" />
                  {property.city}
                </>
              )}
            </p>
          </div>
        </div>

        {/* Action: Create User (quick access from header) */}
        <button
          onClick={() => navigate(`/properties/${id}/users/create`)}
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold rounded-xl shadow-sm transition whitespace-nowrap"
        >
          <Plus className="w-4 h-4" />
          Create User
        </button>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200 bg-white rounded-t-xl">
        <nav className="flex gap-0 overflow-x-auto px-2">
          {TABS.map((tab) => {
            const isSelected = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center gap-2 px-4 py-3.5 text-sm font-medium border-b-2 whitespace-nowrap transition-all ${
                  isSelected
                    ? 'border-indigo-600 text-indigo-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <tab.icon className="w-4 h-4" />
                {tab.label}
              </button>
            );
          })}
        </nav>
      </div>

      {/* Tab Content */}
      <div>
        {activeTab === 'overview'      && <OverviewTab property={property} />}
        {activeTab === 'staff'         && <StaffTab propertyId={id} propertyName={property.name} />}
        {activeTab === 'rooms'         && <RoomsTab propertyId={id} />}
        {activeTab === 'devices'       && <DevicesTab propertyId={id} />}
        {activeTab === 'subscription'  && <SubscriptionTab property={property} />}
        {activeTab === 'audit'         && <AuditTab propertyId={id} />}
      </div>
    </div>
  );
}
