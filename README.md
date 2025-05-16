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
Disables a USB device by its name using `Get-PnpDevice` and `Disable-PnpDevice`.

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
