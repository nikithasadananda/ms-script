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
    Write-Output "Putting system into sleep state using powercfg..."
    Start-Process -FilePath "powercfg.exe" -ArgumentList "/hibernate off" -NoNewWindow -Wait
    Start-Process -FilePath "rundll32.exe" -ArgumentList "powrprof.dll,SetSuspendState 0,1,0" -NoNewWindow -Wait
}

function Set-WakeTimer {
    Write-Output "Setting wake timer..."
    $time = (Get-Date).AddMinutes(10)
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
    $ResultFilePathXml = "$env:SystemDrive\SleepStudy.xml"
    $ResultFilePathHtml = "$env:SystemDrive\SleepStudy.html"

    $ExePath = Join-Path $env:WINDIR "System32\powercfg.exe"

    $CmdArguments = "/sleepstudy", "/Output $ResultFilePathXml", "/xml"
    Start-Process -FilePath $ExePath -ArgumentList $CmdArguments -NoNewWindow -Wait

    $CmdArguments = "/sleepstudy", "/transformxml $ResultFilePathXml", "/Output $ResultFilePathHtml"
    Start-Process -FilePath $ExePath -ArgumentList $CmdArguments -NoNewWindow -Wait

    Write-Output "Sleep study report generated at $ResultFilePathHtml"
    Start-Sleep 3
    & "$ResultFilePathHtml"
}

function Check-SleepStudy {
    Write-Output "Checking Sleep Study report..."
    $ResultFile = "$env:SystemDrive\SleepStudy.html"
    $MatchWords = "SW:", "HW:"

    foreach ($MatchWord in $MatchWords) {
        $Drips = Get-Content $ResultFile | Select-String $MatchWord
        if (-not $Drips -or $Drips.Count -eq 0) {
            Write-Output "$MatchWord : SleepStudy did not generate valid results !!!"
        } else {
            foreach ($Drip in $Drips) {
                $Result = $Drip.ToString().Trim()
                $Value = [float]$Result.Split(":")[1].Trim()
                if ($MatchWord -eq "SW:" -and $Value -lt 90.00) {
                    Write-Host "`t $MatchWord : $Result ( less than 90% )" -ForegroundColor Yellow
                } elseif ($MatchWord -eq "SW:" -and $Value -ge 90.00) {
                    Write-Host "`t $MatchWord : $Result ( good )" -ForegroundColor Green
                } elseif ($MatchWord -eq "HW:" -and $Value -ne 0.00) {
                    Write-Host "`t $MatchWord : $Result ( blockers )" -ForegroundColor Red
                } else {
                    Write-Host "`t $MatchWord : $Result ( good )" -ForegroundColor Green
                }
            }
        }
    }
    Write-Output
}

# Main script
$usbDeviceName = "Intel(R) USB 3.20 eXtensible Host Controller - 1.20 (Microsoft)"
$deviceDisabled = Disable-USBDevice -deviceName $usbDeviceName

if ($deviceDisabled) {
    try {
        Write-Output "Starting WPR tracing..."
        wpr -start power

        Set-WakeTimer

        Write-Output "Putting system into sleep state for 10 minutes..."
        Put-SystemToSleep
        Start-Sleep -Seconds 600

        Write-Output "Waking up and stopping WPR tracing..."
        wpr -stop power.etl
        Move-Item -Path power.etl -Destination "$env:SystemDrive\power.etl"

        Generate-SleepStudyReport
        Check-SleepStudy
    } catch {
        Write-Output "An error occurred: $_"
    }
} else {
    Write-Output "Stopping further processing as the device was not found or cannot be disabled."
}
