# Device reminders

Reminder scheduling is implemented for Android and iOS, including connected synthetic accounts after per-account opt-in. Android debug compilation now succeeds using `tool/build-android-verified.ps1` on this Windows host; physical delivery and iOS compilation remain unverified. The browser preview saves times but does not deliver notifications.

## Use

1. Complete demo onboarding, then open Settings → notification preferences.
2. Enable notifications and grant the system permission. Startup never requests permission.
3. Optionally enable quiet hours and choose their start/end times.
4. Add or edit a task and select a future reminder time. The Reminders screen reports the current scheduling status; Settings offers refresh/retry.

All three conditions share the same reminder types, scheduling limits and neutral default copy. AI conditions can explicitly opt into assigned-agent wording using fixed gentle templates; control remains neutral. This is a versioned intervention change, not a model call in the background. Notifications contain no task title or credential. The app requests silent notifications without vibration or badges. Phone settings remain authoritative. Tapping a notification opens its task (or the task list if deleted), subject to onboarding and assignment guards. It does not start focus or mark work complete.

## Scheduling policy

- Policy `reminders-v2` (2026-10-30): manual reminder times remain available. Planned-start and at-deadline reminders are separate opt-ins, off by default. Agent wording is also off by default. Configure these under **Reminder types & limits**.
- The common default cap is 3 reserved slots per local calendar day and 60 minutes between requested slots, configurable per account. Old reminder times are retained; policy can suppress their scheduling. Past registration slots conservatively consume the budget across refresh/restart/agent switches; they are not counted as verified deliveries. Inexact OS timing can bunch actual notifications despite separated requested slots.
- Coincident types for one task collapse into one slot. Completed/paused tasks and expired times are excluded. No automatic daily, progress, deferral-loop or ignored-reminder nudges were enabled.

- Task changes, completion, deletion, opt-out, startup and app resume reconcile pending reminders. Reset clears pending/delivered notifications and local reminder preferences.
- Quiet hours are a half-open interval: the start is quiet and the end is allowed. Reminders in that interval move to its end. Overnight intervals and daylight-saving transitions use calendar-aware time-zone calculations.
- Locally chosen times follow wall-clock time in the device's current IANA time zone, refreshed when the app resumes. Explicit UTC timestamps preserve their instant. Reopen after travel to reconcile schedules.
- Android uses inexact scheduling; the OS may delay delivery. Quiet hours constrain the requested schedule, **not guaranteed delivery time**. No exact-alarm permission is requested.
- The nearest 60 reminders are queued, consistently across platforms. Extra reminders are shown as waiting and are reconsidered when the app next reconciles. There is no background refill service.
- If replacing a schedule fails, the adapter attempts to clear the partial replacement and surfaces a retryable error. Scheduled counts represent successful scheduling requests, not confirmed delivery or participant engagement.
- Preferences are stored separately in `small_steps.demo.reminders.v1`. Participant builds do not load these settings and cancel pending demo schedules. Real study integration remains disabled.

## Native configuration

Android includes notification permission, reboot/package-update receivers, a monochrome notification icon, release resource retention and core-library desugaring. iOS registers the notification-center delegate and defers permission requests until opt-in. Configuration follows the installed [flutter_local_notifications 22.3.2 documentation](https://pub.dev/packages/flutter_local_notifications/versions/22.3.2). Device time-zone discovery uses [flutter_timezone](https://pub.dev/packages/flutter_timezone).

## Required device verification

After installing the Android SDK/JDK, run `flutter doctor -v`, accept SDK licenses and run `flutter build apk --debug`. On macOS, compile/sign the iOS app with Xcode. On both platforms verify permission grant/denial/revocation, foreground/background/locked delivery, notification taps from terminated and running apps, quiet hours, time-zone changes, cancellation after task edits/completion/deletion, reset and restart. Also test Android reboot restoration and release resource shrinking. OS force-stop, battery restrictions and user notification settings can affect delivery; capture observed behavior before using reminders in a research protocol.

Automated coverage includes planner boundaries/DST, persistence, permission and cancellation flows, experimental parity, scheduling failures, native method-channel arguments and responsive layouts. Mocked native calls do not establish actual mobile delivery.

## Account boundaries and evidence (2026-10-28)

- Each server/account has a separate opt-in and quiet-hour preference. Connecting does not inherit local-demo permission preferences. Disconnect clears its device schedule; the next account must opt in independently.
- Payloads contain a scoped target, not task titles or tokens. Legacy task-only payloads belong to local demo. A cold account notification asks for a backend connection and only opens after matching authentication; other accounts cannot open it.
- Notification IDs remain stable when task order changes. Rescheduling, completion, pause, deletion and opt-out reconcile pending and displayed notifications.
- Connected reminder timestamps represent instants; after zone changes/resume they are displayed/scheduled in the current zone. Local demo retains its wall-clock plan. Quiet-hour deferral uses the current device zone. Travel while terminated is not certified.
- `notification_schedule_registered` means the OS scheduling API returned successfully, **not delivery**. `notification_opened` records a scoped callback or authenticated resume; it does not start work. Both carry `deliveryConfirmed=false`. Registration reports are deduplicated for the same task/condition/scheduled instant. No sent/delivered/ignored event is inferred.
- The inexact, silent, neutral behavior is the same across all conditions. No server push exists. Freeze prompt/model and notification settings under an approved protocol before real participant use.
