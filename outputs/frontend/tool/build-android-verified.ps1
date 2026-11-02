# Windows workaround: Gradle's captured Flutter child crashes with 0xC0000008
# on this host. Compile Flutter in the terminal first, then package those exact
# verified assets with Gradle. No compilation errors are ignored.
param([switch]$Online)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$stateRoot = Join-Path $projectRoot '.tool-state'
$sdkRoot = Join-Path $env:USERPROFILE 'Documents/Codex/.tools/flutter'
$androidRoot = Join-Path $stateRoot 'android'
$saved = @{}
foreach ($key in @('JAVA_HOME','ANDROID_HOME','ANDROID_USER_HOME','GRADLE_USER_HOME','PUB_CACHE','APPDATA','TEMP','TMP','PATH','CI','FLUTTER_ROOT','GIT_CONFIG_COUNT','GIT_CONFIG_KEY_0','GIT_CONFIG_VALUE_0')) {
    $saved[$key] = [Environment]::GetEnvironmentVariable($key,'Process')
}
function Get-SourceDigest {
    $paths = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'lib'),(Join-Path $projectRoot 'assets'),(Join-Path $projectRoot 'android/app/src') -File -Recurse)
    $paths += Get-Item (Join-Path $projectRoot 'pubspec.yaml'),(Join-Path $projectRoot 'pubspec.lock'),(Join-Path $projectRoot 'android/app/build.gradle.kts')
    $text = ($paths | Sort-Object FullName | ForEach-Object { $_.FullName.Substring($projectRoot.Length) + ':' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }) -join "`n"
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text)))).Replace('-','') } finally { $sha.Dispose() }
}
$result = 1
Push-Location $projectRoot
try {
    $env:JAVA_HOME = (Get-ChildItem -LiteralPath $androidRoot -Directory -Filter 'jdk-*' | Select-Object -First 1).FullName
    $env:ANDROID_HOME = Join-Path $androidRoot 'sdk'
    $env:ANDROID_USER_HOME = Join-Path $androidRoot 'user'
    $env:GRADLE_USER_HOME = Join-Path $env:USERPROFILE 'Documents/Codex/g'
    $env:PUB_CACHE = Join-Path $env:USERPROFILE 'Documents/Codex/.tools/pub-cache'
    $env:APPDATA = Join-Path $stateRoot 'roaming'
    $env:TEMP = $stateRoot
    $env:TMP = $stateRoot
    $env:PATH = (Join-Path $env:JAVA_HOME 'bin') + ';' + $env:PATH
    $env:CI = 'true'
    $env:GIT_CONFIG_COUNT = '1'
    $env:GIT_CONFIG_KEY_0 = 'safe.directory'
    $env:GIT_CONFIG_VALUE_0 = $sdkRoot.Replace('\','/')
    $sourceBefore = Get-SourceDigest
    $intermediate = Join-Path $projectRoot 'build/app/intermediates/flutter/debug'
    Write-Host 'Compiling current Flutter debug sources...' -ForegroundColor Cyan
    $compileArguments = @('assemble','--no-version-check','--depfile',"$intermediate/flutter_build.d",'--output',$intermediate,'-dTargetFile=lib/main.dart','-dTargetPlatform=android','-dBuildMode=debug','-dTrackWidgetCreation=true','-dAndroidArchs=android-arm android-arm64 android-x64','-dMinSdkVersion=24','debug_android_application')
    & (Join-Path $PSScriptRoot 'flutter.ps1') @compileArguments
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Flutter launcher failed. Retrying the same compiler through the installed Dart SDK...' -ForegroundColor Yellow
        $env:FLUTTER_ROOT = $sdkRoot
        & (Join-Path $sdkRoot 'bin/cache/dart-sdk/bin/dart.exe') (Join-Path $sdkRoot 'bin/cache/flutter_tools.snapshot') @compileArguments
    }
    if ($LASTEXITCODE -ne 0) { throw 'Flutter compilation failed. Packaging was not attempted.' }
    $kernel = Join-Path $intermediate 'flutter_assets/kernel_blob.bin'
    if (-not (Test-Path -LiteralPath $kernel)) { throw 'Compiled debug kernel is missing.' }
    Write-Host 'Packaging the freshly compiled debug assets...' -ForegroundColor Cyan
    $packagingArgs = @('-p','android','assembleDebug','-x','compileFlutterBuildDebug','--console','plain')
    if (-not $Online) { $packagingArgs += '--offline' }
    & (Join-Path $projectRoot 'android/gradlew.bat') @packagingArgs
    if ($LASTEXITCODE -ne 0) { throw 'Gradle packaging failed.' }
    $apk = Join-Path $projectRoot 'build/app/outputs/apk/debug/app-debug.apk'
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($apk)
    try {
        $entry = $zip.GetEntry('assets/flutter_assets/kernel_blob.bin')
        if ($null -eq $entry) { throw 'Packaged Flutter kernel is missing.' }
        $stream = $entry.Open()
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $packedHash = ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','') }
        finally { $sha.Dispose(); $stream.Dispose() }
    } finally { $zip.Dispose() }
    if ($packedHash -ne (Get-FileHash -LiteralPath $kernel -Algorithm SHA256).Hash) { throw 'Packaged kernel differs from the compiled sources.' }
    if ($sourceBefore -ne (Get-SourceDigest)) { throw 'Sources changed during the build. Rebuild before distribution.' }
    $delivery = Join-Path $projectRoot 'SmallSteps-debug.apk'
    Copy-Item -LiteralPath $apk -Destination $delivery -Force
    $receipt = @{builtAtUtc=[DateTime]::UtcNow.ToString('o'); sourceSha256=$sourceBefore; apkSha256=(Get-FileHash -LiteralPath $delivery -Algorithm SHA256).Hash; kernelSha256=$packedHash; mode='debug'; method='terminal Flutter assemble, then Gradle packaging'; minSdk=24}
    $receipt | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $stateRoot 'verified-android-build.json') -Encoding UTF8
    Write-Host "SUCCESS: $delivery" -ForegroundColor Green
    Write-Host "SHA256: $($receipt.apkSha256)"
    $result = 0
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host 'No new verified APK was delivered.'
} finally {
    Pop-Location
    foreach ($key in $saved.Keys) { [Environment]::SetEnvironmentVariable($key,$saved[$key],'Process') }
}
exit $result
