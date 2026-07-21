"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { api } from "@/lib/api";
import { useAuthStore } from "@/store/useAuthStore";
import axios from "axios";

export default function Login() {
  const router = useRouter();
  const login = useAuthStore((state) => state.login);
  const [bookingReference, setBookingReference] = useState("");
  const [mobileNumber, setMobileNumber] = useState("");
  const [otp, setOtp] = useState("");
  const [step, setStep] = useState<"request" | "verify">("request");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleRequestOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      await api.post("/portal/auth/request-otp", {
        booking_reference: bookingReference,
        mobile_number: mobileNumber,
      });
      setStep("verify");
    } catch (err: unknown) {
      if (axios.isAxiosError(err)) {
        setError(err.response?.data?.detail || "Failed to request OTP. Please check your credentials.");
      } else {
        setError("An unexpected error occurred.");
      }
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const res = await api.post("/portal/auth/verify-otp", {
        booking_reference: bookingReference,
        mobile_number: mobileNumber,
        otp,
      });
      
      login(res.data);
      router.push("/dashboard");
    } catch (err: unknown) {
      if (axios.isAxiosError(err)) {
        setError(err.response?.data?.detail || "Invalid OTP. Please try again.");
      } else {
        setError("An unexpected error occurred.");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-900 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <h2 className="mt-6 text-center text-3xl font-extrabold text-white">
          Guest Portal Login
        </h2>
        <p className="mt-2 text-center text-sm text-gray-400">
          Enter your booking reference and registered phone number to receive an OTP
        </p>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-gray-800 py-8 px-4 shadow sm:rounded-lg sm:px-10 border border-gray-700">
          {error && (
            <div className="mb-4 bg-red-500/10 border border-red-500 text-red-500 px-4 py-3 rounded text-sm">
              {error}
            </div>
          )}

          {step === "request" ? (
            <form className="space-y-6" onSubmit={handleRequestOtp}>
              <div>
                <label htmlFor="bookingRef" className="block text-sm font-medium text-gray-300">
                  Booking Reference
                </label>
                <div className="mt-1">
                  <input
                    id="bookingRef"
                    name="bookingRef"
                    type="text"
                    required
                    value={bookingReference}
                    onChange={(e) => setBookingReference(e.target.value)}
                    placeholder="e.g. BK-12345"
                    className="appearance-none block w-full px-3 py-2 border border-gray-600 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-gray-700 text-white"
                  />
                </div>
              </div>

              <div>
                <label htmlFor="phone" className="block text-sm font-medium text-gray-300">
                  Phone Number
                </label>
                <div className="mt-1">
                  <input
                    id="phone"
                    name="phone"
                    type="text"
                    required
                    value={mobileNumber}
                    onChange={(e) => setMobileNumber(e.target.value)}
                    placeholder="+91XXXXXXXXXX"
                    className="appearance-none block w-full px-3 py-2 border border-gray-600 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-gray-700 text-white"
                  />
                </div>
              </div>

              <div>
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 transition-colors"
                >
                  {loading ? "Sending..." : "Send OTP"}
                </button>
              </div>
            </form>
          ) : (
            <form className="space-y-6" onSubmit={handleVerifyOtp}>
              <div>
                <label htmlFor="otp" className="block text-sm font-medium text-gray-300">
                  Enter 6-digit OTP
                </label>
                <div className="mt-1">
                  <input
                    id="otp"
                    name="otp"
                    type="text"
                    required
                    value={otp}
                    onChange={(e) => setOtp(e.target.value)}
                    placeholder="123456"
                    className="appearance-none block w-full px-3 py-2 border border-gray-600 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm bg-gray-700 text-white"
                  />
                </div>
              </div>

              <div>
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50 transition-colors"
                >
                  {loading ? "Verifying..." : "Verify & Login"}
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}
