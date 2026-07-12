import {
  ClipboardCheck,
  BrushCleaning,
  CreditCard,
  Receipt,
} from "lucide-react";

import SectionHeader from "@/components/ui/SectionHeader";
import QuickActionCard from "./QuickActionCard";

export default function QuickActions() {
  return (
    <section className="mt-8">

      <SectionHeader
        title="Quick Actions"
        subtitle="Manage your stay"
      />

      <div className="mt-4 grid grid-cols-2 gap-4">

        <QuickActionCard
          title="Check-in"
          subtitle="Complete online"
          href="/checkin"
          icon={ClipboardCheck}
        />

        <QuickActionCard
          title="Housekeeping"
          subtitle="Request service"
          href="/services"
          icon={BrushCleaning}
        />

        <QuickActionCard
          title="Payments"
          subtitle="Pay balance"
          href="/payments"
          icon={CreditCard}
        />

        <QuickActionCard
          title="Invoice"
          subtitle="Download PDF"
          href="/invoices"
          icon={Receipt}
        />

      </div>

    </section>
  );
}