# === CONFIGURATION ===
$desktopPath = [Environment]::GetFolderPath("Desktop")
$logFile = Join-Path $desktopPath "IntelPep_Integration_Log.txt"
$secondPart1Path = Join-Path $desktopPath "SecondPart1.ps1"
$secondPart2Path = Join-Path $desktopPath "SecondPart2.ps1"
$taskName1 = "IntelPep_SecondPart1"
$taskName2 = "IntelPep_SecondPart2"
$networkBasePath = "\\wosext3.amr.corp.intel.com\Users\nsadanax"
$disableScriptPath = "C:\disable.cmd"
$debugHostIP = "10.241.106.152"
$debugPort = "50828"
$debugKey = "1.2.3.4"

# === UTILITY FUNCTIONS ===
function Log-Message {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp - $message"
}

function Get-LatestIntelpepPath {
    try {
        Get-ChildItem -Path "C:\Windows\System32\DriverStore\FileRepository" -Recurse -Filter "intelpep.sys" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 -ExpandProperty FullName
    } catch {
        Log-Message "Error locating intelpep.sys: $_"
        return $null
    }
}

# === CORE FUNCTIONS ===
function Copy-RequiredFolders {
    try {
        Log-Message "Copying required folders to Desktop..."
        Copy-Item -Path (Join-Path $networkBasePath "fre") -Destination $desktopPath -Recurse -Force
        Copy-Item -Path (Join-Path $networkBasePath "Changing_Binaries") -Destination $desktopPath -Recurse -Force
        Log-Message "Folders copied successfully."
    } catch {
        Log-Message "Error copying folders: $_"
        throw
    }
}

function Replace-IntelpepFile {
    param([string]$platform)
    if ($platform -ne "PTLH-MS") {
        $intelpepPath = Get-LatestIntelpepPath
        if ($intelpepPath) {
            try {
                Log-Message "Replacing intelpep.sys in local folders..."
                Copy-Item -Path $intelpepPath -Destination (Join-Path $desktopPath "fre\intelpep.sys") -Force
                Copy-Item -Path $intelpepPath -Destination (Join-Path $desktopPath "Changing_Binaries\intelpep.sys") -Force
                Log-Message "intelpep.sys replaced successfully."
            } catch {
                Log-Message "Error copying intelpep.sys: $_"
                throw
            }
        } else {
            Log-Message "intelpep.sys not found."
        }
    } else {
        Log-Message "No replacement needed for PTLH-MS."
    }
}

function Configure-Debugger {
    try {
        Log-Message "Configuring debugger settings..."
        bcdedit /dbgsettings net hostip:$debugHostIP port:$debugPort key:$debugKey
    } catch {
        Log-Message "Error configuring debugger: $_"
        throw
    }
}

function Run-DisableScript {
    try {
        Log-Message "Running disable.cmd..."
        Start-Process "cmd.exe" -ArgumentList "/c $disableScriptPath" -Wait
        Log-Message "disable.cmd completed."
    } catch {
        Log-Message "Error running disable.cmd: $_"
        throw
    }
}

function Create-SecondPart1Script {
    try {
        $script = @"
`$desktopPath = [Environment]::GetFolderPath('Desktop')
`$logFile = Join-Path `$desktopPath 'IntelPep_Integration_Log.txt'
`$secondScriptPath = Join-Path `$desktopPath 'SecondPart2.ps1'
`$taskName2 = '$taskName2'

function Log {
    param([string]`$message)
    `$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path `$logFile -Value \"`$timestamp - `$message\"
}

Log \"Running SecondPart1.ps1...\"
bcdedit /debug on
Log \"Debugging enabled.\"

`$action2 = New-ScheduledTaskAction -Execute \"powershell.exe\" -Argument \"-ExecutionPolicy Bypass -File `\"`$secondScriptPath`\"\""
`$trigger2 = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName `$taskName2 -Action `$action2 -Trigger `$trigger2 -RunLevel Highest -Force
Log \"Scheduled task '`$taskName2' created.\"

Log \"Rebooting system to continue integration...\"
Restart-Computer -Force
"@
        $script | Out-File -FilePath $secondPart1Path -Encoding UTF8
        Log-Message "SecondPart1.ps1 created."
    } catch {
        Log-Message "Error creating SecondPart1.ps1: $_"
        throw
    }
}

function Create-SecondPart2Script {
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

Unregister-ScheduledTask -TaskName \"$taskName1\" -Confirm:\$false
Unregister-ScheduledTask -TaskName \"$taskName2\" -Confirm:\$false
Log \"Scheduled tasks removed.\"

Log \"Final rebooting system...\"
Restart-Computer -Force
"@
        $script | Out-File -FilePath $secondPart2Path -Encoding UTF8
        Log-Message "SecondPart2.ps1 created."
    } catch {
        Log-Message "Error creating SecondPart2.ps1: $_"
        throw
    }
}

function Schedule-SecondPart1Task {
    try {
        Log-Message "Scheduling SecondPart1.ps1..."
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$secondPart1Path`""
        $trigger = New-ScheduledTaskTrigger -AtStartup
        Register-ScheduledTask -TaskName $taskName1 -Action $action -Trigger $trigger -RunLevel Highest -Force
        Log-Message "Scheduled task '$taskName1' created."
    } catch {
        Log-Message "Error scheduling SecondPart1.ps1: $_"
        throw
    }
}

# === MAIN WORKFLOW ===
function Start-IntelPepIntegration {
    try {
        Copy-RequiredFolders
        $platform = Read-Host "Enter platform (PTLH-MS, ARLH-MS, ARLU-MS, LNL-MS)"
        Replace-IntelpepFile -platform $platform
        Configure-Debugger
        Run-DisableScript
        Create-SecondPart1Script
        Create-SecondPart2Script
        Schedule-SecondPart1Task
        Log-Message "Rebooting system to begin integration..."
        Restart-Computer -Force
    } catch {
        Log-Message "Integration process failed: $_"
    }
}

# === EXECUTE ===
Start-IntelPepIntegration