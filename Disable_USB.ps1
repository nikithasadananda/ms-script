<# 
Run-SleepStudy.ps1

powercfg  /sleepstudy  [ /output  file_name ]  [ /xml]
powercfg  /sleepstudy  [ /duration  days ]
powercfg  /sleepstudy  [ /transformxmL  file_name.xml ]  [ /output  file_name.html ]

#>

# mandatory global variables
$Global:ScriptFolder = split-path $myinvocation.MyCommand.path
$Global:ScriptFileName = $MyInvocation.MyCommand.Name
$Global:ModuleName = ($ScriptFileName.Split("."))[0]
$Global:ToolRootFolder = $ScriptFolder.SubString(0, ($ScriptFolder.IndexOf("\SCA\")+5) )
$Global:LogsFolder = Join-Path $ToolRootFolder "Logs"
$env:PSModulePath += ";$ToolRootFolder"
Enable-ScaLogging 
# for Import Modules

$TimeStamp = (Get-Date).ToString( "MMdd-HHmmss" )
$ResultFilePathXml = Join-Path $LogsFolder   "$( "SCA-Sleep-Study-" + $TimeStamp + ".xml" )"
$ResultFilePathHtml = Join-Path $LogsFolder  "$( "SCA-Sleep-Study-" + $TimeStamp + ".html" )"

Function Disable-USBDevice {
    param (
        [string]$deviceName
    )
    $device = Get-PnpDevice | Where-Object { $_.Name -eq $deviceName -and $_.Status -eq "OK" }
    if ($device) {
        $instanceId = $device.InstanceId
        try {
            Disable-PnpDevice -InstanceId $instanceId -Confirm:$false
            Write-Output "$deviceName has been disabled."
            return $true
        } catch {
            Write-Output "Failed to disable: $deviceName. Error: $_"
            return $false
        }
    } else {
        Write-Output "Device not found or cannot be disabled: $deviceName"
        return $false
    }
}

Function Put-SystemToSleep {
    Write-Output "Putting system into sleep state..."
    Invoke-Expression "rundll32.exe powrprof.dll,SetSuspendState Sleep"
}

Function Set-WakeTimer {
    $time = (Get-Date).AddMinutes(20)  # Set wake timer to 20 minutes
    $taskName = "WakeUpTask"
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command `"Write-Output 'System woke up'`"" 
    $trigger = New-ScheduledTaskTrigger -Once -At $time -RepetitionInterval (New-TimeSpan -Minutes 20) -RepetitionDuration (New-TimeSpan -Minutes 20)
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -User "SYSTEM"
}

Function Generate-SleepStudyReport {
    Write-Output "Generating verbose sleep study report..."
    cmd /c powercfg /spr verbose /output C:\Windows\System32\sleepstudy_report.html
}

Function Check-SleepStudy {
    Write-HostScaInfo "Check-SleepStudy : $ResultFilePathXml ..."

    $ResultFile = $ResultFilePathXml
    
    $MatchWords = "SW:", "HW:"
    Foreach ($MatchWord in $MatchWords) {
        $Drips = get-content $ResultFile | Select-String $MatchWord
        if((-NOT $Drips) -OR ($Drips.Count -eq 0)) {
            Write-HostScaInfo "$MatchWord : SleepStudy did not generate valid results !!!" 1 Red
        } else {
            Foreach ($Drip in $Drips) {
                $Result = $Drip.ToString().Trim()
                $Value = float)
                if($Value -lt 80.00) {
                    Write-HostScaInfo "`t $MatchWord : $Result ( less than 80% )" 1 Yellow
                } else {
                    Write-HostScaInfo "`t $MatchWord : $Result ( good )" 1 Green
                }
            }
        }
    }
    Write-Host
}

Function Main {
    $FN = "$($ScriptFileName), $($MyInvocation.MyCommand):"
    Write-HostScaInfo "$FN starting ..."

    $usbDeviceName = "Intel(R) USB 3.20 eXtensible Host Controller - 1.20 (Microsoft)"
    $deviceDisabled = Disable-USBDevice -deviceName $usbDeviceName
    if ($deviceDisabled) {
        Write-Output "Starting WPR tracing..."
        wpr -start power

        Write-Output "Setting wake timer..."
        Set-WakeTimer

        Write-Output "Putting system into sleep state for 20 minutes..."
        Put-SystemToSleep
        Start-Sleep -Minutes 20  # Sleep for 20 minutes

        Write-Output "Waking up and stopping WPR tracing..."
        wpr -stop power.etl
        Write-Output "Saving ETL file to C:\Windows\System32..."
        Move-Item -Path power.etl -Destination C:\Windows\System32\power.etl

        Generate-SleepStudyReport

        Write-Output "Sleep study report generated at C:\Windows\System32\sleepstudy_report.html"
        Check-SleepStudy
    } else {
        Write-HostScaInfo "Stopping further processing as the device was not found or cannot be disabled."
    }
}

$Ret = Main
