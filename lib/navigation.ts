// Single source of truth for the nav/footer link set. The nav, the mobile
// menu and the footer Explore column all read these lists, in the order a
// visitor scrolls past the sections. Change the page order, change it here.

export type NavLink = {
  label: string;
  hash: `#${string}`;
};

export const NAV_LINKS: NavLink[] = [
  { label: "Social", hash: "#social" },
  { label: "About", hash: "#about" },
  { label: "How it works", hash: "#how" },
  { label: "Reading", hash: "#reading" },
  { label: "Community", hash: "#community" },
  { label: "Partners", hash: "#partners" },
];

export const NAV_LINKS_LEFT = NAV_LINKS.slice(0, 3);
export const NAV_LINKS_RIGHT = NAV_LINKS.slice(3);

export const FOOTER_EXPLORE_LINKS: NavLink[] = [
  { label: "Social", hash: "#social" },
  { label: "About", hash: "#about" },
  { label: "How it works", hash: "#how" },
  { label: "What we're reading", hash: "#reading" },
  { label: "Community", hash: "#community" },
];

export const FOOTER_INVOLVED_LINKS: NavLink[] = [
  { label: "Join the flock", hash: "#join" },
  { label: "Partner with us", hash: "#partners" },
];

type Page = "home" | "merch";

/** Resolves a hash link to the right href depending which page it's rendered on. */
export function resolveNavHref(link: NavLink, page: Page): string {
  if (link.hash === "#merch") {
    return page === "merch" ? "/merch" : "#merch";
  }
  return page === "merch" ? `/${link.hash}` : link.hash;
}
