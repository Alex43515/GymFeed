# GymFeed CMO: approved ideas, seven-day production

Deployed 20 September 2026. This process supersedes the earlier one-day immediate-generation workflow.

## Start a campaign

1. Open http://127.0.0.1:5678/workflow/GFMainCMOOrchestrator001 and reload the page.
2. Open **Campaign settings - edit action here**. Keep `action = 'plan_campaign'`. Set a fixed `startDate`, the campaign length (1–31 days; default 28), and the target-market timezone (default America/New_York). Keep the same request key when retrying the same campaign.
3. Execute the workflow. This generates text plans only, using the configured OpenAI research/strategy budget. It does not call fal or Buffer.
4. Review **Idea Review** in the existing GymFeed-Marketing-Approval spreadsheet. Each video and carousel has title, hook, audience, objective, story/slide outline, dialogue, caption, CTA, research sources/metrics/gaps, reasoning, production requirements and revision.
5. Select Approve, or write specific instructions then Reject. The dispatcher checks every five minutes. Only the rejected item is revised. All current campaign idea versions must be approved before production.

## Generate the first seven days

Copy the campaign ID from the planning output. In the same settings node choose `action = 'start_batch'`, set `campaignId`, and keep `batchNumber = 1`. Execute. The database releases exactly the first seven calendar days (or the remaining smaller period). No other campaign content is eligible for generation.

The worker checks every required app recording before spending on any item in the batch. It then generates, performs shot QA, assembles, checks the final edited audio/duration, performs final visual QA, and writes previews to **Content Review**. The run must reach that handoff to report success. A failing item stops this batch and reports its reason.

Use `action = 'resume_batch'` with the same campaign and batch IDs after addressing a missing recording, approving a revised idea, or resolving a reported failure. Never create a new campaign to resume an existing one. A known in-flight task is resumed; an ambiguous interrupted provider submission requires reconciliation rather than automatic duplicate spending.

## Review and schedule

Review the whole rendered video, including sound and transitions, not only its thumbnail. Approve video/carousel rows independently. Reject returns that content item to idea revision and approval before regeneration; unrelated items are preserved.

The last finished-asset approval in a batch authorizes release to Buffer. Every item must pass the database gate, have final approval and use a future campaign schedule. Defaults are carousel at 12:00, Instagram video at 18:00, TikTok at 18:15 and YouTube at 18:30 in the campaign timezone. Existing configured platform channels and YouTube privacy remain unchanged. There is no immediate-post fallback for an expired date.

`release_batch` is an explicit recovery action after every final is approved. Existing Buffer request IDs are reused rather than submitted again. A pending submission without a confirmed provider ID must be reconciled in Buffer before retrying.

After approving the finished batch, choose `start_batch` and increment `batchNumber` to explicitly release the next seven days. Reusing the prior request key resumes/reuses the old batch, not the next one.

## App recordings and current limits

Place real clean-demo MP4 recordings in `docs/marketing/app-captures/` and verify them in its `manifest.json`, including the SHA-256 file hash, duration and visible interactions. See the README in that folder. After adding recordings, rebuild/restart the worker so the Docker image includes them. Existing screenshots remain supported; they are not presented as actual tap-to-result interactions.

Missing recordings can be proposed as `requested:...` in the idea brief. Supplying one requires revising that idea to reference the verified recording, then approving the new version. Never edit an approved plan directly: its hash is checked against the production manifest.

V2 supports connected human-action shots, real app captures, exact composited branding and per-scene dialogue/narration. It does not guarantee artifact-free video. Automated visual QA uses sampled frames; human final review is still required for motion/lip-sync quality. Licensed background music mixing is not implemented yet.

The old general content-pipeline/review mutation paths cannot bypass the new campaign gates. Historical assets and review rows are preserved but are not automatically enrolled or generated. The weekly analysis and publication-status workflows remain enabled.

## Verification and recovery

Unit/mock tests cover approval order, stale decisions, duplicate work, seven-day manifests, missing assets, scheduling and feedback preservation. The actual SQL migration was tested in isolated PostgreSQL; FFmpeg integration was tested without network access. No paid campaign generation or publication was used to verify deployment.

The pre-change main/dispatcher exports are saved under `marketing/artifacts/workflow-backups/2026-09-20-approval-gates/`. The new campaign tables are additive; old content is not deleted. Do not restore the old immediate-generation workflow without checking pending decisions first.
