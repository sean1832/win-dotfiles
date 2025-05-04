<#
.SYNOPSIS
 JSON-driven bulk installer via winget, with optional custom install paths and enhanced error handling.

.DESCRIPTION
 This script installs applications via winget based on a named JSON config:
   - essential → apps\essential.json
   - full      → apps\full.json
   - custom    → apps\<custom>.json

.PARAMETER Mode
 Which config to load: 'essential', 'full', or a custom name.

.PARAMETER Root
 (Optional) Override the install root directory for any Category/Folder installs.

.PARAMETER Help
 Show this help message and exit.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Mode,

    [Parameter(Position = 1)]
    [Alias('r')]
    [string]$Root,

    [Alias('h')]
    [switch]$Help
)

function Show-Usage {
    @"
Usage:
  .\Install-Apps.ps1 <config> [options]

Configs:
  essential      Installs essential apps (apps\essential.json)
  full           Installs all apps      (apps\full.json)
  <custom>       Installs custom named config (apps\<custom>.json)

Options:
  -r, --root     Override the base install directory (e.g. D:\Tools)
  -h, --help     Show this help and exit
"@ | Write-Host
    exit 0
}

if ($Help -or -not $Mode) {
    Show-Usage
}

# --- Locate config file ---
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $ScriptDir '..\apps' -ChildPath "$Mode.json"
# resolve to absolute path
$configPath = (Resolve-Path $configPath).Path
if (-not (Test-Path $configPath)) {
    Write-Error "Config file '$configPath' not found."
    Show-Usage
}
Write-Host "Using config: $configPath" -ForegroundColor Cyan

# --- Load JSON ---
try {
    $config = Get-Content $configPath -Raw -ErrorAction Stop |
    ConvertFrom-Json -ErrorAction Stop
}
catch {
    Write-Error "Failed to parse JSON: $($_.Exception.Message)"
    exit 1
}

# --- Prepare log ---
$LogFile = Join-Path $ScriptDir "Install-Apps.log"
Out-File -FilePath $LogFile -Encoding UTF8 -Force

function Log {
    param($Msg, [ValidateSet('INFO', 'WARN', 'ERROR')] $Level = 'INFO')
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "[$ts] [$Level] $Msg" | Tee-Object -FilePath $LogFile -Append
}

# --- Elevation logic ---
if (-not ([Security.Principal.WindowsPrincipal] `
            [Security.Principal.WindowsIdentity]::GetCurrent() `
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Log "Relaunching elevated..." 'WARN'
    try { $pw = (Get-Process -Id $PID).Path }
    catch { $pw = Test-Path (Join-Path $PSHome 'pwsh.exe') ? "$PSHome\pwsh.exe" : "$PSHome\powershell.exe" }
    Start-Process -FilePath $pw -ArgumentList @(
        '-ExecutionPolicy', 'Bypass',
        '-File', $MyInvocation.MyCommand.Path,
        $Mode
        if ($Root) { '-Root'; $Root }
    ) -Verb RunAs
    exit
}

# --- Validate apps list ---
if (-not $config.Apps -or $config.Apps.Count -eq 0) {
    Log "No apps to install." 'WARN'
    Write-Warning "Nothing to do."
    exit 0
}

# --- Install loop ---
$total = $config.Apps.Count
$count = 0
$success = 0
$fail = 0

foreach ($app in $config.Apps) {
    $count++
    $pct = [int]((($count - 1) / $total) * 100)
    Write-Progress "Installing apps" "Installing $($app.Name)" $pct

    if (-not $app.Id -or -not $app.Name) {
        Log "Entry #$count missing Id/Name." 'ERROR'; $fail++; continue
    }

    # Already installed?
    Write-Host "Checking $($app.Name)..." -ForegroundColor Yellow
    & winget list --id $app.Id | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Log "Skipped (already installed): $($app.Name)" 'INFO'; $success++; continue
    }

    # Build base winget args
    $wingetArgs = @(
        'install',
        '--id', $app.Id,
        '--accept-source-agreements',
        '--accept-package-agreements',
        '-e'
    )

    # ONLY if user passed -r, apply a --location
    if ($Root -and $app.Category -and $app.Folder) {
        $path = Join-Path $Root "$($app.Category)\$($app.Folder)"
        New-Item -Path $path -ItemType Directory -Force | Out-Null
        $wingetArgs += @('--location', $path)
        Log "Target: $path" 'INFO'
    }
    else {
        Log "Default location" 'INFO'
    }

    # Retry loop
    $max = 2
    $try = 0
    $done = $false
    while (-not $done -and $try -le $max) {
        $try++
        Write-Host "-> Attempt $try/$($max+1): $($app.Name)" -ForegroundColor Cyan
        $cmd = "winget " + ($wingetArgs -join ' ') + " --verbose-logs --log `"$LogFile`""
        Write-Host "Running: $cmd" -ForegroundColor Yellow

        try {
            winget @wingetArgs --verbose-logs --log $LogFile
            if ($LASTEXITCODE -ne 0) { throw "Exit $LASTEXITCODE" }
            Log "Installed: $($app.Name) [try $try]" 'INFO'
            $success++
            $done = $true
        }
        catch {
            Log "Error on $($app.Name) [try $try]: $($_.Exception.Message)" 'ERROR'
            if ($try -gt $max) {
                Log "Giving up: $($app.Name)" 'ERROR'
                $fail++
            }
            else {
                Start-Sleep 5
                Log "Retrying: $($app.Name)" 'WARN'
            }
        }
    }

    Write-Progress "Installing apps" "Finished $($app.Name)" ([int]($count / $total * 100))
}

Write-Progress -Activity "Installing apps" -Completed

# --- Summary ---
$s = @(
    "",
    "===== SUMMARY =====",
    "Total:   $total",
    "Success: $success",
    "Failed:  $fail",
    "Log:     $LogFile"
) -join "`n"

Write-Host $s -ForegroundColor Green
Log $s

if ($Host.Name -match 'ConsoleHost') { Pause }
