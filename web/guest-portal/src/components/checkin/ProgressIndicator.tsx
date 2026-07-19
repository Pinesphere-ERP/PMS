interface Props {
  step: number;
}

export default function ProgressIndicator({
  step,
}: Props) {

  const labels = [
    "Personal",
    "Document",
    "Review",
    "Done",
  ];

  return (
    <div className="mb-6">

      <h1 className="mb-4 text-center text-2xl font-bold">
        Digital Check-in
      </h1>

      <div className="flex justify-between">

        {labels.map((label, index) => {

          const active = step >= index + 1;

          return (

            <div
              key={label}
              className="flex flex-1 flex-col items-center"
            >

              <div
                className={`mb-2 flex h-10 w-10 items-center justify-center rounded-full font-bold ${
                  active
                    ? "bg-green-600 text-white"
                    : "bg-gray-200 text-gray-600"
                }`}
              >
                {index + 1}
              </div>

              <span
                className={`text-xs ${
                  active
                    ? "font-semibold text-green-700"
                    : "text-gray-400"
                }`}
              >
                {label}
              </span>

            </div>

          );

        })}

      </div>

    </div>
  );
}