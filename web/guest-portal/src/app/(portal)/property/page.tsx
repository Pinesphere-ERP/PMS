"use client";

import { useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { MapPin, Mail, Phone, Clock } from "lucide-react";

export default function PropertyPage() {
  const { data: property, isLoading } = useQuery({
    queryKey: ["portalProperty"],
    queryFn: async () => {
      const res = await api.get("/portal/property");
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
      <h1 className="text-2xl font-semibold text-white mb-6">Property Info</h1>

      <div className="bg-gray-800 rounded-xl p-6 border border-gray-700 space-y-6">
        
        <div>
          <h2 className="text-xl font-bold text-gray-100 mb-1">{property?.name}</h2>
          {property?.address && (
            <div className="flex items-start text-gray-400 mt-2">
              <MapPin className="mr-2 flex-shrink-0 mt-0.5 text-blue-400" size={18} />
              <span className="text-sm">{property.address}</span>
            </div>
          )}
        </div>

        <div className="border-t border-gray-700 pt-6 space-y-4">
          <h3 className="text-sm font-medium text-gray-300 uppercase tracking-wider mb-2">Contact</h3>
          
          {property?.contact_email && (
            <div className="flex items-center text-gray-300">
              <Mail className="mr-3 text-gray-500" size={20} />
              <a href={`mailto:${property.contact_email}`} className="text-sm text-blue-400 hover:underline">
                {property.contact_email}
              </a>
            </div>
          )}
          
          {property?.contact_phone && (
            <div className="flex items-center text-gray-300">
              <Phone className="mr-3 text-gray-500" size={20} />
              <a href={`tel:${property.contact_phone}`} className="text-sm text-blue-400 hover:underline">
                {property.contact_phone}
              </a>
            </div>
          )}
        </div>

        {(property?.check_in_time || property?.check_out_time) && (
          <div className="border-t border-gray-700 pt-6">
            <h3 className="text-sm font-medium text-gray-300 uppercase tracking-wider mb-4">Timings</h3>
            <div className="flex justify-between max-w-xs">
              {property.check_in_time && (
                <div className="flex items-center">
                  <Clock className="mr-2 text-green-400" size={18} />
                  <div>
                    <p className="text-xs text-gray-500">Check-in</p>
                    <p className="font-medium text-gray-200">{property.check_in_time}</p>
                  </div>
                </div>
              )}
              {property.check_out_time && (
                <div className="flex items-center">
                  <Clock className="mr-2 text-orange-400" size={18} />
                  <div>
                    <p className="text-xs text-gray-500">Check-out</p>
                    <p className="font-medium text-gray-200">{property.check_out_time}</p>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}
        
      </div>
    </div>
  );
}
