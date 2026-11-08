import { createHash } from "node:crypto";
import { GoogleSheetsApprovalQueue } from "./google-sheets.mjs";

export const CONTENT_HEADERS = [
  "Decision", "Current status", "Reason / next step", "QA score", "Preview", "Asset 1",
  "Topic", "Planned date", "Buffer status", "Buffer posts", "Revision instructions", "Last activity",
  "Content type", "Caption", "AI QA score", "QA summary", "Asset 2", "Asset 3", "Asset 4", "Asset 5", "Asset 6", "Asset 7",
  "Hook", "Concept", "Revision", "Content key", "Content ID", "Pipeline state", "Updated at",
  "Processing result", "Processed at", "Processed decision fingerprint",
];
export const IDEA_HEADERS = [
  "Idea decision", "Current status", "Reason / next step", "Title", "Description", "Content type",
  "Planned date", "Revision instructions", "Last activity", "Production requirements", "Generation prompt",
  "Dialogue", "Hook", "Storyboard / slide outline", "Caption", "CTA", "Audience", "GymFeed feature", "Objective",
  "Evidence and metrics", "Reasoning and limitations", "Version", "Approved version", "Campaign ID", "Idea ID",
  "Updated at", "Processing result", "Processed at", "Processed decision fingerprint", "Block kind", "Stored planned date",
];

const text = (value) => value == null ? "" : (typeof value === "string" ? value : JSON.stringify(value, null, 2)).slice(0, 48000);
const decision = (value) => /^(approve|approved)$/i.test(String(value).trim()) ? "Approve" : /^reject$/i.test(String(value).trim()) ? "Reject" : "Pending";
const object = (headers, values) => Object.fromEntries(headers.map((key, i) => [key, values[i] ?? ""]));
const cells = (headers, value) => headers.map((key) => text(value[key]));
export const fingerprint = (entry) => createHash("sha256").update(JSON.stringify([
  entry.ideaId ?? entry.contentId, entry.version ?? entry.revision, entry.decision,
  entry.instructions ?? "", entry.plannedDate ?? "", entry.qaOverride ?? null,
])).digest("hex");
export function columnName(index) {
  let name = "";
  for (let n = index + 1; n > 0; n = Math.floor((n - 1) / 26)) name = String.fromCharCode(65 + (n - 1) % 26) + name;
  return name;
}
const last = (headers) => columnName(headers.length - 1);
const revision = (content) => Number(content.decision?.review_revision ?? 1);
function latestRows(rows, idField, versionField) {
  const latest = new Map();
  for (const row of rows) {
    if (!row[idField]) continue;
    const old = latest.get(row[idField]);
    if (!old || Number(row[versionField]) >= Number(old[versionField])) latest.set(row[idField], row);
  }
  return [...latest.values()];
}

export function contentPresentation(content) {
  const progress = content.decision?.workflow ?? {};
  const publications = content.publications ?? [];
  const errors = publications.filter((p) => p.error).map((p) => `${p.platform}: ${p.error}`);
  const confirmed = publications.filter((p) => p.provider_request_id);
  const qaReasons = [...(content.qa?.critical_issues ?? []), ...(content.qa?.required_fixes ?? [])];
  const sceneReasons = (content.decision?.generation?.scenes ?? []).filter((s) => s.qa?.accept === false)
    .map((s) => `${s.scene_id}: ${s.qa?.defects?.[0] || s.qa?.required_fixes?.[0] || s.qa?.summary || "Scene QA failed"}`);
  let status = ({ planned: "Pending", generating: "Generating", generated: "Preparing review", awaiting_approval: "Needs Review",
    qa_failed: "Needs Review", failed: "Needs Review", approved: "Sending to Buffer", scheduled: "Scheduled", published: "Published" })[content.status] ?? content.status;
  if (progress.stage === "revising") status = "Revising plan";
  if (progress.stage === "repairing") status = "Repairing";
  if (progress.stage === "generating" && content.status === "planned") status = "Generating";
  if (progress.stage === "blocked" && content.status === "generating") status = "Needs Review";
  if (progress.stage === "intake" && content.status === "planned") status = "Pending";
  const editing = content.status === "generating" && (content.decision?.generation?.scenes ?? [])
    .filter((scene) => scene.operation === "edit" && ["queued", "running"].includes(scene.status));
  if (editing?.length) status = "Editing scene";
  if (content.status === "planned" && (progress.stage === "blocked" || content.decision?.campaign?.production_blocked)) status = "Approved - Blocked";
  if (errors.length || content.status === "approved" && progress.stage === "blocked") status = "Approved - Blocked";
  const musicPublications=["approved","scheduled","published"].includes(content.status)?publications.filter(p=>p.provider_request_id&&p.platform_copy?.delivery?.scheduling_type==="notification"&&p.status!=="published"&&p.status!=="pending"):[];
  const musicAction=musicPublications.some(p=>p.platform_copy.delivery.user_action_required);
  if(musicPublications.length&&!errors.length)status=musicAction?"Action required: add music":"Scheduled — music in app";
  const reviewReasons = [...new Set([...sceneReasons, ...qaReasons, ...(!sceneReasons.length && !qaReasons.length ? [content.failure_reason] : [])].filter(Boolean))];
  const hasPlatformVariants = content.content_type === "video" && content.decision?.generation?.platform_variants;
  const assetLabel = hasPlatformVariants
    ? "Assets 1-3 (Instagram Reel, TikTok, YouTube Short)"
    : "Asset 1";
  const reviewAction = `ACTION REQUIRED: Review ${assetLabel}. Set Decision to Approve to publish this asset as-is${content.qa_score == null ? "" : ` despite its QA score of ${content.qa_score}`}. Set Decision to Reject and enter Revision instructions to regenerate this same item.`;
  const reason = errors.join("\n") || (editing?.length ? `AI correction in progress: ${editing.map((scene) => scene.scene_id).join(", ")}. The edited result will be checked again before assembly.` : ["revising", "repairing"].includes(progress.stage) ? progress.message : content.status === "qa_failed" || content.status === "failed"
    ? (content.asset_urls?.length ? [reviewAction, "QA findings:", ...reviewReasons] : [content.failure_reason, ...sceneReasons]).filter(Boolean).join("\n").slice(0, 700)
    : progress.message || (content.status === "awaiting_approval" ? `Review ${assetLabel}, then Approve or Reject.` : ""));
  return {
    status, reason:musicPublications.length&&!errors.length
      ? `${musicAction?"ACTION REQUIRED":"Music notification scheduled"}: open the Buffer mobile notification, add music in Instagram/TikTok and finish publishing. ${musicPublications.map(p=>`${p.platform}: ${p.platform_copy.photo_music?.direction??"choose an available track in the app"}`).join("; ")}`:reason,
    bufferStatus: errors.length ? "Blocked" : confirmed.length ? confirmed.map((p) => `${p.platform}: ${p.platform_copy?.delivery?.scheduling_type==="notification"&&p.status!=="published"?p.platform_copy.delivery.user_action_required?"add music and publish in app":"notification scheduled":p.status}`).join("; ") : "Not submitted",
    bufferPosts: confirmed.map((p) => `${p.platform}: ${p.external_url || p.provider_request_id}`).join("\n"),
  };
}

// Header-based reads and writes keep user input attached to its item when columns move.
export class ReviewBoard extends GoogleSheetsApprovalQueue {
  constructor(options) {
    super(options);
    this.layoutLocks = new Map();
    this.boardWriteTails = new Map();
  }

  async exclusiveBoardWrite(name, task) {
    const previous = this.boardWriteTails.get(name) ?? Promise.resolve();
    let release;
    const gate = new Promise((resolve) => { release = resolve; });
    const tail = previous.then(() => gate);
    this.boardWriteTails.set(name, tail);
    await previous;
    try {
      return await task();
    } finally {
      release();
      if (this.boardWriteTails.get(name) === tail) this.boardWriteTails.delete(name);
    }
  }

  async ensureLayout(name, headers) {
    if (this.layoutLocks.has(name)) return this.layoutLocks.get(name);
    const task = this.migrateLayout(name, headers);
    this.layoutLocks.set(name, task);
    try { return await task; } catch (error) { this.layoutLocks.delete(name); throw error; }
  }

  async migrateLayout(name, headers) {
    const metadata = await this.request("?fields=sheets.properties");
    let sheet = metadata.sheets?.find((s) => s.properties.title === name);
    if (!sheet) {
      const response = await this.request(":batchUpdate", { method: "POST", body: { requests: [{ addSheet: { properties: { title: name } } }] } });
      sheet = response.replies[0].addSheet;
    }
    const sheetId = sheet.properties.sheetId;
    const result = await this.request(this.valuesPath("A1:AZ1000", name));
    const [oldHeaders = [], ...oldRows] = result.values ?? [];
    if (headers.every((h, i) => oldHeaders[i] === h)) return sheetId;
    if (oldHeaders.some(Boolean) && !oldHeaders.includes(name === this.ideaSheetName ? "Idea ID" : "Content ID")) throw new Error(`Unrecognized review layout: ${name}`);
    // Preserve a native backup (values, formatting, validation) before the one-time migration.
    const requests = oldHeaders.some(Boolean) ? [{ duplicateSheet: { sourceSheetId: sheetId, newSheetName: `${name} backup ${Date.now()}` } }] : [];
    if (Number(sheet.properties.gridProperties?.columnCount ?? 26) < headers.length) requests.push({ appendDimension: { sheetId, dimension: "COLUMNS", length: headers.length - Number(sheet.properties.gridProperties?.columnCount ?? 26) } });
    if (requests.length) await this.request(":batchUpdate", { method: "POST", body: { requests } });
    const migrated = oldRows.map((row) => {
      const data = object(oldHeaders, row);
      if (name === this.sheetName) {
        const video = data["Content type"] === "video";
        data.Decision = data.Decision || data[video ? "Video decision" : "Carousel decision"] || "Pending";
        data["Revision instructions"] ||= data[video ? "Video instructions" : "Carousel instructions"] || "";
        data["Pipeline state"] ||= data["Current status"];
        data["AI QA score"] = data["QA score"];
      }
      data["Reason / next step"] ||= data["Processing result"];
      data["Last activity"] ||= data["Processed at"] || data["Updated at"];
      return cells(headers, data);
    });
    await this.request(this.valuesPath(`A1:${last(headers)}${migrated.length + 1}`, name) + "?valueInputOption=RAW", {
      method: "PUT", body: { values: [headers, ...migrated] },
    });
    const editable = name === this.ideaSheetName ? ["Idea decision", "Planned date", "Revision instructions"] : ["Decision", "QA score", "Revision instructions"];
    const validation = name === this.ideaSheetName ? ["Pending", "Approve", "Reject"] : ["Pending", "Needs Review", "Approve", "Reject"];
    await this.request(":batchUpdate", { method: "POST", body: { requests: [
      { repeatCell: { range: { sheetId, startRowIndex: 0, endColumnIndex: headers.length }, cell: {}, fields: "dataValidation" } },
      { updateSheetProperties: { properties: { sheetId, gridProperties: { frozenRowCount: 1, frozenColumnCount: 2 } }, fields: "gridProperties.frozenRowCount,gridProperties.frozenColumnCount" } },
      { updateDimensionProperties: { range: { sheetId, dimension: "COLUMNS", startIndex: 0, endIndex: headers.length }, properties: { pixelSize: 180, hiddenByUser: false }, fields: "pixelSize,hiddenByUser" } },
      { repeatCell: { range: { sheetId, startRowIndex: 0, endRowIndex: 1, endColumnIndex: headers.length }, cell: { userEnteredFormat: { backgroundColor: { red: .08, green: .15, blue: .12 }, textFormat: { bold: true, foregroundColor: { red: 1, green: 1, blue: 1 } }, wrapStrategy: "WRAP" } }, fields: "userEnteredFormat" } },
      { repeatCell: { range: { sheetId, startRowIndex: 1, endRowIndex: 1000, endColumnIndex: headers.length }, cell: { userEnteredFormat: { wrapStrategy: "CLIP", verticalAlignment: "TOP", backgroundColor: { red: 1, green: 1, blue: 1 } } }, fields: "userEnteredFormat" } },
      { repeatCell: { range: { sheetId, startRowIndex: 1, endRowIndex: 1000, startColumnIndex: 2, endColumnIndex: 3 }, cell: { userEnteredFormat: { wrapStrategy: "WRAP" } }, fields: "userEnteredFormat.wrapStrategy" } },
      { updateDimensionProperties: { range: { sheetId, dimension: "ROWS", startIndex: 1, endIndex: Math.max(2, migrated.length + 1) }, properties: { pixelSize: 88 }, fields: "pixelSize" } },
      ...editable.map((key) => ({ repeatCell: { range: { sheetId, startRowIndex: 1, endRowIndex: 1000, startColumnIndex: headers.indexOf(key), endColumnIndex: headers.indexOf(key) + 1 }, cell: { userEnteredFormat: { backgroundColor: { red: 1, green: .97, blue: .79 } } }, fields: "userEnteredFormat.backgroundColor" } })),
      { updateDimensionProperties: { range: { sheetId, dimension: "COLUMNS", startIndex: 2, endIndex: 3 }, properties: { pixelSize: 450 }, fields: "pixelSize" } },
      { setDataValidation: { range: { sheetId, startRowIndex: 1, endRowIndex: 1000, startColumnIndex: 0, endColumnIndex: 1 }, rule: { condition: { type: "ONE_OF_LIST", values: validation.map((userEnteredValue) => ({ userEnteredValue })) }, strict: true, showCustomUi: true } } },
      ...(name === this.sheetName ? [{ setDataValidation: { range: { sheetId, startRowIndex: 1, endRowIndex: 1000, startColumnIndex: 3, endColumnIndex: 4 }, rule: { condition: { type: "NUMBER_BETWEEN", values: [{ userEnteredValue: "0" }, { userEnteredValue: "100" }] }, strict: true } } }] : []),
    ] } });
    return sheetId;
  }

  async readBoard(name, headers) {
    await this.ensureLayout(name, headers);
    const result = await this.request(this.valuesPath(`A2:${last(headers)}1000`, name));
    return (result.values ?? []).map((row, i) => ({ ...object(headers, row), rowNumber: i + 2 }));
  }
  async writeFields(name, headers, rowNumber, values) {
    return this.writeMany(name, headers, [{ rowNumber, values }]);
  }
  async writeMany(name, headers, changes) {
    const data = changes.flatMap(({ rowNumber, values }) => Object.entries(values).map(([key, value]) => {
      const index = headers.indexOf(key);
      if (index < 0) throw new Error(`Unknown review column: ${key}`);
      const col = columnName(index);
      return { range: `'${name.replace(/'/g, "''")}'!${col}${rowNumber}`, values: [[text(value)]] };
    }));
    if (data.length) await this.request("/values:batchUpdate", { method: "POST", body: { valueInputOption: "RAW", data } });
  }
  // Write at an explicit A-column row. The values:append endpoint guesses the
  // table origin and can shift every new row to a later column.
  async appendBoard(name, headers, rows) {
    if (!rows.length) return;
    const used = await this.request(this.valuesPath("A1:AZ5000", name));
    const start = (used.values?.length ?? 0) + 1;
    await this.request(this.valuesPath(`A${start}:${last(headers)}${start + rows.length - 1}`, name) + "?valueInputOption=RAW", {
      method: "PUT", body: { values: rows.map((r) => cells(headers, r)) },
    });
  }

  // Simple tabs (Shot List, Library) are rewritten in full on every refresh.
  // Editable columns are highlighted; their values are read back before rewriting.
  async writeTab(name, headers, rows, { editable = [], choices = null, emptyRow = null, wideColumns = [] } = {}) {
    const metadata = await this.request("?fields=sheets.properties");
    let sheet = metadata.sheets?.find((s) => s.properties.title === name);
    if (!sheet) {
      const response = await this.request(":batchUpdate", { method: "POST", body: { requests: [{ addSheet: { properties: { title: name, gridProperties: { frozenRowCount: 1 } } } }] } });
      sheet = response.replies[0].addSheet;
      const sheetId = sheet.properties.sheetId;
      await this.request(":batchUpdate", { method: "POST", body: { requests: [
        { repeatCell: { range: { sheetId, startRowIndex: 0, endRowIndex: 1, endColumnIndex: headers.length }, cell: { userEnteredFormat: { backgroundColor: { red: .08, green: .15, blue: .12 }, textFormat: { bold: true, foregroundColor: { red: 1, green: 1, blue: 1 } } } }, fields: "userEnteredFormat" } },
        { updateDimensionProperties: { range: { sheetId, dimension: "COLUMNS", startIndex: 0, endIndex: headers.length }, properties: { pixelSize: 200 }, fields: "pixelSize" } },
        ...wideColumns.map((key) => ({ updateDimensionProperties: { range: { sheetId, dimension: "COLUMNS", startIndex: headers.indexOf(key), endIndex: headers.indexOf(key) + 1 }, properties: { pixelSize: 480 }, fields: "pixelSize" } })),
        ...editable.map((key) => ({ repeatCell: { range: { sheetId, startRowIndex: 1, endRowIndex: 1000, startColumnIndex: headers.indexOf(key), endColumnIndex: headers.indexOf(key) + 1 }, cell: { userEnteredFormat: { backgroundColor: { red: 1, green: .97, blue: .79 } } }, fields: "userEnteredFormat.backgroundColor" } })),
        ...(choices ? [{ setDataValidation: { range: { sheetId, startRowIndex: 1, endRowIndex: 1000, startColumnIndex: 0, endColumnIndex: 1 }, rule: { condition: { type: "ONE_OF_LIST", values: choices.map((userEnteredValue) => ({ userEnteredValue })) }, strict: false, showCustomUi: true } } }] : []),
      ] } });
    }
    await this.request(this.valuesPath(`A1:${last(headers)}1000`, name) + ":clear", { method: "POST", body: {} });
    const values = [headers, ...(rows.length ? rows : emptyRow ? [emptyRow] : []).map((row) => cells(headers, row))];
    await this.request(this.valuesPath(`A1:${last(headers)}${values.length}`, name) + "?valueInputOption=RAW", { method: "PUT", body: { values } });
    return { rows: rows.length };
  }

  async readTab(name) {
    const metadata = await this.request("?fields=sheets.properties");
    if (!metadata.sheets?.some((s) => s.properties.title === name)) return [];
    const result = await this.request(this.valuesPath("A1:AZ1000", name));
    const [headers = [], ...rows] = result.values ?? [];
    return rows.map((row, i) => ({ ...object(headers, row), rowNumber: i + 2 }));
  }

  async syncShotList(rows, headers, name = "Shot List") {
    return this.writeTab(name, headers, rows, { emptyRow: { Status: "Nothing to record for the next 7 days" }, wideColumns: ["What to record"] });
  }

  async syncContent(contents) {
    return this.exclusiveBoardWrite(this.sheetName, () => this.syncContentUnlocked(contents));
  }

  async syncContentUnlocked(contents) {
    const rows = await this.readBoard(this.sheetName, CONTENT_HEADERS);
    const byId = new Map(rows.map((r) => [r["Content ID"], r]));
    const append = [], changes = [];
    for (const content of contents) {
      const old = byId.get(content.id);
      const fresh = !old || Number(old.Revision) !== revision(content) || (content.asset_urls?.[0] ?? "") !== old["Asset 1"];
      const presentation = contentPresentation(content);
      const plan = content.decision?.content ?? {};
      const fields = {
        "Current status": presentation.status, "Reason / next step": presentation.reason,
        Preview: content.thumbnail_url ?? content.asset_urls?.[0] ?? "", Topic: content.topic,
        "Planned date": content.decision?.campaign?.date, "Buffer status": presentation.bufferStatus, "Buffer posts": presentation.bufferPosts,
        "Last activity": content.decision?.workflow?.at ?? content.updated_at, "Content type": content.content_type,
        Caption: plan.caption ?? plan.platform_copy?.instagram_caption, "AI QA score": content.qa?.human_override?.original_score ?? content.qa_score,
        "QA summary": [content.qa?.summary, ...(content.qa?.critical_issues ?? []), ...(content.qa?.required_fixes ?? [])].filter(Boolean).join("\n"), Hook: content.hook, Concept: content.concept, Revision: revision(content),
        "Content key": content.content_key, "Content ID": content.id, "Pipeline state": content.status, "Updated at": content.updated_at,
      };
      for (let i = 0; i < 7; i++) fields[`Asset ${i + 1}`] = content.asset_urls?.[i] ?? "";
      const failed = ["failed", "qa_failed"].includes(content.status);
      const newlyFailed = failed && (fresh || old?.["Pipeline state"] !== content.status);
      if (fresh || newlyFailed) Object.assign(fields, { Decision: failed ? "Needs Review" : "Pending", "Revision instructions": fresh ? "" : old?.["Revision instructions"], "QA score": content.qa_score, "Processed decision fingerprint": "" });
      else if ((String(old["QA score"]) === String(old["AI QA score"]) || old["QA score"] === "")
        && String(old["AI QA score"]) !== String(fields["AI QA score"] ?? "")) fields["QA score"] = content.qa_score;
      if (["scheduled", "published"].includes(content.status)) fields.Decision = "Approve";
      if (old) changes.push({ rowNumber: old.rowNumber, values: fields });
      else append.push(fields);
    }
    await this.writeMany(this.sheetName, CONTENT_HEADERS, changes);
    await this.appendBoard(this.sheetName, CONTENT_HEADERS, append);
    return { updated: changes.length, appended: append.length };
  }

  async syncIdeas(ideas) {
    return this.exclusiveBoardWrite(this.ideaSheetName, () => this.syncIdeasUnlocked(ideas));
  }

  async syncIdeasUnlocked(ideas) {
    const [rows, contentRows] = await Promise.all([
      this.readBoard(this.ideaSheetName, IDEA_HEADERS),
      this.readBoard(this.sheetName, CONTENT_HEADERS),
    ]);
    const byId = new Map(rows.map((r) => [r["Idea ID"], r]));
    const contentRowById = new Map(contentRows.map((r) => [r["Content ID"], r.rowNumber]));
    const changes = [], append = [];
    for (const idea of ideas) {
      const old = byId.get(idea.id), brief = idea.brief ?? {};
      const fresh = !old || Number(old.Version) !== Number(idea.version);
      const req = brief.production_requirements ?? {};
      const reviewRow = contentRowById.get(idea.id);
      const readyForContentReview = idea.status === "Ready in Content Review" && reviewRow;
      const currentStatus = readyForContentReview
        ? `Ready in Content Review - row ${reviewRow}`
        : idea.status === "pending" ? "Pending" : idea.status;
      const defaultReason = idea.production_block_reason || idea.progress_message || (["Scheduled", "Published"].includes(idea.status) ? "Buffer confirmation is in Content Review." : "Approve this idea to start production.");
      const reason = readyForContentReview
        ? [`GENERATION COMPLETE${idea.qa_score == null ? "" : ` - QA ${idea.qa_score}/100`}. ACTION REQUIRED: Open Content Review row ${reviewRow}.`, "Set Decision to Approve to publish the existing asset as-is, or Reject with Revision instructions to regenerate it.", defaultReason ? `QA findings: ${defaultReason}` : ""].filter(Boolean).join("\n")
        : defaultReason;
      const fields = {
        "Current status": currentStatus, "Reason / next step": reason.slice(0, 700),
        Title: brief.title, Description: brief.description, "Content type": idea.content_type,
        "Last activity": idea.progress_at ?? idea.updated_at,
        "Production requirements": [...new Set((req.captures ?? []).filter((r) => r.startsWith("requested:")).map((r) => `${r.slice(10)}.mp4`)), req.upload_folder_url, ...(req.brief ?? [])].filter(Boolean).join("\n"),
        "Generation prompt": brief.generation_prompt, Dialogue: brief.dialogue, Hook: brief.hook,
        "Storyboard / slide outline": brief.storyboard, Caption: brief.caption, CTA: brief.cta, Audience: brief.audience,
        "GymFeed feature": brief.feature, Objective: brief.objective, "Evidence and metrics": brief.evidence,
        "Reasoning and limitations": brief.rationale, Version: idea.version, "Approved version": idea.approved_version,
        "Campaign ID": idea.campaign_id, "Idea ID": idea.id, "Updated at": idea.updated_at,
        "Stored planned date": idea.planned_date,
        "Block kind": idea.production_block_kind || (idea.production_block_reason ? /missing|recording|Drive|too short/i.test(idea.production_block_reason) ? "capture" : "production" : ""),
      };
      if (fresh) Object.assign(fields, { "Idea decision": Number(idea.approved_version) === Number(idea.version) ? "Approve" : "Pending", "Revision instructions": "", "Planned date": old?.["Planned date"] || idea.planned_date, "Processed decision fingerprint": "" });
      if (old) changes.push({ rowNumber: old.rowNumber, values: fields }); else append.push(fields);
    }
    await this.writeMany(this.ideaSheetName, IDEA_HEADERS, changes);
    await this.appendBoard(this.ideaSheetName, IDEA_HEADERS, append);
    return { updated: changes.length, appended: append.length };
  }

  async pendingIdeaDecisions() {
    const rows = await this.readBoard(this.ideaSheetName, IDEA_HEADERS);
    return latestRows(rows, "Idea ID", "Version").flatMap((row) => {
      const entry = { rowNumber: row.rowNumber, ideaId: row["Idea ID"], campaignId: row["Campaign ID"], version: Number(row.Version), decision: decision(row["Idea decision"]), instructions: row["Revision instructions"].trim(), plannedDate: row["Planned date"].trim(), storedPlannedDate: String(row["Stored planned date"] ?? "").trim() };
      entry.fingerprint = fingerprint(entry);
      if (!entry.ideaId || entry.decision === "Pending") return [];
      const blocked = row["Current status"] === "Approved - Blocked" && row["Block kind"] === "capture";
      const explicitProductionRetry = row["Block kind"] === "production" && !row["Processed decision fingerprint"];
      const finishedOrActive = ["Needs Review", "Repairing", "Scheduled", "Published", "Generating"]
        .includes(row["Current status"])
        || String(row["Current status"]).startsWith("Ready in Content Review");
      if (entry.decision === "Approve" && Number(row["Approved version"]) === entry.version
        && entry.plannedDate === row["Stored planned date"]
        && finishedOrActive
        && !explicitProductionRetry) return [];
      if (entry.fingerprint === row["Processed decision fingerprint"] && !blocked) return [];
      return [entry];
    });
  }

  async pendingDecisions() {
    const rows = await this.readBoard(this.sheetName, CONTENT_HEADERS);
    return latestRows(rows, "Content ID", "Revision").flatMap((row) => {
      const score = Number(row["QA score"]), aiScore = Number(row["AI QA score"]);
      const qaOverride = row["QA score"] !== "" && Number.isFinite(score) && score >= 85 && score <= 100 && score !== aiScore ? score : undefined;
      const entry = {
        rowNumber: row.rowNumber, contentId: row["Content ID"], contentType: row["Content type"], revision: Number(row.Revision),
        decision: decision(row.Decision), instructions: row["Revision instructions"].trim(),
        currentStatus: row["Pipeline state"], contentUpdatedAt: row["Updated at"], processingResult: row["Processing result"], qaOverride,
      };
      if (qaOverride != null && entry.decision !== "Reject") entry.decision = "Approve";
      entry.fingerprint = fingerprint(entry);
      const explicitRetry = decision(row.Decision) === "Approve" && /Blocked|Needs Review|ERROR/i.test(row["Processing result"] ?? "");
      if (!entry.contentId || entry.decision === "Pending" || entry.fingerprint === row["Processed decision fingerprint"] && !explicitRetry) return [];
      if (["scheduled", "published"].includes(entry.currentStatus)) return [];
      return [entry];
    });
  }

  async ideaApprovalForContent(contentId) {
    const rows = await this.readBoard(this.ideaSheetName, IDEA_HEADERS);
    const row = latestRows(rows, "Idea ID", "Version").find((candidate) => candidate["Idea ID"] === contentId);
    if (!row) throw new Error("The blocked item has no Idea Review row");
    const entry = { rowNumber: row.rowNumber, ideaId: contentId, campaignId: row["Campaign ID"], version: Number(row.Version), decision: "Approve", instructions: row["Revision instructions"].trim(), plannedDate: row["Planned date"].trim(), storedPlannedDate: String(row["Stored planned date"] ?? "").trim() };
    return { ...entry, fingerprint: fingerprint(entry) };
  }

  async markContentGenerationRetry(entry, result, processedAt = new Date().toISOString()) {
    const rows = await this.readBoard(this.sheetName, CONTENT_HEADERS);
    const row = latestRows(rows, "Content ID", "Revision").find((candidate) => candidate["Content ID"] === entry.contentId);
    if (!row || Number(row.Revision) !== entry.revision || decision(row.Decision) !== "Approve"
      || row["Revision instructions"].trim() !== (entry.instructions ?? "").trim()) return { marked: false };
    // This approval starts unfinished media; it is not approval to publish its replacement.
    await this.writeFields(this.sheetName, CONTENT_HEADERS, row.rowNumber, {
      Decision: "Pending", "Current status": "Pending", "Reason / next step": result,
      "Processing result": result, "Processed at": processedAt, "Last activity": processedAt,
      "Processed decision fingerprint": "",
    });
    return { marked: true };
  }

  async markIdeaDecision(entry, result, processedAt = new Date().toISOString()) {
    const rows = await this.readBoard(this.ideaSheetName, IDEA_HEADERS);
    const row = latestRows(rows, "Idea ID", "Version").find((r) => r["Idea ID"] === entry.ideaId);
    if (!row || Number(row.Version) !== entry.version) return { marked: false };
    const current = { ...entry, decision: decision(row["Idea decision"]), instructions: row["Revision instructions"].trim(), plannedDate: row["Planned date"].trim() };
    if (fingerprint(current) !== fingerprint(entry)) return { marked: false };
    await this.writeFields(this.ideaSheetName, IDEA_HEADERS, row.rowNumber, { "Processing result": result, "Processed at": processedAt, "Reason / next step": result, "Last activity": processedAt, "Processed decision fingerprint": fingerprint(entry) });
    return { marked: true };
  }

  async markInterruptedIdea(contentId, result, processedAt = new Date().toISOString()) {
    const rows = await this.readBoard(this.ideaSheetName, IDEA_HEADERS);
    const row = latestRows(rows, "Idea ID", "Version").find((candidate) => candidate["Idea ID"] === contentId);
    if (!row) return { marked: false };
    await this.writeFields(this.ideaSheetName, IDEA_HEADERS, row.rowNumber, {
      "Idea decision": "Pending",
      "Current status": "Pending",
      "Reason / next step": result,
      "Processing result": result,
      "Processed at": processedAt,
      "Last activity": processedAt,
      "Processed decision fingerprint": "",
    });
    return { marked: true };
  }

  async markIdeaRetryRequired(entry, result, processedAt = new Date().toISOString()) {
    const rows = await this.readBoard(this.ideaSheetName, IDEA_HEADERS);
    const row = latestRows(rows, "Idea ID", "Version").find((candidate) => candidate["Idea ID"] === entry.ideaId);
    if (!row || Number(row.Version) !== entry.version) return { marked: false };
    await this.writeFields(this.ideaSheetName, IDEA_HEADERS, row.rowNumber, {
      "Idea decision": "Pending",
      "Current status": "Retry Required",
      "Reason / next step": result,
      "Processing result": result,
      "Processed at": processedAt,
      "Last activity": processedAt,
      "Processed decision fingerprint": "",
      "Block kind": "production",
    });
    return { marked: true };
  }

  async markContentDecision(entry, result, processedAt = new Date().toISOString()) {
    const rows = await this.readBoard(this.sheetName, CONTENT_HEADERS);
    const row = latestRows(rows, "Content ID", "Revision").find((r) => r["Content ID"] === entry.contentId);
    if (!row || Number(row.Revision) !== entry.revision) return { marked: false };
    if (row["Revision instructions"].trim() !== (entry.instructions ?? "").trim()) return { marked: false };
    await this.writeFields(this.sheetName, CONTENT_HEADERS, row.rowNumber, { "Processing result": result, "Processed at": processedAt, "Reason / next step": result, "Last activity": processedAt, "Processed decision fingerprint": entry.fingerprint || fingerprint(entry), ...(/Blocked|Needs Review|ERROR/i.test(result) ? { Decision: "Needs Review" } : {}) });
    return { marked: true };
  }
}
