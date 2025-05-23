# PreSleep.ps1

$logPath = "C:\Windows\System32\SleepAutomation.log"
function Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "$timestamp [PreSleep] $message"
}

Log "Starting PreSleep script..."

function Disable-USBDevice {
    Log "Disabling USB device using pnputil..."
    pnputil /disable-device "PCI\VEN_8086&DEV_A831&SUBSYS_72708086&REV_10\3&11583659&0&68"
}

function Set-WakeTimer {
    Log "Setting wake timer for 20 minutes using schtasks.exe..."

    $taskName = "WakeUpTask"
    $time = (Get-Date).AddMinutes(20).ToString("HH:mm")

    schtasks /Delete /TN $taskName /F > $null 2>&1
    schtasks /Create /TN $taskName /TR "powershell.exe -ExecutionPolicy Bypass -File C:\Windows\System32\PostWake.ps1" /SC ONCE /ST $time /RL HIGHEST /RU SYSTEM /F

    $task = Get-ScheduledTask -TaskName $taskName
    $task.Settings.WakeToRun = $true
    Set-ScheduledTask -TaskName $taskName -Settings $task.Settings

    Log "Wake timer set for $time"
}

function Put-SystemToSleep {
    Log "Putting system into sleep state..."
    try {
        powercfg -hibernate off
        rundll32.exe powrprof.dll,SetSuspendState 0,1,0
    } catch {
        Log "Failed to put system to sleep. Error: $_"
    }
}

Disable-USBDevice

try {
    Log "Starting WPR tracing..."
    $etlPath = "C:\Windows\System32\power.etl"
    if (Test-Path $etlPath) { Remove-Item $etlPath -Force }
    wpr -start power

    Set-WakeTimer
    Put-SystemToSleep
} catch {
    Log "An error occurred in PreSleep script: $_"
}
