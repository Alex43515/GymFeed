# Coach calendar and diary actions

The previous workout flow used English/regional substring matching and a
separate JSON compiler only after those keywords matched. Plain confirmations
re-created a proposal rather than executing it, and meals had no action path.

The new production `ask` path uses one strict JSON-schema envelope for every
language. Its intents distinguish conversation, essential clarification,
proposal, approval of an earlier text-only plan, confirmation and cancellation.
The app validates dated workouts, explicit sets and planned meal nutrition
before storing anything. Missing reps, weights and portions use conservative
defaults in the reviewable proposal rather than another question.

The payload is stored in `ai_coach_plan_actions`, separate from response prose.
UI buttons depend on persisted pending state. A button or a written confirmation
executes the same payload; the confirmation path never generates a new plan.
The app creates receipts after applying the action, so model text cannot claim
a successful write. One local import marker per action preserves subsequent
routine edits and makes import retries harmless. Train re-imports implemented
cloud actions when opened on another device.

Meal Diary reads implemented dated meals as **planned**, alongside starter
meals. Its eaten calorie totals remain unchanged until the athlete logs a meal.
Recipes and macros are available through the existing planned-meal detail UI.

Proposal replacement and terminal status transitions are transactional RPCs
with invoker security and owner RLS. Repeated confirmation returns the same
implemented action. Superseded or skipped actions cannot be reopened. A stale
chat confirmation also checks the plan id visible to that session. Clearing
chat skips any pending action, while implemented calendar/diary entries remain.

Legacy workout metadata is still decoded for existing conversations. The old
English/regional helper methods remain for compatibility tests; production
`ask` does not use them to detect writes. Full proposal data is supplied to the
model as context, including when recovering a prior text-only plan.

## Research

- [OpenAI Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs): strict schema adherence is stronger than JSON mode; refusals and truncation still need handling.
- [OpenAI function calling](https://developers.openai.com/api/docs/guides/function-calling): application code owns tool execution and receives structured arguments.
- [Gemini generation config](https://ai.google.dev/api/generate-content#v1beta.GenerationConfig): the fallback supports `responseJsonSchema`.
- [Supabase database functions](https://supabase.com/docs/guides/database/functions): transactional state changes and invoker security.

Schema adherence does not guarantee perfect semantic interpretation in every
possible language or situation. Deterministic validation and persisted status
protect execution even when a provider fails. An invalid output gets one
bounded repair attempt; no invalid payload is executed.

## Verification

Run the focused Flutter tests:

```sh
flutter test test/coach_plan_actions_test.dart test/ai_coach_test.dart test/nutrition_diary_test.dart test/workout_routine_flow_test.dart
```

The opt-in live evaluation uses synthetic athlete data and performs no app
database writes. Provide `GYMFEED_EVAL_OPENAI_KEY` in the process environment:

```sh
flutter test test/coach_plan_live_eval_test.dart --dart-define=RUN_LIVE_COACH_EVAL=true
```

It covers requests and confirmations in English, Serbian Latin/Cyrillic,
Spanish, French, German, Portuguese, Russian, Arabic, Hindi, Chinese and
Japanese; also negative approval, date changes, repeat confirmation, a
seven-day batch and approval of a prior text-only plan. Fixed local test date:
2026-10-12. This evaluates semantics separately from the deterministic executor
and calendar/diary widget tests.
