interface AppButtonProps {
  title: string;
  onClick?: () => void;
}

export default function AppButton({
  title,
  onClick,
}: AppButtonProps) {
  return (
    <button
      onClick={onClick}
      className="
        primary-button
        w-full
        rounded-2xl
        py-3
        font-semibold
        shadow-lg
        transition-all
        duration-300
        hover:scale-[1.02]
        active:scale-95
      "
    >
      {title}
    </button>
  );
}