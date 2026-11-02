# Development event contract — not an approved analysis protocol

Version: **development-events-2026-10-28**. Uses fictional data only. Preserve unknown/missing observations rather than inventing behavior.

**2026-10-30 extension:** `task-support-ui-v1`, server `small-steps-task-support-v1` and `reminders-v2` are documented in `AGENT_FEATURE_AUDIT.md`. These are distinct intervention/context policies, not retroactive changes to older records. Registration now deduplicates against the most recent matching task/condition/category/time/wording/policy, rather than ignoring later changes to wording.

| Added record | Operational meaning | Does not establish |
|---|---|---|
| `agent_switched` | Local researcher demo changed active condition; from/to saved | A participant was reassigned by the backend |
| `correction_proposed` | A draft was returned; original task/version retained | Display or acceptance |
| `correction_accepted/rejected` | Explicit decision on a linked draft; acceptance applies only approved fields | Independent task quality or work completion |
| `suggestion_displayed` | Card intersects the current chat scroll viewport, or a rendered proposal sheet is current | Eye attention, reading, agreement or improved behavior |
| `suggestion_opened` | User opened the linked task/control review flow | Acceptance, work initiation or a committed task edit |
| `suggestion_dismissed` | User dismissed that versioned in-app action card | OS notification dismissal or an ignored reminder |

Recommendation cards use explicit application rules. Free-form model text never executes actions. Correction/breakdown acceptance and task/reminder/focus actions keep their existing specific records; do not add them as independent duplicate outcomes. Notification category/wording/policy and reserved-slot limits are recorded separately from OS delivery evidence.

| Record | Meaning | Does not establish |
|---|---|---|
| Client `task_created` | Frontend reported task creation | Work started |
| Server task mutation audit | Owned database transaction committed; receipt time is server UTC | Independent observation of participant work |
| `task_started` | Explicit first-start self-report | Objective initiation or notification causation |
| `task_recovery` | User chose pause/resume/reschedule/smaller step, optional stated reason | Diagnosis or inferred procrastination |
| `self_reported_completion` | User marked work complete | Verified completion/quality |
| Focus start/pause/resume/end/elapsed | Timestamp-based timer state/report | Task completion or continuous attention |
| `reminder_requested` | User chose a reminder time | OS scheduling, send or delivery |
| `notification_schedule_registered` | OS schedule API returned without error for that plan | Sent/delivered/seen/ignored notification |
| `notification_opened` | Scoped OS callback or authenticated replay of a pending callback | Task start, work, or all notifications delivered |

Client occurrence timestamps and local offsets are separate from server receipt timestamps. Backend assignment is authoritative. Group records by server/account, condition, task/version, protocol and actual recorded prompt/model version. Do not relabel historical records to the current prompt version. Runtime export provenance explicitly means current configuration only.

Schedule registration deduplicates the same task/condition/scheduled instant. It is not a complete trace of every cancellation/re-registration or OS delivery attempt. Keep that limitation when calculating denominators. There is no server push, delivery acknowledgment or ignored-notification event. An opening report's `deliveryConfirmed=false` deliberately avoids upgrading a callback into a universal delivery measurement. Test-device screenshots/OS observations are QA evidence, not automatic participant delivery receipts.

The frontend and server can retry reports using stable event IDs. Reusing an ID with a changed body is a conflict. Never add client reports and server audit rows together as two task initiations. Pending device reports in an export are labeled separately from committed server records. Failed synchronization does not establish absence of behavior.

Before calculating time-to-start, the research team must approve:

1. Analysis unit and anchor: task creation, planned start or a versioned invitation exposure. They are different estimands.
2. First valid explicit start source and handling of duplicated, reordered, edited or reopened tasks.
3. Reschedule/pause rules and which task version/anchor applies.
4. Clock-skew handling using occurrence versus receipt times; do not silently substitute one for the other.
5. Observation end, missing starts, censoring and exclusions. Missing is not zero, completion time or notification time.
6. Evidence and observation window before labeling a reminder delivered, opened or ignored; scheduled time alone is inadequate.

No automatic latency or procrastination score is produced from these draft rules. Optional check-ins remain raw demonstration responses, not validated questionnaire scores or research findings.
