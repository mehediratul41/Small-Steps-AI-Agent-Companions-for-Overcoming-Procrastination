# Study integration handoff

The demo is not an enrollment client. Participant builds remain closed.
This document records outstanding decisions; it is not approved consent or a
research protocol. No researcher identity, questionnaire or policy is invented.

## Inputs required from the study owner and backend maintainer

| Input | Required detail | Status |
|---|---|---|
| Service | Backend repository, staging HTTPS URL, versioned OpenAPI schema, test account | Not supplied |
| Authentication | Login/logout flow, token expiry/refresh, revocation, participant identity binding | Not supplied |
| Assignment | Authoritative immutable condition, eligibility and enrollment state, authorization rules | Not supplied |
| Consent | Approved text/version/language, acknowledgment fields, withdrawal route and approval reference | Not supplied |
| Questionnaires | Approved instrument/version, exact items, response scales, requiredness, scoring and timing | Not supplied |
| Data governance | Retention duration, deletion/anonymization rules, backup handling, access roles and export rules | Not supplied |
| Withdrawal | Effect on future collection, existing records, authentication and device reminders; confirmation receipt | Not supplied |
| Contact | Approved researcher/institution contact and support/escalation wording | Not supplied |
| Release | Approved icon/application ID, signing ownership, distribution channel | Existing demo mark adapted; study approval pending |

## Integration sequence after inputs arrive

1. Reconcile `API_CONTRACTS.md` with the backend OpenAPI schema. Agree timestamp
   semantics, validation, pagination, chat thread identifiers, event IDs,
   idempotency, conflict detection, consent versions and error envelopes.
2. Implement authentication and call `/api/participants/me`. Reject absent or
   unknown assignment; the server must authorize all condition-sensitive calls.
   Do not take assignment from settings, request bodies or cached demo records.
3. Implement approved onboarding and questionnaires. Record consent on the server
   before entering study screens; handle expired or withdrawn enrollment.
4. Replace demo preferences with participant-scoped persistence. Clear in-memory
   state and reminders on logout/account change. Never migrate fictional demo
   tasks or history into participant records.
5. Implement an event outbox only after agreeing stable event IDs and server
   deduplication. Exercise offline recovery, restart, duplicate delivery, partial
   failures and concurrent edits. Do not blindly retry POST requests.
6. Implement approved withdrawal and retention behavior end-to-end, including
   server confirmation and removal of pending device reminders.
7. Run staging integration and device acceptance with synthetic accounts in all
   three conditions. Include 401/403 handling, cross-participant access denial,
   token expiry, network loss and data isolation. Obtain study-owner sign-off
   before changing the participant gate.

API adapter tests use intercepted Dio requests, not a live service. They validate
frontend assumptions only. `DEVICE_VALIDATION.md` holds the device acceptance
record; every unobserved result must remain pending.
