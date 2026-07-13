interface WelcomeCardProps {
  guestName: string;
  roomNumber: string;
  roomType: string;
  checkIn: string;
  checkOut: string;
  status: string;
}

export default function WelcomeCard({
  guestName,
  roomNumber,
  roomType,
  checkIn,
  checkOut,
  status,
}: WelcomeCardProps) {
  return (
    <section className="mx-auto mt-4 max-w-md px-4">
      <div className="rounded-3xl bg-gradient-to-r from-blue-600 to-cyan-500 p-6 text-white shadow-lg">

        <p className="text-sm opacity-90">
          Welcome back 👋
        </p>

        <h2 className="mt-1 text-2xl font-bold">
          {guestName}
        </h2>

        <div className="mt-5 grid grid-cols-2 gap-4">

          <div>
            <p className="text-xs opacity-80">
              Room
            </p>

            <p className="font-semibold">
              {roomNumber}
            </p>

            <p className="text-sm opacity-90">
              {roomType}
            </p>
          </div>

          <div>
            <p className="text-xs opacity-80">
              Status
            </p>

            <span className="inline-block rounded-full bg-white/20 px-3 py-1 text-sm font-medium">
              {status}
            </span>
          </div>

        </div>

        <div className="mt-6 rounded-2xl bg-white/15 p-4">

          <p className="text-xs opacity-80">
            Stay Duration
          </p>

          <div className="mt-2 flex items-center justify-between">

            <div>
              <p className="text-xs opacity-80">
                Check-In
              </p>

              <p className="font-semibold">
                {checkIn}
              </p>
            </div>

            <div className="text-xl">
              →
            </div>

            <div className="text-right">
              <p className="text-xs opacity-80">
                Check-Out
              </p>

              <p className="font-semibold">
                {checkOut}
              </p>
            </div>

          </div>

        </div>

      </div>
    </section>
  );
}