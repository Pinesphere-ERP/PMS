"use client";

import { useCheckoutStatus } from "@/hooks/useCheckoutAPI";
import { CheckCircle2, MessageSquare, CalendarDays, Loader2, Clock } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { useAuthStore } from "@/store/useAuthStore";

export default function CheckoutCompletePage() {
  const router = useRouter();
  const { data: status, isLoading } = useCheckoutStatus();
  const logout = useAuthStore(state => state.logout);
  const [timeLeft, setTimeLeft] = useState<string>("");

  useEffect(() => {
    if (status?.state === "ACTIVE") {
      router.replace("/checkout");
    } else if (status?.state === "REQUESTED") {
      router.replace("/checkout/status");
    } else if (status?.state === "REVOKED") {
      logout();
    }
  }, [status?.state, router, logout]);

  useEffect(() => {
    if (!status?.grace_period_ends_at) return;

    const end = new Date(status.grace_period_ends_at).getTime();

    const updateTimer = () => {
      const now = new Date().getTime();
      const distance = end - now;

      if (distance < 0) {
        logout();
        return;
      }

      const hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
      const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
      const seconds = Math.floor((distance % (1000 * 60)) / 1000);

      setTimeLeft(`${hours}h ${minutes}m ${seconds}s`);
    };

    updateTimer();
    const interval = setInterval(updateTimer, 1000);
    return () => clearInterval(interval);
  }, [status?.grace_period_ends_at, logout]);

  if (isLoading || status?.state !== "COMPLETED") {
    return (
      <div className="p-6 max-w-lg mx-auto flex justify-center items-center h-[50vh]">
        <Loader2 size={32} className="animate-spin text-indigo-500" />
      </div>
    );
  }

  return (
    <div className="p-6 pb-24 max-w-lg mx-auto space-y-8">
      <div className="flex flex-col items-center text-center mt-8">
        <div className="w-20 h-20 bg-green-500/20 rounded-full flex justify-center items-center mb-6">
          <CheckCircle2 size={40} className="text-green-400" />
        </div>
        <h1 className="text-3xl font-bold text-white mb-2">Checkout Complete</h1>
        <p className="text-gray-400">
          Thank you for staying with us! Your checkout has been processed successfully.
        </p>
      </div>

      <div className="bg-gray-800 rounded-xl p-6 border border-gray-700">
        <h2 className="text-sm font-semibold text-gray-400 uppercase tracking-wider mb-4 text-center">
          Final Balance
        </h2>
        <p className="text-4xl font-bold text-white text-center mb-6">
          ${status.balance.toFixed(2)}
        </p>
        
        <div className="grid grid-cols-2 gap-3">
          <Link href="/folio" className="bg-gray-750 hover:bg-gray-700 rounded-lg p-4 flex flex-col items-center transition border border-gray-700">
            <CalendarDays size={20} className="text-orange-400 mb-2" />
            <span className="text-sm font-medium text-white text-center">View Invoice</span>
          </Link>
          <Link href="/feedback/new" className="bg-gray-750 hover:bg-gray-700 rounded-lg p-4 flex flex-col items-center transition border border-gray-700">
            <MessageSquare size={20} className="text-pink-400 mb-2" />
            <span className="text-sm font-medium text-white text-center">Rate Stay</span>
          </Link>
        </div>
      </div>

      <div className="bg-yellow-900/20 border border-yellow-900/50 rounded-xl p-4 flex gap-3 items-start">
        <Clock className="text-yellow-400 shrink-0 mt-0.5" size={20} />
        <div>
          <h3 className="text-sm font-medium text-yellow-400 mb-1">Access Expiring Soon</h3>
          <p className="text-sm text-yellow-200/70 mb-2">
            Your access to the portal will be revoked automatically in:
          </p>
          <p className="font-mono font-bold text-lg text-yellow-300">
            {timeLeft}
          </p>
        </div>
      </div>
    </div>
  );
}
