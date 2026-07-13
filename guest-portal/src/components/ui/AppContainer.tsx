interface AppContainerProps {
  children: React.ReactNode;
}

export default function AppContainer({
  children,
}: AppContainerProps) {
  return (
    <main className="mx-auto min-h-screen max-w-md px-4 pb-28 pt-4 fade-in">
      {children}
    </main>
  );
}