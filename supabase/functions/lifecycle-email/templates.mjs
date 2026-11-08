// Welcome and Premium-reminder emails for the Founding Members launch.
// Pure functions: they take the row returned by claim_lifecycle_emails() and
// return { subject, text, html }, or null when the email should not be sent.

export const DOWNLOAD_URL = "https://gymfeed.io/download";
const REFERRAL_DAYS = 7;
const MAX_INVITES = 4;
const DAY_MS = 86_400_000;

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

export function foundingLabel(number) {
  return Number.isInteger(number) && number > 0 ? `#${String(number).padStart(4, "0")}` : null;
}

function firstName(row) {
  const name = String(row.display_name ?? "").trim() || String(row.username ?? "").trim();
  return name ? name.split(/\s+/)[0] : "there";
}

function plural(count, word) {
  return `${count} ${word}${count === 1 ? "" : "s"}`;
}

/** Whole days left, rounded up, or 0 when Premium has already ended. */
export function daysLeft(premiumUntil, now = new Date()) {
  const until = Date.parse(premiumUntil ?? "");
  if (!Number.isFinite(until)) return 0;
  const ms = until - now.getTime();
  return ms <= 0 ? 0 : Math.ceil(ms / DAY_MS);
}

const FOOTER = "You're getting this because you have a GymFeed account. "
  + "Reply STOP and we won't email you again.";

function render({ subject, preheader, paragraphs, bullets = [], closing, button }) {
  const text = [
    ...paragraphs.slice(0, 2),
    ...(bullets.length ? [bullets.map((item) => `- ${item}`).join("\n")] : []),
    ...paragraphs.slice(2),
    `${button.label}: ${button.url}`,
    ...closing,
    "",
    FOOTER,
  ].join("\n\n");

  const p = (value) => `<p style="margin:0 0 16px;font-size:16px;line-height:1.5;color:#111111">${escapeHtml(value)}</p>`;
  const list = bullets.length
    ? `<ul style="margin:0 0 16px;padding-left:20px;font-size:16px;line-height:1.5;color:#111111">${
      bullets.map((item) => `<li style="margin:0 0 6px">${escapeHtml(item)}</li>`).join("")}</ul>`
    : "";
  const html = `<!doctype html><html><body style="margin:0;padding:0;background:#f4f4f4">`
    + `<span style="display:none;max-height:0;overflow:hidden">${escapeHtml(preheader)}</span>`
    + `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f4f4f4"><tr><td align="center" style="padding:24px 12px">`
    + `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;background:#ffffff;border-radius:12px"><tr><td style="padding:28px 24px;font-family:Helvetica,Arial,sans-serif">`
    + paragraphs.slice(0, 2).map(p).join("")
    + list
    + paragraphs.slice(2).map(p).join("")
    + `<p style="margin:8px 0 24px"><a href="${escapeHtml(button.url)}" style="display:inline-block;background:#16E77D;color:#000000;font-weight:bold;font-size:16px;text-decoration:none;padding:12px 22px;border-radius:999px">${escapeHtml(button.label)}</a></p>`
    + closing.map(p).join("")
    + `<p style="margin:24px 0 0;font-size:12px;line-height:1.5;color:#777777">${escapeHtml(FOOTER)}</p>`
    + `</td></tr></table></td></tr></table></body></html>`;
  return { subject, text, html };
}

export function welcomeEmail(row) {
  const label = foundingLabel(row.founding_number);
  const days = Number.isInteger(row.trial_days) && row.trial_days > 0 ? row.trial_days : 7;
  const handle = String(row.username ?? "").trim();
  const friendLine = handle
    ? `+${REFERRAL_DAYS} more days for every friend you invite (up to ${MAX_INVITES}). They just enter your username, @${handle}, when they sign up.`
    : `+${REFERRAL_DAYS} more days for every friend you invite (up to ${MAX_INVITES}). They just enter your username when they sign up.`;
  const start = "Not sure where to start? Scan a machine at your gym, or tell the AI coach how much time you have today.";
  const closing = ["Hit reply anytime. This email goes straight to the founders.", "The GymFeed founders"];
  const button = { label: "Open GymFeed", url: DOWNLOAD_URL };

  if (label) {
    return render({
      subject: `You're GymFeed Founding Member ${label}`,
      preheader: `${plural(days, "day")} of Premium, starting today.`,
      paragraphs: [
        `Hi ${firstName(row)},`,
        `Welcome to GymFeed. You're Founding Member ${label}, one of the first 1,000 people here. Here's what that gets you:`,
        start,
      ],
      bullets: [
        "A Founding badge on your profile, forever",
        `${plural(days, "day")} of Premium, starting today`,
        friendLine,
        "First access to everything we build, and a vote on what comes next",
      ],
      closing,
      button,
    });
  }
  return render({
    subject: "Welcome to GymFeed",
    preheader: `${plural(days, "day")} of Premium, starting today.`,
    paragraphs: [
      `Hi ${firstName(row)},`,
      "Welcome to GymFeed. Here's what you get to start:",
      start,
    ],
    bullets: [`${plural(days, "day")} of Premium, starting today`, friendLine],
    closing,
    button,
  });
}

export function reminderEmail(row, now = new Date()) {
  const left = daysLeft(row.premium_until, now);
  // Ended already, or a friend's invite pushed the end date out again.
  if (left < 1 || left > 2) return null;
  const label = foundingLabel(row.founding_number);
  const used = Number.isInteger(row.invites_used) ? row.invites_used : 0;
  const invitesLeft = Math.max(0, MAX_INVITES - used);
  const handle = String(row.username ?? "").trim();
  const lead = `${plural(left, "day")} of Premium left`;

  const more = invitesLeft > 0
    ? `Want more time? Invite a friend. When they sign up and enter ${handle ? `@${handle}` : "your username"} under "Who invited you?", you both get ${REFERRAL_DAYS} more days. You have ${plural(invitesLeft, "invite")} left.`
    : "Want to keep your AI coach after that? GymFeed Pro keeps every AI tool unlocked.";

  return render({
    subject: label ? `${lead}, Founding Member ${label}` : lead,
    preheader: invitesLeft > 0 ? "Invite a friend and you both get 7 more days." : "Keep your AI coach with GymFeed Pro.",
    paragraphs: [
      `Hi ${firstName(row)},`,
      `Your free Premium ends in ${plural(left, "day")}. Before it does, try one of these:`,
      more,
    ],
    bullets: [
      "Scan a machine you've never used",
      "Ask the AI coach for a workout that fits the time you have",
      "Snap your next meal to log it",
    ],
    closing: ["The GymFeed founders"],
    button: { label: invitesLeft > 0 ? "Open GymFeed and invite a friend" : "Open GymFeed", url: DOWNLOAD_URL },
  });
}

/** Picks the template for a claimed row; null means skip it. */
export function emailFor(row, now = new Date()) {
  if (row.kind === "welcome") return welcomeEmail(row);
  if (row.kind === "premium_reminder") return reminderEmail(row, now);
  return null;
}
