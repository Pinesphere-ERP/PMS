"use client";

import { useRouter } from "next/navigation";

import AppCard from "@/components/ui/AppCard";
import AppButton from "@/components/ui/AppButton";

export default function SuccessScreen() {
  const router = useRouter();

  return (
    <AppCard>

      <div className="flex flex-col items-center space-y-6 py-8">

        {/* Success Icon */}

        <div className="flex h-24 w-24 items-center justify-center rounded-full bg-green-100">

          <span className="text-5xl">
            ✅
          </span>

        </div>

        {/* Title */}

        <div className="text-center">

          <h2 className="text-3xl font-bold text-gray-800">
            Check-in Submitted
          </h2>

          <p className="mt-3 text-gray-500">

            Your check-in request has been submitted successfully.

          </p>

        </div>

        {/* Status */}

        <div className="w-full rounded-2xl bg-green-50 p-5">

          <h3 className="font-semibold text-green-700">

            Current Status

          </h3>

          <p className="mt-2">

            🟡 Waiting for Reception Approval

          </p>

        </div>

        {/* Info */}

        <div className="w-full rounded-2xl border border-gray-200 p-5">

          <p className="text-sm text-gray-600">

            You will receive an update once reception verifies your
            identity documents.

          </p>

        </div>

        {/* Button */}

        <AppButton
          title="Back to Home"
          onClick={() => router.push("/")}
        />

      </div>

    </AppCard>
  );
}