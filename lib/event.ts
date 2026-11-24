// Single source of truth for the next Social. Every date-dependent spot on the
// homepage (hero pill, stat tile, Social section, RSVP message, nav and footer
// link labels) reads from one EventInfo object, so changing the event means
// editing one object. It becomes the `events` row the admin edits in Phase 7.

export type EventInfo = {
  heading: string; // "BookClub Social 4.0"
  edition?: string; // "Surrounded by Idiots edition"
  tagline?: string; // one line from the poster
  shortLabel: string; // "5 Dec": nav link, stat tile, footer
  pillText: string; // "Saturday 5 December"
  time: string; // "12:00–6:00 PM"
  venueName: string;
  venueAddress?: string;
  price?: string; // "KES 2,000"
  priceNote?: string; // "Covers a buffet lunch"
  who: string;
  bring: string;
  posterSrc?: string;
  posterAlt?: string;
};
