import { GoogleAuth } from "google-auth-library";
import { createHash } from "node:crypto";

export const IDEA_REVIEW_HEADERS = [
  "Idea decision", "Revision instructions", "Campaign ID", "Planned date", "Content type",
  "Version", "Current status", "Title", "Hook", "Audience", "GymFeed feature", "Objective",
  "Description", "Storyboard / slide outline", "Dialogue", "Caption", "CTA", "Evidence and metrics",
  "Reasoning and limitations", "Production requirements", "Approved version", "Processing result",
  "Processed at", "Idea ID", "Updated at", "Processed decision fingerprint",
];
const IDEA_COLUMN = Object.fromEntries(IDEA_REVIEW_HEADERS.map((name, index) => [name, index]));

function cellText(value) {
  if (value === undefined || value === null) return "";
  const text = typeof value === "string" ? value : JSON.stringify(value, null, 2);
  return text.length > 48000 ? `${text.slice(0, 48000)}\n[Display truncated; see the stored idea brief.]` : text;
}

function ideaFingerprint(entry) {
  return createHash("sha256").update(JSON.stringify([
    entry.ideaId, Number(entry.version), normalizedDecision(entry.decision), String(entry.instructions ?? "").trim(),
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
  return [
    "Pending", "", idea.campaign_id, idea.planned_date ?? "", idea.content_type,
    idea.version, idea.status, brief.title ?? "", brief.hook ?? "", cellText(brief.audience),
    cellText(brief.feature), cellText(brief.objective), cellText(brief.description), cellText(brief.storyboard),
    cellText(brief.dialogue), cellText(brief.caption), cellText(brief.cta), cellText(brief.evidence),
    cellText(brief.rationale), cellText(brief.production_requirements), idea.approved_version ?? "",
    "New idea version; approve this idea before production", "", idea.id, idea.updated_at ?? "", "",
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

function rowForContent(content, existing = null) {
  const assets = [...(content.asset_urls ?? [])].slice(0, 7);
  while (assets.length < 7) assets.push("");
  const revision = reviewRevision(content);
  const sameRevision = existing && Number(existing[COLUMN.Revision] ?? 1) === revision;
  const fields = reviewFields(content.content_type);
  const needsRevisionDecision = ["failed", "qa_failed"].includes(content.status);
  const decision = sameRevision ? normalizedDecision(existing[COLUMN[fields.decision]]) : "Pending";
  const instructions = sameRevision ? (existing[COLUMN[fields.instructions]] ?? "") : "";
  const processingResult = needsRevisionDecision
    ? `ERROR: ${content.failure_reason ?? "Content failed quality review"}`
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
    needsRevisionDecision ? processingResult : (sameRevision ? (existing[COLUMN["Processing result"]] ?? "") : processingResult),
    needsRevisionDecision ? "" : (sameRevision ? (existing[COLUMN["Processed at"]] ?? "") : ""),
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

  async appendRows(values, sheetName = this.sheetName) {
    if (!values.length) return null;
    return this.request(`${this.valuesPath(`A:${LAST_COLUMN}`, sheetName)}:append?valueInputOption=RAW&insertDataOption=INSERT_ROWS`, {
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
    const byContentRevision = new Map();
    rows.forEach((row, index) => {
      const id = row[COLUMN["Content ID"]];
      if (id) byContentRevision.set(`${id}:${Number(row[COLUMN.Revision] || 1)}`, { row, rowNumber: index + 2 });
    });

    const append = [];
    for (const content of contents) {
      const key = `${content.id}:${reviewRevision(content)}`;
      const existing = byContentRevision.get(key);
      const next = rowForContent(content, existing?.row);
      if (existing?.rowNumber) {
        // A:D belong to the reviewer; W:X belong to the decision dispatcher.
        // Never write them during sync, even if the status is failed or QA-failed.
        await this.updateRange(`E${existing.rowNumber}:V${existing.rowNumber}`, [next.slice(4, 22)]);
        await this.updateRange(`Y${existing.rowNumber}:Z${existing.rowNumber}`, [next.slice(24)]);
      } else if (!existing) {
        append.push(next);
        byContentRevision.set(key, { row: next });
      }
    }
    await this.appendRows(append);
    return { updated: contents.length - append.length, appended: append.length };
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
    const decisionColumn = type === "video" ? COLUMN["Video decision"] : COLUMN["Carousel decision"];
    const instructionsColumn = type === "video" ? COLUMN["Video instructions"] : COLUMN["Carousel instructions"];
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
    const headerResult = await this.request(this.valuesPath("A1:Z1", this.ideaSheetName));
    const headers = headerResult.values?.[0] ?? [];
    if (IDEA_REVIEW_HEADERS.every((header, index) => headers[index] === header)) return sheetId;
    if (headers.some((value) => value !== "")) throw new Error(`Refusing to overwrite unfamiliar columns in ${this.ideaSheetName}`);
    await this.updateRange("A1:Z1", [IDEA_REVIEW_HEADERS], this.ideaSheetName);
    await this.request(":batchUpdate", {
      method: "POST",
      body: { requests: [
        { updateSheetProperties: {
          properties: { sheetId, gridProperties: { frozenRowCount: 1, frozenColumnCount: 2 } },
          fields: "gridProperties.frozenRowCount,gridProperties.frozenColumnCount",
        } },
        { repeatCell: {
          range: { sheetId, startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: 26 },
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
          range: { sheetId, dimension: "COLUMNS", startIndex: 0, endIndex: 26 },
          properties: { pixelSize: 220 }, fields: "pixelSize",
        } },
        { updateDimensionProperties: {
          range: { sheetId, dimension: "COLUMNS", startIndex: 25, endIndex: 26 },
          properties: { hiddenByUser: true }, fields: "hiddenByUser",
        } },
      ] },
    });
    return sheetId;
  }

  async readIdeaRows() {
    await this.ensureIdeaSheet();
    const result = await this.request(this.valuesPath("A2:Z", this.ideaSheetName));
    return result.values ?? [];
  }

  async syncIdeas(ideas) {
    const rows = await this.readIdeaRows();
    const byVersion = new Map();
    rows.forEach((row, index) => {
      const id = row[IDEA_COLUMN["Idea ID"]];
      if (id) byVersion.set(`${id}:${Number(row[IDEA_COLUMN.Version])}`, { row, rowNumber: index + 2 });
    });
    const append = [];
    let updated = 0;
    for (const idea of ideas) {
      if (!idea.id || !idea.campaign_id || !Number.isInteger(Number(idea.version)) || Number(idea.version) < 1) {
        throw new Error("Each idea requires a stable id, campaign_id, and positive integer version");
      }
      const key = `${idea.id}:${Number(idea.version)}`;
      const existing = byVersion.get(key);
      const next = ideaRow(idea);
      if (existing?.rowNumber) {
        const rowNumber = existing.rowNumber;
        // A:B are human-owned; V:W and Z are dispatcher-owned acknowledgments.
        await this.updateRange(`C${rowNumber}:U${rowNumber}`, [next.slice(2, 21)], this.ideaSheetName);
        await this.updateRange(`X${rowNumber}:Y${rowNumber}`, [next.slice(23, 25)], this.ideaSheetName);
        updated += 1;
      } else if (!existing) {
        append.push(next);
        byVersion.set(key, { row: next });
      }
    }
    await this.appendRows(append, this.ideaSheetName);
    return { updated, appended: append.length };
  }

  async pendingIdeaDecisions() {
    const rows = await this.readIdeaRows();
    const latest = latestRowsById(rows, IDEA_COLUMN["Idea ID"], IDEA_COLUMN.Version);
    return [...latest.values()].flatMap(({ row, rowNumber, version }) => {
      const decision = normalizedDecision(row[IDEA_COLUMN["Idea decision"]]);
      if (decision === "Pending" || !Number.isInteger(version) || version < 1) return [];
      const entry = {
        rowNumber, ideaId: row[IDEA_COLUMN["Idea ID"]], campaignId: row[IDEA_COLUMN["Campaign ID"]],
        version, decision, instructions: String(row[IDEA_COLUMN["Revision instructions"]] ?? "").trim(),
      };
      entry.fingerprint = ideaFingerprint(entry);
      if (entry.fingerprint === row[IDEA_COLUMN["Processed decision fingerprint"]]) return [];
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
    };
    const fingerprint = ideaFingerprint(entry);
    if (ideaFingerprint(current) !== fingerprint || (entry.fingerprint && entry.fingerprint !== fingerprint)) {
      return { marked: false, reason: "Reviewer input changed; the new input remains pending" };
    }
    await this.updateRange(`V${entry.rowNumber}:W${entry.rowNumber}`, [[result, processedAt]], this.ideaSheetName);
    await this.updateRange(`Z${entry.rowNumber}:Z${entry.rowNumber}`, [[fingerprint]], this.ideaSheetName);
    return { marked: true, fingerprint };
  }
}
