"use client";

import { useCheckoutStatus } from "@/hooks/useCheckoutAPI";
import { Clock, Loader2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useEffect } from "react";

export default function CheckoutStatusPage() {
  const router = useRouter();
  const { data: status, isLoading } = useCheckoutStatus();

  useEffect(() => {
    if (status?.state === "ACTIVE") {
      router.replace("/checkout");
    } else if (status?.state === "COMPLETED") {
      router.replace("/checkout/complete");
    }
  }, [status?.state, router]);

  if (isLoading || status?.state !== "REQUESTED") {
    return (
      <div className="p-6 max-w-lg mx-auto flex justify-center items-center h-[50vh]">
        <Loader2 size={32} className="animate-spin text-indigo-500" />
      </div>
    );
  }

  return (
    <div className="p-6 pb-24 max-w-lg mx-auto flex flex-col justify-center items-center h-[80vh] text-center space-y-6">
      <div className="relative">
        <div className="w-24 h-24 bg-blue-500/20 rounded-full flex justify-center items-center animate-pulse">
          <Clock size={40} className="text-blue-400" />
        </div>
        <div className="absolute top-0 left-0 w-24 h-24 border-4 border-blue-500/30 rounded-full border-t-blue-500 animate-spin"></div>
      </div>
      
      <div>
        <h1 className="text-2xl font-bold text-white mb-2">Waiting for Staff</h1>
        <p className="text-gray-400 max-w-xs mx-auto">
          We have notified the front desk. They are finalizing your folio. This screen will update automatically.
        </p>
      </div>
    </div>
  );
}
