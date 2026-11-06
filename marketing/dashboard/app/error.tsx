'use client';
export default function ErrorPage({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return <main className="fatal"><span className="eyebrow">GYMFEED / MARKETING STUDIO</span><h1>Prikaz nije uspeo.</h1><p>Podaci i poslovi ostaju sačuvani. Ponovo učitaj prikaz da nastaviš.</p><pre>{error.message}</pre><button className="button primary" onClick={reset}>Pokušaj ponovo</button></main>;
}
