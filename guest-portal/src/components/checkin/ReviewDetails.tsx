"use client";

import AppCard from "@/components/ui/AppCard";
import AppButton from "@/components/ui/AppButton";
import { CheckinData } from "@/types/checkin";

interface Props {
  data: CheckinData;
  onBack: () => void;
  onSubmit: () => void;
}

export default function ReviewDetails({
  data,
  onBack,
  onSubmit,
}: Props) {
  return (
    <AppCard>

      <div className="space-y-6">

        {/* Title */}
        <div>
          <h2 className="text-2xl font-bold text-gray-800">
            Review Details
          </h2>

          <p className="mt-1 text-sm text-gray-500">
            Please verify your information before submitting.
          </p>
        </div>

        {/* Personal Information */}
        <div className="rounded-2xl border border-gray-200 bg-gray-50 p-4">

          <h3 className="mb-4 text-lg font-semibold">
            Personal Information
          </h3>

          <div className="space-y-3">

            <ReviewRow
              label="First Name"
              value={data.firstName}
            />

            <ReviewRow
              label="Last Name"
              value={data.lastName}
            />

            <ReviewRow
              label="Phone"
              value={data.phone}
            />

            <ReviewRow
              label="Email"
              value={data.email}
            />

          </div>

        </div>

        {/* Document */}
        <div className="rounded-2xl border border-green-200 bg-green-50 p-4">

          <h3 className="mb-2 text-lg font-semibold">
            Uploaded Document
          </h3>

          {data.document ? (
            <div>

              <p className="font-medium text-green-700">
                ✅ {data.document.name}
              </p>

              <p className="mt-1 text-sm text-gray-500">
                Ready for submission
              </p>

            </div>
          ) : (
            <p className="text-red-500">
              No document uploaded.
            </p>
          )}

        </div>

        {/* Terms */}

        <div className="rounded-2xl bg-blue-50 p-4 text-sm text-gray-600">

          By submitting this form, you confirm that the
          information provided is correct.

        </div>

        {/* Buttons */}

        <div className="flex gap-3">

          <button
            onClick={onBack}
            className="flex-1 rounded-2xl border border-gray-300 py-3 font-semibold"
          >
            Back
          </button>

          <div className="flex-1">
            <AppButton
              title="Submit"
              onClick={onSubmit}
            />
          </div>

        </div>

      </div>

    </AppCard>
  );
}

interface RowProps {
  label: string;
  value: string;
}

function ReviewRow({
  label,
  value,
}: RowProps) {
  return (
    <div className="flex items-center justify-between">

      <span className="text-gray-500">
        {label}
      </span>

      <span className="font-medium text-gray-800">
        {value || "-"}
      </span>

    </div>
  );
}