'use client';
import { useCallback, useEffect, useRef, useState, type FormEvent } from 'react';
import { CalendarDays, Film, ImageIcon, RefreshCw, Sparkles } from 'lucide-react';

type MediaType = 'video' | 'image';
type Channel = 'instagram' | 'tiktok' | 'youtube';
type Publication = { platform: Channel; scheduledTime: string; status: string; postId?: string; error?: { message: string } };
type Edit = { id: string; status: string; mediaType: MediaType; prompt: string; previewUrl: string | null;
  error?: { message: string; category?: string; retryable?: boolean }; attempts: number; max_attempts: number;
  resumable: boolean; partCount?: number; partsComplete?: number; publications: Publication[] };
const channels: Record<Channel, string> = { instagram: 'Instagram', tiktok: 'TikTok', youtube: 'YouTube' };
const statusLabels: Record<string, string> = { queued: 'U redu', running: 'U toku', succeeded: 'Završeno',
  failed: 'Greška', retry_wait: 'Čeka ponovni pokušaj', needs_attention: 'Potrebna provera', cancelled: 'Otkazano' };

async function request(path: string, options?: RequestInit) {
  const res = await fetch('/api/studio/' + path, { cache: 'no-store', ...options });
  const body = await res.json();
  if (!res.ok) throw new Error(body.message || body.error || 'Zahtev nije uspeo.');
  return body;
}
const message = (error: unknown) => error instanceof Error ? error.message : 'Zahtev nije uspeo.';

function Schedule({ edit, connected, reload }: { edit: Edit; connected: Channel[]; reload: () => Promise<void> }) {
  const [selected, setSelected] = useState<Channel[]>([]);
  const [date, setDate] = useState('');
  const [caption, setCaption] = useState('');
  const [title, setTitle] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const available = connected.filter(channel => (channel !== 'youtube' || edit.mediaType === 'video') &&
    !edit.publications.some(post => post.platform === channel));
  const chosen = selected.filter(channel => available.includes(channel));
  async function submit(event: FormEvent) {
    event.preventDefault();
    setError('');
    setBusy(true);
    try {
      await request(`editor/${edit.id}/schedule`, { method: 'POST', headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ platforms: chosen, scheduledTime: new Date(date).toISOString(), caption, title }) });
      setSelected([]);
      await reload();
    } catch (error) { setError(message(error)); }
    finally { setBusy(false); }
  }
  return <>
    {edit.publications.map(post => <div className="metric-row" key={post.platform}>
      <span>{channels[post.platform]} · {new Date(post.scheduledTime).toLocaleString('sr-Latn-RS')}</span>
      <b>{post.postId ? 'Zakazano u Bufferu' : statusLabels[post.status] || post.status}</b>
      {post.error && <small className="error-text">{post.error.message}</small>}
    </div>)}
    {available.length > 0 && <form onSubmit={submit}>
      <label className="field-label">Datum i vreme objave (lokalno)
        <input type="datetime-local" required value={date} onInput={e => setDate(e.currentTarget.value)}/>
      </label>
      <div className="editor-channels" role="group" aria-label="Kanali za objavu">
        {available.map(channel => <label className="checkbox" key={channel}>
          <input type="checkbox" checked={chosen.includes(channel)} onChange={e => {
            const checked = e.currentTarget.checked;
            setSelected(current => checked ? [...current, channel] : current.filter(value => value !== channel));
          }}/>{channels[channel]}
        </label>)}
      </div>
      {chosen.includes('youtube') && <label className="field-label">YouTube naslov
        <input required maxLength={100} value={title} onChange={e => setTitle(e.target.value)}/>
      </label>}
      <label className="field-label">Opis objave<textarea maxLength={2200} value={caption} onChange={e => setCaption(e.target.value)}/></label>
      <button className="button primary" disabled={!chosen.length || !date || busy}><CalendarDays size={16}/>{busy ? 'Upisujem termin…' : 'Zakaži objavu'}</button>
    </form>}
    {error && <p role="alert" className="error-text">{error}</p>}
  </>;
}

export default function MediaEditor() {
  const [mediaType, setMediaType] = useState<MediaType>('video');
  const [file, setFile] = useState<File | null>(null);
  const [prompt, setPrompt] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [loadError, setLoadError] = useState('');
  const [notice, setNotice] = useState('');
  const [data, setData] = useState<{ channels: Channel[]; edits: Edit[] } | null>(null);
  const key = useRef('');
  const load = useCallback(async () => {
    try { setData(await request('editor')); setLoadError(''); }
    catch (error) { setLoadError(message(error)); }
  }, []);
  useEffect(() => {
    void load();
    const timer = setInterval(() => void load(), 10000);
    return () => clearInterval(timer);
  }, [load]);

  async function submit(event: FormEvent) {
    event.preventDefault();
    if (!file || busy) return;
    setError('');
    setNotice('');
    if (file.size > 50 * 1024 * 1024) { setError('Fajl može imati najviše 50 MB.'); return; }
    setBusy(true);
    key.current ||= crypto.randomUUID();
    try {
      await request('editor/upload', { method: 'POST', headers: {
        'content-type': 'application/octet-stream', 'idempotency-key': key.current,
        'x-edit-media-type': mediaType, 'x-edit-prompt': encodeURIComponent(prompt.trim()),
      }, body: file });
      setFile(null);
      setPrompt('');
      key.current = '';
      setNotice('Prerada je sačuvana u redu poslova.');
      await load();
    } catch (error) { setError(message(error)); }
    finally { setBusy(false); }
  }

  return <div className="media-editor">
    <form className="panel" onSubmit={submit}>
      <h2>Dodaj materijal za preradu</h2>
      <div className="tabs">
        <button type="button" className={mediaType === 'video' ? 'selected' : ''} disabled={busy} onClick={() => {
          if (mediaType !== 'video') { setMediaType('video'); setFile(null); key.current = ''; }
        }}><Film size={15}/> Video</button>
        <button type="button" className={mediaType === 'image' ? 'selected' : ''} disabled={busy} onClick={() => {
          if (mediaType !== 'image') { setMediaType('image'); setFile(null); key.current = ''; }
        }}><ImageIcon size={15}/> Slika</button>
      </div>
      <label className="field-label">Izvorni fajl
        <input type="file" key={mediaType} disabled={busy} accept={mediaType === 'video' ? '.mp4,video/mp4' : '.jpg,.jpeg,.png,.webp'}
          onChange={e => { setFile(e.currentTarget.files?.[0] ?? null); e.currentTarget.value = ''; key.current = ''; }}/>
      </label>
      <p>{file ? file.name : mediaType === 'video' ? 'MP4, 3–60 sekundi, od 720 do 3840 px, do 50 MB.' : 'JPG, PNG ili WebP, do 50 MB.'}</p>
      {mediaType === 'video' && <p>Za duže snimke Studio obrađuje delove i spaja ih u jedan video.</p>}
      <label className="field-label">Prompt za preradu
        <textarea disabled={busy} value={prompt} maxLength={1200} placeholder="Opiši šta želiš da promeniš i šta treba da ostane isto."
          onChange={e => { setPrompt(e.target.value); key.current = ''; }}/>
      </label>
      <p>Studio dodaje GymFeed logo kao referencu i smernice za boje i stil uz tvoj prompt.</p>
      <p>{mediaType === 'video' ? 'Kling O3 Pro · procena 0,168 USD po sekundi.' : 'Nano Banana 2.1 · naplata prema potrošnji modela.'}</p>
      <button className="button primary" disabled={!file || prompt.trim().length < 5 || busy}>
        <Sparkles size={16}/>{busy ? 'Otpremam…' : 'Pokreni preradu'}
      </button>
      {notice && <p role="status">{notice}</p>}
      {error && <p className="error-text" role="alert">{error}</p>}
    </form>
    <section aria-label="Rezultati prerade">
      <div className="row-heading"><h2>Prerade i objave</h2><button type="button" className="icon-button" title="Osveži prerade" onClick={() => void load()}><RefreshCw size={16}/></button></div>
      {loadError && <p role="alert" className="error-text">{loadError}</p>}
      {data?.edits.length === 0 && <p>Novi rezultati i njihovi termini pojaviće se ovde.</p>}
      {data?.edits.map(edit => <article className="panel editor-result" key={edit.id}>
        <div className="row-heading"><h3>{edit.mediaType === 'video' ? 'Video' : 'Slika'}</h3><span>{statusLabels[edit.status] || edit.status}</span></div>
        <p>{edit.prompt}</p>
        {!!edit.partCount && <p>Obrađeni delovi {edit.partsComplete ?? 0}/{edit.partCount}</p>}
        {edit.error && <p className="error-text">{edit.error.message}</p>}
        {edit.attempts < edit.max_attempts && ['failed', 'needs_attention'].includes(edit.status) &&
          !['moderation', 'review'].includes(edit.error?.category ?? '') &&
          (edit.resumable || edit.error?.retryable || !['interrupted', 'connection'].includes(edit.error?.category ?? '')) &&
          <button type="button" className="button subtle" onClick={async () => {
            try { await request(`jobs/${edit.id}/retry`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: '{}' }); await load(); }
            catch (error) { setLoadError(message(error)); }
          }}><RefreshCw size={15}/>Ponovi pokušaj</button>}
        {edit.previewUrl && <>
          {edit.mediaType === 'video' ? <video controls preload="metadata" src={edit.previewUrl}/> : <img src={edit.previewUrl} alt="Prerađena slika"/>}
          <a className="text-button" href={edit.previewUrl} target="_blank" rel="noreferrer">Otvori rezultat</a>
          <Schedule edit={edit} connected={data.channels} reload={load}/>
        </>}
      </article>)}
    </section>
  </div>;
}
