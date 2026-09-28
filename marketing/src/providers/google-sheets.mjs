import { GoogleAuth } from "google-auth-library";
import { createHash } from "node:crypto";

const LEGACY_IDEA_REVIEW_HEADERS = [
  "Idea decision", "Revision instructions", "Campaign ID", "Planned date", "Content type",
  "Version", "Current status", "Title", "Hook", "Audience", "GymFeed feature", "Objective",
  "Description", "Storyboard / slide outline", "Dialogue", "Caption", "CTA", "Evidence and metrics",
  "Reasoning and limitations", "Production requirements", "Approved version", "Processing result",
  "Processed at", "Idea ID", "Updated at", "Processed decision fingerprint",
];
export const IDEA_REVIEW_HEADERS = [
  ...LEGACY_IDEA_REVIEW_HEADERS.slice(0, 13),
  "Generation prompt",
  ...LEGACY_IDEA_REVIEW_HEADERS.slice(13),
];
const IDEA_COLUMN = Object.fromEntries(IDEA_REVIEW_HEADERS.map((name, index) => [name, index]));

function cellText(value) {
  if (value === undefined || value === null) return "";
  const text = typeof value === "string" ? value : JSON.stringify(value, null, 2);
  return text.length > 48000 ? `${text.slice(0, 48000)}\n[Display truncated; see the stored idea brief.]` : text;
}

function productionRequirementsText(requirements) {
  if (!requirements || typeof requirements !== "object" || Array.isArray(requirements)) {
    return cellText(requirements);
  }

  const requested = [];
  const addRequested = (value) => {
    const text = String(value ?? "").trim();
    if (text && !requested.includes(text)) requested.push(text);
  };
  const brief = Array.isArray(requirements.brief) ? requirements.brief : [];
  const assets = Array.isArray(requirements.assets) ? requirements.assets : [];
  brief.forEach(addRequested);
  assets.forEach(addRequested);
  for (const ref of requirements.captures ?? []) {
    if (String(ref).startsWith("requested:")) {
      const filename = `${String(ref).slice("requested:".length)}.mp4`;
      addRequested(`Required video recording: ${ref}`);
      addRequested(`UPLOAD WITH THIS EXACT FILE NAME: ${filename}`);
    }
  }

  const availableCaptures = (requirements.captures ?? []).filter((ref) => !String(ref).startsWith("requested:"));
  const screenshots = requirements.screenshots ?? [];
  const lines = requested.length
    ? ["ACTION REQUIRED FROM YOU BEFORE GENERATION", ...requested.map((item) => `- ${item}`), "", "STATUS: Generation is blocked until the required files are supplied and verified."]
    : ["NO NEW FILE REQUIRED FROM YOU", "The currently listed production assets are available."];

  if (requirements.upload_folder_url) {
    lines.push("", "UPLOAD THE REQUIRED FILE HERE", requirements.upload_folder_url);
  }

  if (availableCaptures.length || screenshots.length) {
    lines.push("", "ALREADY AVAILABLE");
    availableCaptures.forEach((ref) => lines.push(`- App recording: ${ref}`));
    screenshots.forEach((ref) => lines.push(`- GymFeed image: ${ref}`));
  }
  if (requirements.estimated_video_cost_usd_per_attempt != null) {
    lines.push("", `Estimated generated-video cost per attempt: $${requirements.estimated_video_cost_usd_per_attempt}`);
  }
  if (requirements.cost_note) lines.push(requirements.cost_note);
  return cellText(lines.join("\n"));
}

function ideaFingerprint(entry) {
  return createHash("sha256").update(JSON.stringify([
    entry.ideaId, Number(entry.version), normalizedDecision(entry.decision), String(entry.instructions ?? "").trim(),
    String(entry.plannedDate ?? "").trim(),
  ])).digest("hex");
}

function latestRowsById(rows, idColumn, versionColumn) {
  const latest = new Map();
  rows.forEach((row, index) => {
    const id = row[idColumn];
    if (!id) return;
    const version = Number(row[versionColumn] || 1);
    if (!latest.has(id) || latest.get(id).version <= version) latest.set(id, { row, version, rowNumber: index + 2 });
  });
  return latest;
}

function ideaRow(idea) {
  const brief = idea.brief ?? {};
  const approved = ["approved", "approved - blocked"].includes(String(idea.status ?? "").toLowerCase())
    && Number(idea.approved_version) === Number(idea.version);
  const processingResult = idea.production_block_reason
    ? `Approved - Blocked: ${idea.production_block_reason}`
    : Number(idea.version) > 1 && String(idea.instructions ?? "").trim()
    ? approved
      ? `Rejected version ${Number(idea.version) - 1}: ${String(idea.instructions).trim()}\nRevised version ${idea.version} is approved for replacement production.`
      : `Rejected version ${Number(idea.version) - 1}: ${String(idea.instructions).trim()}\nRevised version ${idea.version} is pending approval.`
    : "New idea version; approve this idea before production";
  return [
    approved ? "Approve" : "Pending", "", idea.campaign_id, idea.planned_date ?? "", idea.content_type,
    idea.version, idea.status, brief.title ?? "", brief.hook ?? "", cellText(brief.audience),
    cellText(brief.feature), cellText(brief.objective), cellText(brief.description), cellText(brief.generation_prompt), cellText(brief.storyboard),
    cellText(brief.dialogue), cellText(brief.caption), cellText(brief.cta), cellText(brief.evidence),
    cellText(brief.rationale), productionRequirementsText(brief.production_requirements), idea.approved_version ?? "",
    processingResult, "", idea.id, idea.updated_at ?? "", "",
  ];
}

export const APPROVAL_SHEET_HEADERS = [
  "Video decision",
  "Video instructions",
  "Carousel decision",
  "Carousel instructions",
  "Preview",
  "Asset 1",
  "Asset 2",
  "Asset 3",
  "Asset 4",
  "Asset 5",
  "Asset 6",
  "Asset 7",
  "Content key",
  "Content type",
  "Current status",
  "Revision",
  "Topic",
  "Hook",
  "Concept",
  "Caption",
  "QA score",
  "QA summary",
  "Processing result",
  "Processed at",
  "Content ID",
  "Updated at",
];

const LEGACY_APPROVAL_SHEET_HEADERS = [
  "Decision",
  "Revision instructions",
  "Preview",
  "Asset 1",
  "Asset 2",
  "Asset 3",
  "Asset 4",
  "Asset 5",
  "Asset 6",
  "Asset 7",
  "Content key",
  "Content type",
  "Current status",
  "Revision",
  "Topic",
  "Hook",
  "Concept",
  "Caption",
  "QA score",
  "QA summary",
  "Processing result",
  "Processed at",
  "Content ID",
  "Updated at",
];

const COLUMN = Object.fromEntries(APPROVAL_SHEET_HEADERS.map((name, index) => [name, index]));
const LEGACY_COLUMN = Object.fromEntries(LEGACY_APPROVAL_SHEET_HEADERS.map((name, index) => [name, index]));
const LAST_COLUMN = "Z";
const LEGACY_LAST_COLUMN = "X";
const IDEA_LAST_COLUMN = "AA";

function normalizedDecision(value) {
  const text = String(value ?? "").trim().toLowerCase();
  if (text === "approve") return "Approve";
  if (text === "reject") return "Reject";
  return "Pending";
}

function captionFor(content) {
  const plan = content.decision?.content ?? {};
  return plan.caption ?? plan.platform_copy?.instagram_caption ?? "";
}

function reviewRevision(content) {
  return Number(content.decision?.review_revision ?? 1);
}

function reviewKind(contentType) {
  const normalized = String(contentType ?? "").trim().toLowerCase();
  return ["video", "reel", "short", "fitclip"].some((token) => normalized.includes(token))
    ? "video"
    : "carousel";
}

function reviewFields(contentType) {
  return reviewKind(contentType) === "video"
    ? { decision: "Video decision", instructions: "Video instructions" }
    : { decision: "Carousel decision", instructions: "Carousel instructions" };
}

function migrateLegacyRow(row) {
  const contentType = row[LEGACY_COLUMN["Content type"]];
  const decision = normalizedDecision(row[LEGACY_COLUMN.Decision]);
  const instructions = row[LEGACY_COLUMN["Revision instructions"]] ?? "";
  const video = reviewKind(contentType) === "video";
  return [
    video ? decision : "",
    video ? instructions : "",
    video ? "" : decision,
    video ? "" : instructions,
    ...row.slice(LEGACY_COLUMN.Preview, LEGACY_APPROVAL_SHEET_HEADERS.length),
  ];
}

function rowForContent(content, existing = null, { freshReview = false } = {}) {
  const assets = [...(content.asset_urls ?? [])].slice(0, 7);
  while (assets.length < 7) assets.push("");
  const revision = reviewRevision(content);
  const sameRevision = existing && Number(existing[COLUMN.Revision] ?? 1) === revision;
  const previousRevision = existing ? Number(existing[COLUMN.Revision] || 1) : null;
  const fields = reviewFields(content.content_type);
  const needsRevisionDecision = ["failed", "qa_failed"].includes(content.status);
  const decision = sameRevision && !freshReview ? normalizedDecision(existing[COLUMN[fields.decision]]) : "Pending";
  const instructions = sameRevision && !freshReview ? (existing[COLUMN[fields.instructions]] ?? "") : "";
  const processingResult = needsRevisionDecision
    ? `ERROR: ${content.failure_reason ?? "Content failed quality review"}`
    : freshReview
      ? "New media is ready for review; the previous decision was cleared"
    : previousRevision != null && previousRevision !== revision
      ? `Rejected revision ${previousRevision}; replacement revision ${revision} is ready for review`
      : "New revision ready for review";
  const video = reviewKind(content.content_type) === "video";
  return [
    video ? decision : "",
    video ? instructions : "",
    video ? "" : decision,
    video ? "" : instructions,
    content.thumbnail_url ?? content.asset_urls?.[0] ?? "",
    ...assets,
    content.content_key,
    content.content_type,
    content.status,
    revision,
    content.topic,
    content.hook,
    content.concept,
    captionFor(content),
    content.qa_score ?? "",
    content.qa?.summary ?? content.failure_reason ?? "",
    needsRevisionDecision || freshReview ? processingResult : (sameRevision ? (existing[COLUMN["Processing result"]] ?? "") : processingResult),
    needsRevisionDecision || freshReview ? "" : (sameRevision ? (existing[COLUMN["Processed at"]] ?? "") : ""),
    content.id,
    content.updated_at ?? "",
  ];
}

export class GoogleSheetsApprovalQueue {
  constructor({ spreadsheetId, sheetName = "Content Review", ideaSheetName = "Idea Review", credentialsPath, auth, fetchImpl = fetch } = {}) {
    this.spreadsheetId = spreadsheetId;
    this.sheetName = sheetName;
    this.ideaSheetName = ideaSheetName;
    if (sheetName === ideaSheetName) throw new Error("Idea Review must use a separate tab from Content Review");
    this.fetchImpl = fetchImpl;
    this.auth = auth ?? (spreadsheetId ? new GoogleAuth({
      ...(credentialsPath ? { keyFile: credentialsPath } : {}),
      scopes: ["https://www.googleapis.com/auth/spreadsheets"],
    }) : null);
  }

  get configured() {
    return Boolean(this.spreadsheetId && this.auth);
  }

  ensureConfigured() {
    if (!this.configured) throw new Error("Google Sheets approval queue is not configured");
  }

  async request(path, { method = "GET", body } = {}) {
    this.ensureConfigured();
    const client = await this.auth.getClient();
    const authHeaders = await client.getRequestHeaders();
    const requestHeaders = typeof authHeaders?.entries === "function"
      ? Object.fromEntries(authHeaders.entries())
      : authHeaders;
    const response = await this.fetchImpl(`https://sheets.googleapis.com/v4/spreadsheets/${this.spreadsheetId}${path}`, {
      method,
      headers: {
        ...requestHeaders,
        ...(body === undefined ? {} : { "content-type": "application/json" }),
      },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(`Google Sheets ${method} ${path}: ${payload.error?.message ?? response.status}`);
    return payload;
  }

  valuesPath(range, sheetName = this.sheetName) {
    return `/values/${encodeURIComponent(`'${sheetName.replaceAll("'", "''")}'!${range}`)}`;
  }

  async updateRange(range, values, sheetName = this.sheetName) {
    return this.request(`${this.valuesPath(range, sheetName)}?valueInputOption=RAW`, {
      method: "PUT",
      body: { range: `'${sheetName.replaceAll("'", "''")}'!${range}`, majorDimension: "ROWS", values },
    });
  }

  async updateRanges(updates, sheetName = this.sheetName) {
    if (!updates.length) return null;
    const escapedSheet = sheetName.replaceAll("'", "''");
    return this.request("/values:batchUpdate", {
      method: "POST",
      body: {
        valueInputOption: "RAW",
        data: updates.map(({ range, values }) => ({
          range: `'${escapedSheet}'!${range}`,
          majorDimension: "ROWS",
          values,
        })),
      },
    });
  }

  async appendRows(values, sheetName = this.sheetName) {
    if (!values.length) return null;
    const lastColumn = sheetName === this.ideaSheetName ? IDEA_LAST_COLUMN : LAST_COLUMN;
    return this.request(`${this.valuesPath(`A:${lastColumn}`, sheetName)}:append?valueInputOption=RAW&insertDataOption=INSERT_ROWS`, {
      method: "POST",
      body: { majorDimension: "ROWS", values },
    });
  }

  async ensureSheet() {
    const metadata = await this.request("?fields=sheets.properties");
    let sheet = metadata.sheets?.find((item) => item.properties?.title === this.sheetName);
    if (!sheet) {
      const created = await this.request(":batchUpdate", {
        method: "POST",
        body: { requests: [{ addSheet: { properties: { title: this.sheetName } } }] },
      });
      sheet = created.replies?.[0]?.addSheet;
    }
    const sheetId = sheet.properties?.sheetId;
    const headerResult = await this.request(this.valuesPath(`A1:${LAST_COLUMN}1`));
    const currentHeaders = headerResult.values?.[0] ?? [];
    const needsInitialization = APPROVAL_SHEET_HEADERS.some((header, index) => currentHeaders[index] !== header);
    if (!needsInitialization) return sheetId;

    const hasLegacyHeaders = LEGACY_APPROVAL_SHEET_HEADERS.every((header, index) => currentHeaders[index] === header);
    if (!hasLegacyHeaders && currentHeaders.some((value) => value !== "")) {
      throw new Error(`Refusing to overwrite unfamiliar columns in ${this.sheetName}`);
    }
    if (hasLegacyHeaders) {
      const legacyRows = await this.request(this.valuesPath(`A2:${LEGACY_LAST_COLUMN}1000`));
      const migratedRows = (legacyRows.values ?? []).map(migrateLegacyRow);
      if (migratedRows.length) {
        await this.updateRange(`A2:${LAST_COLUMN}${migratedRows.length + 1}`, migratedRows);
      }
    }

    await this.updateRange(`A1:${LAST_COLUMN}1`, [APPROVAL_SHEET_HEADERS]);
    await this.request(":batchUpdate", {
      method: "POST",
      body: {
        requests: [
          {
            updateSheetProperties: {
              properties: { sheetId, gridProperties: { frozenRowCount: 1, frozenColumnCount: 4 } },
              fields: "gridProperties.frozenRowCount,gridProperties.frozenColumnCount",
            },
          },
          {
            repeatCell: {
              range: { sheetId, startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: APPROVAL_SHEET_HEADERS.length },
              cell: {
                userEnteredFormat: {
                  backgroundColor: { red: 0.05, green: 0.08, blue: 0.07 },
                  textFormat: { foregroundColor: { red: 1, green: 1, blue: 1 }, bold: true },
                  horizontalAlignment: "CENTER",
                  verticalAlignment: "MIDDLE",
                  wrapStrategy: "WRAP",
                },
              },
              fields: "userEnteredFormat",
            },
          },
          {
            repeatCell: {
              range: { sheetId, startRowIndex: 1, endRowIndex: 1000, startColumnIndex: 0, endColumnIndex: 2 },
              cell: { userEnteredFormat: { backgroundColor: { red: 1, green: 0.96, blue: 0.76 }, verticalAlignment: "MIDDLE", wrapStrategy: "WRAP" } },
              fields: "userEnteredFormat",
            },
          },
          {
            repeatCell: {
              range: { sheetId, startRowIndex: 1, endRowIndex: 1000, startColumnIndex: 2, endColumnIndex: 4 },
              cell: { userEnteredFormat: { backgroundColor: { red: 0.87, green: 0.94, blue: 1 }, verticalAlignment: "MIDDLE", wrapStrategy: "WRAP" } },
              fields: "userEnteredFormat",
            },
          },
          {
            setDataValidation: {
              range: { sheetId, startRowIndex: 1, endRowIndex: 1000, startColumnIndex: 0, endColumnIndex: 1 },
              rule: {
                condition: { type: "ONE_OF_LIST", values: ["Pending", "Approve", "Reject"].map((userEnteredValue) => ({ userEnteredValue })) },
                strict: true,
                showCustomUi: true,
              },
            },
          },
          {
            setDataValidation: {
              range: { sheetId, startRowIndex: 1, endRowIndex: 1000, startColumnIndex: 2, endColumnIndex: 3 },
              rule: {
                condition: { type: "ONE_OF_LIST", values: ["Pending", "Approve", "Reject"].map((userEnteredValue) => ({ userEnteredValue })) },
                strict: true,
                showCustomUi: true,
              },
            },
          },
          {
            autoResizeDimensions: {
              dimensions: { sheetId, dimension: "COLUMNS", startIndex: 0, endIndex: APPROVAL_SHEET_HEADERS.length },
            },
          },
        ],
      },
    });
    return sheetId;
  }

  async readRows() {
    await this.ensureSheet();
    const result = await this.request(this.valuesPath(`A2:${LAST_COLUMN}`));
    return result.values ?? [];
  }

  async syncContent(contents) {
    const rows = await this.readRows();
    const byContent = latestRowsById(rows, COLUMN["Content ID"], COLUMN.Revision);

    const append = [];
    const updates = [];
    let updated = 0;
    for (const content of contents) {
      const existing = byContent.get(content.id);
      let next = rowForContent(content, existing?.row);
      if (existing?.rowNumber) {
        const sameRevision = existing.version === reviewRevision(content);
        const mediaChanged = next.slice(COLUMN.Preview, COLUMN["Content key"])
          .some((value, index) => String(value ?? "") !== String(existing.row[COLUMN.Preview + index] ?? ""));
        const becameReviewable = content.status === "awaiting_approval"
          && existing.row[COLUMN["Current status"]] !== "awaiting_approval";
        const freshReview = sameRevision && content.status === "awaiting_approval" && (mediaChanged || becameReviewable);
        if (freshReview) next = rowForContent(content, existing.row, { freshReview: true });
        if (sameRevision && !freshReview) {
          // A:D belong to the reviewer; W:X belong to the decision dispatcher.
          updates.push({ range: `E${existing.rowNumber}:V${existing.rowNumber}`, values: [next.slice(4, 22)] });
          updates.push({ range: `Y${existing.rowNumber}:Z${existing.rowNumber}`, values: [next.slice(24)] });
        } else {
          // New media remains on the stable row, but always requires a fresh review.
          updates.push({ range: `A${existing.rowNumber}:Z${existing.rowNumber}`, values: [next] });
        }
        updated += 1;
      } else if (!existing) {
        append.push(next);
        byContent.set(content.id, { row: next, version: reviewRevision(content) });
      }
    }
    await this.updateRanges(updates);
    await this.appendRows(append);
    return { updated, appended: append.length };
  }

  async pendingDecisions() {
    const rows = await this.readRows();
    const latest = latestRowsById(rows, COLUMN["Content ID"], COLUMN.Revision);
    return rows.flatMap((row, index) => {
      const contentType = row[COLUMN["Content type"]];
      const fields = reviewFields(contentType);
      const decision = normalizedDecision(row[COLUMN[fields.decision]]);
      const contentId = row[COLUMN["Content ID"]];
      if (!contentId || decision === "Pending" || latest.get(contentId)?.rowNumber !== index + 2) return [];
      return [{
        rowNumber: index + 2,
        contentId,
        contentType,
        revision: Number(row[COLUMN.Revision] ?? 1),
        decision,
        instructions: String(row[COLUMN[fields.instructions]] ?? "").trim(),
        currentStatus: String(row[COLUMN["Current status"]] ?? ""),
        contentUpdatedAt: String(row[COLUMN["Updated at"]] ?? ""),
        processingResult: String(row[COLUMN["Processing result"]] ?? ""),
      }];
    });
  }

  async setProcessingResult(rowNumber, result, processedAt = new Date().toISOString()) {
    return this.updateRange(`W${rowNumber}:X${rowNumber}`, [[result, processedAt]]);
  }

  async markContentDecision(entry, result, processedAt = new Date().toISOString()) {
    const rows = await this.readRows();
    const latest = latestRowsById(rows, COLUMN["Content ID"], COLUMN.Revision).get(entry.contentId);
    if (!latest || latest.rowNumber !== entry.rowNumber || latest.version !== entry.revision) return { marked: false, reason: "Row or revision moved" };
    const type = latest.row[COLUMN["Content type"]];
    const fields = reviewFields(type);
    const decisionColumn = COLUMN[fields.decision];
    const instructionsColumn = COLUMN[fields.instructions];
    if (normalizedDecision(latest.row[decisionColumn]) !== entry.decision || String(latest.row[instructionsColumn] ?? "").trim() !== entry.instructions) return { marked: false, reason: "Reviewer input changed" };
    await this.setProcessingResult(entry.rowNumber, result, processedAt);
    return { marked: true };
  }

  async ensureIdeaSheet() {
    const metadata = await this.request("?fields=sheets.properties");
    let sheet = metadata.sheets?.find((item) => item.properties?.title === this.ideaSheetName);
    if (!sheet) {
      const created = await this.request(":batchUpdate", {
        method: "POST", body: { requests: [{ addSheet: { properties: { title: this.ideaSheetName } } }] },
      });
      sheet = created.replies?.[0]?.addSheet;
    }
    const sheetId = sheet.properties?.sheetId;
    const headerResult = await this.request(this.valuesPath(`A1:${IDEA_LAST_COLUMN}1`, this.ideaSheetName));
    const headers = headerResult.values?.[0] ?? [];
    if (IDEA_REVIEW_HEADERS.every((header, index) => headers[index] === header)) return sheetId;
    const hasLegacyHeaders = LEGACY_IDEA_REVIEW_HEADERS.every((header, index) => headers[index] === header);
    if (!hasLegacyHeaders && headers.some((value) => value !== "")) throw new Error(`Refusing to overwrite unfamiliar columns in ${this.ideaSheetName}`);
    const columnCount = Number(sheet.properties?.gridProperties?.columnCount ?? 0);
    if (columnCount < IDEA_REVIEW_HEADERS.length) {
      await this.request(":batchUpdate", {
        method: "POST",
        body: { requests: [{ appendDimension: { sheetId, dimension: "COLUMNS", length: IDEA_REVIEW_HEADERS.length - columnCount } }] },
      });
    }
    if (hasLegacyHeaders) {
      const legacyRows = await this.request(this.valuesPath("A2:Z1000", this.ideaSheetName));
      const migratedRows = (legacyRows.values ?? []).map((row) => [...row.slice(0, 13), "", ...row.slice(13)]);
      if (migratedRows.length) await this.updateRange(`A2:${IDEA_LAST_COLUMN}${migratedRows.length + 1}`, migratedRows, this.ideaSheetName);
    }
    await this.updateRange(`A1:${IDEA_LAST_COLUMN}1`, [IDEA_REVIEW_HEADERS], this.ideaSheetName);
    await this.request(":batchUpdate", {
      method: "POST",
      body: { requests: [
        { updateSheetProperties: {
          properties: { sheetId, gridProperties: { frozenRowCount: 1, frozenColumnCount: 2 } },
          fields: "gridProperties.frozenRowCount,gridProperties.frozenColumnCount",
        } },
        { repeatCell: {
          range: { sheetId, startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: IDEA_REVIEW_HEADERS.length },
          cell: { userEnteredFormat: {
            backgroundColor: { red: 0.05, green: 0.08, blue: 0.07 },
            textFormat: { foregroundColor: { red: 1, green: 1, blue: 1 }, bold: true }, wrapStrategy: "WRAP",
          } }, fields: "userEnteredFormat",
        } },
        { repeatCell: {
          range: { sheetId, startRowIndex: 1, endRowIndex: 1000, startColumnIndex: 0, endColumnIndex: 2 },
          cell: { userEnteredFormat: { backgroundColor: { red: 1, green: 0.96, blue: 0.76 }, wrapStrategy: "WRAP" } },
          fields: "userEnteredFormat",
        } },
        { setDataValidation: {
          range: { sheetId, startRowIndex: 1, endRowIndex: 1000, startColumnIndex: 0, endColumnIndex: 1 },
          rule: {
            condition: { type: "ONE_OF_LIST", values: ["Pending", "Approve", "Reject"].map((userEnteredValue) => ({ userEnteredValue })) },
            strict: true, showCustomUi: true,
          },
        } },
        { updateDimensionProperties: {
          range: { sheetId, dimension: "COLUMNS", startIndex: 0, endIndex: IDEA_REVIEW_HEADERS.length },
          properties: { pixelSize: 220 }, fields: "pixelSize",
        } },
        { updateDimensionProperties: {
          range: { sheetId, dimension: "COLUMNS", startIndex: IDEA_COLUMN["Production requirements"], endIndex: IDEA_COLUMN["Production requirements"] + 1 },
          properties: { pixelSize: 420 }, fields: "pixelSize",
        } },
        { updateDimensionProperties: {
          range: { sheetId, dimension: "COLUMNS", startIndex: IDEA_COLUMN["Generation prompt"], endIndex: IDEA_COLUMN["Generation prompt"] + 1 },
          properties: { pixelSize: 520 }, fields: "pixelSize",
        } },
        { repeatCell: {
          range: { sheetId, startRowIndex: 1, endRowIndex: 1000, startColumnIndex: IDEA_COLUMN["Production requirements"], endColumnIndex: IDEA_COLUMN["Production requirements"] + 1 },
          cell: { userEnteredFormat: { backgroundColor: { red: 1, green: 0.96, blue: 0.76 }, verticalAlignment: "TOP", wrapStrategy: "WRAP" } },
          fields: "userEnteredFormat",
        } },
        { repeatCell: {
          range: { sheetId, startRowIndex: 1, endRowIndex: 1000, startColumnIndex: IDEA_COLUMN["Generation prompt"], endColumnIndex: IDEA_COLUMN["Generation prompt"] + 1 },
          cell: { userEnteredFormat: { verticalAlignment: "TOP", wrapStrategy: "WRAP" } },
          fields: "userEnteredFormat.verticalAlignment,userEnteredFormat.wrapStrategy",
        } },
        { updateDimensionProperties: {
          range: { sheetId, dimension: "COLUMNS", startIndex: IDEA_COLUMN["Updated at"], endIndex: IDEA_COLUMN["Updated at"] + 1 },
          properties: { hiddenByUser: false }, fields: "hiddenByUser",
        } },
        { updateDimensionProperties: {
          range: { sheetId, dimension: "COLUMNS", startIndex: IDEA_COLUMN["Processed decision fingerprint"], endIndex: IDEA_COLUMN["Processed decision fingerprint"] + 1 },
          properties: { hiddenByUser: true }, fields: "hiddenByUser",
        } },
      ] },
    });
    return sheetId;
  }

  async readIdeaRows() {
    await this.ensureIdeaSheet();
    const result = await this.request(this.valuesPath(`A2:${IDEA_LAST_COLUMN}`, this.ideaSheetName));
    return result.values ?? [];
  }

  async syncIdeas(ideas) {
    const rows = await this.readIdeaRows();
    const byIdea = latestRowsById(rows, IDEA_COLUMN["Idea ID"], IDEA_COLUMN.Version);
    const append = [];
    const updates = [];
    let updated = 0;
    for (const idea of ideas) {
      if (!idea.id || !idea.campaign_id || !Number.isInteger(Number(idea.version)) || Number(idea.version) < 1) {
        throw new Error("Each idea requires a stable id, campaign_id, and positive integer version");
      }
      const existing = byIdea.get(idea.id);
      const next = ideaRow(idea);
      if (existing?.rowNumber) {
        const rowNumber = existing.rowNumber;
        if (existing.version === Number(idea.version)) {
          // A:B and Planned date (D) are human-owned; W:X and AA are dispatcher-owned acknowledgments.
          updates.push({ range: `C${rowNumber}:C${rowNumber}`, values: [next.slice(2, 3)] });
          updates.push({ range: `E${rowNumber}:V${rowNumber}`, values: [next.slice(4, 22)] });
          updates.push({ range: `Y${rowNumber}:Z${rowNumber}`, values: [next.slice(24, 26)] });
        } else {
          next[IDEA_COLUMN["Planned date"]] = existing.row[IDEA_COLUMN["Planned date"]] || next[IDEA_COLUMN["Planned date"]];
          updates.push({ range: `A${rowNumber}:${IDEA_LAST_COLUMN}${rowNumber}`, values: [next] });
        }
        updated += 1;
      } else if (!existing) {
        append.push(next);
        byIdea.set(idea.id, { row: next, version: Number(idea.version) });
      }
    }
    await this.updateRanges(updates, this.ideaSheetName);
    await this.appendRows(append, this.ideaSheetName);
    return { updated, appended: append.length };
  }

  async pendingIdeaDecisions() {
    const rows = await this.readIdeaRows();
    const latest = latestRowsById(rows, IDEA_COLUMN["Idea ID"], IDEA_COLUMN.Version);
    return [...latest.values()].flatMap(({ row, rowNumber, version }) => {
      const decision = normalizedDecision(row[IDEA_COLUMN["Idea decision"]]);
      const currentStatus = String(row[IDEA_COLUMN["Current status"]] ?? "").toLowerCase();
      if (decision === "Pending" || !Number.isInteger(version) || version < 1) return [];
      if (decision === "Approve" && currentStatus === "approved"
        && Number(row[IDEA_COLUMN["Approved version"]]) === version) return [];
      const entry = {
        rowNumber, ideaId: row[IDEA_COLUMN["Idea ID"]], campaignId: row[IDEA_COLUMN["Campaign ID"]],
        version, decision, instructions: String(row[IDEA_COLUMN["Revision instructions"]] ?? "").trim(),
        plannedDate: String(row[IDEA_COLUMN["Planned date"]] ?? "").trim(),
      };
      entry.fingerprint = ideaFingerprint(entry);
      if (entry.fingerprint === row[IDEA_COLUMN["Processed decision fingerprint"]]
        && currentStatus !== "approved - blocked") return [];
      return [entry];
    });
  }

  async markIdeaDecision(entry, result, processedAt = new Date().toISOString()) {
    const rows = await this.readIdeaRows();
    const latest = latestRowsById(rows, IDEA_COLUMN["Idea ID"], IDEA_COLUMN.Version).get(entry.ideaId);
    if (!latest || latest.rowNumber !== entry.rowNumber || latest.version !== Number(entry.version)
      || latest.row[IDEA_COLUMN["Campaign ID"]] !== entry.campaignId) {
      return { marked: false, reason: "Idea row or version changed; acknowledgment was not written" };
    }
    const current = {
      ideaId: entry.ideaId, version: latest.version,
      decision: latest.row[IDEA_COLUMN["Idea decision"]],
      instructions: latest.row[IDEA_COLUMN["Revision instructions"]],
      plannedDate: latest.row[IDEA_COLUMN["Planned date"]],
    };
    const fingerprint = ideaFingerprint(entry);
    if (ideaFingerprint(current) !== fingerprint || (entry.fingerprint && entry.fingerprint !== fingerprint)) {
      return { marked: false, reason: "Reviewer input changed; the new input remains pending" };
    }
    await this.updateRanges([
      { range: `W${entry.rowNumber}:X${entry.rowNumber}`, values: [[result, processedAt]] },
      { range: `AA${entry.rowNumber}:AA${entry.rowNumber}`, values: [[fingerprint]] },
    ], this.ideaSheetName);
    return { marked: true, fingerprint };
  }
}
