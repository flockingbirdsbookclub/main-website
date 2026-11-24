"use client";

import { useRef } from "react";
import type { EventInfo } from "@/lib/event";
import { buildWhatsAppLink } from "@/lib/whatsapp";
import { recordSubmission } from "@/lib/netlifyForms";
import { Button } from "@/components/ui/Button";

// The #social section: the next Social, its poster and the RSVP form.
// It sits on an ivory beat between the green hero and the green About band.
//
// The visible RSVP inputs aren't bound to a real <form>. Each RSVP is saved to
// Netlify Forms (form "rsvp", defined in public/__forms.html) and handed off to
// WhatsApp at the same time.
export function EventBanner({ event, description }: { event: EventInfo; description: string }) {
  const nameRef = useRef<HTMLInputElement>(null);
  const phoneRef = useRef<HTMLInputElement>(null);
  const headsRef = useRef<HTMLSelectElement>(null);
  const whoRef = useRef<HTMLSelectElement>(null);

  function handleRsvp() {
    const name = nameRef.current?.value.trim() ?? "";
    const phone = phoneRef.current?.value.trim() ?? "";
    const heads = headsRef.current?.value ?? "";
    const who = whoRef.current?.value ?? "";

    // Save a structured copy to Netlify so we get a countable list, not just chats.
    recordSubmission("rsvp", { name, phone, coming: heads, member: who });

    const title = event.edition ? `${event.heading}, ${event.edition}` : event.heading;
    const message =
      `FLOCKING BIRDS · RSVP for ${title}\n` +
      `${event.pillText}, ${event.time}` +
      (event.venueName ? `, ${event.venueName}` : "") +
      "\n\n" +
      `Name: ${name || "(not given)"}\n` +
      `Phone: ${phone || "(not given)"}\n` +
      `Coming: ${heads}\n` +
      `Member: ${who}`;

    window.open(buildWhatsAppLink(message), "_blank", "noopener");
  }

  const where = [event.venueName, event.venueAddress].filter(Boolean).join(" · ");

  return (
    <section id="social">
      <div className="wrap social-grid">
        <div>
          <p className="eyebrow">
            <CalendarIcon />
            The next Social
          </p>
          <h2>{event.heading}</h2>
          {event.edition ? <p className="edition">{event.edition}</p> : null}
          {event.tagline ? <p className="lede tagline">{event.tagline}</p> : null}
          <p style={{ maxWidth: "54ch", marginTop: 14 }}>{description}</p>

          <ul className="facts">
            <li>
              <span className="k">WHEN</span>
              <span className="v">
                {event.pillText}, {event.time.replace("–", " to ")}
              </span>
            </li>
            <li>
              <span className="k">WHERE</span>
              <span className="v">{where}</span>
            </li>
            {event.price ? (
              <li>
                <span className="k">COST</span>
                <span className="v">
                  <b className="price">{event.price}</b>
                  {event.priceNote ? ` · ${event.priceNote}` : null}
                </span>
              </li>
            ) : null}
            <li>
              <span className="k">WHO</span>
              <span className="v">{event.who}</span>
            </li>
            <li>
              <span className="k">BRING</span>
              <span className="v">{event.bring}</span>
            </li>
          </ul>

          <div className="rsvp">
            <div className="rsvp-h">RSVP</div>
            <div className="rsvp-f">
              <div className="rf">
                <label htmlFor="r-name">YOUR NAME</label>
                <input id="r-name" ref={nameRef} type="text" autoComplete="name" placeholder="First and last name" />
              </div>
              <div className="rf">
                <label htmlFor="r-phone">PHONE</label>
                <input id="r-phone" ref={phoneRef} type="tel" autoComplete="tel" placeholder="07XX XXX XXX" />
              </div>
              <div className="rf">
                <label htmlFor="r-heads">HOW MANY OF YOU</label>
                <select id="r-heads" ref={headsRef} defaultValue="Just me">
                  <option>Just me</option>
                  <option>Me + 1</option>
                  <option>Me + 2</option>
                  <option>Me + 3</option>
                  <option>A group of 5 or more</option>
                </select>
              </div>
              <div className="rf">
                <label htmlFor="r-who">ARE YOU A MEMBER</label>
                <select id="r-who" ref={whoRef} defaultValue="Yes, I am in a flock">
                  <option>Yes, I am in a flock</option>
                  <option>Not yet, first time</option>
                  <option>I used to be, coming back</option>
                </select>
              </div>
            </div>
            <Button variant="gold" className="rsvp-go" onClick={handleRsvp}>
              Send my RSVP
            </Button>
            <p className="rsvp-note">
              Opens WhatsApp with your RSVP written out.
              {event.price
                ? ` We reply with how to pay the ${event.price} by M\u2011Pesa, and a reminder the week of.`
                : " We reply with the details and a reminder the week of."}
            </p>
          </div>
          <p className="social-alt">
            Not ready for a Social yet?{" "}
            <a href="#join">Join a flock instead</a>
          </p>
        </div>

        {event.posterSrc ? (
          <figure className="poster">
            <img src={event.posterSrc} alt={event.posterAlt ?? `${event.heading} poster`} />
          </figure>
        ) : null}
      </div>
    </section>
  );
}

// Calendar, the hangouts icon (same drawing as the gallery eyebrow).
function CalendarIcon() {
  return (
    <svg
      className="ico"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.7}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
    >
      <rect x={3.5} y={5.5} width={17} height={15} rx={2.2} />
      <path d="M3.5 10h17" />
      <path d="M8 3.4v4" />
      <path d="M16 3.4v4" />
    </svg>
  );
}
