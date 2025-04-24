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
    Invoke-Expression "rundll32.exe powrprof.dll,SetSuspendState Sleep"
}

function Set-WakeTimer {
    $time = (Get-Date).AddMinutes(10)
    $taskName = "WakeUpTask"
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command `"Write-Output 'System woke up'`""
    $trigger = New-ScheduledTaskTrigger -Once -At $time -RepetitionInterval (New-TimeSpan -Minutes 10) -RepetitionDuration (New-TimeSpan -Minutes 10)
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -User "SYSTEM"
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
        Start-Sleep -Seconds 600  # Sleep for 10 minutes

        Write-Output "Waking up and stopping WPR tracing..."
        wpr -stop power.etl
        Write-Output "Saving ETL file to C:\Windows\System32..."
        Move-Item -Path power.etl -Destination C:\Windows\System32\power.etl
        Write-Output "Generating verbose sleep study report..."
        cmd /c powercfg /spr verbose /output C:\Windows\System32\sleepstudy_report.html
    } catch {
        Write-Output "An error occurred: $_"
    }
} else {
    Write-Output "Stopping further processing as the device was not found or cannot be disabled."
}
