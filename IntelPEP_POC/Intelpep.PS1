$stateKey = "HKLM:\SOFTWARE\IntelPepIntegration"
$taskName = "IntelPepIntegration"
$platformFile = "$env:USERPROFILE\Desktop\platform.txt"
$logFile = "$env:USERPROFILE\Desktop\IntelPepIntegration_Log.txt"
$networkBasePath = "\\wosext3.amr.corp.intel.com\Users\nsadanax"

function Log-Message {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp - $message"
}

if (-not (Test-Path $platformFile)) {
    "PTLH-MS" | Out-File -FilePath $platformFile -Encoding UTF8
}
$platform = Get-Content $platformFile -Raw

if (-not (Test-Path $stateKey)) {
    New-Item -Path $stateKey | Out-Null
    Set-ItemProperty -Path $stateKey -Name "Step" -Value "Init"
}

$step = (Get-ItemProperty -Path $stateKey).Step

switch ($step) {
    "Init" {
        Log-Message "Step: Init - Configuring debugger settings"
        Set-ItemProperty -Path $stateKey -Name "Platform" -Value $platform
        bcdedit /dbgsettings net hostip:10.241.106.152 port:50828 key:1.2.3.4
        Set-ItemProperty -Path $stateKey -Name "Step" -Value "Disable"
        Restart-Computer -Force
    }
    "Disable" {
        Log-Message "Step: Disable - Running disable.cmd"
        cd C:\
        Start-Process "cmd.exe" -ArgumentList "/c C:\disable.cmd" -Wait
        Set-ItemProperty -Path $stateKey -Name "Step" -Value "EnableDebug"
        Restart-Computer -Force
    }
    "EnableDebug" {
        Log-Message "Step: EnableDebug - Enabling debugging"
        bcdedit /debug on
        Set-ItemProperty -Path $stateKey -Name "Step" -Value "CopyIntelPep"
        Restart-Computer -Force
    }
    "CopyIntelPep" {
        Log-Message "Step: CopyIntelPep - Copying intelpep.sys based on platform"
        if ($platform -eq "PTLH-MS") {
            Log-Message "Platform is PTLH-MS - Copying fre and Changing_Binaries from network"
            Copy-Item -Path (Join-Path $networkBasePath "fre") -Destination "$env:USERPROFILE\Desktop" -Recurse -Force
            Copy-Item -Path (Join-Path $networkBasePath "Changing_Binaries") -Destination "$env:USERPROFILE\Desktop" -Recurse -Force
            $intelpepPath = "$env:USERPROFILE\Desktop\fre\intelpep.sys"
            Copy-Item -Path $intelpepPath -Destination "C:\Windows\System32\drivers\intelpep.sys" -Force
        } else {
            Log-Message "Platform is not PTLH-MS - Copying intelpep.sys from DriverStore"
            $intelpepPath = Get-ChildItem -Path "C:\Windows\System32\DriverStore\FileRepository" -Recurse -Filter "intelpep.sys" |
                            Sort-Object LastWriteTime -Descending |
                            Select-Object -First 1 -ExpandProperty FullName
            if ($intelpepPath) {
                Copy-Item -Path $intelpepPath -Destination "$env:USERPROFILE\Desktop\fre\intelpep.sys" -Force
                Copy-Item -Path $intelpepPath -Destination "$env:USERPROFILE\Desktop\Changing_Binaries\intelpep.sys" -Force
                Copy-Item -Path $intelpepPath -Destination "C:\Windows\System32\drivers\intelpep.sys" -Force
            }
        }
        Set-ItemProperty -Path $stateKey -Name "Step" -Value "ConfigureBootOptions"
        Restart-Computer -Force
    }
    "ConfigureBootOptions" {
        Log-Message "Step: ConfigureBootOptions - Configuring boot options"
        bcdedit -set testsigning on
        bcdedit -set nointegritychecks on
        bcdedit -set advancedoptions on
        Set-ItemProperty -Path $stateKey -Name "Step" -Value "RunSfpcopy"
        Restart-Computer -Force
    }
    "RunSfpcopy" {
        Log-Message "Step: RunSfpcopy - Running sfpcopy commands"
        cd "$env:USERPROFILE\Desktop\fre"
        Start-Process "sfpcopy_new.exe" -ArgumentList "intelpep.sys intelpep.inf:intelpep.sys" -Wait
        cd "C:\Windows\System32\Changing_Binaries"
        Start-Process "sfpcopy.exe" -ArgumentList "intelpep.sys C:\Windows\System32\drivers\intelpep.sys" -Wait
        Log-Message "Step: RunSfpcopy - Cleaning up"
        Remove-Item -Path $stateKey -Recurse
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Restart-Computer -Force
    }
}
