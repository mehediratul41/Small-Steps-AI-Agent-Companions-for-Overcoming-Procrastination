$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$androidRoot = Join-Path $projectRoot '.tool-state/android'
$sdk = Join-Path $androidRoot 'sdk'
$adb = Join-Path $sdk 'platform-tools/adb.exe'
$emulator = Join-Path $sdk 'emulator/emulator.exe'
$appId = 'jp.ac.shimane.smallsteps.small_steps'
$serial = $null
try {
    if (-not (Test-Path -LiteralPath $adb)) { throw 'Android platform-tools are missing. See VSCODE_SETUP.md.' }
    # Process-local settings only; no Windows security, ownership or PATH changes.
    $env:ANDROID_HOME = $sdk
    $env:ANDROID_USER_HOME = Join-Path $androidRoot 'user'
    $env:ANDROID_AVD_HOME = Join-Path $androidRoot 'user/avd'
    Write-Host 'Building the latest Small Steps demo. A successful build is required before installation.' -ForegroundColor Cyan
    $shellExe = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
    if (-not $shellExe) { $shellExe = (Get-Command powershell.exe -ErrorAction Stop).Source }
    & $shellExe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'build-apk.ps1')
    if ($LASTEXITCODE -ne 0) { throw 'APK build failed. See the build log printed above; installation was not attempted.' }
    $apk = Join-Path $projectRoot 'SmallSteps-debug.apk'
    if (-not (Test-Path -LiteralPath $apk)) { throw 'The new APK was not produced.' }
    function Get-OnlineDevices {
        $output = & $adb devices
        if ($LASTEXITCODE -ne 0) { throw 'ADB could not list devices. Run this launcher from your normal Windows account.' }
        @($output | Where-Object { $_ -match '^\S+\s+device\s*$' } | ForEach-Object { ($_ -split '\s+')[0] })
    }
    $devices = @(Get-OnlineDevices)
    if ($devices.Count -eq 0) {
        $known = & $adb devices
        if (-not ($known -match '^emulator-\d+\s+offline')) {
            if (-not (Test-Path -LiteralPath $emulator)) { throw 'Connect an Android phone with USB debugging authorized, then rerun.' }
            $avds = @(& $emulator -list-avds)
            if ($avds -notcontains 'SmallSteps_API35') { throw 'SmallSteps_API35 is not installed. Connect an authorized Android phone instead.' }
            & $emulator -accel-check
            if ($LASTEXITCODE -ne 0) { throw 'Android hardware acceleration is unavailable. Enable Windows Hypervisor Platform in Windows Features, restart Windows, then rerun. Firmware virtualization was already enabled on this PC at the last check.' }
            Write-Host 'Launching SmallSteps_API35 using hardware acceleration.'
            Start-Process -FilePath $emulator -ArgumentList @('-avd','SmallSteps_API35','-accel','on','-gpu','swiftshader','-feature','-Vulkan','-no-snapshot-load','-no-audio') -WindowStyle Normal | Out-Null
        }
        Write-Host 'Waiting up to 5 minutes for an Android device. You can connect a phone instead.'
        $until = (Get-Date).AddMinutes(5)
        do {
            Start-Sleep -Seconds 3
            $devices = @(Get-OnlineDevices)
        } while ($devices.Count -eq 0 -and (Get-Date) -lt $until)
    }
    if ($devices.Count -eq 0) { throw 'No Android device became ready. The APK is built; connect a phone with USB debugging authorized and rerun.' }
    if ($devices.Count -eq 1) { $serial = $devices[0] }
    else {
        Write-Host 'Choose the device on which to install the demo:'
        for ($i = 0; $i -lt $devices.Count; $i++) { Write-Host "$($i + 1). $($devices[$i])" }
        $choice = Read-Host 'Device number'
        $number = 0
        if (-not [int]::TryParse($choice, [ref]$number) -or $number -lt 1 -or $number -gt $devices.Count) { throw 'No valid device selected; nothing was installed.' }
        $serial = $devices[$number - 1]
    }
    $until = (Get-Date).AddMinutes(5)
    do {
        $booted = (& $adb -s $serial shell getprop sys.boot_completed 2>$null | Out-String).Trim()
        if ($booted -eq '1') { break }
        Start-Sleep -Seconds 3
    } while ((Get-Date) -lt $until)
    if ($booted -ne '1') { throw "Android on $serial has not completed boot. APK installation was not attempted." }
    Write-Host "Installing the debug APK on $serial..."
    & $adb -s $serial install -r $apk
    if ($LASTEXITCODE -ne 0) { throw 'APK installation failed.' }
    $launch = & $adb -s $serial shell am start -W -n "$appId/.MainActivity"
    $launch | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0 -or -not ($launch -match 'Status:\s+ok')) { throw 'Android did not confirm activity launch.' }
    Write-Host "SUCCESS: Small Steps launched on $serial. Unlock the device to view it." -ForegroundColor Green
    exit 0
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host 'No successful Android launch is claimed unless SUCCESS appears above.'
    exit 1
}


