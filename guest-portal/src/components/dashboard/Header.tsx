import { Bell, Hotel } from "lucide-react";

interface HeaderProps {
  propertyName: string;
  guestName: string;
}

export default function Header({
  propertyName,
  guestName,
}: HeaderProps) {
  return (
    <header className="sticky top-0 z-50 bg-white border-b shadow-sm">
      <div className="mx-auto flex max-w-md items-center justify-between px-4 py-3">
        <div className="flex items-center gap-3">
          <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-blue-100">
            <Hotel className="h-6 w-6 text-blue-600" />
          </div>

          <div>
            <h1 className="text-lg font-bold text-gray-800">
              {propertyName}
            </h1>
            <p className="text-xs text-gray-500">
              Guest Portal
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <button className="relative">
            <Bell className="h-5 w-5 text-gray-600" />
            <span className="absolute -right-1 -top-1 h-2 w-2 rounded-full bg-red-500" />
          </button>

          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-blue-600 font-semibold text-white">
            {guestName.charAt(0).toUpperCase()}
          </div>
        </div>
      </div>
    </header>
  );
}