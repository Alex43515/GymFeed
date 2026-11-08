# GymFeed marketing worker

This service implements the decision, generation, QA, budget, approval, publishing, and learning layers of GymFeed's marketing system. n8n only schedules authenticated worker endpoints; business logic remains version-controlled and testable here.

Safe defaults:

- `marketing_brand_config.enabled = false`
- `GENERATE_ASSETS=false`
- `AUTO_PUBLISH=false`
- imported n8n workflows are inactive

See [`../docs/MARKETING_AUTOMATION.md`](../docs/MARKETING_AUTOMATION.md) for deployment and activation.

Owner review is the default (`MARKETING_REVIEW_MODE=human`). Idea approval authorizes one production attempt. Completed videos, carousels and images go to Content Review without AI story/scene/final QA or automatic paid retakes. Approve in Content Review sends the existing asset to Buffer; Reject with revision instructions requests a new version of the same item. Transcription remains enabled to produce captions from actual speech. Missing files, provider failures and invalid schedules remain explicit technical errors.

`FAL_MAX_VIDEO_ATTEMPT_USD=25` caps the configured cost estimate before a new video batch is submitted, in addition to the monthly budget. This is an estimate, not reconciled provider billing. Existing task IDs and downloaded clips are saved incrementally and reused after interruption. Full revision briefs are applied by the planner; each video request contains only its own shot. TikTok photo posts disclose generated imagery in their caption and omit Buffer's video-only `isAiGenerated` field.

In owner-review production, each scene prompt contains only its own action and line. Native speech gets at least 2.4 words/second plus a breath and source handles, checked against the provider window and cost limit before submission. Word/segment timestamps select complete sentences with pauses, preserving the creator's voice. An unmatched or boundary-truncated line keeps its full source as a clearly flagged preview, without a paid retake. All platforms retain the same story. Narration stays at its recorded speed; the edit may hold the last visual frame while preserving the real app action and playback speed. Captions follow small groups of actual spoken words. Final audio transcription checks complete planned lines; missing words, rushed source speech and unavailable checks appear in Reason / next step and QA summary. These are technical findings for the owner, not an AI creative score or publication veto.

Reject plus Revision instructions in Content Review now makes a selective video revision in the same content row. Astra returns a constrained patch using stable scene IDs: edits, captions, CTA and pacing reuse raw clips, actor references and unchanged narration. Only explicitly affected shots receive new fal requests; the cost preflight covers only those shots and missing references. A full remake requires explicit owner instructions. The previous asset snapshot survives the campaign revision reset, each task is checkpointed, and a resumed revision reuses queued jobs. The finished revision returns to Pending / Needs Review for manual approval; it is never automatically published. Missing raw footage or an instruction that cannot be met by editing is reported before new media is submitted.

Photo/carousel music has an opt-in delivery route: `PHOTO_MUSIC_MODE=notification` schedules the original images through Buffer Notify Me on Instagram and TikTok. The owner must have Buffer mobile notifications configured, select an available licensed track in the native app and finish publishing there. Astra supplies an idea-specific mood/energy direction; Instagram's music sticker field is a reminder placeholder, not an audio attachment. TikTok's Buffer API exposes no soundtrack field. The Sheet displays notification scheduled / add music and publish in app, and a sent reminder never counts as a published post or a performance example until Buffer reports `markedAsPublished`. That mark is the owner's confirmation, not verification of attached audio. Existing scheduled posts are not converted or duplicated. The default is `off` (existing automatic photo delivery); enabling notifications changes the owner's publishing workflow and requires choosing that route. Fully automatic music would require a separately reviewed video/slideshow output rather than native photos. See [Buffer's music support](https://support.buffer.com/en-us/articles/adding-music-stickers-and-other-effects-to-instagram-and-tiktok-posts-G5QrWfQL4k).

Local checks:

New human-review video productions default to `MARKETING_CONTINUITY_MODE=locked`. Astra compiles the approved storyboard into stable location IDs without rewriting the story. Each actor has one persistent portrait and wardrobe; every physical set has one cached empty-location reference, reused across angles. On-camera dialogue uses single-speaker framing. `MARKETING_CREATOR_VOICES` binds distinct voices to actors, and product narration uses the lead's voice. Each complete line is recorded once, cached by speaker/voice/text/direction, padded without truncation, and synchronized through `fal-ai/sync-lipsync/v2`. The final edit uses the canonical audio, normalizes level and discards all source audio, so generated music, voice changes and extra words cannot leak into the master. Music is currently off; an approved master track is required before adding it centrally. Both picture generation and synchronization are included in preflight cost estimates and the per-video/provider budgets. A sync failure retains the source and reports the failed stage; it never triggers a full reshoot or an automatic paid retry. Revisions preserve identity, set and audio assets; changed dialogue on an unchanged shot needs only new speech/sync, not a new base video. Existing completed legacy videos remain unchanged until an explicit revision request.

The marketing Storage bucket must allow `audio/mpeg` as well as PNG, JPEG, WebP and MP4 so reusable narration can be checkpointed. After provisioning an existing bucket, run `node scripts/allow-marketing-narration.mjs` with the worker environment. It preserves the existing bucket settings, adds MP3 support, verifies a tiny synthetic MP3 upload/download and removes the probe. Assembly errors record `failed` plus the saved sources, rather than leaving `generating` after the worker stops.

```powershell
cd marketing
npm install
npm test
npm run check
```
