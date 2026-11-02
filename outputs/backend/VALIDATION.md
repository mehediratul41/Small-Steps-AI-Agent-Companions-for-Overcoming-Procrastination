# Backend validation record - 2026-10-27

Implemented under `outputs/backend`; the frontend Dart code and installed APK were not changed in this stage.

- Isolated Python 3.12 environment installed successfully. Dependency versions recorded in `requirements-lock.txt`.
- `python -m pytest -q`: **16 passed**, one upstream Starlette deprecation warning recommending httpx2 for TestClient. Tests still pass using installed httpx; no warnings were suppressed.
- `python -m ruff check app tests`: **All checks passed**.
- `python -m ruff format --check app tests`: **9 files already formatted**.
- `python -m pip check`: **No broken requirements found**.
- `start-backend.ps1` successfully started Uvicorn on loopback port 8000, mock mode.
- Live `GET /health`: **200**, development/mock, participant enrollment false.
- Live `GET /openapi.json`: **200**, **17 paths**.
- Local CLI provisioned synthetic DEV-SELF-01; raw credential saved only in ignored `local-accounts.json`.
- Live HTTP smoke workflow succeeded: current demo acknowledgment, persistent task, suggested subtasks, explicit acceptance, mock Self-Agent reply, user-reported completion.
- Official Google SDK request construction, matched persona settings, schema validation and exception redaction tested with synthetic credentials and mocked model calls. **No real Gemini request was made.** No Google key was supplied or created.
- SQLite tested; PostgreSQL driver installed, PostgreSQL server/migrations not tested.
- Frontend-to-backend integration, deployed HTTPS, real participant authentication/enrollment, approved consent/instruments, retention/withdrawal and production operation remain future work. Production configuration is intentionally unsupported.

A task edit audit test initially found a before/after snapshot aliasing bug. The implementation now captures the original task before the SQL update; the regression test passes. Refinement acceptance/rejection also uses a database state transition plus task revision guard.

The service may stop when the shell/PC closes. Relaunch with RUN-BACKEND.cmd. This record does not promise continuing server availability after this session.

## Live Gemini validation - after user-created key, 2026-10-27

This update supersedes the earlier no-live-request status. The user created the Small Steps key in Google AI Studio. Its value is stored in the ignored local `.env`; no secret was added to source, test fixtures, screenshots, or the APK.

- Google model listing authenticated successfully.
- The older gemini-2.5-flash generation route returned 404; gemini-3.8-flash returned timeout/high-demand errors. These were reported as failures, not successful generations.
- `gemini-3.1-flash-lite` returned a successful synthetic text response and is now the pinned local model.
- Live structured generation exposed a Google SDK conversion incompatibility: `response_schema` emitted `additional_properties`, which the service rejected. The provider now supplies `response_json_schema=Suggestion.model_json_schema()`, and validates the result with Pydantic as before. A live async structured request succeeded.
- Backend restarted in Gemini mode. `/health` returned HTTP 200 with `aiProvider=gemini`, `model=gemini-3.1-flash-lite`.
- Complete live HTTP workflow succeeded with synthetic text: demonstration acknowledgment, task creation, Gemini subtask suggestion, explicit acceptance, Gemini Self-Agent conversation, reported task completion.
- Regression suite after the fix: **16 passed**, same single upstream Starlette/httpx deprecation warning. Ruff checks passed and pip check found no broken requirements.
- The Google AI Studio project displayed Free tier. Billing configuration was not changed.
- The Flutter application remains local mock mode; no live participant enrollment or frontend synchronization has been enabled. Live Friend-Agent behavior has not separately been evaluated with a participant; its prompt parity and settings are covered by mocked automated tests.

## Flutter integration update - 2026-10-27

The frontend now supports explicit authenticated synthetic-account connections. A new enrolled/owned GET /api/state snapshot powers initial refresh. The live Flutter controller test passed against FastAPI/Gemini, and an actual Chrome Flutter conversation was verified. Backend pytest now reports 17 passed. See ../frontend/CONNECT_BACKEND.md and ../frontend/CONNECTION_VALIDATION.md for the complete instructions and actual checks, including Windows build-process failures. The older APK has not been overwritten or claimed updated.
