# Actual API contracts

Source: [main.py](../outputs/backend/app/main.py), [schemas.py](../outputs/backend/app/schemas.py), [repository.dart](../outputs/frontend/lib/data/repository.dart). The running server's `/openapi.json` and `/docs` show executable schemas; restart after editing backend source. These are development endpoints, not provisional commercial API promises.

## Common rules

Bearer authorization: `Authorization: Bearer <synthetic-participant-token>`. The model key is never the client token. Tokens are hashed in DB, time-limited and revocable. `authenticated` permits identity/onboarding/erasure; `enrolled` additionally requires the current demo acknowledgment; `agent` additionally rejects standard control. Every owned query checks the authenticated participant. Client-supplied condition never overrides assignment.

JSON bodies are bounded to 64 KiB. Strict Pydantic models forbid extra fields. Task/chat/check-in language accepts `en` or `ja`; timestamps require an explicit offset and are normalized to UTC. The server adds no-store and nosniff response headers. CORS allows configured local frontend origins and methods, not unrestricted browser access.

## Endpoints

| Method/path | Gate | Request | Response/semantics |
|---|---|---|---|
| `GET /health` | Public | None | `status`, `mode`, `aiProvider`, `model`, `participantEnrollment:false` |
| `GET /api/participants/me` | Authenticated | None | `id`, immutable `condition`, `onboarded`, `consentVersion`, development `mode` |
| `POST /api/participants/onboarding` | Authenticated | `acknowledged:true`, current `consent_version`, `demonstration:true` | Acknowledged; repeated current acknowledgment does not add another audit |
| `GET/PATCH /api/participants/profile` | Enrolled | PATCH full `values`, `goal`, `brief`, `invitations` | Profile; not an offline outbox |
| `GET /api/tasks` | Enrolled | None | Owned active tasks |
| `POST /api/tasks` | Enrolled | Task version 1 | 201 task; same ID and same semantic data can replay, conflicting reuse is 409 |
| `GET /api/tasks/{id}` | Enrolled | None | Owned active task or 404 |
| `PATCH /api/tasks/{id}` | Enrolled | Full Task with matching ID and version current+1 | Task receipt; conditional update; exact committed replay allowed at version >1; different stale edit 409 |
| `DELETE /api/tasks/{id}?version=N` | Enrolled | Current version | Tombstone and `historyRetained:true`; replay of that same deletion succeeds without another audit |
| `POST /api/tasks/refine` | Agent | Saved current Task, `variant` 0..100, `mode` breakdown/correction, `language`; required Idempotency-Key | Proposed editable draft, IDs/version/snapshot/status and provider/prompt/language provenance; task unchanged |
| `POST /api/refinements/{id}/accept` | Agent | `task_version` and either `subtasks` or `correction` | Updated task; proposed-state CAS, ownership and current version required; modes cannot be mixed |
| `POST /api/refinements/{id}/reject` | Agent | No body required | Rejected status; task unchanged; repeated resolved decision is 409 |
| `POST /api/chat` | Agent | `message`, optional `task_id`, `language`; required Idempotency-Key | Agent message receipt; server builds context/history and selects persona |
| `GET /api/chat/history?task_id=...` | Agent | Optional task ID | Up to last 10 matching turns inside latest 500 chat records; omitted ID means general conversation |
| `GET /api/ai-requests/{id}` | Agent | Owned request ID | `status`, saved `response` when available; UI does not automatically poll |
| `POST /api/events` | Enrolled | `events` batch 1..100 | Accepted IDs; identical event ID/body replay accepted, changed body conflicts |
| `POST /api/focus-sessions` | Enrolled | Focus BehaviorEvent | Same event store; restricted focus event names; UI currently batches events through `/api/events` |
| `GET /api/progress` | Enrolled | None | First 10,000 owned client events; no calculated research score |
| `POST /api/check-ins` | Enrolled | CheckIn | Accepted ID and demonstration flag; identical replay safe |
| `GET /api/state` | Enrolled | None | Participant ID/condition, active tasks, profile, events, checkIns and all visible messages; one transactional read boundary, no pagination |
| `GET /api/export` | Enrolled | None | schemaVersion/exportedAt, current runtime provenance, participant/profile, tasks including tombstones, records with receivedAt; no raw auth/model key |
| `POST /api/participants/erase-development-data` | Authenticated | `confirmation:"ERASE MY DEVELOPMENT DATA"` | Delete owned live data, revoke credential, retain inactive tombstone; backups not erased |

## Task schema and replacement semantics

`id` uses `[A-Za-z0-9_.:-]`, 1..100 characters. Title is nonblank, at most 300; description at most 5000. `priority`: Low/Normal/High; `minutes`: 1..1440; `version`: integer >=1; `done` and `paused` booleans. Date fields: `due`, `plannedStart`, `firstStartedAt`, `completedAt`, `reminder`. Subtasks: at most 30, each nonblank title <=300 and done flag.

Optional support fields default empty: `startCue` and `startAction` <=300, `futureNote` <=1000, `difficulty` one of empty/unclear/overwhelming/worried/distracted/tired. The frontend additionally requires cue and action together. Backend accepts empty/default optional fields; semantic normalization prevents missing legacy defaults causing false stale conflicts. No database migration rewrites old JSON rows.

Despite the HTTP method, PATCH Task/Profile uses full model validation with defaults: omitted fields can reset. Submit the full intended object, not an arbitrary partial delta. A normal update increments the task version; the server manages completedAt when needed and clears it on reopening.

Synthetic create example:
```json
{"id":"example-task","title":"Read one paper","priority":"Normal","minutes":10,"version":1,"plannedStart":"2026-11-02T06:00:00Z"}
```
To edit, take the receipt, change intended fields, increment its version and PATCH that full object. Never regenerate IDs on a retry of the same creation.

## Chat/proposal retries

```http
POST /api/chat
Authorization: Bearer <synthetic-token>
Idempotency-Key: synthetic-message-001
Content-Type: application/json

{"message":"Help me choose a first step.","task_id":"example-task","language":"en"}
```

`run_ai` fingerprints operation plus validated payload. Same key + same complete request returns the saved response with no new generation. Same key + different body is 409 `key_reused`; pending/failed same attempt is 409 `ai_request_unresolved`. AI jobs count toward the configured hourly limit; one local asyncio lock serializes generation. Server timeout is 30 seconds; cancellation does not prove the provider did not process/bill a request. Do not blindly loop new IDs. Current UI retries messages with the same ID/task/language; new proposal requests generate new IDs, so avoid repeated taps or treating regeneration as a free retry.

Acceptance is version-gated rather than universally replayable: after a decision, fetch authoritative task/state if the response was lost. UI state refresh can reconcile the result. This audit does not claim every mutation has exactly-once delivery.

## Event/check-in fields

BehaviorEvent includes stable `id`, lowercase/underscore `kind`, optional `taskId`, aware `at`, offset -840..840 minutes, optional matching condition/version, seconds 0..86400, reflection <=4000, details and protocolVersion. Stored event JSON is limited to 16,000 characters. The backend stamps authoritative condition. Task-linked events may refer to tombstoned owned tasks.

CheckIn includes stable ID, `phase` baseline/daily/before/during/after, language, timestamp/offset, optional owned task and matching condition, `instrumentVersion:"demo-check-in-v1"`, and <=20 bounded answers. These are raw demonstration answers. The frontend's visible phase labels are mapped to canonical API codes.

## Error envelope

```json
{"error":{"code":"stale_task","message":"Task changed; refresh first"}}
```

| Status | Examples | Client action |
|---|---|---|
| 401 | Missing, invalid, expired or changed session | Reconnect correct account |
| 403 | Onboarding required, condition restricted, assignment mismatch | Respect guard; do not override assignment |
| 404 | Not-owned/missing record | Check account/context; no cross-account lookup |
| 409 | Stale version, changed ID replay, resolved proposal, unresolved AI | Refresh or inspect owned request before deliberate retry |
| 413 | Body exceeds 64 KiB | Reduce request |
| 422 | Invalid fields/ID/time/decision | Correct details; validation response lists fields, not raw input |
| 429 | Hourly AI cap | Wait; avoid automatic retry storms |
| 503 | AI timeout/unavailable or storage failure | Preserve pending state, verify service; task not changed by AI generation |
| 500 | Unexpected failure | Generic bounded feedback; diagnose with synthetic reproduction |

Some Dio messages intentionally summarize these statuses rather than surfacing raw server/provider details. Provider/model IDs are configuration, not evidence of live generation; distinguish provider mock from Gemini and actual request success.


## Invite-only account endpoints (revision 2)

These routes precede research acknowledgement and do not accept participant IDs, roles or conditions.

| Method/path | Body and result | Authorization |
|---|---|---|
| POST `/api/auth/enroll` | `{username, password, invitation}` → 201 `{token, token_type: "bearer", expires_at, participant_id, condition}` | Valid unused unexpired researcher-issued invitation; enrollment flag enabled |
| POST `/api/auth/login` | `{username, password}` → same session receipt | Argon2 verification and active participant |
| POST `/api/auth/logout` | No body → `{signed_out: true}` | Current bearer token; revoked immediately |

Username is normalized lowercase (3–64 ASCII letters/digits/dot/underscore/hyphen). Password 12–128 characters. Invitation 20–200 characters. Extra fields rejected (422). `expires_at` is Unix seconds UTC, not a formatted date. Store the token only in secure mobile storage or web memory; never passwords. Login and enrollment replace the participant's current token hash. Exactly one active bearer session exists per account; login after expiry renews it while the participant is active. No refresh endpoint exists.

Login failure: 401 `invalid_credentials`, same message for missing, disabled or incorrect password. Enrollment failure: 400 `enrollment_failed`; duplicate concurrent database writes may produce existing 409 conflict response. Reused/expired codes do not create another account. Disabled redemption: 403 `enrollment_disabled`. Ten attempts per normalized name or 30 per peer in ten minutes: 429 `auth_rate_limited`; development in-memory limiter resets on process restart. Enrollment does not imply consent. Existing `/participants/onboarding` is still required before tasks/state/AI.

Lost enrollment response: try password sign-in instead of reusing the code automatically. Login response loss: sign in again to replace the unknown session; token issuance is not idempotent. Logout response loss: repeating the old token can return 401 because revocation already succeeded. No other participant's ID is accepted for export/deletion. Health now reports `invitationAccounts` separately from `participantEnrollment` (still false).


## Optional development support feedback (2026-11-02)

No new route: existing authenticated `POST /api/events` transports `support_feedback_offered`, `support_feedback_answered`, `support_feedback_skipped`. Existing event ownership, ID replay/conflict rules, timestamp/condition checks and export scope apply. `details` stores `instrumentVersion: dev-support-feedback-v1`, `source`, `sessionId`, offer `cooldownHours`, decision `offerId` and `choice` (`smaller_step`, `clear_plan`, `encouragement`, `quiet_time`, `skip`). These are client-reported observations, not verified efficacy/delivery. Feature availability is disabled by default and gated off in participant Flutter builds; generic server event acceptance is not a protocol-approval gate. See [UX scope and instrument](UX_IMPROVEMENTS.md).
