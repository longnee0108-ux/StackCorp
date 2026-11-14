@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Launch.ps1" -Editor
if errorlevel 1 pause
endlocal

