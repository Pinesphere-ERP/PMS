import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { paymentsApi } from '../lib/payments-api';
import { PortalSecurePaymentRequest } from '../types/api';

export const useFolioSummary = () => {
  return useQuery({
    queryKey: ['folio', 'summary'],
    queryFn: paymentsApi.getFolioSummary,
  });
};

export const usePaymentHistory = () => {
  return useQuery({
    queryKey: ['folio', 'payments'],
    queryFn: paymentsApi.getPaymentHistory,
  });
};

export const useInvoices = () => {
  return useQuery({
    queryKey: ['folio', 'invoices'],
    queryFn: paymentsApi.getInvoices,
  });
};

export const usePayBalance = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: PortalSecurePaymentRequest) => paymentsApi.payBalance(payload),
    onSuccess: () => {
      // Invalidate to refresh balances and history
      queryClient.invalidateQueries({ queryKey: ['folio'] });
    },
  });
};
