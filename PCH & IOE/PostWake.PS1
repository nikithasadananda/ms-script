# PostWake.ps1

$logPath = "C:\Windows\System32\SleepAutomation.log"
function Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "$timestamp [PostWake] $message"
}

Log "System has woken up. Starting PostWake script..."

function Generate-SleepStudyReport {
    Log "Generating verbose Sleep Study report..."
    $reportPath = "C:\Windows\System32\sleepstudy_report.html"
    if (Test-Path $reportPath) { Remove-Item $reportPath -Force }

    try {
        powercfg /spr /output $reportPath
        Log "Sleep Study report generated at $reportPath"
    } catch {
        Log "Failed to generate Sleep Study report. Error: $_"
    }
}

try {
    $etlPath = "C:\Windows\System32\power.etl"
    Log "Stopping WPR tracing..."
    wpr -stop $etlPath
    Log "WPR trace saved to $etlPath"

    Generate-SleepStudyReport
} catch {
    Log "An error occurred in PostWake script: $_"
}
