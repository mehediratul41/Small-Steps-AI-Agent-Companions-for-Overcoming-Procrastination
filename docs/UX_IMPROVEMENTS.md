# UX improvements — 2026-11-02

## Scope and baseline

Existing Flutter/Riverpod/Dio frontend, authenticated FastAPI/SQLAlchemy backend, PostgreSQL, server-side Gemini, local reminders and EN/JA localization were retained. Existing uncommitted multi-user/database work was preserved. No agent prompt, assignment, consent or questionnaire was rewritten; no application database migration was repeated.

Before editing, traced Today → focus controller, chat → repository/API → persisted message, task plan/recovery editors, reminder reconciliation and owned research events. Baseline analyzer was clean. The preceding integration report recorded 180 Flutter tests and 94 backend tests; these are historical baseline counts, not newly rerun pre-change suites. This change's actual runs are below.

Existing capabilities reused: selected Today task, incomplete subtasks, guarded focus preparation/start, versioned task saves, manual subtask editor, recovery/rescheduling confirmation, chat retry IDs and owner caches, reminder pause/quiet hours/caps, generic owned event persistence. Problems: direct start required a duration step, chat controls crowded the reading area, context explanations dominated the screen, difficulty advice lacked an immediate optional action, and no optional structured support feedback existed.

## Implemented behavior

- **Today:** one selected task and its first incomplete subtask, otherwise its actual title. Start 5 minutes prepares and starts through the existing controller. Duplicate calls cannot replace a session. Existing session offers Resume; Choose duration remains secondary. Recovery opens the existing Make smaller / Reschedule / Pause flow.
- **Event meaning:** direct timer start records `focus_started`, not `task_started`, verified work or completion. Existing explicit work-start and completion controls remain separate. Timer expiry never completes a task.
- **Chat:** task context is a compact expandable summary with its selector inside. About this conversation retains connection, demo/study and explanation content. Active agent identity and mode remain visible. Initially two quick actions; More actions reveals the remaining actions. Both agent layouts share this code. Archived conversations retain their existing restrictions.
- **Reading:** list scroll state is keyed by agent and task context; separate expansion keys avoid a Flutter PageStorage type collision found during regression testing. Replies follow the bottom unless the reader scrolls up during the request; Show latest is then offered. Composer remains outside the scrolling list. Native keyboard/assistive-technology review remains necessary.
- **Request feedback:** Sending covers local preparation; Waiting for reply covers the repository request. Saved on server appears only on acknowledged connected messages; local demos explicitly say Kept in local demo. Existing failed-message retry/edit/cancel actions and stable request IDs are retained. No artificial progress or silent live-to-demo fallback.
- **Start plans:** editable example cue “After lunch” and action “Open one paper and read its abstract.” Drafts require Save; dismissal preserves the stored plan. Text cues never automatically schedule reminders. Language changes do not translate stored plans/tasks/chats.
- **Difficulty:** one optional action at a time, plus Skip: unclear/overwhelming opens the existing manual next-step editor; worried offers a rough-attempt draft; distracted offers an editable distraction-reduction draft; tired opens existing duration selection. Opening an external helper closes the unsaved plan editor; draft fields are not silently saved. Reschedule is available through recovery. No diagnosis or automatic deadline change.

## Development-only capabilities

All defaults are OFF. Participant builds (`RESEARCHER_DEMO=false`) force both capabilities off even if flags are supplied. Existing assignments and restricted DEV account switching remain unchanged.

| Compile-time flag | Default | Meaning |
|---|---|---|
| `DEV_SUPPORT_FEEDBACK` | false | Optional inline Insights feedback after a started focus session has ended |
| `DEV_SUPPORT_FEEDBACK_HOURS` | 24 | Minimum between offers, clamped 1–168 hours; used only when feedback enabled |
| `DEV_REDUCED_SUPPORT` | false | Today shortcut to the existing reminder pause policy |

Opt in on a synthetic development build only:

```powershell
./tool/flutter.ps1 run --dart-define=DEV_SUPPORT_FEEDBACK=true --dart-define=DEV_REDUCED_SUPPORT=true --dart-define=DEV_SUPPORT_FEEDBACK_HOURS=24
```

The default verified APK has neither flag enabled. The documented Windows APK packaging helper produces that default variant; it does not accept these `run` flags. Do not enable new measurements in a study without protocol review.

### Feedback wording and frequency

Instrument `dev-support-feedback-v1`: “What helped?” Options: Smaller step, Clear plan, Encouragement, Quiet time, Skip. Optional development feedback; no response required. Japanese equivalents are in the existing ARB files and need native-language review.

An offer is created on entering Insights after a recorded `focus_elapsed` or `focus_ended_early`, only with no active session, no unanswered offer, a different ended session from the last offer, and elapsed cooldown. A pending inline offer can remain until answered/skipped; it is not a repeated modal prompt. Skipping records a skip and still consumes that offer/cooldown. Repeated taps cannot duplicate answers. Later text reports only the user's last actual choice; it makes no causal or performance claim.

Existing `BehaviorEvent` storage is reused: `support_feedback_offered`, `support_feedback_answered`, `support_feedback_skipped`. Details include instrument version, source, session ID, cooldown on offers, and offer ID/actual choice on decisions. Existing event ID, UTC timestamp, condition and language metadata remain intact. Connected records are server-owned by authenticated participant; local pending events remain in the existing account-scoped cache. No new endpoint, table, database service or migration. Generic event APIs are self-report transport, not proof of clinical validity or server-attested UI exposure. Demo feedback is local demonstration data.

Connected failures use existing pending-event persistence/retry; the panel does not claim server acknowledgement. This is not a general offline task-sync system. Legacy records without these optional event kinds need no backfill. No measurement from another account is used in summaries.

### Less support today

Confirmation explicitly explains that the existing policy pauses **all Small Steps reminders**, including planned starts/deadlines, until the next local day. It is not a selective optional-agent-check-in pause. Existing settings can resume early; missed notifications are not replayed. Existing reconciliation cancels/rebuilds pending notifications, suppressing slots before pause expiry while keeping eligible future-day reminders. A deterministic Asia/Tokyo test confirms no replay burst. Permissions, account scope, quiet hours and caps remain in effect. No new check-in window or adaptive timing policy was introduced. Scheduling/opening do not prove delivery or ignored status.

## Research interpretation

Ordinary task/chat navigation changes reduce steps and visual crowding but may still affect measured initiation; record build/version consistently across study arms. Shared task controls remain comparable across conditions, and standard control gains no AI endpoint or agent support. Difficulty shortcuts reuse user-controlled task editing; they must be documented as exposure changes. New feedback is a research measurement and reduced-support placement can change intervention exposure, hence both are development-only.

Persona evaluation specification already exists at `outputs/backend/evals/agent_cases.json`: reluctance, completion, deferral, stop requests, frustration, unrelated requests and privacy/instruction attacks. Use the same synthetic task/history and EN/JA cases for both agents. Rate future-goal reflection without invented memory for Self-Agent, empathetic acknowledgment for Friend-Agent, and shared autonomy/no-pressure/privacy criteria. Blind reviewers to model identity where possible; retain prompt/model/language provenance and report failures. Two similar responses are insufficient evidence of reliable distinction. No live model evaluation was run for this UX change and no prompts were changed.

## Files

Frontend: `lib/app/config.dart`, `lib/app/state.dart`, `lib/features/dashboard.dart`, `chat.dart`, `start_support.dart`, `insights.dart`, new `support_feedback.dart`; English/Japanese ARBs and generated localization. Tests: new `test/ux_improvements_test.dart`, participant guard and affected existing chat/focus tests. Backend: one regression in `tests/test_api.py` covering optional event ownership, provenance, replay and conflict. Documentation/API/data notes updated only for this extension.

## Verification

| Check | Result |
|---|---|
| Baseline / final Flutter analyzer | PASS, no issues |
| Changed Dart formatting and localization generation | PASS |
| Default Flutter regression | PASS: 192 passed, 13 skipped |
| Development feedback enabled targeted tests | PASS: 10 passed, 1 skipped (default-off test); includes throttling, skip, replay prevention and persisted choice |
| Participant build with both dev flags requested | PASS: 1 test; both capabilities remain disabled |
| PostgreSQL backend tests in disposable test schemas | PASS: 95 passed; existing Starlette/httpx deprecation warning |
| Backend Ruff | PASS |
| Real Dio → FastAPI → PostgreSQL HTTP contracts, mock AI | PASS: 6 passed, all three conditions |
| Android current-source build | PASS: Flutter compile + verified Gradle packaging, default development flags OFF |
| Native emulator smoke | PASS: Android API 35 install/launch, Today direct-start and compact Chat controls observed, installed APK hash verified |
| Physical notification delivery / iOS compilation | NOT TESTED |
| Live Gemini persona quality / clinical benefit / formative user study | NOT TESTED |

Targeted tests cover all-condition rapid five-minute starts, session preservation, no false task-start/completion, compact chat/More actions, Japanese labels/raw task preservation, explicit plan approval/dismissal and feedback gating/throttling. Existing regression covers failures/retries, account boundaries, recovery approval, legacy records and reminder cancellation/limits. Automated widgets are not a substitute for native screen-reader, keyboard or older-message reading checks. During development, targeted tests exposed a new PageStorage expansion/list key collision; distinct keys fixed it and the affected chat regression passes. Additional test-only failures (map key type, lazy-list finder ambiguity and an incorrect assumption that a one-day pause cancels future-day reminders) were corrected before the final pass. No failing check is reported as passed.

Build receipt: `outputs/frontend/.tool-state/verified-android-build.json`; delivered `outputs/frontend/SmallSteps-debug.apk`, SHA-256 `D7BD208659E718A2A5644DC537F136FF5E9201B0B4910A35EB88DFD9B46AF494`. Source digest `583D14867B65C63942B02780A1E572BF988E6908E9F156B9C68163187A0C4B53`. Android API 35 emulator installation returned Success and launch Status ok; installed APK SHA-256 independently matches. Only read-only navigation was used on retained app data. No task/chat mutation or live model call was made on that installation. Existing Gradle deprecation warnings remain.

Actual commands: `flutter gen-l10n`, Dart format on changed files, `flutter analyze --no-pub`, `flutter test --no-pub --reporter json`, flag-enabled targeted suite, participant guard with `RESEARCHER_DEMO=false` and both flags requested, opt-in `RUN_HTTP_INTEGRATION=true`, backend `pytest -q --basetemp=.tmp/ux-final` with isolated PostgreSQL configuration, `ruff check app tests tool`, `tool/build-apk.ps1`, ADB install/launch/UI inspection/hash comparison. The HTTP fixture used disposable synthetic records and was cleaned up afterward. No application/participant database was migrated or edited.

Logs: frontend `.tool-state/ux-*`; backend `.tmp/ux-backend.log`. All are private/ignored.

## Try it / formative usability script

Launch the default APK or Flutter app. On Today select a synthetic task, Start 5 minutes, pause/back, then Resume; check that the task is still incomplete. In Chat expand Task context, select another task, expand More actions, send a synthetic message and inspect truthful demo/connected labels. Edit a start-plan example, dismiss, reopen and explicitly save. No existing participant records should be used.

With 3–5 consenting formative testers using synthetic accounts, ask them to: (1) identify the next step and start five minutes without help; (2) resume without losing a session; (3) change chat task context and find a less visible action; (4) read older messages during a delayed reply, then find Show latest; (5) dismiss versus save a plan; (6) explain exactly what Less support today pauses on a flagged development build. Observe success, wrong taps, hesitation and perceived burden; check 320px width, large text, Japanese, keyboard and screen reader. Do not interpret task success as reduced procrastination. Keep new instrumentation disabled in participant builds pending review.
