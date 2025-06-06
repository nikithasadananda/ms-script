@Echo off
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto continueToRun 
) else ( powershell "saps -filepath %0 -verb runas" >nul 2>&1)
exit /b 


:continueToRun 

::Clear previous powercfg settings and set AH Threshold Refills to 1, AH battery drain threshold to 1 percent, and AH Window length to 3 hours
powercfg -restoredefaultschemes
powercfg /setdcvalueindex 381b4222-f694-41f0-9685-ff5bb260df2e 8619b916-e004-4dd8-9b66-dae86f806698 aca8648e-c4b1-4baa-8cce-9390ad647f8c 1
powercfg /setdcvalueindex 381b4222-f694-41f0-9685-ff5bb260df2e 8619b916-e004-4dd8-9b66-dae86f806698 9fe527be-1b70-48da-930d-7bcf17b44990 1
powercfg /setdcvalueindex 381b4222-f694-41f0-9685-ff5bb260df2e 8619b916-e004-4dd8-9b66-dae86f806698 61f45dfe-1919-4180-bb46-8cc70e0b38f1 10800


Echo --------AH Threshold Refills set to 1, AH Battery Drain Threshold set to 1%, and AH Window Length set to 3 hours--------
Pause

Exit