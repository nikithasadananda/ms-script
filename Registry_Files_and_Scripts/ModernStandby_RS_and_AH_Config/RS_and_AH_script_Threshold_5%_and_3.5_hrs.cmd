@echo off
:: RS_AH_Validation_5pct_3.5hrs.cmd

:: Check for admin rights
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' (
    goto continueToRun
) else (
    powershell "Start-Process -FilePath '%~f0' -Verb RunAs" >nul 2>&1
    exit /b
)

:continueToRun

:: Optional: Log start time
echo [%date% %time%] Script started >> %~dp0RS_AH_log.txt

:: Restore default power settings
powercfg -restoredefaultschemes

:: Set AH window to 3.5 hours (12600 seconds)
powercfg /setdcvalueindex SCHEME_CURRENT 8619b916-e004-4dd8-9b66-dae86f806698 61f45dfe-1919-4180-bb46-8cc70e0b38f1 12600

:: Optional: Set AH battery drain threshold to 5% (default, but can be explicit)
powercfg /setdcvalueindex SCHEME_CURRENT 8619b916-e004-4dd8-9b66-dae86f806698 9fe527be-1b70-48da-930d-7bcf17b44990 5

:: Apply scheme
powercfg -setactive SCHEME_CURRENT

echo ---------AH Window set to 3.5 hours, Threshold = 5%%---------
echo Please manually put the system to sleep now.
echo Avoid touching mouse/keyboard during the test.
pause

:: Optional: Log end of script
echo [%date% %time%] Settings applied, ready for sleep >> %~dp0RS_AH_log.txt

exit
