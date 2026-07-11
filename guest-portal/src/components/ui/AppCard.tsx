interface AppCardProps {
  children: React.ReactNode;
  className?: string;
}

export default function AppCard({
  children,
  className = "",
}: AppCardProps) {
  return (
    <div
      className={`
        card
        rounded-[24px]
        p-5
        transition-all
        duration-300
        hover:-translate-y-1
        hover:shadow-xl
        ${className}
      `}
    >
      {children}
    </div>
  );
}