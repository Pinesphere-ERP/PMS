import { api } from "./api";
import { PortalMenuCategory, PortalFoodOrderCreate, PortalFoodOrderResponse } from "../types/api";

export class FoodAPI {
  static async getMenu(): Promise<PortalMenuCategory[]> {
    const res = await api.get<PortalMenuCategory[]>("/portal/food/menu");
    return res.data;
  }

  static async getOrderHistory(): Promise<PortalFoodOrderResponse[]> {
    const res = await api.get<PortalFoodOrderResponse[]>("/portal/food/orders");
    return res.data;
  }

  static async createOrder(payload: PortalFoodOrderCreate): Promise<{ status: string; task_id: string; order_total: number; message: string }> {
    const res = await api.post("/portal/food/orders", payload);
    return res.data;
  }
}
