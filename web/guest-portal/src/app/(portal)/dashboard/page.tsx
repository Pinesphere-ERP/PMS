"use client";

import { useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { useAuthStore } from "@/store/useAuthStore";
import { DoorOpen, MapPin, Clock, CalendarDays, Coffee, MessageSquare, LogOut } from "lucide-react";
import Link from "next/link";

export default function DashboardPage() {
  const { guestName, capabilities, logout } = useAuthStore();

  const { data: me, isLoading } = useQuery({
    queryKey: ["portalMe"],
    queryFn: async () => {
      const res = await api.get("/portal/me");
      return res.data;
    },
    staleTime: 60 * 1000,
  });

  if (isLoading) {
    return (
      <div className="flex justify-center items-center h-full">
        <div className="animate-pulse flex flex-col items-center space-y-4">
          <div className="h-12 w-12 bg-gray-800 rounded-full"></div>
          <div className="h-4 w-32 bg-gray-800 rounded"></div>
        </div>
      </div>
    );
  }

  const { guest, stay, room } = me || {};

  return (
    <div className="p-6 pb-24 max-w-lg mx-auto">
      {/* Header */}
      <header className="flex justify-between items-center mb-8">
        <div>
          <p className="text-sm text-gray-400">Welcome to Pinesphere</p>
          <h1 className="text-2xl font-semibold text-white">
            {guestName || guest?.name || "Guest"}
          </h1>
        </div>
        <button 
          onClick={logout}
          className="text-xs bg-gray-800 hover:bg-gray-700 text-gray-300 py-1 px-3 rounded-full transition-colors"
        >
          Logout
        </button>
      </header>

      {/* Main Status Card */}
      <div className="bg-gradient-to-br from-blue-900 to-gray-900 rounded-2xl p-6 mb-6 shadow-lg border border-blue-800/30">
        <div className="flex justify-between items-start mb-6">
          <div>
            <p className="text-blue-200 text-sm mb-1">Room</p>
            <p className="text-3xl font-bold text-white">
              {room?.room_number || "Pending"}
            </p>
          </div>
          <div className="text-right">
            <p className="text-blue-200 text-sm mb-1">Status</p>
            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-800 text-blue-100 uppercase tracking-wider">
              {stay?.status || "Unknown"}
            </span>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4 pt-4 border-t border-blue-800/50">
          <div>
            <p className="text-blue-300 text-xs mb-1">Arrival</p>
            <p className="text-white text-sm font-medium">{stay?.check_in_date}</p>
          </div>
          <div>
            <p className="text-blue-300 text-xs mb-1">Departure</p>
            <p className="text-white text-sm font-medium">{stay?.check_out_date}</p>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <h3 className="text-lg font-medium text-gray-200 mb-4">Quick Actions</h3>
      <div className="grid grid-cols-2 gap-4">
        {capabilities?.can_request_service && (
          <Link href="/services" className="bg-gray-800 rounded-xl p-4 border border-gray-700 flex flex-col items-center justify-center hover:bg-gray-750 transition-colors">
            <DoorOpen size={24} className="text-blue-400 mb-2" />
            <span className="text-sm font-medium">Services</span>
          </Link>
        )}

        {capabilities?.can_request_service && (
          <Link href="/food" className="bg-gray-800 rounded-xl p-4 border border-gray-700 flex flex-col items-center justify-center hover:bg-gray-750 transition-colors">
            <Coffee size={24} className="text-yellow-400 mb-2" />
            <span className="text-sm font-medium">Food</span>
          </Link>
        )}

        <Link href="/room" className="bg-gray-800 rounded-xl p-4 border border-gray-700 flex flex-col items-center justify-center hover:bg-gray-750 transition-colors">
          <Clock size={24} className="text-green-400 mb-2" />
          <span className="text-sm font-medium">Room Info</span>
        </Link>
        
        <Link href="/property" className="bg-gray-800 rounded-xl p-4 border border-gray-700 flex flex-col items-center justify-center hover:bg-gray-750 transition-colors">
          <MapPin size={24} className="text-purple-400 mb-2" />
          <span className="text-sm font-medium">Property</span>
        </Link>

        {capabilities?.can_submit_feedback && (
          <Link href="/feedback" className="bg-gray-800 rounded-xl p-4 border border-gray-700 flex flex-col items-center justify-center hover:bg-gray-750 transition-colors">
            <MessageSquare size={24} className="text-pink-400 mb-2" />
            <span className="text-sm font-medium">Feedback</span>
          </Link>
        )}

        {capabilities?.can_download_invoice && (
          <Link href="/folio" className="bg-gray-800 rounded-xl p-4 border border-gray-700 flex flex-col items-center justify-center hover:bg-gray-750 transition-colors">
            <CalendarDays size={24} className="text-orange-400 mb-2" />
            <span className="text-sm font-medium">My Bill</span>
          </Link>
        )}

        <Link href="/checkout" className="bg-gray-800 rounded-xl p-4 border border-gray-700 flex flex-col items-center justify-center hover:bg-gray-750 transition-colors">
          <LogOut size={24} className="text-red-400 mb-2" />
          <span className="text-sm font-medium">Checkout</span>
        </Link>
      </div>
    </div>
  );
}
