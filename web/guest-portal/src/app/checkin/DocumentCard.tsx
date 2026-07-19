interface Props {
  title: string;
  icon: string;
  active: boolean;
  onClick: () => void;
}

export default function DocumentCard({
  title,
  icon,
  active,
  onClick,
}: Props) {

  return (

    <button
      onClick={onClick}
      className={`
        w-full
        rounded-2xl
        border
        p-4
        text-left
        transition
        ${
          active
            ? "border-green-600 bg-green-50"
            : "border-gray-200 bg-white"
        }
      `}
    >

      <div className="flex items-center gap-4">

        <span className="text-3xl">
          {icon}
        </span>

        <span className="font-semibold">
          {title}
        </span>

      </div>

    </button>

  );
}