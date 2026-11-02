# Mobile acceptance record

Status: PARTIAL. Android API 35 emulator installation and initial Welcome-screen rendering were verified on 27 October 2026. The emulator later disconnected; see BUILD_STATUS.md. Notification delivery scenarios below remain unexecuted. Automated planner and method-channel tests do not prove delivery.
Use fictional tasks. Record each run on both Android and iOS, and repeat shared
flows under Self-Agent, Friend-Agent and Standard Control.

For every run record: tester, date, app version/build, device model, OS version,
condition, time zone, permission state, battery restrictions, expected result,
actual result, pass/fail, and screenshot/log filename. Record requested and actual
delivery times separately. Do not include participant data in evidence.

| Scenario | Procedure and expected result | Android | iOS |
|---|---|---|---|
| First launch | No notification permission prompt until explicit opt-in | Pending | Pending |
| Permissions | Grant, deny, revoke in OS settings; resume and refresh. Status follows OS; denial offers recovery without crashing | Pending | Pending |
| Delivery | Schedule future task, exercise foreground/background/locked states. Neutral, silent reminder; log OS delays | Pending | Pending |
| Tap routing | Tap with app running and terminated. Open matching task; never start focus or complete it | Pending | Pending |
| Missing task | Delete task before opening an already delivered reminder. Navigate safely to task list | Pending | Pending |
| Quiet hours | Test start boundary, end boundary, overnight range. Requested delivery shifts to allowed time | Pending | Pending |
| Time zone | Change device zone, resume. Local times follow wall clock; explicit UTC times retain instant | Pending | Pending |
| Cancellation | Edit, complete, delete, disable reminders, reset. Old schedules are removed | Pending | Pending |
| Queue limit | Create 61 future reminders. Nearest 60 queued; extra reported as waiting; reconcile on resume | Pending | Pending |
| Restart | Restart app with reminders and paused/running focus. State recovers without duplicate events | Pending | Pending |
| Reboot | Reboot after scheduling, then verify pending reminder restoration and tap routing | Pending | N/A |
| Restrictions | Exercise Android force-stop/battery restrictions and iOS notification settings; document observed limitations | Pending | Pending |
| Release resources | Install release build; verify notification icon and launcher icon survive shrinking | Pending | Pending |
| Accessibility | TalkBack/VoiceOver, large text, contrast, focus order, touch targets and keyboard on small screen | Pending | Pending |
| Condition isolation | Control rejects chat/refinement deep links; reminders have identical wording across conditions | Pending | Pending |
| Participant guard | Install RESEARCHER_DEMO=false build over demo. Demo data unavailable; schedules cancelled; enrollment blocked | Pending | Pending |

Build a debug APK using `powershell -NoProfile -ExecutionPolicy Bypass -File
tool/flutter.ps1 build apk --debug`. Use `flutter devices` and `flutter run -d
<id>` with a connected device. iOS compilation and execution require macOS/Xcode.
Do not mark rows passed from source inspection or a successful compilation.

