$desktopPath = [Environment]::GetFolderPath("Desktop")
$logFile = Join-Path $desktopPath "IntelPep_Integration_Log.txt"
$secondScriptPath = Join-Path $desktopPath "SecondPart2.ps1"
$taskName2 = "IntelPep_SecondPart2"

function Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp - $message"
}

Log "Running SecondPart1.ps1..."

bcdedit /debug on
Log "Debugging enabled."

# Schedule SecondPart2.ps1 to run at next startup
$action2 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$secondScriptPath`""
$trigger2 = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName $taskName2 -Action $action2 -Trigger $trigger2 -RunLevel Highest -Force
Log "Scheduled task '$taskName2' created."

# Reboot the system
Log "Rebooting system to continue integration..."
Restart-Computer -Force
