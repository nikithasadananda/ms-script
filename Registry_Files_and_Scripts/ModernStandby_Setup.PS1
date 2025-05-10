#Copy necessary files over from server to Desktop
copy "\\wosext3.amr.corp.intel.com\BSP\Tools\ModernStandby\2x2_Execution_Tools\private-intelpep-trace.wprp" $Home\Desktop -Force
copy "\\wosext3.amr.corp.intel.com\BSP\Tools\ModernStandby\2x2_Execution_Tools\Modern_Standby_Boot_Trace\Start_IntelPepTraceLoggingProvider.bat" $Home\Desktop -Force
copy "\\wosext3.amr.corp.intel.com\BSP\Tools\ModernStandby\2x2_Execution_Tools\Modern_Standby_Boot_Trace\Stop_IntelPepTraceLoggingProvider.bat" $Home\Desktop -Force
Copy-Item -Path "\\wosext3.amr.corp.intel.com\BSP\Execution\SCA\MFC_golden\Security\SCA" -Destination "$Home\Desktop" -Recurse -Force
Copy-Item -Path "\\wosext3.amr.corp.intel.com\Users\nsadanax\TOOLS\Registry_Files_and_Scripts\ModernStandby_RS_and_AH_Config" -Destination "$Home\Desktop" -Recurse -Force

#Move necessary files into System 32
move $Home\Desktop\private-intelpep-trace.wprp C:\Windows\System32 -Force
move $Home\Desktop\Start_IntelPepTraceLoggingProvider.bat C:\Windows\System32 -Force
move $Home\Desktop\Stop_IntelPepTraceLoggingProvider.bat C:\Windows\System32 -Force


#Copy Newest ADK to Desktop
#Get-ChildItem -Directory \\wosext3.amr.corp.intel.com\BSP\OS-Vetting |
#sort Name -Descending |
#select -f 1 |
#cd
#cd .\KITS
#Copy-Item -Path ".\ADK" -Destination "$Home\Desktop" -Recurse -Force


#Install ADK with all modules
#cd $Home\Desktop\ADK
#.\adksetup.exe /features + /ceip off



# Automatically detect OS build and fetch matching ADK
$osBuild = (Get-CimInstance Win32_OperatingSystem).BuildNumber
Write-Host "Detected OS Build: $osBuild"

$osVettingRoot = "\\wosext3.amr.corp.intel.com\BSP\OS-Vetting"
$matchingFolder = Get-ChildItem -Directory $osVettingRoot |
    Where-Object { $_.Name -match $osBuild } |
    Sort-Object Name -Descending |
    Select-Object -First 1

if ($matchingFolder) {
    $adkSourcePath = Join-Path $matchingFolder.FullName "KITS\ADK"
    $adkSetupPath = Join-Path $adkSourcePath "adksetup.exe"

    if (Test-Path $adkSetupPath) {
        $adkDestPath = "$Home\Desktop\ADK"
        Copy-Item -Path $adkSourcePath -Destination $adkDestPath -Recurse -Force
        Write-Host "ADK files copied from: $adkSourcePath"

        # Install ADK
        & "$adkDestPath\adksetup.exe" /features + /ceip off
    } else {
        Write-Host "ADK setup not found in: $adkSourcePath"
    }
} else {
    Write-Host "No matching OS-Vetting folder found for build $osBuild"
}


#Disable sleep and screen off timeouts
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change monitor-timeout-ac 0
powercfg /change monitor-timeout-dc 0
Write-Host "------Sleep and Screen Off Timeout Disabled------"
Write-Host
Write-Host
Write-Host


#Enable SPR data for Short Modern Standby Sessions
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -v SleepStudySessionThresholdSeconds -t REG_DWORD -d 0 -f > $null
net stop dps > $null
net start dps > $null
Write-Host "------Short Session Data Collection Enabled------"
Write-Host
Write-Host
Write-Host


#Disable Windows Auto Update
Reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate -v NoAutoUpdate -t REG_DWORD -d 1 -f > $null
Write-Host "------Auto Update Disabled------"
Write-Host
Write-Host
Write-Host


#Stop and disable Windows Update and Update Orchestrator Service
sc.exe stop wuauserv > $null
sc.exe config wuauserv start=disabled > $null
sc.exe stop UsoSvc > $null
sc.exe config UsoSvc start=disabled > $null


#Add System32 to File Explorer Quick Access links
$o=new-object -com shell.application
$o.Namespace('c:\Windows\System32').Self.InvokeVerb("pintohome")


#Double-check that services are stopped and disabled
sc.exe query wuauserv
sc.exe qc wuauserv
sc.exe query UsoSvc
sc.exe qc UsoSvc
Write-Host "------WU and Update Orchestrator Service Disabled------"
Write-Host
Write-Host
Write-Host


#Delete cached user credentials
cmdkey.exe /delete:wosext3.amr.corp.intel.com > $null
Write-Host "------Credentials cache cleaned up------"
Write-Host
Write-Host
Write-Host



Write-Host "Setup is Complete. Press Enter to continue..."
Read-Host