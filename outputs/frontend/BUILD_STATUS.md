# Current web and Android build status — 27 October 2026

- Web: release build served at http://127.0.0.1:8787; the Today dashboard was opened and visually verified in the in-app browser. Live screenshot: design-review/running-web.png.
- Android debug build: **successful** using the installed JDK/SDK and `android/gradlew.bat -p android assembleDebug`. Gradle reported BUILD SUCCESSFUL, exit 0, with 184 tasks (149 executed, 35 up-to-date).
- APK: `SmallSteps-debug.apk`, copied from `build/app/outputs/apk/debug/app-debug.apk`, 160,691,199 bytes.
- SHA-256: `2A8E9F1C55D530FE73B1CFDE6C58DCAB487F0ADE3D5A9145A947A830DDE3CFD9`.
- `apksigner verify --print-certs`: passed, exit 0; Android Debug certificate. This is a testing build, not a production-signed release.
- Package: `jp.ac.shimane.smallsteps.small_steps`; version 1.0.0 (1); minimum Android API 24; target/compile API 36.
- Installation/activity launch: **verified after the Windows restart** on SmallSteps_API35 / emulator-5554. APK installation returned Success, the Welcome screen rendered, and a subsequent activity launch returned Status: ok. The emulator later disconnected; see the latest launch record below. Earlier software-emulation failures are historical.
- iOS compilation/testing: not performed; macOS/Xcode required.

## Build details

Explicit local network and user-path access allowed the direct Gradle build to progress past earlier restricted-shell path failures. The offline attempt first identified missing Kotlin dependencies; the online build downloaded them and completed native JNI compilation for arm64-v8a, armeabi-v7a, x86 and x86_64.

The legacy Windows PowerShell child process returned an invalid-handle exit even after printing successful dependency resolution. The launchers now prefer PowerShell 7 when available and retain Windows PowerShell as a fallback. Both edited PowerShell scripts pass parser checks. The full one-click build/install/launch workflow is still unverified; its syntax check does not establish a successful device launch. The successful build above used direct Gradle, not a claimed successful `flutter build apk` command.

Existing README, feature report and VS Code setup observations from earlier attempts are superseded by this status for Android compilation. Native notifications, background/lock-screen behavior and real-device accessibility remain to be tested.

## Install and run after connecting an authorized Android phone

From this frontend directory:

```powershell
.\.tool-state\android\sdk\platform-tools\adb.exe devices
.\.tool-state\android\sdk\platform-tools\adb.exe -s <device-serial> install -r .\SmallSteps-debug.apk
.\.tool-state\android\sdk\platform-tools\adb.exe -s <device-serial> shell am start -W -n jp.ac.shimane.smallsteps.small_steps/.MainActivity
```

An on-device USB debugging authorization prompt must be handled by the device owner. Installation is not attempted on an offline or unauthorized device. No security, firewall, virtualization or driver settings were changed.

## Additional emulator recovery attempts

At the user's request, further attempts used a separate official Android 9/API 28 x86 image and `SmallSteps_API28_Software`, leaving API 35 intact. The test device uses one core, 1536 MB RAM and a 480 x 800 display.

Google's official emulator archive supplied emulator 36.1.9, extracted separately under `.tool-state/android/emulator-compat-36.1.9/` without replacing installed 37.2.12. Its ZIP SHA-256 matched the published value: `edcba6087056d6c180ee7389ec6bc7518026bab673fbf9c57dd5ee341de3c55f`.

Both emulator versions failed before completing Android boot. Tests covered single-core software emulation, headless mode, SwiftShader/guest graphics and an alternative software CPU model. Launch through VS Code's Flutter: Launch Emulator command also failed with exit 3221225477 (0xC0000005), so the crash was reproduced outside the terminal launch path. No APK installation or activity launch on an emulator is claimed.

A separate experimental compatibility entry remains in VS Code's configured emulator list for reproduction. No Windows security, firmware, driver or virtualization settings were changed. The next practical test is a hardware-accelerated emulator or an authorized physical device; enabling acceleration may require administrator access and restarting Windows, and is not guaranteed to resolve this particular crash.

Official references:
- https://developer.android.com/studio/emulator_archive
- https://developer.android.com/studio/run/emulator-troubleshooting
- https://developer.android.com/studio/run/emulator-acceleration

The nested PowerShell 7 dependency command also returned an invalid-handle exit despite printing successful dependency resolution. The launcher preference change therefore does not establish a fix; direct Gradle remains the verified APK build path.

## Latest rebuild and acceleration check

The APK was rebuilt successfully again with direct Gradle: BUILD SUCCESSFUL in 30 seconds; 184 tasks, 20 executed and 164 up-to-date. The delivery APK was refreshed from that successful output.

A read-only Windows API check reports firmware virtualization enabled and second-level address translation available. WHvGetCapability succeeds (HRESULT 0) but reports the Windows hypervisor absent. The accelerated emulator launch exits 1 and explicitly requires hardware acceleration. ADB lists no connected devices. BIOS virtualization is therefore not the missing prerequisite identified by this check; Windows hypervisor configuration/activation is the next required step to investigate.

The primary VS Code API 35 profile and Android launcher now request acceleration explicitly rather than forcing the previously failing software mode. The launcher checks acceleration before starting a new emulator and reports the Windows Hypervisor Platform/restart requirement instead of waiting on another software boot. The script passes PowerShell parsing and the workspace settings parse as JSON. No Windows features, services, security settings or firmware were changed, and no Android install or successful native app launch is claimed.

## Administrator setup helper

`ENABLE-ANDROID-EMULATOR.cmd` opens `tool/enable-android-emulator.ps1`. Run it manually from Windows Explorer. It requests Windows administrator approval, enables the HypervisorPlatform optional feature with `-NoRestart`, logs the result, and waits for the user to close the window. It never restarts Windows automatically. Syntax was checked; the helper has not been executed and no feature change or successful emulator launch is claimed. Save work and restart Windows manually after Windows confirms the feature configuration.

## Successful Android launch after Windows restart

Windows Hypervisor Platform was enabled through the administrator setup helper and Windows was restarted. The restricted command environment still receives E_ACCESSDENIED (0x80070005) from Windows Hypervisor APIs, so its acceleration-check failure is not evidence that the Windows setup failed.

The existing API 35 hardware-acceleration profile was launched through VS Code's Flutter: Launch Emulator action in the desktop session. ADB reported emulator-5554 online as sdk_gphone64_x86_64. Android's sys.boot_completed returned 1. Installing SmallSteps-debug.apk returned Success. The first cold am start -W timed out while the app initialized, but its process existed (PID 2132) and the emulator visibly displayed the complete Small Steps Welcome screen. Repeating the activity-launch request returned Status: ok, delivering the intent to the already-running top-most activity.

Evidence: design-review/android-running.png, captured from the Android framebuffer with ADB. The app was not advanced through demo consent, and notification delivery, task flows, lock-screen timing and physical-device behavior were not newly tested.

The emulator subsequently disappeared from desktop windows and ADB. No cause has been established. Reopening from VS Code was interrupted by detected user input while the IDE was minimized; the user was asked whether the desktop could be left idle for another launch. Initial install and rendering are verified; persistent operation after that disconnect remains pending.
