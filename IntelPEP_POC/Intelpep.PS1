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
        Log-Message "ERROR copying from $source to $destination: $_"
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
    # Step 1: Copy from network
    Safe-Copy "$networkBasePath\fre" $frePath
    Safe-Copy "$networkBasePath\Changing_Binaries" $changingPath

    # Step 2: Copy Changing_Binaries to System32
    Safe-Copy $changingPath "$system32\Changing_Binaries"

    # Step 3: Copy intelpep.sys to drivers
    Safe-Copy "$frePath\intelpep.sys" "$drivers\intelpep.sys"

} elseif ($platform -eq "LNL-MR" -or $platform -eq "ARL-H" -or $platform -eq "ARL-U MS") {
    # Step 1: Copy from network
    Safe-Copy "$networkBasePath\fre" $frePath
    Safe-Copy "$networkBasePath\Changing_Binaries" $changingPath

    # Step 2: Find latest intelpep.sys
    $latestIntelPep = Find-LatestIntelPep

    # Step 3: Replace in Desktop folders
    Safe-Copy $latestIntelPep "$frePath\intelpep.sys"
    Safe-Copy $latestIntelPep "$changingPath\intelpep.sys"

    # Step 4: Copy Changing_Binaries to System32
    Safe-Copy $changingPath "$system32\Changing_Binaries"

    # Step 5: Copy intelpep.sys to drivers
    Safe-Copy $latestIntelPep "$drivers\intelpep.sys"
}

# Step 6: Run bcdedit commands
Run-BCDCommands

Log-Message "IntelPep Integration Script completed"
