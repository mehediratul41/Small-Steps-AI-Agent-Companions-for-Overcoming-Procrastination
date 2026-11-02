# QA and integration report

Audit date: 2 November 2026. Scope: this local source tree, synthetic tests, and the Android emulator. **Suitable for further supervised synthetic rehearsal; not yet established as ready for participant recruitment.** No deployment, publication, production-data modification, or live model evaluation was performed.

## Environment and baseline

Windows/PowerShell, Asia/Tokyo; Flutter 3.47.4, Dart 3.13.3, Python 3.12.14, FastAPI 0.162.0, SQLAlchemy 2.1.6. See [developer setup](DEVELOPER_MANUAL.md). Neither root nor application directories contain a Git checkout: tracked-file history and previously committed secrets cannot be certified here. Existing files and reports were preserved.

Baseline: Flutter analysis clean; Flutter suite 172 passed with 6 skipped; backend 77 passed; Ruff clean. Three added server reproductions failed before fixes: legacy refinement, update replay, deletion replay. Logs are under `outputs/frontend/.tool-state/` and `outputs/backend/.tmp/`, intentionally private/generated.

The existing port-8000 development service reported Gemini configured. Merely checking health does not verify model responses. The isolated contract service used mock AI and a temporary SQLite database, never existing account credentials. Its credentials and database are removed when stopped.

## Confirmed findings and fixes

| Severity | Reproduction / previous actual behavior | Expected / fix | Evidence and files |
|---|---|---|---|
| High | Save an old editor snapshot after another task update: controller could assign the current version to stale fields | Reject stale local snapshots before sending | `lib/app/state.dart`, `test/live_agent_accounts_test.dart` |
| High | Restore a saved account with a different identity but the same condition | Validate saved participant ID as well as assignment | Same controller and regression file |
| High | Erase a remembered development account: credential could remain in the vault | Remove only that account's remembered credential; preserve linked account; report cleanup failure | `lib/data/saved_connections.dart`, controller and regressions |
| Medium | Failed live restoration followed by task save/refinement could operate on demo state | Refuse operations until connection is resolved | Controller session guard and regressions |
| Medium | Refine a legacy task whose JSON omits newly optional fields: false stale-data rejection | Normalize stored task through current model defaults for semantic comparison | `app/main.py`, `tests/test_integration_sync.py` |
| Medium | Repeat identical versioned update after lost response: conflict despite successful original save | Return existing receipt for exact update replay; different stale edits still conflict | Same backend files |
| Medium | Repeat deletion with original version after lost response: not found | Recognize exact tombstone replay without another audit event | Same backend files |

Paths above are relative to `outputs/frontend/` or `outputs/backend/`. No agent prompts, consent instruments, intervention timing, or condition capabilities were changed in these fixes.

## Feature inventory and verification matrix

Inventory status describes implementation; result describes executed verification. WORKING does not imply physical-device validation.

| Flow | Inventory | Result / evidence |
|---|---|---|
| Demo onboarding, consent and condition routing | WORKING | PASS automated; consent is demonstration wording |
| Participant enrollment / approved instruments | MISSING | NOT TESTED; deployment deliberately development-only |
| Token ownership, expiry, account isolation | WORKING | PASS backend and Flutter regression tests |
| Secure remembered mobile login | WORKING | PASS synthetic tests; installed Android launched into Connected development after update |
| Live synthetic agent switching | WORKING | PASS controller isolation tests; assignment remains server-controlled |
| Task CRUD, version conflicts, completion and replay | WORKING | PASS unit/API and real Dart-to-FastAPI HTTP tests |
| Approved breakdown and correction | WORKING | PASS HTTP accept/save flows; mock provider |
| Start plans, difficulty and future-self notes | WORKING | PASS HTTP persistence; Self-only context test for both agents |
| Chat history, stable request IDs and duplicate prevention | WORKING | PASS HTTP for both AI conditions; mock provider |
| Standard-control AI restriction | WORKING | PASS client/backend tests and HTTP condition case |
| Provider quality, real quota/network behavior | UNVERIFIED | NOT TESTED this audit; health only |
| Durable pending chat/event recovery | PARTIAL | PASS covered recovery cases; no universal offline mutation outbox |
| Task/profile writes while offline | PARTIAL | Backend required; errors supported, automatic conflict merging absent |
| Focus pause/resume and timestamp calculation | WORKING | PASS automated; timer end does not complete task |
| Reminder policy, cancellation, quiet hours, caps | WORKING | PASS automated policy/controller tests |
| Actual locked/terminated-device reminder delivery | UNVERIFIED | NOT TESTED; scheduling success is not delivery |
| Check-ins, events and exports | WORKING | PASS HTTP persistence/deduplication/owner checks; instruments provisional |
| English/Japanese locale and payload language | WORKING | PASS automated locale and Japanese HTTP payload cases; native linguistic review outstanding |
| Android debug packaging, install and launch | WORKING | PASS emulator install/update and launch; Connected development UI observed |
| iOS build, secure storage and delivery | UNVERIFIED | BLOCKED by Windows; macOS/Xcode and device required |
| PostgreSQL, production hosting, push notifications | UNVERIFIED / MISSING | NOT TESTED; SQLite and local notifications verified in scope |

## Commands and final results

Commands ran in their application directories with documented Windows environment helpers:

| Executed check | Result |
|---|---|
| `flutter analyze --no-pub` via `tool/flutter.ps1` | PASS, no issues |
| `flutter test --no-pub --reporter json` | PASS, 176 tests; 6 skipped |
| Participant-build routing guard test | PASS, 1 test |
| Opt-in `http_contract_integration_test.dart`, `RUN_HTTP_INTEGRATION=true` | PASS, 3 conditions over real Dio/HTTP/FastAPI/SQLite, mock AI |
| `dart format --output=none --set-exit-if-changed lib test` | PASS |
| `python -m pytest -q` | PASS, 82 tests |
| `python -m ruff check app tests tool` | PASS |
| Ruff formatting of modified Python files | PASS |
| `python -m pip check` | PASS |
| `tool/build-apk.ps1` | PASS, current Flutter compilation then Gradle packaging with kernel/source verification |
| `adb install -r SmallSteps-debug.apk` | Success |
| `adb shell am start -W .../.MainActivity` | Status ok; UI hierarchy showed Connected development |

Final APK SHA-256: `4B076EAEEB92C0708BB25147B26A3F08D018B8F2644A8EEF757F71FCD42606C1`. Build receipt: `outputs/frontend/.tool-state/verified-android-build.json`. This is a debug development build, not a signed study release. Gradle/Kotlin deprecation warnings remain. Backend tests have a Starlette/httpx deprecation warning; no dependency upgrades were made.

## Limits and next checks

The identified local port-8000 development service was restarted after the checks and its health endpoint responded successfully with Gemini configured. No live model request was sent. The isolated HTTP service used current code and was stopped with temporary credentials removed. APK update preserves existing application data; a cold restart also launched successfully. No claim is made that every persisted record, UI size, or network race was tested.

Documentation local links and code-fence balance passed validation. A limited common API-key-signature scan of application source and these guides found no matches; this does not certify unknown secret formats or prior Git history. Ignore rules cover local accounts, environment secrets, databases, research exports, generated APKs and logs.

Pending proposal decisions are not universally idempotent; ambiguous outcomes require refresh before retry. General offline writes, automatic conflict merging, pagination, production enrollment, formal instruments and migrations remain limitations. See [data and sync](DATA_AND_SYNC.md), [researcher manual](RESEARCHER_MANUAL.md), and [physical Android/iOS checklist](TROUBLESHOOTING.md).

Before any pilot: restart the development backend, rehearse only synthetic accounts, execute physical-device permission/quiet-hour/time-zone/reboot/tap checks, review Japanese and English prompts/instruments, approve event definitions and retention, and establish participant provisioning and deployment security. Never infer delivered or ignored notifications from local scheduling alone.
