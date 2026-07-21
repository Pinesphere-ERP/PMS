import { useState, useEffect } from 'react';
import { subscriptionService } from '../../services/subscriptionService';
import { 
  Plus, Search, Edit2, Trash2, X, Loader2, AlertCircle, CheckCircle2, ArrowLeft 
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';

export default function SubscriptionPlans() {
  const [plans, setPlans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const navigate = useNavigate();
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingPlan, setEditingPlan] = useState(null);
  
  const [planForm, setPlanForm] = useState({ name: '', features: '', amount: '', duration: '', status: 'Active' });

  const loadPlans = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await subscriptionService.getSubscriptionPlans();
      setPlans(response.data || []);
    } catch (err) {
      setError(err.message || 'Failed to load plans');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadPlans();
  }, []);

  const openCreateModal = () => {
    setEditingPlan(null);
    setPlanForm({ name: '', features: '', amount: '', duration: '1', status: 'Active' });
    setIsModalOpen(true);
  };

  const openEditModal = (plan) => {
    setEditingPlan(plan);
    setPlanForm({ 
      name: plan.name, 
      features: plan.features || '', 
      amount: plan.amount, 
      duration: plan.duration || '1',
      status: plan.status || 'Active'
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this plan?')) return;
    try {
      await subscriptionService.deleteSubscriptionPlan(id);
      await loadPlans();
    } catch (err) {
      alert(`Failed to delete plan: ${err.message}`);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        ...planForm,
        amount: parseFloat(String(planForm.amount).replace(/[^0-9.]/g, '')),
        duration: parseInt(planForm.duration, 10)
      };

      if (editingPlan) {
        await subscriptionService.updateSubscriptionPlan(editingPlan.id, payload);
      } else {
        await subscriptionService.createSubscriptionPlan(payload);
      }
      setIsModalOpen(false);
      await loadPlans();
    } catch (err) {
      alert(`Failed to save plan: ${err.message}`);
    }
  };

  return (
    <div className="space-y-6 animate-slide-up relative pb-20">
      <div className="flex items-center gap-4 mb-4">
        <button 
          onClick={() => navigate('/subscriptions/dashboard')}
          className="p-2 hover:bg-gray-100 rounded-full transition-colors"
          title="Back to Dashboard"
        >
          <ArrowLeft className="w-5 h-5 text-gray-600" />
        </button>
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 tracking-tight">Subscription Plans</h1>
          <p className="text-sm text-gray-500 mt-1">Manage subscription packages, pricing, and features available to properties.</p>
        </div>
      </div>
      
      <div className="flex justify-end items-center">
        <button className="saas-button-primary flex items-center" onClick={openCreateModal}>
          <Plus className="w-4 h-4 mr-2" />
          Create New Plan
        </button>
      </div>

      <div className="saas-card overflow-hidden">
        <div className="overflow-x-auto min-h-[300px] relative">
          {loading ? (
            <div className="absolute inset-0 flex flex-col items-center justify-center bg-white/80 z-10">
              <Loader2 className="h-8 w-8 text-pine animate-spin mb-2" />
              <p className="text-gray-500 text-sm">Loading plans...</p>
            </div>
          ) : error ? (
            <div className="absolute inset-0 flex flex-col items-center justify-center bg-white/80 z-10">
              <AlertCircle className="h-8 w-8 text-red-500 mb-2" />
              <p className="text-gray-800 text-sm font-medium">Failed to load data</p>
              <p className="text-gray-500 text-xs mt-1 max-w-sm text-center">{error}</p>
            </div>
          ) : plans.length === 0 ? (
            <div className="absolute inset-0 flex flex-col items-center justify-center bg-white/80 z-10">
              <p className="text-gray-500 text-sm">No subscription plans found</p>
            </div>
          ) : null}
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th scope="col" className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Plan Name</th>
                <th scope="col" className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Features</th>
                <th scope="col" className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Amount (₹)</th>
                <th scope="col" className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Duration</th>
                <th scope="col" className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
                <th scope="col" className="relative px-4 py-3"><span className="sr-only">Actions</span></th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {plans.map((plan) => (
                <tr key={plan.id} className="hover:bg-gray-50/50 transition-colors">
                  <td className="px-4 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{plan.name}</div>
                  </td>
                  <td className="px-4 py-4">
                    <div className="text-sm text-gray-500 line-clamp-2 max-w-xs">{plan.features || '—'}</div>
                  </td>
                  <td className="px-4 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">₹{parseFloat(plan.amount).toFixed(2)}</div>
                  </td>
                  <td className="px-4 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">{plan.duration} Month(s)</div>
                  </td>
                  <td className="px-4 py-4 whitespace-nowrap">
                    <span className={`status-badge ${plan.status === 'Active' ? 'status-active' : 'bg-gray-100 text-gray-800'}`}>
                      {plan.status}
                    </span>
                  </td>
                  <td className="px-4 py-4 whitespace-nowrap text-right text-sm font-medium flex justify-end gap-2">
                    <button 
                      onClick={() => openEditModal(plan)}
                      className="p-1.5 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-md transition-colors"
                      title="Edit Plan"
                    >
                      <Edit2 className="w-4 h-4" />
                    </button>
                    <button 
                      onClick={() => handleDelete(plan.id)}
                      className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-md transition-colors"
                      title="Delete Plan"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Create/Edit Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-md p-6">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-semibold text-gray-900">
                {editingPlan ? 'Edit Subscription Plan' : 'Create Subscription Plan'}
              </h2>
              <button onClick={() => setIsModalOpen(false)} className="text-gray-500 hover:text-gray-700">
                <X className="w-5 h-5" />
              </button>
            </div>
            
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Plan Name</label>
                <input 
                  type="text"
                  required
                  className="saas-input w-full"
                  placeholder="e.g. Premium Plan"
                  value={planForm.name}
                  onChange={(e) => setPlanForm({...planForm, name: e.target.value})}
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Features Description</label>
                <textarea 
                  required
                  className="saas-input w-full min-h-[100px]"
                  placeholder="Describe the plan features..."
                  value={planForm.features}
                  onChange={(e) => setPlanForm({...planForm, features: e.target.value})}
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Amount (INR)</label>
                  <div className="relative">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 font-medium">₹</span>
                    <input 
                      type="number"
                      required
                      min="0"
                      step="0.01"
                      className="saas-input w-full pl-8"
                      placeholder="0.00"
                      value={planForm.amount}
                      onChange={(e) => setPlanForm({...planForm, amount: e.target.value})}
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Duration (Months)</label>
                  <input 
                    type="number"
                    required
                    min="1"
                    step="1"
                    className="saas-input w-full"
                    placeholder="1, 6, 12"
                    value={planForm.duration}
                    onChange={(e) => setPlanForm({...planForm, duration: e.target.value})}
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Status</label>
                <select 
                  className="saas-input w-full"
                  value={planForm.status}
                  onChange={(e) => setPlanForm({...planForm, status: e.target.value})}
                >
                  <option value="Active">Active</option>
                  <option value="Inactive">Inactive</option>
                </select>
              </div>

              <div className="flex justify-end gap-3 mt-6">
                <button 
                  type="button" 
                  onClick={() => setIsModalOpen(false)}
                  className="saas-button-secondary"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="saas-button-primary"
                >
                  {editingPlan ? 'Save Changes' : 'Create Plan'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
