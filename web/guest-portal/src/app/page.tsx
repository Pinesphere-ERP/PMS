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
  const [roomNumber, setRoomNumber] = useState("TBD");
  const [roomType, setRoomType] = useState("Standard");
  const [checkIn, setCheckIn] = useState("");
  const [checkOut, setCheckOut] = useState("");

  useEffect(() => {
    Promise.all([
      fetchAPI('/portal/me').catch(err => {
        console.error("Failed to fetch user:", err);
        return null;
      }),
      fetchAPI('/portal/folio').catch(err => {
        console.error("Failed to fetch folio:", err);
        return null;
      })
    ]).then(([meData, folioData]) => {
      if (meData) {
        setGuestName(meData.name || "Guest");
        setRoomNumber(meData.room_number || "TBD");
        setRoomType(meData.room_type || "Standard");
        setCheckIn(meData.check_in || "");
        setCheckOut(meData.check_out || "");
        
        let displayStatus = "Pending Approval";
        if (meData.status === "confirmed") displayStatus = "Confirmed";
        if (meData.status === "checked_in") displayStatus = "Checked In";
        if (meData.status === "checked_out") displayStatus = "Checked Out";
        setStatus(displayStatus);
      }
      
      if (folioData && folioData.balance_due !== undefined) {
        setBalance(folioData.balance_due);
      }
    }).finally(() => {
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
          roomNumber={roomNumber}
          roomType={roomType}
          checkIn={checkIn}
          checkOut={checkOut}
          status={status}
        />
        <QuickActions status={status} />
        <RoomInfo
          roomNumber={roomNumber}
          roomType={roomType}
        />
        <BalanceCard balance={balance} />
      </AppContainer>
      <BottomNavigation />
    </>
  );
}