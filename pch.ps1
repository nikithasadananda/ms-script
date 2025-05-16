# Function to disable USB device using pnputil
function Disable-USBDevice {
    Write-Output "Disabling USB device using pnputil..."
    pnputil /disable-device "PCI\VEN_8086&DEV_A831&SUBSYS_72708086&REV_10\3&11583659&0&68"
}

# Function to set a wake timer for 20 minutes using schtasks
function Set-WakeTimer {
    Write-Output "Setting wake timer for 20 minutes using schtasks.exe..."

    $taskName = "WakeUpTask"
    $time = (Get-Date).AddMinutes(20).ToString("HH:mm")

    # Delete existing task if it exists
    schtasks /Delete /TN $taskName /F > $null 2>&1

    # Create a new task that wakes the system
    schtasks /Create /TN $taskName /TR "cmd.exe /c exit" /SC ONCE /ST $time /RL HIGHEST /RU SYSTEM /F

    # Enable WakeToRun using PowerShell
    $task = Get-ScheduledTask -TaskName $taskName
    $task.Settings.WakeToRun = $true
    Set-ScheduledTask -TaskName $taskName -Settings $task.Settings
}

# Function to put system to sleep
function Put-SystemToSleep {
    Write-Output "Putting system into sleep state..."
    try {
        powercfg -hibernate on
        rundll32.exe powrprof.dll,SetSuspendState Sleep
    } catch {
        Write-Output "Failed to put system to sleep. Error: $_"
    }
}

# Function to generate verbose Sleep Study report in System32
function Generate-SleepStudyReport {
    Write-Output "Generating verbose Sleep Study report in System32..."
    $reportPath = "C:\Windows\System32\sleepstudy_report.html"
    if (Test-Path $reportPath) { Remove-Item $reportPath -Force }

    try {
        powercfg /spr /output $reportPath
    } catch {
        Write-Output "Failed to generate Sleep Study report. Error: $_"
    }
}

# Main Execution
Disable-USBDevice

try {
    Write-Output "Starting WPR tracing..."
    $etlPath = "C:\Windows\System32\power.etl"
    if (Test-Path $etlPath) { Remove-Item $etlPath -Force }
    wpr -start power

    Write-Output "Setting wake timer..."
    Set-WakeTimer

    Write-Output "Putting system into sleep state..."
    Put-SystemToSleep

    # Wait for system to wake up (20 minutes)
    Start-Sleep -Seconds 1200

    Write-Output "Stopping WPR tracing and saving to System32..."
    wpr -stop $etlPath

    Generate-SleepStudyReport

    Write-Output " Sleep Study report and power trace saved to C:\Windows\System32"
} catch {
    Write-Output " An error occurred: $_"
}
