@echo off
:: RS_AH_Validation.bat - Validates AH behavior when battery reaches 10%

:: Check for admin rights
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' (
    goto continue
) else (
    powershell "Start-Process -FilePath '%~f0' -Verb RunAs" >nul 2>&1
    exit /b
)

:continue

:: Wait until battery is at or below 10%
echo Waiting for battery to reach 10%%...
:checkBattery
for /f "tokens=2 delims==" %%i in ('"wmic path Win32_Battery get EstimatedChargeRemaining /value"') do set battery=%%i
set /a battery=%battery%
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

echo AH Threshold set to 1%%, Window = 3 hours
pause
exit
