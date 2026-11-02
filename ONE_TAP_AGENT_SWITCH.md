# One-tap chat switching — 2026-10-30

The Self-Agent / Friend-Agent selector is now pinned above the conversation. It stays visible while scrolling. Short/keyboard-constrained layouts compact the header; very short layouts show the active agent and a one-tap Switch button. No settings visit or confirmation is required in local Researcher Demo mode. Connected backend assignments remain locked. Separate histories and composer drafts are preserved; duplicate taps during switching are blocked.

Changed `outputs/frontend/lib/features/chat.dart`. Added a scrolling regression in `test/pinned_agent_switch_test.dart`; existing retry tests now settle scrolling before tapping.

Verification:

- Full Flutter suite: **152 passed, 5 optional skips**, exit 0; `.tool-state/pinned-switch-full.jsonl`.
- Direct Dart analysis with fatal infos: **No issues found**, exit 0.
- Verified Android build: success, source/kernel checks passed. APK SHA-256 `17320CDB1888BEF9C6976392DBAE9BAD1685524BEF4CA47C8F55EBC5FAAA32CC`; receipt `.tool-state/verified-android-build.json`, `2026-10-30T12:31:36.6686482Z`.
- Installed with `adb install -r` on online `emulator-5554`; data was retained. Android activity launch returned Status ok.
- Opened Chat, tapped Self-Agent once and observed its heading, then tapped Friend-Agent once and observed its heading. Left the emulator open on Friend-Agent. XML evidence: `work/pinned-switch-self.xml`, `pinned-switch-friend.xml`; viewed screenshot: `work/pinned-switch-friend.png`.

These are emulator UI/runtime checks. They do not verify physical notification delivery, live AI response quality or iOS. Backend code and prompts were unchanged in this UX iteration.
