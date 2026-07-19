import {
  BedDouble,
  Wifi,
  Coffee,
  Clock3,
  Phone,
} from "lucide-react";

import AppCard from "@/components/ui/AppCard";
import SectionHeader from "@/components/ui/SectionHeader";

interface RoomInfoProps {
  roomNumber: string;
  roomType: string;
}

export default function RoomInfo({
  roomNumber,
  roomType,
}: RoomInfoProps) {
  return (
    <section className="mt-8">

      <SectionHeader
        title="Room Information"
        subtitle="Everything you need during your stay"
      />

      <AppCard className="mt-4">

        <div className="space-y-5">

          <InfoRow
            icon={<BedDouble size={22} />}
            title="Room"
            value={`${roomType} • ${roomNumber}`}
          />

          <InfoRow
            icon={<Wifi size={22} />}
            title="Wi-Fi"
            value="Pinesphere Guest"
          />

          <InfoRow
            icon={<Coffee size={22} />}
            title="Breakfast"
            value="07:00 AM - 10:00 AM"
          />

          <InfoRow
            icon={<Clock3 size={22} />}
            title="Check-out"
            value="11:00 AM"
          />

          <InfoRow
            icon={<Phone size={22} />}
            title="Reception"
            value="+91 98765 43210"
          />

        </div>

      </AppCard>

    </section>
  );
}

interface InfoRowProps {
  icon: React.ReactNode;
  title: string;
  value: string;
}

function InfoRow({
  icon,
  title,
  value,
}: InfoRowProps) {
  return (
    <div className="flex items-center gap-4">

      <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#0d631b] text-white">
        {icon}
      </div>

      <div>

        <p className="text-sm text-gray-500">
          {title}
        </p>

        <p className="font-semibold text-[#1d2b1f]">
          {value}
        </p>

      </div>

    </div>
  );
}   