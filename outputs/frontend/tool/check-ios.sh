#!/bin/bash
# Local compile only. No signing, upload, deployment or participant-data changes.
set -euo pipefail
if [[ "$(uname -s)" != Darwin ]]; then
  echo "iOS compilation requires macOS and Xcode." >&2
  exit 1
fi
cd "$(dirname "$0")/.."
command -v flutter >/dev/null
xcodebuild -version
flutter doctor -v
flutter pub get
plutil -lint ios/Runner/Info.plist ios/Runner/Info-Debug.plist ios/Runner/Runner.entitlements
flutter build ios --simulator --debug --dart-define="API_BASE_URL=${API_BASE_URL:-http://127.0.0.1:8000}"
echo "Simulator compilation completed; this does not verify iPhone signing or device behavior."
