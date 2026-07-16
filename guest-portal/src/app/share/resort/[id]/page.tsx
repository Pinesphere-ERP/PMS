"use client";

import { useEffect, useState } from "react";
import { useParams, useSearchParams } from "next/navigation";
import {
  Sparkles,
  MapPin,
  Layers,
  Phone,
  Home,
  ExternalLink,
  ChevronRight,
  ArrowRight,
  Info,
} from "lucide-react";
import Link from "next/link";

interface CatalogRoom {
  id: string;
  room_number: string;
  type: string;
  price: number;
  images: string[];
  description?: string;
  amenities?: { name: string; price: number }[];
}

export default function ResortCatalogPage() {
  const params = useParams();
  const searchParams = useSearchParams();
  
  const resortId = params?.id as string;
  const resortName = searchParams?.get("name") || "Pinesphere Luxury Resort";
  const roomsRaw = searchParams?.get("rooms") || "";

  const [rooms, setRooms] = useState<CatalogRoom[]>([]);
  const [loading, setLoading] = useState(true);

  // Fallback mock rooms if empty
  const fallbackRooms: CatalogRoom[] = [
    {
      id: "mock_1",
      room_number: "101",
      type: "Forest View Deluxe",
      price: 2500,
      images: [
        "https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=600&q=80",
        "https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=600&q=80",
        "https://images.unsplash.com/photo-1578683010236-d716f9a3f461?auto=format&fit=crop&w=600&q=80",
        "https://images.unsplash.com/photo-1631049307264-da0ec9d70304?auto=format&fit=crop&w=600&q=80",
        "https://images.unsplash.com/photo-1631049035182-249067d7618e?auto=format&fit=crop&w=600&q=80"
      ]
    },
    {
      id: "mock_2",
      room_number: "102",
      type: "Forest View Premium",
      price: 3500,
      images: [
        "https://images.unsplash.com/photo-1566665797739-1674de7a421a?auto=format&fit=crop&w=600&q=80",
        "https://images.unsplash.com/photo-1611892440504-42a792e24d32?auto=format&fit=crop&w=600&q=80"
      ]
    }
  ];

  useEffect(() => {
    const fetchRooms = async () => {
      try {
        setLoading(true);
        // Try fetching from database first
        const res = await fetch('http://localhost:8000/api/v1/properties/rooms');
        if (res.ok) {
          const data = await res.json();
          // Filter rooms belonging to this resort
          const resortRooms = data.filter((r: any) => r.resort_id === resortId);
          
          if (resortRooms.length > 0) {
            const mappedRooms = resortRooms.map((r: any) => {
              let parsedAmenities: any[] = [];
              let parsedDescription = "Enjoy a luxurious stay with premium amenities in our beautiful " + r.type + ".";
              
              try {
                if (r.description && r.description.startsWith('{')) {
                  const descData = JSON.parse(r.description);
                  parsedDescription = descData.description || parsedDescription;
                  parsedAmenities = descData.amenities || [];
                }
              } catch (e) {}

              // Sanitize local image paths to unsplash fallbacks
              let safeImages = Array.isArray(r.images) && r.images.length > 0 ? r.images : [];
              safeImages = safeImages.map((img: string) => {
                if (img.startsWith('http') || img.startsWith('data:')) return img;
                return "https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=600&q=80";
              });
              if (safeImages.length === 0) {
                safeImages = ["https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=600&q=80"];
              }

              return {
                id: r.id,
                room_number: r.room_number,
                type: r.type,
                price: r.price,
                images: safeImages,
                description: parsedDescription,
                amenities: parsedAmenities,
              };
            });
            
            setRooms(mappedRooms);
            return;
          }
        }
        
        // If DB fetch fails or is empty, fallback to URL parameters
        if (roomsRaw) {
          // Format: roomNumber|type|price|firstImage,secondImage...|id
          const parsed = roomsRaw.split(";").map((item, idx) => {
            const parts = item.split("|");
            const rawImages = parts[3] ? parts[3].split(",") : [];
            const sanitizedImages = rawImages.map(img => {
              if (img.startsWith('http') || img.startsWith('data:')) return img;
              return "https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=600&q=80";
            });
            const images = sanitizedImages.length > 0 ? sanitizedImages : ["https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=600&q=80"];
            
            return {
              room_number: parts[0] || `Room ${idx + 1}`,
              type: parts[1] || "Standard Room",
              price: parseFloat(parts[2] || "1500"),
              images: images,
              id: parts[4] || `room_${idx}`,
              description: "Enjoy a luxurious stay with premium amenities in our beautiful " + (parts[1] || "Standard Room") + ".",
              amenities: []
            };
          });
          setRooms(parsed);
        } else {
          setRooms(fallbackRooms as any);
        }
      } catch (e) {
        console.error("Failed to fetch/parse shared rooms catalog:", e);
        setRooms(fallbackRooms as any);
      } finally {
        setLoading(false);
      }
    };

    fetchRooms();
  }, [roomsRaw, resortId]);

  if (loading) {
    return (
      <div className="min-h-screen bg-[#f7f9fa] flex flex-col items-center justify-center p-4">
        <div className="relative w-16 h-16">
          <div className="absolute top-0 left-0 w-full h-full border-4 border-[#0d631b]/20 border-t-[#0d631b] rounded-full animate-spin"></div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#f7f9fa] text-gray-800 pb-20">
      {/* Top Banner / Branding */}
      <header className="bg-white border-b border-gray-200 sticky top-0 z-40 px-4 py-3 shadow-sm flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="h-8 w-8 rounded bg-[#0d631b] flex items-center justify-center text-white font-black text-lg">
            P
          </div>
          <div>
            <h1 className="text-sm font-bold text-gray-900 tracking-tight">Pinesphere Stay</h1>
            <p className="text-[10px] text-gray-500 font-semibold uppercase">Guest Portal</p>
          </div>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 mt-6">
        
        {/* Page Title */}
        <div className="mb-6">
          <h2 className="text-2xl font-black text-gray-900 tracking-tight">
            {resortName} - Available Rooms
          </h2>
          <p className="text-sm text-gray-600 mt-1">
            Choose from {rooms.length} amazing luxury rooms available for your stay.
          </p>
        </div>

        {/* Catalog Grid */}
        <div className="space-y-6">
          {rooms.map((room) => (
            <div
              key={room.id}
              className="bg-white rounded-md border border-gray-200 shadow-sm overflow-hidden flex flex-col md:flex-row"
            >
              {/* Left Side: Image Gallery */}
              <div className="w-full md:w-72 flex-shrink-0 flex flex-col">
                <div className="h-48 md:h-52 w-full relative">
                  <img
                    src={room.images[0] || "https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=600&q=80"}
                    alt={room.type}
                    className="w-full h-full object-cover"
                  />
                  <span className="absolute top-2 left-2 bg-black/70 text-white px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider">
                    Room {room.room_number}
                  </span>
                </div>
                
                {/* Thumbnails below main image */}
                <div className="flex w-full h-16">
                  {room.images.slice(1, 4).map((img, i) => (
                    <div key={i} className="flex-1 relative border-r border-t border-white last:border-r-0">
                      <img src={img} className="w-full h-full object-cover" alt="thumbnail" />
                      {/* Overlay "See all" on the 3rd thumbnail if there are more than 4 images total */}
                      {i === 2 && room.images.length > 4 && (
                        <Link 
                          href={`/share/room/${room.id}?num=${room.room_number}&type=${encodeURIComponent(room.type)}&price=${room.price}&images=${encodeURIComponent(room.images.join(','))}`}
                          className="absolute inset-0 bg-black/60 flex items-center justify-center cursor-pointer hover:bg-black/70 transition"
                        >
                          <span className="text-white text-xs font-bold">See all</span>
                        </Link>
                      )}
                    </div>
                  ))}
                  {/* Fill empty spots if fewer than 4 total images */}
                  {room.images.length < 4 && Array.from({ length: 4 - room.images.length }).map((_, i) => (
                    <div key={`empty-${i}`} className="flex-1 bg-gray-50 border-r border-t border-white last:border-r-0 flex items-center justify-center">
                       <span className="text-gray-300">
                          <Layers size={14} />
                       </span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Right Side: Details */}
              <div className="p-4 md:p-5 flex-1 flex flex-col justify-between">
                <div>
                  <h4 className="text-xl font-bold text-gray-900 leading-tight hover:text-[#0d631b] cursor-pointer">
                    <Link href={`/share/room/${room.id}?num=${room.room_number}&type=${encodeURIComponent(room.type)}&price=${room.price}&images=${encodeURIComponent(room.images.join(','))}`}>
                       {room.type} - {resortName}
                    </Link>
                  </h4>
                  
                  <div className="flex items-center gap-1 mt-1.5 text-[#f5a623] text-sm">
                    <span>★★★★★</span>
                    <span className="text-xs text-[#0d631b] ml-1 flex items-center font-medium hover:underline cursor-pointer">
                      <MapPin size={12} className="mr-0.5" /> {resortName} Center - View on map
                    </span>
                  </div>

                  {/* Amenities */}
                  <div className="flex flex-wrap gap-2 mt-3">
                    {room.amenities && room.amenities.length > 0 ? (
                      room.amenities.map((amenity, idx) => (
                        <span key={idx} className="text-xs font-semibold px-2 py-1 border border-gray-300 rounded text-gray-700">
                          {amenity.name}
                        </span>
                      ))
                    ) : (
                      <>
                        <span className="text-xs font-semibold px-2 py-1 border border-gray-300 rounded text-gray-700">Free Wi-Fi</span>
                        <span className="text-xs font-semibold px-2 py-1 border border-gray-300 rounded text-gray-700">Free parking</span>
                        <span className="text-xs font-semibold px-2 py-1 border border-gray-300 rounded text-gray-700">AC</span>
                      </>
                    )}
                  </div>

                  <p className="text-sm text-gray-700 mt-4 leading-relaxed line-clamp-2">
                    {room.description || `"The front desk staff gave excellent customer service during check-in/check-out. Enjoy a luxurious stay with premium amenities in our beautiful ${room.type}."`}
                  </p>
                  <Link 
                    href={`/share/room/${room.id}?num=${room.room_number}&type=${encodeURIComponent(room.type)}&price=${room.price}&images=${encodeURIComponent(room.images.join(','))}`}
                    className="text-[#0d631b] text-sm font-semibold mt-1 inline-flex items-center gap-1 hover:underline"
                  >
                    Show more ▾
                  </Link>
                </div>

                <div className="flex items-end justify-between mt-6 pt-4 border-t border-gray-100">
                  <div className="text-xs text-[#0d631b] font-bold flex items-center gap-1 bg-green-50 px-2 py-1 rounded">
                    <Sparkles size={12} /> High demand
                  </div>

                  <div className="text-right">
                    <span className="text-xs text-gray-500 font-semibold block mb-0.5">Amount per day</span>
                    <div className="flex items-baseline justify-end gap-1">
                      <span className="text-2xl font-black text-gray-900">
                        ₹{room.price.toLocaleString("en-IN")}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Footer */}
        <div className="mt-12 text-center p-6 bg-white rounded-md border border-gray-200 shadow-sm">
          <h4 className="font-bold text-sm text-gray-900">Need help planning your booking?</h4>
          <p className="text-xs text-gray-500 mt-1">Get in touch with reception staff to customize your stay packages.</p>
          <a
            href="tel:+919876543210"
            className="inline-flex items-center gap-1.5 mt-3 text-sm font-bold text-[#0d631b] hover:underline"
          >
            <Phone size={16} /> Call Front Desk (+91 98765 43210)
          </a>
        </div>
      </main>
    </div>
  );
}
