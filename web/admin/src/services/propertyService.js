import { fetchAPI } from './api';

export const propertyService = {
  getAllProperties: async () => {
    return fetchAPI('/properties');
  },

  getDashboardKPIs: async () => {
    return fetchAPI('/properties/kpis');
  },

  getSuperAdminDashboardData: async () => {
    return fetchAPI('/properties/dashboard');
  },

  getPropertyDetails: async (id) => {
    return fetchAPI(`/properties/${id}`);
  },

  createProperty: async (data) => {
    return fetchAPI('/properties', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  updateProperty: async (id, data) => {
    return fetchAPI(`/properties/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data)
    });
  },

  deleteProperty: async (id) => {
    return fetchAPI(`/properties/${id}`, {
      method: 'DELETE'
    });
  }
};
