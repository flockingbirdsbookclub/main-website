import type { Metadata } from "next";
import { Nav } from "@/components/layout/Nav";
import { Footer } from "@/components/layout/Footer";
import { MerchShop, type MerchConfig } from "@/components/content/MerchShop";
import type { MerchProduct } from "@/components/content/MerchProductCard";
import { rsvpCtaLabel } from "@/lib/event";

// Real content ported verbatim from merch.html's CONFIG/PRODUCTS block —
// including the fact that every product's photo is still null and prices
// are still marked as suggestions, not decisions (see the draft banner
// below). Becomes a Supabase read in a later phase.
const eventShortLabel = "3 Oct";

const config: MerchConfig = {
  whatsapp: "254723906069",
  depositPct: 50,
  closesDate: "2026-09-22",
  currency: "KES",
  partnerStoreUrl: null,
};

const products: MerchProduct[] = [
  {
    id: "shelf-care",
    kind: "T-SHIRT",
    name: "Shelf Care",
    price: 1800,
    photoSrc: null,
    blurb: "For the ones who treat a good book as a wellness routine. Front print, soft cotton.",
    options: [
      { label: "COLOUR", swatch: true, values: ["forest", "navy", "cream", "black"] },
      { label: "SIZE", values: ["S", "M", "L", "XL", "2XL"] },
    ],
    partnerStoreUrl: null,
  },
  {
    id: "booked-and-busy",
    kind: "T-SHIRT",
    name: "Booked & Busy",
    price: 1800,
    photoSrc: null,
    blurb: "The one you wear to the discussion you almost skipped. Front print, soft cotton.",
    options: [
      { label: "COLOUR", swatch: true, values: ["forest", "navy", "cream", "black"] },
      { label: "SIZE", values: ["S", "M", "L", "XL", "2XL"] },
    ],
    partnerStoreUrl: null,
  },
  {
    id: "one-more-chapter",
    kind: "T-SHIRT",
    name: "One More Chapter",
    price: 1800,
    photoSrc: null,
    blurb: "A lie we tell ourselves at 1am, printed on a shirt so at least it is honest now.",
    options: [
      { label: "COLOUR", swatch: true, values: ["forest", "navy", "cream", "clay"] },
      { label: "SIZE", values: ["S", "M", "L", "XL", "2XL"] },
    ],
    partnerStoreUrl: null,
  },
  {
    id: "know-your-bird",
    kind: "T-SHIRT",
    name: "Know Your Bird",
    price: 2000,
    photoSrc: null,
    blurb: "The archetype series. Pick the bird you actually are, not the one you wish you were.",
    options: [
      { label: "BIRD", values: ["Owl", "Woodpecker", "Raven", "Sparrow", "Eagle", "Dove"] },
      { label: "COLOUR", swatch: true, values: ["forest", "navy", "cream"] },
      { label: "SIZE", values: ["S", "M", "L", "XL", "2XL"] },
    ],
    partnerStoreUrl: null,
  },
  {
    id: "embroidered-cap",
    kind: "CAP",
    name: "Embroidered Cap",
    price: 1500,
    photoSrc: null,
    blurb: "The submark stitched on the front. One bird, one weight, a bookmark for a tail.",
    options: [{ label: "COLOUR", swatch: true, values: ["forest", "navy", "black"] }],
    partnerStoreUrl: null,
  },
  {
    id: "book-tote",
    kind: "TOTE",
    name: "Book Tote",
    price: 1000,
    photoSrc: null,
    blurb: "Heavy canvas, flat bottom, actually fits a hardback and a laptop at the same time.",
    options: [{ label: "COLOUR", swatch: true, values: ["cream", "forest"] }],
    partnerStoreUrl: null,
  },
  {
    id: "bookmark-set",
    kind: "BOOKMARKS",
    name: "Bookmark Set",
    price: 400,
    photoSrc: null,
    blurb: "Six punny bookmarks, one per archetype. The cheapest thing here and the most used.",
    options: [{ label: "SET", values: ["Set of 6"] }],
    partnerStoreUrl: null,
  },
];

const merchDescription =
  "We print to order. Reserve your size with a deposit and collect at the BookClub Social on 3 October.";

export const metadata: Metadata = {
  title: "Merch Preorder · Flocking Birds Book Club",
  description: merchDescription,
  alternates: { canonical: "/merch" },
  openGraph: {
    type: "website",
    siteName: "Flocking Birds Book Club",
    title: "Merch Preorder · Flocking Birds Book Club",
    description: merchDescription,
    url: "https://flockingbirdsbookclub.com/merch",
    images: ["https://flockingbirdsbookclub.com/share-card.jpg"],
  },
  twitter: {
    card: "summary_large_image",
    title: "Merch Preorder · Flocking Birds Book Club",
    description: merchDescription,
    images: ["https://flockingbirdsbookclub.com/share-card.jpg"],
  },
};

export default function MerchPage() {
  return (
    <>
      {/* ===== DRAFT — delete this banner once real prices/photos/dates are confirmed ===== */}
      <div className="draft">
        <div className="wrap">
          <b>DRAFT</b>
          <p>
            Before this goes live, confirm the five things still marked as placeholders: real{" "}
            <code>price</code> values, product <code>photo</code> uploads, the <code>whatsapp</code>{" "}
            number that receives orders, the <code>deposit</code> percentage, and the{" "}
            <code>closes</code> date. Product names below are suggestions, not decisions.
          </p>
        </div>
      </div>

      <Nav page="merch" rsvpLabel={rsvpCtaLabel(eventShortLabel)} eventShortLabel={eventShortLabel} />

      <MerchShop products={products} config={config} />

      <Footer page="merch" eventShortLabel={eventShortLabel} />
    </>
  );
}
