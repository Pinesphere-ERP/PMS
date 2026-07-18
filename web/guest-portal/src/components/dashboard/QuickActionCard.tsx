import Link from "next/link";
import { LucideIcon } from "lucide-react";

interface QuickActionCardProps {
  title: string;
  subtitle: string;
  href: string;
  icon: LucideIcon;
}

export default function QuickActionCard({
  title,
  subtitle,
  href,
  icon: Icon,
}: QuickActionCardProps) {
  return (
    <Link href={href}>
      <div className="group cursor-pointer rounded-3xl bg-[#ebefec] border border-green-100 p-5 transition-all duration-300 hover:-translate-y-1 hover:shadow-xl hover:border-[#0d631b]/30">

        <div className="mb-5 flex h-14 w-14 items-center justify-center rounded-2xl bg-[#0d631b] text-white transition-transform duration-300 group-hover:scale-110">
          <Icon size={26} />
        </div>

        <h3 className="text-base font-semibold text-[#1d2b1f]">
          {title}
        </h3>

        <p className="mt-1 text-sm text-gray-500">
          {subtitle}
        </p>

      </div>
    </Link>
  );
}