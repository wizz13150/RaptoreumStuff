@echo off

set DOWNLOAD_URL=https://raw.githubusercontent.com/wizz13150/RaptoreumStuff/main/RTM_Bootstrap_Es.ps1
set DOWNLOAD_PATH=%CD%\RTM_Bootstrap_Es.ps1

echo Descargando archivo desde %DOWNLOAD_URL% ...
powershell.exe -Command "& { Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%DOWNLOAD_PATH%' }"

if exist "%DOWNLOAD_PATH%" (
echo Archivo descargado exitosamente!
echo Ejecutando RTM_Bootstrap_Es.ps1...
powershell.exe -ExecutionPolicy RemoteSigned -File "%DOWNLOAD_PATH%"
) else (
echo Fallo al descargar el archivo.
)