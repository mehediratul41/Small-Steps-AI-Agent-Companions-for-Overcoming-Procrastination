# Keep this a basic script: Windows PowerShell can otherwise consume Flutter's
# --debug/--verbose flags as its own common parameters.
$FlutterArgs = @($args)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$flutterExecutable = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if (-not $flutterExecutable) {
    $flutterExecutable = Join-Path $env:USERPROFILE 'Documents/Codex/.tools/flutter/bin/flutter.bat'
}
if (-not (Test-Path -LiteralPath $flutterExecutable)) { throw 'Install Flutter stable or put flutter on PATH.' }
$sdkRoot = Split-Path (Split-Path $flutterExecutable -Parent) -Parent
$stateRoot = Join-Path $projectRoot '.tool-state'
New-Item -ItemType Directory -Force (Join-Path $stateRoot 'roaming'),(Join-Path $stateRoot 'local') | Out-Null
$original = @{}
foreach ($key in @('APPDATA','LOCALAPPDATA','GIT_CONFIG_COUNT','GIT_CONFIG_KEY_0','GIT_CONFIG_VALUE_0','CI','PUB_CACHE','JAVA_HOME','ANDROID_HOME','ANDROID_USER_HOME','ANDROID_AVD_HOME','ANDROID_EMULATOR_HOME','GRADLE_USER_HOME','PATH')) { $original[$key] = [Environment]::GetEnvironmentVariable($key,'Process') }
try {
    # Process-only tool locations; no global settings or user preferences changed.
    $env:APPDATA = Join-Path $stateRoot 'roaming'
    $env:LOCALAPPDATA = Join-Path $stateRoot 'local'
    $env:CI = 'true'
    $androidRoot = Join-Path $stateRoot 'android'
    $localSdk = Join-Path $androidRoot 'sdk'
    if (Test-Path -LiteralPath $localSdk) {
        $env:ANDROID_HOME = $localSdk
        $env:ANDROID_USER_HOME = Join-Path $androidRoot 'user'
        $env:ANDROID_AVD_HOME = Join-Path $androidRoot 'user/avd'
        $env:ANDROID_EMULATOR_HOME = $env:ANDROID_USER_HOME
        # Keep dependency paths short enough for Windows Java ZIP handling.
        $env:GRADLE_USER_HOME = Join-Path $env:USERPROFILE 'Documents/Codex/g'
        $jdk = Get-ChildItem -LiteralPath $androidRoot -Directory -Filter 'jdk-*' | Select-Object -First 1
        if ($jdk) {
            $env:JAVA_HOME = $jdk.FullName
            $env:PATH = (Join-Path $jdk.FullName 'bin') + ';' + $env:PATH
        }
    }
    $env:GIT_CONFIG_COUNT = '1'
    $env:GIT_CONFIG_KEY_0 = 'safe.directory'
    $env:GIT_CONFIG_VALUE_0 = $sdkRoot.Replace('\','/')
    $cachedPackages = Join-Path $env:USERPROFILE 'Documents/Codex/.tools/pub-cache'
    if (Test-Path -LiteralPath $cachedPackages) { $env:PUB_CACHE = $cachedPackages }
    Push-Location $projectRoot
    try { & $flutterExecutable @FlutterArgs; $resultCode = $LASTEXITCODE } finally { Pop-Location }
} finally {
    foreach ($key in $original.Keys) { [Environment]::SetEnvironmentVariable($key,$original[$key],'Process') }
}
exit $resultCode
