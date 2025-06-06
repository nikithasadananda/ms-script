$ErrorActionPreference = "Stop"

# === Configuration ===
$taskName = "IntelPepIntegration"
$scriptPath = "$env:USERPROFILE\Desktop\IntelPEP_POC\Intelpep.ps1"
$logFile = "$env:USERPROFILE\Desktop\IntelPepIntegration_Task_Log.txt"

# === Logging Function ===
function Log-Message {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp - $message"
}

# === Register Scheduled Task ===
try {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup

    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest -Force
    Log-Message "Scheduled task '$taskName' registered to run at startup."
    Write-Host "Scheduled task '$taskName' registered to run at startup."
} catch {
    Log-Message "ERROR registering scheduled task: $_"
    Write-Host "Failed to register scheduled task. See log for details."
    exit
}

# === Run the Script Immediately ===
try {
    Log-Message "Running Intelpep.ps1 immediately..."
    Write-Host "Running Intelpep.ps1 now..."
    powershell.exe -ExecutionPolicy Bypass -File $scriptPath
    Log-Message "Intelpep.ps1 executed successfully."
} catch {
    Log-Message "ERROR running Intelpep.ps1: $_"
    Write-Host "Failed to run Intelpep.ps1. See log for details."
    exit
}

# === Optional Reboot Prompt ===
Write-Host "Do you want to reboot now to test the scheduled task? (Y/N)"
$response = Read-Host
if ($response -match '^[Yy]$') {
    Log-Message "User chose to reboot the system."
    Restart-Computer -Force
} else {
    Log-Message "User chose not to reboot."
}
