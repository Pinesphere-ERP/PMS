"use client";

import { usePaymentHistory } from "@/hooks/usePayments";
import { ArrowLeft, CheckCircle2, Clock, XCircle, CreditCard, AlertCircle } from "lucide-react";
import Link from "next/link";

const StatusStyles: Record<string, { bg: string, text: string, icon: React.ElementType, label: string }> = {
  pending: { bg: "bg-yellow-900/30", text: "text-yellow-400", icon: Clock, label: "Pending" },
  completed: { bg: "bg-green-900/30", text: "text-green-400", icon: CheckCircle2, label: "Completed" },
  failed: { bg: "bg-red-900/30", text: "text-red-400", icon: XCircle, label: "Failed" },
  refunded: { bg: "bg-gray-800", text: "text-gray-400", icon: XCircle, label: "Refunded" },
};

export default function PaymentHistoryPage() {
  const { data: history, isLoading, isError } = usePaymentHistory();

  if (isLoading) {
    return (
      <div className="p-6 max-w-lg mx-auto pb-24">
        <div className="h-8 w-1/3 bg-gray-800 rounded mb-6 animate-pulse"></div>
        <div className="space-y-4">
          {[1, 2].map((i) => (
            <div key={i} className="h-24 bg-gray-800 rounded-xl animate-pulse"></div>
          ))}
        </div>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="p-6 max-w-lg mx-auto pb-24 text-center mt-20">
        <AlertCircle size={48} className="text-red-500 mb-4 mx-auto" />
        <h2 className="text-xl font-semibold text-white mb-2">Could not load history</h2>
        <button 
          onClick={() => window.location.reload()}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg mt-4"
        >
          Retry
        </button>
      </div>
    );
  }

  const payments = history || [];

  return (
    <div className="p-6 pb-24 max-w-lg mx-auto">
      <header className="flex items-center gap-3 mb-8">
        <Link href="/folio" className="p-2 -ml-2 text-gray-400 hover:text-white transition-colors">
          <ArrowLeft size={20} />
        </Link>
        <h1 className="text-2xl font-semibold text-white">Payment History</h1>
      </header>

      {payments.length === 0 ? (
        <div className="bg-gray-800 rounded-xl p-8 text-center border border-gray-700 mt-10">
          <CreditCard size={48} className="text-gray-600 mb-4 mx-auto" />
          <h2 className="text-lg font-medium text-white mb-2">No Payments Yet</h2>
          <p className="text-gray-400 mb-6 text-sm">You haven&apos;t made any payments during this stay.</p>
        </div>
      ) : (
        <div className="space-y-4 relative before:absolute before:inset-0 before:ml-5 before:-translate-x-px md:before:mx-auto md:before:translate-x-0 before:h-full before:w-0.5 before:bg-gradient-to-b before:from-transparent before:via-gray-700 before:to-transparent">
          {payments.map((payment) => {
            const statusStyle = StatusStyles[payment.status.toLowerCase()] || StatusStyles.pending;
            
            return (
              <div key={payment.payment_id} className="relative flex items-center justify-between md:justify-normal md:odd:flex-row-reverse group is-active">
                {/* Timeline dot */}
                <div className={`flex items-center justify-center w-10 h-10 rounded-full border-4 border-gray-900 shrink-0 md:order-1 md:group-odd:-translate-x-1/2 md:group-even:translate-x-1/2 shadow absolute left-0 md:relative md:left-auto ${statusStyle.bg} ${statusStyle.text}`}>
                  <CreditCard size={16} />
                </div>

                {/* Card */}
                <div className="w-[calc(100%-4rem)] md:w-[calc(50%-2.5rem)] ml-14 md:ml-0 bg-gray-800 p-4 rounded-xl border border-gray-700 shadow">
                  <div className="flex justify-between items-start mb-2">
                    <h3 className="font-semibold text-white">₹{payment.amount.toFixed(2)}</h3>
                    <div className={`flex items-center gap-1 text-[10px] uppercase font-bold px-2 py-0.5 rounded-full ${statusStyle.bg} ${statusStyle.text}`}>
                      {statusStyle.label}
                    </div>
                  </div>
                  
                  <p className="text-sm text-gray-400 mb-1 capitalize">Mode: {payment.mode.replace('_', ' ')}</p>
                  <p className="text-xs text-gray-500 mb-3 break-all font-mono">Ref: {payment.transaction_id.slice(0, 8)}...</p>
                  
                  <div className="flex items-center justify-between pt-3 border-t border-gray-700/50">
                    <div className="text-xs text-gray-500">
                      {new Date(payment.created_at).toLocaleString('en-US', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' })}
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
