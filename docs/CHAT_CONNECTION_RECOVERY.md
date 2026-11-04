# Chat connection recovery — 2026-11-03

The screenshot showed old scripted-demo messages and a failed saved-login restoration. The local backend was not listening on port 8000. Started the existing backend script, rebuilt/installed the Android app, and confirmed the emulator's connected-development header. Opened Chat without sending a message or changing tasks.

Added a visible Retry connection action, sign-in shortcut, Japanese recovery text and a disabled composer while restoration is blocked. Retry validates the remembered account ID and condition through the existing authenticated connection flow. It never silently replaces live failures with demo replies, merges histories or renews expired credentials. Expired/revoked credentials require sign-in.

Controller and widget regressions verify blocked restoration, safe retry and restoration of the same account/history. Final Flutter regression completed successfully; analyzer clean. Verified Android build and emulator installation/launch succeeded. No live AI message was sent; iOS runtime remains unverified.

After restarting the PC, start the existing backend before using connected chat. Retry connection if necessary, or sign in again if credentials expired. Private test/build logs are in the ignored frontend .tool-state directory.

## Rejected token during a connected session

A later screenshot showed HTTP-authentication failure while the app still displayed Connected. This is a backend session token failure, not proof of a Gemini key or quota problem. The server intentionally cannot distinguish expiry from revocation to the client. Another login can replace the account's previous token.

The repository now records a 401 rejection. Chat and the app header show Sign-in required, disable repeated sends, and expose Sign in again. The same rejection remains visible if saved-login restoration closes the failed API object. An expired session is not offered a misleading token-renewal retry. Reauthentication explicitly disconnects the old account first, preserving its pending-message cache, then navigates to the existing account screen. It does not change assignments, issue admin tokens, bypass authentication or transfer pending messages to another user.

Regression coverage includes 401 handling, duplicate-send prevention, retained failed messages, rejection during restoration and navigation to sign-in. A widget test isolates the router from the application's unrelated startup-refresh lifecycle so asynchronous storage can be awaited reliably. iOS native behavior and live model responses remain unverified for this fix.

Valid account credentials are still required. The application cannot recover a password or renew an expired token by changing the Gemini API key. Legacy token-only synthetic accounts need a researcher-issued renewed development credential through the existing provisioning workflow; no account was reprovisioned automatically.

Verification for rejected-token handling: 202 Flutter tests passed, 13 skipped; analyzer clean. Android compilation/verified packaging and emulator install/launch succeeded. Native inspection confirmed Sign-in required, and the sign-in action was opened without entering credentials or sending a model request. APK SHA-256: 53853781CE40E3D19331C0DFD1C2B96481757DCBD7500C495B11B3D90154E050. Account credentials and server-side token renewal remain user/researcher responsibilities. Private logs are named session-* under .tool-state.
