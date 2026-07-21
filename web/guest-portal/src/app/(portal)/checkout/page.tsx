"use client";

import { useCheckoutStatus, useRequestCheckout } from "@/hooks/useCheckoutAPI";
import { ArrowLeft, CreditCard, LogOut, Loader2, AlertCircle } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect } from "react";

export default function PreCheckoutPage() {
  const router = useRouter();
  const { data: status, isLoading } = useCheckoutStatus();
  const { mutate: requestCheckout, isPending } = useRequestCheckout();

  useEffect(() => {
    if (status?.state === "REQUESTED") {
      router.replace("/checkout/status");
    } else if (status?.state === "COMPLETED") {
      router.replace("/checkout/complete");
    }
  }, [status?.state, router]);

  if (isLoading || status?.state !== "ACTIVE") {
    return (
      <div className="p-6 max-w-lg mx-auto flex justify-center items-center h-[50vh]">
        <Loader2 size={32} className="animate-spin text-indigo-500" />
      </div>
    );
  }

  const handleCheckout = () => {
    requestCheckout(undefined, {
      onSuccess: () => {
        router.push("/checkout/status");
      }
    });
  };

  return (
    <div className="p-6 pb-24 max-w-lg mx-auto">
      <header className="flex items-center gap-3 mb-8">
        <Link href="/dashboard" className="p-2 -ml-2 text-gray-400 hover:text-white transition">
          <ArrowLeft size={20} />
        </Link>
        <h1 className="text-2xl font-semibold text-white">Checkout</h1>
      </header>

      <div className="bg-gray-800 rounded-xl p-6 border border-gray-700 mb-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-gray-300 font-medium">Estimated Balance</h2>
          <CreditCard size={20} className="text-gray-400" />
        </div>
        <p className="text-3xl font-bold text-white mb-2">
          ${status.balance.toFixed(2)}
        </p>
        <p className="text-sm text-gray-400">
          This balance is estimated and may change based on final room inspections or late charges.
        </p>
      </div>

      <div className="bg-blue-900/20 border border-blue-900/50 rounded-xl p-4 mb-8 flex gap-3">
        <AlertCircle className="text-blue-400 shrink-0 mt-0.5" size={20} />
        <div className="text-sm text-blue-200 space-y-1">
          <p>By requesting checkout, you notify the front desk to finalize your stay.</p>
          <p>Please leave your room keys at the reception.</p>
        </div>
      </div>

      <button
        onClick={handleCheckout}
        disabled={isPending}
        className="w-full bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 text-white font-semibold py-4 rounded-xl shadow-lg flex items-center justify-center gap-2 transition"
      >
        {isPending ? (
          <>
            <Loader2 size={20} className="animate-spin" />
            Requesting...
          </>
        ) : (
          <>
            <LogOut size={20} />
            Request Express Checkout
          </>
        )}
      </button>
    </div>
  );
}
