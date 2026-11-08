'use client';

import { useEffect, useMemo, useState } from 'react';
import { ExternalLink, LoaderCircle, RefreshCw, Search, X } from 'lucide-react';
import './studio-analytics.css';

type Post = {
  id: string;
  platform: string;
  title?: string;
  caption?: string;
  format?: string;
  sent_at?: string;
  external_url?: string;
  source: string;
  metrics: Record<string, number>;
  metric_units?: Record<string, string>;
  metrics_updated_at?: string;
  duration_seconds?: number;
  attributed_signups?: number | null;
};
type Registrations = {
  total: number;
  current_profiles: number;
  attributed: number;
  content_only: number;
  daily: { date: string; count: number }[];
  recent: { at: string; platform?: string; attributed: boolean }[];
};
type Report = {
  registrations: Registrations | null;
  registration_error?: string;
  posts: Post[];
  social_error?: string;
  publication_error?: string;
  collected_at: string;
};
type Audience = {
  source?: string;
  period?: string;
  scope: 'post' | 'channel';
  reason?: string;
  native_url: string;
  breakdowns: Record<string, { label: string; value: number; unit: string }[]>;
  errors?: Record<string, string>;
};
const platforms: Record<string, string> = { instagram: 'Instagram', tiktok: 'TikTok', youtube: 'YouTube' };
const formats: Record<string, string> = { reel: 'Reel', video: 'Video', image: 'Slika', carousel: 'Carousel', text: 'Tekst' };
const labels: Record<string, string> = {
  views: 'Pregledi', reach: 'Dosegnuti nalozi', impressions: 'Impresije',
  likes: 'Lajkovi', reactions: 'Reakcije', comments: 'Komentari', shares: 'Deljenja', saves: 'Čuvanja',
  averageTimeWatched: 'Prosečno gledanje', engagementRate: 'Stopa angažovanja', clicks: 'Klikovi',
};
const dimensions: Record<string, string> = { countries: 'Zemlje', cities: 'Gradovi', gender: 'Pol', age: 'Starost', traffic: 'Izvori pregleda' };
const num = (value?: number | null) => typeof value === 'number' && Number.isFinite(value) ? value.toLocaleString('sr-Latn-RS', { maximumFractionDigits: 2 }) : '—';
const stamp = (value?: string) => value ? new Date(value).toLocaleString('sr-Latn-RS', { timeZone: 'Europe/Belgrade', dateStyle: 'short', timeStyle: 'short' }) : '—';
const headline = (post: Post) => post.title || post.caption?.split('\n')[0]?.slice(0, 115) || 'Objava';
const safeUrl = (value?: string) => value?.startsWith('https://') ? value : undefined;
const displayLabel = (dimension: string, label: string) => {
  if (dimension === 'gender') {
    if (['f', 'female'].includes(label.toLowerCase())) return 'Žene';
    if (['m', 'male'].includes(label.toLowerCase())) return 'Muškarci';
    if (['u', 'unknown'].includes(label.toLowerCase())) return 'Nepoznato';
    if (label.toLowerCase() === 'other') return 'Ostalo';
  }
  if (dimension === 'countries' && /^[A-Z]{2}$/.test(label) && label !== 'ZZ') {
    return new Intl.DisplayNames(['sr-Latn'], { type: 'region' }).of(label) ?? label;
  }
  return label;
};

async function getReport<T>(path: string, signal: AbortSignal): Promise<T> {
  const response = await fetch('/api/studio/analytics/' + path, { signal, cache: 'no-store' });
  const result = await response.json();
  if (!response.ok) throw new Error(result.message || result.error || 'Učitavanje nije uspelo.');
  return result;
}

function AudiencePanel({ id }: { id: string }) {
  const [state, setState] = useState<{ id: string; report?: Audience; error?: string }>();
  useEffect(() => {
    const controller = new AbortController();
    getReport<Audience>('audience/' + encodeURIComponent(id), controller.signal)
      .then(report => setState({ id, report }))
      .catch(error => { if (!controller.signal.aborted) setState({ id, error: error.message }); });
    return () => controller.abort();
  }, [id]);
  if (state?.id !== id) return <p className="analytics-loading"><LoaderCircle className="spin" size={16}/> Učitavam publiku…</p>;
  if (!state.report) return <p role="alert" className="analytics-error">{state.error}</p>;
  const report = state.report;
  return <div className="analytics-audience">
    <p className="muted">{report.scope === 'post' ? 'Publika ove objave' : 'Publika celog kanala'}
      {report.source && ' · ' + report.source}{report.period && ' · ' + report.period}</p>
    {report.reason && <p>{report.reason}</p>}
    <div className="analytics-breakdowns">
      {Object.entries(dimensions).filter(([key]) => key in report.breakdowns || key in (report.errors ?? {})).map(([key, title]) => {
        const rows = [...(report.breakdowns[key] ?? [])].sort((a, b) => b.value - a.value);
        return <div key={key}>
          <h3>{title}</h3>
          {report.errors?.[key] && <p className="analytics-error">{report.errors[key]}</p>}
          {!rows.length && !report.errors?.[key] && <p className="muted">Platforma nije vratila podatke za ovaj period.</p>}
          <div className="analytics-breakdown-list">
            {rows.map((row, index) => <div className="metric-row" key={row.label + index}>
              <span>{displayLabel(key, row.label)}</span><b>{num(row.value)}{row.unit === 'percent' ? '%' : ''}</b>
            </div>)}
          </div>
        </div>;
      })}
    </div>
    <a className="text-button" href={safeUrl(report.native_url)} target="_blank" rel="noreferrer">Otvori originalnu analitiku <ExternalLink size={13}/></a>
  </div>;
}

// Channel totals built from Buffer's per-post metrics, so every channel shows numbers even without a native insights API.
function ChannelSummary({ posts, channel, days }: { posts: Post[]; channel: string; days: number }) {
  const since = Date.now() - days * 86400000;
  const list = posts.filter(post => post.platform === channel && post.sent_at && Date.parse(post.sent_at) >= since);
  const sum = (key: string) => list.reduce((total, post) => total + (post.metrics[key] ?? 0), 0);
  const has = (key: string) => list.some(post => typeof post.metrics[key] === 'number');
  const views = sum('views'), reactions = sum('likes') + sum('reactions'), comments = sum('comments'), shares = sum('shares');
  const watched = list.filter(post => (post.metrics.averageTimeWatched ?? 0) > 0);
  const top = [...list].sort((a, b) => (b.metrics.views ?? 0) - (a.metrics.views ?? 0))[0];
  const tiles: [string, string, boolean][] = [
    ['Objave u periodu', num(list.length), true],
    ['Pregledi ukupno', num(views), has('views')],
    ['Prosečno pregleda po objavi', num(list.length ? views / list.length : 0), has('views')],
    ['Doseg ukupno', num(sum('reach')), has('reach') && sum('reach') > 0],
    ['Lajkovi / reakcije', num(reactions), has('likes') || has('reactions')],
    ['Komentari', num(comments), has('comments')],
    ['Deljenja', num(shares), has('shares')],
    ['Stopa angažovanja', num(views ? 100 * (reactions + comments + shares) / views : 0) + '%', has('views')],
    ['Ukupno gledanja (min)', num(sum('totalTimeWatched')), has('totalTimeWatched')],
    ['Prosečno gledanje (s)', num(watched.length ? watched.reduce((t, post) => t + post.metrics.averageTimeWatched, 0) / watched.length : 0), watched.length > 0],
  ];
  return <div className="analytics-channel-summary">
    <p className="muted">Ukupno za kanal · Buffer · poslednjih {days} dana (period biraš gore kod registracija)</p>
    {list.length ? <div className="analytics-kpis">
      {tiles.filter(([, , show]) => show).map(([label, value]) => <div key={label}><span>{label}</span><strong>{value}</strong></div>)}
    </div> : <p className="muted">Nema objava na ovom kanalu u izabranom periodu.</p>}
    {top && (top.metrics.views ?? 0) > 0 && <p className="muted">Najgledanija objava: {headline(top)} · {num(top.metrics.views)} pregleda</p>}
  </div>;
}

export default function StudioAnalytics() {
  const [days, setDays] = useState(30);
  const [reload, setReload] = useState(0);
  const [report, setReport] = useState<Report>();
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  const [platform, setPlatform] = useState('');
  const [format, setFormat] = useState('');
  const [search, setSearch] = useState('');
  const [sort, setSort] = useState('date');
  const [page, setPage] = useState(0);
  const [selected, setSelected] = useState<Post>();
  const [channel, setChannel] = useState('instagram');
  useEffect(() => {
    const controller = new AbortController();
    getReport<Report>(String(days), controller.signal)
      .then(result => { setReport(result); setError(''); })
      .catch(error => { if (!controller.signal.aborted) setError(error.message); })
      .finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [days, reload]);
  const posts = useMemo(() => {
    const list = (report?.posts ?? []).filter(post => (!platform || post.platform === platform)
      && (!format || post.format === format) && (!search || (headline(post) + ' ' + (post.caption ?? '')).toLowerCase().includes(search.toLowerCase())));
    if (sort !== 'date') list.sort((a, b) => (b.metrics[sort] ?? -1) - (a.metrics[sort] ?? -1));
    return list;
  }, [report, platform, format, search, sort]);
  const registrations = report?.registrations;
  const daily = [...(registrations?.daily ?? [])].reverse();
  const max = Math.max(1, ...daily.map(day => day.count));
  const pageSize = 20;
  const pageIndex = Math.min(page, Math.max(0, Math.ceil(posts.length / pageSize) - 1));
  return <div className="studio-analytics">
    <section className="panel">
      <div className="row-heading"><div><h2>Registracije u aplikaciji</h2><p>GymFeed · Europe/Belgrade</p></div>
        <button className="button subtle" onClick={() => { setLoading(true); setReload(reload + 1); }} disabled={loading}><RefreshCw size={15}/>Učitaj podatke</button>
      </div>
      {error && <p className="analytics-error" role="alert">{error}</p>}
      {report?.registration_error && <p className="analytics-error" role="alert">{report.registration_error}</p>}
      {loading && !report && <p className="analytics-loading"><LoaderCircle className="spin" size={16}/> Učitavam rezultate…</p>}
      {registrations && <>
        <div className="analytics-kpis">
          <div><span>Sačuvane registracije ukupno</span><strong>{num(registrations.total)}</strong></div>
          <div><span>Postojeći profili</span><strong>{num(registrations.current_profiles)}</strong></div>
          <div><span>Registracije u periodu</span><strong>{num(daily.reduce((sum, day) => sum + day.count, 0))}</strong></div>
          <div><span>Povezano sa konkretnom objavom ukupno</span><strong>{num(registrations.attributed)}</strong></div>
        </div>
        <div className="analytics-filters"><label>Period registracija
          <select value={days} onChange={event => { setLoading(true); setDays(Number(event.target.value)); }}>
            {[7, 30, 90, 365].map(value => <option key={value} value={value}>{value} dana</option>)}
          </select></label></div>
        <div className="analytics-chart" role="img" aria-label={'Dnevne registracije u prikazanom periodu: ' + daily.filter(day => day.count).map(day => day.date + ': ' + day.count).join(', ')}>
          {daily.map(day => <div key={day.date} title={day.date + ' · ' + day.count + ' registracija'}><i style={{ height: (day.count ? 100 * day.count / max : 2) + '%' }}/></div>)}
        </div>
        <div className="analytics-chart-axis"><span>{daily[0]?.date}</span><span>{daily.at(-1)?.date}</span></div>
        <details className="detail-disclosure"><summary>Datumi i vreme poslednjih registracija</summary>
          {registrations.recent.map((item, index) => <div key={item.at + index} className="metric-row">
            <span>{stamp(item.at)}</span><b>{item.attributed ? platforms[item.platform ?? ''] ?? 'Povezano sa objavom' : 'Izvor nije zabeležen'}</b>
          </div>)}
        </details>
      </>}
    </section>
    <section className="panel">
      <div className="row-heading"><div><h2>Rezultati svake objave</h2><p>{posts.length} objava · {report ? 'Učitano ' + stamp(report.collected_at) : 'Buffer'}</p></div></div>
      {report?.social_error && <p className="analytics-error" role="alert">Buffer · {report.social_error}</p>}
      {report?.publication_error && <p className="analytics-error" role="alert">Veza sa kampanjama · {report.publication_error}</p>}
      <div className="analytics-filters">
        <label>Platforma<select value={platform} onChange={event => { setPlatform(event.target.value); setPage(0); }}>
          <option value="">Sve platforme</option>{Object.entries(platforms).map(([key, label]) => <option key={key} value={key}>{label}</option>)}
        </select></label>
        <label>Format<select value={format} onChange={event => { setFormat(event.target.value); setPage(0); }}>
          <option value="">Svi formati</option>{Object.entries(formats).map(([key, label]) => <option key={key} value={key}>{label}</option>)}
        </select></label>
        <label>Sortiranje<select value={sort} onChange={event => { setSort(event.target.value); setPage(0); }}>
          <option value="date">Najnovije</option><option value="views">Pregledi</option><option value="reach">Doseg</option><option value="impressions">Impresije</option>
        </select></label>
        <label>Pretraga<span className="search"><Search size={15}/><input value={search} onChange={event => { setSearch(event.target.value); setPage(0); }} placeholder="Naslov ili opis"/></span></label>
      </div>
      <div className="analytics-scroll"><table className="analytics-table">
        <thead><tr><th>Objava</th><th>Pregledi</th><th>Doseg</th><th>Impresije</th><th>Lajkovi / reakcije</th><th>Komentari</th><th>Deljenja</th><th>Čuvanja</th><th>Registracije</th></tr></thead>
        <tbody>{posts.slice(pageIndex * pageSize, (pageIndex + 1) * pageSize).map(post => <tr key={post.id}>
          <td><button onClick={() => setSelected(post)}>{headline(post)}</button><small>{platforms[post.platform] || post.platform} · {formats[post.format ?? ''] ?? post.format ?? 'Objava'} · {stamp(post.sent_at)}</small></td>
          <td>{num(post.metrics.views)}</td><td>{num(post.metrics.reach)}</td><td>{num(post.metrics.impressions)}</td>
          <td>{num(post.metrics.likes ?? post.metrics.reactions)}</td><td>{num(post.metrics.comments)}</td><td>{num(post.metrics.shares)}</td>
          <td>{num(post.metrics.saves)}</td><td>{num(post.attributed_signups)}</td>
        </tr>)}</tbody>
      </table></div>
      {report && !posts.length && <p className="muted">Nema objava za prikaz sa ovim filterima.</p>}
      <div className="analytics-pagination"><p className="muted">Crtica označava podatak koji izvor nije dostavio. Metrike su poslednje dostupne vrednosti po objavi.</p>
        <button className="button subtle" disabled={pageIndex === 0} onClick={() => setPage(pageIndex - 1)}>Prethodna</button>
        <button className="button subtle" disabled={(pageIndex + 1) * pageSize >= posts.length} onClick={() => setPage(pageIndex + 1)}>Sledeća</button>
      </div>
    </section>
    <section className="panel">
      <div className="row-heading"><div><h2>Publika po kanalu</h2><p>Zemlje, gradovi, starost, pol i izvori pregleda gde kanal daje podatke.</p></div></div>
      <div className="tabs">{Object.entries(platforms).map(([key, label]) => <button key={key} className={channel === key ? 'selected' : ''} onClick={() => setChannel(key)}>{label}</button>)}</div>
      {report && <ChannelSummary posts={report.posts} channel={channel} days={days}/>}
      <AudiencePanel id={'account-' + channel}/>
    </section>
    {selected && <div className="drawer-overlay" onClick={() => setSelected(undefined)}>
      <aside className="drawer" role="dialog" aria-modal="true" aria-label="Analitika objave" onClick={event => event.stopPropagation()}>
        <div className="drawer-top"><span className="eyebrow">{platforms[selected.platform]} / ANALITIKA OBJAVE</span>
          <button className="icon-button" aria-label="Zatvori analitiku" onClick={() => setSelected(undefined)}><X size={20}/></button></div>
        <h2>{headline(selected)}</h2>
        <div className="drawer-content">
          <p>{stamp(selected.sent_at)} · {selected.source} · Metrike {stamp(selected.metrics_updated_at)}</p>
          {selected.duration_seconds && <p>Trajanje videa {num(selected.duration_seconds)} s</p>}
          {safeUrl(selected.external_url) && <a className="text-button" href={safeUrl(selected.external_url)} target="_blank" rel="noreferrer">Otvori objavu <ExternalLink size={13}/></a>}
          {Object.entries(selected.metrics).map(([key, value]) => <div className="metric-row" key={key}>
            <span>{labels[key] ?? key}</span><b>{num(value)} {selected.metric_units?.[key] === 'count' ? '' : selected.metric_units?.[key]}</b>
          </div>)}
          <div className="metric-row"><span>Zabeležene registracije povezane sa objavom</span><b>{num(selected.attributed_signups)}</b></div>
          <h3>Ko je gledao ovu objavu</h3><AudiencePanel id={selected.id}/>
        </div>
      </aside>
    </div>}
  </div>;
}
