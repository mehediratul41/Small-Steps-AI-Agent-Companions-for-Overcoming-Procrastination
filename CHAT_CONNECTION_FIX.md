# Chat connection diagnosis — 2026-11-02

The screenshot's generic response to “hi” came from the frontend's `MockResearchRepository`, not Gemini. `repositoryProvider` defaults to that scripted demo until a development account connects. The FastAPI service was stopped at diagnosis. Backend `.env` already selected Gemini; no credentials were added to Flutter.

## Changes and verification

- Started the existing FastAPI development service on `127.0.0.1:8000`; `/health` confirms Gemini configuration. Android emulator uses `http://10.0.2.2:8000`.
- One synthetic generation request through the configured Gemini SDK succeeded. This verifies connectivity only, not persona quality or clinical effectiveness.
- Added an explicit English/Japanese scripted-demo notice and a direct **Connect AI backend** action in chat.
- Demo greeting replies now acknowledge greetings and disclose the scripted service, rather than inventing frustration about the task. Normal demo task responses remain scripted.
- Preserved assignment restrictions: connected accounts use server-assigned agents; local demo switching does not override them. Existing `DEV-SELF-01` is an already-onboarded synthetic Self-Agent account.
- Frontend focused regression tests: **27 passed, 1 optional screenshot test skipped**. Includes greeting disclosure and navigation to connection, API repository and bilingual regression cases. Evidence: `outputs/frontend/.tool-state/chat-fix-tests.jsonl`.
- Backend API/language tests: **24 passed**, one existing Starlette/httpx deprecation warning. No production data was used by these tests.
- Direct Dart analysis with fatal infos: **no issues**. Fixed a braces lint in the previously added reminder-pause code.

## Using actual AI

Open Settings → Connect to development backend (or the chat connection action), use the emulator URL above and the existing development participant token stored locally at `outputs/backend/local-accounts.json`. Never enter the Gemini API key into Flutter. The server needs to keep running; restart with `outputs/backend/RUN-BACKEND.cmd` after Windows restarts. Development tokens are intentionally not persisted by the app, so a process restart can require reconnecting. Connection keeps the local demo dataset separate; it does not upload that history automatically.

Do not post the credential file, `.env`, database, screenshots containing credentials, or participant conversations to the public repository.

## Android result
Updated debug APK built successfully (SHA256 F5D8A52B1C97BA4C4653558F79D1229CBF1ADB25CA239E8893D6F33139700993), installed with data preserved, and launched on emulator-5554. Connected the already-onboarded synthetic DEV-SELF-01 account through the app. The UI now shows Connected development and Self-Agent. Sent one explicit synthetic connection-test message from the emulator and visually observed a Gemini reply. Evidence: work/live-chat.png. This is an end-to-end connectivity check, not a persona evaluation. Friend-Agent live behavior was not evaluated in this session; the server assignment remains locked by design.

