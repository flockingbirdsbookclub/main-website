// Single source of truth for the nav/footer link set. The legacy site
// hand-copied this list three times per page (desktop-left, desktop-right,
// mobile menu) and again, slightly differently, in the footer — this file
// is what ends that duplication.

export type NavLink = {
  label: string;
  hash: `#${string}`;
};

export const NAV_LINKS: NavLink[] = [
  { label: "3 Oct Social", hash: "#social" },
  { label: "Merch", hash: "#merch" },
  { label: "About", hash: "#about" },
  { label: "How it works", hash: "#how" },
  { label: "Reading", hash: "#reading" },
  { label: "Community", hash: "#community" },
  { label: "Partners", hash: "#partners" },
];

export const NAV_LINKS_LEFT = NAV_LINKS.slice(0, 4);
export const NAV_LINKS_RIGHT = NAV_LINKS.slice(4);

export const FOOTER_EXPLORE_LINKS: NavLink[] = [
  { label: "3 Oct Social", hash: "#social" },
  { label: "Merch", hash: "#merch" },
  { label: "About", hash: "#about" },
  { label: "How it works", hash: "#how" },
  { label: "What we're reading", hash: "#reading" },
  { label: "Community", hash: "#community" },
];

export const FOOTER_INVOLVED_LINKS: NavLink[] = [
  { label: "Join the flock", hash: "#join" },
  { label: "Partner with us", hash: "#partners" },
  { label: "Member stories", hash: "#community" },
];

type Page = "home" | "merch";

/** Resolves a hash link to the right href depending which page it's rendered on. */
export function resolveNavHref(link: NavLink, page: Page): string {
  if (link.hash === "#merch") {
    return page === "merch" ? "/merch" : "#merch";
  }
  return page === "merch" ? `/${link.hash}` : link.hash;
}
