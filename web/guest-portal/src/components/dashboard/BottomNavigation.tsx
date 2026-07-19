"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  House,
  ConciergeBell,
  CreditCard,
  User,
} from "lucide-react";

const navItems = [
  {
    label: "Home",
    href: "/",
    icon: House,
  },
  {
    label: "Services",
    href: "/services",
    icon: ConciergeBell,
  },
  {
    label: "Payments",
    href: "/payments",
    icon: CreditCard,
  },
  {
    label: "Profile",
    href: "/profile",
    icon: User,
  },
];

export default function BottomNavigation() {
  const pathname = usePathname();

  return (
    <nav className="fixed bottom-5 left-1/2 z-50 w-[92%] max-w-md -translate-x-1/2 rounded-3xl border border-green-100 bg-white/90 shadow-xl backdrop-blur-lg">

      <div className="flex justify-around py-3">

        {navItems.map((item) => {
          const Icon = item.icon;

          // Robust path matching that handles trailing slashes
          const active = 
            pathname === item.href || 
            pathname?.replace(/\/$/, "") === item.href.replace(/\/$/, "");

          return (
            <Link
              key={item.label}
              href={item.href}
              className="flex flex-col items-center gap-0.5 sm:gap-1 cursor-pointer"
            >
              <div
                className={`rounded-xl p-1.5 sm:p-2 transition ${
                  active
                    ? "bg-[#0d631b] text-white"
                    : "text-gray-500 hover:text-gray-800"
                }`}
              >
                <Icon size={20} className="sm:w-[22px] sm:h-[22px]" />
              </div>

              <span
                className={`text-[10px] sm:text-xs transition-colors ${
                  active
                    ? "font-semibold text-[#0d631b]"
                    : "text-gray-500 hover:text-gray-800"
                }`}
              >
                {item.label}
              </span>
            </Link>
          );
        })}

      </div>

    </nav>
  );
}