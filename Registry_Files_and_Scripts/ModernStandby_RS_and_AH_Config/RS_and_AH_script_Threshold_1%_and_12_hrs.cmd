@Echo off
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto continueToRun 
) else ( powershell "saps -filepath %0 -verb runas" >nul 2>&1)
exit /b 


:continueToRun 

::Clear previous powercfg settings and set AH battery drain threshold to 1 percent (AH Window Length 12 hours is default)
powercfg -restoredefaultschemes
powercfg /setdcvalueindex 381b4222-f694-41f0-9685-ff5bb260df2e 8619b916-e004-4dd8-9b66-dae86f806698 9fe527be-1b70-48da-930d-7bcf17b44990 1


Echo ---------AH Battery Drain Threshold set to 1%---------
Pause

Exit