# iPhone setup and QA — 2026-11-03

## Assessment

The existing Flutter iOS target is prepared for **Mac-based compilation and synthetic testing**, not yet an installable or TestFlight-validated iOS release. This environment is Windows; no Xcode, iOS simulator, signing team or physical iPhone was available. No IPA/archive was built, signed or uploaded. Approved participant enrollment/instruments and deployment review remain separate research blockers.

Preserved Android code, accounts, server-owned assignments, secure storage, explicit AI-change approval, EN/JA content, DEV-only switching and default-off UX measurement flags. No prompts, consent wording, database records or backend deployment were changed.

## Audit and changes

| Area | Finding / action | Status |
|---|---|---|
| Native target | Existing `AppDelegate` delegates local notifications, registers plugins through implicit-engine bridge; `SceneDelegate` uses Flutter scenes | Source traced; native runtime UNVERIFIED |
| Dependency integration | Existing Swift Package Manager package reference, framework dependency and prepare pre-action; no Podfile | Preserved; Mac resolution UNVERIFIED |
| Deployment target | Project Debug/Profile/Release use iOS 15.0 | Preserved, no SDK upgrade |
| Branding | Small Steps name, teal/mint icon assets and launch storyboard already exist | Preserved; archive appearance UNVERIFIED |
| Network default | All native platforms previously inherited Android `10.0.2.2` | FIXED: Android retains alias; iOS/desktop/web default to loopback; explicit API_BASE_URL still wins |
| URL security | Local HTTP was accepted regardless of build mode in account/connect flows | FIXED: shared policy used by both; HTTP loopback only in debug, HTTPS required for profile/release, Android alias rejected on iOS/browser; URL credentials/query/fragment rejected |
| ATS | No local debug exception existed | Debug-only Info-Debug.plist allows local networking, never arbitrary loads; release/profile keep normal ATS |
| Native language metadata | Flutter supported EN/JA but native languages not declared | Added CFBundleLocalizations, Japanese known region, bundled EN/JA InfoPlist.strings with localized debug local-network purpose |
| Keychain | Runner.entitlements already contains plugin-prescribed keychain-access-groups; referenced in all three configurations | Preserved; device read/write/lock/signing UNVERIFIED |
| Reminder limit | Controller already limits pending slots to 60, below plugin-documented iOS limit | Preserved, not a newly added fix |
| Permissions | No automatic first-launch notification request; opt-in requests alert only, no sound/badge | Preserved; iOS delivery UNVERIFIED |
| Privacy | Cached plugin privacy manifests present | Archive aggregation and App Store disclosures UNVERIFIED |
| Signing artifacts | Ignore rules did not explicitly cover all Apple provisioning/archive files | Added mobileprovision/provisionprofile/p8/xcarchive/dSYM/local export-option exclusions |

Main changes: `outputs/frontend/lib/app/config.dart`, `lib/app/state.dart`, `lib/features/account.dart`, existing EN/JA error strings/generated localizations, `ios/Runner/Info.plist`, new `Info-Debug.plist`, EN/JA `InfoPlist.strings`, `ios/Runner.xcodeproj/project.pbxproj`, `test/ios_readiness_test.dart`, new `tool/check-ios.sh`, root ignore/LF rules and README. No CocoaPods migration, dependency upgrade, push service or additional background capability.

### Networking behavior

| Environment | Address / constraints |
|---|---|
| Android emulator debug | Default `http://10.0.2.2:8000` reaches host PC |
| iOS simulator debug | Default `http://127.0.0.1:8000` reaches the **Mac**, not this Windows PC |
| Mac browser debug | Loopback reaches Mac; browser CORS still applies |
| Physical iPhone | Use reachable HTTPS backend with trusted certificate; localhost is the phone |
| Profile/release/TestFlight | HTTPS only, including URLs entered or restored from saved credentials |

The current backend was previously configured on this Windows PC; its loopback service is not an iPhone-accessible HTTPS deployment. No reachable HTTPS deployment was provisioned or verified here. API_BASE_URL is configuration, never an AI key. Obtain a suitable HTTPS endpoint before physical-device connected testing. Do not substitute Android's alias, permit arbitrary loads, disable certificate verification, or embed database/model credentials in Flutter.

Debug ATS permits local networking only. Flutter validation deliberately still rejects plain HTTP LAN IPs/hostnames: no new insecure physical-phone policy was introduced. Debug local network purpose text is bundled in EN/JA. Profile/release have no ATS exception or base local-network purpose key. A restored old HTTP session in a distributed build now fails safely and requires HTTPS reconnection; it does not fall back to scripted AI. HTTPS network/TLS failures remain normal errors.

### App Store icon finding

The supplied 1024×1024 marketing PNG has an RGBA alpha channel (PNG type 6). Its visual design is already appropriate, but the legacy Any Appearance marketing asset needs opaque RGB export and archive validation before upload. No image was regenerated or branding changed. On the Mac, open that PNG in Preview, export PNG with **Alpha unchecked**, replace the same file, then verify:

```bash
sips -g pixelWidth -g pixelHeight -g hasAlpha ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
```

Expect 1024×1024 and no alpha for this legacy marketing slot. Review other supplied legacy slots during archive validation. This is a remaining asset-preparation item, not a passed upload check. Do not confuse this legacy catalog with newer layered Icon Composer transparency rules.

## Mac setup and simulator

Use a Mac supported by the chosen Xcode, compatible Flutter stable (verified here: **Flutter 3.47.4 / Dart 3.13.3**), Xcode plus iOS platform/simulator components and Git. Select Xcode, accept its license and install its first-launch components. Xcode/macOS versions are **not verified here**; use versions accepted by Flutter doctor and Apple's current submission requirements.

Copy/clone the working source including the current local changes. A GitHub clone may omit these uncommitted changes; never transfer private databases or secrets merely to compile the frontend. Do not copy Windows generated .dart_tool/build/ios ephemeral files.

```bash
cd /path/to/SmallSteps/outputs/frontend
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
flutter --version
flutter doctor -v
flutter pub get
bash tool/check-ios.sh
open -a Simulator
flutter devices
flutter run -d <SIMULATOR_ID> --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

The helper runs on macOS only, resolves current dependencies, lints plists and compiles an unsigned debug simulator app. It does not upload or sign anything. Default research mode supports synthetic rehearsal; it is not approved study enrollment. If no backend runs on the Mac, use scripted demo explicitly or supply the reachable HTTPS test backend:

```bash
API_BASE_URL=https://api.example.org bash tool/check-ios.sh
flutter run -d <SIMULATOR_ID> --dart-define=API_BASE_URL=https://api.example.org
```

`api.example.org` is a placeholder, not a deployed service. Existing architecture is SwiftPM: start with Flutter CLI so it generates `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage`. Then `open ios/Runner.xcworkspace` for signing/debugging. Do not create a Podfile or run pod init blindly. If Flutter reports a specific plugin requires CocoaPods fallback, follow its output and official migration guidance; no fallback was needed or tested on Windows.

On Windows the helper intentionally exits with “iOS compilation requires macOS and Xcode.” Installing more VS Code extensions cannot provide Xcode or an iOS simulator.

## Physical iPhone and signing

1. In Xcode select Runner target → Signing & Capabilities. Choose your authorized team and automatic signing. No team ID or certificate was invented.
2. Existing bundle ID is `jp.ac.shimane.smallsteps.smallSteps`; confirm you are authorized to use/register it. Otherwise select an identifier you control, updating Runner and related test identifiers consistently. Do not change an already registered app ID casually.
3. Connect/pair an iPhone, enable Developer Mode as requested, trust the Mac, select it in Xcode/Flutter and run with a trusted reachable HTTPS backend.
4. Test Keychain read/write/restart, lock/unlock, session expiry/logout and notification behavior before distributing.

A personal Apple account may support local-device development subject to Apple's signing restrictions. TestFlight distribution requires Apple Developer Program membership and appropriate App Store Connect permissions. Neither account access nor signing was available here.

Keychain remains the plugin's default unlocked accessibility with synchronization disabled by default; no shared App Group was added. Do not loosen access simply to make locked-phone reads succeed. Local notification delivery does not require reading a bearer token while locked. Keychain items can outlive reinstall; verify restoration/forgetting behavior and do not treat uninstall as guaranteed erasure. Existing per-account preference caches are not thereby encrypted and require the existing retention/privacy review.

## Archive / TestFlight handover — do not upload yet

After device tests, icon preparation, secure backend and privacy/research review:

```bash
flutter analyze
flutter test
flutter build ipa --release --build-name=1.0.0 --build-number=<UNUSED_INTEGER> --dart-define=API_BASE_URL=https://api.example.org
open build/ios/archive/Runner.xcarchive
```

Replace placeholders, choose a build number higher than existing uploads and inspect all resolved build flags. Keep `DEV_SUPPORT_FEEDBACK` and `DEV_REDUCED_SUPPORT` off. Current default `RESEARCHER_DEMO=true` is for synthetic development; `RESEARCHER_DEMO=false` preserves restricted participant routing and is not a shortcut around missing approved study onboarding. Choose the approved build configuration explicitly; do not distribute a researcher build to study participants by accident.

In Xcode Organizer validate the archive, inspect signing/provisioning and generated privacy report, then stop. Upload/distribution requires a separate explicit request. When authorized: create/select the matching App Store Connect record, upload via Organizer, wait for processing, complete truthful beta/privacy/export-compliance information, select internal testers with appropriate roles, and submit external testing for required TestFlight review. Do not promise review approval or timeline. Keep certificates, provisioning profiles, App Store keys and local export-options files out of Git. Paid membership/publishing/CI was not enabled.

## Privacy and SDK review

Cached native manifests were found in `shared_preferences_foundation 2.5.7`, `flutter_secure_storage_darwin 0.4.3`, `flutter_local_notifications 22.3.2` and `flutter_timezone 5.1.1`. shared_preferences declares the UserDefaults required-reason API for its use. This source inspection does **not** prove the generated archive includes every required manifest or that its declarations match your deployment.

No app-level privacy manifest with invented collection declarations was added. Review the Xcode archive privacy report and all SDK/required-reason API use. App Store privacy disclosures must describe actual accounts/identifiers, task/chat text, research events, retention and backend-to-Gemini transmission, including third-party handling and required user permission. No tracking/ATT prompt, camera/microphone/location permission or APNs entitlement is justified by current features. Do not guess encryption/export-compliance answers; review actual crypto use and Apple's current guidance.

## Actual checks and limitations

| Check | Result |
|---|---|
| Baseline analyzer | PASS, clean |
| Final Dart formatting / localization generation / analyzer | PASS, no issues after fixing two new brace lint findings |
| iOS readiness regression | PASS: 5 tests (platform defaults, distribution URL policy, debug policy, metadata/entitlements, icon references/dimensions) |
| Full Flutter suite | PASS: 197 passed, 13 skipped |
| Dio → FastAPI → isolated PostgreSQL synthetic contracts | PASS: 6 tests, all conditions, mock AI |
| Backend full suite | NOT RERUN: backend source unchanged; previous 95-test evidence is historical |
| Plist parsing and cached manifest inventory | PASS (Windows structural checks only) |
| macOS helper bash syntax / non-macOS guard | PASS; actual macOS build BLOCKED |
| Android regression build | PASS, current-source compilation + verified Gradle packaging |
| Xcode SwiftPM resolution / simulator compile/run | BLOCKED: no Mac/Xcode |
| Signing, iPhone install, Keychain runtime, lock behavior | BLOCKED: no Mac/team/device |
| Physical notification delivery / notification-tap native navigation | NOT TESTED |
| Marketing icon opacity / archive/privacy validation / TestFlight upload | NOT TESTED; RGBA source asset flagged above |
| Live Gemini persona quality / efficacy / production load | NOT TESTED |

Full shared regression includes focus semantics/duplicate starts/resume, locale layouts, raw text preservation, approved plan changes, standard-control restrictions, account/cache/history isolation, failed chat retries and reminder policy/reconciliation. It is not iOS-native end-to-end evidence. No extra live model requests were made. Synthetic HTTP data used a disposable PostgreSQL test schema, cleaned afterward; application/participant records were not edited.

The first HTTP-fixture launch in a Windows PTY failed because Application Control blocked a native SQLAlchemy DLL; the normal non-PTY launch worked without weakening policy. The successful six-test run used that fixture. No iOS native behavior is inferred from Android success.

Logs are ignored in `outputs/frontend/.tool-state/ios-*`. Android debug receipt: `.tool-state/verified-android-build.json`; APK SHA-256 `28E94360E747E66BAD95855AFA02092A2E9C16B930B67B57E94794E9C3360797`. This task built but did not install that Android variant. No IPA exists from this task.

## Physical-device checklist

Use synthetic users only. Record iPhone model/iOS, build number, language, backend and prompt version without recording credentials.

- First launch: demo vs connected clear; no premature notification prompt; consent separate from authentication.
- Login, restart, expiry/revocation, disabled account, logout/forget and reinstall; no leaked previous-user tasks/history or old notification taps. Test locked-device Keychain failure safely.
- Self-Agent/Friend-Agent own histories and assignments; DEV switching only authorized accounts; control AI endpoints/UI rejected.
- Task CRUD/subtasks, approved/refused corrections and plan saving/dismissal; failed mutations show errors without false success.
- Direct 5-minute start/rapid taps, pause/resume/background/lock/restart, existing session retained; no inferred task initiation/completion.
- Compact Chat, More actions, slow reply while reading older history, Show latest, keyboard and scroll behavior; retry lost response without duplicates.
- EN/JA, light/dark, smallest supported iPhone, landscape, large Dynamic Type and VoiceOver; raw tasks/chats unchanged.
- Notification allow/deny/re-enable via iPhone Settings → Apps → Small Steps → Notifications; returning to app refreshes permission. iOS may not show a second authorization prompt after denial.
- Task reminders foreground/background/terminated (record actual observed banner), local Tokyo time and timezone change, quiet hours/cooldown/daily cap, pending limit, edit/delete/complete cancellation, pause/resume and owned tap routing. Reopen app to replenish future slots; no claim of indefinite background replenishment.
- Distinguish scheduled/opened from observed delivery and never infer ignored status. Test Focus/DND and notification summary as platform effects.
- Validate archive assets/privacy/signing, HTTPS certificate failure and unavailable backend. End with export/deletion checks in isolated synthetic data, observing documented backup/retention limits.

## Official references consulted

- [Flutter iOS setup](https://docs.flutter.dev/platform-integration/ios/setup)
- [Flutter iOS build/release](https://docs.flutter.dev/deployment/ios)
- [Flutter SwiftPM guidance](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers)
- [Apple local-network ATS key](https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity/nsallowslocalnetworking)
- [Apple privacy disclosures](https://developer.apple.com/app-store/app-privacy-details/)
- [Apple TestFlight](https://developer.apple.com/testflight/)
- [Apple icon catalog guidance](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)
- [Notification plugin documentation](https://pub.dev/packages/flutter_local_notifications/versions/22.3.2)
- [Secure-storage plugin documentation](https://pub.dev/packages/flutter_secure_storage/versions/11.2.0)

Current Apple/Xcode submission requirements must be checked again at actual distribution time.
