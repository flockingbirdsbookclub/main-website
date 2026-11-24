import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Flocking Birds Book Club",
  description:
    "Flocking Birds is a Nairobi book club and growth community. Over 200 members across 12 flocks read one book every two months, apply it, and grow together.",
  metadataBase: new URL("https://flockingbirdsbookclub.com"),
  icons: {
    icon: "/favicon.png",
    apple: "/apple-touch-icon.png",
  },
  openGraph: {
    type: "website",
    siteName: "Flocking Birds Book Club",
    title: "Flocking Birds Book Club",
    description:
      "Flocking Birds is a Nairobi book club and growth community. Over 200 members across 12 flocks read one book every two months, apply it, and grow together.",
    images: ["https://flockingbirdsbookclub.com/share-card.jpg"],
  },
  twitter: {
    card: "summary_large_image",
    title: "Flocking Birds Book Club",
    description:
      "Flocking Birds is a Nairobi book club and growth community. Over 200 members across 12 flocks read one book every two months, apply it, and grow together.",
    images: ["https://flockingbirdsbookclub.com/share-card.jpg"],
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <meta name="theme-color" content="#0C4831" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          rel="stylesheet"
          href="https://fonts.googleapis.com/css2?family=Archivo:wdth,wght@62..125,400..900&family=Karla:wght@400;500;600;700&family=DM+Mono:wght@400;500&display=swap"
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
