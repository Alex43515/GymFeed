import { GoogleAuth } from "google-auth-library";

export const OUTREACH_HEADERS = [
  "Reached", "Reacted", "Messaged back", "Accepted", "Owner",
  "Creator", "Platform", "Handle", "Open DM", "Profile URL", "Other profiles", "Email",
  "Followers", "Engagement %", "Market", "Language", "Fit score", "Tier", "Why they fit",
  "First message", "Status", "Last activity", "Conversation summary", "Next step for you", "Suggested reply",
  "Notes", "Instagram user ID", "Last handled message ID", "Week", "Creator ID", "Updated at",
];
export const CHECKBOX_HEADERS = ["Reached", "Reacted", "Messaged back", "Accepted"];
export const BOT_OWNER = "Bot";

const COLUMN = Object.fromEntries(OUTREACH_HEADERS.map((name, index) => [name, index]));

export function columnLetter(index) {
  let letter = "";
  for (let value = index + 1; value > 0; value = Math.floor((value - 1) / 26)) {
    letter = String.fromCharCode(65 + ((value - 1) % 26)) + letter;
  }
  return letter;
}

const LAST_COLUMN = columnLetter(OUTREACH_HEADERS.length - 1);

export function normalizeHandle(value) {
  let text = String(value ?? "").trim().split(/[?#]/)[0].replace(/\/+$/, "");
  if (text.includes("/")) text = text.split("/").pop();
  return text.replace(/^@+/, "").toLowerCase();
}

export function dmLink(platform, handle) {
  const clean = normalizeHandle(handle);
  return platform === "instagram" ? `https://ig.me/m/${clean}` : `https://www.tiktok.com/@${clean}`;
}

function cell(value) {
  if (value === undefined || value === null) return "";
  return value;
}

export function recordToRow(record) {
  return OUTREACH_HEADERS.map((header) => cell(record[header]));
}

export function rowToRecord(row = []) {
  return Object.fromEntries(OUTREACH_HEADERS.map((header, index) => {
    const value = row[index] ?? "";
    if (CHECKBOX_HEADERS.includes(header)) return [header, value === true || String(value).toUpperCase() === "TRUE"];
    return [header, value];
  }));
}

// Every handle a row is known by, so a creator found again on another platform is not contacted twice.
export function rowHandles(record) {
  const handles = [normalizeHandle(record.Handle)];
  for (const part of String(record["Other profiles"] ?? "").split(/[,\n]/)) {
    const handle = normalizeHandle(part.replace(/^\s*(instagram|tiktok)\s*:/i, ""));
    if (handle) handles.push(handle);
  }
  return handles.filter(Boolean);
}

export class OutreachSheet {
  constructor({ spreadsheetId, sheetName = "Influencer Outreach", credentialsPath, auth, fetchImpl = fetch } = {}) {
    this.spreadsheetId = spreadsheetId;
    this.sheetName = sheetName;
    this.fetchImpl = fetchImpl;
    this.auth = auth ?? (spreadsheetId ? new GoogleAuth({
      ...(credentialsPath ? { keyFile: credentialsPath } : {}),
      scopes: ["https://www.googleapis.com/auth/spreadsheets"],
    }) : null);
  }

  get configured() {
    return Boolean(this.spreadsheetId && this.auth);
  }

  async request(path, { method = "GET", body } = {}) {
    if (!this.configured) throw new Error("Outreach sheet is not configured (set OUTREACH_SHEET_ID)");
    const client = await this.auth.getClient();
    const authHeaders = await client.getRequestHeaders();
    const headers = typeof authHeaders?.entries === "function" ? Object.fromEntries(authHeaders.entries()) : authHeaders;
    const response = await this.fetchImpl(`https://sheets.googleapis.com/v4/spreadsheets/${this.spreadsheetId}${path}`, {
      method,
      headers: { ...headers, ...(body === undefined ? {} : { "content-type": "application/json" }) },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(`Google Sheets ${method} ${path}: ${payload.error?.message ?? response.status}`);
    return payload;
  }

  range(range) {
    return `'${this.sheetName.replaceAll("'", "''")}'!${range}`;
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
    const current = (await this.request(`/values/${encodeURIComponent(this.range(`A1:${LAST_COLUMN}1`))}`)).values?.[0] ?? [];
    if (OUTREACH_HEADERS.every((header, index) => current[index] === header)) return sheetId;
    if (current.some((value) => value !== "")) throw new Error(`Refusing to overwrite unfamiliar columns in ${this.sheetName}`);

    await this.request(`/values/${encodeURIComponent(this.range(`A1:${LAST_COLUMN}1`))}?valueInputOption=RAW`, {
      method: "PUT",
      body: { range: this.range(`A1:${LAST_COLUMN}1`), majorDimension: "ROWS", values: [OUTREACH_HEADERS] },
    });
    await this.request(":batchUpdate", {
      method: "POST",
      body: {
        requests: [
          {
            updateSheetProperties: {
              properties: { sheetId, gridProperties: { frozenRowCount: 1, frozenColumnCount: 8 } },
              fields: "gridProperties.frozenRowCount,gridProperties.frozenColumnCount",
            },
          },
          {
            repeatCell: {
              range: { sheetId, startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: OUTREACH_HEADERS.length },
              cell: {
                userEnteredFormat: {
                  backgroundColor: { red: 0.05, green: 0.08, blue: 0.07 },
                  textFormat: { foregroundColor: { red: 1, green: 1, blue: 1 }, bold: true },
                  horizontalAlignment: "CENTER",
                  wrapStrategy: "WRAP",
                },
              },
              fields: "userEnteredFormat",
            },
          },
          {
            setDataValidation: {
              range: { sheetId, startRowIndex: 1, endRowIndex: 5000, startColumnIndex: COLUMN.Status, endColumnIndex: COLUMN.Status + 1 },
              rule: {
                condition: {
                  type: "ONE_OF_LIST",
                  values: ["To contact", "Contacted", "In conversation", "Handed off", "Accepted", "Declined", "Skip"]
                    .map((userEnteredValue) => ({ userEnteredValue })),
                },
                showCustomUi: true,
                strict: false,
              },
            },
          },
        ],
      },
    });
    return sheetId;
  }

  async readRecords() {
    const result = await this.request(`/values/${encodeURIComponent(this.range(`A2:${LAST_COLUMN}5000`))}?valueRenderOption=UNFORMATTED_VALUE`);
    return (result.values ?? [])
      .map((row, index) => ({ rowNumber: index + 2, record: rowToRecord(row) }))
      .filter(({ record }) => record["Creator ID"] || record.Handle);
  }

  async sheetProperties() {
    const metadata = await this.request("?fields=sheets.properties");
    const sheet = metadata.sheets?.find((item) => item.properties?.title === this.sheetName);
    if (!sheet) throw new Error(`Missing ${this.sheetName} tab`);
    return sheet.properties;
  }

  // Writes directly below the last creator. The values:append API would skip past checkbox cells
  // (they read as FALSE), so checkboxes are only added to rows that hold a creator.
  async appendRecords(records) {
    if (!records.length) return null;
    const { sheetId, gridProperties } = await this.sheetProperties();
    const existing = await this.readRecords();
    const start = existing.length ? Math.max(...existing.map(({ rowNumber }) => rowNumber)) + 1 : 2;
    const end = start + records.length - 1;
    const requests = [];
    if (end > (gridProperties?.rowCount ?? 0)) {
      requests.push({ appendDimension: { sheetId, dimension: "ROWS", length: end - (gridProperties?.rowCount ?? 0) } });
    }
    requests.push({
      setDataValidation: {
        range: { sheetId, startRowIndex: start - 1, endRowIndex: end, startColumnIndex: 0, endColumnIndex: CHECKBOX_HEADERS.length },
        rule: { condition: { type: "BOOLEAN" }, showCustomUi: true },
      },
    });
    await this.request(":batchUpdate", { method: "POST", body: { requests } });
    const range = this.range(`A${start}:${LAST_COLUMN}${end}`);
    return this.request(`/values/${encodeURIComponent(range)}?valueInputOption=RAW`, {
      method: "PUT",
      body: { range, majorDimension: "ROWS", values: records.map(recordToRow) },
    });
  }

  async updateRecord(rowNumber, changes) {
    const data = Object.entries({ ...changes, "Updated at": new Date().toISOString() })
      .filter(([header]) => header in COLUMN)
      .map(([header, value]) => ({
        range: this.range(`${columnLetter(COLUMN[header])}${rowNumber}`),
        majorDimension: "ROWS",
        values: [[cell(value)]],
      }));
    if (!data.length) return null;
    return this.request("/values:batchUpdate", { method: "POST", body: { valueInputOption: "RAW", data } });
  }
}
