# PostWake.ps1
# Purpose: Stop WPR tracing and generate a verbose Sleep Study report after system wakes up.

$logPath = "C:\Windows\System32\SleepAutomation.log"

function Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "$timestamp [PostWake] $message"
}

# Generate a verbose Sleep Study report
function Generate-SleepStudyReport {
    Log "Generating Sleep Study report..."
    $reportPath = "C:\Windows\System32\sleepstudy_report.html"
    if (Test-Path $reportPath) { Remove-Item $reportPath -Force }

    try {
        powercfg /spr /output $reportPath
        Log "Sleep Study report saved to $reportPath"
    } catch {
        Log "Failed to generate Sleep Study report. Error: $_"
    }
}

# Stop WPR tracing and save the ETL file
function Stop-WPRTrace {
    $etlPath = "C:\Windows\System32\power.etl"
    Log "Stopping WPR tracing..."
    try {
        wpr -stop $etlPath
        Log "WPR trace saved to $etlPath"
    } catch {
        Log "Failed to stop WPR tracing. Error: $_"
    }
}

# Main execution flow
Log "System has resumed. Starting PostWake script..."
Stop-WPRTrace
Generate-SleepStudyReport
