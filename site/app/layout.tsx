import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({ variable: "--font-geist-sans", subsets: ["latin"] });
const geistMono = Geist_Mono({ variable: "--font-geist-mono", subsets: ["latin"] });

export const metadata: Metadata = {
  title: "ON AIR Deck — Turn your podcast into a real radio performance",
  description: "A native macOS broadcast desk that mixes mic, BGM, jingles, SFX, and voice effects for WAV recording, Zoom, Meet, and OBS.",
  keywords: ["podcast", "macOS", "radio", "sampler", "virtual microphone", "Zoom", "OBS", "open source"],
  authors: [{ name: "ON AIR Deck contributors" }],
  openGraph: {
    title: "ON AIR Deck — Your podcast, performed like radio.",
    description: "Mic, BGM, jingles, SFX, and voice FX on one Mac. Record to WAV or go live through one virtual microphone.",
    type: "website",
    images: [{ url: "/og.png", width: 1200, height: 630, alt: "ON AIR Deck — Your podcast, performed like radio" }],
  },
  twitter: { card: "summary_large_image", title: "ON AIR Deck", description: "Turn your podcast into a real radio performance.", images: ["/og.png"] },
  icons: { icon: "/app-icon.png", apple: "/app-icon.png" },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="ja"><body className={`${geistSans.variable} ${geistMono.variable}`}>{children}</body></html>;
}
