"use client";

import { Dispatch, SetStateAction } from "react";

import AppCard from "@/components/ui/AppCard";
import AppButton from "@/components/ui/AppButton";

import { CheckinData } from "@/types/checkin";

interface Props {
  data: CheckinData;
  setData: Dispatch<SetStateAction<CheckinData>>;
  onNext: () => void;
}

export default function PersonalDetails({
  data,
  setData,
  onNext,
}: Props) {
  function update(field: keyof CheckinData, value: string) {
    setData((prev) => ({
      ...prev,
      [field]: value,
    }));
  }

  function validate() {
    if (!data.firstName.trim()) {
      alert("Please enter your first name.");
      return;
    }

    if (!data.lastName.trim()) {
      alert("Please enter your last name.");
      return;
    }

    if (!data.phone.trim()) {
      alert("Please enter your phone number.");
      return;
    }

    if (!data.email.trim()) {
      alert("Please enter your email.");
      return;
    }

    onNext();
  }

  return (
    <AppCard>

      <div className="space-y-5">

        <div>
          <h2 className="text-2xl font-bold text-gray-800">
            Personal Details
          </h2>

          <p className="mt-1 text-sm text-gray-500">
            Please confirm your details before check-in.
          </p>
        </div>

        {/* First Name */}
        <div>
          <label className="mb-2 block text-sm font-medium text-gray-700">
            First Name
          </label>

          <input
            type="text"
            value={data.firstName}
            onChange={(e) => update("firstName", e.target.value)}
            placeholder="Enter first name"
            className="w-full rounded-2xl border border-gray-300 px-4 py-3 text-base outline-none transition focus:border-green-600 focus:ring-2 focus:ring-green-100"
          />
        </div>

        {/* Last Name */}
        <div>
          <label className="mb-2 block text-sm font-medium text-gray-700">
            Last Name
          </label>

          <input
            type="text"
            value={data.lastName}
            onChange={(e) => update("lastName", e.target.value)}
            placeholder="Enter last name"
            className="w-full rounded-2xl border border-gray-300 px-4 py-3 text-base outline-none transition focus:border-green-600 focus:ring-2 focus:ring-green-100"
          />
        </div>

        {/* Phone */}
        <div>
          <label className="mb-2 block text-sm font-medium text-gray-700">
            Phone Number
          </label>

          <input
            type="tel"
            value={data.phone}
            onChange={(e) => update("phone", e.target.value)}
            placeholder="+91 XXXXX XXXXX"
            className="w-full rounded-2xl border border-gray-300 px-4 py-3 text-base outline-none transition focus:border-green-600 focus:ring-2 focus:ring-green-100"
          />
        </div>

        {/* Email */}
        <div>
          <label className="mb-2 block text-sm font-medium text-gray-700">
            Email Address
          </label>

          <input
            type="email"
            value={data.email}
            onChange={(e) => update("email", e.target.value)}
            placeholder="example@email.com"
            className="w-full rounded-2xl border border-gray-300 px-4 py-3 text-base outline-none transition focus:border-green-600 focus:ring-2 focus:ring-green-100"
          />
        </div>

        <AppButton
          title="Continue"
          onClick={validate}
        />

      </div>

    </AppCard>
  );
}