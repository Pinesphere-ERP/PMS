"use client";

import { useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { Calendar, Users, Clock } from "lucide-react";

export default function StayPage() {
  const { data: stay, isLoading } = useQuery({
    queryKey: ["portalStay"],
    queryFn: async () => {
      const res = await api.get("/portal/stay");
      return res.data;
    },
  });

  if (isLoading) {
    return (
      <div className="flex justify-center items-center h-full pt-12">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  return (
    <div className="p-6 max-w-lg mx-auto">
      <h1 className="text-2xl font-semibold text-white mb-6">Stay Details</h1>

      <div className="bg-gray-800 rounded-xl p-6 border border-gray-700 space-y-6">
        
        {/* Status */}
        <div className="flex items-center justify-between border-b border-gray-700 pb-4">
          <span className="text-gray-400">Status</span>
          <span className="px-3 py-1 bg-blue-900 text-blue-200 text-sm font-medium rounded-full capitalize">
            {stay?.booking_status}
          </span>
        </div>

        {/* Dates */}
        <div className="space-y-4 border-b border-gray-700 pb-4">
          <div className="flex items-center text-gray-300">
            <Calendar className="mr-3 text-blue-400" size={20} />
            <div>
              <p className="text-xs text-gray-500">Booked On</p>
              <p className="font-medium">{new Date(stay?.booked_at).toLocaleDateString()}</p>
            </div>
          </div>
          {stay?.checked_in_at && (
            <div className="flex items-center text-gray-300">
              <Clock className="mr-3 text-green-400" size={20} />
              <div>
                <p className="text-xs text-gray-500">Checked In</p>
                <p className="font-medium">{new Date(stay.checked_in_at).toLocaleString()}</p>
              </div>
            </div>
          )}
          {stay?.checked_out_at && (
            <div className="flex items-center text-gray-300">
              <Clock className="mr-3 text-orange-400" size={20} />
              <div>
                <p className="text-xs text-gray-500">Checked Out</p>
                <p className="font-medium">{new Date(stay.checked_out_at).toLocaleString()}</p>
              </div>
            </div>
          )}
        </div>

        {/* Occupancy */}
        <div className="flex items-center text-gray-300 pt-2">
          <Users className="mr-3 text-purple-400" size={20} />
          <div className="flex space-x-6">
            <div>
              <p className="text-xs text-gray-500">Adults</p>
              <p className="font-medium">{stay?.adults}</p>
            </div>
            <div>
              <p className="text-xs text-gray-500">Children</p>
              <p className="font-medium">{stay?.children}</p>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
}
