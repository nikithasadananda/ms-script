# Function to disable USB device using pnputil
function Disable-USBDevice {
    Write-Output "Disabling USB device using pnputil..."
    pnputil /disable-device "PCI\VEN_8086&DEV_A831&SUBSYS_72708086&REV_10\3&11583659&0&68"
}

# Function to put system to sleep
function Put-SystemToSleep {
    Write-Output "Putting system into sleep state..."
    try {
        rundll32.exe powrprof.dll,SetSuspendState Sleep
    } catch {
        Write-Output "Failed to put system to sleep. Error: $_"
    }
}

# Function to set a wake timer
function Set-WakeTimer {
    Write-Output "Setting wake timer..."
    $time = (Get-Date).AddMinutes(10)
    $taskName = "WakeUpTask"
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c exit"
    $trigger = New-ScheduledTaskTrigger -Once -At $time
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -User "SYSTEM" -RunLevel Highest
}

# Function to generate Sleep Study report
function Generate-SleepStudyReport {
    Write-Output "Generating verbose sleep study report..."
    $reportPath = "C:\SleepStudyLogs"
    if (-not (Test-Path $reportPath)) {
        New-Item -ItemType Directory -Path $reportPath | Out-Null
    }
    try {
        powercfg /spr /output "$reportPath\sleepstudy_report.html"
    } catch {
        Write-Output "Failed to generate sleep study report. Error: $_"
    }
}

# Function to analyze Sleep Study report
function Check-SleepStudy {
    Write-Output "Checking Sleep Study report..."
    $ResultFile = "C:\SleepStudyLogs\sleepstudy_report.html"
    $MatchWords = "SW:", "HW:"
    foreach ($MatchWord in $MatchWords) {
        $Drips = Get-Content $ResultFile | Select-String $MatchWord
        if (-not $Drips) {
            Write-Output "$MatchWord : SleepStudy did not generate valid results !!!"
        } else {
            foreach ($Drip in $Drips) {
                $Result = $Drip.ToString().Trim()
                $parts = $Result.Split(":")
                if ($parts.Count -ge 2 -and [float]::TryParse($parts[1].Trim(), [ref]$null)) {
                    $Value = [float]$parts[1].Trim()
                    if ($MatchWord -eq "SW:" -and $Value -lt 90.00) {
                        Write-Output "`t $MatchWord : $Result ( less than 90% )"
                    } elseif ($MatchWord -eq "SW:" -and $Value -ge 90.00) {
                        Write-Output "`t $MatchWord : $Result ( good )"
                    } elseif ($MatchWord -eq "HW:" -and $Value -ne 0.00) {
                        Write-Output "`t $MatchWord : $Result ( blockers )"
                    } else {
                        Write-Output "`t $MatchWord : $Result ( good )"
                    }
                } else {
                    Write-Output "`t $MatchWord : Skipped invalid line: $Result"
                }
            }
        }
    }
}

# Main Execution
Disable-USBDevice

try {
    Write-Output "Starting WPR tracing..."
    wpr -start power

    Write-Output "Setting wake timer..."
    Set-WakeTimer

    Write-Output "Putting system into sleep state..."
    Put-SystemToSleep

    # Wait for system to wake up
    Start-Sleep -Seconds 660

    Write-Output "Waking up and stopping WPR tracing..."
    wpr -stop power.etl

    $logPath = "C:\SleepStudyLogs"
    if (-not (Test-Path $logPath)) {
        New-Item -ItemType Directory -Path $logPath | Out-Null
    }

    Move-Item -Path "power.etl" -Destination "$logPath\power.etl" -Force

    Generate-SleepStudyReport
    Check-SleepStudy

    Write-Output "Sleep study report and trace saved to $logPath"
} catch {
    Write-Output "An error occurred: $_"
}
