# Messaging UX update — 2026-11-04

## Assessment and baseline

Implemented in the existing Flutter/Riverpod/go_router/Dio frontend. The local backend configuration was inspected and uses FastAPI, PostgreSQL/Psycopg and server-side Gemini. No backend route, database, authentication protocol, prompt or dependency was replaced.

Existing uncommitted work was preserved; relevant pre-change files were backed up under ignored `work/messaging-before`. No AGENTS.md was found in the searched project source. Reviewed the architecture, API/data/authentication, previous UX/recovery and iOS guides, and traced ChatScreen → AppController.send → ApiResearchRepository.chatWithId → authenticated backend job/history/persistence. The existing request ID, cache, assignment and suggestion-decision paths were retained.

Baseline analyzer: clean. Selected existing baseline tests: 25 passed, 1 skipped. Earlier 202-test totals are historical; the final executed suite for this update is below. Baseline gaps identified in source and UI: large explanations/errors in the timeline, agent-only transient draft keys, drafts lost on navigation, no conversation previews/search, and no explicit whole-message copy menu. No baseline cross-account leak was demonstrated; explicit account scoping was added to prevent that risk.

## Implemented

| Area | Current behavior |
|---|---|
| Header | Compact avatar/name/mode; authorized one-tap agent chips remain pinned in normal layouts. The information icon opens conversation, assignment, privacy/mode explanations and Settings. Required consent routing remains unchanged. |
| Task context | One compact task row opens General conversation, current tasks and archived task conversations. Current selection is checked. Deleted-task histories remain read-only. |
| Picker/search | Latest loaded preview/date; search matches loaded titles/messages for the current authenticated account and agent. No backend search endpoint or complete-history claim. Archived task titles remain generic when unavailable. |
| Composer | Rounded, initially one-line input; Japanese hints stay on one line. Typed text expands up to four lines, fewer on short views. Empty/busy/recovery states disable sending; existing controller guards still prevent duplicates. |
| Drafts | RAM memory keyed by backend/account, agent and conversation. Navigation and authorized DEV switches retain separate drafts. Explicit disconnect clears the departing account's draft/scroll entries. Quick-action sends do not erase unrelated typed drafts. A rejected send before message creation restores the draft. |
| Timeline | Readable bubble widths, actual local date/time separators and acknowledgement labels. No fake human presence or delivered/read receipt. Empty history has a neutral empty state rather than an invented agent turn. |
| Scrolling | New conversations initially open at latest content; navigation restores offset. Reading upward during a delayed reply preserves position and offers Show latest. |
| Failures | Small message-level Couldn't send / Try again, with Edit/Cancel/Details in Message options. Edit/cancel applies only to existing failed attempts, retaining their records. Authentication rejection has persistent sign-in status and direct recovery; message retry never renews credentials. |
| Error meaning | Optional frontend AppFailure.code distinguishes known network, timeout, rate-limit/busy, service/provider, unresolved request and malformed response cases. Validation/assignment errors retain their actual explanation. Unknown errors remain generic. No transport retry policy or wire schema changed. |
| Suggestions | Existing single task-aware card, review/dismiss and approval services reused. Explanations/priority/next-step/persona copy remain available by expanding the card; concise task provenance stays visible. No automatic task mutation. |
| Copy | Long-press/secondary-click opens Copy message; a screen-reader custom action is also provided. Copies exact stored text without editing history. |
| EN/JA | New controls and errors localized through ARBs/generated getters. Stored tasks/chats remain raw. Fixed an existing canonical URL-error translation mismatch without changing URL security policy. |

Long explanations and repeated footer notices moved to information/details panels; mode remains visible in the header/app bar. Chat synchronization errors are shown in its scrolling content and information panel rather than a space-consuming global banner. Other screens retain their existing banners. On very short landscape/large-text keyboard views, the header/context become scrollable and the composer uses one line so messages and input remain reachable.

## Data, security and limitations

New `lib/app/chat_memory.dart` is an in-memory Riverpod store, not a new database. Unsent composer drafts and reading positions survive navigation **only while the app process remains alive**; restart clears them. Failed/sending message attempts continue using the existing durable, account-owned pending cache. No general offline task synchronization was added. Another account cannot see a draft simply because it uses the same agent or task ID.

No new endpoint, persisted field, migration or refresh token. AppFailure.code is optional presentation metadata and is not persisted. After restart an older failed attempt may therefore have generic failure details; retry still uses its original ID/language and existing status recovery. Malformed/lost responses are not proof that the server failed to commit. Explicit sign-in is still needed for expired/revoked credentials. No passwords were requested, reset or reprovisioned.

Search is local to currently loaded history; there is no pagination/comprehensive server search. It does not log search terms. Copy is an explicit OS clipboard action, not a new analytics/export event. Existing device caches still have the privacy limitations described in DATA_AND_SYNC.md; this work does not certify production security.

## Research interpretation

Self-Agent and Friend-Agent use the same layout, utilities, task actions and error handling. Their backend prompts were unchanged. Standard-control routing/API restrictions remain intact. No new notifications, intervention schedules, measurement instruments, read receipts or engagement-pressure features were added. Development feedback/reduced-support flags remain off by default.

These UI changes can affect exposure and task initiation, so use a consistent build across study arms and record the build version. `suggestion_displayed` still means the app observed an intersecting visible suggestion card, not proof that its expanded explanation was read. Initial scrolling now often exposes that card immediately. Existing stable suggestion IDs prevent duplicate display/open/dismiss events. Expanding explanations is not newly logged. The neutral empty-history UI and collapsed explanations are UX exposure changes, not a versioned modification of the model's persona prompt. No claim of reduced procrastination or improved user performance follows from these tests.

## Actual verification

| Check | Result |
|---|---|
| Baseline analyzer / selected tests | PASS; 25 tests passed, 1 skipped |
| Final changed-file formatting, localization generation, analyzer | PASS; no analyzer issues |
| Full Flutter regression | PASS: 211 passed, 14 skipped |
| Synthetic EN/JA rendered screenshots | PASS: opt-in visual test executed; images visually inspected |
| Real Dio → FastAPI → disposable PostgreSQL schema contracts | PASS: 6 tests across all three conditions, mock AI |
| Android build | PASS: current-source Flutter compile followed by verified Gradle packaging |
| API 35 emulator | Install Success, launch Status ok; installed APK hash matches receipt; Chat information/context and searchable picker observed; a synthetic search query produced the native empty-result state |
| Real authenticated chat on retained emulator account | BLOCKED: valid sign-in required; no credentials entered or account reset |
| Live Gemini evaluation | NOT TESTED; no live model requests made |
| iOS native compilation/device behavior | NOT TESTED on Windows |
| Physical notification delivery, screen reader/native clipboard, production load | NOT TESTED |
| Formative usability/clinical efficacy | NOT TESTED |

New regressions cover draft navigation/conversation/agent isolation, authorized live-account switching/logout cleanup, duplicate sends, failed-message editing, loaded-history search, exact Unicode copying, delayed-reply reading/offset restoration, Japanese keyboard layouts at 200% text on 320×568 and 844×390, and safe HTTP error categories. Existing regression covers authentication/expiry, stale-account guards, approval/version checks, condition routing, legacy records and reminders.

During development, tests caught a missing semantics import, a reply-scroll direction bug, short-keyboard overflow, and a missing Material ancestor for the new task row. All were fixed before the final pass. Test finders were updated for compact failure menus, timestamps within acknowledgements and information-button navigation; explicit message/approval/event assertions were retained. Existing suggestion visibility assertions were updated because opening at the latest content actually makes the card visible.

Executed commands: flutter analyze --no-pub; flutter test --no-pub --reporter json; targeted messaging/account tests; opt-in CAPTURE_MESSAGING=true render with --update-goldens; opt-in RUN_HTTP_INTEGRATION=true; Dart format and localization/catalog generation; tool/build-apk.ps1; ADB install/start/UI inspection/hash comparison. Backend application code was unchanged, so its full suite/lint was not rerun. HTTP fixtures used isolated synthetic PostgreSQL records and were cleaned afterward. Existing participant/task/chat records were not edited; native checks were read-only navigation.

APK: `outputs/frontend/SmallSteps-debug.apk`, SHA-256 `610128BCF8F80737888254335D203504647134E9C45C30493D30F57F284BB919`. Receipt: ignored `.tool-state/verified-android-build.json`. Logs: frontend `.tool-state/messaging-*`; backend `.tmp/messaging-*`. Rendered synthetic previews: ignored `outputs/frontend/design-review/messaging-en.png` and `messaging-ja.png`. Existing Gradle deprecation warnings remain.

## Main files

- `outputs/frontend/lib/features/chat.dart`: shared screen, menus, context, reading and recovery.
- `outputs/frontend/lib/features/chat_widgets.dart`: picker, date separators and copyable bubbles.
- `outputs/frontend/lib/app/chat_memory.dart`: scoped transient drafts/offsets and disconnect cleanup.
- `outputs/frontend/lib/features/agent_actions.dart`: compact expandable existing suggestion card.
- `outputs/frontend/lib/data/repository.dart`: optional safe failure categories; transport unchanged.
- `outputs/frontend/lib/app/app.dart`: Chat handles its own errors; other screen banners preserved.
- `outputs/frontend/lib/app/state.dart`: existing URL-error text aligned with localization catalog.
- EN/JA ARBs/generated localization and catalog; new messaging tests and affected existing UI/account tests.

## Try it and formative test

The local backend and emulator were launched and the new APK installed. Sign in with valid existing credentials for connected AI. In Chat: tap the task/context row, search loaded conversations, type a draft and navigate away/back, switch permitted agents, long-press a message to copy, and use More actions or Review suggestion. Saved-on-server labels require backend acknowledgement; local demos explicitly identify their mode.

For 3–5 consenting formative testers using synthetic accounts, ask them to: identify the active agent/mode; find a task conversation; leave and recover a draft; send and recover a failed message; read older text while a delayed reply arrives; find Show latest; review/dismiss a task suggestion without changing it; copy Japanese text; and recover an expired session. Repeat core tasks in EN/JA, large text and with keyboard open. Record success, wrong taps, hesitation and reported burden, not inferred procrastination reduction. Native VoiceOver/TalkBack, full iPhone testing and broader Japanese linguistic review remain necessary before participant deployment.
