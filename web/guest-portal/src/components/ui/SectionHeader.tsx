interface SectionHeaderProps {
  title: string;
  subtitle?: string;
}

export default function SectionHeader({
  title,
  subtitle,
}: SectionHeaderProps) {
  return (
    <div className="mb-3">
      <h2 className="section-title">
        {title}
      </h2>

      {subtitle && (
        <p className="subtitle">
          {subtitle}
        </p>
      )}
    </div>
  );
}