# Final integration check — 2026-11-02

## Assessment and actual architecture

The tested development build integrates Flutter/Riverpod/go_router/Dio → authenticated FastAPI → PostgreSQL 18.6 using SQLAlchemy/Psycopg. Gemini `gemini-3.1-flash-lite` is server-side. Native local notifications and secure credential storage remain separate platform responsibilities. This is suitable for further synthetic supervised rehearsal, **not a certification of production security, complete synchronization or participant-study readiness**.

The running service responded at `127.0.0.1:8000/health` with Gemini configured. Active server configuration was checked directly: PostgreSQL, application role not superuser. Shared API tests use the separate `small_steps_test` database with randomly named disposable schemas. No SQLite-to-PostgreSQL migration was rerun and no existing participant records were changed. Earlier migration receipt and SQLite backups remain private. Existing uncommitted work was preserved; nothing was pushed or deployed.

Entry points and traced layers: [main.dart](../outputs/frontend/lib/main.dart), [app.dart](../outputs/frontend/lib/app/app.dart), [state.dart](../outputs/frontend/lib/app/state.dart), [repository.dart](../outputs/frontend/lib/data/repository.dart), backend [main.py](../outputs/backend/app/main.py), [accounts.py](../outputs/backend/app/accounts.py), [db.py](../outputs/backend/app/db.py), and [ai.py](../outputs/backend/app/ai.py). For detailed ownership/contracts, see [data and sync](DATA_AND_SYNC.md), [API contracts](API_CONTRACTS.md), [multi-user design](MULTI_USER_DESIGN.md) and [PostgreSQL setup](POSTGRESQL_SETUP.md).

## Baseline

- Git had existing multi-user and PostgreSQL implementation changes; no AGENTS.md was found.
- PostgreSQL service was running; active configuration used PostgreSQL 18.6 and a non-superuser application role.
- Backend baseline with PostgreSQL fixtures: **93 passed**; Ruff and dependency checks passed.
- Flutter baseline: **179 passed, 12 skipped**; analysis clean.
- Emulator was initially not running. The previous APK receipt described an earlier source snapshot; a new verified build was required after the logout fix.
- A new reproduction deliberately made secure-storage writes fail during logout. It failed before the fix with `StateError` from `SavedConnections.deactivate`; logout did not finish disconnecting.

## Confirmed defect and targeted fix

**High: secure-storage failure could leave a revoked/signed-out account visible.**

Reproduce: connect and remember a synthetic account; make secure storage unavailable; sign out. Previously, the server logout completed but device cleanup threw before `_api`/account state were cleared. With offline revocation plus a stale vault, automatic restoration was also a risk.

Expected: close the current account even when credential cleanup fails, explain incomplete cleanup, and prevent automatic restoration where device preferences remain available.

Fix: `AppController.disconnectBackend` writes a non-sensitive restoration-disable marker, attempts secure cleanup, then closes the API and removes visible account state regardless of secure-storage failure. Sign-out handles a second cleanup failure without leaving the account visible. Initialization respects the marker. A successful explicit remembered connection clears it, preserving normal restoration and linked DEV switching. If preference storage also fails, the app warns that durable cleanup could not be confirmed; it does not claim otherwise.

Regression: `test/multi_user_test.dart`, “secure storage failure cannot leave a signed-out account visible or restore it.” It passes after the fix, including a new controller initialization against the stale vault. Existing normal/control restoration and linked-account tests still pass.

No research prompts, instruments, consent text, assignments or intervention timing were changed.

## Additional failure check

`test_database_unavailability_returns_safe_error_and_recovers` in `tests/test_qa_regressions.py` injects a database failure into an isolated test engine. Health and authenticated task requests return 503 `storage_unavailable` without leaking internal exception text. Removing the injected failure restores health. The actual application PostgreSQL service was not stopped to test this.

## Feature matrix

PASS means the named evidence passed, not that every platform and edge case was exercised.

| Feature / boundary | Result | Evidence / limits |
|---|---|---|
| PostgreSQL selected; non-superuser application role; separate test database | PASS | Direct configuration/database checks and PostgreSQL API fixture run |
| Invitation, login/logout, expiry/revocation, disabled accounts, consent gate | PASS | Backend account tests; Flutter session/form tests; HTTP account suite |
| Cross-account task, chat, proposal, request-status, export and erasure isolation | PASS | Negative backend tests and separate controller histories |
| Standard control and immutable assignment | PASS | Server restrictions, controller tests and participant-build guard |
| Remembered mobile session and secure-store failure | PASS | Injected storage/controller tests; physical iOS storage not tested |
| Task create/edit/delete/complete/reopen/start/pause/reschedule | PASS | Existing controller/API flows, state tests and HTTP CRUD/version checks |
| Plans, difficulty and future-self context filtering | PASS | Persistence/context regressions; no questionnaire-validity claim |
| AI breakdown/correction approval, edit and rejection | PASS | Mock repository/controller/API/HTTP tests; model prose cannot execute changes |
| Separate agent histories and linked synthetic account switching | PASS | Existing account/conversation and in-flight request guards |
| Failed chat retry, duplicate IDs, stale updates and legacy records | PASS | Regression suites; some ambiguous proposal decisions still require refresh |
| Focus countdown/pause/resume/background timestamp model | PASS | Automated state tests; no new physical lock-screen observation |
| Timer ending does not complete task; reported starts differ from focus starts | PASS | Existing focus/event tests and code trace |
| Reminder edits/cancellation, denied permission, scope, quiet hours and caps | PASS | Policy and injected native-service tests; not delivery evidence |
| Actual scheduled notification delivery on locked/terminated device | NOT TESTED | Physical Android/iOS checklist still required |
| English/Japanese UI, request language, raw user-text preservation | PASS | Existing locale, widget and HTTP tests; native linguistic review outstanding |
| Keyboard/scroll/empty/error/long and Unicode input | PASS | Existing widget validation/layout coverage; exhaustive device sizes not tested |
| Backend unavailable, malformed replies, storage/network failures | PASS | Existing error tests plus new isolated database failure test |
| Research event/check-in/export ownership, stable IDs and timestamps | PASS | Existing API/HTTP tests; delivery/ignored/task-completion claims remain limited |
| Two real Gemini requests, one per agent, stored replies | PASS | Isolated PostgreSQL schema, server provider, real network; not mocked |
| Consistent experimental persona separation / efficacy | NOT TESTED | Two samples are insufficient; see live observations below |
| General offline task/profile conflict merging | NOT TESTED | Not implemented; connected mutations require server |
| Full native invitation-to-chat journey for every condition | NOT TESTED | Widgets/controllers and real HTTP verified separately |
| iOS compilation, production load, deployed TLS and disaster recovery | NOT TESTED | No corresponding environment or operational test |
| Approved participant enrollment/instruments | BLOCKED | Intentionally disabled; demonstration consent is not approval |

## Live AI observations

Exactly **two synthetic live Gemini chat calls** were made in a disposable test schema, not existing accounts. Both returned HTTP 200 and their two-turn conversations were present in backend history. Both responses were brief, supportive and suggested opening a paper/reading its abstract. The Self-Agent sample did not explicitly use future-self framing, and the samples were similar. This verifies provider connectivity and persistence, **not reliable persona distinction**. Review a predefined behavioral evaluation set before a study; no prompt was changed to optimize these two samples.

All other AI integration tests used the mock provider. No completion or improvement in procrastination was inferred from model replies.

## Executed commands and final results

Commands ran from the corresponding frontend/backend directories using documented Windows helpers. Backend test environment read only the private test connection; no credentials were printed.

| Command / check | Actual result |
|---|---|
| `python -m pytest -q` with isolated PostgreSQL fixtures | **94 passed**, one existing Starlette/httpx deprecation warning |
| `python -m ruff check app tests tool` | PASS |
| `python -m pip check` | PASS |
| Dart formatting of changed files | PASS |
| `flutter analyze --no-pub` | PASS, no issues |
| `flutter test --no-pub --reporter json` | **180 passed, 12 skipped** |
| Participant guard with `RESEARCHER_DEMO=false` | **1 passed** |
| Dart-to-FastAPI/PostgreSQL opt-in HTTP suite | **6 passed**, all three conditions; mock AI |
| `tool/build-apk.ps1` | PASS; current Flutter compilation and verified Gradle packaging |
| Emulator install, source/APK identity and launch | PASS; install Success, cold launch Status ok, installed APK hash matches receipt, UI shows Connected development |

Final debug APK SHA-256: `7FC7D2DF059FAFD75FE233C3D5F7BDD28DEB70DDDC91F0F2BF468E29D860855B`. Source receipt: `outputs/frontend/.tool-state/verified-android-build.json`, source hash `1D364C7B6592E93544766016A25F5DB0C7F002260F6FDC26AABB625FFCC92CCF`. The installed emulator APK was independently hashed and matched. Build warnings concern existing Gradle/Kotlin deprecations. No iOS build was attempted. The installed prior APK was replaced with this verified build; existing app data was retained.

Logs: backend `.tmp/final-baseline.log`, `.tmp/final-regression.log`, `.tmp/final-live-smoke.json`; frontend `.tool-state/final-*.log` and `.jsonl`. They are ignored/private. The secure-storage reproduction is recorded in `final-reproduction.jsonl` as a deliberate pre-fix failure.

## Main files changed in this check

- `outputs/frontend/lib/app/state.dart`: safe disconnect/logout and restoration-disable marker.
- `outputs/frontend/test/multi_user_test.dart`: secure-store failure reproduction/regression.
- `outputs/backend/tests/test_qa_regressions.py`: database unavailability and recovery regression.
- This report and the matching authentication/synchronization documentation.

## Remaining limits and how to run

Start the PostgreSQL Windows service if stopped. From `outputs/backend`, run `RUN-BACKEND.cmd`; health is `http://127.0.0.1:8000/health`. Flutter's Android emulator address remains `http://10.0.2.2:8000`. Install the verified `outputs/frontend/SmallSteps-debug.apk`, then open Small Steps. Keep demo versus connected mode visible and use synthetic accounts for further rehearsal. Existing account instructions are in [developer manual](DEVELOPER_MANUAL.md).

Before participant use, complete physical permission/quiet-hour/reboot/notification-tap checks, English/Japanese review, a persona evaluation set, approved instruments/consent, protected device caches, deployment and backup/restore procedures. Local pending-report caches are not encrypted by ordinary preferences; universal offline sync and provider-level exactly-once billing are not implemented. Do not infer a delivered or ignored reminder merely from scheduling, or completed work from focus timer use.
