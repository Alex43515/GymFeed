const words = value => String(value ?? "").toLowerCase().replace(/gymfeed/g, "").match(/[\p{L}\p{N}]+/gu) ?? [];
const stop = new Set(["the","a","an","to","and","your","you","for","with","in","on","is","it","of","this","that"]);
export function hookSimilarity(a, b) {
  const left = new Set(words(a).filter(w => !stop.has(w))), right = new Set(words(b).filter(w => !stop.has(w)));
  if (left.size < 3 || right.size < 3) return words(a).join(" ") === words(b).join(" ") && left.size ? 1 : 0;
  return [...left].filter(w => right.has(w)).length / new Set([...left, ...right]).size;
}
const frequencies = values => Object.entries(values.filter(Boolean).reduce((out, value) => ({ ...out, [value]: (out[value] ?? 0) + 1 }), {}))
  .map(([name, count]) => ({ name, count })).sort((a, b) => b.count - a.count);
export function attributionSummary(events = []) {
  const groups = new Map(); let unattributed = 0;
  for (const event of events) {
    const id = event.content_id ?? event.utm_content ?? event.properties?.content_id ?? event.properties?.utm_content;
    if (!id) { unattributed++; continue; }
    const key = String(id);
    const group = groups.get(key) ?? { content_ref: key, event_counts: {}, latest_at: null };
    const name = event.event_name ?? event.name ?? "unknown";
    const count = Number(event.event_count ?? event.count ?? 1);
    group.event_counts[name] = (group.event_counts[name] ?? 0) + (Number.isFinite(count) && count >= 0 ? count : 1);
    const at = event.occurred_at ?? event.created_at;
    if (at && (!group.latest_at || at > group.latest_at)) group.latest_at = at;
    groups.set(key, group);
  }
  return { sample_rows: events.length, unattributed_rows: unattributed, content: [...groups.values()].slice(0, 40),
    possibly_truncated: events.length >= 2000,
    limitation: "Counts are observed identifiers in the supplied event sample, not causal lift or conversion rates. Exposure denominators and a consistent attribution window are still required." };
}
export function creativeIntelligence(content = [], publications = [], events = []) {
  const rows = content.filter(row => !row.master_content_id).slice(0, 240);
  const plans = rows.map(row => ({ ...row, plan: row.decision?.content ?? {} }));
  const videos = plans.filter(row => row.content_type === "video");
  const pairs = [];
  for (let i = 0; i < Math.min(plans.length, 90); i++) for (let j = i + 1; j < Math.min(plans.length, 90); j++) {
    if (plans[i].content_type !== plans[j].content_type) continue;
    const similarity = hookSimilarity(plans[i].plan.hook ?? plans[i].hook, plans[j].plan.hook ?? plans[j].hook);
    if (similarity >= 0.7) pairs.push({ first_id: plans[i].id, second_id: plans[j].id,
      hook: plans[i].plan.hook ?? plans[i].hook, similarity: Number(similarity.toFixed(2)) });
  }
  const attributed = events.filter(e => e.content_id || e.properties?.content_id || e.properties?.utm_content);
  return {
    version: "gymfeed-cmo-4", sample_size: rows.length,
    scope: "Up to 240 master assets from the available 90-day archive. Planned content is not performance evidence.",
    format_frequency: frequencies(videos.map(r => r.plan.creative_treatment?.format_family)),
    setting_frequency: frequencies(videos.map(r => r.plan.creative_treatment?.setting_family)),
    feature_frequency: frequencies(plans.map(r => r.plan.product_feature ?? r.plan.product_features?.join(","))),
    hook_pattern_frequency: frequencies(videos.map(r => r.plan.creative_treatment?.hook_pattern)),
    duplicate_hooks: pairs.slice(0, 15),
    last_video_concepts: videos.slice(0, 12).map(r => ({ id: r.id, hook: r.plan.hook ?? r.hook,
      concept: (r.plan.concept ?? r.concept ?? "").slice(0, 400), format: r.plan.creative_treatment?.format_family,
      setting: r.plan.creative_treatment?.setting_family, feature: r.plan.product_feature })),
    measurement: { publications: publications.length, events: events.length, attributable_events: attributed.length,
      limitations: attributed.length ? ["Attribution identifiers do not establish causality. Use a consistent conversion window and denominator."]
        : ["No event-level content attribution found in this sample. Views and aggregate signups cannot identify a winning creative."] },
    operating_rules: ["Start with audience tension and a business hypothesis, then choose product proof.",
      "Changing the room, actress or feature does not make a repeated plot original.",
      "Compare distinct premises, narrative structures and payoffs, with explicit failure risks.",
      "Separate observed facts, hypotheses and missing data. QA scores are not conversion evidence.",
      "Test one main variable with a named control, metric, denominator and observation window.",
      "Owner-requested concepts take precedence over autonomous rotation."],
  };
}
export function assertFreshHooks(decision, memory = []) {
  for (const [type, plan] of [["video", decision.video], ["carousel", decision.instagram], ["image", decision.post]]) {
    const duplicate = memory.filter(row => row.content_type === type).slice(0, 30)
      .find(row => hookSimilarity(plan.hook, row.hook) >= 0.82);
    if (duplicate) throw new Error(`Creative novelty: ${type} hook repeats ${duplicate.id}. Change the audience tension and opening premise, not just synonyms.`);
  }
}
