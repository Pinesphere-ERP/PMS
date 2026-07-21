"use client";

import { useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { BedDouble, Info } from "lucide-react";

export default function RoomPage() {
  const { data: room, isLoading, isError } = useQuery({
    queryKey: ["portalRoom"],
    queryFn: async () => {
      const res = await api.get("/portal/room");
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

  if (isError) {
    return (
      <div className="p-6 text-center text-gray-400 mt-12">
        <p>No room assigned yet.</p>
      </div>
    );
  }

  return (
    <div className="p-6 max-w-lg mx-auto">
      <h1 className="text-2xl font-semibold text-white mb-6">Room Details</h1>

      <div className="bg-gray-800 rounded-xl overflow-hidden border border-gray-700">
        <div className="bg-blue-900/40 p-6 flex items-center justify-between border-b border-gray-700">
          <div>
            <p className="text-blue-300 text-sm mb-1">Room Number</p>
            <p className="text-4xl font-bold text-white">{room?.room_number}</p>
          </div>
          <BedDouble size={40} className="text-blue-400 opacity-50" />
        </div>

        <div className="p-6 space-y-4">
          <div>
            <p className="text-xs text-gray-500 uppercase tracking-wider mb-1">Category</p>
            <p className="text-gray-200 font-medium">{room?.category}</p>
          </div>
          
          {room?.description && (
            <div>
              <p className="text-xs text-gray-500 uppercase tracking-wider mb-1 flex items-center">
                <Info size={12} className="mr-1" /> Description
              </p>
              <p className="text-gray-300 text-sm leading-relaxed">{room.description}</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
