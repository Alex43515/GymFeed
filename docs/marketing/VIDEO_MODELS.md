# Video model selection

Reviewed: 2026-11-01.

New generations use `alibaba/wan-3.0/text-to-video` and
`alibaba/wan-3.0/reference-to-video` at 1080p. Wan 3.0 leads the current
Artificial Analysis text-to-video-with-audio overall ranking; that ranking
does not establish a winner for GymFeed's specific scenes.

Wan's fal schema uses integer `duration`, `audio` and `reference_image_urls`.
The adapter rounds source duration up so the generated source covers the
approved retained cut. Prompt expansion is disabled to preserve directed copy.
The published 1080p rate is $0.20 per generated second, including reference
generation without input video. Retries, casting images and QA cost extra.

Seedance 2.0 is also supported with its own schema: `image_urls`, string
duration (4-15 seconds), `generate_audio`, and `@Image1` reference tokens.
To select it, change both FAL model endpoints, resolution and the matching
`FAL_VIDEO_USD_PER_SECOND` estimate together. It is not an automatic fallback.
At 720p, fal currently lists approximately $0.3034/s for text-to-video and
$0.3024/s for reference-to-video; use the higher rate for a conservative reserve.

Existing queued scene records retain their stored model for status/result
polling. Failed or low-quality scenes follow the existing bounded retry and
review flow. A model change does not automatically regenerate old assets.

Sources:
- https://artificialanalysis.ai/video/leaderboards/text-to-video
- https://fal.ai/models/alibaba/wan-3.0/text-to-video
- https://fal.ai/models/alibaba/wan-3.0/reference-to-video/api
- https://fal.ai/models/bytedance/seedance-2.0/reference-to-video/api
- https://fal.ai/learn/tools/how-to-use-seedance-2-0

## Scene repair

`FAL_SCENE_EDIT_ENABLED=true` enables one editing attempt per generated scene,
within the existing scene attempt limit. It uses the dedicated
`fal-ai/wan/v2.7/edit-video` endpoint with `audio_setting=origin`, rather than
treating Wan 3 reference-to-video as an instruction editing endpoint.
The 1080p rate is $0.15 per output second; reservations round input duration up.

Only saved generated scenes with score >=70, scene-match >=85, concrete QA fixes
and 2-10 second source duration qualify. Incorrect speech and missing actions
go to regeneration. Edited outputs follow the normal download, audio check,
transcription, visual QA and final review flow. App recordings and UI are added
by the compositor after this step. Original clips remain in scene history.

API: https://fal.ai/models/fal-ai/wan/v2.7/edit-video/api
