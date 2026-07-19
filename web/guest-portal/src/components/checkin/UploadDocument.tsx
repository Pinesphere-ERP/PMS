"use client";
import { useRef, Dispatch, SetStateAction } from "react";
import AppCard from "@/components/ui/AppCard";
import AppButton from "@/components/ui/AppButton";
import { CheckinData } from "@/types/checkin";

interface Props {
  data: CheckinData;
  setData: Dispatch<SetStateAction<CheckinData>>;
  onBack: () => void;
  onNext: () => void;
}

export default function UploadDocument({
  data,
  setData,
  onBack,
  onNext,
}: Props) {
  const inputRef = useRef<HTMLInputElement>(null);

  function handlePick() {
    inputRef.current?.click();
  }

  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    if (!e.target.files?.length) return;
    const file = e.target.files[0];
    setData((prev) => ({
      ...prev,
      document: file,
    }));
  }

  function validate() {
    if (!data.document) {
      alert("Please upload a government-issued ID.");
      return;
    }
    onNext();
  }

  return (
    <AppCard>
      <div className="space-y-5">
        <div>
          <h2 className="text-xl font-bold text-gray-800">
            Verify Your Identity
          </h2>
          <p className="text-sm text-gray-500">
            Upload a government-issued ID.
          </p>
        </div>

        <button
          onClick={handlePick}
          className="flex h-40 w-full flex-col items-center justify-center gap-2 rounded-2xl border-2 border-dashed border-green-500 bg-green-50/50 p-4 transition hover:bg-green-50"
        >
          {data.document ? (
            <div className="text-center">
              <span className="text-3xl">📄</span>
              <p className="mt-2 text-sm font-semibold text-green-800 break-all">
                {data.document.name}
              </p>
              <p className="text-xs text-gray-500 mt-1">
                Tap to change document
              </p>
            </div>
          ) : (
            <div className="text-center text-gray-500">
              <span className="text-3xl">📤</span>
              <p className="mt-2 font-medium text-green-700">
                Upload Aadhaar / Passport
              </p>
              <p className="text-xs text-gray-400 mt-1">
                Supports JPG, PNG or PDF
              </p>
            </div>
          )}
        </button>

        <input
          ref={inputRef}
          hidden
          type="file"
          accept="image/*,.pdf"
          onChange={handleChange}
        />

        <div className="flex gap-3">
          <button
            onClick={onBack}
            className="flex-1 rounded-2xl border border-gray-300 py-3 font-semibold text-gray-700 hover:bg-gray-50 active:scale-95 transition"
          >
            Back
          </button>
          <div className="flex-1">
            <AppButton
              title="Continue"
              onClick={validate}
            />
          </div>
        </div>
      </div>
    </AppCard>
  );
}