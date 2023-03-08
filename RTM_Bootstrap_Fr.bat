@echo off

set DOWNLOAD_URL=https://raw.githubusercontent.com/wizz13150/RaptoreumStuff/main/RTM_Bootstrap_Fr.ps1
set DOWNLOAD_PATH=%CD%\RTM_Bootstrap_Fr.ps1

echo Telechargement du fichier depuis %DOWNLOAD_URL% ...
powershell.exe -Command "& { Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%DOWNLOAD_PATH%' }"

if exist "%DOWNLOAD_PATH%" (
echo Fichier telecharge avec succes !
echo Execution de RTM_Bootstrap_Fr.ps1...
powershell.exe -ExecutionPolicy RemoteSigned -File "%DOWNLOAD_PATH%"
) else (
echo Echec du telechargement du fichier.
)