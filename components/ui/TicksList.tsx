export function TicksList({ variant, items }: { variant: "yes" | "no"; items: string[] }) {
  return (
    <ul className={`ticks ${variant}`}>
      {items.map((item) => (
        <li key={item}>{item}</li>
      ))}
    </ul>
  );
}
