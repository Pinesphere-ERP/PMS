"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import {
  CreditCard,
  ShieldCheck,
  Receipt,
  FileText,
  CheckCircle2,
  Loader2,
  Calendar,
  AlertCircle,
  Download,
  ArrowLeft,
} from "lucide-react";
import Header from "@/components/dashboard/Header";
import BottomNavigation from "@/components/dashboard/BottomNavigation";
import AppContainer from "@/components/ui/AppContainer";
import AppCard from "@/components/ui/AppCard";
import AppButton from "@/components/ui/AppButton";
import SectionHeader from "@/components/ui/SectionHeader";
import { guest } from "@/data/guest";

export default function PaymentsPage() {
  const [guestName, setGuestName] = useState(guest.guestName);
  const [balance, setBalance] = useState(guest.balance);
  const [paying, setPaying] = useState(false);
  const [paidSuccess, setPaidSuccess] = useState(false);
  const [downloading, setDownloading] = useState(false);
  const [downloadSuccess, setDownloadSuccess] = useState(false);

  useEffect(() => {
    // Load guest name
    const savedData = localStorage.getItem("checkinData");
    if (savedData) {
      try {
        const parsed = JSON.parse(savedData);
        if (parsed.firstName) {
          setGuestName(parsed.firstName);
        }
      } catch (e) {
        console.error(e);
      }
    }

    // Load balance
    const savedBalance = localStorage.getItem("paymentBalance");
    if (savedBalance !== null && savedBalance !== undefined) {
      setBalance(Number(savedBalance));
    }
  }, []);

  const handlePayment = () => {
    setPaying(true);
    setTimeout(() => {
      setPaying(false);
      setPaidSuccess(true);
      setBalance(0);
      localStorage.setItem("paymentBalance", "0");
    }, 2000);
  };

  const handleDownloadInvoice = () => {
    setDownloading(true);
    setTimeout(() => {
      setDownloading(false);
      setDownloadSuccess(true);
      setTimeout(() => setDownloadSuccess(false), 3000);
    }, 1500);
  };

  return (
    <>
      <Header
        propertyName={guest.propertyName}
        guestName={guestName}
      />

      <AppContainer>
        {/* Back Link */}
        <div className="mb-4">
          <Link
            href="/"
            className="inline-flex items-center gap-2 text-sm font-semibold text-[#0d631b] hover:opacity-80 transition"
          >
            <ArrowLeft size={16} />
            Back to Dashboard
          </Link>
        </div>

        {/* Title */}
        <div className="mb-4">
          <SectionHeader
            title="Folio & Payments"
            subtitle="Review charges and complete secure checkout"
          />
        </div>

        {/* Balance Card */}
        <AppCard className="mb-6 border-green-100">
          {paidSuccess || balance === 0 ? (
            <div className="text-center py-4">
              <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-green-50 text-green-600 mb-3 border border-green-200">
                <CheckCircle2 size={32} />
              </div>
              <h3 className="text-xl font-bold text-gray-800">
                All Settled!
              </h3>
              <p className="text-sm text-gray-500 mt-1">
                Your folio balance is fully paid.
              </p>
              <h2 className="text-3xl font-extrabold text-[#0d631b] mt-2">
                ₹0
              </h2>
            </div>
          ) : (
            <div>
              <div className="flex justify-between items-center">
                <div>
                  <p className="text-xs text-gray-500 font-semibold uppercase tracking-wider">
                    Amount Outstanding
                  </p>
                  <h2 className="text-4xl font-extrabold text-[#0d631b] mt-1">
                    ₹{balance.toLocaleString()}
                  </h2>
                </div>
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#ebefec] text-[#0d631b]">
                  <CreditCard size={24} />
                </div>
              </div>

              {/* Secure payment shield */}
              <div className="flex items-center gap-3 bg-green-50 border border-green-100/50 p-3 rounded-2xl mt-4">
                <ShieldCheck className="text-green-700 h-5 w-5 shrink-0" />
                <div className="text-xs">
                  <p className="font-bold text-green-800">
                    Secure checkout portal
                  </p>
                  <p className="text-green-600">
                    Supports UPI, Credit Cards, Net Banking
                  </p>
                </div>
              </div>

              {/* Pay now trigger */}
              <div className="mt-5">
                {paying ? (
                  <button
                    disabled
                    className="w-full rounded-2xl bg-gray-100 py-3 font-semibold text-gray-400 flex items-center justify-center gap-2 border border-gray-200"
                  >
                    <Loader2 className="h-4 w-4 animate-spin text-gray-400" />
                    <span>Processing Secure Gateway...</span>
                  </button>
                ) : (
                  <AppButton title="Pay Now" onClick={handlePayment} />
                )}
              </div>
            </div>
          )}
        </AppCard>

        {/* Detailed Breakdown */}
        <SectionHeader
          title="Charge Breakdown"
          subtitle="Itemized billing statements"
        />
        <AppCard className="mb-6">
          <div className="space-y-3.5 text-sm">
            <div className="flex justify-between text-gray-600">
              <span>Room Tariff (2 Nights)</span>
              <span className="font-medium text-gray-800">₹8,000</span>
            </div>
            <div className="flex justify-between text-gray-600">
              <span>In-Room Dining (Order #1092)</span>
              <span className="font-medium text-gray-800">₹1,200</span>
            </div>
            <div className="flex justify-between text-gray-600">
              <span>Canopy Spa Treatment</span>
              <span className="font-medium text-gray-800">₹2,500</span>
            </div>
            <div className="flex justify-between text-gray-600">
              <span>State & Central Taxes (18% GST)</span>
              <span className="font-medium text-gray-800">₹2,650</span>
            </div>

            <hr className="border-gray-200/80 my-2" />

            <div className="flex justify-between text-base font-bold text-gray-800">
              <span>Total Accrued Charges</span>
              <span>₹14,350</span>
            </div>

            <div className="flex justify-between text-sm text-green-700 font-semibold">
              <span>Less: Booking Advance Deposit</span>
              <span>-₹12,000</span>
            </div>

            <hr className="border-gray-200/80 my-2" />

            <div className="flex justify-between text-lg font-bold text-[#0d631b]">
              <span>Outstanding Due</span>
              <span>₹{balance.toLocaleString()}</span>
            </div>
          </div>
        </AppCard>

        {/* Invoice Actions */}
        <SectionHeader title="Invoice Documents" />
        <AppCard className="mb-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50 text-blue-600">
                <Receipt size={20} />
              </div>
              <div>
                <h4 className="font-bold text-gray-800 text-sm">
                  Tax Invoice Folio
                </h4>
                <p className="text-xs text-gray-500">
                  PDF format • GST details included
                </p>
              </div>
            </div>

            {downloading ? (
              <button
                disabled
                className="flex items-center gap-1 rounded-xl bg-gray-50 text-gray-400 px-3 py-2 text-xs font-semibold"
              >
                <Loader2 className="h-3.5 w-3.5 animate-spin" />
                <span>Building</span>
              </button>
            ) : downloadSuccess ? (
              <span className="flex items-center gap-1 rounded-xl bg-green-50 border border-green-200 text-green-700 px-3 py-2 text-xs font-bold shadow-sm">
                <CheckCircle2 className="h-3.5 w-3.5 text-green-600" />
                <span>Downloaded</span>
              </span>
            ) : (
              <button
                onClick={handleDownloadInvoice}
                className="flex items-center gap-1 rounded-xl bg-[#ebefec] text-[#0d631b] hover:bg-[#0d631b] hover:text-white px-3 py-2 text-xs font-bold transition active:scale-95 cursor-pointer border border-green-100"
              >
                <Download size={14} />
                <span>PDF</span>
              </button>
            )}
          </div>
        </AppCard>

        {/* Transaction History */}
        <SectionHeader title="Payment History" />
        <AppCard className="mb-4">
          <div className="space-y-4">
            <div className="flex justify-between items-start text-sm">
              <div className="flex gap-3">
                <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-gray-100 text-gray-500">
                  <Calendar size={16} />
                </div>
                <div>
                  <h4 className="font-bold text-gray-800 text-sm">
                    Advance deposit receipt
                  </h4>
                  <p className="text-xs text-gray-400">
                    Paid via Card • Ref: #TXN-98321
                  </p>
                  <p className="text-[10px] text-gray-400 mt-0.5">
                    28 Jun 2026, 11:20 AM
                  </p>
                </div>
              </div>
              <span className="font-bold text-green-700">
                ₹12,000
              </span>
            </div>

            {/* If paid during portal session, show it here dynamically */}
            {(balance === 0 || paidSuccess) && (
              <div className="flex justify-between items-start text-sm border-t border-gray-100 pt-4">
                <div className="flex gap-3">
                  <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-green-50 text-green-600">
                    <CheckCircle2 size={16} />
                  </div>
                  <div>
                    <h4 className="font-bold text-gray-800 text-sm">
                      Portal Checkout Settle
                    </h4>
                    <p className="text-xs text-gray-400">
                      Paid via Gateway • Ref: #TXN-GP827
                    </p>
                    <p className="text-[10px] text-gray-400 mt-0.5">
                      Today, Just now
                    </p>
                  </div>
                </div>
                <span className="font-bold text-green-700">
                  ₹2,350
                </span>
              </div>
            )}
          </div>
        </AppCard>
      </AppContainer>

      <BottomNavigation />
    </>
  );
}
