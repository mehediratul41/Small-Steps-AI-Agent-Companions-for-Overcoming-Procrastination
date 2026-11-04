# User manual

This manual describes the synthetic research prototype, not an approved participant service.

## First launch and language

Choose **English / 日本語** from the globe menu or Settings. The choice is saved. Existing task text and old messages are not translated. Read the welcome and demonstration-consent information; Continue requires acknowledgment. That acknowledgment does not replace an approved research consent process.

## Know which mode you are using

- **Demo:** local sample tasks and scripted agent replies. No genuine model conversation.
- **Connected development:** authenticated synthetic account data on the backend. The server can use mock AI or Gemini; the operator checks `/health` to determine which. The current local configuration uses Gemini.
- **Participant build unavailable:** the study-enrollment workflow is intentionally not enabled.

To connect, keep the backend running, open Settings → Development backend (or the chat connection button), enter the server URL and a synthetic participant token, and acknowledge fictional-data use. **Do not enter a model API key.** Android emulator URL: `http://10.0.2.2:8000`.

Remembered `DEV-` agent logins use secure device storage on Android/iOS. Use **Link the other agent account** to connect and remember the second synthetic account. Both must be linked on the same server for live one-tap switching. The browser remembers only within its session. Tokens can expire. Forgetting saved logins removes automatic-login credentials; it does not erase server records.

## Tasks

Use Today for the next selected task, or Tasks to browse and add one. Enter a title, optional description, priority, duration, dates and reminder. Save commits the change; an open form alone does not. Select a card to open task details.

You can edit/reschedule, explicitly report starting, mark complete/reopen, pause/resume, adjust a plan, edit subtasks, or delete a task. Completion offers a guarded Undo. Deleting removes a task from the active list but the development backend retains historical records. If a conflict appears, refresh the backend data before editing again. Connected task writes require the service; they are not queued offline.

## My start plan and difficulty

In task details, expand **My start plan**, then open its editor. Enter both a situation (“after lunch at my desk”) and an action (“open the slides”), or leave both empty. These notes do not automatically create a reminder.

The optional difficulty choices offer a brief practical suggestion. You can skip or clear the choice. Only Save persists the plan. Self-Agent additionally offers an optional future-self note; Friend-Agent does not receive that note in AI context. These are support features, not assessments or diagnoses.

**Not now / adjust plan** offers a different start time, pause/resume or a smaller step. You decide. No automatic escalation follows a postponement.

## Agent conversations and suggestions

Tap the compact task/context row for **Conversations**. Search covers only loaded titles/messages for the active account and agent. General and task histories remain separate. The header information icon contains mode/privacy details and Settings.

Unsent drafts survive navigation and permitted agent switching while the app stays running; restarting clears composer drafts. Failed submitted attempts remain in the existing account cache. **Message options** contains failure details, edit and cancel; committed history is not edited. Long-press a bubble to copy its exact text. A delayed reply does not move you away from older messages; use **Show latest** when ready.

The task suggestion card initially shows its title/task and review controls; expand it for the existing explanation. Review opens the existing confirmation/editor, not an automatic task change.

Open Chat, check the active agent and select a task context or General conversation. Send your message; a pending state prevents duplicate taps. A failed message has retry/cancel controls. Retrying uses its original request and language, not a new billable attempt by default. If the server reports an unresolved attempt, inspect/reconnect or explicitly cancel before sending a new attempt.

In linked researcher mode, tap Self-Agent or Friend-Agent once to open that account. **Tasks and histories are separate**. Control and ordinary unlinked assignments remain restricted. Finish active focus sessions and in-flight requests before switching.

Breakdown and task-correction controls show editable suggestions. Accept only changes you want. Rejecting leaves the task unchanged. A model saying “I will remind you” does not schedule anything; use the actual reminder control.

## Focus sessions

Choose 5, 10, 15 or 25 minutes, then start when ready. Pause/resume or end separately. Remaining time is calculated from timestamps on resume. At the end, save the session and optionally reflect/check in. You must explicitly mark the task complete if you finished it. Timer use does not prove sustained attention or work quality.

## Reminders

Settings → notification preferences controls opt-in, permission, quiet hours, categories, daily cap, cooldown and optional agent wording. No permission prompt should appear before you opt in. Select a future reminder time on a task; planned-start and deadline reminders are separate opt-ins.

**Pause reminders today** suppresses the relevant requests until the stored next-midnight boundary. Suppressed reminders are not replayed as a burst. Resume reverses the pause for still-future requests. Completion, pause, deletion and edits reconcile pending reminders. In researcher mode, switching accounts changes the active device schedule and preferences.

Android/iOS settings, battery restrictions, Focus/DND and OS timing can delay or suppress reminders. Web previews do not deliver native scheduled reminders. A scheduled status does not prove delivery. Tap a reminder to open its task; you may need to reconnect the correct account.

## Progress, check-ins and data

Insights shows recent completion state, explicit task-start reports and focus starts. Optional check-ins record demonstration responses, not validated diagnostic scores. Language is recorded separately from canonical answer codes. Exports contain raw development text and pending reports; treat them as private. Development erasure is irreversible for that account's live database records, revokes its credential, retains a tombstone and does not erase provider-side data or backups.

## When something fails

Check the mode label first. For live chat, check backend health and token validity. Refresh when records conflict. If saved reconnection fails, reconnect or forget that login; the app blocks silently falling into writable mock mode. Keep unsaved form text before navigating away. See [Troubleshooting](TROUBLESHOOTING.md) for exact steps.
