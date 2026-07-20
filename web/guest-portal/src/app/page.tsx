"use client";

import { useEffect, useState } from "react";
import Header from "@/components/dashboard/Header";
import StayCard from "@/components/dashboard/StayCard";
import QuickActions from "@/components/dashboard/QuickActions";
import AppContainer from "@/components/ui/AppContainer";
import RoomInfo from "@/components/dashboard/RoomInfo";
import BalanceCard from "@/components/dashboard/BalanceCard";
import BottomNavigation from "@/components/dashboard/BottomNavigation";
import { fetchAPI } from "@/services/api";

export default function Home() {
  const [guestName, setGuestName] = useState("Loading...");
  const [status, setStatus] = useState("Pending");
  const [balance, setBalance] = useState(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const savedStatus = localStorage.getItem("checkinStatus");
    const savedData = localStorage.getItem("checkinData");
    const savedBalance = localStorage.getItem("paymentBalance");

    if (savedStatus === "Pending") {
      setStatus("Pending Approval");
    } else if (savedStatus === "Approved") {
      setStatus("Checked In");
    }

    if (savedData) {
      try {
        const parsed = JSON.parse(savedData);
        if (parsed.firstName) {
          setGuestName(parsed.firstName);
        }
      } catch (e) {
        console.error(e);
      }
    }

    if (savedBalance !== null && savedBalance !== undefined) {
      setBalance(Number(savedBalance));
    }

    // Fetch real user data
    fetchAPI('/portal/me')
      .then((data) => {
        if (data.name) {
          setGuestName(data.name);
        }
      })
      .catch((err) => {
        console.error("Failed to fetch user:", err);
      })
      .finally(() => {
        setLoading(false);
      });
  }, []);

  if (loading) {
    return <div className="min-h-screen bg-gray-900 flex items-center justify-center text-white">Loading...</div>;
  }

  return (
    <>
      <Header
        propertyName="Pinesphere Stay"
        guestName={guestName}
      />

      <AppContainer>
        <StayCard
          guestName={guestName}
          propertyName="Pinesphere Stay"
          roomNumber="101"
          roomType="Deluxe Suite"
          checkIn="2026-07-20"
          checkOut="2026-07-25"
          status={status}
        />
        <QuickActions status={status} />
        <RoomInfo
          roomNumber="101"
          roomType="Deluxe Suite"
        />
        <BalanceCard balance={balance} />
      </AppContainer>
      <BottomNavigation />
    </>
  );
}