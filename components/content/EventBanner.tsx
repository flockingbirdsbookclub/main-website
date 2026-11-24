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
export function EventBanner({ event, photoSrc }: { event: EventInfo; photoSrc?: string }) {
  const nameRef = useRef<HTMLInputElement>(null);
  const phoneRef = useRef<HTMLInputElement>(null);
  const headsRef = useRef<HTMLInputElement>(null);
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
          <span className="pill">{event.pillText}</span>
          <h2 style={{ marginTop: 16 }}>Join us for the Social</h2>
          <p className="lede">
            An afternoon to meet other flocks in person, swap book recommendations, and put faces
            to the WhatsApp names.
          </p>

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
                {event.venueName}, {event.venueAddress}
              </span>
            </li>
            <li>
              <span className="k">WHO</span>
              <span className="v">Members and anyone curious about joining</span>
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
                <label htmlFor="r-name">Name</label>
                <input id="r-name" ref={nameRef} type="text" autoComplete="name" />
              </div>
              <div className="rf">
                <label htmlFor="r-phone">Phone</label>
                <input id="r-phone" ref={phoneRef} type="tel" autoComplete="tel" />
              </div>
              <div className="rf">
                <label htmlFor="r-heads">Coming with</label>
                <input id="r-heads" ref={headsRef} type="text" placeholder="Just me" />
              </div>
              <div className="rf">
                <label htmlFor="r-who">Member status</label>
                <select id="r-who" ref={whoRef} defaultValue="Member">
                  <option value="Member">Member</option>
                  <option value="First-timer">First-timer</option>
                </select>
              </div>
            </div>
            <Button variant="gold" className="rsvp-go" onClick={handleRsvp}>
              RSVP on WhatsApp
            </Button>
            <p className="rsvp-note">We&apos;ll confirm your spot over WhatsApp.</p>
          </div>
        </div>

        <PhotoSlot src={photoSrc} alt="" ratio="r43" slotLabel="Social photo 4:3" />
      </div>
    </section>
  );
}
