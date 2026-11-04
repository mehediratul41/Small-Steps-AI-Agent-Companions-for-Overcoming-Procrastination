# Small Steps — AI Agent Companions for Overcoming Procrastination

A Flutter + FastAPI Human–AI Interaction research prototype for a master's project at Shimane University, Japan. Self-Agent encourages future-oriented reflection; Friend-Agent provides empathetic support; the standard-control condition has no AI. English and Japanese interfaces are available.

**Current status:** synthetic development accounts work; this is **not an approved participant-study deployment**. Researcher switching opens separate authenticated synthetic accounts, never reassigns a participant. Model credentials belong only on the backend. Do not publish private data or credential files.

Latest verification and known limits: [Final integration check](docs/FINAL_INTEGRATION_CHECK.md).

Latest chat UI update: [Messaging UX implementation and verification](docs/MESSAGING_UX_UPDATE.md).

## Current local database

PostgreSQL 18.6 is connected to FastAPI on this PC; existing SQLite records were preserved and verified. See [PostgreSQL setup, tests and recovery](docs/POSTGRESQL_SETUP.md). Private connection values stay in ignored local files. Fresh clones retain the SQLite default until configured.

## Multi-user accounts

Invite-only username/password accounts are now implemented for development rehearsal. Each user retains a server-assigned condition and separate data. Start with [multi-user setup](docs/DEVELOPER_MANUAL.md), [authentication](docs/AUTHENTICATION.md), [design](docs/MULTI_USER_DESIGN.md), [migration](docs/DATABASE_MIGRATIONS.md), and [test results](docs/MULTI_USER_QA_REPORT.md). Install the updated backend requirements and restart the service before using the new Account screen. This does not enable approved participant-study enrollment.

## Start locally on Windows

Use two terminals from this workspace. Existing tool installations are described in the developer manual.

Backend terminal:
```powershell
Set-Location outputs/backend
.\RUN-BACKEND.cmd
```

Frontend terminal, with an Android emulator already running:
```powershell
Set-Location outputs/frontend
.\tool\build-apk.ps1
.\.tool-state\android\sdk\platform-tools\adb.exe -s emulator-5554 install -r SmallSteps-debug.apk
.\.tool-state\android\sdk\platform-tools\adb.exe -s emulator-5554 shell am start -W -n jp.ac.shimane.smallsteps.small_steps/.MainActivity
```

The emulator reaches this PC's backend at `http://10.0.2.2:8000`; web on this PC uses `http://127.0.0.1:8000`. Health: `http://127.0.0.1:8000/health`. API explorer: `http://127.0.0.1:8000/docs`. Connect with a **synthetic participant token**, never a Gemini/OpenAI API key. For a first-time build requiring uncached Android dependencies, use `./tool/build-android-verified.ps1 -Online` instead of the offline build wrapper.

## iPhone preparation

See [iOS setup and QA](docs/IOS_SETUP_AND_QA.md). On a Mac with Xcode, run `bash outputs/frontend/tool/check-ios.sh` from the repository root. Simulator loopback refers to the Mac; physical iPhones and distributed builds need a reachable HTTPS backend. iOS signing, device testing and TestFlight validation remain unverified.

## Understand the application

| Guide | What to learn |
|---|---|
| [UX improvements](docs/UX_IMPROVEMENTS.md) | New task/chat UX, development flags and verification |
| [Learning path](docs/LEARNING_PATH.md) | A short, practical reading order |
| [System design](docs/SYSTEM_DESIGN.md) | Components, trust boundaries, storage and eight sequence diagrams |
| [Code walkthrough](docs/CODE_WALKTHROUGH.md) | Actual files, methods and request journeys |
| [User manual](docs/USER_MANUAL.md) | Using the app |
| [Developer manual](docs/DEVELOPER_MANUAL.md) | Setup, builds, tests and safe changes |
| [Researcher manual](docs/RESEARCHER_MANUAL.md) | Conditions, event interpretation and study limits |
| [API contracts](docs/API_CONTRACTS.md) | Real endpoints, versions, errors and retry rules |
| [Data and synchronization](docs/DATA_AND_SYNC.md) | Sources of truth, caches, offline behavior and conflicts |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Diagnose failures systematically |
| [QA and integration report](docs/QA_AND_INTEGRATION_REPORT.md) | Current evidence, fixes, inventory and remaining gaps |

Source: [Flutter](outputs/frontend/lib/), [FastAPI](outputs/backend/app/). Existing feature reports at the workspace root and in `outputs/` are **historical snapshots**; their dated test totals and APK hashes describe those builds. The current integration report takes precedence where results differ. The local Git checkout tracks the public repository. Later multi-user implementation changes remain local until explicitly reviewed and pushed; private credentials, databases, screenshots and build artifacts are ignored.
