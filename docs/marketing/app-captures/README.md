# Verified product recordings

Place short MP4 recordings from a clean demo account here. Record actual interactions, not an animation of a screenshot. Keep names, email addresses, notifications and private fitness information out of frame. Do not use fabricated workout completions as product proof.

After reviewing the footage, add a manifest entry with `id`, `filename`, `feature`, `description`, `duration_seconds`, `recorded_interactions` (an array of the actions visible in this clip), `verified: true`, `marketing_safe: true`, and the file's `sha256`. Use PowerShell `Get-FileHash -Algorithm SHA256` to obtain the hash. Changing the recording requires re-verification and a new hash.

Useful first recording: open today's Train routine, inspect sets/reps/kg, start the workout and mark a real demo set complete. Other useful recordings: review an estimated food scan and log it to Nutrition diary, or confirm an AI Coach proposal and show the resulting dated Train entry.

The CMO can propose a recording that is not yet available, but production stops before any media-provider spending until every referenced capture has been verified. Screenshot assets remain in the existing screenshots folder.
