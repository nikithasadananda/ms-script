# PreSleep.ps1
# Purpose: Disable a specific USB device, start WPR tracing, set a wake timer, and put the system into sleep mode.
# Logs all actions to a central log file for traceability.

$logPath = "C:\Windows\System32\SleepAutomation.log"

function Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "$timestamp [PreSleep] $message"
}

# Disable a specific USB device using its hardware ID
function Disable-USBDevice {
    Log "Disabling USB device using pnputil..."
    pnputil /disable-device "PCI\VEN_8086&DEV_A831&SUBSYS_72708086&REV_10\3&11583659&0&68"
}

# Set a scheduled task to wake the system after 20 minutes
function Set-WakeTimer {
    Log "Setting wake timer for 20 minutes..."

    $taskName = "WakeUpTask"
    $wakeTime = (Get-Date).AddMinutes(20).ToString("HH:mm")

    # Remove any existing task with the same name
    schtasks /Delete /TN $taskName /F > $null 2>&1

    # Create a new scheduled task that runs PostWake.ps1
    schtasks /Create /TN $taskName /TR "powershell.exe -ExecutionPolicy Bypass -File C:\Windows\System32\PostWake.ps1" /SC ONCE /ST $wakeTime /RL HIGHEST /RU SYSTEM /F

    # Enable WakeToRun to allow the task to wake the system
    $task = Get-ScheduledTask -TaskName $taskName
    $task.Settings.WakeToRun = $true
    Set-ScheduledTask -TaskName $taskName -Settings $task.Settings

    Log "Wake timer set for $wakeTime"
}

# Put the system into sleep mode (not hibernate)
function Put-SystemToSleep {
    Log "Putting system into sleep mode..."
    try {
        powercfg -hibernate off
        rundll32.exe powrprof.dll,SetSuspendState 0,1,0
    } catch {
        Log "Failed to enter sleep mode. Error: $_"
    }
}

# Main execution flow
Log "Starting PreSleep script..."
Disable-USBDevice

try {
    Log "Starting WPR tracing..."
    $etlPath = "C:\Windows\System32\power.etl"
    if (Test-Path $etlPath) { Remove-Item $etlPath -Force }
    wpr -start power

    Set-WakeTimer
    Put-SystemToSleep
} catch {
    Log "An error occurred during PreSleep execution: $_"
}
