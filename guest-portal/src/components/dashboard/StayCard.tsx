import { CalendarDays, BedDouble, MapPin } from "lucide-react";
import AppBadge from "@/components/ui/AppBadge";
import AppCard from "@/components/ui/AppCard";

interface StayCardProps {
  guestName: string;
  propertyName: string;
  roomNumber: string;
  roomType: string;
  checkIn: string;
  checkOut: string;
  status: string;
}

export default function StayCard({
  guestName,
  propertyName,
  roomNumber,
  roomType,
  checkIn,
  checkOut,
  status,
}: StayCardProps) {
  return (
    <section className="mt-5">
      <div className="relative overflow-hidden rounded-[32px] bg-gradient-to-br from-[#0d631b] via-[#2d7a39] to-[#3c6840] p-6 text-white shadow-[0_20px_50px_rgba(13,99,27,0.25)]">

        {/* Decorative circles */}
        <div className="absolute -right-10 -top-10 h-40 w-40 rounded-full bg-white/10 blur-2xl" />
        <div className="absolute -left-8 bottom-0 h-24 w-24 rounded-full bg-white/5 blur-xl" />

        <div className="relative z-10">

          <p className="text-sm text-white/80">
            Welcome Back 👋
          </p>

          <h1 className="mt-1 text-3xl font-bold">
            {guestName}
          </h1>

          <div className="mt-2 flex items-center gap-2 text-white/90">
            <MapPin size={16} />
            <span className="text-sm">
              {propertyName}
            </span>
          </div>

          <div className="mt-6 flex items-center justify-between rounded-3xl bg-white/10 p-4 backdrop-blur-md">

            <div className="flex items-center gap-3">

              <div className="rounded-2xl bg-white/15 p-3">
                <BedDouble size={22} />
              </div>

              <div>
                <p className="text-xs text-white/70">
                  Your Room
                </p>

                <h3 className="font-semibold">
                  {roomNumber}
                </h3>

                <p className="text-sm text-white/80">
                  {roomType}
                </p>
              </div>

            </div>

            <AppBadge title={status} />

          </div>

          <div className="mt-5 flex items-center gap-3 rounded-3xl bg-white/10 p-4 backdrop-blur-md">

            <CalendarDays size={22} />

            <div>

              <p className="text-xs text-white/70">
                Stay Duration
              </p>

              <p className="font-medium">
                {checkIn} → {checkOut}
              </p>

            </div>

          </div>

        </div>
      </div>
    </section>
  );
}