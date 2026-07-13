"use client";

import { useRef, useState } from "react";

import AppCard from "@/components/ui/AppCard";
import AppButton from "@/components/ui/AppButton";

export default function UploadDocument() {
  const inputRef = useRef<HTMLInputElement>(null);

  const [file, setFile] = useState<File | null>(null);

  function handlePick() {
    inputRef.current?.click();
  }

  function handleChange(
    e: React.ChangeEvent<HTMLInputElement>
  ) {
    if (!e.target.files?.length) return;

    setFile(e.target.files[0]);
  }

  return (
    <AppCard>

      <div className="space-y-5">

        <div>

          <h2 className="text-xl font-bold">
            Verify Your Identity
          </h2>

          <p className="text-sm text-gray-500">
            Upload a government-issued ID.
          </p>

        </div>

        <button
          onClick={handlePick}
          className="flex h-40 w-full items-center justify-center rounded-2xl border-2 border-dashed border-green-500 bg-green-50"
        >

          {file ? (
            <span className="font-medium">
              {file.name}
            </span>
          ) : (
            <span>
              📄 Upload Aadhaar
            </span>
          )}

        </button>

        <input
          ref={inputRef}
          hidden
          type="file"
          accept="image/*,.pdf"
          onChange={handleChange}
        />

        <AppButton
          title="Continue"
        />

      </div>

    </AppCard>
  );
}