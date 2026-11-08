'use client';
import { useId, useState } from 'react';
import { ChevronDown, Upload } from 'lucide-react';

export default function CaptureUpload({ filename, instructions, notes, ready, upload }: {
  filename: string;
  instructions?: string;
  notes: string[];
  ready?: { source: string; duration: number } | null;
  upload: (file: File, actions: string) => Promise<void>;
}) {
  const [file, setFile] = useState<File | null>(null);
  const [actions, setActions] = useState('');
  const [verified, setVerified] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [expanded, setExpanded] = useState(false);
  const instructionsId = useId();
  const full = instructions?.trim() ?? '';
  const long = full.length > 240;
  const excerpt = long ? full.slice(0, 240).replace(/\s+\S*$/, '') + '…' : full;

  async function submit() {
    if (!file || !verified) return;
    setBusy(true);
    setError('');
    try {
      await upload(file, actions.trim());
      setFile(null);
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Upload nije uspeo.');
    } finally {
      setBusy(false);
    }
  }

  return <div className="upload-card">
    <Upload size={23}/>
    <h3>{ready?.source === 'storage' ? 'Snimak je sačuvan u Studiju' : ready ? 'Snimak je u biblioteci' : 'Potreban izvorni snimak'}</h3>
    <code>{filename}</code>
    <div id={instructionsId} className="capture-instructions">
      {full && <p>{expanded ? full : excerpt}</p>}
      {expanded && notes.length > 0 && <ul>{notes.map(note => <li key={note}>{note}</li>)}</ul>}
    </div>
    {(long || notes.length > 0) && <button type="button" className="text-button capture-instructions-toggle"
      aria-expanded={expanded} aria-controls={instructionsId} onClick={() => setExpanded(value => !value)}>
      {expanded ? 'Sakrij detalje' : 'Prikaži celo uputstvo'}<ChevronDown size={15}/>
    </button>}
    {ready?.source === 'storage' ? <p>{ready.duration.toFixed(1)} s · Verifikovan snimak</p> : <>
      <label className="button primary upload-button"><Upload size={15}/>Izaberi MP4 snimak
        <input type="file" accept="video/mp4,.mp4" disabled={busy} onChange={e => {
          const chosen = e.currentTarget.files?.[0] ?? null;
          e.currentTarget.value = '';
          setVerified(false);
          const tooLarge = chosen && chosen.size > 50 * 1024 * 1024;
          setError(tooLarge ? 'MP4 snimak može imati najviše 50 MB.' : '');
          setFile(tooLarge ? null : chosen);
        }}/>
      </label>
      {file && <>
        <p>{file.name}</p>
        <label className="field-label">Šta je vidljivo u snimku
          <textarea value={actions} onChange={e => setActions(e.target.value)} maxLength={700} placeholder="Opiši radnje koje se vide i približno vreme."/>
        </label>
        <label className="checkbox"><input type="checkbox" checked={verified} onChange={e => setVerified(e.target.checked)}/>Pregledao sam snimak. Prikazuje stvarni UI, bez ličnih podataka i tuđih brendova.</label>
        <button type="button" className="button primary" disabled={!verified || actions.trim().length < 10 || busy} onClick={() => void submit()}>
          <Upload size={15}/>{busy ? 'Čuvam snimak…' : 'Otpremi u Studio'}
        </button>
      </>}
    </>}
    {error && <p className="error-text" role="alert">{error}</p>}
  </div>;
}
