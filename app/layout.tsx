import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Pookie Match — AI-Powered Gamified Dating & Real-World Exploration",
  description: "Find your pookie through shared interests, Pokémon GO-inspired map exploration, AI compatibility matching, virtual collectibles, and live video calling.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" data-scroll-behavior="smooth">
      <head>
        <link
          rel="stylesheet"
          href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
          integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY="
          crossOrigin=""
        />
      </head>
      <body className="min-h-screen bg-white font-sans text-ink antialiased">{children}</body>
    </html>
  );
}
