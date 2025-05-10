@Echo off
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto continueToRun 
) else ( powershell "saps -filepath %0 -verb runas" >nul 2>&1)
exit /b 


:continueToRun 

Echo "Please check that Wosext3 credentials are saved by clicking 'Remember My Credentials' when logging in to Wosext3. Credentials cache will be wiped after script is run."

Pause

Echo.
Echo.
Echo.


::Run ModernStandby Setup PowerShell script
"%AppData%\Microsoft\Windows\Start Menu\Programs\Windows Powershell\Windows PowerShell.lnk" -ExecutionPolicy Bypass -File %~dp0ModernStandby_Setup.ps1