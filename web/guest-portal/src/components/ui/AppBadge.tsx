interface AppBadgeProps {
  title: string;
}

export default function AppBadge({
  title,
}: AppBadgeProps) {
  return (
    <span className="rounded-full border border-white/20 bg-white/15 px-4 py-1 text-sm font-semibold text-white backdrop-blur-md">
      {title}
    </span>
  );
}