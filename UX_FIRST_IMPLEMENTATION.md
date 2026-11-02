# Small Steps: first UX implementation

This is the dated first-UX snapshot. The current source and delivered APK are newer; see [agent integration audit](AGENT_FEATURE_AUDIT.md) for the current hash, test counts and reminder policy. The hash below identifies the earlier artifact and is retained as historical evidence.

Implemented and checked **2026-10-30, Asia/Tokyo**. This covers the first agreed improvements: a simpler Today screen, actionable reminder status, and completion Undo. The previous backend and agent prompts were preserved.

## Implemented behavior

- **Today:** one highlighted active task, its next unfinished subtask where available, one focus action, View task and Change task. Add task uses the same label as the editor. Progress and other tasks are lower down; optional check-ins/preferences are collapsed. An existing focus session has a Return action. The picker scrolls and supports large text in landscape.
- **Task choice:** the highlighted choice persists in local demo state or the connected account's separate cache. Missing, completed or paused choices fall back to another active task. Choosing a task or a duration does not record task initiation; the existing explicit Start action remains necessary.
- **Reminder feedback:** settings, the control interface and task details distinguish Notifications off, Permission needed, Time saved, Scheduled on this phone, No upcoming reminders and update failures. Available actions include Enable notifications, Request permission, Check again, Choose a time/task and Try again. Preview storage never claims OS scheduling or delivery. The permission copy explains phone Settings when no further prompt appears.
- **Completion Undo:** task cards and details offer an eight-second snackbar with Undo after a successful completion. Undo reopens the task through the existing repository and event path. A receipt is single-use and scoped to the current task version, account/server and condition. Later edits, deletion, condition/account changes and duplicate Undo attempts cannot silently overwrite newer state. A failed request leaves the completed task intact and shows an error. The existing manual Mark as to do action remains available later.
- **Research history:** the original `self_reported_completion` event remains; correction appends `completion_undone`. No task-start, inferred delivery or ignored-reminder events were introduced. Shared functionality is the same in Self-Agent, Friend-Agent and control; existing persona wording and control restrictions remain intact.

These shared layout/interaction changes can influence behavior in a study. Freeze and record this UI version before enrollment, and avoid pooling earlier UI sessions without accounting for the version. This implementation is not evidence of improved procrastination outcomes or validated usability.

## Verification actually executed

Windows; Flutter 3.47.4 / Dart 3.13.3; installed locked dependencies. Synthetic data and mocked repositories/services only. No dependency upgrades, live AI calls, production records, public deployments or real-user notifications.

| Check | Result |
|---|---|
| Baseline `flutter test --no-pub` | PASS: 115 tests, 3 optional skips. |
| Final `flutter test --no-pub --file-reporter=json:.tool-state/ux-full.jsonl` | PASS: **132 tests, 4 optional skips**, exit 0 and runner success true. Includes 17 new regression tests. |
| Separate `test/participant_test.dart` with `--dart-define=RESEARCHER_DEMO=false` | PASS: 1 test, exit 0; real participant enrollment remains closed. |
| `dart format --output=none --set-exit-if-changed lib test` | PASS: 38 files, 0 changes. |
| Direct SDK `dart analyze` | PASS: No issues found, exit 0. |
| `flutter analyze --no-pub` | Initial run found three brace-style diagnostics, subsequently fixed. Final wrapper invocations failed at host startup, including native `0xC0000008`; not counted as successful Flutter analyzer commands. Direct Dart analysis above completed successfully. |
| Visual capture/review | Generated and viewed Today, task picker and completion Undo PNGs under `work/ux-first`. The capture runner reported 18 successful cases, but the command returned exit 1; it is not counted as a clean command pass. Default full-suite tests above passed independently. |
| Verified Android build `./tool/build-apk.ps1` | PASS: freshly compiled Flutter code, Gradle packaging exit 0, packaged kernel and unchanged source digest verified. |
| Current web release | BLOCKED: standard wrapper, Windows PowerShell and direct Flutter-tool invocation exited 1 before producing a current bundle. Verbose output stopped during plugin discovery. Existing older web previews are not evidence of this UI version. |
| Android runtime / delivery | NOT TESTED: `adb devices` returned no attached devices. APK build success does not establish device launch or notification delivery. |
| iOS / live personas / backend suite | NOT TESTED this iteration. Windows cannot compile iOS; backend source was unchanged. Prior backend results are historical, in `FOLLOWUP_REPORT.md`. |

Four default skips are the separately run participant test, live model integration, the previous screen capture and the new opt-in UX capture.

The new tests verify completion/correction events, version protection, condition invalidation, selection persistence without initiation, Undo UI in all three conditions, failed Undo, honest reminder states and recovery, and long Unicode task text at 200% scaling in 320×568 portrait and 844×390 landscape. The landscape test caught a 7.3px picker overflow; enabling scroll-controlled sheet sizing fixed it and the full suite passed afterward. An initial test-launch socket restriction and a test-harness scrolling issue were resolved before the final run.

## Current Android artifact

- `outputs/frontend/SmallSteps-debug.apk`, debug-signed, minimum API 24.
- SHA-256: `85C2EA625F94E41E1D8162E957D26CB56FAF30702BFB9A680D6B6B5B3BD2E7BB`.
- Receipt: `outputs/frontend/.tool-state/verified-android-build.json`, built at `2026-10-30T11:24:50.3058413Z`.
- Source fingerprint: `812E88881EF520178465A445C87C5E33BC13BF0338DF2CCC92A36AC9F949325D`.
- Existing Gradle/Kotlin deprecation, SDK XML-version and restricted analytics-directory warnings remain; none prevented this debug build. Conventional captured-child Flutter builds remain unreliable on this Windows host. The existing verified build script compiles before packaging and checks exact assets, as described in `FOLLOWUP_REPORT.md`.

## Try the implementation

On an authorized test Android device, install the APK and open Small Steps. In local demo mode:

1. Complete demo onboarding if needed. On Today, choose Change task, select another task and reopen the app to check the choice persists. Focus on this task opens duration selection; work is recorded only after explicit Start.
2. Open Tasks, mark a task complete, then tap Undo. Verify it returns to Active and Insights shows both the completion and correction. Repeat in all three demo conditions. Edit a completed task before Undo to verify newer changes are protected.
3. Save a future reminder. While notifications are off, verify Time saved is not presented as scheduled. Enable notifications, test both permission denial and allowance, then check again. Verify edits/completion/deletion update the schedule. Observe lock-screen/background/terminated delivery and tapping on actual hardware; do not infer delivery from the status card.
4. Test at large system text size, landscape and with the keyboard open. Confirm optional support can be expanded without blocking the primary action. Formally test TalkBack/VoiceOver on devices before a pilot.

For web after resolving the host startup failure, run from `outputs/frontend`:

```powershell
./tool/flutter.ps1 build web --no-pub --no-wasm-dry-run
./tool/flutter.ps1 run -d chrome
```

No new web build or browser runtime success is claimed here. Physical Android checks, iOS/Xcode verification, approved participant consent/enrollment and the remaining release gates in the QA report are still required before a participant pilot.

## Changed source

- `outputs/frontend/lib/features/dashboard.dart`
- `outputs/frontend/lib/features/reminder_settings.dart`
- `outputs/frontend/lib/features/tasks.dart`
- `outputs/frontend/lib/shared/widgets.dart`
- `outputs/frontend/lib/app/state.dart`
- `outputs/frontend/test/ux_first_test.dart`

The workspace has no Git repository. Before editing, affected source snapshots were saved under `work/ux-first-before` with a hash manifest; unrelated files and previous QA evidence were retained.
