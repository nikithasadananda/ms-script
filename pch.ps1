function Disable-USBDevice {
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

function Put-SystemToSleep {
    Write-Output "Putting system into sleep state..."
    try {
        powercfg -hibernate off
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c start /min powercfg -hibernate off && rundll32.exe powrprof.dll,SetSuspendState 0,1,0" -NoNewWindow -Wait
    } catch {
        Write-Output "Failed to put system to sleep. Error: $_"
    }
}

function Set-WakeTimer {
    Write-Output "Setting wake timer..."
    $time = (Get-Date).AddMinutes(10) # Set wake timer to 10 minutes
    $taskName = "WakeUpTask"
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command `"Write-Output 'System woke up'`"" 
    $trigger = New-ScheduledTaskTrigger -Once -At $time
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -User "SYSTEM"
}

function Generate-SleepStudyReport {
    Write-Output "Generating verbose sleep study report..."
    try {
        cmd /c powercfg /spr verbose /output C:\Windows\System32\sleepstudy_report.html
    } catch {
        Write-Output "Failed to generate sleep study report. Error: $_"
    }
}

function Check-SleepStudy {
    Write-Output "Checking Sleep Study report..."
    $ResultFile = "C:\Windows\System32\sleepstudy_report.html"
    $MatchWords = "SW:", "HW:"
    Foreach ($MatchWord in $MatchWords) {
        $Drips = get-content $ResultFile | Select-String $MatchWord
        if((-NOT $Drips) -OR ($Drips.Count -eq 0)) {
            Write-Output "$MatchWord : SleepStudy did not generate valid results !!!"
        } else {
            Foreach ($Drip in $Drips) {
                $Result = $Drip.ToString().Trim()
                $Value = [float]$Result.Split(":")[1].Trim()
                if($MatchWord -eq "SW:" -and $Value -lt 90.00) {
                    Write-Output "`t $MatchWord : $Result ( less than 90% )" -ForegroundColor Yellow
                } elseif ($MatchWord -eq "SW:" -and $Value -ge 90.00) {
                    Write-Output "`t $MatchWord : $Result ( good )" -ForegroundColor Green
                } elseif ($MatchWord -eq "HW:" -and $Value -ne 0.00) {
                    Write-Output "`t $MatchWord : $Result ( blockers )" -ForegroundColor Red
                } else {
                    Write-Output "`t $MatchWord : $Result ( good )" -ForegroundColor Green
                }
            }
        }
    }
    Write-Output
}


# Main script with improved error handling and logging
$usbDeviceName = "Intel(R) USB 3.20 eXtensible Host Controller - 1.20 (Microsoft)"
$deviceDisabled = Disable-USBDevice -deviceName $usbDeviceName
if ($deviceDisabled) {
    try {
        Write-Output "Starting WPR tracing..."
        wpr -start power

        Write-Output "Setting wake timer..."
        Set-WakeTimer

        Write-Output "Putting system into sleep state for 10 minutes..."
        Put-SystemToSleep
        Start-Sleep -Seconds 600 # Sleep for 10 minutes

        Write-Output "Waking up and stopping WPR tracing..."
        wpr -stop power.etl
        Write-Output "Saving ETL file to C:\Windows\System32..."
        Move-Item -Path power.etl -Destination C:\Windows\System32\power.etl

        Generate-SleepStudyReport

        Write-Output "Sleep study report generated at C:\Windows\System32\sleepstudy_report.html"
        Check-SleepStudy
    } catch {
        Write-Output "An error occurred: $_"
    }
} else {
    Write-Output "Stopping further processing as the device was not found or cannot be disabled."
}
