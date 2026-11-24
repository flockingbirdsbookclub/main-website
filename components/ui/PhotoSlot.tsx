// Preserves the site's existing "TO DO" convention: a photo slot with no
// image gets a dashed gold outline and a gold "TO DO" badge (CSS in
// globals.css, `.ph[data-slot]:not([data-done])`). Filled slots show the
// real photo and the badge disappears. This is the one "incomplete" visual
// language on the site — PartnerCard/BookCard reuse it for missing links.
type Ratio = "r43" | "r34" | "r169" | "r1";

export function PhotoSlot({
  src,
  alt = "",
  ratio,
  slotLabel,
  className,
}: {
  src?: string | null;
  alt?: string;
  ratio?: Ratio;
  slotLabel: string;
  className?: string;
}) {
  const done = Boolean(src);
  const cls = ["ph", ratio, done ? "done" : "", className].filter(Boolean).join(" ");

  return (
    <div className={cls} data-slot={slotLabel} {...(done ? { "data-done": "" } : {})}>
      {done ? <img src={src!} alt={alt} /> : null}
    </div>
  );
}
