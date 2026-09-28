# GymFeed CMO: seven-day ideas, single-item production

Updated 27 September 2026. This process supersedes the earlier batch-first approval workflow.

## Start a campaign

The active weekly workflow runs Sunday morning, refreshes the learning loop, and creates the next Monday-through-Sunday plan. It stops at Idea Review and never bulk-generates media.

1. Open http://127.0.0.1:5678/workflow/GFMainCMOOrchestrator001 and reload the page.
2. Open **Campaign settings - edit action here**. Keep `action = 'plan_campaign'`. Set a fixed `startDate`; the normal campaign length is seven days. Keep the same request key when retrying the same campaign.
3. Execute the workflow. This generates text plans only, using the configured OpenAI research/strategy budget. It does not call fal or Buffer.
4. Review **Idea Review** in the existing GymFeed-Marketing-Approval spreadsheet. Each video and carousel has title, hook, audience, objective, story/slide outline, dialogue, caption, CTA, research sources/metrics/gaps, reasoning, production requirements, revision, and the exact generation prompt package.
5. Edit **Planned date** in that row when the item should publish on a different day, using `YYYY-MM-DD`, then select Approve. The date is reviewer-owned, survives sheet refreshes, and is stored in Supabase before production starts. Select Approve on any single row to start only that video's or carousel's production. Write specific instructions and select Reject to revise only that idea. The revised content replaces the same row, records the rejected version in Processing result, and resets the decision to Pending.

**Idea Review** starts with A: Idea decision, B: Current status, C: Reason / next step, D: Title, E: Description, F: Content type, G: Planned date. Edit G before approval using `YYYY-MM-DD`. Automation resolves fields by their headers. A date cannot be changed after production starts, and two items of the same format in one campaign cannot share the same date. Technical IDs and fingerprints are at the right. Native backup tabs preserve the previous layout and values.

## Generate an approved item

No manual batch action is needed in the normal path. The decision dispatcher sends every individual Idea Review approval to **GymFeed 06 - Import Capture and Start Approved Item**. Workflow 06 discovers the approved plan's exact requested MP4 in the configured Drive upload folder, refreshes matching approved screenshots when Drive copies exist, downloads them to the persistent local mounts, validates them, and starts production plus QA for only that content ID. Other pending ideas do not block it and are not generated.

If a required Drive file is absent or fails intake validation, the approved idea remains approved but its **Current status** becomes `Approved - Blocked`. **Reason / next step** contains the exact reason, such as the missing filename or invalid MIME type. The dispatcher retries capture-blocked approvals every five minutes. While checking Drive, the status changes to Pending and Last activity updates; a repeated failure returns to Approved - Blocked. Supplying the required file resumes the same item without another approval. Paid production/QA failures do not restart endlessly: they require a Content Review action. Workflow 06 can also be run manually with no entry; it scans only existing eligible approvals, never creates a campaign, and reports no work when none is pending.

After intake succeeds, the worker checks every required app recording before spending on that item. It then generates, performs shot QA, assembles, checks the final edited audio/duration, performs final visual QA, and writes previews to **Content Review**. The run must reach that handoff to report success.

Use `action = 'resume_batch'` with the same campaign and batch IDs after addressing a missing recording, approving a revised idea, or resolving a reported failure. Never create a new campaign to resume an existing one. A known in-flight task is resumed; an ambiguous interrupted provider submission requires reconciliation rather than automatic duplicate spending.

## Review and schedule

**Content Review** starts with A: Decision, B: Current status, C: Reason / next step, D: QA score, E: Preview, F: Asset 1. Topic, planned date, Buffer status and confirmed post IDs follow. Review the whole rendered video, including sound and transitions, not only its thumbnail. Reject with revision instructions revises only that asset, replaces its links in the same row, and resets the decision to Pending (or Needs Review if QA fails). No row is deleted and no new Idea Review approval is required.

A failed asset changes to **Needs Review**, with the reason in C. Selecting **Approve** on that failed asset requests automatic repair using the saved QA findings and contact sheets of the actual source recordings. The worker preserves the concept, people and dialogue, attempts at most two repair cycles, and schedules the corrected asset only if it passes. A missing genuine interaction cannot be fabricated: upload a new recording when that is the stated blocker. Budget/provider errors remain visible and stop retries.

To explicitly accept an existing asset despite the AI review, change **QA score** in D to a different value from 85 through 100. That edit itself requests approval and Buffer scheduling on the next dispatcher check. It cannot approve a missing asset or a stale revision. **AI QA score** and the original review are preserved for audit. A new revision clears the override. Leaving an AI score of 85+ unchanged is not approval.

Publishing remains separately gated. Every published item must pass the database gate, have final approval and use the date saved from Idea Review. Defaults are carousel at 12:00, Instagram video at 18:00, TikTok at 18:15 and YouTube at 18:30 in the campaign timezone. There is no immediate-post fallback for an expired date.

In the normal single-item path, approving the finished row in **Content Review** releases only that item, without waiting for other assets in its batch, and attempts to create its scheduled Buffer posts. This requires `BUFFER_API_KEY` plus the relevant channel IDs in `marketing/.env`. **Scheduled** means Buffer returned a post ID for every target; partial or rejected submissions show **Approved - Blocked** and a reason. Existing confirmed posts are not duplicated on retry.

`release_batch` is an explicit recovery action after every final is approved. Existing Buffer request IDs are reused rather than submitted again. A pending submission without a confirmed provider ID must be reconciled in Buffer before retrying.

`start_batch`, `resume_batch` and `release_batch` remain operator recovery actions for existing campaign state. They are not part of the normal single-item approval path.

## App recordings and current limits

Upload real clean-demo MP4 recordings to the Drive folder linked from **Production requirements**, using the exact requested filename. Workflow 06 downloads the file to `docs/marketing/app-captures/`, verifies its MIME type, duration and SHA-256 hash, and updates the persistent manifest. Matching approved Drive screenshots are downloaded to `docs/marketing/screenshots/curated/` with MIME, dimensions and hash verification. Existing verified local screenshots remain valid; they are not presented as actual tap-to-result interactions.

Missing recordings can be proposed as `requested:...` in the idea brief. After the idea is approved, a missing recording produces `Approved - Blocked`; supplying the exact Drive file lets the automatic retry continue the same approved revision. Never edit an approved plan directly: its hash is checked against the production manifest.

V2 supports connected human-action shots, real app captures, exact composited branding and per-scene dialogue/narration. It does not guarantee artifact-free video. Automated visual QA uses sampled frames; human final review is still required for motion/lip-sync quality. Licensed background music mixing is not implemented yet.

### V3 human-story production

New plans and revisions use production version 3; existing approved V2 plans are not silently rewritten. The default is a two-person dialogue story: situation, tension, real product action, human payoff. Every actor has a stable ID, appearance, wardrobe and voice direction. Each generated shot explicitly names the visible cast and exactly one speaker. A dialogue story must include at least three native speech beats across two speakers, a human opening and a human payoff after the app action, with people occupying at least half the edit. Solo-story exceptions need an explicit creative reason; product-only work requires an explicit tutorial brief.

Each actor receives a separate Nano Banana reference. Gemini Omni receives only that scene's references, in the same order as the prompt's IMAGE_REF markers. Retries reuse the saved actor references. Shot QA receives those identity images separately from the contact sheet, plus the retained-audio transcript evidence. This improves identity/speaker control but does not guarantee stable voices or lip sync; the final human review remains necessary.

Before any V3 image/video spend, an independent Luna script review checks hook, natural dialogue, product causality, payoff and filmability. All five scores must be at least 85, with acceptance and no required fixes. Timing/cast/cut arithmetic is validated in code, not guessed by the reviewer. The review is saved under decision.story_review with a fingerprint; a changed plan cannot reuse an older approval. A failed gate records a concrete failure reason and stops media generation. The existing explicit approval/repair workflow handles revisions; it is not an unlimited retry loop. Final audio, duration, scene QA and publication approval gates still apply to V3.

An isolated Astra test is available through `node --env-file=.env scripts/test-astra-story.mjs` from the marketing directory. It makes one Astra script call and a Luna review, stores the result locally, and accounts for actual token cost in the existing ledger. It does not create a campaign, produce media, edit review sheets or publish. Its fixed run key prevents a duplicate Astra call. The explicit `--review-existing` option reviews the saved script only. Astra pricing is accounted separately; production creative routing remains Sol until a creative model change is intentionally selected. Gemini Omni remains the active video model because its reference endpoint supports the required multiple identities; changing a text-to-video setting alone does not change reference-based production.

The old general content-pipeline/review mutation paths cannot bypass the new campaign gates. Historical assets and review rows are preserved but are not automatically enrolled or generated. The weekly analysis and publication-status workflows remain enabled.

## OpenAI routing and cost controls

Research, content QA and scene QA use `gpt-6-luna`; creative plans and revisions now use `OPENAI_CREATIVE_MODEL`, default `gpt-6-sol`. Research and QA use low reasoning; creative plans and revisions use medium reasoning. A deterministic validation failure may make one `gpt-6-sol` fallback request; weekly CMO strategy also uses Sol. Terra and Astra are not enabled by default. The creative direction prioritizes relatable people-led or hybrid stories, natural dialogue, simple actions and verified product proof.

The worker sends bounded performance summaries instead of raw event, publication and content histories. Prompt caching is explicit: one-off research and generation calls do not write their changing payloads to cache, while repeated QA calls may reuse only their stable instruction prefix. Output token ceilings and the 272K long-context multiplier are included in configuration and cost accounting.

Daily and weekly run keys are idempotent. A failed paid run is not automatically replayed by the scheduler; use a new explicit revision, or set `retryFailed = true` on an intentional campaign recovery request. If an OpenAI response is billed but rejected by deterministic validation, the recorded token usage is settled in `marketing_cost_ledger` instead of being released.

## Verification and recovery

Unit/mock tests cover approval order, stale decisions, duplicate work, missing assets, manual QA overrides, bounded repair, scheduling confirmation and feedback preservation. The SQL migrations were tested in isolated PostgreSQL, including release of one approved item while a peer fails QA; FFmpeg integration verifies actual rendered audio and source footage. Live verification includes a successful empty-input Workflow 06 run, scheduled Workflow 05 checks, and a direct Buffer read confirming an existing scheduled carousel. Existing failed videos are retried separately; a passing unit suite is not proof that generated media passes final QA.

## Active workflows

- **00 Main CMO Orchestrator:** executes the exact decision forwarded by 05; manually running its planning branch creates a campaign.
- **03 Weekly CMO:** scheduled research/learning and next-week idea planning, not bulk video production.
- **04 Publication Status:** reads actual Buffer post state and refreshes review rows.
- **05 Google Sheet Decision Dispatcher:** checks reviewer changes and capture-blocked approvals every five minutes; independent items do not wait behind long-running generation.
- **06 Import Capture and Start Approved Item:** downloads approved Drive assets, verifies technical requirements, produces only that item and hands it to Content Review. Manual execution safely scans existing approvals.

For normal use, edit the review sheets. Do not run 00 to retry a failed asset or create another campaign to repair an existing one. Current status, Reason / next step and Last activity are machine-owned. Buffer status and post IDs are the scheduling confirmation, not the Approve dropdown alone.

The pre-change main/dispatcher exports are saved under `marketing/artifacts/workflow-backups/2026-09-20-approval-gates/`. The new campaign tables are additive; old content is not deleted. Do not restore the old immediate-generation workflow without checking pending decisions first.
