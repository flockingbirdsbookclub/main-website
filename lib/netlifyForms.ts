// Saves a structured copy of a submission to Netlify Forms, so the club gets a
// countable list (and a CSV export) rather than only WhatsApp chats.
//
// It POSTs to /__forms.html, not to the page itself. With Next.js on Netlify,
// form submissions must go to a static file that holds the form definition.
// See public/__forms.html. Do not remove this: it runs alongside the WhatsApp
// handoff, not instead of it.
export function recordSubmission(formName: string, fields: Record<string, string>): void {
  try {
    fetch("/__forms.html", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ "form-name": formName, ...fields }).toString(),
    }).catch(() => {});
  } catch {
    // Never let a failed save block the WhatsApp handoff.
  }
}
