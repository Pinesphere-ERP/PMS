import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';

export interface Capabilities {
  can_login: boolean;
  can_view_dashboard: boolean;
  can_request_service: boolean;
  can_pay: boolean;
  can_download_invoice: boolean;
  can_submit_feedback: boolean;
}

interface AuthState {
  token: string | null;
  guestName: string | null;
  bookingId: string | null;
  roomNumber: string | null;
  bookingReference: string | null;
  capabilities: Capabilities | null;
  isHydrated: boolean;
  
  // Actions
  login: (data: {
    access_token: string;
    guest_name: string;
    booking_id: string;
    room_number?: string | null;
    booking_reference?: string | null;
  }) => void;
  setCapabilities: (caps: Capabilities) => void;
  setHydrated: (state: boolean) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      guestName: null,
      bookingId: null,
      roomNumber: null,
      bookingReference: null,
      capabilities: null,
      isHydrated: false,

      login: (data) => set({
        token: data.access_token,
        guestName: data.guest_name,
        bookingId: data.booking_id,
        roomNumber: data.room_number || null,
        bookingReference: data.booking_reference || null,
      }),
      
      setCapabilities: (caps) => set({ capabilities: caps }),
      setHydrated: (state) => set({ isHydrated: state }),
      
      logout: () => set({
        token: null,
        guestName: null,
        bookingId: null,
        roomNumber: null,
        bookingReference: null,
        capabilities: null,
      }),
    }),
    {
      name: 'guest-portal-auth', // key in localStorage
      storage: createJSONStorage(() => localStorage),
      onRehydrateStorage: () => (state) => {
        state?.setHydrated(true);
      },
    }
  )
);
