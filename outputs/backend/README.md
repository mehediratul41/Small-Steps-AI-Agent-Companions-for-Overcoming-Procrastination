# Small Steps backend

Agent integration update (2026-10-30): `POST /api/tasks/refine` also accepts `mode: "correction"` with the saved current task. It returns a versioned `correction` proposal (title, description, minutes, reason). Approve edited fields with `POST /api/refinements/{suggestionId}/accept` and `{task_version, correction}`; reject through the existing reject route. Breakdown remains the default mode with `{task_version, subtasks}` approval. Modes cannot be mixed; ownership, assignment and task version are checked before mutation. No schema migration or client-selectable assignment endpoint was added. See [agent audit](../../AGENT_FEATURE_AUDIT.md). Restart the development server to load updated source; no live provider evaluation is implied.

FastAPI development backend for the existing Flutter prototype. The default is **mock AI and synthetic accounts**, with SQLite persistence. Gemini uses Google's official `google-genai` SDK; the provider can only be called by the server. PostgreSQL is configurable via SQLAlchemy/psycopg. This is an initial backend, not an approved research deployment.

## Start on this PC

Double-click `RUN-BACKEND.cmd`. The installed `.venv` is ready. Open http://127.0.0.1:8000/docs. Stop with Ctrl+C. The script binds to this PC only, runs one worker, and creates `.env` from the example if absent.

For a fresh environment (Python 3.12+), open PowerShell in this folder:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-lock.txt
Copy-Item .env.example .env
.\.venv\Scripts\python.exe -m uvicorn app.main:create_app --factory --host 127.0.0.1 --port 8000 --workers 1 --no-access-log
```

The lock file records versions tested on Windows/Python 3.12; `requirements.txt` records acceptable update ranges. Re-test after updating dependencies. Database tables are created for a new development database; schema migrations are not yet installed.

## Synthetic participant accounts

Use a second terminal in this folder. There is no public signup/admin API, and clients cannot change assignments. A local operator explicitly provisions each synthetic account (this is **not an RCT randomization algorithm**):

```powershell
.\.venv\Scripts\python.exe -m app.admin create --id DEV-SELF-01 --condition selfAgent --token-file local-accounts.json
```

`friendAgent` and `standardControl` are the other conditions. Choose a new ID and new credential filename for each account. Keep all credential files private and outside version control. Tokens are random, expire after seven days by default, and are stored as SHA-256 hashes in the database. The local file contains the raw token. It is not printed in logs.

In Swagger `/docs`, click **Authorize** and enter the token from that local file. First call `GET /api/participants/me`, then `POST /api/participants/onboarding` with:

```json
{"acknowledged":true,"consent_version":"demo-consent-v1","demonstration":true}
```

This records demonstration acknowledgment only. Genuine informed consent, eligibility, approved instruments, token refresh/login, and participant enrollment remain unavailable. `APP_MODE=production` deliberately fails validation.

Run a complete synthetic HTTP workflow (creates a task and reports it completed):

```powershell
.\.venv\Scripts\python.exe -m app.smoke --account local-accounts.json
```

Revoke or rotate credentials using the local CLI:

```powershell
.\.venv\Scripts\python.exe -m app.admin revoke --id DEV-SELF-01
.\.venv\Scripts\python.exe -m app.admin rotate --id DEV-SELF-01 --token-file fresh-account.json
```

Rotation preserves assignment; revocation disables access. It does not erase historical records. Deletion, withdrawal, retention, and backup policies must be agreed before real data is collected.

## Enable Google Gemini

1. Create a project/key in [Google AI Studio](https://aistudio.google.com/api-keys).
2. Edit **backend `.env` locally**, setting `AI_PROVIDER=gemini`, `GEMINI_API_KEY`, and `GEMINI_MODEL` to an available text model ID in your account. Do not share the key in chat, source control, Flutter, `--dart-define`, or an APK.
3. Restart the backend. `/health` reports the chosen provider/model without exposing credentials.
4. Run the smoke workflow using synthetic text first. It makes two potentially billable requests for AI assignments. There is no automatic fallback to mock and no automatic retry after a provider failure.

[Google SDK reference](https://googleapis.github.io/python-genai/) and [structured output documentation](https://ai.google.dev/gemini-api/docs/structured-output). Both personas use the same configured model, temperature, limits, and task capabilities; their system instructions differ. Prompts are versioned in `app/ai.py`. No browser search, external tools, real-friend cloning, autonomous task changes, or automatic nudges are enabled.

Pin a model and prompt version for each experiment. Mock/Gemini provenance is stored on conversation/refinement records. A model provider can still change behavior; generation is not guaranteed reproducible. Review Google account data-use settings and institutional approval before sending actual research text.

## API and concurrency rules

OpenAPI is generated at `/openapi.json`; interactive docs are at `/docs`.

| Endpoint | Behavior |
|---|---|
| `GET /api/participants/me` | Authenticated, immutable assigned condition |
| `POST /api/participants/onboarding` | Versioned demonstration acknowledgment |
| `GET/PATCH /api/participants/profile` | Optional stated goal/values/preferences |
| `GET/POST /api/tasks` | List/create owned tasks |
| `GET/PATCH/DELETE /api/tasks/{id}` | Read/full replacement edit/soft deletion |
| `POST /api/tasks/refine` | AI proposal; saves a snapshot, never changes task |
| `POST /api/refinements/{id}/accept` | Explicit edited-subtask acceptance with revision guard |
| `POST /api/refinements/{id}/reject` | Rejection without task mutation |
| `POST /api/chat` | Assigned persona with task-scoped recent history |
| `GET /api/chat/history?task_id=...` | Last 10 turns; general chat when task omitted |
| `GET /api/ai-requests/{id}` | Inspect completed/failed/pending operation |
| `POST /api/focus-sessions` | Store a focus event; never marks task complete |
| `POST /api/events` | Atomic batch, stable event IDs and duplicate detection |
| `POST /api/check-ins` | Dated raw demonstration check-ins; no score inference |
| `GET /api/progress` | Up to 10,000 client-reported events in insertion order |
| `GET /api/export` | Owned tasks/history/audit/check-ins, including raw text |

All data routes require bearer authentication. Except `me`/onboarding, they require current demonstration acknowledgment. Control accounts receive 403 on every AI route, including history and suggestion acceptance. Errors use `{error:{code,message}}`; validation responses omit submitted text. Request bodies are limited to 64 KiB. Local plaintext database/export files must be protected by the operator.

Task creation requires version 1. PATCH takes the **complete task**, with version = current + 1 (matches the existing controller's revision approach). DELETE requires `?version=current`. Compare-and-swap database updates reject stale edits with 409. Deletions retain history for review; they are not research-data erasure.

All timestamps must include UTC or an explicit offset. The Flutter adapter converts task timestamps to UTC at its network boundary and back to local time for display.

Chat/refine require `Idempotency-Key` (1-100 alphanumeric, dot, underscore, colon or hyphen). Reuse the same key and identical body after a network interruption to retrieve a completed response, without another provider call. A reused key with different content is rejected. Failed/pending requests require inspection using the status endpoint and an explicit new key for a new attempt. A provider timeout can still incur a charge. A process interruption may leave a pending job; there is no background replay. Local processing is serialized; run **one worker only**. This intentionally favors correctness over throughput for local development. Distributed quotas, job reconciliation, and multi-worker scheduling are future work.

Events record client occurrence time separately from server receipt time and server-assigned condition. Client reports are **not verified behavior**. Task mutation audit records are separate from progress events, preventing automatic double-counting. Focus time expiry is not proof of task completion. Arbitrary demo event details are retained; define the approved event vocabulary and analysis rules before study use.

## Flutter connection

The updated Flutter source has an explicit **Connect to development backend** screen. See [../frontend/CONNECT_BACKEND.md](../frontend/CONNECT_BACKEND.md). It uses a synthetic participant token kept in memory, server assignment, UTC network dates, revision guards, stable chat request IDs, server proposal acceptance/rejection, and an account-scoped pending-event/timer cache. Local demo records stay separate. Older installed APKs must be updated.

GET /api/state is an authenticated read-only development snapshot of the account's tasks, profile, messages, events and raw check-ins. It requires the current development acknowledgment; control accounts receive no AI messages. Pagination is a future scaling step.

Real participant enrollment remains closed. Native connected reminders require per-account opt-in and OS permission; browser previews do not deliver notifications. Windows web uses http://127.0.0.1:8000; the official Android emulator uses http://10.0.2.2:8000. The server remains loopback-only.

## PostgreSQL

Create a local database and set, for example, `DATABASE_URL=postgresql+psycopg://USER:PASSWORD@localhost:5432/small_steps` in `.env`. Restart. SQLite data is **not** migrated automatically. The psycopg driver is installed, but PostgreSQL has not been started or integration-tested in this session. Add Alembic migrations, managed secrets, HTTPS, authentication lifecycle, backups, retention/withdrawal, access roles, and operational monitoring before deployment.

## Tests

```powershell
.\.venv\Scripts\python.exe -m ruff check app tests
.\.venv\Scripts\python.exe -m ruff format --check app tests
.\.venv\Scripts\python.exe -m pytest -q
```

Tests use fresh SQLite databases and synthetic tokens, never a real Gemini key. They cover auth/consent, immutable assignment, cross-participant access, control isolation, task revision conflicts, persistence, proposal acceptance/rejection, chat history/deduplication, provider failure/quotas, token expiry/revocation, events/check-ins, and official SDK request construction with mocked transport.

## Locally verified Gemini configuration (2026-10-27)

The local `.env` now selects `AI_PROVIDER=gemini` and `GEMINI_MODEL=gemini-3.1-flash-lite`. A user-created key is stored only in that ignored environment file. Live model authentication, synthetic generation, structured refinement, and a complete HTTP workflow passed. The distributable `.env.example` intentionally keeps mock defaults and an empty key.

Use `python check-gemini.py --list-models` to check available generation models, or `python check-gemini.py` for a small synthetic generation test. The latter sends a model request. The backend's refinement provider uses raw JSON Schema plus Pydantic output validation for compatibility with the Google API. See `VALIDATION.md` for the actual results and limitations.

## QA follow-up: development data erasure and provenance (2026-10-28)

`POST /api/participants/erase-development-data` requires the current account bearer token and `{"confirmation":"ERASE MY DEVELOPMENT DATA"}`. It serializes with AI work, logically deletes the owner's tasks, records and AI jobs, clears profile/acknowledgment, and revokes the token. An inactive account marker remains; backups, prior exports and physical SQLite page/WAL sanitization are not covered. This synthetic-account tool is **not** the approved participant withdrawal procedure. Nothing is erased automatically by QA or disconnecting.

Owned database operations recheck active credentials inside their transaction; PostgreSQL row locking is used where supported. SQLite stale writes fail rather than repopulating erased data. Tests use temporary synthetic databases; PostgreSQL remains untested.

Complete exports now include `runtimeProvenance` (current protocol, prompt, provider/model); each historical AI record retains its own provenance. Current shared prompt is `small-steps-agents-v3`: it describes permission-based phone reminders and unavailable browser delivery, without letting the model change preferences or claim scheduling/delivery. Personality strings and model parameters remain unchanged. Review/freeze v3 before study use and do not silently combine versions.

New client events `notification_schedule_registered` and `notification_opened` are client reports with source/time/condition, not verified delivery, ignored behavior, or task initiation. There is no server push or delivery acknowledgment.
