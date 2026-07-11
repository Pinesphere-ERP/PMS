import Header from "@/components/dashboard/Header";
import StayCard from "@/components/dashboard/StayCard";

import AppContainer from "@/components/ui/AppContainer";

import { guest } from "@/data/guest";

export default function Home() {
  return (
    <>
      <Header
        propertyName={guest.propertyName}
        guestName={guest.guestName}
      />

      <AppContainer>

        <StayCard
          guestName={guest.guestName}
          propertyName={guest.propertyName}
          roomNumber={guest.roomNumber}
          roomType={guest.roomType}
          checkIn={guest.checkIn}
          checkOut={guest.checkOut}
          status={guest.status}
        />

      </AppContainer>
    </>
  );
}