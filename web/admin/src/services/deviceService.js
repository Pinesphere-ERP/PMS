import { fetchAPI } from './api';

export const deviceService = {
  getGlobalDevices: async () => {
    return fetchAPI('/devices');
  },

  getGlobalKPIs: async () => {
    return fetchAPI('/devices/kpis');
  },

  getDiagnostics: async () => {
    return fetchAPI('/devices/diagnostics');
  },

  getMyDevices: async () => {
    return fetchAPI('/devices/my');
  },

  approveDevice: async (id) => {
    return fetchAPI(`/devices/${id}/approve`, { method: 'POST' });
  },

  lockDevice: async (id) => {
    return fetchAPI(`/devices/${id}/lock`, { method: 'POST' });
  },

  unlockDevice: async (id) => {
    return fetchAPI(`/devices/${id}/unlock`, { method: 'POST' });
  },

  triggerSync: async (id) => {
    return fetchAPI(`/devices/${id}/sync`, { method: 'POST' });
  }
};
