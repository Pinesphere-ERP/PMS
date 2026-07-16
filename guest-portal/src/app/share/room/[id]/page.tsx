"use client";

import { useEffect, useState } from "react";
import { useParams, useSearchParams } from "next/navigation";
import {
  Wifi,
  Coffee,
  Tv,
  Wind,
  Bath,
  ArrowLeft,
  ChevronLeft,
  ChevronRight,
  Sparkles,
  MapPin,
  Maximize2,
  Calendar,
  Layers,
  Heart,
  DollarSign,
  AlertCircle,
  HelpCircle,
  ExternalLink,
} from "lucide-react";
import Link from "next/link";

interface RoomDetails {
  id: string;
  room_number: string;
  type: string;
  price: number;
  status: string;
  description: string;
  images: string[];
}

export default function SharedRoomPage() {
  const params = useParams();
  const searchParams = useSearchParams();
  const roomId = params?.id as string;

  const queryNum = searchParams?.get("num");
  const queryType = searchParams?.get("type");
  const queryPrice = searchParams?.get("price");
  const queryImages = searchParams?.get("images");

  const [room, setRoom] = useState<RoomDetails | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [isLightboxOpen, setIsLightboxOpen] = useState(false);

  // Fallback / Mock room details with 5 stunning photos
  const fallbackRoom: RoomDetails = {
    id: roomId || "mock_room_id",
    room_number: "204",
    type: "Forest View Premium Suite",
    price: 3500.0,
    status: "Vacant",
    description:
      "Experience luxury nestled in nature. This premium suite offers a breathtaking panoramic forest view, a private outdoor balcony, bespoke wooden interiors, a spacious king-sized bed, and modern high-end amenities. Perfect for couples or solo travelers looking to escape into tranquility.",
    images: [
      "https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1200&q=80",
      "https://images.unsplash.com/photo-1566665797739-1674de7a421a?auto=format&fit=crop&w=1200&q=80",
      "https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=1200&q=80",
      "https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=1200&q=80",
      "https://images.unsplash.com/photo-1618773928121-c32242e63f39?auto=format&fit=crop&w=1200&q=80",
    ],
  };

  useEffect(() => {
    if (!roomId) return;

    const fetchRoomDetails = async () => {
      try {
        setLoading(true);
        // Attempt to fetch from backend
        const res = await fetch(`http://localhost:8000/api/v1/properties/rooms/${roomId}`);
        if (!res.ok) {
          throw new Error("Could not load database details, using preview template.");
        }
        const data = await res.json();
        // Sanitize local image paths to unsplash fallbacks
        if (data.images && Array.isArray(data.images)) {
          data.images = data.images.map((img: string) => {
            if (img.startsWith('http') || img.startsWith('data:')) return img;
            return "https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1200&q=80";
          });
        }
        setRoom(data);
      } catch (err: any) {
        console.log("Backend not connected or failed, using premium template:", err.message);
        if (queryNum || queryType || queryPrice || queryImages) {
          let imagesList = fallbackRoom.images;
          if (queryImages) {
            const rawImages = queryImages.split(",");
            const sanitizedImages = rawImages.map(img => {
              if (img.startsWith('http') || img.startsWith('data:')) return img;
              return "https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1200&q=80";
            });
            if (sanitizedImages.length > 0) {
              imagesList = sanitizedImages;
            }
          }
          
          setRoom({
            id: roomId,
            room_number: queryNum || fallbackRoom.room_number,
            type: queryType || fallbackRoom.type,
            price: queryPrice ? parseFloat(queryPrice) : fallbackRoom.price,
            status: "Vacant",
            description: fallbackRoom.description,
            images: imagesList,
          });
        } else {
          setRoom(fallbackRoom);
        }
      } finally {
        setLoading(false);
      }
    };

    fetchRoomDetails();
  }, [roomId, queryNum, queryType, queryPrice, queryImages]);

  const handleNextImage = () => {
    if (!room) return;
    setCurrentImageIndex((prev) => (prev + 1) % room.images.length);
  };

  const handlePrevImage = () => {
    if (!room) return;
    setCurrentImageIndex((prev) => (prev - 1 + room.images.length) % room.images.length);
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-[#fafbfc] flex flex-col items-center justify-center p-4">
        <div className="relative w-16 h-16">
          <div className="absolute top-0 left-0 w-full h-full border-4 border-[#0d631b]/20 border-t-[#0d631b] rounded-full animate-spin"></div>
        </div>
        <p className="mt-4 text-sm font-semibold text-gray-500 tracking-wide">
          Loading Luxury Preview...
        </p>
      </div>
    );
  }

  const activeRoom = room || fallbackRoom;

  return (
    <div className="min-h-screen bg-[#fafbfc] text-gray-800 pb-20">
      {/* Top Banner / Branding */}
      <header className="bg-white border-b border-gray-100 sticky top-0 z-40 px-4 py-3 shadow-sm flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="h-8 w-8 rounded-lg bg-[#0d631b] flex items-center justify-center text-white font-extrabold text-lg shadow-md shadow-green-950/20">
            P
          </div>
          <div>
            <h1 className="text-sm font-bold text-gray-900 tracking-tight">Pinesphere Stay</h1>
            <p className="text-[10px] text-gray-400 font-semibold tracking-wider uppercase">Guest Portal</p>
          </div>
        </div>
        <span className="text-[10px] bg-green-50 text-[#0d631b] px-2 py-1 rounded-full font-bold uppercase tracking-wider border border-green-100 flex items-center gap-1">
          <Sparkles size={10} /> Room Preview
        </span>
      </header>

      {/* Main Content Area */}
      <main className="max-w-2xl mx-auto px-4 mt-4">
        
        {/* Back navigation/helper note */}
        <div className="mb-4 flex items-center justify-between text-xs text-gray-500 font-semibold">
          <span className="flex items-center gap-1">
            <MapPin size={12} className="text-[#0d631b]" /> Pinesphere Resort & Spa
          </span>
          <span>Room #{activeRoom.room_number}</span>
        </div>

        {/* Gallery / Image Slider */}
        <div className="relative h-64 md:h-80 w-full rounded-3xl overflow-hidden shadow-lg border border-gray-100 bg-black group">
          <img
            src={activeRoom.images[currentImageIndex]}
            alt={`${activeRoom.type} view`}
            className="w-full h-full object-cover cursor-pointer transition duration-300 hover:scale-102"
            onClick={() => setIsLightboxOpen(true)}
          />
          
          {/* Slider controls */}
          <button
            onClick={handlePrevImage}
            className="absolute left-3 top-1/2 -translate-y-1/2 h-9 w-9 bg-white/90 backdrop-blur-sm rounded-full flex items-center justify-center shadow-md text-gray-800 hover:bg-white active:scale-95 transition"
          >
            <ChevronLeft size={20} />
          </button>
          
          <button
            onClick={handleNextImage}
            className="absolute right-3 top-1/2 -translate-y-1/2 h-9 w-9 bg-white/90 backdrop-blur-sm rounded-full flex items-center justify-center shadow-md text-gray-800 hover:bg-white active:scale-95 transition"
          >
            <ChevronRight size={20} />
          </button>

          {/* Lightbox / Zoom trigger */}
          <button
            onClick={() => setIsLightboxOpen(true)}
            className="absolute right-3 bottom-3 h-8 w-8 bg-black/60 backdrop-blur-sm text-white rounded-full flex items-center justify-center hover:bg-black/80 transition"
          >
            <Maximize2 size={14} />
          </button>

          {/* Dots Indicator */}
          <div className="absolute bottom-3 left-1/2 -translate-x-1/2 flex gap-1.5 bg-black/30 backdrop-blur-sm px-2.5 py-1.5 rounded-full">
            {activeRoom.images.map((_, i) => (
              <span
                key={i}
                className={`h-1.5 rounded-full transition-all duration-300 ${
                  i === currentImageIndex ? "w-4 bg-white" : "w-1.5 bg-white/55"
                }`}
              />
            ))}
          </div>
        </div>

        {/* Small thumbnail strip */}
        <div className="flex gap-2.5 mt-3 overflow-x-auto pb-1 scrollbar-thin">
          {activeRoom.images.map((img, i) => (
            <button
              key={i}
              onClick={() => setCurrentImageIndex(i)}
              className={`relative h-14 w-20 rounded-xl overflow-hidden flex-shrink-0 border-2 transition-all ${
                i === currentImageIndex ? "border-[#0d631b] scale-102 shadow-sm" : "border-transparent opacity-75"
              }`}
            >
              <img src={img} className="h-full w-full object-cover" alt="" />
            </button>
          ))}
        </div>

        {/* Room Header Info */}
        <div className="mt-6 bg-white p-6 rounded-3xl border border-gray-100 shadow-sm">
          <div className="flex justify-between items-start gap-4">
            <div>
              <h2 className="text-2xl font-extrabold text-gray-900 leading-tight">
                {activeRoom.type}
              </h2>
              <div className="flex gap-2 items-center mt-2 text-xs text-gray-500 font-semibold">
                <span className="bg-[#ebefec] text-[#0d631b] px-2 py-0.5 rounded-md">
                  Room {activeRoom.room_number}
                </span>
                <span>•</span>
                <span className="flex items-center gap-0.5">
                  <Layers size={12} /> 2nd Floor
                </span>
              </div>
            </div>
            <div className="text-right flex-shrink-0">
              <span className="text-[10px] text-gray-400 font-bold uppercase tracking-wider">Per Night</span>
              <p className="text-2xl font-extrabold text-[#0d631b] flex items-center justify-end">
                ₹{activeRoom.price.toLocaleString("en-IN")}
              </p>
            </div>
          </div>

          <div className="h-px bg-gray-100 my-4" />

          {/* Description */}
          <h3 className="text-sm font-bold text-gray-900 uppercase tracking-wider">Room Overview</h3>
          <p className="text-sm text-gray-600 mt-2 leading-relaxed">
            {activeRoom.description}
          </p>
        </div>

        {/* Amenities Grid */}
        <div className="mt-5 bg-white p-6 rounded-3xl border border-gray-100 shadow-sm">
          <h3 className="text-sm font-bold text-gray-900 uppercase tracking-wider mb-4">Premium Amenities Included</h3>
          
          <div className="grid grid-cols-2 gap-4">
            <div className="flex items-center gap-3">
              <div className="h-9 w-9 rounded-xl bg-[#ebefec] text-[#0d631b] flex items-center justify-center">
                <Wifi size={18} />
              </div>
              <div>
                <p className="text-xs text-gray-500 font-medium">Internet</p>
                <p className="text-sm font-bold text-gray-800">High-Speed Wi-Fi</p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="h-9 w-9 rounded-xl bg-[#ebefec] text-[#0d631b] flex items-center justify-center">
                <Wind size={18} />
              </div>
              <div>
                <p className="text-xs text-gray-500 font-medium">Climate Control</p>
                <p className="text-sm font-bold text-gray-800">Air Conditioner</p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="h-9 w-9 rounded-xl bg-[#ebefec] text-[#0d631b] flex items-center justify-center">
                <Coffee size={18} />
              </div>
              <div>
                <p className="text-xs text-gray-500 font-medium">Mini-bar & Coffee</p>
                <p className="text-sm font-bold text-gray-800">Tea/Coffee Maker</p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="h-9 w-9 rounded-xl bg-[#ebefec] text-[#0d631b] flex items-center justify-center">
                <Tv size={18} />
              </div>
              <div>
                <p className="text-xs text-gray-500 font-medium">Entertainment</p>
                <p className="text-sm font-bold text-gray-800">Smart Flat TV</p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="h-9 w-9 rounded-xl bg-[#ebefec] text-[#0d631b] flex items-center justify-center">
                <Bath size={18} />
              </div>
              <div>
                <p className="text-xs text-gray-500 font-medium">Bathroom</p>
                <p className="text-sm font-bold text-gray-800">Luxury Toiletries</p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="h-9 w-9 rounded-xl bg-[#ebefec] text-[#0d631b] flex items-center justify-center">
                <Sparkles size={18} />
              </div>
              <div>
                <p className="text-xs text-gray-500 font-medium">Services</p>
                <p className="text-sm font-bold text-gray-800">Daily Housekeeping</p>
              </div>
            </div>
          </div>
        </div>

        {/* Reservation CTA Info Card */}
        <div className="mt-5 bg-gradient-to-br from-[#0d631b] to-[#1b5e20] text-white p-6 rounded-3xl shadow-md border border-green-800">
          <div className="flex justify-between items-center gap-4 flex-wrap">
            <div>
              <h3 className="font-extrabold text-lg">Interested in this room?</h3>
              <p className="text-xs text-white/80 mt-1">Contact the host resort to check stay availability or confirm booking.</p>
            </div>
            
            <a
              href="tel:+919876543210"
              className="bg-white text-[#0d631b] px-5 py-3 rounded-2xl font-bold text-sm shadow-sm hover:bg-gray-55 hover:scale-102 transition active:scale-98 flex items-center gap-2"
            >
              Contact Resort
            </a>
          </div>
        </div>
      </main>

      {/* Lightbox Modal */}
      {isLightboxOpen && (
        <div className="fixed inset-0 bg-black/95 z-50 flex items-center justify-center p-4">
          <button
            onClick={() => setIsLightboxOpen(false)}
            className="absolute top-4 right-4 text-white/70 hover:text-white h-10 w-10 bg-white/10 rounded-full flex items-center justify-center transition"
          >
            ✕
          </button>
          
          <div className="relative w-full max-w-3xl aspect-[4/3] max-h-[80vh]">
            <img
              src={activeRoom.images[currentImageIndex]}
              className="w-full h-full object-contain rounded-2xl"
              alt="lightbox zoomed view"
            />

            {/* Slider controls inside lightbox */}
            <button
              onClick={handlePrevImage}
              className="absolute left-4 top-1/2 -translate-y-1/2 h-11 w-11 bg-white/20 hover:bg-white/30 backdrop-blur-sm text-white rounded-full flex items-center justify-center transition"
            >
              <ChevronLeft size={24} />
            </button>
            
            <button
              onClick={handleNextImage}
              className="absolute right-4 top-1/2 -translate-y-1/2 h-11 w-11 bg-white/20 hover:bg-white/30 backdrop-blur-sm text-white rounded-full flex items-center justify-center transition"
            >
              <ChevronRight size={24} />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
