# Live Self-Agent and Friend-Agent — 2026-11-02

## Implementation

Researcher Demo Mode can now link two synthetic `DEV-` accounts on the same backend and switch between them from the existing chat selector. This opens a different authenticated account; it does not alter either backend assignment. Tasks, profiles, reminders, pending reports and conversation history remain scoped to their own accounts. Connecting a normal or control account does not enable this selector. Participant builds still fail closed pending approved study configuration.

The connection screen offers **Remember this synthetic agent account**, **Link the other agent account**, and **Forget saved agent logins**. Tokens are saved only after authentication and assignment validation. Android/iOS use `flutter_secure_storage` (Android Keystore-backed encryption / iOS Keychain); test and browser-preview storage is session-only. No model API key enters Flutter. Android application backups are disabled; iOS signing entitlements are configured but have not been compiled or tested on macOS.

On startup, the selected saved account reconnects and loads server data. If authentication or networking fails, chat is blocked with a reconnect message rather than sending scripted replies. Switching validates the target account before leaving the current one; a failed transition attempts to restore the previous account. Busy requests and active focus sessions block switching. Disconnecting stops automatic reconnection; forgetting removes remembered logins. Tokens still expire according to backend policy and may need operator renewal.

## Actual checks

- Full Flutter suite: **170 passed, 6 optional skipped**, before the final reconnect/navigation refinements. `.tool-state/both-agents-full-tests.jsonl`.
- Final targeted account suite: **7 passed**. Includes one-tap account isolation, history restoration, restart, offline restore without mock fallback, failed target, unlinked restrictions, forgetting, and nonremembered-session behavior. `.tool-state/live-accounts-final.jsonl`.
- Participant-build guard (`RESEARCHER_DEMO=false`): **1 passed**. `.tool-state/both-agents-participant-test.jsonl`.
- Final direct Dart analysis with fatal infos: **no issues**.
- Android source/kernel-verified APK build: **PASS**, installed on `emulator-5554` with existing data preserved. SHA256 `19E068379F42C3CDD0941ED3230782B5790133A53F60328FBBD1412A660DE945`.
- Existing synthetic Self-Agent account and new synthetic Friend-Agent account authenticated and linked through the app. Both credential files are ignored by Git. No production participants or notifications were used.

The cached build initially lacked new secure-storage dependencies. Added an opt-in `-Online` switch to `tool/build-android-verified.ps1`; online dependency resolution and packaging then succeeded. Normal builds keep their prior offline default.

## How to use

Keep `outputs/backend/RUN-BACKEND.cmd` running. In the installed Android app, open Chat and tap **Self-Agent** or **Friend-Agent**. With both remembered synthetic accounts linked, this changes the actual authenticated backend account and history. Start the backend again after reboot; the app can then restore the selected saved login.

For a fresh installation, connect and remember one synthetic account using Settings → Development backend, choose **Link the other agent account**, then connect and remember the other account. The emulator backend address is `http://10.0.2.2:8000`. Never paste a Gemini/OpenAI API key into the participant-token field.

## Limits

Live connectivity checks are not a systematic evaluation of persona quality, intervention effectiveness, notification delivery, or Japanese wording. Separate synthetic datasets are intentional; switching does not copy tasks between them. Physical Android and iOS testing remain outstanding. Do not use this researcher account-switching workflow to change an enrolled participant's experimental condition.

Secure-storage implementation reference: [maintainer documentation](https://pub.dev/packages/flutter_secure_storage).

A native check revealed Chat redirected to Today during the temporary consent reset while switching accounts. The router now keeps Chat mounted during a validated synthetic-account transition. A dedicated route regression test passes; participant-mode routing is still restricted.

## Final native verification
Both Self-Agent and Friend-Agent returned real Gemini replies to synthetic messages sent through the emulator. One-tap live switching was observed. Force-stopping and reopening the app restored the saved Self-Agent login without re-entering a token. Returning to Friend-Agent restored its separate live history; its own reply was visually confirmed after scrolling. The app is left connected to Friend-Agent. Screenshot: work/both-agents-live.png. The first automated history-visibility assertion ran before the latest reply was in view; a focused follow-up confirmed visibility and saved the screenshot. No history loss was observed.

