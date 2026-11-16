import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = { title: "Mind Vision Power Portal", description: "Student and administrator portal" };
export default function RootLayout({ children }: Readonly<{children: React.ReactNode}>) {
  return <html lang="en"><body>{children}</body></html>;
}
