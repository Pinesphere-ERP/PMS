import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { servicesApi } from '../lib/services-api';
import { PortalServiceCreate } from '../types/api';

export const useServiceCatalog = () => {
  return useQuery({
    queryKey: ['services', 'catalog'],
    queryFn: servicesApi.getCatalog,
    staleTime: 1000 * 60 * 60, // 1 hour
  });
};

export const useServiceHistory = () => {
  return useQuery({
    queryKey: ['services', 'history'],
    queryFn: servicesApi.getHistory,
  });
};

export const useCreateService = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: PortalServiceCreate) => servicesApi.createRequest(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['services', 'history'] });
    },
  });
};

export const useCancelService = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (taskId: string) => servicesApi.cancelRequest(taskId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['services', 'history'] });
    },
  });
};
