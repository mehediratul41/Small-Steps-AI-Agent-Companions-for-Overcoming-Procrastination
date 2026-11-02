param([switch]$Install)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$venvPython = Join-Path $PSScriptRoot '.venv/Scripts/python.exe'
New-Item -ItemType Directory -Force '.tmp' | Out-Null
$env:TEMP = (Resolve-Path '.tmp').Path
$env:TMP = $env:TEMP
if (-not (Test-Path -LiteralPath $venvPython)) {
    $bundledPython = Join-Path $env:USERPROFILE '.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
    if (Test-Path -LiteralPath $bundledPython) { & $bundledPython -m venv .venv }
    elseif (Get-Command py -ErrorAction SilentlyContinue) { & py -3 -m venv .venv }
    else { throw 'Install Python 3.12 or newer, then run this script again.' }
    if ($LASTEXITCODE -ne 0) { throw 'Could not create Python environment.' }
    $Install = $true
}
if ($Install) {
    & $venvPython -m pip install -r requirements-lock.txt --cache-dir .tmp/pip-cache
    if ($LASTEXITCODE -ne 0) { throw 'Package installation failed.' }
}
if (-not (Test-Path -LiteralPath '.env')) { Copy-Item -LiteralPath '.env.example' -Destination '.env' }
Write-Host 'Small Steps development API: http://127.0.0.1:8000/docs'
Write-Host 'Provider and model are shown at /health. Ctrl+C stops the server.'
& $venvPython -m uvicorn app.main:create_app --factory --host 127.0.0.1 --port 8000 --workers 1 --no-access-log
exit $LASTEXITCODE

