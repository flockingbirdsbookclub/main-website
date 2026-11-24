import { FOOTER_EXPLORE_LINKS, FOOTER_INVOLVED_LINKS, resolveNavHref } from "@/lib/navigation";
import { JOIN_URL } from "@/lib/join";

// One footer, used on both the home and merch pages. The legacy merch.html
// shipped a much sparser footer (two spans, no nav) than index.html's
// three-column version — nothing in CLAUDE.md calls that out as intentional,
// so this rebuild gives both pages the same real footer rather than carrying
// the inconsistency forward.
export function Footer({ page, eventShortLabel }: { page: "home" | "merch"; eventShortLabel: string }) {
  const year = new Date().getFullYear();

  return (
    <footer>
      <div className="wrap">
        <div className="cols">
          <div>
            <img className="mark" src="/images/footer/mark.png" alt="Flocking Birds" />
            <p className="motto">Different journeys. Common purpose. Stronger together.</p>
          </div>
          <div>
            <h4>Explore</h4>
            {FOOTER_EXPLORE_LINKS.map((link) => (
              <a key={link.hash} href={resolveNavHref(link, page)}>
                {link.hash === "#social" ? `The ${eventShortLabel} Social` : link.label}
              </a>
            ))}
          </div>
          <div>
            <h4>Get involved</h4>
            <a href={JOIN_URL} target="_blank" rel="noopener noreferrer">
              Join the flock
            </a>
            {FOOTER_INVOLVED_LINKS.map((link) => (
              <a key={link.hash} href={resolveNavHref(link, page)}>
                {link.label}
              </a>
            ))}
          </div>
        </div>
        <div className="base">
          <span>&copy; {year} Flocking Birds Book Club · Nairobi</span>
          <span>You&apos;re not alone here. Welcome to the flock.</span>
        </div>
      </div>
    </footer>
  );
}
