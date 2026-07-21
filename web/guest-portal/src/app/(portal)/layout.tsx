"use client";

import AuthGuard from "@/components/AuthGuard";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, Bed, Hotel, Coffee, FileText } from "lucide-react";

export default function PortalLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  const navItems = [
    { name: "Home", href: "/dashboard", icon: Home },
    { name: "Stay", href: "/stay", icon: Bed },
    { name: "Room", href: "/room", icon: Hotel },
    { name: "Amenities", href: "/amenities", icon: Coffee },
    { name: "Folio", href: "/folio", icon: FileText },
  ];

  return (
    <AuthGuard>
      <div className="flex flex-col h-screen bg-gray-950 text-gray-100">
        <main className="flex-1 overflow-y-auto pb-20">
          {children}
        </main>
        
        {/* Bottom Navigation */}
        <nav className="fixed bottom-0 w-full bg-gray-900 border-t border-gray-800 pb-safe">
          <div className="flex justify-around items-center h-16">
            {navItems.map((item) => {
              const isActive = pathname.startsWith(item.href);
              const Icon = item.icon;
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className={`flex flex-col items-center justify-center w-full h-full space-y-1 ${
                    isActive ? "text-blue-500" : "text-gray-400 hover:text-gray-300"
                  }`}
                >
                  <Icon size={20} />
                  <span className="text-[10px] font-medium">{item.name}</span>
                </Link>
              );
            })}
          </div>
        </nav>
      </div>
    </AuthGuard>
  );
}
