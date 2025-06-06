# Stop execution on any error
$ErrorActionPreference = "Stop"

# === Configuration ===
$logFile = "$env:USERPROFILE\Desktop\IntelPepIntegration_Log.txt"
$platformFile = "$env:USERPROFILE\Desktop\platform.txt"
$networkBasePath = "\\wosext3.amr.corp.intel.com\Users\nsadanax"
$frePath = "$env:USERPROFILE\Desktop\fre"
$changingPath = "$env:USERPROFILE\Desktop\Changing_Binaries"
$driverStore = "C:\Windows\System32\DriverStore\FileRepository"
$system32 = "C:\Windows\System32"
$drivers = "$system32\drivers"
$disableCmd = "C:\disable.cmd"

# === Logging Function ===
function Log-Message {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp - $message"
}

# === Safe Copy Function with Logging and Error Handling ===
function Safe-Copy {
    param($source, $destination)
    try {
        Copy-Item -Path $source -Destination $destination -Recurse -Force
        Log-Message "Copied from $source to $destination"
    } catch {
        Log-Message "ERROR copying from $source to $destination: $_"
        throw
    }
}

# === Find the Most Recent intelpep.sys in DriverStore ===
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

# === Configure Boot Options for Debugging ===
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

# === Main Script Execution Starts Here ===
Log-Message "===== Starting IntelPep Integration Script ====="

# Read platform name from file
$platform = Get-Content -Path $platformFile -Raw
Log-Message "Detected platform: $platform"

# Perform platform-specific file operations
if ($platform -eq "PTLH-MS") {
    Safe-Copy "$networkBasePath\fre" $frePath
    Safe-Copy "$networkBasePath\Changing_Binaries" $changingPath
    Safe-Copy $changingPath "$system32\Changing_Binaries"
    Safe-Copy "$frePath\intelpep.sys" "$drivers\intelpep.sys"
} elseif ($platform -in @("LNL-MR", "ARL-H", "ARL-U MS")) {
    Safe-Copy "$networkBasePath\fre" $frePath
    Safe-Copy "$networkBasePath\Changing_Binaries" $changingPath
    $latestIntelPep = Find-LatestIntelPep
    Safe-Copy $latestIntelPep "$frePath\intelpep.sys"
    Safe-Copy $latestIntelPep "$changingPath\intelpep.sys"
    Safe-Copy $changingPath "$system32\Changing_Binaries"
    Safe-Copy $latestIntelPep "$drivers\intelpep.sys"
} else {
    Log-Message "Unsupported platform: $platform"
    exit
}

# Configure debugger settings
try {
    Invoke-Expression "bcdedit /dbgsettings net hostip:10.241.106.152 port:50828 key:1.2.3.4"
    Log-Message "Executed: bcdedit /dbgsettings"
} catch {
    Log-Message "ERROR running dbgsettings: $_"
    exit
}

# Run disable.cmd and check for success
try {
    cd C:\
    $exitCode = (Start-Process "cmd.exe" -ArgumentList "/c $disableCmd" -Wait -PassThru).ExitCode
    if ($exitCode -ne 0) {
        throw "disable.cmd exited with code $exitCode"
    }
    Log-Message "Executed: disable.cmd"
} catch {
    Log-Message "ERROR running disable.cmd: $_"
    exit
}

# Prompt user before rebooting
Write-Host "Press any key to reboot..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Restart-Computer -Force

# === Post-Reboot Actions ===

# Enable debugging
try {
    Invoke-Expression "bcdedit /debug on"
    Log-Message "Executed: bcdedit /debug on"
} catch {
    Log-Message "ERROR running bcdedit /debug on: $_"
    exit
}

# Apply additional boot configuration
Run-BCDCommands

Log-Message "===== IntelPep Integration Script completed ====="
