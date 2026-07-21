"use client";

import { useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { CheckCircle2 } from "lucide-react";
import { PortalAmenity, PortalAmenitiesResponse } from "@/types/api";

export default function AmenitiesPage() {
  const { data, isLoading } = useQuery({
    queryKey: ["portalAmenities"],
    queryFn: async () => {
      const res = await api.get<PortalAmenitiesResponse>("/portal/amenities");
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

  const amenities = data?.amenities || [];

  return (
    <div className="p-6 max-w-lg mx-auto">
      <h1 className="text-2xl font-semibold text-white mb-6">Property Amenities</h1>

      {amenities.length === 0 ? (
        <div className="text-center text-gray-500 py-12">
          No amenities listed.
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {amenities.map((amenity: PortalAmenity) => (
            <div 
              key={amenity.id} 
              className="bg-gray-800 p-4 rounded-xl border border-gray-700 flex items-start"
            >
              <CheckCircle2 className="text-green-400 mr-3 mt-0.5 flex-shrink-0" size={20} />
              <div>
                <p className="font-medium text-gray-200">{amenity.name}</p>
                {amenity.description && (
                  <p className="text-xs text-gray-500 mt-1 capitalize">{amenity.description}</p>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
