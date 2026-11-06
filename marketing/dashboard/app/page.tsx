'use client';
import StudioAnalytics from './studio-analytics';
import CaptureUpload from './capture-upload';
import MediaEditor from './media-editor';
import { useState, useEffect, useCallback, useRef, type ReactNode } from 'react';
import { Activity, ArrowDownLeft, ArrowRight, ArrowUpRight, Bell, BookOpen, CalendarDays, Check, CheckCircle2, ChevronDown, ChevronRight, Circle, CircleAlert, Clock3, Clapperboard, Copy, ExternalLink, FileText, Film, FlaskConical, Globe, ImageIcon, Layers3, LayoutDashboard, Lightbulb, LoaderCircle, Mail, MoreHorizontal, Play, Plus, RefreshCw, Search, Send, Settings2, ShieldCheck, Sparkles, TriangleAlert, TrendingUp, Upload, Users, Workflow, X, XCircle, Zap } from 'lucide-react';

type Any = Record<string, any>;
type Content = Any & { id: string; title: string; type: string; status: string; ideaStatus: string; date: string; publicationDate: string | null; createdAt?: string; assets: string[]; sceneProgress: Any };
const nav = [
  ['overview','Pregled',LayoutDashboard], ['ideas','Ideje i plan',Lightbulb], ['studio','Creative studio',Clapperboard],
  ['editor','Prerada sadržaja',Sparkles],
  ['calendar','Kalendar',CalendarDays], ['analytics','Rezultati',TrendingUp], ['jobs','Poslovi i greške',Activity],
  ['team','Tim i kanali',Users], ['knowledge','Znanje i strategija',BookOpen],
] as const;
const statusNames: Any = { planned:'Ideja', generating:'U produkciji', generated:'Na proveri', awaiting_approval:'Za pregled', qa_failed:'Potrebna izmena', failed:'Zaustavljeno', approved:'Odobreno', scheduled:'Zakazano', published:'Objavljeno', queued:'U redu', running:'U toku', retry_wait:'Čeka retry', needs_attention:'Potrebna provera', succeeded:'Završeno', cancelled:'Otkazano', pending:'Za pregled', revising:'Menja se' };
const money = (value: number) => new Intl.NumberFormat('en-US', { style:'currency',currency:'USD',maximumFractionDigits:2 }).format(value || 0);
const date = (value?: string) => value ? new Date(value).toLocaleDateString('sr-Latn-RS', {day:'numeric',month:'short'}) : '—';
function publicationLabel(item: Content) {
  if (!item.publicationDate) return 'Datum objave nije određen';
  const day = new Date(item.publicationDate).toLocaleDateString('sr-Latn-RS', { day:'numeric', month:'short', timeZone:'UTC' });
  return `${item.status === 'scheduled' ? 'Zakazano' : 'Planirano'} za ${day}`;
}
const time = (value?: string) => value ? new Date(value).toLocaleTimeString('sr-Latn-RS',{hour:'2-digit',minute:'2-digit'}) : '—';
const clean = (value: any): string => typeof value === 'string' ? value : value == null ? '' : JSON.stringify(value, null, 2);
const assetType = (type: string) => type === 'video' ? 'Video' : type === 'carousel' ? 'Carousel' : 'Image';
function canRetryJob(job: Any) {
  return job.canRetry === true;
}
function Badge({ status, children }: {status: string; children?: ReactNode}) { return <span className={`badge ${status}`}><i/>{children || statusNames[status] || status}</span>; }
function Empty({ title, text, icon: Icon = Layers3 }: {title:string;text:string;icon?:any}) { return <div className="empty"><Icon size={28}/><h3>{title}</h3><p>{text}</p></div>; }
async function api(path: string, body?: any, headers: Any = {}) {
  const response = await fetch(`/api/studio/${path}`, {method:body === undefined ? 'GET':'POST', headers:{...(body === undefined ? {} : {'content-type':'application/json'}),...headers}, body:body === undefined ? undefined:JSON.stringify(body), cache:'no-store'});
  const result = await response.json(); if (!response.ok) throw new Error(result.message || result.error || `HTTP ${response.status}`); return result;
}

export default function Studio() {
  const [view,setView] = useState('overview'), [data,setData] = useState<Any|null>(null), [error,setError] = useState(''), [loading,setLoading] = useState(true);
  const [selected,setSelected] = useState<Content|null>(null), [detail,setDetail] = useState<Any|null>(null), [detailTab,setDetailTab] = useState('brief');
  const [query,setQuery] = useState(''), [filter,setFilter] = useState('all'), [toast,setToast] = useState(''), [busy,setBusy] = useState('');
  const [ideasFrom,setIdeasFrom] = useState(''), [ideasTo,setIdeasTo] = useState('');
  const [modal,setModal] = useState(''), [jobDetail,setJobDetail] = useState<Any|null>(null), [instructions,setInstructions] = useState('');
  const [campaignName,setCampaignName] = useState('GymFeed · fresh creative experiments'), [startDate,setStartDate] = useState(new Date(Date.now()+86400000).toISOString().slice(0,10)), [days,setDays] = useState(7);
  const [department,setDepartment] = useState('research');
  const pendingRequests = useRef(new Map<string,string>());
  const notify = (message:string) => {setToast(message);setTimeout(()=>setToast(''),5500);};
  const load = useCallback(async () => { try {const result=await api('snapshot');setData(result);setError('');} catch(e:any){setError(e.message);}finally{setLoading(false);}},[]);
  useEffect(()=>{
    if (window.location.hash === '#analytics') setView('analytics');
    if (window.location.hash === '#ideas') setView('ideas');
    if (window.location.hash === '#editor') setView('editor');
    if (window.location.hash === '#jobs') setView('jobs');
    void load();
    const timer = setInterval(() => void load(), 15000);
    return () => clearInterval(timer);
  },[load]);
  useEffect(()=>{if(!selected)return;let active=true;setDetail(null);setInstructions('');api(`content/${selected.id}`).then(r=>{if(active)setDetail(r);}).catch(e=>notify(e.message));return()=>{active=false;};},[selected?.id]);
  useEffect(()=>{
    if(!data)return;
    if(jobDetail){const current=data.jobs.find((j:Any)=>j.id===jobDetail.id);if(current)setJobDetail(current);}
    if(!selected)return;
    let active=true;
    const current=data.content.find((c:Content)=>c.id===selected.id);
    if(current&&current.updatedAt!==selected.updatedAt){setSelected(current);api(`content/${current.id}`).then(r=>{if(active)setDetail(r);}).catch(()=>{});}
    return()=>{active=false;};
  },[data,jobDetail?.id,selected?.id]);
  const content: Content[] = data?.content || [];
  const jobs: Any[] = data?.jobs || [];
  const events: Any[] = data?.events || [];
  const incidents = content.filter(c=>(c.blocked || c.error || c.status==='failed') && !['published','scheduled'].includes(c.status));
  const stoppedCampaigns = jobs.filter(job => job.kind === 'plan_campaign' && ['failed', 'needs_attention'].includes(job.status));
  const stoppedCampaign = stoppedCampaigns[0];
  const alertCount = incidents.length + stoppedCampaigns.length;
  const activeJobs = jobs.filter(j=>['running','queued','retry_wait'].includes(j.status));
  const actionable = content.filter(c=>['awaiting_approval','qa_failed'].includes(c.status) || c.status==='planned' && c.ideaStatus==='pending');
  const inProduction = content.filter(c=>c.status==='generating');
  const published = content.filter(c=>['scheduled','published'].includes(c.status));
  const ideasView = view === 'ideas';
  const invalidRange = Boolean(ideasFrom && ideasTo && ideasFrom > ideasTo);
  const visible = content.filter(c => {
    if (ideasView) {
      const pendingIdea = c.status === 'planned' && ['pending', 'revising'].includes(c.ideaStatus) && !c.assets.length;
      if (!pendingIdea && c.status !== 'scheduled') return false;
      const day = c.publicationDate;
      if (invalidRange || (ideasFrom && (!day || day < ideasFrom)) || (ideasTo && (!day || day > ideasTo))) return false;
    } else if (c.status === 'planned' && c.ideaStatus !== 'approved') return false;
    return (filter === 'all' || c.type === filter)
      && `${c.title} ${c.hook} ${c.feature}`.toLowerCase().includes(query.toLowerCase());
  });
  const open = (item:Content) => {setSelected(item);setDetailTab('brief');};
  const navigate = (next:string) => {setView(next);setQuery('');setFilter('all');};
  const enqueue = async (kind:string,payload:Any={},item?:Content) => {
    const signature=JSON.stringify({kind,payload,contentId:item?.id});
    let key=pendingRequests.current.get(signature);
    if(!key){
      const hash=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(signature)))).map(b=>b.toString(16).padStart(2,'0')).join('');
      key=item||kind==='plan_campaign'?`studio:${kind}:${hash}`:crypto.randomUUID();pendingRequests.current.set(signature,key);
    }
    setBusy(kind);try {const result=await api('jobs',{kind,payload,contentId:item?.id},{'idempotency-key':key});notify('Posao je sačuvan u redu. Status i svaki pokušaj vidiš u Poslovi i greške.');setModal('');if(!item&&kind!=='plan_campaign')pendingRequests.current.delete(signature);await load();return result;}catch(e:any){notify(e.message);}finally{setBusy('');}
  };
  const decide = async (kind:string) => {if(!selected)return;const item=detail || selected;await enqueue(kind,{revision:kind.startsWith('asset_')?item.reviewRevision:item.revision,instructions},selected);setSelected(null);};
  const retry = async (job:Any) => {setBusy(job.id);try{await api(`jobs/${job.id}/retry`,{});notify(job.kind==='plan_campaign'?'Nastavak kampanje je u redu poslova.':'Retry je sačuvan.');await load();}catch(e:any){notify(e.message);}finally{setBusy('');}};
  const upload = async (id: string, file: File, ref: string, actions: string) => {
    const response = await fetch(`/api/studio/content/${id}/upload`, {
      method: 'POST',
      headers: { 'content-type': 'application/octet-stream', 'x-owner-verified': 'true',
        'x-capture-ref': ref, 'x-observed-actions': encodeURIComponent(actions) },
      body: file,
    });
    const result = await response.json();
    if (!response.ok) throw new Error(result.message || result.error);
    setDetail(current => current?.id === id ? { ...current,
      captureUploads: { ...current.captureUploads, [ref]: { source: 'storage', duration: result.duration } } } : current);
    notify(result.resumeQueued ? 'Snimak je sačuvan. Produkcija je ponovo u redu.' : 'Snimak je sačuvan u Studiju.');
    void load();
  };
  const sectionHead = (eyebrow:string,title:string,description:string,action?:ReactNode) => <div className="section-head"><div><span className="eyebrow">{eyebrow}</span><h1>{title}</h1><p>{description}</p></div>{action}</div>;
  const contentCard = (item:Content,index:number) => <button key={item.id} className="content-card" onClick={()=>open(item)}>
    <div className={`cover cover-${index%4}`}>
      {item.thumbnail ? <img src={item.thumbnail} alt=""/> : <><div className="cover-grid"/><span className="cover-brand">GYMFEED<span>®</span></span><span className="cover-title">{item.hook || item.title}</span><span className="cover-bottom">{item.feature?.replaceAll('_',' ') || 'Make your next move.'}<ArrowUpRight size={22}/></span></>}
      <span className="type-tag">{item.type==='video'?<Film size={12}/>:item.type==='carousel'?<Layers3 size={12}/>:<ImageIcon size={12}/>} {assetType(item.type)}{item.duration?` · ${item.duration}s`:''}</span>
    </div><div className="card-body"><div className="card-meta"><span>{ideasView ? publicationLabel(item) : date(item.date)}</span><Badge status={item.blocked?'failed':ideasView&&item.status==='planned'?item.ideaStatus:item.status}/></div><h3>{item.title}</h3>{ideasView&&item.createdAt&&<div className="idea-planned-date">Kreirano {date(item.createdAt)} · {time(item.createdAt)}</div>}<div className="card-foot"><span>{item.treatment?.format_family?.replaceAll('_',' ') || item.feature?.replaceAll('_',' ') || 'GymFeed creative'}</span><ArrowUpRight size={16}/></div></div>
  </button>;

  return <div className="app-shell">
    <aside className="sidebar"><a href="#" className="brand" onClick={e=>{e.preventDefault();navigate('overview');}}><span className="brand-mark"><Activity size={23} strokeWidth={3}/></span>GymFeed<span className="brand-small">STUDIO</span></a>
      <button className="workspace" onClick={()=>navigate('team')}><span className="workspace-avatar">G</span><span><strong>GymFeed</strong><small>Marketing workspace</small></span><ChevronDown size={15}/></button>
      <span className="nav-label">WORKSPACE</span><nav>{nav.map(([id,label,Icon])=><button key={id} className={view===id?'nav-item active':'nav-item'} onClick={()=>navigate(id)}><Icon size={18}/><span>{label}</span>{id==='jobs'&&alertCount>0?<b className="nav-count">{alertCount}</b>:null}</button>)}</nav>
      <div className="sidebar-bottom"><div className="owner-card"><ShieldCheck size={18}/><div><strong>Ti imaš poslednju reč.</strong><p>Ideja → tvoj pregled → produkcija → tvoj pregled.</p></div></div><button className="nav-item" onClick={()=>navigate('team')}><Settings2 size={18}/>Podešavanja i konekcije</button><div className="profile"><span className="profile-avatar">A</span><div><strong>Alex</strong><small>Workspace owner</small></div><span className="local-dot" title="Lokalni pregled"/></div></div>
    </aside>
    <div className="main-shell"><header className="topbar"><div className="breadcrumb">Workspace <ChevronRight size={13}/><span>{nav.find(n=>n[0]===view)?.[1]}</span></div><div className="top-actions"><span className="local-badge"><span/>Local preview</span><button className="icon-button" title="Osveži podatke" onClick={()=>void load()}><RefreshCw size={16} className={loading?'spin':''}/></button><button className="icon-button notification" title="Greške i obaveštenja" onClick={()=>navigate('jobs')}><Bell size={18}/>{alertCount>0&&<i/>}</button><div className="top-avatar">A</div></div></header>
    <main className="main-content">
      {error&&<div className="error-banner"><CircleAlert size={20}/><div><strong>Veza sa backendom nije dostupna</strong><p>{error}</p></div><button className="button subtle" onClick={()=>void load()}>Pokušaj ponovo</button></div>}
      {stoppedCampaign&&<div className="error-banner" role="alert">
        <CircleAlert size={20}/>
        <div>
          <strong>{stoppedCampaigns.length === 1 ? 'Planiranje kampanje je prekinuto' : `${stoppedCampaigns.length} kampanja traži proveru`}</strong>
          <p>{stoppedCampaign.error?.code === 'WORKER_INTERRUPTED'
            ? 'Radni proces je prekinut tokom planiranja. Već sačuvane ideje su dostupne u planu.'
            : stoppedCampaign.error?.message || 'Otvori detalje posla da vidiš razlog.'}</p>
        </div>
        <button className="button subtle" onClick={()=>{navigate('jobs');setJobDetail(stoppedCampaign);setModal('job');}}>Otvori detalje</button>
        <button className="button primary" disabled={!!busy || !canRetryJob(stoppedCampaign)} onClick={()=>void retry(stoppedCampaign)}>Nastavi kampanju</button>
      </div>}
      {loading&&!data?<div className="loading-state"><LoaderCircle className="spin"/><h2>Učitavam tvoj workspace</h2><p>Čitam stvarne kampanje, produkciju i rezultate.</p></div>:<>
      {view==='overview'&&<>
        {sectionHead('YOUR MARKETING, CONNECTED','Dobre ideje. Stvarni rezultati.','Jedno mesto za strategiju, sadržaj i sve što se dešava između.',<button className="button primary" onClick={()=>setModal('campaign')}><Plus size={17}/>Nova kampanja</button>)}
        <section className="overview-hero"><div className="hero-copy"><span className="hero-kicker"><span/>GYMFEED MARKETING OS</span><h2>Od prve ideje<br/>do sledećeg korisnika<span>.</span></h2><p>Istraži. Napravi. Proveri. Objavi. Nauči.<br/>Tvoj marketing tim, u jednom povezanom toku.</p><button className="button hero-button" onClick={()=>navigate('ideas')}>Otvori content plan <ArrowUpRight size={17}/></button></div><div className="hero-art"><div className="orb orb-one"/><div className="orbit orbit-one"/><div className="orbit orbit-two"/><div className="art-core"><Activity size={56} strokeWidth={2.5}/></div><div className="floating-label fl-one"><Lightbulb size={15}/>Original ideas</div><div className="floating-label fl-two"><Film size={15}/>Better creative</div><div className="floating-label fl-three"><TrendingUp size={15}/>Learn & grow</div><span className="art-coordinate">01 / RESEARCH → REVENUE</span></div></section>
        <div className="stats-grid"><div className="stat"><div><span>Čeka tvoj pregled</span><CheckCircle2 size={17}/></div><strong>{actionable.length}<small>materijala</small></strong><p>Ideje i gotov sadržaj za odluku</p></div><div className="stat"><div><span>U produkciji</span><Clapperboard size={17}/></div><strong>{inProduction.length}<small>u toku</small></strong><p>{activeJobs.length} aktivnih poslova u redu</p></div><div className="stat"><div><span>Zakazano / objavljeno</span><Send size={17}/></div><strong>{published.length}<small>materijala</small></strong><p>U učitanoj istoriji kampanja</p></div><div className="stat"><div><span>Produkcija · poslednjih 30 dana</span><Layers3 size={17}/></div><strong>{money(data?.totals?.spent)}<small>utrošeno</small></strong><p>{money(data?.totals?.reserved)} rezervisano za poslove</p></div></div>
        {incidents.length>0&&<button className="attention-strip" onClick={()=>navigate('jobs')}><span className="attention-icon"><TriangleAlert size={19}/></span><div><strong>{incidents.length} {incidents.length===1?'materijal traži':'materijala traži'} pažnju</strong><span>Nedostajući fajlovi i greške imaju razlog, sledeći korak i istoriju.</span></div><span>Pregledaj <ArrowRight size={16}/></span></button>}
        <div className="content-section"><div className="row-heading"><div><h2>Sledeće u tvom planu <span className="pill">{content.length}</span></h2><p>Stvarne ideje i materijali iz GymFeed kampanja.</p></div><button className="text-button" onClick={()=>navigate('ideas')}>Ceo plan<ArrowRight size={15}/></button></div><div className="cards-grid">{content.slice(0,4).map(contentCard)}</div>{!content.length&&<Empty title="Prostor za sledeću dobru ideju" text="Pokreni novu kampanju. Ideje prvo stižu na tvoj pregled."/>}</div>
        <div className="two-columns"><section className="panel"><div className="row-heading"><h2>Povezan proces</h2><Workflow size={18}/></div><div className="pipeline">{[[Search,'Istraživanje'],[Lightbulb,'Ideja'],[ShieldCheck,'Odobrenje'],[Film,'Produkcija'],[Send,'Objava'],[TrendingUp,'Učenje']].map(([Icon,label]:any,i)=><div key={label}><span className={i===3?'current':''}><Icon size={19}/></span><small>{label}</small></div>)}</div><p className="panel-note">Svaki korak čuva stanje. Tvoje odluke pokreću sledeći.</p></section><section className="panel"><div className="row-heading"><h2>Kreativna memorija</h2><FlaskConical size={18}/></div><div className="memory-line"><strong>{data?.intelligence?.sample_size || 0}</strong><span>materijala u arhivi za poređenje ideja</span></div><div className="memory-tags">{data?.intelligence?.format_frequency?.slice(0,3).map((f:Any)=><span key={f.name}>{f.name.replaceAll('_',' ')} <b>{f.count}</b></span>)}</div><button className="text-button" onClick={()=>navigate('knowledge')}>Pogledaj šta sistem pamti<ArrowRight size={14}/></button></section></div>
      </>}
      {(view==='ideas'||view==='studio')&&<>
        {sectionHead(view==='ideas'?'CONTENT PLANNING':'CREATIVE PRODUCTION',view==='ideas'?'Prostor za bolje ideje.':'Od ideje do gotovog kadra.',view==='ideas'?'Pregledaj priču, dokaze i storyboard pre nego što odobriš produkciju.':'Sačuvane scene, status produkcije i gotovi materijali za tvoj pregled.',<button className="button primary" onClick={()=>setModal('campaign')}><Plus size={17}/>Nova kampanja</button>)}
        <div className="toolbar"><div className="tabs">{[['all','Sve'],['video','Video'],['carousel','Carousel'],['image','Image']].map(([id,label])=><button key={id} className={filter===id?'selected':''} onClick={()=>setFilter(id)}>{label}</button>)}</div><div className="search"><Search size={16}/><input aria-label="Pretraži sadržaj" placeholder="Pronađi ideju ili temu…" value={query} onChange={e=>setQuery(e.target.value)}/></div></div>
        {ideasView&&<div className="ideas-range" role="group" aria-label="Period planirane ili zakazane objave">
          <label className="field-label">Objava od<input type="date" value={ideasFrom} onInput={e=>setIdeasFrom(e.currentTarget.value)} /></label>
          <label className="field-label">Objava do<input type="date" value={ideasTo} onInput={e=>setIdeasTo(e.currentTarget.value)} /></label>
          {(ideasFrom||ideasTo)&&<button type="button" className="button subtle" onClick={()=>{setIdeasFrom('');setIdeasTo('');}}>Obriši period</button>}
        </div>}
        {ideasView&&invalidRange ? <p role="alert" className="ideas-range-error">Krajnji datum mora biti isti ili kasniji od početnog.</p> : <>
          <div className="cards-grid content-grid">{visible.map(contentCard)}</div>
          {!visible.length&&<Empty title={ideasView?'Nema ideja za pregled':'Nema rezultata'} text={ideasView?'Promeni filtere ili pokreni novu kampanju.':'Promeni pretragu ili filter formata.'}/>}
        </>}
      </>}
      {view==='editor'&&<>
        {sectionHead('MEDIA EDITOR','Preradi svoj sadržaj.','Otpremi video ili sliku, napiši šta želiš da promeniš i zakaži rezultat kad ga pregledaš.')}
        <MediaEditor/>
      </>}
      {view==='calendar'&&<>
        {sectionHead('PUBLISHING CALENDAR','Tvoj sledeći potez.','Planirani datum ideje i stvarno stanje publikacije, zajedno.')}
        {[...new Set(content.map(c=>c.date).filter(Boolean))].sort().map(day=><section className="calendar-day" key={day}><div className="day-label"><strong>{new Date(day).getDate()}</strong><span>{new Date(day).toLocaleDateString('sr-Latn-RS',{month:'short',weekday:'short'})}</span></div><div className="day-items">{content.filter(c=>c.date===day).map(c=><button key={c.id} onClick={()=>open(c)}><span className="item-type">{c.type==='video'?<Film size={18}/>:<Layers3 size={18}/>}</span><div><strong>{c.title}</strong><small>{assetType(c.type)} · {c.feature?.replaceAll('_',' ')}</small></div><Badge status={c.status}/><ChevronRight size={16}/></button>)}</div></section>)}
      </>}
      {view==='analytics'&&<>
        {sectionHead('ANALYTICS & LEARNING','Brojevi koji imaju smisla.','Podaci, pretpostavke i rupe u merenju prikazani su odvojeno.',<button className="button primary" disabled={!!busy} onClick={()=>void enqueue('weekly_review')}><Sparkles size={16}/>Pokreni Weekly CMO</button>)}
        <StudioAnalytics/>
        <div className="stats-grid"><div className="stat"><span>Publikacije u uzorku</span><strong>{data?.publications?.length||0}</strong><p>Učitano iz poslednjih 30 dana</p></div><div className="stat"><span>Product events</span><strong>{data?.intelligence?.measurement?.events||0}</strong><p>U učitanom uzorku događaja</p></div><div className="stat"><span>Events sa content atribucijom</span><strong>{data?.intelligence?.measurement?.attributable_events||0}</strong><p>Identifikator nije dokaz uzročnosti</p></div><div className="stat"><span>Trošak produkcije</span><strong>{money(data?.totals?.spent)}</strong><p>Rezervisano: {money(data?.totals?.reserved)}</p></div></div>
        <div className="info-banner"><FlaskConical size={20}/><div><strong>Učenje počinje pouzdanim merenjem.</strong><p>{data?.intelligence?.measurement?.limitations?.join(' ')}</p><p>ROI i prihod po objavi ostaju nepoznati dok ne postoji potvrđena veza objava → korisnik → konverzija.</p></div></div>
        <div className="two-columns"><section className="panel"><div className="row-heading"><h2>Product events</h2><Activity size={18}/></div>{Object.entries(data?.eventCounts||{}).map(([name,count]:any)=><div className="metric-row" key={name}><span>{name.replaceAll('_',' ')}</span><b>{count}</b></div>)}{!Object.keys(data?.eventCounts||{}).length&&<Empty title="Nema događaja u uzorku" text="Nedostajući podaci nisu nula konverzija."/>}</section><section className="panel"><div className="row-heading"><h2>Šta ponavljamo</h2><Layers3 size={18}/></div>{data?.intelligence?.format_frequency?.map((f:Any)=><div className="frequency" key={f.name}><div><span>{f.name.replaceAll('_',' ')}</span><b>{f.count}</b></div><div className="bar"><i style={{width:`${f.count/Math.max(1,...data.intelligence.format_frequency.map((v:Any)=>v.count))*100}%`}}/></div></div>)}</section></div>
        <section className="panel learnings"><div className="row-heading"><h2>Sačuvana učenja</h2><BookOpen size={18}/></div>{data?.learnings?.slice(0,12).map((l:Any)=><div className="learning" key={l.id}><Badge status={l.status||'pending'}/><div><strong>{l.pattern||l.title||l.hypothesis||'Learning'}</strong><p>{l.recommended_action||l.insight||clean(l.finding||l.evidence)}</p></div><span>{l.confidence!=null?`${Math.round(l.confidence*100)}% confidence`:''}</span></div>)}</section>
      </>}
      {view==='jobs'&&<>
        {sectionHead('OPERATIONS & RECOVERY','Svaki posao. Svaki pokušaj.','Šta se desilo, zašto se desilo i šta je sledeći korak.',<button className="button subtle" onClick={()=>void load()}><RefreshCw size={16}/>Osveži</button>)}
        <div className="tabs ops-tabs">{[['all','Sve'],['attention','Traži pažnju'],['running','Aktivno'],['succeeded','Završeno']].map(([id,label])=><button className={filter===id?'selected':''} key={id} onClick={()=>setFilter(id)}>{label}</button>)}</div>
        {filter!=='succeeded'&&filter!=='running'&&incidents.map(c=><div className="incident-card" key={c.id}><div className="incident-symbol"><TriangleAlert size={20}/></div><div><div className="incident-meta">CONTENT / {c.blockKind==='capture'?'POTREBAN SNIMAK':'PRODUKCIJA'}<span>{date(c.updatedAt)} · {time(c.updatedAt)}</span></div><h3>{c.title}</h3><p>{c.error||c.progress?.message||'Produkcija je zaustavljena.'}</p><div className="incident-next"><ArrowDownLeft size={14}/>{c.blockKind==='capture'?'Otvori zahteve, uploaduj tačan snimak i ponovo pokreni intake.':'Otvori istoriju scena i proveri prethodni pokušaj pre nastavka.'}</div></div><button className="button subtle" onClick={()=>{open(c);setDetailTab('errors');}}>Detalji<ArrowUpRight size={15}/></button></div>)}
        <section className="panel jobs-panel"><div className="row-heading"><h2>Red poslova <span className="pill">{jobs.length}</span></h2><span className="muted">Trajno sačuvano u bazi</span></div><div className="job-table"><div className="job-table-head"><span>OPERACIJA</span><span>STATUS</span><span>POKUŠAJI</span><span>VREME</span><span/></div>{jobs.filter(j=>filter==='all'||filter==='attention'&&['failed','needs_attention'].includes(j.status)||filter==='running'&&['queued','running','retry_wait'].includes(j.status)||filter==='succeeded'&&j.status==='succeeded').map(j=><div className="job-row" key={j.id}><button className="job-name" onClick={()=>{setJobDetail(j);setModal('job');}}><Workflow size={17}/><div><strong>{j.kind.replaceAll('_',' ')}</strong><small>{j.error?.message||j.id.slice(0,8)}</small></div></button><Badge status={j.status}/><span>{j.attempts} / {j.max_attempts}</span><span>{date(j.created_at)}<small>{time(j.created_at)}</small></span><button className="icon-button" title="Detalji posla" onClick={()=>{setJobDetail(j);setModal('job');}}><ChevronRight size={18}/></button></div>)}</div>{!jobs.length&&<Empty title="Spremno za prvi posao" text="Kada pokreneš kampanju, odobriš ideju ili zatražiš izmenu, ovde vidiš svaki pokušaj." icon={Workflow}/>}</section>
        <section className="panel"><div className="row-heading"><h2>Istorija događaja</h2><Clock3 size={17}/></div>{events.slice(0,25).map(e=><div className="event" key={e.id}><span className={`event-dot ${e.level}`}/><div><strong>{e.message}</strong><small>{e.stage} · {date(e.created_at)} {time(e.created_at)}</small>{e.detail?.next_action&&<p>{e.detail.next_action}</p>}</div>{e.level==='error'&&!e.resolved_at&&<button className="text-button" onClick={async()=>{try{await api(`incidents/${e.id}/resolve`,{});await load();}catch(err:any){notify(err.message);}}}>Označi rešeno<Check size={14}/></button>}</div>)}</section>
      </>}
      {view==='team'&&<>
        {sectionHead('YOUR CONNECTED TEAM','Ceo tim. Jedan workspace.','Strategija, kreativna produkcija, distribucija i učenje za GymFeed.')}
        <div className="department-grid">{Object.entries(data?.departments||{}).map(([id,d]:any)=><section className="department-card" key={id}><div className="department-top"><span className="department-icon">{id==='creative'?<Clapperboard/>:id==='email'?<Mail/>:id==='analytics'?<TrendingUp/>:id==='seo'?<Globe/>:id==='sales'?<Users/>:id==='community'?<Send/>:<Search/>}</span><span className="tag">{['email','sales','seo','community'].includes(id)?'DRAFT & REVIEW':'CONNECTED'}</span></div><h2>{d.title}</h2><p>{id==='research'?'Publika, dokazi i originalni kreativni pravci.':id==='creative'?'Priča, storyboard, kontinuitet, zvuk i gotovi materijali.':id==='analytics'?'Podaci, troškovi i eksperimenti za sledeću nedelju.':id==='email'?'Onboarding i reaktivacija. Slanje čeka povezan servis i odobrenje.':id==='sales'?'Kreatori, partnerstva i kvalifikacija prilika.':id==='seo'?'Search intent, content briefovi i predlozi za sajt.':'Copy za kanale i priprema odgovora, uz ljudsku proveru.'}</p><button className="text-button" onClick={()=>{setDepartment(id);setInstructions('');setModal('brief');}}>Novi brief<ArrowUpRight size={15}/></button></section>)}</div>
        <section className="panel connections"><div className="row-heading"><h2>Konekcije i produkcija</h2><Settings2 size={18}/></div>{Object.entries(data?.settings?.connections||{}).map(([name,connected]:any)=><div className="connection-row" key={name}><span className="connection-icon">{name==='openai'?<Sparkles size={19}/>:name==='fal'?<Film size={19}/>:name==='email'?<Mail size={19}/>:<Globe size={19}/>}</span><strong>{({openai:'AI strategy & copy',fal:'fal.ai · media generation',buffer:'Buffer · publishing',googleDrive:'Google Drive · source recordings',ga4:'GA4 · property configuration',email:'Email delivery',crm:'CRM & booking'} as Any)[name]}</strong><Badge status={connected?'succeeded':'pending'}>{connected?'Podešeno':'Nije povezano'}</Badge></div>)}<p className="panel-note">Status označava serversku konfiguraciju, ne potvrdu da provajder trenutno odgovara.</p><div className="model-row"><span>Video<strong>{data?.settings?.videoModel}</strong></span><span>Images<strong>{data?.settings?.imageModel}</strong></span><span>Review<strong>{data?.settings?.reviewMode==='human'?'Owner review':'AI + owner review'}</strong></span></div></section>
      </>}
      {view==='knowledge'&&<>
        {sectionHead('KNOWLEDGE & CREATIVE MEMORY','Sistem koji pamti. I uči.','Proizvodne činjenice, istorija ideja i pravila koja vode sledeću kampanju.')}
        <section className="strategy-banner"><span className="eyebrow">CMO OPERATING SYSTEM / V4</span><h2>Nova ideja počinje novim razlogom.</h2><p>Promena glumice, sobe ili feature-a nije dovoljna. Sistem sada poredi premise i hookove sa dužom arhivom, prikazuje zasićenost i traži različite priče sa jasnim eksperimentom.</p><div className="strategy-tags"><span><Check size={14}/>90-day archive</span><span><Check size={14}/>Hook novelty gate</span><span><Check size={14}/>Evidence before claims</span><span><Check size={14}/>Owner feedback first</span></div></section>
        <div className="two-columns"><section className="panel"><h2>Pravila odlučivanja</h2>{data?.intelligence?.operating_rules?.map((rule:string,i:number)=><div className="rule" key={rule}><span>{String(i+1).padStart(2,'0')}</span><p>{rule}</p></div>)}</section><section className="panel"><h2>Zasićenost tema</h2>{data?.intelligence?.feature_frequency?.slice(0,10).map((f:Any)=><div className="metric-row" key={f.name}><span>{f.name.replaceAll('_',' ')}</span><b>{f.count} materijala</b></div>)}<p className="panel-note">Učestalost vodi istraživanje novih uglova; ne dokazuje da je tema loša ili dobra.</p></section></div>
        <section className="panel"><div className="row-heading"><h2>Izvori iza novog procesa</h2><BookOpen size={18}/></div><div className="sources-grid">{data?.sources?.map((s:Any)=><a href={s.url} target="_blank" rel="noreferrer" className="source" key={s.url}><span>{new URL(s.url).hostname}</span><h3>{s.title}<ArrowUpRight size={16}/></h3><p>{s.use}</p></a>)}</div></section>
        <section className="panel"><div className="row-heading"><h2>Istraživanja kampanja</h2><Search size={18}/></div>{data?.research?.map((r:Any)=><details className="research" key={r.id}><summary>{date(r.created_at)}<strong>{r.summary?.slice(0,150)}</strong><ChevronDown size={16}/></summary><p>{r.summary}</p>{r.sources?.map((url:string)=><a href={url} target="_blank" rel="noreferrer" key={url}>{url}<ExternalLink size={12}/></a>)}</details>)}</section>
      </>}
      </>}
      <footer className="page-footer"><span><span className="local-dot"/>GymFeed Marketing Studio</span><span>{data?`Poslednja sinhronizacija ${time(data.fetchedAt)} · Osvežava se na 15s`:'Povezivanje sa workspaceom…'}</span></footer>
    </main></div>

    {selected&&<div className="drawer-overlay" onClick={()=>setSelected(null)}><aside className="drawer" onClick={e=>e.stopPropagation()}><div className="drawer-top"><span className="eyebrow">{assetType(selected.type)} / REVISION {selected.revision}</span><button className="icon-button" aria-label="Zatvori detalje" onClick={()=>setSelected(null)}><X size={21}/></button></div><h2>{selected.title}</h2><div className="drawer-meta"><Badge status={selected.blocked?'failed':selected.status}/><span>{date(selected.date)}</span><span>{selected.duration?`${selected.duration} sekundi`:assetType(selected.type)}</span></div><div className="tabs drawer-tabs">{[['brief','Brief'],['story','Storyboard'],['assets','Materijali'],['errors','Status i greške']].map(([id,label])=><button key={id} className={detailTab===id?'selected':''} onClick={()=>setDetailTab(id)}>{label}</button>)}</div>
      {!detail?<div className="loading-state"><LoaderCircle className="spin"/>Učitavam detalje…</div>:<div className="drawer-content">
        {detailTab==='brief'&&<><span className="eyebrow">THE HOOK</span><blockquote>{detail.hook}</blockquote><h3>Ideja</h3><p>{detail.concept}</p><div className="detail-fields"><div><small>FEATURE</small><strong>{detail.feature||'—'}</strong></div><div><small>FORMAT</small><strong>{detail.treatment?.format_family?.replaceAll('_',' ')||assetType(detail.type)}</strong></div></div>{detail.rationale&&<><h3>Zašto ova ideja</h3><p>{clean(detail.rationale)}</p></>}{detail.experiment&&<details className="detail-disclosure"><summary>Eksperiment i merenje<ChevronDown size={15}/></summary><pre>{clean(detail.experiment)}</pre></details>}{detail.research?.summary&&<details className="detail-disclosure"><summary>Dokazi i istraživanje<ChevronDown size={15}/></summary><p>{detail.research.summary}</p></details>}</>}
        {detailTab==='story'&&<>{(detail.plan?.scenes||detail.plan?.slides||[]).map((s:Any,i:number)=><div className="story-scene" key={s.scene_id||i}><div className="scene-number">{String(i+1).padStart(2,'0')}</div><div><div className="scene-label">{s.asset_type?.replaceAll('_',' ')||s.visual_type?.replaceAll('_',' ')}{s.duration_seconds?` · ${s.duration_seconds}s`:''}</div><h3>{s.headline||s.action||s.purpose}</h3><p>{s.spoken_dialogue||s.voiceover_text||s.body||s.visual_prompt}</p>{s.overlay_text&&<span className="overlay-copy">Overlay: {s.overlay_text}</span>}{s.capture_ref&&<code>{s.capture_ref}</code>}</div></div>)}</>}
        {detailTab==='assets'&&<>
          {detail.assets?.map((url:string,i:number)=><div className="asset-preview" key={url}>{selected.type==='video'?<video controls preload="metadata" src={url}/>:<img src={url} alt={`Materijal ${i+1}`}/>}<a href={url} target="_blank" rel="noreferrer">Otvori materijal {i+1}<ExternalLink size={14}/></a></div>)}
          {!detail.assets?.length&&<Empty title="Gotov materijal još nije dostupan" text="Ovde će se pojaviti završeni video ili slike." icon={Film}/>}
          {Object.entries(detail.captureUploads ?? {}).map(([ref, ready]) => {
            const capture = detail.plan?.capture_requests?.find((r: Any) => r.capture_ref === ref);
            const scenes = (detail.plan?.scenes ?? []).filter((scene: Any) => scene.asset_type === 'app_capture' && scene.capture_ref === ref);
            const notes = new Set<string>();
            if (capture?.target_duration_seconds) notes.add(`Ciljano trajanje izvornog snimka: ${capture.target_duration_seconds} s.`);
            for (const scene of scenes) {
              if (typeof scene.duration_seconds === 'number') {
                const start = scene.source_start_seconds ?? 0;
                notes.add(`Deo snimka koji se koristi: od ${start} do ${start + scene.duration_seconds} s.`);
              }
              if (scene.action && capture?.shot_instructions) notes.add(scene.action);
              if (scene.continuity_notes) notes.add(scene.continuity_notes);
            }
            return <CaptureUpload key={detail.id + ref} filename={ref.slice(10) + '.mp4'}
              instructions={capture?.shot_instructions || scenes[0]?.action} notes={[...notes]}
              ready={ready as { source: string; duration: number } | null}
              upload={(file, actions) => upload(detail.id, file, ref, actions)}/>;
          })}
        </>}
        {detailTab==='errors'&&<>
          <div className="detail-fields"><div><small>POSLEDNJI KORAK</small><strong>{detail.progress?.stage||detail.status}</strong></div><div><small>SAČUVANE SCENE</small><strong>{detail.sceneProgress.complete} / {detail.sceneProgress.total}</strong></div></div>
          {(detail.error||detail.progress?.message)&&<div className={detail.error?'error-detail':'info-detail'}><strong>{detail.error?'Razlog zaustavljanja':'Poslednji status'}</strong><p>{detail.error||detail.progress.message}</p></div>}
          {detail.scenes?.map((s:Any)=><div className="scene-status" key={s.id}><div><strong>{s.id}</strong><Badge status={s.status}/><span>Pokušaj {s.attempt}</span></div><small>{s.model}</small>{s.taskId&&<code>Task: {s.taskId}</code>}{s.error&&<p className="error-text">{s.error}</p>}{s.url&&<a href={s.url} target="_blank" rel="noreferrer">Otvori sačuvanu scenu<ExternalLink size={12}/></a>}{s.history?.length>0&&<details><summary>Prethodni pokušaji ({s.history.length})</summary><pre>{clean(s.history)}</pre></details>}</div>)}
          {jobs.filter(j=>j.content_id===detail.id).map(j=><div className="linked-job" key={j.id}><div><Badge status={j.status}/><strong>{j.kind.replaceAll('_',' ')}</strong></div><p>{j.error?.message}</p>{j.error?.next_action&&<p>{j.error.next_action}</p>}</div>)}
        </>}
      </div>}
      <div className="drawer-actions"><label className="field-label">Tvoja uputstva za izmenu<textarea value={instructions} onChange={e=>setInstructions(e.target.value)} placeholder="Šta tačno treba promeniti u ideji ili gotovom materijalu?"/></label><div className="action-buttons">{['planned','failed','generating'].includes(selected.status)&&!selected.assets.length?<><button className="button subtle" disabled={!!busy||instructions.trim().length<5} onClick={()=>void decide('idea_reject')}>Traži izmenu</button><button className="button primary" disabled={!!busy||selected.status==='generating'} onClick={()=>void decide(selected.ideaStatus==='approved'?'resume_content':'idea_approve')}>{busy?<LoaderCircle size={16} className="spin"/>:<Play size={15}/>} {selected.ideaStatus==='approved'?'Nastavi produkciju':'Odobri i pokreni'}</button></>:['awaiting_approval','qa_failed','failed'].includes(selected.status)&&selected.assets.length>0?<><button className="button subtle" disabled={!!busy||instructions.trim().length<5} onClick={()=>void decide('asset_reject')}>Vrati na izmenu</button><button className="button primary" disabled={!!busy} onClick={()=>setModal('publish')}><Check size={16}/>Odobri za objavu</button></>:<span className="muted">{statusNames[selected.status]||selected.status} · sve odluke ostaju sačuvane.</span>}</div></div>
    </aside></div>}

    {modal&&<div className="modal-overlay" onClick={()=>setModal('')}><section role="dialog" aria-modal="true" className="modal" onClick={e=>e.stopPropagation()}><button className="modal-close icon-button" aria-label="Zatvori prozor" onClick={()=>setModal('')}><X size={20}/></button>
      {modal==='campaign'&&<><span className="modal-icon"><Sparkles size={24}/></span><span className="eyebrow">RESEARCH → IDEAS → YOUR REVIEW</span><h2>Sledeća dobra kampanja.</h2><p>CMO istražuje i priprema nove ideje. Generisanje materijala kreće tek kada odobriš pojedinačnu ideju.</p><label className="field-label">Naziv kampanje<input value={campaignName} onChange={e=>setCampaignName(e.target.value)}/></label><div className="form-columns"><label className="field-label">Prvi dan<input type="date" value={startDate} onChange={e=>setStartDate(e.target.value)}/></label><label className="field-label">Broj dana<select value={days} onChange={e=>setDays(Number(e.target.value))}>{[1,3,7,14].map(d=><option key={d} value={d}>{d} {d===1?'dan':'dana'}</option>)}</select></label></div><div className="mini-notice"><ShieldCheck size={16}/>Istraživanje koristi AI budžet. Produkcija čeka tvoje odobrenje.</div><button className="button primary full" disabled={!!busy||campaignName.trim().length<3} onClick={()=>void enqueue('plan_campaign',{name:campaignName,startDate,days})}>{busy?<LoaderCircle size={16} className="spin"/>:<Sparkles size={16}/>}Istraži i napravi plan</button></>}
      {modal==='brief'&&<><span className="modal-icon"><FileText size={24}/></span><span className="eyebrow">{data?.departments?.[department]?.title}</span><h2>Šta želiš da istražimo?</h2><p>Dobijaš sačuvan brief u redu poslova. Emailovi, odgovori i izmene sajta ostaju nacrti za pregled.</p><label className="field-label">Uputstva<textarea rows={6} value={instructions} onChange={e=>setInstructions(e.target.value)} placeholder="Publika, problem, cilj i šta želiš da uradimo drugačije…"/></label><button className="button primary full" disabled={!!busy} onClick={()=>void enqueue('department_brief',{department,instructions})}><Sparkles size={16}/>Napravi brief</button></>}
      {modal==='publish'&&<><span className="modal-icon"><Send size={24}/></span><h2>Odobri ovaj materijal za objavu?</h2><p>Potvrđuješ gotov materijal trenutne revizije. Postojeći publishing tok zatim ga prosleđuje povezanim kanalima preko Buffera.</p><button className="button primary full" disabled={!!busy} onClick={()=>void decide('asset_approve')}><Check size={16}/>Potvrdi odobrenje za objavu</button></>}
      {modal==='job'&&jobDetail&&<><span className="eyebrow">JOB / {jobDetail.id.slice(0,8)}</span><h2>{jobDetail.kind.replaceAll('_',' ')}</h2><Badge status={jobDetail.status}/><p>Pokušaj {jobDetail.attempts} od {jobDetail.max_attempts} · {date(jobDetail.created_at)} {time(jobDetail.created_at)}</p>{jobDetail.error&&<div className="error-detail"><strong>{jobDetail.error.code}</strong><p>{jobDetail.error.message}</p><h3>Sledeći korak</h3><p>{jobDetail.kind === 'plan_campaign' && canRetryJob(jobDetail) ? 'Klikni Nastavi kampanju. Studio kreće od prvog nedovršenog dana.' : jobDetail.error.next_action}</p></div>}{jobDetail.result&&<div className="brief-result">{jobDetail.result.title&&<h3>{jobDetail.result.title}</h3>}{jobDetail.result.summary&&<p>{jobDetail.result.summary}</p>}{jobDetail.result.items?.map((item:Any,i:number)=><article key={i}><span className="eyebrow">{item.channel} · {item.objective}</span><h3>{item.title}</h3><p>{item.body}</p><small>Merimo: {item.success_metric}</small></article>)}{jobDetail.result.next_actions?.map((a:string)=><p key={a}>→ {a}</p>)}{jobDetail.result.limitations?.map((a:string)=><p className="muted" key={a}>{a}</p>)}{!jobDetail.result.items&&<pre>{clean(jobDetail.result)}</pre>}</div>}{['failed','needs_attention'].includes(jobDetail.status)&&<button className="button primary full" disabled={!!busy||!canRetryJob(jobDetail)} onClick={()=>void retry(jobDetail)}><RefreshCw size={16}/>{jobDetail.kind==='plan_campaign'?'Nastavi kampanju':'Retry operacije'}</button>}{['queued','retry_wait'].includes(jobDetail.status)&&<button className="button subtle full" onClick={async()=>{try{await api(`jobs/${jobDetail.id}/cancel`,{});setModal('');await load();}catch(e:any){notify(e.message);}}}>Otkaži posao u redu</button>}</>}
    </section></div>}
    {toast&&<div role="status" className="toast"><CircleAlert size={17}/>{toast}<button aria-label="Zatvori obaveštenje" onClick={()=>setToast('')}><X size={15}/></button></div>}
  </div>;
}
