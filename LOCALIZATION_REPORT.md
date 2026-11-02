# English and Japanese localization

Implemented 2026-10-31 in the existing frontend and backend, preserving experiment assignments and task storage.

## Delivered

- Globe language menu on onboarding and main screens; Settings language selection. English / 日本語 choice is saved independently of participant assignment.
- Flutter generated localization catalogues, Material date/time localization, Japanese dates and bundled Noto Sans JP with SIL OFL license.
- Translated onboarding, consent demonstration, navigation, task forms, focus, insights, check-ins, settings, agent actions and reminder controls.
- Japanese agent responses and task proposals in mock mode; validated `language: en | ja` requests and Japanese response instructions in the backend. Persona and control-condition restrictions remain unchanged.
- Japanese reminder templates use existing scheduling, cancellation, quiet-hour and frequency rules. Changing language refreshes pending reminder copy without changing stable notification IDs.
- Task titles, user text and existing conversation history are preserved verbatim. Future replies use the selected language; retries retain the original request language. Canonical research codes remain stable; language metadata is recorded.

## Actual verification

| Check | Result |
| --- | --- |
| Flutter dependency resolution and localization generation | PASS |
| Existing Flutter regression suite | PASS: 152 tests; 5 optional skips, `.tool-state/bilingual-regression.jsonl` |
| New localization suite | PASS: 11 tests; 1 optional capture skipped, `.tool-state/bilingual-focused.jsonl` |
| Japanese screen capture test | PASS: five screenshots under `work/ja-review` |
| Existing backend suite | PASS: 70 tests before new bilingual cases |
| New backend bilingual cases | PASS: 7 tests, mocked AI only |
| Final direct Dart analysis, fatal infos | PASS: no issues |
| Final full Flutter reruns | BLOCKED: Flutter tester loopback socket error 10057 / connection closed; not counted as passed |
| Updated Android compilation | Flutter source compilation completed; Gradle packaging BLOCKED by inability to connect to its local daemon |
| New APK installation / native Japanese runtime | NOT TESTED; existing APK remains the earlier build |
| iOS, physical notification delivery, live Gemini Japanese quality | NOT TESTED |

Focused tests cover language persistence, agent separation, request language on retry, approved proposals, canonical check-ins, reminder identity, language controls, original task text, demo consent and core routes on small/landscape screens at 150% text size. Visual inspection found missing glyphs in explicit Inter chip/button styles; those styles now include the bundled Japanese fallback. Final analysis passes after that fix; screenshot recapture is blocked by the current tester socket restriction.

## Run and maintain

From `outputs/frontend`, run `./tool/flutter.ps1 run` and use the globe menu → 日本語. Restart the updated development backend before using bilingual API requests. To package Android, run `./tool/build-apk.ps1` in a normal Windows terminal with local process networking available. This session did not deliver a new verified APK.

Edit `lib/l10n/app_en.arb` and `app_ja.arb`, run `./tool/flutter.ps1 gen-l10n`, then `python tool/generate-display-catalog.py` and Dart formatting. New widgets should use the generated typed strings. The canonical display bridge must never be applied to arbitrary task or chat content.

Japanese font source: Google Fonts `google/fonts`, `ofl/notosansjp`; source license is bundled at `assets/fonts/NotoSansJP-OFL.txt` and registered with Flutter's license registry. No new AI secrets or live API calls were introduced.

Before participant use, have the research team review Japanese consent, questionnaire and agent wording for linguistic and experimental equivalence. These demonstration translations do not constitute validated research instruments. Unknown external technical errors can retain their original server/platform wording.

## Android follow-up — 2026-10-31
Network permission resolved the Gradle socket restriction. Updated APK successfully built and source/kernel verified. SHA256: 0E33B76B8025C25C9ECF8C133A2BFDE7B88861D17B57E8FCF5E95454F6F7015F. This supersedes the packaging blocker above.

Updated APK installed successfully with adb install -r on emulator-5554; activity launch confirmed Status: ok. Native Japanese dashboard and globe language button visually observed. Existing task text preserved. Screenshot: work/bilingual-native.png.
Native English dashboard also visually observed; both languages render with the globe button visible.
