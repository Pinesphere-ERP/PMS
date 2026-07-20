import { useState } from 'react';
import { X, Crown, User, Phone, Mail, Briefcase, Hash, Loader2, CheckCircle } from 'lucide-react';
import { ownerService } from '../../services/ownerService';

const FIELDS = [
  { key: 'full_name', label: 'Full Name', icon: User, type: 'text', required: true, placeholder: 'e.g. Rajesh Kumar' },
  { key: 'mobile_number', label: 'Mobile Number', icon: Phone, type: 'tel', required: true, placeholder: '+91 9999999999' },
  { key: 'email', label: 'Email Address', icon: Mail, type: 'email', required: true, placeholder: 'owner@company.com' },
  { key: 'designation', label: 'Designation', icon: Briefcase, type: 'text', required: false, placeholder: 'e.g. Managing Director' },
  { key: 'pan_number', label: 'PAN Number', icon: Hash, type: 'text', required: false, placeholder: 'ABCDE1234F' },
  { key: 'alternate_contact', label: 'Alternate Contact', icon: Phone, type: 'tel', required: false, placeholder: 'Backup mobile / landline' },
];

export default function CreateOwnerModal({ onClose, onCreated }) {
  const [form, setForm] = useState({
    full_name: '',
    mobile_number: '',
    email: '',
    designation: '',
    pan_number: '',
    alternate_contact: '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);

  const handleChange = (e) => {
    setForm((prev) => ({ ...prev, [e.target.name]: e.target.value }));
    setError(null);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      // Strip empty optional fields
      const payload = Object.fromEntries(
        Object.entries(form).filter(([_, v]) => v !== '')
      );
      await ownerService.createOwner(payload);
      setSuccess(true);
      setTimeout(() => {
        onCreated();
      }, 1200);
    } catch (err) {
      setError(err.message || 'Failed to create owner');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* Modal */}
      <div className="relative w-full max-w-lg bg-white rounded-2xl shadow-2xl overflow-hidden animate-fade-in">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-5 border-b border-gray-100 bg-gradient-to-r from-amber-50 to-orange-50">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center">
              <Crown className="w-5 h-5 text-amber-600" />
            </div>
            <div>
              <h2 className="text-base font-semibold text-gray-900">Create New Owner</h2>
              <p className="text-xs text-gray-500">Step 1 of the onboarding process</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-gray-100 text-gray-400 hover:text-gray-600 transition"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Body */}
        <form onSubmit={handleSubmit}>
          <div className="px-6 py-5 space-y-4 max-h-[60vh] overflow-y-auto">
            {/* Success State */}
            {success ? (
              <div className="flex flex-col items-center justify-center py-8 gap-3">
                <div className="w-16 h-16 rounded-full bg-emerald-50 border-2 border-emerald-200 flex items-center justify-center">
                  <CheckCircle className="w-8 h-8 text-emerald-500" />
                </div>
                <p className="font-semibold text-gray-900">Owner Created Successfully</p>
                <p className="text-sm text-gray-500">
                  You can now assign properties to this owner.
                </p>
              </div>
            ) : (
              <>
                {/* Info Banner */}
                <div className="bg-amber-50 border border-amber-200 rounded-xl px-4 py-3 text-xs text-amber-700">
                  <strong>Step 1:</strong> Create the Owner account first. Properties will be assigned to this Owner in the next step.
                </div>

                {/* Fields */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {FIELDS.map((field) => (
                    <div key={field.key} className={field.key === 'full_name' || field.key === 'email' ? 'sm:col-span-2' : ''}>
                      <label className="block text-xs font-semibold text-gray-600 mb-1.5">
                        {field.label}
                        {field.required && <span className="text-red-400 ml-0.5">*</span>}
                      </label>
                      <div className="relative">
                        <field.icon className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                        <input
                          type={field.type}
                          name={field.key}
                          value={form[field.key]}
                          onChange={handleChange}
                          required={field.required}
                          placeholder={field.placeholder}
                          className="w-full pl-9 pr-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-amber-400/30 focus:border-amber-400 transition bg-gray-50/50"
                        />
                      </div>
                    </div>
                  ))}
                </div>

                {/* Error */}
                {error && (
                  <div className="bg-red-50 border border-red-200 rounded-xl px-4 py-3 text-sm text-red-600">
                    {error}
                  </div>
                )}
              </>
            )}
          </div>

          {/* Footer */}
          {!success && (
            <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-gray-100 bg-gray-50/60">
              <button
                type="button"
                onClick={onClose}
                disabled={loading}
                className="px-4 py-2 text-sm font-medium text-gray-600 hover:text-gray-800 hover:bg-gray-100 rounded-lg transition"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={loading}
                className="inline-flex items-center gap-2 px-5 py-2 bg-amber-500 hover:bg-amber-600 text-white text-sm font-semibold rounded-xl transition disabled:opacity-60 shadow-sm"
              >
                {loading ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    Creating…
                  </>
                ) : (
                  <>
                    <Crown className="w-4 h-4" />
                    Create Owner
                  </>
                )}
              </button>
            </div>
          )}
        </form>
      </div>
    </div>
  );
}
