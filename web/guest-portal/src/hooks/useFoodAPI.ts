import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { FoodAPI } from "@/lib/food-api";
import { PortalFoodOrderCreate } from "@/types/api";

export function useMenu() {
  return useQuery({
    queryKey: ["portal", "food", "menu"],
    queryFn: FoodAPI.getMenu,
    staleTime: 5 * 60 * 1000,
  });
}

export function useFoodOrders() {
  return useQuery({
    queryKey: ["portal", "food", "orders"],
    queryFn: FoodAPI.getOrderHistory,
    refetchInterval: 10 * 1000,
  });
}

export function useCreateFoodOrder() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: PortalFoodOrderCreate) => FoodAPI.createOrder(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["portal", "food", "orders"] });
      queryClient.invalidateQueries({ queryKey: ["portal", "folio-summary"] });
    },
  });
}
