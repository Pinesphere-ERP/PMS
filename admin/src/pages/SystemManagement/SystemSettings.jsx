import { useState, useEffect } from 'react';
import {
  Settings,
  Save,
  Plus,
  Trash2,
  Loader2,
  AlertCircle,
  Search,
  RefreshCw,
  Shield,
} from 'lucide-react';
import { fetchAPI } from '../../services/api';

const defaultConfigs = [
  { config_key: 'MAX_ROOMS_PER_PROPERTY', config_value: '200', description: 'Maximum rooms allowed per property' },
  { config_key: 'MAX_DEVICES_PER_PROPERTY', config_value: '5', description: 'Default device limit per property' },
  { config_key: 'GRACE_PERIOD_DAYS', config_value: '5', description: 'Grace period before PMS UI lock' },
  { config_key: 'SMS_GATEWAY_ENDPOINT', config_value: '', description: 'Central SMS gateway URL' },
  { config_key: 'WHATSAPP_GATEWAY_ENDPOINT', config_value: '', description: 'Central WhatsApp gateway URL' },
];

export default function SystemSettings() {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  const [configs, setConfigs] = useState([]);
  const [search, setSearch] = useState('');
  const [editingId, setEditingId] = useState(null);
  const [editValue, setEditValue] = useState('');
  const [showAddForm, setShowAddForm] = useState(false);
  const [newConfig, setNewConfig] = useState({ config_key: '', config_value: '', description: '' });

  const fetchConfigs = async () => {
    try {
      setLoading(true);
      setError(null);
      const endpoint = search
        ? `/settings/system?search=${encodeURIComponent(search)}`
        : '/settings/system';
      const data = await fetchAPI(endpoint);
      setConfigs(data.items || []);
    } catch (err) {
      setError(err.message);
      setConfigs(defaultConfigs.map((c, i) => ({ ...c, id: `fallback-${i}`, created_at: new Date().toISOString() })));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchConfigs(); }, []);

  useEffect(() => {
    const timer = setTimeout(() => fetchConfigs(), 300);
    return () => clearTimeout(timer);
  }, [search]);

  const handleSave = async (config) => {
    try {
      setSaving(true);
      setSuccess(null);
      const isLocal = String(config.id).startsWith('fallback-');
      const method = isLocal ? 'POST' : 'PATCH';
      const endpoint = isLocal
        ? '/settings/system'
        : `/settings/system/${config.id}`;
      const body = isLocal
        ? { config_key: config.config_key, config_value: editValue, description: config.description }
        : { config_value: editValue, description: config.description };

      await fetchAPI(endpoint, {
        method,
        body: JSON.stringify(body),
      });

      setSuccess(`"${config.config_key}" updated successfully`);
      setEditingId(null);
      fetchConfigs();
    } catch (err) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleAdd = async () => {
    if (!newConfig.config_key || !newConfig.config_value) return;
    try {
      setSaving(true);
      setError(null);
      await fetchAPI('/settings/system', {
        method: 'POST',
        body: JSON.stringify(newConfig),
      });
      setSuccess(`"${newConfig.config_key}" created`);
      setNewConfig({ config_key: '', config_value: '', description: '' });
      setShowAddForm(false);
      fetchConfigs();
    } catch (err) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (config) => {
    if (!confirm(`Delete "${config.config_key}"? This cannot be undone.`)) return;
    try {
      const isLocal = String(config.id).startsWith('fallback-');
      if (isLocal) return;
      await fetchAPI(`/settings/system/${config.id}`, { method: 'DELETE' });
      setSuccess(`"${config.config_key}" deleted`);
      fetchConfigs();
    } catch (err) {
      setError(err.message);
    }
  };

  return (
    <div className="space-y-6 animate-slide-up">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <Shield className="h-6 w-6 text-pine" />
            System Configuration
          </h1>
          <p className="text-sm text-gray-500 mt-1">
            Global SaaS settings managed by Super Admin. These apply across all properties.
          </p>
        </div>
        <div className="flex space-x-2">
          <button onClick={fetchConfigs} className="saas-button-secondary flex items-center gap-2">
            <RefreshCw className="h-4 w-4" /> Refresh
          </button>
          <button onClick={() => setShowAddForm(!showAddForm)} className="saas-button-primary flex items-center gap-2">
            <Plus className="h-4 w-4" /> Add Config
          </button>
        </div>
      </div>

      {success && (
        <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg text-sm flex items-center gap-2">
          <Save className="h-4 w-4" /> {success}
        </div>
      )}
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm flex items-center gap-2">
          <AlertCircle className="h-4 w-4" /> {error}
        </div>
      )}

      {showAddForm && (
        <div className="saas-card p-6">
          <h3 className="text-sm font-semibold text-gray-700 uppercase tracking-wider mb-4">New Configuration</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <input
              type="text"
              placeholder="CONFIG_KEY"
              value={newConfig.config_key}
              onChange={(e) => setNewConfig({ ...newConfig, config_key: e.target.value.toUpperCase() })}
              className="saas-input font-mono text-sm"
            />
            <input
              type="text"
              placeholder="Value"
              value={newConfig.config_value}
              onChange={(e) => setNewConfig({ ...newConfig, config_value: e.target.value })}
              className="saas-input"
            />
            <input
              type="text"
              placeholder="Description (optional)"
              value={newConfig.description}
              onChange={(e) => setNewConfig({ ...newConfig, description: e.target.value })}
              className="saas-input"
            />
          </div>
          <div className="flex justify-end gap-2 mt-4">
            <button onClick={() => setShowAddForm(false)} className="saas-button-secondary text-sm">Cancel</button>
            <button onClick={handleAdd} disabled={saving} className="saas-button-primary text-sm flex items-center gap-1">
              {saving ? <Loader2 className="h-3 w-3 animate-spin" /> : <Plus className="h-3 w-3" />}
              Create
            </button>
          </div>
        </div>
      )}

      <div className="relative">
        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <Search className="h-4 w-4 text-gray-400" />
        </div>
        <input
          type="text"
          placeholder="Search configurations..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="saas-input pl-10 w-full md:w-96"
        />
      </div>

      {loading ? (
        <div className="flex justify-center items-center h-48">
          <Loader2 className="w-6 h-6 text-pine animate-spin" />
          <span className="ml-3 text-gray-500">Loading configurations...</span>
        </div>
      ) : (
        <div className="saas-card overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Key</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Value</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Description</th>
                <th className="px-6 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-100">
              {configs.map((config) => (
                <tr key={config.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-6 py-4">
                    <span className="text-sm font-mono font-semibold text-gray-900">{config.config_key}</span>
                  </td>
                  <td className="px-6 py-4">
                    {editingId === config.id ? (
                      <input
                        type="text"
                        value={editValue}
                        onChange={(e) => setEditValue(e.target.value)}
                        className="saas-input text-sm py-1 w-full max-w-xs"
                        autoFocus
                      />
                    ) : (
                      <span className="text-sm text-gray-700 bg-gray-100 px-2 py-1 rounded font-mono">
                        {config.config_value || <span className="text-gray-400 italic">empty</span>}
                      </span>
                    )}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-500 max-w-xs truncate">
                    {config.description}
                  </td>
                  <td className="px-6 py-4 text-right space-x-2">
                    {editingId === config.id ? (
                      <>
                        <button
                          onClick={() => handleSave(config)}
                          disabled={saving}
                          className="text-green-600 hover:text-green-800 text-sm font-medium"
                        >
                          {saving ? <Loader2 className="h-4 w-4 animate-spin inline" /> : 'Save'}
                        </button>
                        <button
                          onClick={() => setEditingId(null)}
                          className="text-gray-500 hover:text-gray-700 text-sm font-medium"
                        >
                          Cancel
                        </button>
                      </>
                    ) : (
                      <>
                        <button
                          onClick={() => { setEditingId(config.id); setEditValue(config.config_value); }}
                          className="text-pine hover:text-pine-dark text-sm font-medium"
                        >
                          Edit
                        </button>
                        <button
                          onClick={() => handleDelete(config)}
                          className="text-red-500 hover:text-red-700"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </>
                    )}
                  </td>
                </tr>
              ))}
              {configs.length === 0 && (
                <tr>
                  <td colSpan="4" className="px-6 py-12 text-center text-gray-500">
                    <Settings className="h-8 w-8 mx-auto mb-2 text-gray-300" />
                    No configurations found
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
