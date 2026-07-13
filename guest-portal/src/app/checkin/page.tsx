"use client";

import { useState } from "react";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";

import Header from "@/components/dashboard/Header";
import BottomNavigation from "@/components/dashboard/BottomNavigation";
import AppContainer from "@/components/ui/AppContainer";

import ProgressIndicator from "@/components/checkin/ProgressIndicator";
import PersonalDetails from "@/components/checkin/PersonalDetails";
import UploadDocument from "@/components/checkin/UploadDocument";
import ReviewDetails from "@/components/checkin/ReviewDetails";
import SuccessScreen from "@/components/checkin/SuccessScreen";

import { CheckinData } from "@/types/checkin";

export default function CheckinPage() {
  const [step, setStep] = useState(1);

  const [data, setData] = useState<CheckinData>({
    firstName: "",
    lastName: "",
    phone: "",
    email: "",
    document: null,
  });

  return (
    <>
      <Header
        propertyName="Pinesphere Stay"
        guestName={data.firstName || "Guest"}
      />

      <AppContainer>
        {/* Back Link */}
        {step < 4 && (
          <div className="mb-4">
            <Link
              href="/"
              className="inline-flex items-center gap-2 text-sm font-semibold text-[#0d631b] hover:opacity-80 transition"
            >
              <ArrowLeft size={16} />
              Back to Dashboard
            </Link>
          </div>
        )}

        <ProgressIndicator step={step} />

        {step === 1 && (
          <PersonalDetails
            data={data}
            setData={setData}
            onNext={() => setStep(2)}
          />
        )}

        {step === 2 && (
          <UploadDocument
            data={data}
            setData={setData}
            onBack={() => setStep(1)}
            onNext={() => setStep(3)}
          />
        )}

        {step === 3 && (
          <ReviewDetails
            data={data}
            onBack={() => setStep(2)}
            onSubmit={() => {
              localStorage.setItem("checkinStatus", "Pending");
              localStorage.setItem("checkinData", JSON.stringify({
                firstName: data.firstName,
                lastName: data.lastName,
                phone: data.phone,
                email: data.email,
                documentName: data.document?.name || "Uploaded ID"
              }));
              setStep(4);
            }}
          />
        )}

        {step === 4 && (
          <SuccessScreen />
        )}

      </AppContainer>

      <BottomNavigation />
    </>
  );
}