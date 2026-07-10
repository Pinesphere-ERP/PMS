import { fetchAPI } from './api';

export const subscriptionService = {
  // Fetch all subscriptions
  getSubscriptions: () => {
    return fetchAPI('/subscriptions');
  },

  // Fetch subscription KPIs (total, active, expired, disabled, upgrades, downgrades)
  getKPIs: () => {
    return fetchAPI('/subscriptions/kpis');
  },

  // Enable or disable a property subscription
  toggleSubscriptionStatus: (propertyId, action) => {
    // action can be 'enable' or 'disable'
    return fetchAPI(`/subscriptions/${propertyId}/status`, {
      method: 'POST',
      body: JSON.stringify({ action })
    });
  },

  // Get General Subscription Dashboard Data
  getDashboardData: () => {
    return fetchAPI('/subscriptions/dashboard');
  },

  // Get Renewal Management Data
  getRenewalData: () => {
    return fetchAPI('/subscriptions/renewals');
  },

  // Change or upgrade plan
  updatePlan: (propertyId, newPlan) => {
    return fetchAPI(`/subscriptions/${propertyId}/plan`, {
      method: 'PUT',
      body: JSON.stringify({ plan: newPlan })
    });
  },

  // Generate new license key
  generateLicense: (propertyId) => {
    return fetchAPI(`/subscriptions/${propertyId}/license`, {
      method: 'POST'
    });
  }
};
