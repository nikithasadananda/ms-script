@echo off
:: RS_AH_Validation.cmd - Validates AH behavior when battery reaches 10%

:: Check for admin rights
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' (
    goto continueToRun
) else (
    powershell "Start-Process -FilePath '%~f0' -Verb RunAs" >nul 2>&1
    exit /b
)

:continueToRun

:: Wait until battery is at or below 10%
echo ------------------------------------------------------------
echo Waiting for battery to reach 10%% before continuing...
echo ------------------------------------------------------------

:checkBattery
for /f %%i in ('powershell -command "(Get-CimInstance -ClassName Win32_Battery).EstimatedChargeRemaining"') do set battery=%%i
echo Battery: %battery%%%

if %battery% GTR 10 (
    timeout /t 60 >nul
    goto checkBattery
)

:: Apply AH settings
powercfg -restoredefaultschemes
powercfg /setdcvalueindex SCHEME_CURRENT 8619b916-e004-4dd8-9b66-dae86f806698 9fe527be-1b70-48da-930d-7bcf17b44990 1
powercfg /setdcvalueindex SCHEME_CURRENT 8619b916-e004-4dd8-9b66-dae86f806698 61f45dfe-1919-4180-bb46-8cc70e0b38f1 10800
powercfg -setactive SCHEME_CURRENT

echo ---------AH Battery Drain Threshold set to 1%% and AH Window Length set to 3 hours---------
pause
exit
