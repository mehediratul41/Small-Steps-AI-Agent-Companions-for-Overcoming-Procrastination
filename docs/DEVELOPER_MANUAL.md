# Developer manual

## Active database

This PC now uses PostgreSQL 18.6, with preserved SQLite records. See [PostgreSQL setup and verification](POSTGRESQL_SETUP.md) for connection locations, tests, backups and safe recovery. Previous SQLite-default descriptions below describe the fallback/default template, not the current private `.env`.


## Invite-only multi-user development accounts

Normal Account now uses `AppConfig.baseUrl` (`API_BASE_URL` at build time); it no longer asks users to configure a server. **Create account** requires password confirmation. Use advanced development settings only for raw-token fixtures. See [returning-login verification and exact limits](PERSISTENT_USER_ACCOUNTS.md); the previous port-8767 DEV-UI demonstration is not permanent enrollment.

See [authentication](AUTHENTICATION.md), [multi-user design](MULTI_USER_DESIGN.md), [database migration](DATABASE_MIGRATIONS.md), and [QA](MULTI_USER_QA_REPORT.md). This is development rehearsal; participant builds remain disabled pending approved study setup.

From `outputs/backend`:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements-lock.txt
# Stop the server and back up the private development database first.
.\.venv\Scripts\python.exe -m app.migrate
.\.venv\Scripts\python.exe -m app.admin invite --id TEST-SELF-A --condition selfAgent --token-file private-invitation-a.json
.\.venv\Scripts\python.exe -m app.admin invite --id TEST-FRIEND-B --condition friendAgent --token-file private-invitation-b.json
.\.venv\Scripts\python.exe -m app.admin invite --id TEST-CONTROL-C --condition standardControl --token-file private-invitation-c.json
.\RUN-BACKEND.cmd
```

The CLI creates NEW participants and writes each code once to a new ignored file; it refuses an existing ID or output file. Share codes privately, never commit them or paste them into chat. Invitations expire in 72 hours. Choose synthetic usernames such as `test-alpha` and `test-bravo` and separate 12–128-character passwords on the app's **Welcome → Sign in / Use invitation** or **Settings → Account / Sign in** screen. Do not reuse an actual personal password for rehearsal. No condition selector is offered. After authentication, explicitly acknowledge the existing demonstration information.

Use `http://10.0.2.2:8000` from Android emulator and `http://127.0.0.1:8000` on local web. Use HTTPS outside local development; never expose the current development service directly to the internet. Sign out before the second user signs in. Check that tasks/history change, restart to test remembered login, and verify completed work remains with the original account. Login rotates the session token, so a second login signs out the previous device. There is no refresh-token or password-reset email flow.

`ACCOUNT_ENROLLMENT=false` disables new invitation redemption; existing password login remains available. Local `app.admin revoke --id ...` disables access, and `rotate` invalidates a token without changing assignment. There is no public admin API. To rerun isolated HTTP account tests, restart `tool/http_fixture.py` to get fresh invitations, then use the opt-in HTTP command below. Database/credentials are temporary; AI is mocked.

Passwords are never saved; mobile remembered tokens use secure storage, web memory only. A successful sign-out revokes the server token. Offline sign-out warns about unconfirmed server revocation. Stop ongoing requests/focus before signing out. Connected operations require the backend; no general offline mutation merge is implemented.


## Isolated HTTP contract rehearsal

From `outputs/backend`, run `./.venv/Scripts/python.exe tool/http_fixture.py` in a separate terminal. This starts a temporary mock-AI FastAPI service on port 8766 and creates ignored synthetic credentials; it does not load `.env` or use the existing database. From `outputs/frontend`, with the Windows helper environment described below, run `./tool/flutter.ps1 test --no-pub test/http_contract_integration_test.dart --dart-define=RUN_HTTP_INTEGRATION=true`. The three conditions exercise real Dart/Dio/HTTP/database contracts. Stop the fixture with Ctrl+C to remove its temporary credentials and database. By default these opt-in tests skip when the fixture is absent. These are not live Gemini evaluations.

## Verified environment

Windows; Flutter **3.47.4**, Dart **3.13.3**, Python **3.12.14**. Installed backend: FastAPI **0.162.0**, Pydantic **2.14.1**, SQLAlchemy **2.1.6**, Uvicorn **0.54.0**, google-genai **2.33.0**, pytest **9.1.1**, Ruff **0.17.3**. Flutter versions are resolved in `outputs/frontend/pubspec.lock`; backend pins are in `requirements-lock.txt`. Use these installed versions; this audit does not upgrade them.

## Project map

```text
docs/                         Current guides and verification report
outputs/frontend/lib/
  main.dart                   Bootstrap and injected services
  app/                        State, router, theme, config, language, reminders
  data/                       Typed models, repositories, saved logins, scheduler
  features/                   Screens and task-support review controls
  shared/                     Reusable widgets and feedback
  l10n/                       ARBs, generated code and display bridge
outputs/frontend/test/        Unit/widget/regression tests
outputs/frontend/tool/        Windows SDK/build/run helpers
outputs/backend/app/          FastAPI, schemas, SQLAlchemy, AI, settings, admin
outputs/backend/tests/        Synthetic HTTP and provider tests
outputs/backend/evals/        Existing evaluation materials; inspect before use
```

The local workspace has no Git repository. Preserve the existing files. `.gitignore` is a prevention rule, not a history scrub or secret scanner. The separately created public GitHub repository is not automatically synchronized with this workspace. Do not run `git add .` or publish until staged contents are reviewed.

## Setup and configuration

Use existing wrappers first; they set process-local SDK/cache locations rather than modifying Windows globally. On a clean machine install compatible Flutter, Python, Android SDK/JDK and an emulator. In the backend directory:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-lock.txt
# Copy only if .env is absent; do not overwrite an existing key.
Copy-Item .env.example .env
```

Example values, with placeholders only:
```dotenv
AI_PROVIDER=mock
DATABASE_URL=sqlite:///./data/small_steps.db
# For a deliberate live test:
# AI_PROVIDER=gemini
# GEMINI_API_KEY=<set locally, never commit>
# GEMINI_MODEL=<available model ID for your account>
```

`Settings` accepts only development mode. Production settings fail closed; this is intentional. Configured CORS origins are localhost/127.0.0.1 port 8787. `API_BASE_URL` exists in frontend config, but the connection screen currently selects its own platform-specific default; edit/enter the URL there rather than assuming a dart-define alone connects the app.

## Start, stop and connect

Backend terminal:
```powershell
Set-Location outputs/backend
.\RUN-BACKEND.cmd
# Equivalent existing environment command:
.\.venv\Scripts\python.exe -m uvicorn app.main:create_app --factory --host 127.0.0.1 --port 8000 --workers 1 --no-access-log
```
Ctrl+C stops a foreground server. Start from the backend directory so `.env` and the relative database path resolve correctly. Source edits require restart; the documented launcher does not use `--reload`. `/health` shows provider/model but not a model credential. Do not start a second process on the same port without identifying the first.

Frontend terminal:
```powershell
Set-Location outputs/frontend
.\tool\flutter.ps1 pub get
.\tool\flutter.ps1 devices
.\tool\flutter.ps1 run -d emulator-5554
# Optional web development, with different native capabilities:
.\tool\flutter.ps1 run -d chrome --web-port 8787
```

The emulator's `10.0.2.2` maps to the PC loopback. A browser on the PC uses `127.0.0.1`; a real phone does not. No public hosting, LAN HTTPS or physical-device connectivity is verified by this audit.

## Synthetic accounts

Run local provisioning, never a public signup endpoint:
```powershell
.\.venv\Scripts\python.exe -m app.admin create --id DEV-SELF-EXAMPLE --condition selfAgent --token-file local-self-example-account.json
.\.venv\Scripts\python.exe -m app.admin create --id DEV-FRIEND-EXAMPLE --condition friendAgent --token-file local-friend-example-account.json
```

Choose unused IDs/files; provisioning refuses existing identities and never changes an assignment. `standardControl` is the third condition. Complete demonstration acknowledgment in the app. Tokens expire after seven days by default; use the operator CLI when renewal is needed:
```powershell
.\.venv\Scripts\python.exe -m app.admin rotate --id DEV-SELF-EXAMPLE --token-file fresh-self-account.json
.\.venv\Scripts\python.exe -m app.admin revoke --id DEV-SELF-EXAMPLE
```

These commands affect the named account. Rotation requires reconnecting saved credentials; it preserves condition. Do not rotate/revoke real or unrelated accounts during testing. Mobile tokens use secure storage; backend model keys remain server-only.

## Builds and installation

```powershell
.\tool\build-apk.ps1
# Once, if a new dependency is unavailable in the offline cache:
.\tool\build-android-verified.ps1 -Online
.\.tool-state\android\sdk\platform-tools\adb.exe devices
.\.tool-state\android\sdk\platform-tools\adb.exe -s emulator-5554 install -r SmallSteps-debug.apk
.\.tool-state\android\sdk\platform-tools\adb.exe -s emulator-5554 shell am start -W -n jp.ac.shimane.smallsteps.small_steps/.MainActivity
```

This Windows workaround compiles Flutter assets first, packages them with Gradle excluding the already-executed Flutter task, checks the packaged kernel hash, and checks source hashes stayed stable. It does **not** skip Flutter compilation errors. The receipt is `.tool-state/verified-android-build.json`. `-r` preserves app data. Hot reload does not update a separately installed APK. This debug APK is not a signed release distribution.

iOS requires macOS, Xcode, a signing team and device/simulator testing. Keychain entitlement settings exist but are unverified here. No iOS build or delivery claim is made.

## Tests

From frontend:
```powershell
.\tool\flutter.ps1 analyze --no-pub
.\tool\flutter.ps1 test --no-pub
.\tool\flutter.ps1 test --no-pub test/participant_test.dart --dart-define=RESEARCHER_DEMO=false
```
From backend:
```powershell
.\.venv\Scripts\python.exe -m pytest -q --basetemp=.tmp/manual-tests
.\.venv\Scripts\python.exe -m ruff check app tests
.\.venv\Scripts\python.exe -m pip check
```

Tests create synthetic temporary databases and fake providers. The optional live/device/capture tests are not covered by “all default tests passed.” If Flutter's wrapper fails due to this host's handle issue, record the failure and try the installed Dart SDK's `dart analyze --fatal-infos`; do not mislabel that as a successful Flutter command. Check the current QA report for actual results.

## Database changes

Legacy domain data uses four tables with JSON payloads. Additive revision 2 adds login, invitation and schema-revision tables; see [migration procedures](DATABASE_MIGRATIONS.md). `create_all` alone cannot alter existing columns. Back up development data before schema work; do not delete a database as a routine repair. New optional JSON fields need defaults and semantic comparisons for legacy rows. The refinement compatibility regression covers that case. PostgreSQL concurrency, migrations, backup/restore and production retention require separate work.

## Make a safe change

- **Screen:** add a feature widget, add a route/guard in app.dart, call controller methods rather than writing a second task store, add ARB labels, and verify keyboard/small-screen behavior.
- **Endpoint:** add a strict schema, choose `authenticated/enrolled/agent`, use owned queries/transactions, define replay and errors, and test wrong-owner/control/expiry cases.
- **Model field:** change Dart constructor/copyWith/JSON and Pydantic defaults/bounds; audit repository serialization, snapshots, context, exports and legacy rows. Test a record created before the field existed.
- **Translation:** edit both ARBs, run `./tool/flutter.ps1 gen-l10n`, run `python tool/generate-display-catalog.py` using the installed Python, and format. Do not translate stored user content.
- **Prompt:** update a deliberate prompt/context version, review scientific consequences, add behavioral evaluation cases for both agents, and separate mock verification from live evaluation. Pin the model for a study; provider behavior is not fully reproducible.

Before a contract change, check: UI validation → Dart serialization → server validation → stored JSON → replay fingerprint → legacy compatibility → account ownership → errors → tests → documentation. Prefer one synthetic journey proving the change over repeated unchanged test runs.

Never log request headers, secure-store contents, `.env` values, raw credential files or real conversations. Debug with request IDs, status codes, synthetic record IDs, provider mode and bounded error categories.
