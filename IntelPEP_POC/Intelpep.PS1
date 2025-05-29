$stateKey = "HKLM:\SOFTWARE\IntelPepIntegration"
$taskName = "IntelPepIntegration"

if (-not (Test-Path $stateKey)) {
    New-Item -Path $stateKey
    Set-ItemProperty -Path $stateKey -Name "Step" -Value "Init"
}

$step = Get-ItemProperty -Path $stateKey -Name "Step"

switch ($step.Step) {
    "Init" {
        $platform = Read-Host "Enter platform (PTLH-MS, ARLH-MS, ARLU-MS, LNL-MS)"
        Set-ItemProperty -Path $stateKey -Name "Platform" -Value $platform
        bcdedit /dbgsettings net hostip:10.241.106.152 port:50828 key:1.2.3.4
        Set-ItemProperty -Path $stateKey -Name "Step" -Value "Disable"
        Restart-Computer -Force
    }
    "Disable" {
        Start-Process "cmd.exe" -ArgumentList "/c C:\disable.cmd" -Wait
        Set-ItemProperty -Path $stateKey -Name "Step" -Value "EnableDebug"
        Restart-Computer -Force
    }
    "EnableDebug" {
        bcdedit /debug on
        bcdedit -set testsigning on
        bcdedit -set nointegritychecks on
        bcdedit -set advancedoptions on
        Set-ItemProperty -Path $stateKey -Name "Step" -Value "CopyIntelPep"
        Restart-Computer -Force
    }
    "CopyIntelPep" {
        $platform = Get-ItemProperty -Path $stateKey -Name "Platform"
        if ($platform.Platform -ne "PTLH-MS") {
            $intelpepPath = Get-ChildItem -Path "C:\Windows\System32\DriverStore\FileRepository" -Recurse -Filter "intelpep.sys" |
                            Sort-Object LastWriteTime -Descending |
                            Select-Object -First 1 -ExpandProperty FullName
            if ($intelpepPath) {
                Copy-Item -Path $intelpepPath -Destination "C:\Windows\System32\drivers\intelpep.sys" -Force
                Copy-Item -Path $intelpepPath -Destination "C:\Users\$env:USERNAME\Desktop\fre\intelpep.sys" -Force
                Copy-Item -Path $intelpepPath -Destination "C:\Users\$env:USERNAME\Desktop\Changing_Binaries\intelpep.sys" -Force
            }
        }
        Remove-Item -Path $stateKey -Recurse
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Restart-Computer -Force
    }
}
