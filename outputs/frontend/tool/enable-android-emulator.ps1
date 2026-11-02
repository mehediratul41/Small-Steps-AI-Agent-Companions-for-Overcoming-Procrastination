# Run manually from ENABLE-ANDROID-EMULATOR.cmd. Windows handles UAC approval.
# Enables only Windows Hypervisor Platform; never restarts Windows automatically.
$ErrorActionPreference = 'Stop'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Windows will ask you to approve administrator access.' -ForegroundColor Cyan
    Write-Host 'The setup enables Windows Hypervisor Platform and does not restart automatically.'
    try {
        $shellExe = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
        $setupProcess = Start-Process -FilePath $shellExe -Verb RunAs -Wait -PassThru -ArgumentList @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath)
        )
        exit $setupProcess.ExitCode
    } catch {
        Write-Host 'Administrator approval was cancelled or unavailable. Setup did not complete.' -ForegroundColor Yellow
        exit 1
    }
}
$projectRoot = Split-Path $PSScriptRoot -Parent
$logRoot = Join-Path $projectRoot '.tool-state/build-logs'
$transcriptStarted = $false
$setupExit = 0
try {
    New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
    $logFile = Join-Path $logRoot ('hypervisor-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')
    Start-Transcript -Path $logFile | Out-Null
    $transcriptStarted = $true
    $feature = Get-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform
    Write-Host "Current Windows Hypervisor Platform state: $($feature.State)"
    if ($feature.State -ne 'Enabled') {
        Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All -NoRestart | Format-List FeatureName, RestartNeeded
    }
    $updated = Get-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform
    if ($updated.State -notin @('Enabled', 'EnablePending')) {
        throw "Windows did not confirm activation or pending activation. State: $($updated.State)"
    }
    Write-Host 'Windows accepted the Hypervisor Platform configuration.' -ForegroundColor Green
    Write-Host 'Save your work, then restart Windows yourself. No automatic restart will occur.' -ForegroundColor Cyan
    Write-Host 'After restarting, return to Codex so the emulator and Small Steps can be tested.'
    Write-Host 'This configures a prerequisite; it does not confirm that the emulator or app has launched.'
    Write-Host "Setup log: $logFile"
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host 'Windows setup did not complete. No emulator launch or restart was attempted.'
    $setupExit = 1
} finally {
    if ($transcriptStarted) { Stop-Transcript | Out-Null }
}
Read-Host 'Press Enter to close this setup window'
exit $setupExit
