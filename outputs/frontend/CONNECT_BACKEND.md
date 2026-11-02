# Connect to the development backend

1. Start ../backend/RUN-BACKEND.cmd and leave its window open.
2. Launch the updated Flutter app. Open **Settings > Connect to development backend**, or use the connection button on Welcome.
3. Use http://127.0.0.1:8000 for web on this PC, or http://10.0.2.2:8000 for the official Android emulator.
4. Open ../backend/local-accounts.json privately. Enter its token value in **Development participant token**. Never enter the Gemini API key.
5. Read the fictional-data disclosure, check its box, and press Connect. A new account must acknowledge the development information before continuing.

The current synthetic account is DEV-SELF-01, assigned to Self-Agent. Separate Friend-Agent/control accounts can be provisioned through the backend admin CLI. The connected UI cannot change assignment. Real participant enrollment remains closed.

Tokens stay in memory; reconnect after an app restart. Disconnect restores the local demo without uploading or overwriting its records. Server data remains on the backend. Pending reports, unsent messages and focus state are cached unencrypted per server/account. Native connected reminders are available after per-account opt-in in Settings. They use neutral local notifications, require OS permission, and are cleared when disconnecting. Browser previews do not deliver notifications.

Tasks, chat, refinement acceptance/rejection, optional preferences/check-ins and focus reports use FastAPI. An authenticated /api/state snapshot reloads server data. Task mutations require a matching revision; dates are converted to UTC at the network boundary. Chat retries reuse their original request ID. Offline task edits are not silently queued; pending behavior reports retry after refreshing.

Chrome must use port 8787, matching the backend CORS allowlist: flutter run -d chrome --web-port=8787 --web-hostname=127.0.0.1. Stop any static preview already using that port first. Alternatively add the exact local origin to backend CORS_ORIGINS and restart it.

The older APK needs rebuilding/reinstalling to receive the connection screen. Loopback HTTP is permitted only in the Android debug configuration; release builds require HTTPS. A physical phone requires a deliberately configured reachable HTTPS service; the backend stays loopback-only. iOS compilation and device integration have not been tested and require macOS/Xcode.

The opt-in test/live_backend_test.dart exercises the controller against FastAPI/Gemini with synthetic data. Set SMALL_STEPS_LIVE_TEST=true and SMALL_STEPS_TOKEN_FILE to the local account file before running it. It makes two AI requests for an AI account; the normal suite skips it. No provider key or participant token is passed through dart-define.
