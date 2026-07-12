import Header from "@/components/dashboard/Header";
import StayCard from "@/components/dashboard/StayCard";
import QuickActions from "@/components/dashboard/QuickActions";
import AppContainer from "@/components/ui/AppContainer";
import RoomInfo from "@/components/dashboard/RoomInfo";
import { guest } from "@/data/guest";
import BalanceCard from "@/components/dashboard/BalanceCard";
import BottomNavigation from "@/components/dashboard/BottomNavigation";
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
        <QuickActions />
        <RoomInfo
          roomNumber={guest.roomNumber}
          roomType={guest.roomType}
        />
        <BalanceCard balance={guest.balance} />
      </AppContainer>
      <BottomNavigation />
    </>
  );
}