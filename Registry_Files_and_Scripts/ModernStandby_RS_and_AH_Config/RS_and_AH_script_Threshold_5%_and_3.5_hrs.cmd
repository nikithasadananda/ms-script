@Echo off
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto continueToRun 
) else ( powershell "saps -filepath %0 -verb runas" >nul 2>&1)
exit /b 


:continueToRun 

::Clear previous powercfg settings and set AH Window Length to 3.5 hours (AH Battery Threshold at 5% is default)
powercfg -restoredefaultschemes
powercfg /setdcvalueindex 381b4222-f694-41f0-9685-ff5bb260df2e 8619b916-e004-4dd8-9b66-dae86f806698 61f45dfe-1919-4180-bb46-8cc70e0b38f1 12600


Echo ---------AH Window Length set to 3.5 hours---------
Pause

Exit