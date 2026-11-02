# Development API integration

See CONNECT_BACKEND.md and ../backend/README.md. The authoritative local schema is at http://127.0.0.1:8000/openapi.json. Real participant enrollment remains closed.

The adapter supports runtime bearer tokens kept in memory, server assignment, versioned demonstration acknowledgment, GET /api/state loading, UTC network dates, revision-checked task edits/deletion, stable chat IDs, server refinement acceptance/rejection, profile/check-in writes and batched behavior events.

PATCH takes a complete task with version=current+1; DELETE takes the observed version query parameter. Refine sends task/variant and Idempotency-Key. The server suggestionId is retained in the proposal event, then used for acceptance/rejection. Chat sends message/task_id plus the original pending message ID as Idempotency-Key. No request selects its own condition.

The local demo is not uploaded or overwritten. Connected preferences cache only pending reports, failed/unsent messages and focus state, scoped to server/account. The token and completed conversations are not copied into that cache. Device notifications are disabled while connected. Server task audit records and client progress reports stay separate; expiry never marks task completion.

Verified status and build limitations are in CONNECTION_VALIDATION.md. Deployment still needs approved participant authentication/consent/instruments, withdrawal/retention, PostgreSQL migrations, offline task conflict handling and distributed request reconciliation.
