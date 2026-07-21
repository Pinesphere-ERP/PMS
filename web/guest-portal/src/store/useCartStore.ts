import { create } from "zustand";
import { PortalMenuItem } from "@/types/api";

export interface CartItem {
  menuItem: PortalMenuItem;
  quantity: number;
}

interface CartState {
  items: CartItem[];
  addItem: (menuItem: PortalMenuItem, quantity?: number) => void;
  removeItem: (itemId: string) => void;
  updateQuantity: (itemId: string, quantity: number) => void;
  clearCart: () => void;
  getTotalItems: () => number;
  getTotalPrice: () => number;
}

export const useCartStore = create<CartState>((set, get) => ({
  items: [],
  addItem: (menuItem, quantity = 1) => {
    set((state) => {
      const existing = state.items.find((i) => i.menuItem.id === menuItem.id);
      if (existing) {
        return {
          items: state.items.map((i) =>
            i.menuItem.id === menuItem.id
              ? { ...i, quantity: i.quantity + quantity }
              : i
          ),
        };
      }
      return { items: [...state.items, { menuItem, quantity }] };
    });
  },
  removeItem: (itemId) => {
    set((state) => ({
      items: state.items.filter((i) => i.menuItem.id !== itemId),
    }));
  },
  updateQuantity: (itemId, quantity) => {
    set((state) => {
      if (quantity <= 0) {
        return { items: state.items.filter((i) => i.menuItem.id !== itemId) };
      }
      return {
        items: state.items.map((i) =>
          i.menuItem.id === itemId ? { ...i, quantity } : i
        ),
      };
    });
  },
  clearCart: () => set({ items: [] }),
  getTotalItems: () => get().items.reduce((sum, item) => sum + item.quantity, 0),
  getTotalPrice: () =>
    get().items.reduce((sum, item) => sum + item.quantity * item.menuItem.price, 0),
}));
