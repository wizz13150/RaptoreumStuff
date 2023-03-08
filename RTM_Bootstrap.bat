@echo off

set DOWNLOAD_URL=https://raw.githubusercontent.com/wizz13150/RaptoreumStuff/main/RTM_Bootstrap.ps1
set DOWNLOAD_PATH=%CD%\RTM_Bootstrap.ps1

echo Downloading file from %DOWNLOAD_URL% ...
powershell.exe -Command "& { Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -UseBasicParsing -OutFile '%DOWNLOAD_PATH%' }"

if exist "%DOWNLOAD_PATH%" (
  echo File downloaded successfully!
  echo Running RTM_Bootstrap.ps1...
  powershell.exe -ExecutionPolicy RemoteSigned -Command "Set-Content -Path '%DOWNLOAD_PATH%' -Value (Get-Content -Path '%DOWNLOAD_PATH%' -Encoding utf8) -Encoding utf8; & '%DOWNLOAD_PATH%'"
) else (
  echo Failed to download file.
)
