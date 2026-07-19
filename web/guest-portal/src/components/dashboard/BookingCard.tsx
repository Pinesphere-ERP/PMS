import { CalendarDays, BedDouble, BadgeCheck } from "lucide-react";

interface BookingCardProps {
  roomNumber: string;
  checkIn: string;
  checkOut: string;
  status: string;
}

export default function BookingCard({
  roomNumber,
  checkIn,
  checkOut,
  status,
}: BookingCardProps) {
  return (
    <section className="mx-auto mt-4 max-w-md px-4">
      <div className="rounded-2xl bg-white p-5 shadow-sm border">

        <div className="mb-4 flex items-center justify-between">
          <h3 className="text-lg font-semibold text-gray-800">
            Booking Summary
          </h3>

          <BadgeCheck className="h-5 w-5 text-green-500" />
        </div>

        <div className="space-y-4">

          <div className="flex items-center gap-3">
            <BedDouble className="h-5 w-5 text-blue-600" />

            <div>
              <p className="text-xs text-gray-500">
                Room Number
              </p>

              <p className="font-medium">
                {roomNumber}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <CalendarDays className="h-5 w-5 text-blue-600" />

            <div>
              <p className="text-xs text-gray-500">
                Stay Duration
              </p>

              <p className="font-medium">
                {checkIn} → {checkOut}
              </p>
            </div>
          </div>

          <div className="flex items-center justify-between rounded-xl bg-green-50 px-4 py-3">
            <span className="text-sm text-gray-600">
              Booking Status
            </span>

            <span className="rounded-full bg-green-100 px-3 py-1 text-sm font-semibold text-green-700">
              {status}
            </span>
          </div>

        </div>
      </div>
    </section>
  );
}