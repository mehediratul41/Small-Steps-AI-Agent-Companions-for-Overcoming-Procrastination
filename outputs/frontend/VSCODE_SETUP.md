# VS Code on this PC

Configured on 27 October 2026. Open this `frontend` folder; `.vscode/settings.json` points at the existing Flutter SDK, project-local Android SDK/JDK and package cache. No global PATH changes are required.

Flutter, Dart and Codex extensions are installed. VS Code was reloaded and its output confirmed Flutter initialization exited with code 0 and the device daemon started. Chrome appeared in the status bar. The prior initialization error was a Git ownership check on the Flutter SDK; a process-local safe-directory setting for that specific SDK resolves it.

## Run

Use Run and Debug → **Small Steps · Chrome** → F5 for the browser. Use **Small Steps · Android/iOS** after connecting a supported device. **Small Steps · Participant guard** verifies the intentionally blocked enrollment screen. A separate Codex session is available through the Codex extension; sign-in requires you.

New VS Code terminals inherit Flutter, Java and Android tool paths from project settings. Existing terminals must be closed/reopened to inherit them. Outside VS Code, use the supplied wrapper:

```powershell
.\tool\flutter.ps1 pub get
.\tool\flutter.ps1 analyze
.\tool\flutter.ps1 test
.\tool\flutter.ps1 run -d chrome
.\tool\flutter.ps1 build apk --debug
```

Tasks → Run Task includes package restore, analysis, tests and web release build. The settings use absolute local paths and an installed JDK version; update those paths if moving the project to another computer.

## Android

Java 21, Android command-line tools, Platform Tools, SDK Platforms 35/36, Build Tools 36.0.0 and the Flutter-selected NDK are under `.tool-state/android`. Flutter recognizes the Android toolchain. Android Studio is optional when using a physical device with these command-line tools.

Android Emulator 37.2.12 and the Google APIs API 35 x86_64 image are installed. The `SmallSteps_API35` virtual device is under `.tool-state/android/user/avd`. VS Code has a custom emulator entry, **Small Steps Android 35 (software emulation)**, using `-accel off` and SwiftShader. The emulator acceleration check reported no usable hypervisor driver. No Windows features or drivers were changed. The restricted-shell launch was stopped. After explicit user approval, desktop launch through VS Code started the emulator process but did not produce a booted Android device: the local adb server reported `emulator-5554 offline`, the emulator console timed out, and VS Code reported launch failure. Software emulation on this host is currently unverified/unusable; app installation was not performed. The desktop emulator process could not be terminated by the restricted command environment and may need to be closed manually.

After booting this emulator on its default port, select **Small Steps · Android emulator** in Run and Debug. This profile explicitly targets `emulator-5554` so it cannot silently fall back to Chrome. For a physical phone, select the phone in the device picker and use **Small Steps · Android/iOS**.

Connect an Android phone with USB debugging enabled and personally approve its USB debugging prompt. Use `flutter devices` in a new VS Code terminal, then choose the phone in the status bar. Windows may display a firewall prompt for adb; review this yourself. This setup does not change firewall rules.

The Codex restricted shell currently fails to resolve adb's Windows user directory (`Cannot mkdir '\.android'`). VS Code running as the normal user started its device daemon and triggered the adb firewall prompt. Native device delivery and mobile acceptance scenarios remain unverified; follow DEVICE_VALIDATION.md after an actual device launch.

## Current verification

- Analyzer: no issues found.
- Automated suite: 53 passed, 2 configuration-specific tests skipped.
- VS Code Flutter initialization: succeeded after reload.
- Android SDK toolchain detection: succeeded.
- Web release build: succeeded on 27 October 2026.
- Android APK build: blocked in the restricted Codex shell. Java can read files but `Path.toRealPath()` throws AccessDeniedException for ordinary project files and Gradle jars. Shorter paths and explicit project/cache access did not resolve it. No successful APK is currently recorded.
- Gradle cache: `C:/Users/mehed/Documents/Codex/g`, configured consistently in the wrapper and VS Code settings. Old caches remain available.

## One-click Android build

The first normal-account attempt reached native JNI compilation but failed because CMake 3.22.1 was missing. That SDK component has now been installed. The Flutter wrapper was changed to a basic PowerShell script so Windows PowerShell preserves Flutter's `--debug` and `--verbose` arguments instead of consuming them as common parameters. The exact APK command with `--help` succeeded under Windows PowerShell after this fix. Rerun the launcher to verify actual compilation.

Double-click **BUILD-APK.cmd** from Windows Explorer, using your normal Windows account. It restores dependencies, builds the debug APK, and copies a successful result to **SmallSteps-debug.apk** beside README.md. It prints the SHA-256 hash and keeps the build output in `.tool-state/build-logs`. No phone is needed to compile. The launcher itself has been syntax-checked; successful native compilation outside the restricted shell remains to be verified. No Windows security settings or file ownership changes are performed.

iOS compilation/signing still requires macOS and Xcode. Windows desktop development requires extra C++ tools only if that platform is later added.
