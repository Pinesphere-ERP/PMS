"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import {
  User,
  Mail,
  Phone,
  Calendar,
  FileBadge,
  MapPin,
  HelpCircle,
  LogOut,
  Compass,
  RefreshCw,
  ArrowLeft,
} from "lucide-react";
import Header from "@/components/dashboard/Header";
import BottomNavigation from "@/components/dashboard/BottomNavigation";
import AppContainer from "@/components/ui/AppContainer";
import AppCard from "@/components/ui/AppCard";
import AppButton from "@/components/ui/AppButton";
import SectionHeader from "@/components/ui/SectionHeader";
import { guest } from "@/data/guest";

export default function ProfilePage() {
  const router = useRouter();
  const [profile, setProfile] = useState({
    firstName: guest.guestName,
    lastName: "",
    email: "joshua@pinesphere.com",
    phone: "+91 98765 43210",
    documentName: "",
    isCheckedIn: false,
  });

  useEffect(() => {
    const savedStatus = localStorage.getItem("checkinStatus");
    const savedData = localStorage.getItem("checkinData");

    if (savedData) {
      try {
        const parsed = JSON.parse(savedData);
        setProfile({
          firstName: parsed.firstName || guest.guestName,
          lastName: parsed.lastName || "",
          email: parsed.email || "joshua@pinesphere.com",
          phone: parsed.phone || "+91 98765 43210",
          documentName: parsed.documentName || "Uploaded ID",
          isCheckedIn: savedStatus === "Pending" || savedStatus === "Approved",
        });
      } catch (e) {
        console.error(e);
      }
    }
  }, []);

  const handleResetSession = () => {
    if (confirm("This will clear your local check-in/payment state and reset the guest portal. Proceed?")) {
      localStorage.clear();
      // Reload page and send to root/checkin
      window.location.href = "/";
    }
  };

  return (
    <>
      <Header
        propertyName={guest.propertyName}
        guestName={profile.firstName}
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
            title="Guest Profile"
            subtitle="Your registration & resort information"
          />
        </div>

        {/* Profile Avatar Card */}
        <AppCard className="mb-6 bg-gradient-to-br from-[#ebefec] to-[#f4f7f5] border-green-100">
          <div className="flex items-center gap-4 py-2">
            <div className="flex h-16 w-16 items-center justify-center rounded-full bg-[#0d631b] font-bold text-white text-2xl shadow-md border-2 border-white">
              {profile.firstName.charAt(0).toUpperCase()}
            </div>
            <div>
              <h2 className="text-xl font-bold text-gray-800">
                {profile.firstName} {profile.lastName}
              </h2>
              <div className="flex items-center gap-1.5 mt-0.5">
                <span className="inline-block h-2 w-2 rounded-full bg-green-500 animate-pulse"></span>
                <span className="text-xs text-green-700 font-semibold">
                  {profile.isCheckedIn ? "Checked In / Verified" : "Access Token Active"}
                </span>
              </div>
            </div>
          </div>
        </AppCard>

        {/* Personal Details */}
        <SectionHeader title="Registration Details" />
        <AppCard className="mb-6 space-y-4">
          <div className="flex items-center gap-4 text-sm">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gray-50 border border-gray-100 text-gray-500">
              <Mail size={16} />
            </div>
            <div>
              <p className="text-xs text-gray-400">Email Address</p>
              <p className="font-semibold text-gray-800 break-all">{profile.email}</p>
            </div>
          </div>

          <div className="flex items-center gap-4 text-sm">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gray-50 border border-gray-100 text-gray-500">
              <Phone size={16} />
            </div>
            <div>
              <p className="text-xs text-gray-400">Phone Number</p>
              <p className="font-semibold text-gray-800">{profile.phone}</p>
            </div>
          </div>

          {profile.documentName && (
            <div className="flex items-center gap-4 text-sm">
              <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gray-50 border border-gray-100 text-gray-500">
                <FileBadge size={16} />
              </div>
              <div>
                <p className="text-xs text-gray-400">ID Verification Document</p>
                <p className="font-semibold text-gray-800">{profile.documentName}</p>
              </div>
            </div>
          )}
        </AppCard>

        {/* Booking Details */}
        <SectionHeader title="Booking Summary" />
        <AppCard className="mb-6 space-y-4">
          <div className="flex justify-between items-center text-sm">
            <span className="text-gray-500">Booking Reference</span>
            <span className="font-bold text-gray-800 font-mono">#PS-829381</span>
          </div>

          <div className="flex justify-between items-center text-sm">
            <span className="text-gray-500">Room Allocated</span>
            <span className="font-semibold text-gray-800">
              Room {guest.roomNumber} ({guest.roomType})
            </span>
          </div>

          <div className="flex justify-between items-start text-sm">
            <span className="text-gray-500 shrink-0">Stay Duration</span>
            <span className="font-semibold text-gray-800 text-right">
              {guest.checkIn} to {guest.checkOut}
            </span>
          </div>
        </AppCard>

        {/* Hotel Details */}
        <SectionHeader title="Resort Details" />
        <AppCard className="mb-6 space-y-4">
          <div className="flex items-start gap-4 text-sm">
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-gray-50 border border-gray-100 text-gray-500">
              <MapPin size={16} />
            </div>
            <div>
              <h4 className="font-bold text-gray-800">{guest.propertyName}</h4>
              <p className="text-xs text-gray-500 mt-0.5 leading-relaxed">
                Canopy Forest Way, Lakkidi, Wayanad, Kerala - 673122
              </p>
            </div>
          </div>

          <div className="flex items-start gap-4 text-sm border-t border-gray-100 pt-4">
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-gray-50 border border-gray-100 text-gray-500">
              <Compass size={16} />
            </div>
            <div>
              <h4 className="font-bold text-gray-800">General Information</h4>
              <p className="text-xs text-gray-500 mt-0.5 leading-relaxed">
                Check-in: 02:00 PM | Check-out: 11:00 AM. Breakfast is included in canonical booking folios.
              </p>
            </div>
          </div>
        </AppCard>

        {/* Reset / Exit Actions */}
        <div className="mt-8 space-y-3">
          <button
            onClick={handleResetSession}
            className="w-full flex items-center justify-center gap-2 rounded-2xl border border-red-200 bg-red-50/50 hover:bg-red-50 text-red-700 py-3 font-semibold transition active:scale-95 cursor-pointer text-sm"
          >
            <RefreshCw size={16} className="animate-spin-hover" />
            Reset Portal Session (Testing)
          </button>
        </div>
      </AppContainer>

      <BottomNavigation />
    </>
  );
}
