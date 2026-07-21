import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { PortalCheckoutStatusResponse } from "@/types/api";

export function useCheckoutStatus() {
  return useQuery({
    queryKey: ["portal", "checkout", "status"],
    queryFn: async () => {
      const res = await api.get<PortalCheckoutStatusResponse>("/portal/checkout/status");
      return res.data;
    },
    refetchInterval: (query) => {
      // Poll faster if we are waiting for staff approval
      return query.state.data?.state === "REQUESTED" ? 5000 : 30000;
    },
  });
}

export function useRequestCheckout() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async () => {
      const res = await api.post("/portal/checkout/request");
      return res.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["portal", "checkout", "status"] });
    },
  });
}
