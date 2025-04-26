[CmdletBinding()]
param(
    [Alias('h')]
    [switch]$Help,

    [Parameter(Position = 0)]
    [string]$Description = 'Scripted Restore Point',

    [Parameter(Position = 1)]
    [ValidateSet(
        'APPLICATION_INSTALL', 'APPLICATION_UNINSTALL',
        'DEVICE_DRIVER_INSTALL', 'MODIFY_SETTINGS', 'CANCELLED_OPERATION')]
    [string]$RestoreType = 'MODIFY_SETTINGS'
)

if ($Help) {
    Get-Help Checkpoint-Computer -Full
    exit
}

function Log {
    param([string]$Message, [ValidateSet('INFO', 'WARN', 'ERROR')][string]$Level = 'INFO')
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    switch ($Level) {
        'INFO' { Write-Host  "[$ts] [INFO ] $Message" }
        'WARN' { Write-Warning "[$ts] [WARN ] $Message" }
        'ERROR' { Write-Error   "[$ts] [ERROR] $Message" }
    }
}

# must be elevated
if (-not ([Security.Principal.WindowsPrincipal] `
            [Security.Principal.WindowsIdentity]::GetCurrent() `
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Log 'Relaunching elevated in Windows PowerShell…' 'WARN'
    Start-Process -FilePath "$env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe" `
        -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", $MyInvocation.MyCommand.Path,
    "-Description", $Description, "-RestoreType", $RestoreType `
        -Verb RunAs
    exit
}

Log "Creating restore point '$Description' of type '$RestoreType'…" 'INFO'

try {
    Checkpoint-Computer -Description $Description -RestorePointType $RestoreType -ErrorAction Stop
    Log "Restore point successfully created." 'INFO'
}
catch {
    Log "Failed to create restore point: $_" 'ERROR'
}

Read-Host -Prompt 'Press Enter to exit'
