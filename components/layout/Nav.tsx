"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { NAV_LINKS_LEFT, NAV_LINKS_RIGHT, NAV_LINKS, resolveNavHref } from "@/lib/navigation";
import { JOIN_URL } from "@/lib/join";

export function Nav({
  page,
  eventShortLabel,
}: {
  page: "home" | "merch";
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
  // The one gold button in the bar is always "Join the flock", straight to the
  // join form. The next Social is the first text link, so attending is one tap
  // away but never louder.

  return (
    <header className={["nav", scrolled ? "scrolled" : ""].filter(Boolean).join(" ")} id="nav">
      <div className="wrap bar">
        <a className="bmark" href={bookmarkHref} aria-label={bookmarkLabel}>
          <img src="/images/nav/bookmark.webp" alt="" width={96} height={153} />
        </a>

        <nav className="links links-l" aria-label="Primary">
          {NAV_LINKS_LEFT.map((link) => (
            <a key={link.hash} href={resolveNavHref(link, page)}>
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
          <a className="btn btn-gold cta" href={JOIN_URL} target="_blank" rel="noopener noreferrer">
            Join the flock
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
            {NAV_LINKS.map((link) => (
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
          <a
            className="btn btn-gold cta"
            href={JOIN_URL}
            target="_blank"
            rel="noopener noreferrer"
            onClick={() => setOpen(false)}
          >
            Join the flock
          </a>
        </div>
      </div>
    </header>
  );
}
