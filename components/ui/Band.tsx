import type { CSSProperties, ReactNode } from "react";

// The single place the green/ivory section flip lives. CLAUDE.md: "green
// background, class=band, always" — a section that goes green without this
// class silently keeps light-ground text colours (green-on-green headings,
// invisible sub-headings). This component makes that mistake impossible.
export function Band({
  id,
  className,
  style,
  children,
}: {
  id?: string;
  className?: string;
  style?: CSSProperties;
  children: ReactNode;
}) {
  return (
    <section id={id} className={["band", className].filter(Boolean).join(" ")} style={style}>
      {children}
    </section>
  );
}
