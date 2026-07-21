"use client";

import { useFolioSummary, usePayBalance } from "@/hooks/usePayments";
import { FileText, CreditCard, History, CheckCircle2 } from "lucide-react";
import { useAuthStore } from "@/store/useAuthStore";
import { PortalFolioItem } from "@/types/api";
import Link from "next/link";
import { useState } from "react";

export default function FolioPage() {
  const { capabilities } = useAuthStore();
  const { data: folio, isLoading, isError } = useFolioSummary();
  const payBalance = usePayBalance();
  const [payError, setPayError] = useState("");

  if (!capabilities?.can_download_invoice) {
    return (
      <div className="flex flex-col items-center justify-center h-full pt-20 px-6 text-center">
        <FileText size={48} className="text-gray-700 mb-4" />
        <h2 className="text-xl font-medium text-white mb-2">Invoice Not Available</h2>
        <p className="text-gray-400">
          Your folio is not currently available for viewing. It typically becomes available closer to checkout.
        </p>
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="flex justify-center items-center h-full pt-12">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="p-6 text-center text-gray-400 mt-12">
        <p>Failed to load folio details.</p>
      </div>
    );
  }

  const { total_charges, total_paid, balance_due, items } = folio || { total_charges: 0, total_paid: 0, balance_due: 0, items: [] };

  const handlePayNow = () => {
    setPayError("");
    payBalance.mutate(
      { mode: "card" }, // Mocking card payment for the portal
      {
        onSuccess: () => {
          alert("Payment processed successfully!");
        },
        onError: () => {
          setPayError("Payment failed. Please try again or contact the front desk.");
        }
      }
    );
  };

  return (
    <div className="p-6 max-w-lg mx-auto pb-24">
      <header className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-semibold text-white">My Folio</h1>
        <div className="flex gap-2">
          <Link href="/folio/history" className="flex items-center text-xs font-medium bg-gray-800 text-gray-300 hover:text-white px-3 py-1.5 rounded-full">
            <History size={14} className="mr-1" />
            History
          </Link>
          <Link href="/folio/invoices" className="flex items-center text-xs font-medium bg-blue-900/30 text-blue-400 hover:text-blue-300 px-3 py-1.5 rounded-full">
            <FileText size={14} className="mr-1" />
            Invoices
          </Link>
        </div>
      </header>

      {/* Summary Card */}
      <div className="bg-gradient-to-r from-gray-800 to-gray-900 rounded-xl p-6 border border-gray-700 mb-6 shadow-md">
        <div className="flex justify-between items-start">
          <div>
            <p className="text-gray-400 text-sm mb-1">Outstanding Balance</p>
            <p className="text-4xl font-bold text-white mb-6">
              ₹{balance_due?.toFixed(2) || "0.00"}
            </p>
          </div>
          {balance_due === 0 && (
            <div className="bg-green-900/30 text-green-400 text-xs px-2 py-1 rounded-md flex items-center gap-1 font-medium border border-green-800">
              <CheckCircle2 size={12} /> Paid in Full
            </div>
          )}
        </div>
        
        {balance_due > 0 && capabilities?.can_pay && (
          <div className="mb-6">
            <button 
              onClick={handlePayNow}
              disabled={payBalance.isPending}
              className="w-full flex justify-center items-center gap-2 bg-blue-600 hover:bg-blue-500 text-white font-medium py-3 rounded-xl transition-colors disabled:opacity-50"
            >
              {payBalance.isPending ? (
                 <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
              ) : (
                <>
                  <CreditCard size={18} />
                  Pay Now
                </>
              )}
            </button>
            {payError && <p className="text-red-400 text-xs mt-2 text-center">{payError}</p>}
          </div>
        )}

        <div className="grid grid-cols-2 gap-4 border-t border-gray-700 pt-4">
          <div>
            <p className="text-xs text-gray-500">Total Charges</p>
            <p className="font-medium text-gray-300">₹{total_charges?.toFixed(2) || "0.00"}</p>
          </div>
          <div>
            <p className="text-xs text-gray-500">Total Paid</p>
            <p className="font-medium text-green-400">₹{total_paid?.toFixed(2) || "0.00"}</p>
          </div>
        </div>
      </div>

      {/* Line Items */}
      <h3 className="text-lg font-medium text-gray-200 mb-4">Recent Charges</h3>
      <div className="space-y-3">
        {items && items.length > 0 ? (
          items.map((item: PortalFolioItem, idx: number) => (
            <div key={idx} className="bg-gray-800 p-4 rounded-lg flex justify-between items-center border border-gray-700">
              <div className="flex-1">
                <p className="text-gray-200 font-medium text-sm">{item.description}</p>
                <p className="text-gray-500 text-xs mt-1">{new Date(item.date).toLocaleString('en-US', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' })}</p>
              </div>
              <p className="text-white font-medium">₹{item.amount.toFixed(2)}</p>
            </div>
          ))
        ) : (
          <div className="text-center py-6 text-gray-500 text-sm">
            No charges recorded yet.
          </div>
        )}
      </div>
    </div>
  );
}
