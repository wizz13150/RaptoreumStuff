##################################################################
### Script Bootstrap Auto para la Ãºltima versiÃ³n, para Windows ###
##################################################################

# Permitir la ejecuciÃ³n del script - Para probar
#Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

Write-Warning "Iniciando el script para aplicar automÃ¡ticamente un Bootstrap de Raptoreum"

# DefiniciÃ³n de variables

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
# Cuadro de diÃ¡logo para seleccionar una carpeta mÃ¡s tarde
Add-Type -AssemblyName System.Windows.Forms

# FunciÃ³n para mostrar la fecha y la hora
function Write-CurrentTime {
    Write-Host ('[' + (Get-Date).ToString("HH:mm:ss") + ']') -NoNewline
}

# FunciÃ³n para comprobar el checksum del archivo bootstrap.zip descargado/usado
function Check-BootstrapZipChecksum {
    Write-CurrentTime; Write-Host " Comprobando el checksum del archivo 'bootstrap.zip'..." -ForegroundColor Green
    Write-CurrentTime; Write-Host " Fuente: https://checksums.raptoreum.com/checksums/bootstrap-checksums.txt" -ForegroundColor Green
    $checksumsUrl = "https://checksums.raptoreum.com/checksums/bootstrap-checksums.txt"
    $checksums = Invoke-WebRequest -Uri $checksumsUrl -UseBasicParsing
    $remoteChecksum = ($checksums.Content.Split("`n") | Select-String -Pattern "v$latestVersion/no-index/bootstrap.zip").ToString().Split(" ")[0].Trim()
    Write-CurrentTime; Write-Host " Checksum: $remoteChecksum" -ForegroundColor Green
    $localChecksum = (Get-FileHash -Path $bootstrapZipPath -Algorithm SHA256 | Select-Object -ExpandProperty Hash).ToLower()
    if ($localChecksum -eq $remoteChecksum) {
        Write-CurrentTime; Write-Host " VerificaciÃ³n del checksum exitosa. El bootstrap es autÃ©ntico." -ForegroundColor Green
        Write-CurrentTime; Write-Host " Checksum local    : $($localChecksum)" -ForegroundColor Green
        Write-CurrentTime; Write-Host " Checksum en lÃ­nea : $($remoteChecksum)" -ForegroundColor Green
    } else {
        Write-CurrentTime; Write-Host " VerificaciÃ³n del checksum fallida. El bootstrap puede haber sido modificado, considera eliminarlo. O el script puede estar desactualizado." -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Checksum local    : $($localChecksum)" -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Checksum en lÃ­nea : $($remoteChecksum)" -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Deteniendo el script..." -ForegroundColor Red
        pause
        exit
    }
}

# FunciÃ³n para obtener la versiÃ³n de raptoreum-qt.exe
function Get-FileVersion {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    $fileVersionInfo = Get-Item $FilePath -ErrorAction SilentlyContinue| Get-ItemProperty | Select-Object -ExpandProperty VersionInfo
    return $fileVersionInfo.ProductVersion
}

# FunciÃ³n para comparar el archivo bootstrap con la versiÃ³n en lÃ­nea. VerificaciÃ³n de suma de comprobaciÃ³n aquÃ­
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
        Write-CurrentTime; Write-Host " El archivo bootstrap.zip estÃ¡ actualizado." -ForegroundColor Green
        Write-CurrentTime; Write-Host " Bootstrap Local     : TamaÃ±o: $(("{0:N2}" -f ($localFile.Length / 1GB))) GB, Fecha: $($localFile.LastWriteTime)" -ForegroundColor Green
        Write-CurrentTime; Write-Host " Bootstrap en lÃ­nea  : TamaÃ±o: $(("{0:N2}" -f ($remoteSize / 1GB))) GB, Fecha: $($remoteLastModified)" -ForegroundColor Green
        # Verificar la suma de comprobaciÃ³n
        Check-BootstrapZipChecksum
    } 
    else {
        Write-CurrentTime; Write-Host " Su bootstrap no estÃ¡ actualizado o incompleto." -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Bootstrap Local     : TamaÃ±o: $(("{0:N2}" -f ($localFile.Length / 1GB))) GB, Fecha: $($localFile.LastWriteTime)" -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Bootstrap en lÃ­nea  : TamaÃ±o: $(("{0:N2}" -f ($remoteSize / 1GB))) GB, Fecha: $($remoteLastModified)" -ForegroundColor Yellow
        Get-BootstrapSize
        $confirmDownload = Read-Host " Â¿Desea descargar el archivo bootstrap.zip ? (Presione Enter si no lo sabe) (s/n)"
        if ($confirmDownload.ToLower() -eq "n") {
            Write-CurrentTime; Write-Host " No se descargarÃ¡ el archivo bootstrap.zip, pero se continuarÃ¡..." -ForegroundColor Yellow
        } 
        else {
            Download-FileWithProgress -Url $bootstrapUrl -FilePath $bootstrapZipPath
            # Verificar la suma de comprobaciÃ³n
            Check-BootstrapZipChecksum
        }
    }
}

# Función para descargar el bootstrap
function Descargar-ArchivoConProgreso {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    Write-CurrentTime; Write-Host " Descargando el bootstrap desde $Url" -ForegroundColor Green
    $clienteWeb = New-Object System.Net.WebClient
    $clienteWeb.DownloadFile($Url, $FilePath)
}

# FunciÃ³n para obtener el tamaÃ±o del bootstrap en lÃ­nea
function Get-BootstrapSize {
    $bootstrapUrl = "https://bootstrap.raptoreum.com/bootstraps/bootstrap.zip"
    $response = Invoke-WebRequest -Uri $bootstrapUrl -Method Head -UseBasicParsing
    $sizeInBytes = $response.Headers.'Content-Length'
    $sizeInGB = [math]::Round($sizeInBytes / 1GB, 2)
    Write-CurrentTime; Write-Host " TamaÃ±o del bootstrap en lÃ­nea: $sizeInBytes bytes ($sizeInGB GB)" -ForegroundColor Green
}

# Verificar la versiÃ³n actual y la Ãºltima disponible
# Verificar la versiÃ³n actual en el equipo, si la carpeta predeterminada
$corePath = "$env:ProgramFiles\RaptoreumCore\raptoreum-qt.exe"
if (Test-Path $corePath) {
    $coreVersion = Get-FileVersion $corePath
    Write-CurrentTime; Write-Host " Su versiÃ³n de RaptoreumCore es            : $coreVersion" -ForegroundColor Green
}
else {
    Write-CurrentTime; Write-Host " Su versiÃ³n de RaptoreumCore es            : No encontrada" -ForegroundColor Yellow
    # Preguntar si hay una ubicaciÃ³n personalizada o no
    $answer = Read-Host " Â¿Necesita seleccionar un directorio personalizado para el lanzador de RaptoreumCore? (s/n)"
    if ($answer.ToLower() -eq "s") {
        # Pedir un directorio personalizado, si no se encuentra raptoreum-qt.exe en la ubicaciÃ³n predeterminada
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
                Write-CurrentTime; Write-Host " Su versiÃ³n de RaptoreumCore es: $coreVersion" -ForegroundColor Green
            } else {
                Write-CurrentTime; Write-Host " raptoreum-qt.exe no encontrado..." -ForegroundColor Yellow
            }
        } else {
            Write-CurrentTime; Write-Host " Su versiÃ³n de RaptoreumCore no se encontrÃ³, pero continÃºa..." -ForegroundColor Yellow
        }
    }
    if ($coreVersion -eq $null) {
        Write-CurrentTime; Write-Host " Su versiÃ³n de RaptoreumCore no se encontrÃ³, pero continÃºa..." -ForegroundColor Yellow
    }
}

# Obtener el nÃºmero de la Ãºltima versiÃ³n disponible de RaptoreumCore, desde github
$uri = "https://api.github.com/repos/Raptor3um/raptoreum/releases/latest"
$response = Invoke-RestMethod -Uri $uri
$latestVersion = $response.tag_name
Write-CurrentTime; Write-Host " Ãšltima versiÃ³n disponible de RaptoreumCore: $latestVersion" -ForegroundColor Green
Write-CurrentTime; Write-Host " Enlace de descarga: https://github.com/Raptor3um/raptoreum/releases/tag/$latestVersion" -ForegroundColor Green

# Obtener el nÃºmero de la Ãºltima versiÃ³n del bootstrap disponible, desde checksums
$checksumsUrl = "https://checksums.raptoreum.com/checksums/bootstrap-checksums.txt"
$checksums = Invoke-WebRequest -Uri $checksumsUrl -UseBasicParsing
$bootstrapVersion = [regex]::Matches($checksums, '\d+\.\d+\.\d+\.\d+').Value | Select-Object -Last 1
Write-CurrentTime; Write-Host " Ãšltima versiÃ³n disponible del bootstrap   : $bootstrapVersion" -ForegroundColor Green
Write-CurrentTime; Write-Host " Enlace de descarga: https://bootstrap.raptoreum.com/bootstraps/bootstrap.zip" -ForegroundColor Green

# Preguntar si la billetera estÃ¡ actualizada correctamente a la versiÃ³n requerida
if (-not ($coreVersion -eq $latestVersion)) {
    $answer = Read-Host " Su versiÃ³n es diferente de la Ãºltima disponible.`n Â¿Ha actualizado RaptoreumCore a la versiÃ³n $($latestVersion)? (s/n)"
    if ($answer.ToLower() -ne "s") {
        Write-CurrentTime; Write-Host " Actualice RaptoreumCore a la versiÃ³n $latestVersion y vuelva a ejecutar el script." -ForegroundColor Red
        Write-CurrentTime; Write-Host " Enlace de descarga: https://github.com/Raptor3um/raptoreum/releases/tag/$latestVersion" -ForegroundColor Green
        pause
        exit
    }
}

# Preguntar si se estÃ¡ utilizando la ubicaciÃ³n de la billetera predeterminada
$customPath = Read-Host " Â¿EstÃ¡ utilizando la carpeta de la billetera Raptoreum en la ubicaciÃ³n predeterminada? (Presione enter si no lo sabe) (s/n)"
if ($customPath.ToLower() -eq "n") {
    # Pedir un directorio personalizado, si no se encuentra raptoreum-qt.exe en la ubicaciÃ³n predeterminada
    $customDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $customDialog.Description = "Seleccione la ruta de su carpeta de billetera Raptoreum personalizada"
    $customDialog.ShowDialog() | Out-Null
    if ($customDialog.SelectedPath) {
        # Cambiar las variables de la ubicaciÃ³n predeterminada a la carpeta de billetera personalizada
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
        Write-CurrentTime; Write-Host " No se encontrÃ³ la ubicaciÃ³n personalizada de la billetera, pero continÃºe con la ubicaciÃ³n predeterminada..." -ForegroundColor Yellow
    }
}

# Comprueba si el archivo bootstrap.zip existe localmente y, si es asÃ­, comprueba si hay una versiÃ³n mÃ¡s nueva disponible
if (Test-Path $bootstrapZipPath) {
    Check-BootstrapZip -bootstrapZipPath $bootstrapZipPath -bootstrapUrl $bootstrapUrl
} else {
    Write-CurrentTime; Write-Host " No se ha detectado ningÃºn archivo 'bootstrap.zip' local." -ForegroundColor Yellow
    Get-BootstrapSize
    $confirmDownload = Read-Host " Â¿Desea descargar el archivo bootstrap.zip? (Presione enter si no sabe) (s/n)"
    if ($confirmDownload.ToLower() -eq "n") {
        Write-CurrentTime; Write-Host " No se descargarÃ¡ el archivo bootstrap.zip, pero se continuarÃ¡..." -ForegroundColor Yellow
    } else {
        Download-FileWithProgress -Url $bootstrapUrl -FilePath $bootstrapZipPath
        Check-BootstrapZip -bootstrapZipPath $bootstrapZipPath -bootstrapUrl $bootstrapUrl
    }
}

# Comprueba si el proceso de la billetera estÃ¡ en ejecuciÃ³n y lo detiene si lo estÃ¡
$walletProcess = Get-Process -Name $walletProcessName -ErrorAction SilentlyContinue
if ($walletProcess) {
    Write-CurrentTime; Write-Host " Deteniendo el proceso RaptoreumCore en ejecuciÃ³n..." -ForegroundColor Yellow
    Stop-Process $walletProcess.Id -Force
} else {
    Write-CurrentTime; Write-Host " No se ha detectado ningÃºn proceso RaptoreumCore..." -ForegroundColor Green
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

# Descarga (de nuevo) y extrae el bootstrap si es necesario. Detecta si 7-Zip estÃ¡ instalado para usarlo, es mÃ¡s rÃ¡pido.
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
        Write-CurrentTime; Write-Host " 7-Zip detectado, usando 7-Zip para extraer el bootstrap. MÃ¡s rÃ¡pido..." -ForegroundColor Green
        & "$zipProgram" x "$bootstrapZipPath" -o"$walletDirectory" -y
    } else {
        Write-CurrentTime; Write-Host " 7-Zip no detectado, usando 'Expand-Archive' para extraer el bootstrap. MÃ¡s lento..." -ForegroundColor Green
        Expand-Archive -Path $bootstrapZipPath -DestinationPath $walletDirectory -Force -ErrorAction Stop
    }
} else {
    Write-CurrentTime; Write-Host " No se ha detectado ningÃºn archivo 'bootstrap.zip' en el directorio de la billetera." -ForegroundColor Yellow
    Get-BootstrapSize
    $confirmDownload = Read-Host " Â¿Desea descargar el archivo bootstrap.zip? (Presione enter si no sabe) (s/n)"
    if ($confirmDownload.ToLower() -eq "n") {
        Write-CurrentTime; Write-Host " No se descargarÃ¡ el archivo bootstrap.zip, pero se continuarÃ¡..." -ForegroundColor Yellow
    } else {
        Download-FileWithProgress -Url $bootstrapUrl -FilePath $bootstrapZipPath
        Check-BootstrapZip -bootstrapZipPath $bootstrapZipPath -bootstrapUrl $bootstrapUrl
    }
}

# Mostrar un mensaje de finalizaciÃ³n
Write-CurrentTime; Write-Host " Â¡OperaciÃ³n completada con Ã©xito!" -ForegroundColor Green
Write-CurrentTime; Write-Host " Fin del bootstrap, ahora puede volver a iniciar RaptoreumCore." -ForegroundColor Green

# Pausar para que la consola no se cierre automÃ¡ticamente si se ejecuta el script directamente
pause
