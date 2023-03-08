##################################################################
### Script Bootstrap Auto para la última versión, para Windows ###
##################################################################

# Permitir la ejecución del script - Para probar
#Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

Write-Warning "Iniciando el script para aplicar automáticamente un Bootstrap de Raptoreum"

# Definición de variables

# Ruta de la carpeta del monedero en la que se debe aplicar el bootstrap. Por defecto "$env:APPDATA\raptoreumcore".
$walletDirectory = "$env:APPDATA\raptoreumcore"
# Ruta del archivo bootstrap.zip
$bootstrapZipPath = "$env:APPDATA\raptoreumcore\bootstrap.zip"

# Otras variables fijas
$walletProcessName = "raptoreum*"
$dateSuffix = Get-Date -Format "ddMMyyyy"
$bootstrapUrl = "https://bootstrap.raptoreum.com/bootstraps/bootstrap.zip"
$blocksDirectory = "$walletDirectory\blocks"
$chainstateDirectory = "$walletDirectory\chainstate"
$evodbDirectory = "$walletDirectory\evodb"
$llmqDirectory = "$walletDirectory\llmq"
$powcachePath = "$walletDirectory\powcache.dat"
# Cuadro de diálogo para seleccionar una carpeta más tarde
Add-Type -AssemblyName System.Windows.Forms

# Función para mostrar la fecha y la hora
function Write-CurrentTime {
    Write-Host ('[' + (Get-Date).ToString("HH:mm:ss") + ']') -NoNewline
}

# Función para comprobar el checksum del archivo bootstrap.zip descargado/usado
function Check-BootstrapZipChecksum {
    Write-CurrentTime; Write-Host " Comprobando el checksum del archivo 'bootstrap.zip'..." -ForegroundColor Green
    Write-CurrentTime; Write-Host " Fuente: https://checksums.raptoreum.com/checksums/bootstrap-checksums.txt" -ForegroundColor Green
    $checksumsUrl = "https://checksums.raptoreum.com/checksums/bootstrap-checksums.txt"
    $checksums = Invoke-WebRequest -Uri $checksumsUrl -UseBasicParsing
    $remoteChecksum = ($checksums.Content.Split("`n") | Select-String -Pattern "v$latestVersion/no-index/bootstrap.zip").ToString().Split(" ")[0].Trim()
    Write-CurrentTime; Write-Host " Checksum: $remoteChecksum" -ForegroundColor Green
    $localChecksum = (Get-FileHash -Path $bootstrapZipPath -Algorithm SHA256 | Select-Object -ExpandProperty Hash).ToLower()
    if ($localChecksum -eq $remoteChecksum) {
        Write-CurrentTime; Write-Host " Verificación del checksum exitosa. El bootstrap es auténtico." -ForegroundColor Green
        Write-CurrentTime; Write-Host " Checksum local    : $($localChecksum)" -ForegroundColor Green
        Write-CurrentTime; Write-Host " Checksum en línea : $($remoteChecksum)" -ForegroundColor Green
    } else {
        Write-CurrentTime; Write-Host " Verificación del checksum fallida. El bootstrap puede haber sido modificado, considera eliminarlo. O el script puede estar desactualizado." -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Checksum local    : $($localChecksum)" -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Checksum en línea : $($remoteChecksum)" -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Deteniendo el script..." -ForegroundColor Red
        pause
        exit
    }
}

# Función para obtener la versión de raptoreum-qt.exe
function Get-FileVersion {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    $fileVersionInfo = Get-Item $FilePath -ErrorAction SilentlyContinue| Get-ItemProperty | Select-Object -ExpandProperty VersionInfo
    return $fileVersionInfo.ProductVersion
}

# Función para comparar el archivo bootstrap con la versión en línea. Verificación de suma de comprobación aquí
function Check-BootstrapZip {
    param(
        [string]$bootstrapZipPath,
        [string]$bootstrapUrl
    )
    $localFile = Get-Item $bootstrapZipPath
    $remoteFile = Invoke-WebRequest -Uri $bootstrapUrl -Method Head
    $remoteLastModified = [datetime]::ParseExact($remoteFile.Headers.'Last-Modified', 'ddd, dd MMM yyyy HH:mm:ss \G\M\T', [System.Globalization.CultureInfo]::InvariantCulture)
    $remoteSize = $remoteFile.Headers.'Content-Length'
    if ($localFile.LastWriteTime -ge $remoteLastModified -and $localFile.Length -eq $remoteSize) {
        Write-CurrentTime; Write-Host " El archivo bootstrap.zip está actualizado." -ForegroundColor Green
        Write-CurrentTime; Write-Host " Bootstrap Local     : Tamaño: $(("{0:N2}" -f ($localFile.Length / 1GB))) GB, Fecha: $($localFile.LastWriteTime)" -ForegroundColor Green
        Write-CurrentTime; Write-Host " Bootstrap en línea  : Tamaño: $(("{0:N2}" -f ($remoteSize / 1GB))) GB, Fecha: $($remoteLastModified)" -ForegroundColor Green
        # Verificar la suma de comprobación
        Check-BootstrapZipChecksum
    } 
    else {
        Write-CurrentTime; Write-Host " Su bootstrap no está actualizado o incompleto." -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Bootstrap Local     : Tamaño: $(("{0:N2}" -f ($localFile.Length / 1GB))) GB, Fecha: $($localFile.LastWriteTime)" -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Bootstrap en línea  : Tamaño: $(("{0:N2}" -f ($remoteSize / 1GB))) GB, Fecha: $($remoteLastModified)" -ForegroundColor Yellow
        Get-BootstrapSize
        $confirmDownload = Read-Host " ¿Desea descargar el archivo bootstrap.zip ? (Presione Enter si no lo sabe) (s/n)"
        if ($confirmDownload.ToLower() -eq "n") {
            Write-CurrentTime
            Write-Host " No se descargará el archivo bootstrap.zip, pero se continuará..." -ForegroundColor Yellow
        } 
        else {
            Write-CurrentTime
            Write-Host " Descargando el archivo bootstrap.zip..." -ForegroundColor Green
            Invoke-WebRequest -Uri $bootstrapUrl -OutFile $bootstrapZipPath -ErrorAction Stop
            # Verificar la suma de comprobación
            Check-BootstrapZipChecksum
        }
    }
}

# Función para imprimir información de descarga
function Download-FileWithProgress {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    Write-CurrentTime; Write-Host " Descargando el bootstrap de $Url" -ForegroundColor Green
    #Write-Progress -Activity "Downloading the bootstrap..." -Status " Downloading..." -PercentComplete 0
    Invoke-WebRequest -Uri $Url -OutFile $FilePath -ErrorAction Stop
    # Mejorar la descarga aquí - ToDo
    #if ($LASTEXITCODE -eq 0) {
        #Write-Progress -Activity " Download of the bootstrap..." -Status " Download complete!" -PercentComplete 100
    #} else {
        #Write-Progress -Activity " Download of the bootstrap..." -Status " Download failed!" -PercentComplete 100
    #}
}

# Función para obtener el tamaño del bootstrap en línea
function Get-BootstrapSize {
    $bootstrapUrl = "https://bootstrap.raptoreum.com/bootstraps/bootstrap.zip"
    $response = Invoke-WebRequest -Uri $bootstrapUrl -Method Head -UseBasicParsing
    $sizeInBytes = $response.Headers.'Content-Length'
    $sizeInGB = [math]::Round($sizeInBytes / 1GB, 2)
    Write-CurrentTime; Write-Host " Tamaño del bootstrap en línea: $sizeInBytes bytes ($sizeInGB GB)" -ForegroundColor Green
}

# Verificar la versión actual y la última disponible
# Verificar la versión actual en el equipo, si la carpeta predeterminada
$corePath = "$env:ProgramFiles\RaptoreumCore\raptoreum-qt.exe"
if (Test-Path $corePath) {
    $coreVersion = Get-FileVersion $corePath
    Write-CurrentTime; Write-Host " Su versión de RaptoreumCore es            : $coreVersion" -ForegroundColor Green
}
else {
    Write-CurrentTime; Write-Host " Su versión de RaptoreumCore es            : No encontrada" -ForegroundColor Yellow
    # Preguntar si hay una ubicación personalizada o no
    $answer = Read-Host " ¿Necesita seleccionar un directorio personalizado para el lanzador de RaptoreumCore? (s/n)"
    if ($answer.ToLower() -eq "s") {
        # Pedir un directorio personalizado, si no se encuentra raptoreum-qt.exe en la ubicación predeterminada
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Seleccione el directorio personalizado del lanzador de RaptoreumCore"
        $dialog.ShowDialog() | Out-Null
        if ($dialog.SelectedPath) {
            $corePath = $dialog.SelectedPath + "\raptoreum-qt.exe"
            $coreVersion = Get-FileVersion $corePath
            # Comprobar si la carpeta seleccionada contiene raptoreum-qt.exe
            if (Test-Path "$corePath") {
                Write-CurrentTime; Write-Host " raptoreum-qt.exe encontrado..." -ForegroundColor Green
                Write-CurrentTime; Write-Host " El directorio de raptoreum-qt.exe es: " $dialog.SelectedPath ... -ForegroundColor Green
                Write-CurrentTime; Write-Host " Su versión de RaptoreumCore es: $coreVersion" -ForegroundColor Green
            } else {
                Write-CurrentTime; Write-Host " raptoreum-qt.exe no encontrado..." -ForegroundColor Yellow
            }
        } else {
            Write-CurrentTime; Write-Host " Su versión de RaptoreumCore no se encontró, pero continúa..." -ForegroundColor Yellow
        }
    }
    if ($coreVersion -eq $null) {
        Write-CurrentTime; Write-Host " Su versión de RaptoreumCore no se encontró, pero continúa..." -ForegroundColor Yellow
    }
}

# Obtener el número de la última versión disponible de RaptoreumCore, desde github
$uri = "https://api.github.com/repos/Raptor3um/raptoreum/releases/latest"
$response = Invoke-RestMethod -Uri $uri
$latestVersion = $response.tag_name
Write-CurrentTime; Write-Host " Última versión disponible de RaptoreumCore: $latestVersion" -ForegroundColor Green
Write-CurrentTime; Write-Host " Enlace de descarga: https://github.com/Raptor3um/raptoreum/releases/tag/$latestVersion" -ForegroundColor Green

# Obtener el número de la última versión del bootstrap disponible, desde checksums
$checksumsUrl = "https://checksums.raptoreum.com/checksums/bootstrap-checksums.txt"
$checksums = Invoke-WebRequest -Uri $checksumsUrl -UseBasicParsing
$bootstrapVersion = [regex]::Matches($checksums, '\d+\.\d+\.\d+\.\d+').Value | Select-Object -Last 1
Write-CurrentTime; Write-Host " Última versión disponible del bootstrap   : $bootstrapVersion" -ForegroundColor Green
Write-CurrentTime; Write-Host " Enlace de descarga: https://bootstrap.raptoreum.com/bootstraps/bootstrap.zip" -ForegroundColor Green

# Preguntar si la billetera está actualizada correctamente a la versión requerida
if (-not ($coreVersion -eq $latestVersion)) {
    $answer = Read-Host " Su versión es diferente de la última disponible.`n ¿Ha actualizado RaptoreumCore a la versión $($latestVersion)? (s/n)"
    if ($answer.ToLower() -ne "s") {
        Write-CurrentTime; Write-Host " Actualice RaptoreumCore a la versión $latestVersion y vuelva a ejecutar el script." -ForegroundColor Red
        Write-CurrentTime; Write-Host " Enlace de descarga: https://github.com/Raptor3um/raptoreum/releases/tag/$latestVersion" -ForegroundColor Green
        pause
        exit
    }
}

# Preguntar si se está utilizando la ubicación de la billetera predeterminada
$customPath = Read-Host " ¿Está utilizando la carpeta de la billetera Raptoreum en la ubicación predeterminada? (Presione enter si no lo sabe) (s/n)"
if ($customPath.ToLower() -eq "n") {
    # Pedir un directorio personalizado, si no se encuentra raptoreum-qt.exe en la ubicación predeterminada
    $customDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $customDialog.Description = "Seleccione la ruta de su carpeta de billetera Raptoreum personalizada"
    $customDialog.ShowDialog() | Out-Null
    if ($customDialog.SelectedPath) {
        # Cambiar las variables de la ubicación predeterminada a la carpeta de billetera personalizada
        [string]$walletDirectory = $customDialog.SelectedPath
        [string]$bootstrapZipPath = "$($customDialog.SelectedPath)\bootstrap.zip"
        [string]$blocksDirectory = "$($customDialog.SelectedPath)\blocks"
        [string]$chainstateDirectory = "$($customDialog.SelectedPath)\chainstate"
        [string]$evodbDirectory = "$($customDialog.SelectedPath)\evodb"
        [string]$llmqDirectory = "$($customDialog.SelectedPath)\llmq"
        [string]$powcachePath = "$($customDialog.SelectedPath)\powcache.dat"
        Write-CurrentTime; Write-Host " Su carpeta de billetera personalizada es: '$($customDialog.SelectedPath)' ..." -ForegroundColor Green
        Write-CurrentTime; Write-Host " Utilizando este directorio para el archivo bootstrap.zip" -ForegroundColor Green
    } else {
        Write-CurrentTime; Write-Host " No se encontró la ubicación personalizada de la billetera, pero continúe con la ubicación predeterminada..." -ForegroundColor Yellow
    }
}

# Comprueba si el archivo bootstrap.zip existe localmente y, si es así, comprueba si hay una versión más nueva disponible
if (Test-Path $bootstrapZipPath) {
    Check-BootstrapZip -bootstrapZipPath $bootstrapZipPath -bootstrapUrl $bootstrapUrl
} else {
    Write-CurrentTime; Write-Host " No se ha detectado ningún archivo 'bootstrap.zip' local." -ForegroundColor Yellow
    Get-BootstrapSize
    $confirmDownload = Read-Host " ¿Desea descargar el archivo bootstrap.zip? (Presione enter si no sabe) (s/n)"
    if ($confirmDownload.ToLower() -eq "n") {
        Write-CurrentTime; Write-Host " No se descargará el archivo bootstrap.zip, pero se continuará..." -ForegroundColor Yellow
    } else {
        Download-FileWithProgress -Url $bootstrapUrl -FilePath $bootstrapZipPath
        Check-BootstrapZip -bootstrapZipPath $bootstrapZipPath -bootstrapUrl $bootstrapUrl
    }
}

# Comprueba si el proceso de la billetera está en ejecución y lo detiene si lo está
$walletProcess = Get-Process -Name $walletProcessName -ErrorAction SilentlyContinue
if ($walletProcess) {
    Write-CurrentTime; Write-Host " Deteniendo el proceso RaptoreumCore en ejecución..." -ForegroundColor Yellow
    Stop-Process $walletProcess.Id -Force
} else {
    Write-CurrentTime; Write-Host " No se ha detectado ningún proceso RaptoreumCore..." -ForegroundColor Green
}

# Comprueba si uno de los directorios existe, si no, omite la solicitud
$directoriesExist = (Test-Path $blocksDirectory) -or (Test-Path $chainstateDirectory) -or (Test-Path $evodbDirectory) -or (Test-Path $llmqDirectory)
if ($directoriesExist) {
    Write-CurrentTime; Write-Host " Se encontraron carpetas existentes..." -ForegroundColor Green
    # Elimina los directorios, si existen
    foreach ($directory in @($blocksDirectory, $chainstateDirectory, $evodbDirectory, $llmqDirectory)) {
        if (Test-Path $directory) {
            Write-CurrentTime; Write-Host " Eliminando carpeta $directory en progreso..." -ForegroundColor Green
            Remove-Item $directory -Recurse -Force -ErrorAction Stop
            Write-CurrentTime; Write-Host " La carpeta $directory ha sido eliminada..." -ForegroundColor Green
        }
    }
} else {
    Write-CurrentTime; Write-Host " No se encontraron carpetas para eliminar." -ForegroundColor Yellow
}

# Elimina el archivo powcache.dat existente, si existe
if (Test-Path $powcachePath) {
    Write-CurrentTime; Write-Host " Eliminando el archivo powcache.dat en progreso..." -ForegroundColor Green
    Remove-Item $powcachePath -Force -ErrorAction Stop
    Write-CurrentTime; Write-Host " El archivo powcache.dat ha sido eliminado..." -ForegroundColor Green
}

# Descarga (de nuevo) y extrae el bootstrap si es necesario. Detecta si 7-Zip está instalado para usarlo, es más rápido.
if (Test-Path $bootstrapZipPath) {
    Write-CurrentTime; Write-Host " Extrayendo bootstrap desde: $bootstrapZipPath..." -ForegroundColor Green
    Write-CurrentTime; Write-Host " Extrayendo bootstrap a    : $walletDirectory..." -ForegroundColor Green
    $zipProgram = $null
    if (Test-Path (Join-Path $env:ProgramFiles "7-zip\7z.exe")) {
        $zipProgram = (Join-Path $env:ProgramFiles "7-zip\7z.exe")
    }
    if (Test-Path (Join-Path ${Env:ProgramFiles(x86)} "7-Zip\7z.exe")) {
        $zipProgram = (Join-Path ${Env:ProgramFiles(x86)} "7-zip\7z.exe")
    }
    if ($zipProgram) {
        Write-CurrentTime; Write-Host " 7-Zip detectado, usando 7-Zip para extraer el bootstrap. Más rápido..." -ForegroundColor Green
        & "$zipProgram" x "$bootstrapZipPath" -o"$walletDirectory" -y
    } else {
        Write-CurrentTime; Write-Host " 7-Zip no detectado, usando 'Expand-Archive' para extraer el bootstrap. Más lento..." -ForegroundColor Green
        Expand-Archive -Path $bootstrapZipPath -DestinationPath $walletDirectory -Force -ErrorAction Stop
    }
} else {
    Write-CurrentTime; Write-Host " No se ha detectado ningún archivo 'bootstrap.zip' en el directorio de la billetera." -ForegroundColor Yellow
    Get-BootstrapSize
    $confirmDownload = Read-Host " ¿Desea descargar el archivo bootstrap.zip? (Presione enter si no sabe) (s/n)"
    if ($confirmDownload.ToLower() -eq "n") {
        Write-CurrentTime; Write-Host " No se descargará el archivo bootstrap.zip, pero se continuará..." -ForegroundColor Yellow
    } else {
        Write-CurrentTime; Write-Host " Descargando el archivo bootstrap.zip..." -ForegroundColor Green
        Download-FileWithProgress -Url $bootstrapUrl -FilePath $bootstrapZipPath
        Check-BootstrapZip -bootstrapZipPath $bootstrapZipPath -bootstrapUrl $bootstrapUrl
    }
}

# Mostrar un mensaje de finalización
Write-CurrentTime; Write-Host " ¡Operación completada con éxito!" -ForegroundColor Green
Write-CurrentTime; Write-Host " Fin del bootstrap, ahora puede volver a iniciar RaptoreumCore." -ForegroundColor Green

# Pausar para que la consola no se cierre automáticamente si se ejecuta el script directamente
pause

