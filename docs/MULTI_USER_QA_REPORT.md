# Multi-user QA report — 2026-11-02

## Baseline and scope

Baseline Git commit: `51571f5`, clean working tree. No AGENTS.md found. Existing architecture, account isolation and research restrictions were inspected before editing. Baseline backend: 82 passing tests. Baseline Flutter: 176 passing tests, 9 skips (including opt-in HTTP tests); analysis clean. Existing CLI tokens and linked DEV switching worked but invitation enrollment and username/password login were missing.

All new database and HTTP checks used temporary SQLite databases, synthetic identities and mock AI. No production records, live provider calls, deployment or GitHub push were performed. The currently running development server was not restarted/migrated by this task. Source changes need the normal backend restart and APK update before use.

## Implementation

- New single-use, expiring, hashed invitations linked to preassigned participants.
- Argon2id username/password accounts; generic login failures, bounded authentication throttling, renewal through sign-in, disabled-account checks and server logout.
- One active bearer token per account, preserving existing ownership dependencies.
- Additive schema revision 2 and migration command, preserving old records.
- Flutter account screen with English/Japanese labels, invitation form, validation and separate acknowledgement routing.
- Normal/control secure mobile session restoration, isolated from researcher linked-account selection; web memory only.
- Sign-out guard for active operations/focus, explicit offline-revocation warning, local credential cleanup and existing scope-based reminder reconciliation.
- Erasure now removes the owned login and invitation as well as existing research records, while retaining the disabled participant tombstone.
- Recheck token identity before AI context preparation, supplementing existing final transaction checks.

No model persona, questionnaire, consent wording, randomization or intervention policy was changed. Participant builds remain fail-closed pending approved study setup.

## Executed verification

| Check | Result |
|---|---|
| `python -m pytest -q` | PASS: 89 tests; one existing Starlette/httpx deprecation warning |
| `python -m ruff check app tests tool` | PASS |
| Changed Python files formatted | PASS |
| `python -m pip check` | PASS |
| `flutter analyze --no-pub` | PASS, no issues |
| `flutter test --no-pub --reporter json` | PASS: 179 tests; 12 explicit skips |
| Real Dart/Dio → HTTP → FastAPI → SQLite contract suite | PASS: 6 tests, including invite/login/logout in all 3 conditions; mock AI |
| Participant-build guard (`RESEARCHER_DEMO=false`) | PASS, 1 test; study mode still fails closed |
| Android debug packaging via `tool/build-apk.ps1` | PASS; verified freshly compiled assets and source receipt |
| APK installation | PASS, `adb install -r` returned Success; initial launch wait timed out, UI checked separately |
| Native launch and account entry | PASS: Connected development rendered and Settings exposed Account / Sign in. A complete native enrollment/sign-in journey was not verified; HTTP and widget/controller checks are separate evidence |

Private logs: backend `.tmp/multi-*.log`, Flutter `.tool-state/multi-*.jsonl` and `multi-*-analyze.log`. The opt-in fixture deletes temporary credentials/database after shutdown.

APK SHA-256: `260F362625B66B0ABB01C892AAC8A98769ED670FAB6BEAB61BFBD7BC336EF07C`. Receipt: `outputs/frontend/.tool-state/verified-android-build.json`. Gradle/Kotlin deprecation warnings remain; no toolchain upgrades were introduced.

## Security and behavior matrix

| Scenario | Result |
|---|---|
| Invite enrollment; condition supplied by server; first access requires acknowledgement | PASS |
| Used/expired invitation and unknown extra assignment field | PASS |
| Password hash storage; absent plaintext password | PASS |
| Case-insensitive login; old token invalid after login; logout invalidates token | PASS |
| Expired token cannot read; password login renews active account | PASS |
| Disabled/deleted account cannot renew; generic failures | PASS |
| Username authentication attempt limit | PASS |
| Foreign task read/update/delete/chat/refinement/focus IDs | PASS: refused |
| Foreign proposal/request ID, export and erasure isolation | PASS |
| Empty other-user AI task context; standard-control AI endpoint refusal | PASS |
| Normal account/control restoration; no participant agent switching | PASS, mocked Flutter controller |
| User-to-user task/history isolation and sign-out | PASS, mocked Flutter controller |
| Account form validation and invitation mode | PASS, widget test |
| Legacy database upgrade repeated without changing account | PASS, SQLite |
| Existing task/chat replay, stale responses, notification scope tests | PASS in full regression suites |
| PostgreSQL concurrency, distributed throttling and production TLS | NOT TESTED |
| Physical notification delivery / iOS build | NOT TESTED; platform checks remain required |
| Complete native account-form journey | NOT TESTED; HTTP and widget/controller checks are separate evidence |
| Approved participant deployment, recovery-email delivery | MISSING |

Early new-test failures were corrected expectations: proposal absence returns the existing 409 contract, general chat includes an empty supportContext, and different AI operations need different request IDs. These did not demonstrate cross-account leaks.

Full-tree Dart format checking identified a pre-existing formatting difference in `test/chat_demo_disclosure_test.dart`; it was left unchanged to avoid unrelated edits. Changed Dart files were formatted. No perfect synchronization, production security certification or study readiness is claimed.

## Next operational steps

Follow [developer setup](DEVELOPER_MANUAL.md) to install the added locked packages, back up synthetic data, apply revision 2, restart the backend and rebuild/install Flutter. Issue invitations for two synthetic users and verify each has its own task and history on a device. Complete permission/logout/reminder-tap/restart checks before a supervised rehearsal. Production account recovery, deployments, encrypted research caches, formal consent/instruments and managed migrations remain work.
