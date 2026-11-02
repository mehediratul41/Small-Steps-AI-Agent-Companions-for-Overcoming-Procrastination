Live agent update (2026-11-02): [Self-Agent/Friend-Agent switching and saved login verification](../../BOTH_AGENTS_LIVE.md). Researcher Demo Mode can link separate synthetic accounts and save their credentials securely on Android/iOS. Keep the backend running.

> Development backend connection is available: see [CONNECT_BACKEND.md](CONNECT_BACKEND.md). Local demo mode remains the default; real participant enrollment stays closed.

# Small Steps

English / 日本語 is now available from the globe menu or Settings. The selection is saved; existing task text and conversations keep their original language. See [localization implementation and actual verification](../../LOCALIZATION_REPORT.md). Updated bilingual APK built and installed on emulator-5554 on 2026-10-31; English and Japanese dashboards were visually observed.

Latest agent integration audit (2026-10-30): [audit, implementation, tests and research limits](../../AGENT_FEATURE_AUDIT.md). Adds chat demo switching, approved task correction, contextual review cards and opt-in reminder categories/frequency controls. Connected study assignments remain locked; backend is Gemini. Older results below remain historical.

Latest UX iteration (2026-10-30): simpler Today, actionable reminder status and completion Undo. See [implementation and verification](../../UX_FIRST_IMPLEMENTATION.md) for the current APK, 132 passing tests, screenshots and remaining web/device limits. Older build and test results below are historical.

A Flutter frontend for the Shimane University Human–AI Interaction research prototype: **Progress, not pressure.**

## Run

**Current status:** Android debug build, installation and initial launch are verified on the API 35 emulator after enabling Windows Hypervisor Platform and restarting. The Welcome screen rendered; the emulator later disconnected. See [BUILD_STATUS.md](BUILD_STATUS.md) for the latest connection state and evidence; it supersedes historical blocker notes below.

For one-click Android build, installation and launch from the normal Windows session, double-click `RUN-ANDROID.cmd`. It builds the latest APK, uses a connected authorized device or starts the existing hardware-accelerated emulator, and verifies Android's activity-launch response. The launcher is syntax-checked; its complete native workflow remains unverified in the restricted shell. Software emulation can time out; an authorized physical Android phone is preferable on this PC.

For this Windows PC, see [VSCODE_SETUP.md](VSCODE_SETUP.md). To build a test APK outside the restricted Codex shell, double-click `BUILD-APK.cmd` in this folder. A successful build is copied to `SmallSteps-debug.apk`; failures retain a log under `.tool-state/build-logs`. Native compilation succeeded through direct Gradle after access was granted; the complete launcher/device workflow remains unverified.

This project was created and checked with Flutter **3.47.4 stable**, Dart **3.13.3**. Dependencies are locked in `pubspec.lock`. Android, iOS and a browser preview share the same Dart implementation.

```powershell
cd outputs/frontend
flutter pub get
flutter run -d chrome
# With an Android SDK and a connected device/emulator:
flutter devices
flutter run -d <device-id>
flutter build apk --debug
```

On this PC, Flutter exists at `C:\Users\mehed\Documents\Codex\.tools\flutter\bin\flutter.bat` but is not on PATH. The optional wrapper below finds that SDK and keeps tool-state files in the project when the Windows sandbox cannot write to AppData:

```powershell
.\tool\flutter.ps1 pub get
.\tool\flutter.ps1 run -d chrome
.\tool\flutter.ps1 test
```

Open this `frontend` folder in Antigravity or another Flutter-capable IDE. The separate FastAPI/Gemini development service is in ../backend.

## What works

The latest research/UX additions and their verification are documented in [FEATURE_UPDATE.md](FEATURE_UPDATE.md).

- Welcome and explicitly labeled **demo consent**, with a required acknowledgment and privacy details.
- Today, Tasks, Chat/Reminders and Insights navigation, with shared Riverpod state and guarded routes.
- Title-only task capture; optional, independent planned start, deadline and reminder; search and Active/Today/Paused/Completed filters. Add, edit, reschedule, pause, resume, delete and complete tasks. Manual subtask editing is shared by all conditions.
- Gentle recovery options with an optional reason, a smaller-step path and a reminder snooze sheet. Changes require a user action.
- Mock task refinement, editable suggestions, regeneration, rejection and explicit acceptance. Existing subtasks are preserved.
- Self-Agent and Friend-Agent use the **same widget**, message composer, task context and actions. Their wording and avatar treatment differ. Histories are separate.
- Task-specific and general conversations; retry, edit or cancel a failed request without blocking a new message. Retries retain their original task context. Settings can make the next mock request fail once.
- Standard control replaces Chat with Reminders and rejects direct navigation and controller calls to AI features.
- Opt-in Android/iOS reminder scheduling, quiet hours, permission status and retry; automatic cancellation/rescheduling as tasks change. Neutral wording and controls are shared across conditions. See [NOTIFICATIONS.md](NOTIFICATIONS.md) for timing policy and device verification.
- Five-, ten-, fifteen- and twenty-five-minute focus sessions with start/pause/resume/end, restart persistence, timestamp-based background recovery and optional reflection. A timer never marks a task complete or records self-reported task initiation.
- Optional baseline, daily and session check-ins with dated history; demo questions, no validated scores. Values/goals preferences and optional on-screen invitations personalize scripted AI-condition examples.
- Seven-day charts and history derived from local interactions, explicit self-reported task initiation, local demo JSON export and light/dark/system themes.
- Bundled Inter font; native Flutter widgets and an editable brand illustration. No screen-sized background images, OpenAI keys or direct OpenAI calls.

The sample tasks are demonstration content. Insight counts reflect local demo actions, not research findings. `focus_started` records timer use; `task_started` records an explicit user report. Neither verifies work. Task completion is self-reported.

## Research configuration

The default build is visibly labeled **Demo**. In Settings, Researcher Demo Mode switches between `selfAgent`, `friendAgent`, and `standardControl`. It preserves shared tasks for comparison; it is not a randomized study assignment.

```powershell
flutter run --dart-define=RESEARCHER_DEMO=false
```

Participant mode **fails closed** at a study-configuration screen. It does not load local demo records, permit condition switching, or enroll a participant. This is intentional: approved participant authentication/enrollment and informed-consent materials are not configured. Synthetic development accounts can connect separately. Do not deploy this demo for participant collection.

The repository adapter includes `GET /api/participants/me` for future assignment. The backend must authorize every condition-sensitive request; client-side guards alone are not a security boundary. Future baseline questions can be configured through `AppConfig.baselineQuestions`, which is currently an empty extension point rather than a questionnaire implementation.

## Data and privacy

The versioned `small_steps.demo.v1` preference stores demo consent, condition, tasks, separate chats, focus state, history, burden and theme. `small_steps.demo.reminders.v1` stores notification preferences. This is **unencrypted demo storage**: use fictional, non-sensitive information. Settings → Reset local demo removes these keys and cancels device reminders. No authentication credentials are stored and no demo data is transmitted by the mock repository. The bundled font needs no network request.

## Backend preparation

`lib/data/repository.dart` contains the typed `ResearchRepository`, working `MockResearchRepository` and provisional Dio-based `ApiResearchRepository`. Models serialize explicitly to JSON; API errors become `AppFailure` messages. The app starts with the mock repository and supports an explicit synthetic-account connection through Settings; it never automatically uploads demo records.

`API_BASE_URL` is configurable (default `http://10.0.2.2:8000`, Android emulator host loopback), but does **not** automatically enable live networking. Wire authentication, approved onboarding and server assignment first, then replace the provider and persistence layer. See [API_CONTRACTS.md](API_CONTRACTS.md). Use HTTPS for deployed study services; platform transport policies and release networking permissions must be configured as part of integration.

## Structure

```text
lib/app/        configuration, theme, router and persistent Riverpod controller
lib/data/       typed models, repository contract, mock and API adapters
lib/features/   onboarding, dashboard, tasks/refinement, chat, focus, insights, settings
lib/shared/     reusable cards, buttons, headings, avatars, feedback and brand mark
assets/fonts/   Inter and its OFL license
test/           behavior, widget flow and optional visual/participant checks
tool/           local Flutter wrapper
design-review/  rendered Flutter captures of the nine screen concepts and dark theme
```

## Checks

```powershell
dart format .
flutter analyze
flutter test
flutter test test/participant_test.dart --dart-define=RESEARCHER_DEMO=false
flutter test test/preview_test.dart --update-goldens --dart-define=CAPTURE_PREVIEWS=true
flutter build web --release
```

The preview capture is a manual visual-review tool, **not** a pixel-accuracy regression baseline: dates and greetings intentionally vary. The normal tests cover onboarding, navigation, task creation/completion, refinement acceptance/rejection, both chat personalities and retries, control guards, timer timestamp behavior, persistence, failures, empty panels, dark theme, large text, three screen sizes and keyboard visibility. See [IMPLEMENTATION_REPORT.md](IMPLEMENTATION_REPORT.md) for actual results and limitations.

## Android and iOS requirements

The local Android SDK/JDK/CMake built the debug APK successfully. After Windows Hypervisor Platform setup and a restart, launching through VS Code brought the API 35 emulator online; APK installation and the Welcome screen were verified. The restricted terminal itself cannot access the hypervisor APIs. Further native interaction and stability checks remain; see BUILD_STATUS.md.

iOS source scaffolding is included. Compile, sign and test on **macOS with Xcode** and a simulator or device; run `flutter pub get`, `flutter build ios --no-codesign` for compilation, then configure signing as appropriate. No iOS build or test was performed here.

## Known boundaries

- Native reminder scheduling is implemented. The current Android debug build is verified by the build receipt; current device launch, actual delivery and iOS compilation remain unverified. Browser preview only saves reminder times. Quiet hours adjust scheduling requests; OS delays can affect actual delivery. See [NOTIFICATIONS.md](NOTIFICATIONS.md).
- The local development API and Gemini path are verified separately from participant deployment; see CONNECT_BACKEND.md and the backend validation record.
- Consent is a demonstration, not ethically/legally sufficient research consent.
- Figma detail exports and screenshots were available for eight screens; its plan limit blocked detailed export of Task Refinement. That screen uses available hierarchy metadata and the supplied requirements. Pixel-perfect accuracy is not claimed.
- Shared functional controls, accessibility and truthful data labeling introduce deliberate differences from the static Figma frames. Text is more readable, screens scroll, the control tab is Reminders, and the focus timer does not imply task completion.
- Launcher icons remain the generated Flutter defaults. The in-app Small Steps brand is implemented.



## New development backend (2026-10-27)

A separate FastAPI/Gemini-ready service is in [../backend](../backend/README.md), with SQLite persistence, hashed participant tokens, server-enforced conditions, task revision guards, chat/refinement, and event storage. See its validation record for actual results. The updated source supports authenticated synthetic development accounts; older installed APKs must be updated to receive the connection screen. Do not upload demo history as participant records or enable the participant gate just by changing the repository provider.

## Verified Windows build and development privacy (2026-10-28)

Double-click `BUILD-APK.cmd`, or run `./tool/build-apk.ps1` in the VS Code terminal. It calls `tool/build-android-verified.ps1`: Flutter compiles current debug sources in the terminal, then Gradle packages those assets. This avoids the host's 0xC0000008 crash in Gradle's captured Flutter child. Compilation failures stop packaging; the script verifies the APK's kernel hash matches the compiled file and sources did not change during the build. `SmallSteps-debug.apk` is delivered only after these checks. `.tool-state/verified-android-build.json` records source/APK/kernel SHA-256 and UTC time. Debug signing is for development only.

For a web release, use the normal Flutter wrapper with an **absolute** output path. Relative out-of-project paths can fail shader writes on this SDK. Builds/tests should run sequentially in a terminal on this host; captured/concurrent processes remain unreliable. Do not interpret an old APK's presence as a fresh successful build.

Connected phones can opt into account-scoped neutral reminders in Settings. Browser delivery is unavailable. Data & study information can copy the full server export plus pending device reports; the expandable preview is labeled partial. Development backend settings include a confirmed synthetic-account erasure action. It erases logical task/chat/report data and revokes the token, retaining an inactive account marker; prior exports/backups/device-media remnants are outside its scope. Offline Settings also lets you explicitly forget cached connected-account data without changing server or local-demo records. Real participant enrollment/consent remain closed.
