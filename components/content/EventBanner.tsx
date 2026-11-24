"use client";

import { useRef } from "react";
import type { EventInfo } from "@/lib/event";
import { buildWhatsAppLink } from "@/lib/whatsapp";
import { PhotoSlot } from "@/components/ui/PhotoSlot";
import { Button } from "@/components/ui/Button";

// The #social section. Visible RSVP inputs aren't bound to a real <form> —
// matching the legacy site's pattern, where the actual hidden Netlify
// <form> only existed so the static host's form-detector could register
// the field names. The WhatsApp handoff is the real user-facing flow;
// writing the RSVP to a database happens in the forms-backend phase.
export function EventBanner({
  event,
  description,
  photoSrc,
}: {
  event: EventInfo;
  description: string;
  photoSrc?: string;
}) {
  const nameRef = useRef<HTMLInputElement>(null);
  const phoneRef = useRef<HTMLInputElement>(null);
  const headsRef = useRef<HTMLSelectElement>(null);
  const whoRef = useRef<HTMLSelectElement>(null);

  function handleRsvp() {
    const name = nameRef.current?.value ?? "";
    const phone = phoneRef.current?.value ?? "";
    const heads = headsRef.current?.value ?? "";
    const who = whoRef.current?.value ?? "";

    const message = [
      `RSVP for ${event.pillText}:`,
      name && `Name: ${name}`,
      phone && `Phone: ${phone}`,
      heads && `Coming with: ${heads}`,
      who && `Member status: ${who}`,
    ]
      .filter(Boolean)
      .join("\n");

    window.open(buildWhatsAppLink(message), "_blank");
  }

  return (
    <section id="social">
      <div className="wrap social-grid">
        <div>
          <span className="pill">
            {event.pillText} · {event.time}
          </span>
          <h2 style={{ marginTop: 16 }}>{event.heading}</h2>
          <p style={{ maxWidth: "54ch", marginTop: 16 }}>{description}</p>

          <ul className="facts">
            <li>
              <span className="k">WHEN</span>
              <span className="v">
                {event.pillText} · {event.time}
              </span>
            </li>
            <li>
              <span className="k">WHERE</span>
              <span className="v">
                {event.venueName} · {event.venueAddress}
              </span>
            </li>
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
                <label htmlFor="r-name">Your name</label>
                <input id="r-name" ref={nameRef} type="text" autoComplete="name" placeholder="First and last name" />
              </div>
              <div className="rf">
                <label htmlFor="r-phone">Phone</label>
                <input id="r-phone" ref={phoneRef} type="tel" autoComplete="tel" placeholder="07XX XXX XXX" />
              </div>
              <div className="rf">
                <label htmlFor="r-heads">How many of you</label>
                <select id="r-heads" ref={headsRef} defaultValue="Just me">
                  <option>Just me</option>
                  <option>Me + 1</option>
                  <option>Me + 2</option>
                  <option>Me + 3</option>
                  <option>A group of 5 or more</option>
                </select>
              </div>
              <div className="rf">
                <label htmlFor="r-who">Are you a member</label>
                <select id="r-who" ref={whoRef} defaultValue="Yes, I am in a flock">
                  <option>Yes, I am in a flock</option>
                  <option>Not yet, first time</option>
                  <option>I used to be, coming back</option>
                </select>
              </div>
            </div>
            <Button variant="gold" className="rsvp-go" onClick={handleRsvp}>
              RSVP on WhatsApp
            </Button>
            <p className="rsvp-note">
              Opens WhatsApp with your RSVP written out. We reply with the venue and a reminder the
              week of.
            </p>
          </div>
          <div style={{ display: "flex", gap: 12, flexWrap: "wrap", marginTop: 22 }}>
            <a className="btn btn-line" href="#merch">
              Reserve your merch
            </a>
            <a className="btn btn-line" href="#join">
              Join a flock instead
            </a>
          </div>
        </div>

        <PhotoSlot src={photoSrc} alt="" ratio="r43" slotLabel="Social photo 4:3" />
      </div>
    </section>
  );
}
