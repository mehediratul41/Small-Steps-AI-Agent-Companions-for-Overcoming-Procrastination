# Researcher manual

## Invite-only accounts update

[Multi-user design](MULTI_USER_DESIGN.md) adds authentication for separate synthetic users, not approved study enrollment. Use the [developer invitation commands](DEVELOPER_MANUAL.md) with pseudonymous TEST IDs and an explicitly chosen condition. Never interpret these commands as a randomization protocol. A local trusted server operator issues invitations; there is no web researcher role or unrestricted cross-participant export. Each account exports only its own records.

The account holder chooses a username/password and then separately acknowledges demonstration information. A login is not consent. Invite codes expire after 72 hours and cannot be reused. Password login does not change assignment; standard control stays excluded from AI. Researcher linked DEV switching remains separate, and normal accounts cannot use it. Do not issue real participant invitations until approved consent, instruments, deployment/privacy controls, recovery and retention are established. The participant-build guard remains closed.

Erasure also removes owned login/invitation records, invalidates access and retains a disabled participant tombstone. Backups and device caches are separate retention concerns. There is no verified password-reset email flow. Production data must never be used in automated tests.


## Scope and readiness

This is a working **synthetic-development prototype**, not a cleared participant study. The backend Settings accepts only development mode; `/health` reports `participantEnrollment: false`. Flutter participant builds intentionally stop at study-setup unavailable. There is no participant recruitment, eligibility workflow, approved consent, validated baseline scoring, production login or token refresh.

Do not interpret successful builds or fluent conversations as evidence of intervention effectiveness. A supervised **synthetic usability rehearsal** is appropriate after checking the device; real participant use requires the institutional protocol, ethics approval, approved language materials, retention/deletion policy and deployment work.

## Conditions and switching

| Condition | Capability | Deliberate distinction |
|---|---|---|
| Self-Agent | Shared task/chat tools and optional template notifications | Future-oriented self-reflection; user-authored future note may enter selected-task context |
| Friend-Agent | Same task/chat tool structure and notification policy | Empathetic, nonjudgmental framing; future note removed from agent context |
| Standard control | Shared ordinary task, focus, check-in and reminder controls | No chat, model breakdown or model correction |

Assignments are immutable account attributes set by the local operator. The CLI provisioning choice is **not an implemented randomization algorithm**. Researcher Demo Mode may switch local scripted conditions or open different remembered synthetic agent accounts. Neither reassigns one enrolled participant. Those synthetic accounts intentionally have separate histories/tasks. Do not use their pooled data as a within-subject study without a separately specified protocol.

Keep model, prompt, context, language and reminder-policy versions fixed during an experiment. The current shared prompt includes start-plan/difficulty guidance, and Self-Agent can reference a future note; those are intervention components that need protocol review. New translations need equivalent tone, burden and meaning rather than word-for-word matching alone. No research-critical prompt or instrument wording was changed by the present integration audit.

## What each observation proves

| Record | Operational meaning | Not established |
|---|---|---|
| Client `task_created/task_updated` | App reported a successful operation | Work performed |
| Server mutation audit | Owned DB transaction committed | Independent task quality |
| `task_started` | Explicit first-start self-report | Objective attention or causal reminder response |
| `task_recovery` | Chosen adjustment and optional reason | A diagnosis or inferred procrastination |
| `self_reported_completion` | User marked complete | Verified quality or duration |
| `focus_started/resumed/paused` | Timer interaction | Continuous work |
| `focus_elapsed/ended_early` | Timer/session report on explicit save | Task completion |
| `refinement/correction_proposed` | Provider draft returned | Actually read or accepted |
| `suggestion_displayed` | App visibility logic saw the current card/sheet | Eye attention or comprehension |
| `suggestion_opened/dismissed` | In-app action on a card | OS notification dismissal or ignored reminder |
| `notification_schedule_registered` | OS schedule API returned successfully | Delivered, seen or ignored |
| `notification_opened` | Scoped notification callback/opening report | All reminders delivered or work began |
| Local `agent_switched` | Researcher changed scripted demo condition | Server participant reassignment |

Live synthetic account switching is not the same event as local `agent_switched`; do not assume the existing local event covers every cross-account transition. There is no delivery acknowledgment, sent-event pipeline, ignored-notification inference or defined observation window for non-response.

## Time-to-start and missing data

The application does not calculate an approved time-to-start outcome. Define it before analysis:

1. Choose the anchor: creation, planned start or a recorded invitation exposure. They answer different questions.
2. Specify which explicit initiation event counts and how reopening/rescheduling affects it.
3. Join by server/account, task/version and condition; do not join unrelated synthetic accounts on matching task names.
4. Keep client occurrence time/offset distinct from server `receivedAt` and server audit time. Define clock-skew handling.
5. Missing starts require a censoring/window rule. They are not zero or completion time.
6. Do not add a client event and the matching server audit as two independent behaviors.

Queued or failed reports mean uncertain completeness, not necessarily absent behavior. Completion counters describe current task state; reopening/deleting tasks can change them. They are not immutable completion-event totals. Current runtime provenance in an export is not historical model provenance; use each AI record's own metadata.

## Private data and erasure

Use fictional tasks in development. Context sent to Gemini can include owned task summaries, profile text and recent conversations even when the visible input is brief. Review provider data-use settings and institutional approval before real research text is sent.

Exports contain raw text, events, profile and historical/tombstoned tasks; device-pending reports are labeled separately. Keep exports, identity mappings and tokens outside public Git. Ignore rules reduce accidental additions but do not sanitize committed history, screenshots or unknown file names. Secure token storage does not encrypt the app's entire research cache.

Development erasure removes that account's live task/record/job rows, revokes credentials and retains an inactive participant tombstone. It does not guarantee removal from backups or provider systems. It is not a fully approved withdrawal/retention workflow. Never test erasure on real participants or another researcher's data.

## Synthetic pilot rehearsal checklist

Use a new account per condition and a recorded app/model/prompt build. Verify consent-demo gating, no AI for control, correct history and language per account, explicit suggestion acceptance, task-start/completion semantics, offline feedback, restored-login behavior, focus background/resume, and per-account reminder preferences. Use optional burden check-ins without treating them as validated scales. On physical Android/iOS, verify permission denial, quiet hours, timezone change, terminated delivery, tap routing and stale cancellation. Document observed delivery separately from scheduling API results.

Review [QA results](QA_AND_INTEGRATION_REPORT.md), [API contracts](API_CONTRACTS.md), and the historical [event contract](../RESEARCH_EVENT_CONTRACT.md) before planning analysis.
