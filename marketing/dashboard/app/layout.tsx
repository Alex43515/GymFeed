import type { Metadata } from 'next';
import './globals.css';
export const metadata: Metadata = { title: 'GymFeed — Marketing Studio', description: 'Ideas, production and growth. One connected workspace.' };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="sr-Latn"><body>{children}</body></html>;
}
