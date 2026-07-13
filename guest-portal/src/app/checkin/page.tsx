"use client";

import { useState } from "react";

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
            onSubmit={() => setStep(4)}
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