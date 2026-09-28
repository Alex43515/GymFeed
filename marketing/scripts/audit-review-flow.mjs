import { loadConfig } from "../src/config.mjs";
import { MarketingRepository } from "../src/repository.mjs";
import { MarketingCampaigns } from "../src/campaigns.mjs";
import { CmoController } from "../src/cmo-controller.mjs";
import { ReviewBoard, IDEA_HEADERS, CONTENT_HEADERS } from "../src/providers/review-board.mjs";

const config = loadConfig();
const repository = new MarketingRepository(config);
const campaigns = new MarketingCampaigns({ repository });
const approvalSheet = new ReviewBoard({ spreadsheetId: config.GOOGLE_SHEETS_APPROVAL_ID, sheetName: config.GOOGLE_SHEETS_APPROVAL_TAB, credentialsPath: config.GOOGLE_SHEETS_CREDENTIALS ?? process.env.GOOGLE_APPLICATION_CREDENTIALS });
const cmo = new CmoController({ config, repository, campaigns, approvalSheet });
if (process.argv.includes("--sync")) {
  for (const campaign of await repository.campaignList()) {
    await cmo.sync(campaign.id);
    console.log(JSON.stringify({ synced: campaign.id }));
  }
}
const ideas = await approvalSheet.readBoard(approvalSheet.ideaSheetName, IDEA_HEADERS);
const content = await approvalSheet.readBoard(approvalSheet.sheetName, CONTENT_HEADERS);
console.log(JSON.stringify({ spreadsheet: `https://docs.google.com/spreadsheets/d/${config.GOOGLE_SHEETS_APPROVAL_ID}/edit`,
  ideas: ideas.map((r) => ({ row: r.rowNumber, id: r["Idea ID"], decision: r["Idea decision"], status: r["Current status"], reason: r["Reason / next step"], blockKind: r["Block kind"] })),
  content: content.map((r) => ({ row: r.rowNumber, id: r["Content ID"], decision: r.Decision, status: r["Current status"], reason: r["Reason / next step"], qa: r["QA score"], aiQa: r["AI QA score"], buffer: r["Buffer status"], posts: r["Buffer posts"] })),
}, null, 2));
