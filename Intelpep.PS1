# === CONFIGURATION ===
$desktopPath = [Environment]::GetFolderPath("Desktop")
$logFile = Join-Path $desktopPath "IntelPep_Integration_Log.txt"
$secondScriptPath = Join-Path $desktopPath "SecondPart.ps1"
$taskName = "IntelPep_SecondPart"

function Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp - $message"
}

# === STEP 1: COPY FOLDERS ===
Log "Copying fre and Changing_Binaries folders to Desktop..."
Copy-Item -Path "\\wosext3.amr.corp.intel.com\Users\nsadanax\fre" -Destination $desktopPath -Recurse -Force
Copy-Item -Path "\\wosext3.amr.corp.intel.com\Users\nsadanax\Changing_Binaries" -Destination $desktopPath -Recurse -Force
Log "Folders copied successfully."

# === STEP 2: PLATFORM CHECK ===
$platform = Read-Host "Enter platform (PTLH-MS, ARLH-MS, ARLU-MS, LNL-MS)"
Log "Platform selected: $platform"

if ($platform -ne "PTLH-MS") {
    Log "Searching for latest intelpep.sys in DriverStore..."
    $intelpepPath = Get-ChildItem -Path "C:\Windows\System32\DriverStore\FileRepository" -Recurse -Filter "intelpep.sys" -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -First 1 -ExpandProperty FullName

    if ($intelpepPath) {
        Log "Found intelpep.sys at: $intelpepPath"
        Copy-Item -Path $intelpepPath -Destination (Join-Path $desktopPath "fre\intelpep.sys") -Force
        Copy-Item -Path $intelpepPath -Destination (Join-Path $desktopPath "Changing_Binaries\intelpep.sys") -Force
        Log "intelpep.sys replaced in both folders."
    } else {
        Log "intelpep.sys not found in DriverStore."
    }
} else {
    Log "No replacement needed for PTLH-MS."
}

# === STEP 3: DEBUGGER SETUP ===
Log "Setting debugger settings..."
bcdedit /dbgsettings net hostip:10.241.106.152 port:50828 key:1.2.3.4

# === STEP 4: DISABLE.CMD ===
Log "Running disable.cmd..."
Start-Process "cmd.exe" -ArgumentList "/c C:\disable.cmd" -Wait
Log "disable.cmd completed."

# === STEP 5: CREATE SECOND PART SCRIPT ===
$secondScript = @"
`$logFile = "$logFile"
function Log {
    param([string]`$message)
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path `$logFile -Value "`$timestamp - `$message"
}

Log "Running second part of integration..."

bcdedit /debug on
Log "Debugging enabled."

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

Log "Rebooting system after second part..."
Restart-Computer -Force
"@

$secondScript | Out-File -FilePath $secondScriptPath -Encoding UTF8
Log "Second part script created at $secondScriptPath"

# === STEP 6: SCHEDULE TASK TO RUN ON STARTUP ===
Log "Creating scheduled task to run second part after reboot..."
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$secondScriptPath`""
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest -Force
Log "Scheduled task '$taskName' created."

# === STEP 7: FIRST REBOOT ===
Log "Rebooting system to continue integration..."
Restart-Computer -Force
