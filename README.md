# ms-script
 Modern standby scripts

# 💤 PCH and IOE Sleep Study Automation Script

This PowerShell script automates the process of disabling a USB device, putting the system into sleep mode, setting a wake timer, generating a sleep study report, and analyzing the results. It's particularly useful for diagnosing sleep-related issues on Windows systems.

---

## 📋 Features

- Disable a specific USB device by name
- Start Windows Performance Recorder (WPR) tracing
- Set a scheduled wake timer (default: 20 minutes)
- Put the system into sleep mode
- Generate a verbose Sleep Study report
- Analyze Sleep Study results for software and hardware efficiency
- Save WPR trace (`.etl`) and Sleep Study report to `C:\Windows\System32`

---

## ⚙️ Prerequisites

- Run as **Administrator**
- PowerShell 5.1 or later
- Windows Performance Toolkit (`wpr.exe`)

---

## 🧩 Script Functions

### `Disable-USBDevice`
Disables a USB device by its name using 'pnputil'.

### `Put-SystemToSleep`
Disables hibernation and puts the system into sleep using `rundll32`.

### `Set-WakeTimer`
Creates a scheduled task to wake the system after a specified time (default: 10 minutes).

### `Generate-SleepStudyReport`
Generates a verbose Sleep Study report using `powercfg /spr`.

### `Check-SleepStudy`
Parses the Sleep Study report for software (`SW:`) and hardware (`HW:`) efficiency metrics.

---

## 🚀 How to Use

1. Open PowerShell as Administrator.
2. Run the script.

# Modern Standby Setup Script

This PowerShell script automates the process of identifying the current Windows OS build, locating the corresponding vetted ADK (Assessment and Deployment Kit) files, copying them locally, and initiating the ADK installation.

## 📁 Script Location

[ModernStandby_Setup.PS1](Registry_Files_and_Scripts/ModernStandby_Setup.PS1  file location on github.
- Copies the appropriate ADK files to the user's desktop.
- Installs the ADK with predefined options.

## 📌 Prerequisites

- PowerShell 5.1 or later
- Network access to the vetting share: \wosext3.amr.corp.intel.com\BSP\OS-Vetting
  ```
- Sufficient permissions to copy files and install software.

## 🚀 Usage

1. Open PowerShell as Administrator.
2. Run the script:
 ```powershell
 .\ModernStandby_Setup.PS1

🧩 Script Breakdown
Get-OSBuild
Retrieves the current Windows OS build number.

Find-MatchingVettingFolder
Searches the vetting root directory for a folder that matches the OS build number.

Copy-ADKFiles
Copies the ADK files from the vetted folder to the user's desktop.

Install-ADK
Runs the ADK installer with specific options.

📂 Output
ADK files will be copied to:

%USERPROFILE%\Desktop\ADK
If a matching vetted folder or ADK setup is not found, the script will notify the user.



# 🔧 IntelPEP_POC Automation Scripts

This repository contains PowerShell scripts to automate the integration of the `intelpep.sys` driver into Windows builds for various platforms.

## 📁 Folder Structure

## 🚀 Workflow Overview

### `Intelpep.ps1`
- Copies `fre` and `Changing_Binaries` folders from a network path to the Desktop.
- Replaces `intelpep.sys` with the latest version from DriverStore (for non-PTLH-MS platforms).
- Sets debugger settings and runs `disable.cmd`.
- Schedules `SecondPart1.ps1` to run after reboot.

### `SecondPart1.ps1`
- Enables kernel debugging.
- Schedules `SecondPart2.ps1` to run at next startup.
- Reboots the system.

### `SecondPart2.ps1`
- Enables test signing, disables integrity checks, and enables advanced boot options.
- Uses `sfpcopy_new.exe` and `sfpcopy.exe` to copy `intelpep.sys`.
- Verifies the file copy.
- Disables debugging and removes scheduled tasks.
- Performs a final reboot.

## 🧪 Usage Instructions

> ⚠️ **Run all scripts as Administrator**

1. Place all scripts (`Intelpep.ps1`, `SecondPart1.ps1`, `SecondPart2.ps1`) on your **Desktop**.
2. Open **PowerShell as Administrator**.
3. Run the main script:

```powershell
& "$env:USERPROFILE\Desktop\Intelpep.ps1"

4. The rest of the process is automated:
The system will reboot multiple times.
SecondPart1.ps1 and SecondPart2.ps1 will run automatically via scheduled tasks.
All actions are logged.

📝 Logging
All steps are logged to:

%USERPROFILE%\Desktop\IntelPep_Integration_Log.txt
