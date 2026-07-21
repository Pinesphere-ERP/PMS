import { api } from './api';
import { 
  PortalFolioSummaryResponse, 
  PortalSecurePaymentRequest, 
  PortalPaymentResponse, 
  PortalInvoiceResponse 
} from '../types/api';

export const paymentsApi = {
  getFolioSummary: async (): Promise<PortalFolioSummaryResponse> => {
    const response = await api.get('/portal/folio-summary');
    return response.data;
  },

  getPaymentHistory: async (): Promise<PortalPaymentResponse[]> => {
    const response = await api.get('/portal/payments');
    return response.data;
  },

  getInvoices: async (): Promise<PortalInvoiceResponse[]> => {
    const response = await api.get('/portal/invoices');
    return response.data;
  },

  payBalance: async (payload: PortalSecurePaymentRequest): Promise<{ status: string; payment_id: string; amount: number; mode: string; message: string }> => {
    const response = await api.post('/portal/pay', payload);
    return response.data;
  }
};
