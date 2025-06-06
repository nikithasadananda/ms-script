@echo off
:: Check for admin privileges
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' (
    goto continueToRun
) else (
    powershell "Start-Process -FilePath '%~f0' -Verb RunAs" >nul 2>&1
    exit /b
)

:continueToRun

:: Prompt user and wait until battery is at 10%
echo ------------------------------------------------------------
echo Waiting for battery to reach 10%% before continuing...
echo ------------------------------------------------------------

:checkBattery
for /f "tokens=2 delims==" %%i in ('"wmic path Win32_Battery get EstimatedChargeRemaining /value"') do set battery=%%i
set /a battery=%battery%
echo Current battery level: %battery%%%

if %battery% GTR 10 (
    timeout /t 60 >nul
    goto checkBattery
) else (
    echo Battery is at or below 10%%. Proceeding with test...
)

:: Restore default power schemes
powercfg -restoredefaultschemes

:: Set AH Battery Drain Threshold to 1%
powercfg /setdcvalueindex SCHEME_CURRENT 8619b916-e004-4dd8-9b66-dae86f806698 9fe527be-1b70-48da-930d-7bcf17b44990 1

:: Set AH Window Length to 3 hours (10800 seconds)
powercfg /setdcvalueindex SCHEME_CURRENT 8619b916-e004-4dd8-9b66-dae86f806698 61f45dfe-1919-4180-bb46-8cc70e0b38f1 10800

:: Apply the changes
powercfg -setactive SCHEME_CURRENT

echo ------------------------------------------------------------
echo AH Battery Drain Threshold set to 1%% and AH Window Length set to 3 hours
echo ------------------------------------------------------------
pause

exit
