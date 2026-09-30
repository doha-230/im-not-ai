@echo off
REM Humanize KR portable launcher (double-click friendly wrapper).
REM All arguments are forwarded verbatim to the PowerShell entry point,
REM which in turn forwards them to scripts\local_runner.py.
REM
REM NOTE: messages here stay ASCII on purpose. cmd.exe renders this .bat with
REM the console code page (cp949 on Korean Windows), so non-ASCII literals in
REM the file would garble. Korean guidance lives in humanize-korean.ps1.
setlocal
chcp 65001 >nul 2>nul
set "PS1=%~dp0humanize-korean.ps1"
if not exist "%PS1%" (
  echo [error] humanize-korean.ps1 not found next to this .bat: "%PS1%"
  exit /b 3
)
where powershell >nul 2>nul
if errorlevel 1 (
  echo [error] PowerShell not found. Windows 10/11 ships it by default.
  exit /b 3
)
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%PS1%" %*
exit /b %ERRORLEVEL%
