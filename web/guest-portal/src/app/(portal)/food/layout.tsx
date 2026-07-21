import { CartDrawer } from "./components/CartDrawer";

export default function FoodLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      {children}
      <CartDrawer />
    </>
  );
}
