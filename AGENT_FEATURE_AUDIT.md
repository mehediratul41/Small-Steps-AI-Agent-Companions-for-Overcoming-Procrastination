# Small Steps: agent integration audit and implementation

**Later UX update, 2026-10-30:** [One-tap agent switch](ONE_TAP_AGENT_SWITCH.md) pins the selector above chat. The current APK has a newer hash; 152 Flutter tests pass, and installation, launch and switching both directions were observed on `emulator-5554`. Earlier build hashes/runtime statuses below are retained as the preceding audit snapshot. Notification delivery, live AI and iOS remain unverified.

2026-10-30, Asia/Tokyo. Existing application extended in place; no architecture replacement or dependency upgrade. Source snapshots are in `work/agent-integration-before`. No Git repository or AGENTS.md was found. No production records, credentials, active backend service or live AI account were modified.

## A. Audit findings

| Feature before this change | Traced implementation and gap |
|---|---|
| Personas/chat | Implemented: Flutter → Riverpod → repository → authenticated FastAPI → provider → owned SQLAlchemy records → visible reply. Separate condition/task histories, retries and idempotency existed. **Actual provider is Gemini via google-genai, not OpenAI.** Live response quality was not verified. |
| Switching | Functional in disconnected Researcher Demo settings; absent from chat. Backend assignments deliberately immutable to clients. |
| Task breakdown | Integrated: editable proposals, explicit accept/reject, version checks and persistence. Backend breakdown prompt did not receive the assigned persona. Rejection could be tapped before generation completed, falsely logging a decision on an unseen suggestion. |
| Task correction | Missing: manual task editing existed, but no AI correction proposal/approval flow. |
| Contextual actions | Task-linked quick chips existed; plain chat responses could not execute actions. No contextual review cards or exposure/dismissal records. |
| Reminders | Integrated local one-shot manual reminders, permissions, timezone/quiet hours, account scope, refresh/cancel and guarded task navigation. All copy neutral; no planned-start/deadline categories, daily cap or cooldown. Device delivery unverified. No server push. |
| Persistence/data | SharedPreferences for demo/account caches; backend SQLAlchemy with development SQLite, PostgreSQL configurable. Owned task versions and proposal records already existed. No separate task database was needed. |

Baseline: backend **62 tests passed**. Flutter runner reported **132 passed, 4 skipped**, but its wrapper returned nonzero; that baseline command is not represented as a clean process pass. Direct Dart baseline analysis completed with no issues. Existing Windows Flutter-launch failures were also observed before edits.

## B. Changes made

- Added a visible chat selector, preserving the existing switching method, separate histories and per-agent unsent composer drafts. Demo switches append `agent_switched`. In-flight chat/proposal requests prevent assignment changes.
- Extended `/api/tasks/refine` with optional `mode: correction` (default remains breakdown). Correction returns structured, validated title/description/minutes/reason fields. Existing proposal accept/reject endpoints now support that mode. Approval is owned, single-decision and task-version checked; dates, priorities, completion and subtasks cannot be changed through correction. Edited proposals require explicit Accept.
- Both providers implement correction; Gemini uses its existing official SDK, timeout/error handling and structured schema. The server selects persona. Breakdown now receives that persona too. Scripted mocks remain clearly labeled.
- Added bounded, account-owned task summaries and recent suggestion/recovery decisions to agent context. Selected task details remain available. Context coverage is explicitly partial: at most 50 task summaries and 100 recent events, with at most 10 relevant decisions. No fabricated memory or cross-account data.
- Added task-aware review cards for breakdown, correction, focus, reminders, replanning, progress/status and notification preferences. Next-task queries use current active tasks, stated priority and schedule. These cards are **transparent application rules**, not executable model output. Model prose never mutates task data. The actual task controls still require user choices/approval.
- Fixed rejection while loading and duplicate/invalid rejection logging. Closing during loading does not mean rejecting or viewing the eventual proposal.
- Added notification policy controls and opted-in persona templates through the existing planner/scheduler. New category/wording settings are off by default. A daily cap of 3 and 60-minute slot cooldown are the new defaults; saved old reminder times are retained, but some may now be suppressed by these limits. This is a material policy change, not a silent task edit.
- Fixed new dropdown overflow at 200% text scale. Reminder status lists all scheduled categories for a task and explains limits when no slot is scheduled.

## C. Agent switching

**Yes, chat can now switch between Self-Agent and Friend-Agent in disconnected Researcher Demo mode.** It changes the actual controller condition/repository persona and the displayed history, not merely the avatar. Demo selection persists. Unsent drafts stay separate while the chat is open.

**Connected accounts cannot switch assignments.** Both selector choices are disabled and the assignment lock is explained. API requests do not submit a client-selected condition; the authenticated participant record selects the provider prompt. Control accounts cannot navigate into chat/refinement/correction. No client-accessible assignment-changing backend route was added. Trying both live personas requires separately provisioned synthetic accounts, as before.

## D. Suggestions users can actually access

- **Breakdown:** Chat → Break it down, a relevant chat review card, or task detail. Edit steps, Accept or Reject; accepted steps append to the existing task.
- **Correction:** Chat → Correct this task, a relevant review card, or task detail → Review task correction. Review original/proposed text and estimate; edit, Accept or Reject. Stale, malformed, duplicate, completed/control-context proposals are rejected safely by the applicable layers.
- **Contextual next actions:** ask “What should I do now?”, “Which task is most important?”, “Break down this task”, “Correct this task”, “Reschedule my unfinished work”, or “Remind me later”. The card opens the existing approval/control flow. Dismiss hides that versioned recommendation and records the decision. Requests to stop reminders open preferences without claiming settings were changed. Stop requests do not trigger another motivational action card.
- Chat remains task-scoped, including completed/archived history. General conversation can use the owned task summaries on the backend. Rule-based action matching is English-oriented, not a claim of full multilingual intent recognition.

Correction and breakdown are AI-generated only when connected to a configured real provider; local/HTTP mock tests use scripted proposals. Live schedule-conflict reasoning, personalization and psychological quality still need evaluation. The mock service does not establish intelligent reasoning quality.

## E. Notifications

| Type | Implementation |
|---|---|
| Manual task reminder | Existing chosen reminder time; now shares frequency policy. |
| Planned-start reminder | Explicit opt-in; scheduled at planned start only while unstarted, active and incomplete. |
| Deadline reminder | Explicit opt-in; scheduled **at the deadline**, not an invented lead time. Quiet hours may delay it. |
| Unstarted/postponement/breakdown/recovery/daily planning/progress support | Existing task controls or new in-app review actions where applicable. **No automatic background notifications for these categories were enabled.** There is no approved observation window for ignored reminders or evidence that repeated unsolicited nudges are appropriate. |

Settings → Task reminders → **Reminder types & limits** controls category opt-ins, maximum slots/day, minimum minutes between slots and optional assigned-agent wording. Opt-in/OS permission are still required. Self/Friend use different fixed gentle templates with the same slots/capabilities; control stays neutral. No network/model call occurs when an OS notification fires. Task titles/content and credentials are omitted from lock-screen messages/payloads.

Planner policy: exclude done/paused/expired tasks; deduplicate coincident times on a task; apply quiet hours; apply cooldown and calendar-day cap across all types; retain conservative past reserved slots across refresh/restart/agent switches. Future cancelled slots do not consume the budget. The native queue still caps at 60, with refill on app reconciliation. Policy may suppress a time rather than repeatedly defer it. Phone inexact scheduling can delay or bunch actual deliveries; these are limits on **requested slots**, not guaranteed delivery timing.

Task edits, completion, deletion, opt-out, resume and demo persona changes reconcile schedules. Stable category IDs prevent both personas creating parallel alerts. Native taps include category and account scope and open the existing guarded task route; they do not start work. Snoozing/replanning is available after opening the task. OS swipes are not labeled as observed dismissals/ignored reminders.

## Research compatibility and logging

Existing chat system prompt remains `small-steps-agents-v3`; augmented task context and correction/breakdown additions carry **`small-steps-task-support-v1`** provenance on server records. Review-card events carry **`task-support-ui-v1`**. Reminder registrations carry **`reminders-v2`**, category, wording, requested/scheduled UTC and timezone. Do not pool earlier context/notification policies as identical interventions.

New client events: `agent_switched` (demo only), `correction_proposed/accepted/rejected`, `suggestion_displayed/opened/dismissed`. Existing refinement decisions, task start/completion/recovery and notification registration/open events are reused. Proposal and action IDs link decisions; task versions, assignment and timestamps remain attached. Server mutation audits and client reports are separate records, not independent double counts.

`suggestion_displayed` for a chat card means a nonzero part of the card intersected its scroll viewport on the current route. It does not prove attention, reading, acceptance or effectiveness. A correction/breakdown sheet records display only after rendering on its current route. Off-screen builds and dismissed loading routes are not exposure. Opening review is distinct from accepting a change. Schedule registrations use the most recent category/time/wording/policy receipt to suppress unchanged refresh reports while retaining relevant changes. They remain incomplete cancellation/delivery traces.

Task initiation after an intervention is available as raw timestamps/IDs for later analysis; **no causal attribution or invented time-to-start score was introduced**. Scheduled is not sent/delivered/seen/ignored. Freeze and approve UI, templates, defaults, persona prompts, assignment procedure and observation rules before a study. Real participant enrollment remains closed.

## F. Executed checks

| Executed command/check | Result |
|---|---|
| Final `flutter test --no-pub --file-reporter=json:.tool-state/agent-integration-final.jsonl` | **PASS: 151 tests, 5 optional skips**, process exit 0, runner success true, zero error events. Nineteen new default tests; existing tests retained. |
| Participant guard with `RESEARCHER_DEMO=false` | **PASS: 1 test**, exit 0. |
| `dart format --output=none --set-exit-if-changed lib test` | **PASS: 40 files, 0 changes.** |
| Direct SDK `dart analyze --fatal-infos` | **PASS: no issues**, exit 0. Initial brace/import diagnostics were fixed. |
| `flutter analyze --no-pub` | Attempted; wrapper exited 1 before analysis output on this host. Not counted as a successful Flutter analyzer command. Direct analyzer above is clean. |
| Backend `pytest -q --basetemp=.tmp/agent-integration-verified` | **PASS: 70 tests**, exit 0. One existing Starlette/httpx deprecation warning. |
| Ruff check, Ruff format check, pip check | **PASS**; 14 Python files formatted, no broken requirements. One new test import-order diagnostic was fixed. |
| Opt-in agent visual capture | **PASS: 1 capture test**, exit 0. Generated and viewed `work/agent-review/chat.png` and `correction.png`. |
| Physical Android/iOS delivery, live Gemini persona quality | **NOT TESTED**. No real users notified, live model calls, service deployment or participant data changes. |

The five optional skips are participant mode (run separately), live Gemini integration and three opt-in visual-capture suites. SDK provider tests mock generation, and native tests fake OS scheduling. These are not live-model/device results.

| Requested scenario | Verification |
|---|---|
| 1–4: correct personas, switch, history/backend selection | PASS for mocked conversations, SDK persona configuration, demo UI/serialization and backend assignment lock. Live persona behavior NOT TESTED. |
| 5–7: breakdown proposal, edited acceptance, saved steps | PASS existing flows plus natural-language card → existing breakdown route. |
| 8–9: correction acceptance/rejection | PASS UI, controller, API adapter and real FastAPI test-client/database transactions. Stale/duplicate/forbidden-field/owner checks and provider failures covered. |
| 10–11: start/deadline reminders | PASS pure planner and fake native coordinator. Physical delivery NOT TESTED. |
| 12–15: completion cancellation, edits, quiet hours, limits | PASS automated planner/coordinator and retained existing reminder tests. Includes persisted opt-ins, same-time de-duplication, conservative history budget, agent switch and copy-change registration. |
| 16: notification tap routing | PASS existing scoped/cold-start routing tests plus category-payload validation; real OS tap NOT TESTED. |
| 17: different notification wording | PASS fixed templates with matched slots; no model generation or delivery claim. |
| 18–20: AI failure, regression, research restrictions | PASS safe mocked failures, full suites and separate participant-mode guard. |

Checks caught and fixed: premature rejection/exposure after leaving a loading route; repeated rejection; a new dropdown overflow at 200% text; category/copy registration de-duplication. Early widget fixtures also needed real-async connection setup and settled scrolling before taps; those harness failures are not represented as product defects. Final suites above pass independently.

**Current Android artifact:** `outputs/frontend/SmallSteps-debug.apk` was rebuilt successfully, debug-signed, minimum API 24. SHA-256 **`B2CADD38516B529BA1E54ABE9CCEEC77DE58D478DD19F6EE5B5F4E9B4F78CF19`**. Receipt `.tool-state/verified-android-build.json` records build time `2026-10-30T12:16:58.0008028Z`, source fingerprint `287C3DCE272337F1442CF4218B3A8CAA99377BFE5747D658455F1F130C3494FD` and exact packaged-kernel verification. Gradle packaging completed with exit 0 (183 tasks; 23 executed). Existing Kotlin/Gradle/SDK-XML and restricted analytics-directory warnings remain.

Two initial build-launcher attempts failed before packaging. Direct invocation of the installed Dart SDK's cached Flutter compiler then completed with exit 0. The existing verified build helper now retries that same compiler directly if the launcher fails, and still refuses packaging on compilation failure. The final helper invocation compiled/packaged successfully and checked unchanged sources and the packaged kernel. The fallback command was verified independently; the successful final helper run did not need its fallback branch.

**Web:** attempted a current release build into `work/agent-web-build`; it exited 1 during web compilation without a usable diagnostic. No successful current web bundle or browser runtime is claimed. Older web previews are not this version. `adb devices` returned no attached devices; Android installation/runtime/delivery and iOS remain unverified.

## G. Main files changed

Frontend: `lib/app/state.dart`, `lib/app/reminders_controller.dart`, `lib/data/models.dart`, `lib/data/repository.dart`, `lib/data/reminders.dart`, `lib/data/services/device_reminders.dart`, `lib/features/agent_actions.dart` (new), `chat.dart`, `tasks.dart`, `reminder_settings.dart`, `insights.dart`.

Backend: `app/ai.py`, `app/schemas.py`, `app/main.py`. Existing JSON records hold the new proposal/provenance fields; no database migration or credential change was required.

Tests: new `test/agent_integration_test.dart` and `tests/test_agent_integration.py`; existing HTTP fake extended for correction; timezone-only fixture explicitly removes burden limits so it still isolates timezone behavior. Original test coverage was retained.

Build tooling: small fallback added to `outputs/frontend/tool/build-android-verified.ps1`; original source/kernel verification remains mandatory. Documentation: frontend/backend README, notification guide, research event contract and QA report updated.

## Remaining device/live checks and use

1. Restart the **development** backend from its existing launcher to load the new code, and install a newly built APK. The running older server was not silently restarted or deployed during this review. Local demo remains usable without a backend/key.
2. With synthetic Self/Friend accounts, verify assignment locking, separate conversations, correct task context and edited correction/breakdown acceptance. Human-rate repeated live responses using behavioral criteria (autonomy, truthful context, brevity, empathy/future reflection, no pressure) rather than exact wording. No live persona success is claimed.
3. On Android, test permission grant/deny/revoke, each opt-in type, limits, timezone changes (including Asia/Tokyo), quiet hours, task edits/completion/deletion, foreground/background/locked/terminated delivery, reboot, tap category, snooze, logout and another account. Observe actual delivery; do not infer it from counters. Test battery restrictions and force-stop separately.
4. On macOS/Xcode/iPhone, compile/sign and repeat native notification/tap/lifecycle checks. Test VoiceOver/TalkBack, keyboard and large text on hardware.
5. Do not start a participant pilot until the existing consent, enrollment, retention/withdrawal and live/device evaluation gates in the QA report are satisfied.
