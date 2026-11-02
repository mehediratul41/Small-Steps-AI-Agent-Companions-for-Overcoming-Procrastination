param([switch]$AcceptLicenses)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$toolsRoot = Join-Path $root '.tool-state/android'
$sdk = Join-Path $toolsRoot 'sdk'
New-Item -ItemType Directory -Force $toolsRoot,$sdk | Out-Null
$jdk = Get-ChildItem -LiteralPath $toolsRoot -Directory -Filter 'jdk-*' | Select-Object -First 1
if (-not $jdk) {
    $release = Invoke-RestMethod 'https://api.adoptium.net/v3/assets/latest/21/hotspot?architecture=x64&image_type=jdk&os=windows'
    $package = $release[0].binary.package
    $archive = Join-Path $toolsRoot 'jdk.zip'
    Invoke-WebRequest $package.link -OutFile $archive -UseBasicParsing
    if ((Get-FileHash $archive -Algorithm SHA256).Hash -ne $package.checksum) { throw 'JDK checksum mismatch' }
    & tar.exe -xf $archive -C $toolsRoot
    if ($LASTEXITCODE -ne 0) { throw 'JDK extraction failed' }
    $jdk = Get-ChildItem -LiteralPath $toolsRoot -Directory -Filter 'jdk-*' | Select-Object -First 1
}
$manager = Join-Path $sdk 'cmdline-tools/latest/bin/sdkmanager.bat'
if (-not (Test-Path -LiteralPath (Join-Path $sdk 'cmdline-tools/latest/.installation-complete'))) {
    $archive = Join-Path $toolsRoot 'commandline-tools.zip'
    if (-not (Test-Path -LiteralPath $archive) -or (Get-FileHash $archive -Algorithm SHA256).Hash -ne '90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a') {
        Invoke-WebRequest 'https://dl.google.com/android/repository/commandlinetools-win-15859902_latest.zip' -OutFile $archive -UseBasicParsing
    }
    if ((Get-FileHash $archive -Algorithm SHA256).Hash -ne '90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a') { throw 'Android tools checksum mismatch' }
    $unpack = Join-Path $toolsRoot 'unpacked'
    New-Item -ItemType Directory -Force $unpack | Out-Null
    & tar.exe -xf $archive -C $unpack
    if ($LASTEXITCODE -ne 0) { throw 'Android tools extraction failed' }
    New-Item -ItemType Directory -Force (Join-Path $sdk 'cmdline-tools/latest') | Out-Null
    & robocopy.exe (Join-Path $unpack 'cmdline-tools') (Join-Path $sdk 'cmdline-tools/latest') /E /R:1 /W:1 /NFL /NDL /NJH /NJS
    if ($LASTEXITCODE -ge 8) { throw 'Android tools copy failed' }
    New-Item -ItemType File -Force (Join-Path $sdk 'cmdline-tools/latest/.installation-complete') | Out-Null
}
$savedJava = $env:JAVA_HOME
$savedAndroid = $env:ANDROID_USER_HOME
try {
    $env:JAVA_HOME = $jdk.FullName
    $env:ANDROID_USER_HOME = Join-Path $toolsRoot 'user'
    if ($AcceptLicenses) {
        1..100 | ForEach-Object { 'y' } | & $manager "--sdk_root=$sdk" --licenses
        if ($LASTEXITCODE -ne 0) { throw 'SDK license acceptance failed' }
    }
    & $manager "--sdk_root=$sdk" 'platform-tools' 'platforms;android-36' 'build-tools;36.0.0' 'cmake;3.22.1'
    if ($LASTEXITCODE -ne 0) { throw 'Android SDK installation failed' }
} finally {
    $env:JAVA_HOME = $savedJava
    $env:ANDROID_USER_HOME = $savedAndroid
}
Write-Output "Android SDK installed at $sdk"
