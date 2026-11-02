# Research and usability update — 27 October 2026

Implemented in the existing Flutter frontend, preserving shared Riverpod state, repository abstractions and condition guards. No backend or credentials were added.

## New interactions

- Title-only task capture. Additional fields are collapsed; planned start, deadline and reminder are independent and optional. No deadline is automatically assigned.
- Search and Active, Today, Paused and Completed filters. Explicit task initiation is separate from starting a timer.
- Gentle recovery: pause/resume, choose another start time, or choose a smaller step, with an optional reason. Users keep control of every change. Active focus sessions must be ended before their task is paused/rescheduled.
- Manual subtask editing in every condition. AI conditions additionally offer editable mock suggestions requiring acceptance; stale proposals cannot overwrite a later revision. Rejection leaves the task unchanged.
- Reminder snooze: 15/30/60 minutes or a custom time, without changing the deadline or planned start. Paused tasks are excluded from scheduling.
- Focus durations: 5/10/15/25 minutes with explicit start, pause/resume, restart restoration and timestamp-based expiry. Expiry never completes a task.
- Optional values/goals preferences and shorter scripted responses. Optional small-step invitations appear on Today in AI conditions, default to off, and never send personalized push messages or silently change tasks.
- Task-specific/general conversations, with read-only history for deleted tasks. Failed requests can be retried, edited or cancelled without blocking new messages. Retries preserve the original context and do not duplicate user messages. Interrupted sends restore as retryable failures.
- Optional baseline-demo, daily and before/during/after-session check-ins. Additional reflection is expandable. Answers append dated entries; skipping saves nothing. Changing the check-in context clears unsaved answers.
- Insights distinguish focus starts, reported task starts and self-reported completion; show check-in/recovery history; and group chart events by local calendar day.
- Settings → Data & study information: local counts, reviewable/copyable demo JSON and integration status. The export contains raw task/chat/reflection text and is not anonymized. Reset remains in Settings.

## Research and persistence

`task_started` requires tapping “I am starting this task.” `focus_started` means timer use. Neither verifies work. Recovery does not imply procrastination, and scheduling does not establish notification delivery. Focus events retain the session's original condition if the researcher switches demo conditions later.

New events have local IDs, UTC timestamps, offsets, conditions, protocol version and task revision where relevant. Refinement records retain original, suggested and accepted snapshots. Unknown legacy condition/offset fields remain unknown. The existing `small_steps.demo.v1` key is retained with a version-2 payload; older tasks, chats, history and ten-minute sessions migrate using defaults. Preferences and check-in history persist locally. Use fictional information in this unencrypted demo storage.

Self-Agent and Friend-Agent share the same controls and personalization options. Standard control shares manual tasks, focus and check-ins while denying AI chat, refinement and agent invitations. These are demo capabilities, not an approved protocol: freeze the question wording, invitation policy and shared controls before a study.

## Verification

- Analyzer: no issues.
- Default suite: 79 passed; two opt-in tests skipped.
- Participant-mode guard test: passed separately, including new routes.
- Preview capture test: passed separately; 14 captures in `design-review/`.
- Release web build: succeeded.
- New widget tests include 320 × 568 portrait and 844 × 390 landscape at 150% text size, expanded task fields, recovery, quick capture, manual control-group steps, snooze, chat failure recovery and check-ins.

Use `tool/flutter.ps1` with the commands in README. Captures support manual visual review; they do not prove usability or pixel-perfect Figma reproduction.

## Remaining work

Check-in items are demonstrations, not validated questionnaires or clinical measures. Approved consent, researcher contact, withdrawal, authentication, authoritative assignment and participant storage/synchronization still require integration. Participant mode remains deliberately unavailable.

Chat/refinement remain scripted mock services; preferences do not create real LLM memory. The provisional API adapter does not transmit preferences, check-ins or event batches. Agree on server contracts, authorization, idempotency and retention before collecting research data.

Android debug compilation and APK signature verification have now succeeded; see [BUILD_STATUS.md](BUILD_STATUS.md). Device execution and notification delivery remain unverified because the software emulator crashes and no authorized phone is connected. iOS requires macOS/Xcode.

Next: connect the approved protocol/backend, verify the native app, then pilot task entry, recovery, chat context, focus and check-ins with users. Observe time, errors and feedback before concluding that the interface is convenient.

