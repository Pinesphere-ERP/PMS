"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import {
  Wifi,
  Copy,
  Check,
  Coffee,
  Clock,
  Phone,
  ShieldAlert,
  ArrowLeft,
  BookOpen,
  Info,
} from "lucide-react";
import Header from "@/components/dashboard/Header";
import BottomNavigation from "@/components/dashboard/BottomNavigation";
import AppContainer from "@/components/ui/AppContainer";
import AppCard from "@/components/ui/AppCard";
import SectionHeader from "@/components/ui/SectionHeader";
import { guest } from "@/data/guest";

export default function RoomPage() {
  const [guestName, setGuestName] = useState(guest.guestName);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
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
  }, []);

  const handleCopyPassword = () => {
    navigator.clipboard.writeText("foreststaygreen");
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
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
            className="inline-flex items-center gap-2 text-sm font-semibold text-[#0d631b] hover:opacity-80"
          >
            <ArrowLeft size={16} />
            Back to Dashboard
          </Link>
        </div>

        {/* Title */}
        <SectionHeader
          title="My Room"
          subtitle="All your room info in one place"
        />

        {/* Room Info Summary */}
        <AppCard className="mb-6 bg-gradient-to-br from-[#0d631b] to-[#2d7a39] text-white">
          <div className="flex justify-between items-center">
            <div>
              <p className="text-xs text-white/80 uppercase tracking-wider font-semibold">
                Room Number
              </p>
              <h2 className="text-4xl font-extrabold mt-1">
                {guest.roomNumber}
              </h2>
              <p className="text-sm mt-1 text-white/90">
                {guest.roomType}
              </p>
            </div>
            <div className="text-right">
              <p className="text-xs text-white/80 uppercase tracking-wider font-semibold">
                Floor
              </p>
              <h3 className="text-xl font-bold mt-1">
                2nd Floor
              </h3>
              <p className="text-xs text-white/90 mt-1">
                Forest View
              </p>
            </div>
          </div>
        </AppCard>

        {/* Wi-Fi Details */}
        <SectionHeader title="Internet Connection" />
        <AppCard className="mb-6">
          <div className="flex items-start gap-4">
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#ebefec] text-[#0d631b]">
              <Wifi size={24} />
            </div>
            <div className="flex-1">
              <p className="text-xs text-gray-500 font-medium">
                Network Name
              </p>
              <p className="font-bold text-gray-800 text-lg">
                Pinesphere Luxury Guest
              </p>

              <p className="text-xs text-gray-500 font-medium mt-3">
                Password
              </p>
              <div className="flex items-center justify-between bg-[#ebefec]/50 px-3 py-2 rounded-xl mt-1 border border-green-100">
                <span className="font-mono text-sm text-gray-800 font-semibold select-all">
                  foreststaygreen
                </span>
                <button
                  onClick={handleCopyPassword}
                  className="flex items-center gap-1 text-xs text-[#0d631b] font-bold hover:opacity-80 active:scale-95 transition px-2 py-1 bg-white rounded-lg shadow-sm border border-green-100/50"
                >
                  {copied ? (
                    <>
                      <Check size={14} className="text-green-600" />
                      <span>Copied!</span>
                    </>
                  ) : (
                    <>
                      <Copy size={14} />
                      <span>Copy</span>
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>
        </AppCard>

        {/* Timings */}
        <SectionHeader title="Stay Timings" />
        <AppCard className="mb-6 space-y-4">
          <div className="flex items-center gap-4">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#ebefec] text-[#0d631b]">
              <Coffee size={20} />
            </div>
            <div>
              <p className="text-xs text-gray-500">
                Breakfast Buffet Hours
              </p>
              <p className="font-semibold text-gray-800">
                07:00 AM - 10:00 AM
              </p>
              <p className="text-xs text-gray-400">
                Served at Canopy Restaurant (1st Floor)
              </p>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#ebefec] text-[#0d631b]">
              <Clock size={20} />
            </div>
            <div>
              <p className="text-xs text-gray-500">
                Check-out Time
              </p>
              <p className="font-semibold text-gray-800">
                11:00 AM
              </p>
              <p className="text-xs text-gray-400">
                Please contact front desk for extensions
              </p>
            </div>
          </div>
        </AppCard>

        {/* Contacts */}
        <SectionHeader title="Support & Contacts" />
        <AppCard className="mb-6 space-y-4">
          <a
            href="tel:+919876543210"
            className="flex items-center justify-between group"
          >
            <div className="flex items-center gap-4">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#ebefec] text-[#0d631b] group-hover:bg-[#0d631b] group-hover:text-white transition">
                <Phone size={20} />
              </div>
              <div>
                <p className="text-xs text-gray-500">
                  Front Desk (24/7)
                </p>
                <p className="font-semibold text-gray-800">
                  +91 98765 43210
                </p>
              </div>
            </div>
            <span className="text-xs font-bold text-[#0d631b] group-hover:underline">
              Call Now
            </span>
          </a>

          <a
            href="tel:+919876599999"
            className="flex items-center justify-between group"
          >
            <div className="flex items-center gap-4">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-red-50 text-red-600 group-hover:bg-red-600 group-hover:text-white transition">
                <ShieldAlert size={20} />
              </div>
              <div>
                <p className="text-xs text-gray-500">
                  Emergency Support
                </p>
                <p className="font-semibold text-red-600">
                  +91 98765 99999
                </p>
              </div>
            </div>
            <span className="text-xs font-bold text-red-600 group-hover:underline">
              Call Now
            </span>
          </a>
        </AppCard>

        {/* Rules & Guidelines */}
        <SectionHeader title="Resort Guidelines" />
        <AppCard className="mb-4">
          <div className="space-y-4 text-sm text-gray-600">
            <div className="flex gap-3">
              <span className="text-[#0d631b] font-bold">1.</span>
              <p>
                <strong className="text-gray-800">Quiet Hours:</strong> Quiet hours are observed between 10:00 PM and 07:00 AM to maintain tranquility for all guests.
              </p>
            </div>
            <div className="flex gap-3">
              <span className="text-[#0d631b] font-bold">2.</span>
              <p>
                <strong className="text-gray-800">No Smoking:</strong> All rooms are strictly non-smoking. Designated smoking zones are located near the forest pathway.
              </p>
            </div>
            <div className="flex gap-3">
              <span className="text-[#0d631b] font-bold">3.</span>
              <p>
                <strong className="text-gray-800">Eco Conservation:</strong> In support of our green initiatives, towels placed on the rack will be reused; towels left on the floor will be laundered.
              </p>
            </div>
            <div className="flex gap-3">
              <span className="text-[#0d631b] font-bold">4.</span>
              <p>
                <strong className="text-gray-800">Visitors:</strong> Outside visitors are permitted in guest rooms until 08:00 PM. Verification is required at reception.
              </p>
            </div>
          </div>
        </AppCard>
      </AppContainer>

      <BottomNavigation />
    </>
  );
}
