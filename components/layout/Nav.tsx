"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { NAV_LINKS_LEFT, NAV_LINKS_RIGHT, NAV_LINKS, resolveNavHref } from "@/lib/navigation";

export function Nav({
  page,
  rsvpLabel,
  eventShortLabel,
}: {
  page: "home" | "merch";
  rsvpLabel: string;
  eventShortLabel: string;
}) {
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    let raf = 0;
    function onScroll() {
      if (raf) return;
      raf = requestAnimationFrame(() => {
        setScrolled(window.scrollY > 24);
        raf = 0;
      });
    }
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const bookmarkHref = page === "merch" ? "/" : "#top";
  const bookmarkLabel = page === "merch" ? "Back to the homepage" : "Back to the top";
  // On merch, the last menu item is "Back to the homepage" (added below), as on the old merch.html.
  const mobileLinks = page === "merch" ? NAV_LINKS : [...NAV_LINKS, { label: "Join the flock", hash: "#join" as const }];

  return (
    <header className={["nav", scrolled ? "scrolled" : ""].filter(Boolean).join(" ")} id="nav">
      <div className="wrap bar">
        <a className="bmark" href={bookmarkHref} aria-label={bookmarkLabel}>
          <img src="/images/nav/bookmark.webp" alt="" width={96} height={153} />
        </a>

        <nav className="links links-l" aria-label="Primary">
          {NAV_LINKS_LEFT.map((link) => (
            <a
              key={link.hash}
              href={resolveNavHref(link, page)}
              aria-current={page === "merch" && link.hash === "#merch" ? "page" : undefined}
            >
              {link.hash === "#social" ? `${eventShortLabel} Social` : link.label}
            </a>
          ))}
        </nav>

        <span className="markgap" />

        <div className="right">
          <nav className="links links-r" aria-label="Secondary">
            {NAV_LINKS_RIGHT.map((link) => (
              <a key={link.hash} href={resolveNavHref(link, page)}>
                {link.label}
              </a>
            ))}
          </nav>
          <a className="btn btn-gold cta" href={page === "merch" ? "/#social" : "#social"}>
            {rsvpLabel}
          </a>
        </div>

        <button
          type="button"
          className="navtoggle"
          aria-label="Open menu"
          aria-expanded={open}
          onClick={() => setOpen((v) => !v)}
        >
          <span />
        </button>
      </div>

      <div id="mobnav" hidden={!open}>
        <div className="wrap">
          <ul>
            {mobileLinks.map((link) => (
              <li key={link.hash}>
                <a href={resolveNavHref(link, page)} onClick={() => setOpen(false)}>
                  {link.hash === "#social" ? `${eventShortLabel} Social` : link.label}
                </a>
              </li>
            ))}
            {page === "merch" ? (
              <li>
                <Link href="/">Back to the homepage</Link>
              </li>
            ) : null}
          </ul>
          <a className="btn btn-gold cta" href={page === "merch" ? "/#social" : "#social"} onClick={() => setOpen(false)}>
            {rsvpLabel}
          </a>
        </div>
      </div>
    </header>
  );
}
