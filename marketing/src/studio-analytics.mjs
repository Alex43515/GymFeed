import { OAuth2Client } from "google-auth-library";
import { redact } from "./studio-errors.mjs";

const TTL = 300_000;
const platforms = ["instagram", "tiktok", "youtube"];
const nativeLinks = {
  instagram: "https://business.facebook.com/latest/insights",
  tiktok: "https://www.tiktok.com/tiktokstudio/analytics",
  youtube: "https://studio.youtube.com/",
};

async function publicationRows(client) {
  const rows = [];
  for (let start = 0; ; start += 500) {
    const result = await client.from("marketing_publications")
      .select("id,content_id,platform,provider_request_id,external_post_id,external_url,published_at,metrics,last_metrics_sync_at,marketing_content(topic,content_type)")
      .eq("status", "published").order("id").range(start, start + 499);
    if (result.error) throw new Error(result.error.message);
    rows.push(...result.data);
    if (result.data.length < 500) return rows;
  }
}

function youtubeId(value) {
  try {
    const url = new URL(value);
    const host = url.hostname.replace(/^www\./, "");
    const id = host === "youtu.be" ? url.pathname.split("/")[1]
      : ["youtube.com", "m.youtube.com"].includes(host)
        ? url.searchParams.get("v") ?? url.pathname.match(/^\/(?:shorts|live)\/([^/]+)/)?.[1]
        : null;
    return /^[\w-]{11}$/.test(id ?? "") ? id : null;
  } catch { return null; }
}

function audienceProviders(config) {
  const { YOUTUBE_ANALYTICS_CLIENT_ID, YOUTUBE_ANALYTICS_CLIENT_SECRET, YOUTUBE_ANALYTICS_REFRESH_TOKEN } = config;
  const youtube = YOUTUBE_ANALYTICS_CLIENT_ID && YOUTUBE_ANALYTICS_CLIENT_SECRET && YOUTUBE_ANALYTICS_REFRESH_TOKEN
    ? new OAuth2Client(YOUTUBE_ANALYTICS_CLIENT_ID, YOUTUBE_ANALYTICS_CLIENT_SECRET)
    : null;
  youtube?.setCredentials({ refresh_token: YOUTUBE_ANALYTICS_REFRESH_TOKEN });
  const instagram = Boolean(config.INSTAGRAM_INSIGHTS_TOKEN && config.INSTAGRAM_BUSINESS_ACCOUNT_ID);
  const { TIKTOK_BUSINESS_APP_ID, TIKTOK_BUSINESS_APP_SECRET, TIKTOK_BUSINESS_OPEN_ID, TIKTOK_BUSINESS_REFRESH_TOKEN } = config;
  const tiktok = TIKTOK_BUSINESS_APP_ID && TIKTOK_BUSINESS_APP_SECRET && TIKTOK_BUSINESS_OPEN_ID && TIKTOK_BUSINESS_REFRESH_TOKEN
    ? tiktokSession(config) : null;
  return { youtube, instagram, tiktok };
}

const TIKTOK_API = "https://business-api.tiktok.com/open_api/v1.3/";

async function tiktokCall(path, init) {
  const response = await fetch(TIKTOK_API + path, { ...init, signal: AbortSignal.timeout(12000) });
  const json = await response.json().catch(() => ({}));
  if (!response.ok || json.code !== 0) throw new Error(json.message ?? "TikTok API HTTP " + response.status);
  return json.data;
}

// TikTok Accounts API access tokens live 24h; the refresh token (1 year) may rotate on each refresh.
function tiktokSession(config) {
  let refreshToken = config.TIKTOK_BUSINESS_REFRESH_TOKEN, accessToken, expiresAt = 0;
  return {
    openId: config.TIKTOK_BUSINESS_OPEN_ID,
    async token() {
      if (accessToken && Date.now() < expiresAt) return accessToken;
      const data = await tiktokCall("tt_user/oauth2/refresh_token/", {
        method: "POST", headers: { "content-type": "application/json" },
        body: JSON.stringify({ client_id: config.TIKTOK_BUSINESS_APP_ID, client_secret: config.TIKTOK_BUSINESS_APP_SECRET,
          grant_type: "refresh_token", refresh_token: refreshToken }),
      });
      accessToken = data.access_token;
      expiresAt = Date.now() + Math.max(60, (data.expires_in ?? 86400) - 300) * 1000;
      if (data.refresh_token && data.refresh_token !== refreshToken) {
        refreshToken = data.refresh_token;
        console.warn("TikTok refresh token rotated; update TIKTOK_BUSINESS_REFRESH_TOKEN before the next restart.");
      }
      return accessToken;
    },
  };
}

async function tiktokAudience(session) {
  // Follower demographics come from TikTok Studio data, so they work for personal accounts with 100+ followers.
  const specs = [["countries", "audience_countries", "country"], ["cities", "audience_cities", "city_name"],
    ["gender", "audience_genders", "gender"], ["age", "audience_ages", "age"]];
  let data, failure;
  try {
    const query = new URLSearchParams({ business_id: session.openId, fields: JSON.stringify(specs.map(([, field]) => field)) });
    data = await tiktokCall("business/get/?" + query, { headers: { "Access-Token": await session.token() } });
  } catch (error) { failure = error; }
  const results = specs.map(([, field, key]) => failure ? { status: "rejected", reason: failure } : {
    status: "fulfilled",
    value: (data?.[field] ?? []).map(item => ({ label: item[key], value: Math.round(item.percentage * 1000) / 10, unit: "percent" }))
      .filter(item => item.label && Number.isFinite(item.value)),
  });
  return audienceResult(specs, results, "channel", "TikTok Accounts API", "Pratioci, poslednje dostupno stanje");
}

async function youtubeAudience(client, videoId) {
  const end = new Date(), start = new Date(end.getTime() - 29 * 86400000);
  const startDate = start.toISOString().slice(0, 10), endDate = end.toISOString().slice(0, 10);
  const specs = [
    ["countries", "country", "views", "count"], ["gender", "gender", "viewerPercentage", "percent"],
    ["age", "ageGroup", "viewerPercentage", "percent"], ["traffic", "insightTrafficSourceType", "views", "count"],
  ];
  const results = await Promise.allSettled(specs.map(async ([, dimensions, metrics, unit]) => {
    const params = { ids: "channel==MINE", startDate, endDate, dimensions, metrics,
      ...(videoId ? { filters: "video==" + videoId } : {}) };
    const response = await client.request({ url: "https://youtubeanalytics.googleapis.com/v2/reports", params, timeout: 12000 });
    return (response.data.rows ?? []).map(([label, value]) => ({ label, value, unit }));
  }));
  return audienceResult(specs, results, videoId ? "post" : "channel", "YouTube Analytics", startDate + " – " + endDate);
}

async function instagramAudience(config) {
  const specs = [["countries", "country"], ["cities", "city"], ["gender", "gender"], ["age", "age"]];
  const version = /^v\d+\.\d+$/.test(config.INSTAGRAM_GRAPH_VERSION ?? "") ? config.INSTAGRAM_GRAPH_VERSION : "v23.0";
  const accountId = encodeURIComponent(config.INSTAGRAM_BUSINESS_ACCOUNT_ID);
  const results = await Promise.allSettled(specs.map(async ([, breakdown]) => {
    const url = new URL("https://graph.facebook.com/" + version + "/" + accountId + "/insights");
    url.search = new URLSearchParams({ metric: "reached_audience_demographics", period: "lifetime",
      // Graph API v20+ rejects last_30_days for demographics; this_week/this_month are the supported windows.
      metric_type: "total_value", timeframe: "this_month", breakdown });
    const response = await fetch(url, { headers: { authorization: "Bearer " + config.INSTAGRAM_INSIGHTS_TOKEN }, signal: AbortSignal.timeout(12000) });
    const json = await response.json();
    if (!response.ok || json.error) throw new Error(json.error?.message ?? "Meta Insights HTTP " + response.status);
    return (json.data?.[0]?.total_value?.breakdowns ?? []).flatMap(item => item.results ?? [])
      .map(item => ({ label: item.dimension_values?.[0], value: item.value, unit: "count" }))
      .filter(item => item.label && Number.isFinite(item.value));
  }));
  return audienceResult(specs, results, "channel", "Meta Insights", "Ovaj mesec");
}

function audienceResult(specs, results, scope, source, period) {
  const breakdowns = {}, errors = {};
  specs.forEach(([name], index) => {
    const result = results[index];
    if (result.status === "fulfilled") breakdowns[name] = result.value;
    else errors[name] = result.reason?.response?.data?.error?.message ?? result.reason?.message ?? "Izveštaj nije dostupan.";
  });
  return { scope, source, period, breakdowns, errors };
}

export function registerStudioAnalytics(app, { repository, publisher, config }) {
  const providers = audienceProviders(config);
  const secrets = Object.entries(config).filter(([key]) => /KEY|TOKEN|SECRET/.test(key)).map(([, value]) => value);
  const channelIds = [config.BUFFER_INSTAGRAM_CHANNEL_ID, config.BUFFER_TIKTOK_CHANNEL_ID, config.BUFFER_YOUTUBE_CHANNEL_ID].filter(Boolean);
  let cached, pending;
  const audienceCache = new Map();

  async function social() {
    if (cached && Date.now() - cached.at < TTL) return cached;
    if (pending) return pending;
    pending = (async () => {
      const [saved, remote] = await Promise.allSettled([
        publicationRows(repository.client),
        publisher?.apiKey && channelIds.length ? publisher.analyticsPosts(channelIds) : Promise.reject(new Error("Podesi Buffer i ID-jeve GymFeed kanala.")),
      ]);
      const posts = new Map((remote.value ?? []).map(post => [post.id, { ...post, source: "Buffer" }]));
      for (const row of saved.value ?? []) {
        const providerIds = [row.provider_request_id, row.external_post_id].filter(Boolean);
        const id = providerIds.find(key => posts.has(key)) ?? providerIds[0] ?? row.id;
        const snapshot = posts.get(id);
        const content = row.marketing_content;
        const format = content?.content_type === "video" && row.platform === "instagram" ? "reel" : content?.content_type;
        posts.set(id, {
          id, platform: row.platform, format, sent_at: row.published_at,
          metrics: row.metrics?.values ?? {},
          metric_units: Object.fromEntries((row.metrics?.details ?? []).map(metric => [metric.type, metric.unit])),
          metrics_updated_at: row.metrics?.provider_updated_at ?? row.last_metrics_sync_at,
          source: "Sačuvani Buffer podaci", ...snapshot,
          external_url: snapshot?.external_url ?? row.external_url,
          title: content?.topic, publication_id: row.id, content_id: row.content_id,
        });
      }
      cached = { at: Date.now(), posts: [...posts.values()].sort((a, b) => String(b.sent_at ?? "").localeCompare(String(a.sent_at ?? ""))),
        error: remote.status === "rejected" ? remote.reason.message : null,
        publication_error: saved.status === "rejected" ? saved.reason.message : null };
      return cached;
    })().finally(() => { pending = null; });
    return pending;
  }

  app.get("/v1/studio/analytics/:days", async (request, reply) => {
    const days = Number(request.params.days);
    if (![7, 30, 90, 365].includes(days)) return reply.code(400).send({ message: "Izaberi 7, 30, 90 ili 365 dana." });
    const [signups, report] = await Promise.all([repository.client.rpc("marketing_studio_signup_report", { p_days: days }), social()]);
    const { publications, ...registrations } = signups.data ?? {};
    return redact({
      registrations: signups.error ? null : registrations,
      registration_error: signups.error?.message ?? null,
      posts: report.posts.map(post => ({ ...post, attributed_signups: post.publication_id && publications
        ? publications[post.publication_id] ?? 0 : null })),
      collected_at: new Date(report.at).toISOString(), social_error: report.error, publication_error: report.publication_error,
    }, secrets);
  });

  app.get("/v1/studio/analytics/audience/:id", async (request, reply) => {
    const { id } = request.params;
    const hit = audienceCache.get(id);
    if (hit && Date.now() - hit.at < TTL) return hit.report;
    const account = id.startsWith("account-") ? id.slice(8) : null;
    const post = account ? null : (await social()).posts.find(item => item.id === id);
    const platform = account ?? post?.platform;
    if (!platforms.includes(platform)) return reply.code(404).send({ message: "Objava nije pronađena." });
    let report;
    if (platform === "youtube" && providers.youtube && (account || youtubeId(post?.external_url))) {
      report = await youtubeAudience(providers.youtube, account ? null : youtubeId(post.external_url));
    } else if (platform === "instagram" && account && providers.instagram) {
      report = await instagramAudience(config);
    } else if (platform === "tiktok" && account && providers.tiktok) {
      report = await tiktokAudience(providers.tiktok);
    } else {
      report = { scope: account ? "channel" : "post", breakdowns: {},
        reason: platform === "tiktok" && !account ? "TikTok demografija preko ove integracije pripada nalogu. Za ovu objavu otvori TikTok Studio."
          : platform === "tiktok" ? "Demografija pratilaca (zemlje, gradovi, pol, starost) stiže kad TikTok odobri Accounts API aplikaciju. Do tada su gore ukupne brojke kanala iz Buffer-a."
          : platform === "instagram" && !account ? "Instagram demografija preko ove integracije pripada nalogu. Za ovu objavu proveri njen Insights."
          : platform === "instagram" ? "Potreban je Meta Insights token za GymFeed profesionalni nalog."
          : providers.youtube ? "Nedostaje originalni YouTube URL za ovu objavu."
          : "Poveži YouTube Analytics OAuth nalog vlasnika kanala." };
    }
    report = redact({ ...report, native_url: nativeLinks[platform] }, secrets);
    if (audienceCache.size >= 250) audienceCache.delete(audienceCache.keys().next().value);
    audienceCache.set(id, { at: Date.now(), report });
    return report;
  });
}
