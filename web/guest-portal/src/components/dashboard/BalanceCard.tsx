import { CreditCard, ShieldCheck } from "lucide-react";

import AppButton from "@/components/ui/AppButton";
import AppCard from "@/components/ui/AppCard";
import SectionHeader from "@/components/ui/SectionHeader";

interface BalanceCardProps {
  balance: number;
}

export default function BalanceCard({
  balance,
}: BalanceCardProps) {
  return (
    <section className="mt-8">

      <SectionHeader
        title="Outstanding Balance"
        subtitle="Secure online payment"
      />

      <AppCard className="mt-4">

        <div className="flex items-center justify-between">

          <div>

            <p className="text-sm text-gray-500">
              Amount Due
            </p>

            <h2 className="mt-1 text-4xl font-bold text-[#0d631b]">
              ₹{balance.toLocaleString()}
            </h2>

          </div>

          <div className="flex h-16 w-16 items-center justify-center rounded-3xl bg-[#0d631b] text-white">
            <CreditCard size={32} />
          </div>

        </div>

        <div className="mt-6 rounded-2xl bg-green-50 p-4">

          <div className="flex items-center gap-3">

            <ShieldCheck
              className="text-green-700"
              size={22}
            />

            <div>

              <p className="font-medium text-green-800">
                Secure Payment
              </p>

              <p className="text-sm text-green-700">
                UPI • Cards • Net Banking
              </p>

            </div>

          </div>

        </div>

        <div className="mt-6">
          <AppButton title="Pay Now" />
        </div>

      </AppCard>

    </section>
  );
}