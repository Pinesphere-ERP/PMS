"use client";

import { useInvoices } from "@/hooks/usePayments";
import { ArrowLeft, FileText, Download, AlertCircle } from "lucide-react";
import Link from "next/link";

export default function InvoicesPage() {
  const { data: invoices, isLoading, isError } = useInvoices();

  const handleDownload = async (invoiceId: string) => {
    // In a real implementation, this would trigger a download or open a PDF
    alert(`Mock downloading invoice ${invoiceId}`);
  };

  if (isLoading) {
    return (
      <div className="p-6 max-w-lg mx-auto pb-24">
        <div className="h-8 w-1/3 bg-gray-800 rounded mb-6 animate-pulse"></div>
        <div className="space-y-4">
          {[1, 2].map((i) => (
            <div key={i} className="h-32 bg-gray-800 rounded-xl animate-pulse"></div>
          ))}
        </div>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="p-6 max-w-lg mx-auto pb-24 text-center mt-20">
        <AlertCircle size={48} className="text-red-500 mb-4 mx-auto" />
        <h2 className="text-xl font-semibold text-white mb-2">Could not load invoices</h2>
        <button 
          onClick={() => window.location.reload()}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg mt-4"
        >
          Retry
        </button>
      </div>
    );
  }

  const safeInvoices = invoices || [];

  return (
    <div className="p-6 pb-24 max-w-lg mx-auto">
      <header className="flex items-center gap-3 mb-8">
        <Link href="/folio" className="p-2 -ml-2 text-gray-400 hover:text-white transition-colors">
          <ArrowLeft size={20} />
        </Link>
        <h1 className="text-2xl font-semibold text-white">Invoices</h1>
      </header>

      {safeInvoices.length === 0 ? (
        <div className="bg-gray-800 rounded-xl p-8 text-center border border-gray-700 mt-10">
          <FileText size={48} className="text-gray-600 mb-4 mx-auto" />
          <h2 className="text-lg font-medium text-white mb-2">No Invoices Yet</h2>
          <p className="text-gray-400 mb-6 text-sm">Invoices are automatically generated during check-out.</p>
        </div>
      ) : (
        <div className="space-y-4">
          {safeInvoices.map((inv) => (
            <div key={inv.invoice_id} className="bg-gray-800 p-5 rounded-xl border border-gray-700 shadow">
              <div className="flex justify-between items-start mb-4">
                <div className="flex items-center gap-3">
                  <div className="bg-blue-900/30 p-2 rounded-lg text-blue-400">
                    <FileText size={20} />
                  </div>
                  <div>
                    <h3 className="font-semibold text-white">{inv.invoice_number}</h3>
                    <p className="text-xs text-gray-400">Generated: {new Date(inv.date).toLocaleDateString()}</p>
                  </div>
                </div>
                <div className={`text-xs px-2 py-1 rounded border font-medium ${
                  inv.status.toLowerCase() === 'paid' 
                    ? 'bg-green-900/30 text-green-400 border-green-800' 
                    : 'bg-yellow-900/30 text-yellow-400 border-yellow-800'
                }`}>
                  {inv.status}
                </div>
              </div>
              
              <div className="bg-gray-900/50 p-3 rounded-lg flex justify-between items-center mb-4">
                <div>
                  <p className="text-xs text-gray-500">Amount</p>
                  <p className="font-semibold text-white">₹{inv.amount.toFixed(2)}</p>
                </div>
                {inv.gst > 0 && (
                  <div>
                    <p className="text-xs text-gray-500">Includes GST</p>
                    <p className="font-medium text-gray-400">₹{inv.gst.toFixed(2)}</p>
                  </div>
                )}
              </div>

              <div className="flex gap-2">
                <button 
                  onClick={() => handleDownload(inv.invoice_id)}
                  className="flex-1 flex items-center justify-center gap-2 bg-gray-700 hover:bg-gray-600 text-white py-2 rounded-lg text-sm transition-colors"
                >
                  <Download size={16} />
                  Download
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
