// Single source of truth for event/date formatting. The legacy index.html
// hardcoded the event date in 6 separate places (nav CTA x2, hero eyebrow,
// hero stat tile, #social pill/facts, footer link) — every one of those
// now reads from one EventInfo object via the helpers below, so changing
// the date (eventually via /admin/event) only ever means editing one field.

export type EventInfo = {
  eyebrowText: string;
  shortLabel: string; // e.g. "3 Oct" — nav CTA, hero stat tile
  pillText: string; // e.g. "Saturday 3 October"
  heading: string;
  time: string;
  venueName: string;
  venueAddress: string;
  who: string;
  bring: string;
};

export function rsvpCtaLabel(shortLabel: string): string {
  return `RSVP · ${shortLabel}`;
}
