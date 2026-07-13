import Header from "@/components/dashboard/Header";
import BottomNavigation from "@/components/dashboard/BottomNavigation";
import AppContainer from "@/components/ui/AppContainer";

import UploadDocument from "@/components/checkin/UploadDocument";

export default function UploadPage() {
  return (
    <>
      <Header />

      <AppContainer>
        <UploadDocument />
      </AppContainer>

      <BottomNavigation />
    </>
  );
}