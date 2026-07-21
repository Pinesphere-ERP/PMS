"use client";

import { useEffect } from "react";
import { useRouter, usePathname } from "next/navigation";
import { useAuthStore } from "@/store/useAuthStore";
import { useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";

export default function AuthGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const { token, isHydrated } = useAuthStore();

  if (!isHydrated) {
    return null; // Avoid rendering until Zustand is loaded from localStorage
  }

  useEffect(() => {
    if (isHydrated && !token && typeof window !== "undefined") {
      router.push("/login");
    }
  }, [isHydrated, token, router]);

  if (!isHydrated || !token) {
    return null; // Avoid rendering until Zustand is loaded and verified
  }

  return <GuardLogic>{children}</GuardLogic>;
}

function GuardLogic({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const { logout, setCapabilities } = useAuthStore();

  const { data, isLoading, isError } = useQuery({
    queryKey: ["portalMe"],
    queryFn: async () => {
      // First fetch capabilities because the API contract separates them
      const capsRes = await api.get("/portal/capabilities");
      const meRes = await api.get("/portal/me");
      
      return { capabilities: capsRes.data, me: meRes.data };
    },
    staleTime: 60 * 1000,
  });

  useEffect(() => {
    if (data?.capabilities) {
      setCapabilities(data.capabilities);
    }
  }, [data, setCapabilities]);

  useEffect(() => {
    if (isError) {
      logout();
      if (typeof window !== "undefined") {
        router.push("/login");
      }
    }
  }, [isError, logout, router]);

  if (isError) {
    return null;
  }

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  // Capability check
  if (!data?.capabilities?.can_view_dashboard) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center p-4">
        <div className="bg-gray-800 p-6 rounded-lg border border-gray-700 text-center max-w-sm">
          <h3 className="text-xl font-semibold text-white mb-2">Access Expired</h3>
          <p className="text-gray-400 text-sm mb-4">
            Your stay has ended and access to the portal is no longer available.
          </p>
          <button
            onClick={() => {
              logout();
              router.push("/login");
            }}
            className="w-full py-2 px-4 bg-gray-700 hover:bg-gray-600 text-white rounded transition-colors"
          >
            Return to Login
          </button>
        </div>
      </div>
    );
  }

  // Strict routing enforcement for Post-Checkout Grace Period
  const isPostCheckout = data?.capabilities ? (!data.capabilities.can_request_service && data.capabilities.can_view_dashboard) : false;
  
  useEffect(() => {
    if (isPostCheckout) {
      const allowedRoutes = [
        "/checkout/complete",
        "/feedback",
        "/feedback/new",
        "/feedback/complaint",
        "/feedback/history",
        "/folio",
        "/folio/history",
        "/dashboard"
      ];
      if (!allowedRoutes.includes(pathname) && typeof window !== "undefined") {
        router.replace("/checkout/complete");
      }
    }
  }, [isPostCheckout, pathname, router]);

  if (isPostCheckout) {
    const allowedRoutes = [
        "/checkout/complete",
        "/feedback",
        "/feedback/new",
        "/feedback/complaint",
        "/feedback/history",
        "/folio",
        "/folio/history",
        "/dashboard"
    ];
    if (!allowedRoutes.includes(pathname)) {
      return null;
    }
  }

  return <>{children}</>;
}
