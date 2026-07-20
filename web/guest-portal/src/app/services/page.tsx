"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import {
  Brush,
  Wind,
  Droplet,
  Package,
  Soup,
  Utensils,
  Coffee,
  Sparkles,
  Luggage,
  Clock,
  Car,
  CheckCircle,
  Loader2,
  ArrowLeft,
} from "lucide-react";
import Header from "@/components/dashboard/Header";
import BottomNavigation from "@/components/dashboard/BottomNavigation";
import AppContainer from "@/components/ui/AppContainer";
import AppCard from "@/components/ui/AppCard";
import SectionHeader from "@/components/ui/SectionHeader";
import { guest } from "@/data/guest";
import { fetchAPI } from "@/services/api";

interface ServiceItem {
  id: string;
  name: string;
  description: string;
  icon: any;
  category: "housekeeping" | "dining" | "frontdesk";
}

const SERVICES_LIST: ServiceItem[] = [
  {
    id: "clean",
    name: "Room Cleaning",
    description: "Standard daily room refresh and dusting",
    icon: Brush,
    category: "housekeeping",
  },
  {
    id: "towels",
    name: "Fresh Towels",
    description: "Extra set of fresh bath & hand towels",
    icon: Wind,
    category: "housekeeping",
  },
  {
    id: "water",
    name: "Bottled Water",
    description: "Complementary Himalayan spring water",
    icon: Droplet,
    category: "housekeeping",
  },
  {
    id: "toiletries",
    name: "Toiletries Pack",
    description: "Eco-friendly shampoo, soap & dental kit",
    icon: Package,
    category: "housekeeping",
  },
  {
    id: "ice",
    name: "Ice Bucket",
    description: "Fresh ice delivered in insulated container",
    icon: Sparkles,
    category: "dining",
  },
  {
    id: "cutlery",
    name: "Request Cutlery",
    description: "Extra spoons, forks, knives or plates",
    icon: Utensils,
    category: "dining",
  },
  {
    id: "coffee",
    name: "Coffee Refill",
    description: "Additional gourmet drip coffee & tea bags",
    icon: Coffee,
    category: "dining",
  },
  {
    id: "luggage",
    name: "Luggage Help",
    description: "Request bellboy assistance at your door",
    icon: Luggage,
    category: "frontdesk",
  },
  {
    id: "wakeup",
    name: "Wake-up Call",
    description: "Schedule a morning wake-up call",
    icon: Clock,
    category: "frontdesk",
  },
  {
    id: "taxi",
    name: "Book a Taxi",
    description: "Request cab booking for local transit",
    icon: Car,
    category: "frontdesk",
  },
];

export default function ServicesPage() {
  const [guestName, setGuestName] = useState(guest.guestName);
  const [requests, setRequests] = useState<Record<string, { status: "sending" | "sent"; time: string }>>({});

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

    // Load active requests
    const savedRequests = localStorage.getItem("guestServicesRequests");
    if (savedRequests) {
      try {
        setRequests(JSON.parse(savedRequests));
      } catch (e) {
        console.error(e);
      }
    }
  }, []);

  const handleRequest = async (serviceId: string) => {
    const service = SERVICES_LIST.find(s => s.id === serviceId);
    if (!service) return;

    // Optimistic sending state
    const newRequests = {
      ...requests,
      [serviceId]: {
        status: "sending" as const,
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      },
    };
    setRequests(newRequests);

    try {
      await fetchAPI('/portal/services', {
        method: 'POST',
        body: JSON.stringify({
          service_type: service.category === 'dining' ? 'room_service' : service.category,
          description: service.name,
        }),
      });

      const updatedRequests = {
        ...requests,
        [serviceId]: {
          status: "sent" as const,
          time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        },
      };
      setRequests(updatedRequests);
      localStorage.setItem("guestServicesRequests", JSON.stringify(updatedRequests));
    } catch (err) {
      console.error("Service request failed", err);
      // Revert optimistic state on failure
      const reverted = { ...requests };
      delete reverted[serviceId];
      setRequests(reverted);
    }
  };

  const renderServiceSection = (category: "housekeeping" | "dining" | "frontdesk", title: string, subtitle: string) => {
    const items = SERVICES_LIST.filter((s) => s.category === category);

    return (
      <div className="mb-6">
        <SectionHeader title={title} subtitle={subtitle} />
        <div className="space-y-3 mt-3">
          {items.map((item) => {
            const Icon = item.icon;
            const reqState = requests[item.id];

            return (
              <AppCard key={item.id} className="p-4 transition hover:border-[#0d631b]/20">
                <div className="flex items-center gap-4">
                  <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-[#ebefec] text-[#0d631b]">
                    <Icon size={20} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <h3 className="font-semibold text-gray-800 text-sm truncate">
                      {item.name}
                    </h3>
                    <p className="text-xs text-gray-500 truncate">
                      {item.description}
                    </p>
                  </div>
                  <div className="shrink-0">
                    {reqState?.status === "sending" ? (
                      <button
                        disabled
                        className="flex items-center gap-1 rounded-xl bg-gray-100 text-gray-500 px-3 py-1.5 text-xs font-semibold"
                      >
                        <Loader2 className="h-3.5 w-3.5 animate-spin" />
                        <span>Sending</span>
                      </button>
                    ) : reqState?.status === "sent" ? (
                      <div className="flex flex-col items-end gap-0.5">
                        <span className="flex items-center gap-1 rounded-xl bg-green-50 border border-green-200 text-green-700 px-3 py-1.5 text-xs font-bold shadow-sm">
                          <CheckCircle className="h-3.5 w-3.5 text-green-600" />
                          <span>Sent</span>
                        </span>
                        <span className="text-[10px] text-gray-400 font-medium">
                          {reqState.time}
                        </span>
                      </div>
                    ) : (
                      <button
                        onClick={() => handleRequest(item.id)}
                        className="rounded-xl border border-green-200 text-[#0d631b] hover:bg-[#0d631b] hover:text-white px-4 py-1.5 text-xs font-bold transition-all active:scale-95 cursor-pointer"
                      >
                        Request
                      </button>
                    )}
                  </div>
                </div>
              </AppCard>
            );
          })}
        </div>
      </div>
    );
  };

  return (
    <>
      <Header
        propertyName={guest.propertyName}
        guestName={guestName}
      />

      <AppContainer>
        <div className="mb-4">
          <Link
            href="/"
            className="inline-flex items-center gap-2 text-sm font-semibold text-[#0d631b] hover:opacity-80 transition"
          >
            <ArrowLeft size={16} />
            Back to Dashboard
          </Link>
        </div>

        <div className="mb-4">
          <SectionHeader
            title="Room Services"
            subtitle="One-tap requests direct to resort staff"
          />
        </div>

        {/* Housekeeping Section */}
        {renderServiceSection(
          "housekeeping",
          "Housekeeping & Cleaning",
          "Maintain your room comfort"
        )}

        {/* Room Dining Section */}
        {renderServiceSection(
          "dining",
          "Room Dining Amenities",
          "Dine with convenience"
        )}

        {/* Front Desk Section */}
        {renderServiceSection(
          "frontdesk",
          "Front Desk & Concierge",
          "Luggage, taxis and planning"
        )}
      </AppContainer>

      <BottomNavigation />
    </>
  );
}
