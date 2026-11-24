import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Page not found · Flocking Birds Book Club",
  robots: { index: false },
};

// Ported from the old 404.html. Shown for any address that does not exist.
export default function NotFound() {
  return (
    <main className="nf">
      <div className="nf-box">
        <img src="/favicon.png" alt="" width={72} height={72} />
        <h1>This bird flew off.</h1>
        <p>
          That page does not exist, or it has moved. Everything worth reading is back on the main
          page.
        </p>
        <Link className="btn btn-gold" href="/">
          Back to Flocking Birds
        </Link>
      </div>
    </main>
  );
}
