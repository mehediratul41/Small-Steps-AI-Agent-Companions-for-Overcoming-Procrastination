# Connected development integration validation - 2026-10-27

Implemented an explicit connection screen and authenticated development API path, preserving the local demo and the participant enrollment gate.

Observed results:
- Flutter pub get resolved existing dependencies; no new packages added.
- Dart analysis after applying brace-style fixes: exit 0, no diagnostics (native-process output/error logs empty).
- Flutter full suite: 89 assertions/tests passed, 3 opt-in tests skipped. The enclosing Windows Flutter process intermittently exited 0xC0000008 after printing All tests passed; do not mistake that cleanup failure for a clean tool exit.
- Opt-in live Flutter controller test: exit 0, 1 passed. It exercised real Dio requests to FastAPI/Gemini, task creation, refinement and acceptance, chat, explicit task start, focus start/pause/end without completion, reported completion, refresh, versioned deletion and disconnect.
- Backend pytest: 17 passed, one upstream Starlette/httpx deprecation warning.
- Backend Ruff checks passed.
- Browser proof: connected Chrome web client to FastAPI using DEV-SELF-01; observed server-owned tasks and a real Gemini reply in the Flutter chat screen. Screenshot: design-review/connected-gemini-web.png.
- Provider key was not passed to Flutter or embedded in Dart defines. Participant token is entered at runtime and kept in memory.

Build limitations:
- Flutter emitted an updated web artifact with the connection UI, then its process exited with Windows 0xC0000008. The emitted web preview was served and exercised successfully; a clean release-build command is not claimed.
- Android assembleDebug failed in compileFlutterBuildDebug because flutter.bat exited with 0xC0000008. The existing SmallSteps-debug.apk was deliberately not overwritten. It does not contain the new connection UI until a successful rebuild/reinstall.
- No iOS build or physical-device integration test was performed.

Runtime servers during verification: FastAPI on 127.0.0.1:8000, web preview on 127.0.0.1:8787. Availability after this session depends on those processes remaining open.

Development scope: synthetic accounts only; immutable server condition; task revision checks; UTC network dates; server refinement IDs; stable chat retries; account/server-scoped pending reports and timer cache. Notifications are disabled while connected. Tokens must be re-entered after restart. Real enrollment, approved consent/instruments, production credential lifecycle, retention/withdrawal and multi-client offline task resolution remain outside this development mode.
