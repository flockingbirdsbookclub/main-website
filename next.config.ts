import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  turbopack: {
    root: __dirname,
  },
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "*.supabase.co",
      },
    ],
  },
  // Links already shared on WhatsApp point at the old .html pages. Send them to
  // the new addresses rather than a not-found page.
  async redirects() {
    return [
      { source: "/merch.html", destination: "/merch", permanent: true },
      { source: "/index.html", destination: "/", permanent: true },
    ];
  },
};

export default nextConfig;
