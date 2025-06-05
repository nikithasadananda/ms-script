$ErrorActionPreference = "Stop"

# Define paths
$taskName = "IntelPepIntegration"
$scriptPath = "$env:USERPROFILE\Desktop\IntelPEP_POC\Intelpep.ps1"

# Register the scheduled task
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -AtStartup

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest -Force
Write-Host "Scheduled task '$taskName' registered to run at startup."

# Run the script immediately
Write-Host "Running Intelpep.ps1 now..."
powershell.exe -ExecutionPolicy Bypass -File $scriptPath

# Optional: Prompt for reboot
Write-Host "Do you want to reboot now to test the scheduled task? (Y/N)"
$response = Read-Host
if ($response -match '^[Yy]$') {
    Restart-Computer -Force
}