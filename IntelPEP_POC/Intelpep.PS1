# === CONFIGURATION ===
$desktopPath = [Environment]::GetFolderPath("Desktop")
$logFile = Join-Path $desktopPath "IntelPep_Integration_Log.txt"
$secondPart1Path = Join-Path $desktopPath "SecondPart1.ps1"
$secondPart2Path = Join-Path $desktopPath "SecondPart2.ps1"
$taskName1 = "IntelPep_SecondPart1"

function Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp - $message"
}

function Copy-Folders {
    try {
        Log "Copying fre and Changing_Binaries folders to Desktop..."
        Copy-Item -Path "\\wosext3.amr.corp.intel.com\Users\nsadanax\fre" -Destination $desktopPath -Recurse -Force
        Copy-Item -Path "\\wosext3.amr.corp.intel.com\Users\nsadanax\Changing_Binaries" -Destination $desktopPath -Recurse -Force
        Log "Folders copied successfully."
    } catch {
        Log "Error copying folders: $_"
        throw
    }
}

function Replace-Intelpep {
    param([string]$platform)
    if ($platform -ne "PTLH-MS") {
        try {
            Log "Searching for latest intelpep.sys in DriverStore..."
            $intelpepPath = Get-ChildItem -Path "C:\Windows\System32\DriverStore\FileRepository" -Recurse -Filter "intelpep.sys" -ErrorAction Stop |
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
        } catch {
            Log "Error replacing intelpep.sys: $_"
            throw
        }
    } else {
        Log "No replacement needed for PTLH-MS."
    }
}

function Setup-Debugger {
    try {
        Log "Setting debugger settings..."
        bcdedit /dbgsettings net hostip:10.241.106.152 port:50828 key:1.2.3.4
    } catch {
        Log "Error setting debugger settings: $_"
        throw
    }
}

function Run-DisableCmd {
    try {
        Log "Running disable.cmd..."
        Start-Process "cmd.exe" -ArgumentList "/c C:\disable.cmd" -Wait
        Log "disable.cmd completed."
    } catch {
        Log "Error running disable.cmd: $_"
        throw
    }
}

function Create-SecondPart1 {
    try {
        $script = @"
`$desktopPath = [Environment]::GetFolderPath('Desktop')
`$logFile = Join-Path `$desktopPath 'IntelPep_Integration_Log.txt'
`$secondScriptPath = Join-Path `$desktopPath 'SecondPart2.ps1'
`$taskName2 = 'IntelPep_SecondPart2'

function Log {
    param([string]`$message)
    `$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path `$logFile -Value \"`$timestamp - `$message\"
}

Log \"Running SecondPart1.ps1...\"

bcdedit /debug on
Log \"Debugging enabled.\"

`$action2 = New-ScheduledTaskAction -Execute \"powershell.exe\" -Argument \"-ExecutionPolicy Bypass -File `\"`$secondScriptPath`\"\"
`$trigger2 = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName `$taskName2 -Action `$action2 -Trigger `$trigger2 -RunLevel Highest -Force
Log \"Scheduled task '`$taskName2' created.\"

Log \"Rebooting system to continue integration...\"
Restart-Computer -Force
"@
        $script | Out-File -FilePath $secondPart1Path -Encoding UTF8
        Log "SecondPart1.ps1 created."
    } catch {
        Log "Error creating SecondPart1.ps1: $_"
        throw
    }
}

function Create-SecondPart2 {
    try {
        $script = @"
`$desktopPath = [Environment]::GetFolderPath('Desktop')
`$logFile = Join-Path `$desktopPath 'IntelPep_Integration_Log.txt'

function Log {
    param([string]`$message)
    `$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path `$logFile -Value \"`$timestamp - `$message\"
}

Log \"Running SecondPart2.ps1...\"

bcdedit -set testsigning on
Log \"Test signing enabled.\"

bcdedit -set nointegritychecks on
Log \"No integrity checks enabled.\"

bcdedit -set advancedoptions on
Log \"Advanced boot options enabled.\"

Start-Process \"sfpcopy_new.exe\" -ArgumentList \"intelpep.sys intelpep.inf:intelpep.sys\" -Wait
Log \"sfpcopy_new.exe completed.\"

Start-Process \"sfpcopy.exe\" -ArgumentList \"intelpep.sys C:\windows\system32\drivers\intelpep.sys\" -Wait
Log \"sfpcopy.exe completed.\"

Log \"Rebooting system after copy...\"
Restart-Computer -Force

Start-Sleep -Seconds 10

Log \"Verifying intelpep.sys is copied...\"
if (Test-Path \"C:\windows\system32\drivers\intelpep.sys\") {
    Log \"intelpep.sys successfully copied to system32\\drivers.\"
} else {
    Log \"intelpep.sys not found in system32\\drivers.\"
}

bcdedit /debug off
Log \"Debugging disabled.\"

Unregister-ScheduledTask -TaskName \"IntelPep_SecondPart1\" -Confirm:\$false
Unregister-ScheduledTask -TaskName \"IntelPep_SecondPart2\" -Confirm:\$false
Log \"Scheduled tasks removed.\"

Log \"Final rebooting system...\"
Restart-Computer -Force
"@
        $script | Out-File -FilePath $secondPart2Path -Encoding UTF8
        Log "SecondPart2.ps1 created."
    } catch {
        Log "Error creating SecondPart2.ps1: $_"
        throw
    }
}

function Schedule-SecondPart1 {
    try {
        Log "Creating scheduled task for SecondPart1.ps1..."
        $action1 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$secondPart1Path`""
        $trigger1 = New-ScheduledTaskTrigger -AtStartup
        Register-ScheduledTask -TaskName $taskName1 -Action $action1 -Trigger $trigger1 -RunLevel Highest -Force
        Log "Scheduled task '$taskName1' created."
    } catch {
        Log "Error scheduling SecondPart1.ps1: $_"
        throw
    }
}

function Main {
    try {
        Copy-Folders
        $platform = Read-Host "Enter platform (PTLH-MS, ARLH-MS, ARLU-MS, LNL-MS)"
        Replace-Intelpep -platform $platform
        Setup-Debugger
        Run-DisableCmd
        Create-SecondPart1
        Create-SecondPart2
        Schedule-SecondPart1
        Log "Rebooting system to begin integration..."
        Restart-Computer -Force
    } catch {
        Log "Script failed: $_"
    }
}

Main
