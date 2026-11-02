# Build in the terminal to avoid the captured-child Windows handle crash.
& (Join-Path $PSScriptRoot 'build-android-verified.ps1')
exit $LASTEXITCODE
