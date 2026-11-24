// Unifies what used to be two separately-hardcoded phone number variables
// (`WA` in index.html's RSVP handler, `JOIN_WA` for join/partner CTAs) into
// one setting. Hardcoded for now (Phase 3/4, no DB yet) — becomes a
// `settings.whatsapp_number` read in Phase 11.

export const WHATSAPP_NUMBER = "254723906069";

export function buildWhatsAppLink(message: string, number: string = WHATSAPP_NUMBER): string {
  return `https://wa.me/${number}?text=${encodeURIComponent(message)}`;
}
