"use client";

import { useEffect, useState } from "react";
import Header from "@/components/dashboard/Header";
import StayCard from "@/components/dashboard/StayCard";
import QuickActions from "@/components/dashboard/QuickActions";
import AppContainer from "@/components/ui/AppContainer";
import RoomInfo from "@/components/dashboard/RoomInfo";
import { guest } from "@/data/guest";
import BalanceCard from "@/components/dashboard/BalanceCard";
import BottomNavigation from "@/components/dashboard/BottomNavigation";

export default function Home() {
  const [guestName, setGuestName] = useState(guest.guestName);
  const [status, setStatus] = useState(guest.status);
  const [balance, setBalance] = useState(guest.balance);

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
  }, []);

  return (
    <>
      <Header
        propertyName={guest.propertyName}
        guestName={guestName}
      />

      <AppContainer>
        <StayCard
          guestName={guestName}
          propertyName={guest.propertyName}
          roomNumber={guest.roomNumber}
          roomType={guest.roomType}
          checkIn={guest.checkIn}
          checkOut={guest.checkOut}
          status={status}
        />
        <QuickActions status={status} />
        <RoomInfo
          roomNumber={guest.roomNumber}
          roomType={guest.roomType}
        />
        <BalanceCard balance={balance} />
      </AppContainer>
      <BottomNavigation />
    </>
  );
}