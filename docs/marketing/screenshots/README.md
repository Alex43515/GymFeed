# GymFeed current-build screenshot library

This directory contains the raw 29 August 2026 captures plus a curated semantic
catalog for the marketing worker.

- Raw timestamp/WhatsApp filenames remain unchanged as the source archive.
- `curated/` contains feature-named copies selected from that archive.
- `manifest.json` is the source of truth for feature meaning, approved claims,
  and public-marketing eligibility.
- Only entries with `marketing_safe: true` are exposed to the CMO or accepted by
  the renderer. A file merely existing in this directory does not make it
  approved marketing evidence.

Do not set `marketing_safe: true` for screens containing real names, profile
photos, messages, user-generated media, or body measurements without explicit
public-use permission or a sanitized replacement capture.
