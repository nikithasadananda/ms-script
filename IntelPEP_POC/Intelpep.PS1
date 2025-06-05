$ErrorActionPreference = "Stop"

$logFile = "$env:USERPROFILE\Desktop\IntelPepIntegration_Log.txt"
$platformFile = "$env:USERPROFILE\Desktop\platform.txt"
$networkBasePath = "\\wosext3.amr.corp.intel.com\Users\nsadanax"
$frePath = "$env:USERPROFILE\Desktop\fre"
$changingPath = "$env:USERPROFILE\Desktop\Changing_Binaries"
$driverStore = "C:\Windows\System32\DriverStore\FileRepository"
$system32 = "C:\Windows\System32"
$drivers = "$system32\drivers"

function Log-Message {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp - $message"
}

function Safe-Copy {
    param($source, $destination)
    try {
        Copy-Item -Path $source -Destination $destination -Recurse -Force
        Log-Message "Copied from $source to $destination"
    } catch {
        Log-Message "ERROR copying from ${source} to ${destination}: $_"
        throw
    }
}

function Find-LatestIntelPep {
    $intelpep = Get-ChildItem -Path $driverStore -Recurse -Filter "intelpep.sys" |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 1
    if (-not $intelpep) {
        throw "intelpep.sys not found in DriverStore"
    }
    Log-Message "Found latest intelpep.sys: $($intelpep.FullName)"
    return $intelpep.FullName
}

function Run-BCDCommands {
    $commands = @(
        "bcdedit -set testsigning on",
        "bcdedit -set nointegritychecks on",
        "bcdedit -set advancedoptions on"
    )
    foreach ($cmd in $commands) {
        try {
            Invoke-Expression $cmd
            Log-Message "Executed: $cmd"
        } catch {
            Log-Message "ERROR running '$cmd': $_"
        }
    }
}

# Start Script
Log-Message "Starting IntelPep Integration Script"

# Read platform from platform.txt
$platform = Get-Content -Path $platformFile -Raw

if ($platform -eq "PTLH-MS") {
    Safe-Copy "$networkBasePath\fre" $frePath
    Safe-Copy "$networkBasePath\Changing_Binaries" $changingPath
    Safe-Copy $changingPath "$system32\Changing_Binaries"
    Safe-Copy "$frePath\intelpep.sys" "$drivers\intelpep.sys"
} elseif ($platform -eq "LNL-MR" -or $platform -eq "ARL-H" -or $platform -eq "ARL-U MS") {
    Safe-Copy "$networkBasePath\fre" $frePath
    Safe-Copy "$networkBasePath\Changing_Binaries" $changingPath
    $latestIntelPep = Find-LatestIntelPep
    Safe-Copy $latestIntelPep "$frePath\intelpep.sys"
    Safe-Copy $latestIntelPep "$changingPath\intelpep.sys"
    Safe-Copy $changingPath "$system32\Changing_Binaries"
    Safe-Copy $latestIntelPep "$drivers\intelpep.sys"
}

# Step: Configure debugger settings
try {
    Invoke-Expression "bcdedit /dbgsettings net hostip:10.241.106.152 port:50828 key:1.2.3.4"
    Log-Message "Executed: bcdedit /dbgsettings"
} catch {
    Log-Message "ERROR running dbgsettings: $_"
    exit
}

# Step: Run disable.cmd with exit code check
try {
    cd C:\
    $exitCode = (Start-Process "cmd.exe" -ArgumentList "/c C:\disable.cmd" -Wait -PassThru).ExitCode
    if ($exitCode -ne 0) {
        throw "disable.cmd exited with code $exitCode"
    }
    Log-Message "Executed: disable.cmd"
} catch {
    Log-Message "ERROR running disable.cmd: $_"
    exit
}

Write-Host "Press any key to reboot..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Restart-Computer -Force

# After reboot: Enable debugging
try {
    Invoke-Expression "bcdedit /debug on"
    Log-Message "Executed: bcdedit /debug on"
} catch {
    Log-Message "ERROR running bcdedit /debug on: $_"
    exit
}

# Continue with boot options
Run-BCDCommands

Log-Message "IntelPep Integration Script completed"
