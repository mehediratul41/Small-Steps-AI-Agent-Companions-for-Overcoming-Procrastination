# Small Steps: QA follow-up and fixes

Completed **2026-10-28, Asia/Tokyo**, following “Fix everything by yourself.” This supersedes the affected statuses in the earlier QA report; the original findings remain as historical evidence.

## Current result

**The current Android debug APK and web release bundle were built successfully.** The application source passes **115 Flutter tests**, **1 separate participant-mode test**, **62 backend tests**, Flutter analysis, Ruff checks/format and pip check. Three optional tests remain skipped in the default Flutter suite (participant-mode run separately; live Gemini and preview capture not enabled).

The frontend remains a **fictional-data development prototype, not a participant-ready research release**. No production database/participant was modified, real-user notification sent, live model called, dependency upgraded, or existing backend service deployed/restarted. The new backend routes require restarting the development server before using them from a newly installed APK; this review tested them against temporary synthetic databases.

## Working artifacts and reproduction

- **APK:** `outputs/frontend/SmallSteps-debug.apk` — debug signing, minimum Android API 24.
- APK SHA-256: `655A8F7466FAF9E0C37DEB155CA50D176E93DD923792F131B346B68FAA5B497C`.
- Build receipt: `outputs/frontend/.tool-state/verified-android-build.json` records UTC build time, source fingerprint and packaged kernel hash.
- Double-click `outputs/frontend/BUILD-APK.cmd` or run `./tool/build-apk.ps1` in the frontend terminal. It now invokes `tool/build-android-verified.ps1`.
- **Web bundle:** `work/qa-web-build`; demo preview at **http://127.0.0.1:8890**. This is an independent local static test preview, not a public deployment or an update to the existing backend. Connecting from this origin needs it to be explicitly allowed by the backend CORS configuration; demo mode does not require a backend.
- The web release was built with a literal PowerShell argument array and an absolute output path, using the existing Flutter wrapper. Five HTTP asset checks returned 200: index, bootstrap, main JavaScript, manifest and bundled Inter font. This is an HTTP smoke check, not a claim of a complete browser runtime test.

### Why the Windows build now works

Gradle's captured Flutter child continued exiting with native `0xC0000008`. The verified Android script compiles the **current** Flutter debug sources in the terminal first, then runs Gradle packaging with that already-completed compilation task excluded. It fails immediately if compilation or packaging fails, verifies the APK's `assets/flutter_assets/kernel_blob.bin` hash equals the freshly compiled file, and verifies sources did not change during the build before delivering the APK. Thus no failed compilation or old binary is silently treated as success.

PowerShell Flutter definitions are passed as literal array entries; an unquoted definition initially truncated `lib/main.dart` to `lib/main`, which was fixed. Absolute web output also avoids the observed relative-path shader-write failure. Captured, nested and concurrent Flutter invocations remain unreliable on this host; some retries still exited nonzero, including an experimental web wrapper which was removed. Successful final commands and artifact checks are distinguished from those failures. No SDK upgrade, system ownership change or global security change was made.

## Technical changes

| Previous QA issue | Work completed | Verification / limits |
|---|---|---|
| R05: Android/web builds blocked | Verified Android build workflow, updated existing launcher, successful current web release. | Final Gradle packaging exit 0; APK/source/kernel receipt. Web build exit 0 and HTTP assets 200. Conventional Gradle-captured Flutter command still has a host problem. |
| R02: connected reminders disabled | Native connected accounts now have separate opt-in/quiet-hour settings. Every condition gets the same neutral, silent, inexact reminder behavior. | Self/Friend/control regression tests pass. Browser remains unsupported; no server push was introduced. Physical delivery remains unverified. |
| Cross-account notification access | Payloads include server/account scope without token or task content. Local-demo payloads cannot open account tasks. Disconnect clears the outgoing schedule; each account starts with its own opt-in state. | Controller and payload tests; cold notification waits for matching authentication before opening. Old callbacks cannot select another account's task. |
| Notification identity/reliability | Stable scoped notification IDs survive ordering changes; cancellation includes obsolete displayed notifications. Connected timestamps represent instants; demo retains wall-clock planning. | ID, Unicode/malformed payload, account timing, existing cancellation/quiet-hour tests pass. Collision resolution within a plan is deterministic. Travel/terminated native behavior still requires observation. |
| R03: missing notification evidence | Added `notification_schedule_registered` and `notification_opened` client reports with explicit source, time, condition and `deliveryConfirmed=false`. Same task/condition/scheduled instant registration is deduplicated. | Repeat-refresh and all-condition tests pass. A successful schedule request is not a delivered notification. No sent/delivered/ignored status is invented. |
| R06: no development-data erasure | Confirmed self-service erasure endpoint and frontend action delete owned task/record/AI-job data, clear profile/acknowledgment and revoke the token. UI explains an inactive account marker remains and backups/exports are excluded. | All three conditions tested; other account intact; old token cannot read/write afterward; no actual account was erased by QA. This is logical development-database erasure, not secure media sanitization or approved research withdrawal. |
| Credential/write races around erasure | Owned database transactions recheck active/current credentials and assignment; row locks used where supported. Erasure serializes with AI work. | SQLite auth/isolation/erasure suite passes. PostgreSQL remains untested. Requests already in flight can complete before erasure acquires its lock; this is not immediate provider cancellation. |
| Local cached data retained indefinitely | Added confirmed “Forget saved development accounts on this device” action when disconnected. It deletes connected pending reports/messages/timers/preferences while retaining local demo, unrelated preferences and server records. | Cache-prefix isolation test passes. User must explicitly acknowledge loss of unsynchronized reports. Storage is still unencrypted development storage. |
| R07: partial client export | Connected export action now fetches the full owned server export plus separately labeled pending device reports. Preview is labeled partial. Server adds current protocol/provider/model/prompt provenance without rewriting historical record provenance. | Server audit/soft-deleted task/provenance tests; client owner validation; receipt validation before erasure; controller cleanup/export tests pass. No claim of anonymization. |
| Model misinformation after enabling reminders | Shared prompt is now **small-steps-agents-v3**: only supported phones with opt-in/OS permission can deliver; browser cannot; the model cannot change settings or claim actions/delivery. Scripted responses and behavioral criteria updated. | 28 mocked SDK transport cases pass. Actual live behavior is still NOT TESTED. Personality strings, model parameters and shared capabilities remain matched. |

Updated sources include frontend state/router/reminder planner and service, settings/connection/data export UI, typed repository methods, backend schema/owned transactions/erasure/export/shared prompt, documentation and regression tests. No schema-table migration was needed. A pre-follow-up source snapshot is retained in `work/followup-before` without credentials or database content.

### Intermediate defects found and corrected during implementation

- Connected reminder tests initially lacked timezone initialization in their isolated fake; corrected the fixture and verified all three conditions.
- Cold notification intent was cleared by a later refresh before opening; retained until acknowledgment.
- Cold notification reporting initially happened during account transition and was suppressed; replay now waits for completed matching authentication, then records exactly one opening.
- New async erasure/export UI uses standard error feedback; erasure requires a validated server receipt before removing device data. Invalid/mismatched exports are rejected before copying.

## Executed verification

| Command / check | Result |
|---|---|
| `flutter analyze --no-pub` | PASS: no issues, exit 0, 14.6s after final source formatting. |
| `dart format lib test` and targeted lint fixes | 37 files formatted; no unrelated fixes/dependency upgrade. |
| `flutter test --no-pub --reporter expanded --file-reporter=json:.tool-state/followup-final-flutter.jsonl` | PASS: **115 passed, 3 skipped**, runner success true, zero error events. |
| Participant test with `RESEARCHER_DEMO=false` | PASS: **1 test**, runner success true. Closed enrollment/assignment guard preserved. |
| Backend pytest, temporary `.tmp/followup-final` | PASS: **62 tests**, one existing upstream Starlette/httpx warning, exit 0. |
| Ruff check/format; pip check | PASS: 13 Python files formatted; no broken requirements. |
| Verified Android build launcher | PASS: compilation and Gradle packaging exit 0; hash-checked APK delivered. |
| Final web release | PASS: build exit 0; 5 required assets HTTP 200. Earlier failed invocations are not counted as passes. |
| Known Gemini key scan | PASS in bounded scope: zero exact configured-key matches in 66 source/asset/web files and the current delivered APK ZIP contents. No key value printed. This is not exhaustive secret discovery. |
| API35 hardware emulator | BLOCKED: exits 1, reports unavailable CPU acceleration despite detecting Hyper-V/WHP. No online ADB device. |
| API28 software fallback | BLOCKED: exits before an online ADB device. No installation/runtime/delivery claim. |
| iOS | BLOCKED: no macOS/Xcode/iPhone here. |
| Live Gemini behavior | NOT TESTED: mock-only QA; human ratings remain unset. |

## Remaining release gates

1. **Device runtime:** Windows accelerator access or a dedicated Android device is still required to observe launch, permissions, reboot/lock/terminated delivery and taps. macOS/Xcode/iPhone is required for iOS. No helper fabricated an emulator success or changed Windows features/rebooted the PC.
2. **Study authorization:** real enrollment remains closed. An approved consent/withdrawal/retention process, researcher contact, baseline instruments and assignment procedure must be supplied by the research team. The development erasure tool does not approve or replace those policies.
3. **Behavioral evaluation:** approve/freeze **prompt v3** and pinned provider/model; human-rate repeated synthetic live responses. This is a common intervention change across both roles; never silently pool v1/v2/v3 data. Gemini remains the actual provider; no OpenAI migration was silently made.
4. **Measurement:** registration/opening are now instrumented, but actual delivery and ignored status require appropriate evidence and an approved observation window. Time-to-start requires approved anchors, missing-event/censoring/clock rules; no fabricated latency/outcome was added. See `RESEARCH_EVENT_CONTRACT.md`.
5. **Deployment scope:** this remains a single-worker local SQLite prototype with unencrypted development caches and debug signing. PostgreSQL/load/migrations, full offline editing, Japanese localization, formal screen-reader/full contrast testing and secure production operation remain outside verified capability. Complete server exports are now available, but data lifecycle/pagination/scaling still need a deployment design.

These remaining gates need unavailable hardware/services or research decisions. They cannot truthfully be declared fixed by passing mocks or writing an approval flag. Use the original QA report's physical Android/iOS checklist with these updates: connected reminders are now explicitly opt-in, logout removes the outgoing schedule, and cold account taps require matching authentication.

## Evidence links

- [Current APK](<C:/Users/mehed/Documents/Codex/2026-10-26/master-development-prompt-flutter-frontend-for/outputs/frontend/SmallSteps-debug.apk>)
- [Verified Android build receipt](<C:/Users/mehed/Documents/Codex/2026-10-26/master-development-prompt-flutter-frontend-for/outputs/frontend/.tool-state/verified-android-build.json>)
- [Final Flutter results](<C:/Users/mehed/Documents/Codex/2026-10-26/master-development-prompt-flutter-frontend-for/outputs/frontend/.tool-state/followup-final-flutter.jsonl>)
- [Participant guard results](<C:/Users/mehed/Documents/Codex/2026-10-26/master-development-prompt-flutter-frontend-for/outputs/frontend/.tool-state/followup-participant.jsonl>)
- [Final backend tests](<C:/Users/mehed/Documents/Codex/2026-10-26/master-development-prompt-flutter-frontend-for/outputs/backend/.tmp/followup-final.log>)
- [Web build and HTTP evidence](<C:/Users/mehed/Documents/Codex/2026-10-26/master-development-prompt-flutter-frontend-for/work/followup-web-receipt.json>)
- [Current artifact secret scan](<C:/Users/mehed/Documents/Codex/2026-10-26/master-development-prompt-flutter-frontend-for/work/followup-secret-scan.json>)
- [Research event definitions](<C:/Users/mehed/Documents/Codex/2026-10-26/master-development-prompt-flutter-frontend-for/RESEARCH_EVENT_CONTRACT.md>)
- [Android build script](<C:/Users/mehed/Documents/Codex/2026-10-26/master-development-prompt-flutter-frontend-for/outputs/frontend/tool/build-android-verified.ps1>)
