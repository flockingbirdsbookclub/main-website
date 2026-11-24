import type { CSSProperties, ReactNode } from "react";

export function Card({
  num,
  icon,
  className,
  style,
  children,
}: {
  num?: string;
  icon?: ReactNode;
  className?: string;
  style?: CSSProperties;
  children: ReactNode;
}) {
  return (
    <div className={["card", className].filter(Boolean).join(" ")} style={style}>
      {num ? <span className="num">{num}</span> : null}
      {icon ? <span className="ico-lg">{icon}</span> : null}
      {children}
    </div>
  );
}

export function CardGrid({
  columns,
  className,
  children,
}: {
  columns: 2 | 3 | 4;
  className?: string;
  children: ReactNode;
}) {
  return <div className={["cards", `c${columns}`, className].filter(Boolean).join(" ")}>{children}</div>;
}
