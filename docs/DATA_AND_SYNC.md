# Data ownership and synchronization

## Sources of truth

| Entity | Authoritative location | Device state/cache | Offline and conflict behavior |
|---|---|---|---|
| Local demo tasks/chats/profile/check-ins/events | SharedPreferences `small_steps.demo.v1` snapshot | AppState | Fully local scripted demo; no automatic upload to backend |
| Connected assignment/onboarding | Backend participant row | Current AppState, validated on connect/snapshot | No client reassignment; expired/revoked token fails; participant enrollment missing |
| Connected tasks/subtasks/start plans | Backend TaskRow JSON + version/tombstone | Current loaded task list | Online writes; no general task outbox; frontend stale-form guard and server compare-and-swap |
| Connected successful chat turns | Backend `records`, kind chat | Current chats, selected task and pending-message cache | Same request ID replay; no automatic new model attempt |
| Pending/failed user message | Device account cache until committed/reconciled | Delivery state sending/failed | Restart marks pending failed; refresh deduplicates by message ID against server snapshot |
| AI request/proposal state | Backend AIJob / suggestion Record | Proposal ID map and open editor | Fingerprinted AI identity; explicit decision/version check; proposal UI drafts not a durable general outbox |
| Client research events | Device until acknowledged; backend event Record after receipt | Pending IDs cached | Stable IDs, batches of 20; identical replay deduplicated; changed body conflicts |
| Server task audits | Backend audit Record | Full export, not the ordinary event list | Transaction receipt evidence; not another copy of user behavior for counting |
| Focus session | Device snapshot/cache plus timestamp deadline | FocusSession | Recalculates on resume/restart; events sent later; no continuous-attention evidence |
| Check-ins | Backend in connected mode; local snapshot in demo | Current list | Backend write before local success; no general offline questionnaire queue |
| Goal/preferences profile | Backend connected profile or local demo snapshot | Current profile | Online connected write; no multidevice conflict-resolution scheme |
| Notification preferences/pause | Device preferences, scoped by server/account | RemindersController | Local opt-in; not synchronized across devices |
| Notification pending/active lists | Native OS | PlannedReminder list/status | Reconciled on task/preference/scope/lifecycle changes; schedule != delivery |
| Remembered tokens and active login | Android/iOS secure store; browser memory only | SavedConnections provider | ID and condition revalidated; restore failure blocks mock mutation; expiry still applies |
| Language | `small_steps.language.v1` | Locale provider | Persists locally, independent of condition; original text unchanged |
| Theme | Local demo state/current account memory | ThemeMode | Selected theme is carried into connections; do not assume cross-device or universal restart persistence |

The connected cache key includes encoded server URL and participant ID. Reminder preference scope also includes server/account. Raw credentials are not placed in these caches. **Pending reports and research text are not encrypted by SharedPreferences**, so actual participant-data protection remains a deployment requirement.

## Connected write lifecycle

Task create/edit/delete is generally pessimistic: request first, update UI on receipt. The controller blocks duplicate saves of one task and checks an incoming editor version against the currently loaded version. The backend checks owner and version again, so a different device cannot silently overwrite a newer server task.

Lost responses create ambiguity: a server commit may succeed while the device shows failure. Creation can replay the same ID/body; updates can replay the exact already-committed version/body without adding another audit; the same deletion version can replay a tombstone. A different edit with a stale version is still rejected. Refresh and reopen a stale form rather than fabricating a new version from an old snapshot.

Local events/focus can be persisted before network synchronization. `_writes` serializes device persistence; `_persistBackend` records acknowledged event IDs after accepted batches. A synchronization failure leaves reports cached and an error. Not every `persist()` failure is thrown to the caller, so inspect the visible synchronization status and export pending reports when debugging with synthetic data.

## Chat recovery

Before requesting AI, `send` saves a pending user message. The API request's ID matches that message. On success it marks sent and appends the reply to the original task context. On error it keeps a failed message. After restart `_loadBackend` reads authoritative messages and merges only unmatched pending IDs; it does not re-add an already committed user turn. The original response language survives retries.

The server uses a request fingerprint, pending/failed/complete state, a unique account/request key, and a one-worker AI lock. A completed replay returns the saved reply. A failed or pending replay is unresolved, not permission to regenerate. The status endpoint exists, but the UI does not implement background polling. There is no guarantee of provider-level exactly-once billing or crash recovery for every in-flight job.

## Account transitions

Remembering a synthetic login does not share tasks. A live switch validates the target before leaving the current account, blocks active requests/focus, flushes queued reports, closes the old API object, loads the target snapshot, and updates the active saved login. Chat routing is held during this transition. Pending events/messages, focus and reminder settings remain per account. A late failure attempts to reconnect the previous saved account; if neither can connect, mutation is blocked with a reconnect error.

Restoration validates expected **ID and condition**, not just persona. A mismatched same-condition token cannot silently restore another user's cache. Forget removes saved logins; explicit disconnect clears automatic selection but can retain remembered accounts for later manual use. Development erasure removes the erased account's remembered credential and leaves another linked account alone.

## Time and scheduling

Flutter's API serializer sends aware UTC instants; readTask converts them for local display. Backend validators reject naive timestamps. Connected reminder scheduling uses absolute instants; local-demo wall-clock values are reconstructed in the current IANA zone. Reopen after travel to reconcile. Asia/Tokyo is supported by the timezone database; DST tests apply to other zones.

Quiet hours shift requested times; OS inexact delivery can still occur later. Pause-today stores a boundary calculated at the time of the action; it is not a continuously recalculated “midnight wherever I travel.” Caps/cooldowns reserve scheduling slots and conservatively use prior registration history; they are not verified delivery counts. Changing devices or clock/timezone can affect observed behavior and must be recorded in study procedures.

## What synchronization does not mean here

No WebSocket/streaming updates, no CRDT/merge engine, no all-purpose offline queue, no background service continually fetching tasks, no server push, no automatic multidevice notification preference sync. `/api/state` is a pull snapshot; one device can remain stale until refresh/reconnection. Acceptance/rejection of suggestions and profile writes are not universal exactly-once operations. Large accounts need pagination/retention work. These are limitations, not hidden “perfect sync” guarantees.

See [API contracts](API_CONTRACTS.md) for replay rules and [researcher manual](RESEARCHER_MANUAL.md) for interpreting missing/duplicated observations.
