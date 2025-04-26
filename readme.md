# Windows Dotfiles
This is my personal collection of "dotfiles" like automation scripts for setting up a Windows environment. It includes scripts for installing software, configuring settings, and other tasks that help me get my system up and running quickly.

> [!WARNING] 
> **Use at your own risk!** This repository is intended for personal use and may not work as expected on other systems. Always create a backup or restore point before running any scripts that modify your system.

## Requirements
- Windows 10 or later
- PowerShell 5.1 or later

## Setup
1. Make sure you set your execution policy to allow running scripts. You can do this by running the following command in PowerShell as an administrator:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
2. Clone this repository to your local machine:
```powershell
git clone https://github.com/sean1832/win-dotfiles.git
cd win-dotfiles
```
3. Run `Install-Winget.ps1` to install winget first. This script will install the Windows Package Manager (winget) if it is not already installed.
```powershell
.\Install-Winget.ps1
```


## Usage
### Create System Restore Point (Recommended)
To create a system restore point, run following script:
```powershell
.\Create-RestorePoint.ps1 <description> <RestorePointType>
```
**Description**: A description for the restore point.
**RestorePointType**: The type of restore point to create. Options are:
- `APPLICATION_INSTALL`: A restore point created before installing an application.
- `APPLICATION_UNINSTALL`: A restore point created before uninstalling an application.
- `MODIFY_SETTINGS`: A restore point created before modifying system settings.
- `DEVICE_DRIVER_INSTALL`: A restore point created before installing a device driver.
- `CANCELLED_OPERATION`: A restore point created when an operation is cancelled.


### Install Applications
1. Run `Install-Apps.ps1` to install the applications. This script will use winget to install the applications.
```powershell
.\Install-Apps.ps1 config <options>
```
**Config**
- `essential`: Installs essential applications for vm or minimal system (`apps/essential.json`).
- `full`: Installs all applications. (`app/full.json`).
- `<custom>`: Installs custom applications. (`apps/<custom>.json`).

**Options:**
| Option         | Description                |
| -------------- | -------------------------- |
| `-r`, `--root` | root directory if possible |
| `-h`, `--help` | show help message and exit |

### WinUtils
Execute `winutil.bat` to run [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil).
This script merely runs command for lazy dudes like me. It will download and run the script from ChrisTitusTech's repository.
```shell
irm "https://christitus.com/win" | iex
```