$desktopPath = [Environment]::GetFolderPath("Desktop")
$logFile = Join-Path $desktopPath "IntelPep_Integration_Log.txt"

function Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp - $message"
}

Log "Running SecondPart2.ps1..."

bcdedit -set testsigning on
Log "Test signing enabled."

bcdedit -set nointegritychecks on
Log "No integrity checks enabled."

bcdedit -set advancedoptions on
Log "Advanced boot options enabled."

Start-Process "sfpcopy_new.exe" -ArgumentList "intelpep.sys intelpep.inf:intelpep.sys" -Wait
Log "sfpcopy_new.exe completed."

Start-Process "sfpcopy.exe" -ArgumentList "intelpep.sys C:\windows\system32\drivers\intelpep.sys" -Wait
Log "sfpcopy.exe completed."

Log "Rebooting system after copy..."
Restart-Computer -Force

# After reboot
Start-Sleep -Seconds 10

Log "Verifying intelpep.sys is copied..."
if (Test-Path "C:\windows\system32\drivers\intelpep.sys") {
    Log "intelpep.sys successfully copied to system32\\drivers."
} else {
    Log "intelpep.sys not found in system32\\drivers."
}

bcdedit /debug off
Log "Debugging disabled."

Unregister-ScheduledTask -TaskName "IntelPep_SecondPart1" -Confirm:$false
Unregister-ScheduledTask -TaskName "IntelPep_SecondPart2" -Confirm:$false
Log "Scheduled tasks removed."

Log "Final rebooting system..."
Restart-Computer -Force
