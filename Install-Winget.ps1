# Install-Winget.ps1
# Self-elevate if not running as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Not running as Administrator. Relaunching with elevation..." -ForegroundColor Yellow
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Check if winget is already installed
$wingetPath = "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*\winget.exe"
$wingetInstalled = Get-ChildItem -Path $wingetPath -ErrorAction SilentlyContinue
if ($wingetInstalled) {
    Write-Host "winget is already installed." -ForegroundColor Green
    exit
}

# Intall WinGet using PowerShell
# see https://learn.microsoft.com/en-us/windows/package-manager/winget/
$progressPreference = 'silentlyContinue'
Write-Host "Installing WinGet PowerShell module from PSGallery..."
Install-PackageProvider -Name NuGet -Force | Out-Null
Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
Write-Host "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..."
Repair-WinGetPackageManager
Write-Host "Done."