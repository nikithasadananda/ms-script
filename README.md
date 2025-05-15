# ms-script
 Modern standby scripts

# 💤 USB Sleep Study Automation Script

This PowerShell script automates the process of disabling a USB device, putting the system into sleep mode, setting a wake timer, generating a sleep study report, and analyzing the results. It's particularly useful for diagnosing sleep-related issues on Windows systems.

---

## 📋 Features

- Disable a specific USB device by name
- Start Windows Performance Recorder (WPR) tracing
- Set a scheduled wake timer (default: 10 minutes)
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

```powershell
$usbDeviceName = "Intel(R) USB 3.20 eXtensible Host Controller - 1.20 (Microsoft)"

