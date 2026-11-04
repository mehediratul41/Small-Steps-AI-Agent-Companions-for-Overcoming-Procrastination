# Code walkthrough: follow the data

Use this with the [sequence diagrams](SYSTEM_DESIGN.md). Paths below refer to the actual workspace, not an idealized design.

## 1. Where the program starts

[Frontend main.dart](../outputs/frontend/lib/main.dart) runs `main()`. It initializes Flutter bindings, registers the bundled Japanese font's license, obtains SharedPreferences, and creates a Riverpod `ProviderScope`. Overrides inject preferences, `DeviceReminderService`, and secure saved-connection storage on Android/iOS. Browser previews use memory-only credential storage.

Think of a provider as a named dependency or observable state container. A widget that `ref.watch`s a provider rebuilds when it changes. `ref.read(provider.notifier)` accesses operations without subscribing. Injection lets tests substitute an in-memory store or fake API without touching real accounts.

[SmallStepsApp](../outputs/frontend/lib/app/app.dart) initializes the controller and reminders, responds to lifecycle changes, and builds `MaterialApp.router`. `routerProvider` creates go_router routes. It redirects loading, unacknowledged demo consent, unavailable participant mode and restricted control routes. During a validated synthetic-account switch, Chat stays mounted despite the temporary connection state. AppShell supplies Today, Tasks, Chat or Reminders, Insights, language and Settings.

## 2. State versus persistence

[AppState](../outputs/frontend/lib/app/state.dart) is the current in-memory snapshot: tasks, current condition, chats, focus, events, profile and check-ins. `AppController` replaces it through `copyWith`. A widget rebuild is not a database write.

`persist()` saves either a local-demo JSON snapshot or the connected-account cache/reports. `_persistBackend()` sends unacknowledged client events in batches of 20, using stable IDs; it also caches pending events/messages and focus state. It does not upload the whole demo dataset into a connected account. `initialize()` reloads demo state or restores/refetches an authenticated backend snapshot.

`_assertSessionReady()` blocks mutations when account transitions or a failed saved-login restoration make the intended data owner uncertain. It is not backend authorization; FastAPI still enforces that independently.

## 3. Example: save a task

Open [tasks.dart](../outputs/frontend/lib/features/tasks.dart), `TaskEditor`, then `AppController.saveTask`, then [repository.dart](../outputs/frontend/lib/data/repository.dart), `ApiResearchRepository.createTask/updateTask`.

1. The form creates an editable `Task` value. This is not yet committed.
2. The controller validates start-plan fields and prevents concurrent saves of the same task. New tasks use version 1; updates use the currently loaded version plus one.
3. `_taskJson` converts date fields to UTC. Dio adds the participant Bearer token.
4. [FastAPI create_task/edit_task/put_task](../outputs/backend/app/main.py) validate the body, owner and version. SQLAlchemy inserts or uses a conditional update inside a transaction.
5. The backend commits the task and a server audit, then returns a receipt.
6. The controller replaces the task only after success, records a client report, persists it, and Riverpod updates Today/Tasks/Insights. Reminders listen for the task change.

If the network fails, the form receives an error and there is no general offline task queue. A lost response can mean the server committed even though the screen reports failure. Exact replay of a committed update can now return the existing receipt without another audit; otherwise refresh before editing again. A different stale edit remains 409.

`toggleTask` and `undoCompletion` protect completion/undo with task version and account identity. `startTask` is an explicit self-report; `recoverTask` handles pause/resume/reschedule/smaller-step choices. `deleteTask` calls versioned server deletion in connected mode and changes local state only after success. Server deletion is a tombstone, not research-history deletion.

## 4. Start plans and support

[start_support.dart](../outputs/frontend/lib/features/start_support.dart), `StartSupportPanel` and `_StartSupportEditorState.save`, expose optional cue/action pairs, difficulty selection and a Self-Agent-only future note. The editor checks that the task version has not changed while it was open. It requires Save; selecting a difficulty does not overwrite a task or schedule a reminder. Advice is application-authored text, not a diagnosis or a generated treatment.

`showRecoverySheet`, `showReminderSheet`, `showFocusSheet` and `showSubtaskEditor` in [task_actions.dart](../outputs/frontend/lib/features/task_actions.dart) reuse the same controller operations. Start-plan cue text is not parsed into an automatic trigger; scheduling remains an explicit time choice.

## 5. Example: one chat message

[ChatScreen.send](../outputs/frontend/lib/features/chat.dart) clears a submitted composer draft, sets a busy state and calls `AppController.send`. Quick-action messages preserve any unrelated typed draft. [ChatMemory](../outputs/frontend/lib/app/chat_memory.dart) scopes transient drafts/offsets by account, agent and conversation. The controller creates a pending `ChatMessage` with a stable ID, task ID and language. It persists that pending record before requesting the service.

Connected mode calls `ApiResearchRepository.chatWithId`: the message ID becomes `Idempotency-Key`. Only message, task ID and language are submitted; the client does not choose the system prompt or supply trusted history.

[main.py](../outputs/backend/app/main.py), `chat` → `run_ai`, authenticates and restricts the account, reserves an `AIJob`, and constructs owned context with `support_context` and `history_for`. [ai.py](../outputs/backend/app/ai.py), `GeminiProvider.chat`, sends the shared safety rules plus the assigned persona and requested-language instructions through Google's server SDK. Task/profile content is delimited as data. Friend-Agent removes future-self notes. Context/history are bounded, not unlimited memory.

The backend saves the user/agent turn with provider/model/prompt/task/language provenance. The controller marks the user message sent, appends the reply to its original task conversation, persists, and the list renders it. On failure, the pending user message becomes failed; retries reuse its original ID and language. Replaying a completed request returns its saved response. A failed/pending server job is not automatically regenerated. Read [API retry rules](API_CONTRACTS.md).

Local mode calls `MockResearchRepository.chat` instead. Those are scripted examples. A realistic-looking bubble does not establish a live model call. The mode notice and connection action make the distinction visible.

## 6. Authentication and account switching

Backend credentials are provisioned locally by [admin.py](../outputs/backend/app/admin.py). Only a SHA-256 token hash is stored in the participant row; the raw synthetic credential is written to an ignored local file. `authenticated` checks hash, active flag and expiry. `enrolled` requires the current demonstration acknowledgment. `agent` rejects control assignments. `owned_transaction` rechecks the account and queries task/record ownership.

[saved_connections.dart](../outputs/frontend/lib/data/saved_connections.dart) stores explicitly remembered synthetic accounts. `SavedConnections` is observable metadata; its backing store is secure on Android/iOS. `AppController.connectBackend` checks mode and optional expected identity/condition, isolates the demo state, and loads `/api/state`. Startup restoration validates both saved ID and condition; a failed restore cannot silently become writable mock mode.

`switchLiveAgent` validates a saved same-server synthetic target, blocks busy/focus transitions, flushes the current account, loads the target account and saves the active selection. It attempts rollback on a later failure. `ChatScreen.switchAgent` updates task context; ChatMemory and conversation binding restore the target account/agent/conversation draft without transferring text between accounts. `switchCondition` remains local-demo-only. Neither route changes a real backend assignment.

Disconnect deactivates automatic restoration but keeps explicitly remembered logins until forgotten. Development erasure revokes the server account and removes its saved credential without removing another linked account. Device caches are separate from the secure token store; pending research text is not encrypted by SharedPreferences and is suitable only for this synthetic prototype.

## 7. Suggestions never execute themselves

`proposeCorrection` and `suggestions` request drafts. `CorrectionSheet` in [agent_actions.dart](../outputs/frontend/lib/features/agent_actions.dart) and `RefinementScreen` in tasks.dart show editable results. `decideCorrection` or `acceptSuggestions` submit an explicit decision. The backend checks proposal state, owner and task version, then changes only approved fields. Cancellation/rejection does not mutate the task.

Chat recommendation cards use application rules and actual task context. They open review controls; they do not interpret arbitrary model prose as commands. Schedule changes still require the user's choice.

## 8. Reminder mechanics

[RemindersController](../outputs/frontend/lib/app/reminders_controller.dart) loads per-account local preferences, checks permission/timezone and calls the pure [planReminders](../outputs/frontend/lib/data/reminders.dart) function. The default cap is three reserved slots/day with a 60-minute cooldown. Manual, planned-start and at-deadline reminders share policy; the latter two and persona wording are opt-in. Quiet hours shift requested times; completed/paused tasks and expired requests are excluded. Pause-today suppresses requests before its stored boundary rather than replaying a burst tomorrow.

[DeviceReminderService](../outputs/frontend/lib/data/services/device_reminders.dart) cancels/replaces native pending schedules and uses inexact Android scheduling. It handles launch/tap payloads scoped by server/account/task/category. The controller can ask for account reconnection before opening a task. No task text or credentials are placed in notification payloads. Scheduling success is not delivery evidence.

## 9. Focus and research events

[FocusSession](../outputs/frontend/lib/data/models.dart) calculates remaining seconds from a deadline, with clamping. The [focus screen](../outputs/frontend/lib/features/focus.dart) ticker only redraws the display. It is not the authoritative clock. `startFocus/pauseFocus/endFocus` persist state and reports; backgrounding or killing the app does not require a continuously running ticker. Ending/expiry never marks a task complete.

`_record` creates client events with task/account condition, timestamp, offset and UI language. Connected reports are retried with stable IDs. The backend stores client events separately from server audit rows; counting both as two outcomes is incorrect. [insights.dart](../outputs/frontend/lib/features/insights.dart) shows current completion state, explicit task starts and focus starts, not an approved efficacy score.

## 10. Language and errors

[language.dart](../outputs/frontend/lib/app/language.dart) saves `en`/`ja`; [ARB catalogues](../outputs/frontend/lib/l10n/) generate typed UI strings. `strings.dart` provides a canonical-value/error translation bridge. User task titles and stored messages are kept verbatim. API requests include response language. A change in UI language is not a change in assignment.

Dio's `_request` maps transport/status failures into `AppFailure`. Backend error envelopes avoid raw credentials and input text. Unknown external errors may remain technical. Use the [troubleshooting table](TROUBLESHOOTING.md) rather than assuming every generic reply is a provider failure.
