import { api } from './api';
import { 
  PortalServiceCatalogItem, 
  PortalServiceResponse, 
  PortalServiceCreate 
} from '../types/api';

export const servicesApi = {
  getCatalog: async (): Promise<PortalServiceCatalogItem[]> => {
    const response = await api.get('/portal/services/catalog');
    return response.data;
  },

  getHistory: async (): Promise<PortalServiceResponse[]> => {
    const response = await api.get('/portal/services');
    return response.data;
  },

  createRequest: async (payload: PortalServiceCreate): Promise<PortalServiceResponse> => {
    const response = await api.post('/portal/services', payload);
    return response.data;
  },

  cancelRequest: async (taskId: string): Promise<PortalServiceResponse> => {
    const response = await api.patch(`/portal/services/${taskId}/cancel`);
    return response.data;
  }
};
