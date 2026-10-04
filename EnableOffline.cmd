@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0OfflineEac.ps1" -Action Enable %*
set "AC8_EXIT_CODE=%ERRORLEVEL%"
echo.
pause
exit /b %AC8_EXIT_CODE%
