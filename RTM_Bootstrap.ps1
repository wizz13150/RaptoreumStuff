############################################################
### Script Bootstrap Auto to latest version, for windows ###
############################################################

# Allow to run the script - To Test
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

Write-Warning "Starting the script to automatically apply a Raptoreum bootstrap"

# Definition of variables

# Path to the wallet folder to which the bootstrap should be applied. "$env:APPDATA\raptoreumcore" by default.
$walletDirectory = "$env:APPDATA\raptoreumcore"
# Path to the bootstrap.zip file
$bootstrapZipPath = "$env:APPDATA\raptoreumcore\bootstrap.zip"

# Other fixed variables
$walletProcessName = "raptoreum*"
$backupDirectory = "$walletDirectory\BootstrapBackup"
$dateSuffix = Get-Date -Format "ddMMyyyy"
$bootstrapUrl = "https://bootstrap.raptoreum.com/bootstraps/bootstrap.zip"
$blocksDirectory = "$walletDirectory\blocks"
$chainstateDirectory = "$walletDirectory\chainstate"
$evodbDirectory = "$walletDirectory\evodb"
$llmqDirectory = "$walletDirectory\llmq"
$powcachePath = "$walletDirectory\powcache.dat"

# Function to display date and time
function Write-CurrentTime {
    Write-Host ('[' + (Get-Date).ToString("HH:mm:ss") + ']') -NoNewline
}

function Check-BootstrapZipChecksum {
    Write-CurrentTime; Write-Host " Checking checksum of the 'bootstrap.zip' file..." -ForegroundColor Green
    Write-CurrentTime; Write-Host " Source: https://checksums.raptoreum.com/checksums/bootstrap-checksums.txt" -ForegroundColor Green
    #$checksumsUrl = "https://checksums.raptoreum.com/checksums/bootstrap-checksums.txt"
    #$checksums = Invoke-WebRequest -Uri $checksumsUrl -UseBasicParsing
    $remoteChecksum = ($checksums.Content.Split("`n") | Select-String -Pattern "v$latestVersion/no-index/bootstrap.zip").ToString().Split(" ")[0].Trim()
    Write-CurrentTime; Write-Host " Checksum: $remoteChecksum" -ForegroundColor Green
    $localChecksum = (Get-FileHash -Path $bootstrapZipPath -Algorithm SHA256 | Select-Object -ExpandProperty Hash).ToLower()
    if ($localChecksum -eq $remoteChecksum) {
        Write-CurrentTime; Write-Host " Checksum verification successful. The bootstrap is authentic." -ForegroundColor Green
        Write-CurrentTime; Write-Host " Local Checksum  : $($localChecksum)" -ForegroundColor Green
        Write-CurrentTime; Write-Host " Online Checksum : $($remoteChecksum)" -ForegroundColor Green
    } else {
        Write-CurrentTime; Write-Host " Checksum verification failed. The bootstrap may have been modified, consider to delete it. Or the script may be outdated." -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Local Checksum  : $($localChecksum)" -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Online Checksum : $($remoteChecksum)" -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Stopping the script..." -ForegroundColor Red
        pause
        exit
    }
}

function Get-FileVersion {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )

    $fileVersionInfo = Get-Item $FilePath | Get-ItemProperty | Select-Object -ExpandProperty VersionInfo
    return $fileVersionInfo.ProductVersion
}

# Checking the current and the latest versions available
# Check current version on the computer, if default folder
$corePath = "$env:ProgramFiles\RaptoreumCore\raptoreum-qt.exe"
if (Test-Path $corePath) {
    $coreVersion = Get-FileVersion $corePath
    Write-CurrentTime; Write-Host " Your RaptoreumCore version is        : $coreVersion" -ForegroundColor Green
}
else {
    Write-CurrentTime; Write-Host " Your RaptoreumCore version is        : Not found" -ForegroundColor Yellow
}

# Get latest version number of RaptoreumCore available, from github
$uri = "https://api.github.com/repos/Raptor3um/raptoreum/releases/latest"
$response = Invoke-RestMethod -Uri $uri
$latestVersion = $response.tag_name
Write-CurrentTime; Write-Host " Last RaptoreumCore version available : $latestVersion" -ForegroundColor Green
Write-CurrentTime; Write-Host " Download link: https://github.com/Raptor3um/raptoreum/releases/tag/$latestVersion" -ForegroundColor Green

# Get latest version number of the bootstrap available, from checksums
$checksumsUrl = "https://checksums.raptoreum.com/checksums/bootstrap-checksums.txt"
$checksums = Invoke-WebRequest -Uri $checksumsUrl -UseBasicParsing
$bootstrapVersion = [regex]::Matches($checksums, '\d+\.\d+\.\d+\.\d+').Value | Select-Object -Last 1
Write-CurrentTime; Write-Host " Last Bootstrap version available     : $bootstrapVersion" -ForegroundColor Green
Write-CurrentTime; Write-Host " Download link: https://bootstrap.raptoreum.com/bootstraps/bootstrap.zip" -ForegroundColor Green

# Ask is the wallet is correctly updated to the required version
if (-not ($coreVersion -eq $latestVersion)) {
    $answer = Read-Host "Have you updated RaptoreumCore to version $latestVersion? (y/n)"
    if ($answer.ToLower() -ne "y") {
        Write-CurrentTime; Write-Host " Please update RaptoreumCore to version $latestVersion and run the script again." -ForegroundColor Red
        Write-CurrentTime; Write-Host " Download link: https://github.com/Raptor3um/raptoreum/releases/tag/$latestVersion" -ForegroundColor Green
        pause
        exit
    }
}

# Check if the bootstrap.zip file exists locally and if yes, check if a newer version is available
if (Test-Path $bootstrapZipPath) {
    $localFile = Get-Item $bootstrapZipPath
    $remoteFile = Invoke-WebRequest -Uri $bootstrapUrl -Method Head
    $remoteLastModified = [datetime]::ParseExact($remoteFile.Headers.'Last-Modified', 'ddd, dd MMM yyyy HH:mm:ss \G\M\T', [System.Globalization.CultureInfo]::InvariantCulture)
    $remoteSize = $remoteFile.Headers.'Content-Length'

    if ($localFile.LastWriteTime -ge $remoteLastModified -and $localFile.Length -eq $remoteSize) {
        Write-CurrentTime; Write-Host " The bootstrap.zip file is up to date." -ForegroundColor Green
        Write-CurrentTime; Write-Host " Local Bootstrap    : Size: $(("{0:N2}" -f ($localFile.Length / 1GB))) GB, Date: $($localFile.LastWriteTime)" -ForegroundColor Green
        Write-CurrentTime; Write-Host " Online Bootstrap   : Size: $(("{0:N2}" -f ($remoteSize / 1GB))) GB, Date: $($remoteLastModified)" -ForegroundColor Green
        # Check checksum
        Check-BootstrapZipChecksum
    } else {
        Write-CurrentTime; Write-Host " Your bootstrap is not up to date or incomplete." -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Local Bootstrap    : Size: $(("{0:N2}" -f ($localFile.Length / 1GB))) GB, Date: $($localFile.LastWriteTime)" -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Online Bootstrap   : Size: $(("{0:N2}" -f ($remoteSize / 1GB))) GB, Date: $($remoteLastModified)" -ForegroundColor Yellow
        $confirmDownload = Read-Host " Do you want to download the bootstrap.zip file? (y/n)"
        if ($confirmDownload -eq "y") {
            Write-CurrentTime; Write-Host " Downloading bootstrap.zip file..." -ForegroundColor Green
            Invoke-WebRequest -Uri $bootstrapUrl -OutFile $bootstrapZipPath -ErrorAction Stop
        } else {
            Write-CurrentTime; Write-Host " Not downloading the bootstrap.zip file, but continuing..." -ForegroundColor Yellow
        }
    }
} else {
    Write-CurrentTime; Write-Host " No local 'bootstrap.zip' file detected." -ForegroundColor Yellow
    $confirmDownload = Read-Host " Do you want to download the bootstrap.zip file? (y/n)"
    if ($confirmDownload -eq "y") {
        Write-CurrentTime; Write-Host " Downloading bootstrap.zip file..." -ForegroundColor Green
        Invoke-WebRequest -Uri $bootstrapUrl -OutFile $bootstrapZipPath -ErrorAction Stop
        # Check checksum
        Check-BootstrapZipChecksum
    } else {
        Write-CurrentTime; Write-Host " Not downloading the bootstrap.zip file, but continuing..." -ForegroundColor Yellow
    }
}

# Check if the wallet process is running and kill it if it is
$walletProcess = Get-Process -Name $walletProcessName -ErrorAction SilentlyContinue
if ($walletProcess) {
    Write-CurrentTime; Write-Host " Stopping the running RaptoreumCore process..." -ForegroundColor Yellow
    Stop-Process $walletProcess.Id -Force
} else {
    Write-CurrentTime; Write-Host " No RaptoreumCore process detected..." -ForegroundColor Green
}

# Check if one of the directories exist, if not, skip the prompt
$directoriesExist = (Test-Path $blocksDirectory) -or (Test-Path $chainstateDirectory) -or (Test-Path $evodbDirectory) -or (Test-Path $llmqDirectory)

if ($directoriesExist) {
    # Prompt the user whether to archive or delete the directories and powcache.dat file
    $archiveAction = Read-Host -Prompt "`nDo you want to archive(a) or delete(d) the directories and powcache.dat file? (a/d)"
    if ($archiveAction -eq "a") {
        $backupAction = "Archiving"
        $removeAction = "archived"
    } else {
        $backupAction = "Deleting"
        $removeAction = "deleted"
    }
} else {
    Write-CurrentTime; Write-Host " No directories found to delete." -ForegroundColor Yellow
    $archiveAction = ""
    $backupAction = ""
    $removeAction = ""
}

# Create the backup directory if it doesn't exist
if (-not (Test-Path $backupDirectory)) {
    Write-CurrentTime; Write-Host " Creating backup directory: $backupDirectory" -ForegroundColor Green
    New-Item -ItemType Directory -Path $backupDirectory | Out-Null
}

# Archive or delete the directories and powcache.dat file based on the user's choice
foreach ($directory in @($blocksDirectory, $chainstateDirectory, $evodbDirectory, $llmqDirectory)) {
    if (Test-Path $directory) {
        $backupPath = Join-Path $backupDirectory "$(Split-Path $directory -Leaf)_$dateSuffix"
        Write-CurrentTime; Write-Host " $backupAction of directory $directory in progress..." -ForegroundColor Green
        if ($archiveAction -eq "a") {
            Move-Item $directory $backupPath -Force -ErrorAction Continue
        }
        #Remove-Item $directory -Recurse -Force -ErrorAction Stop
        Write-CurrentTime; Write-Host " The $directory directory has been $removeAction." -ForegroundColor Green
    }
}

if (Test-Path $powcachePath) {
    $backupPath = Join-Path $backupDirectory "powcache_$dateSuffix.dat"
    Write-CurrentTime; Write-Host " Deleting the powcache.dat file in progress..." -ForegroundColor Green
    if ($archiveAction -eq "a") {
        Copy-Item $powcachePath $backupPath -Force -ErrorAction Continue
    }
    Remove-Item $powcachePath -Force -ErrorAction Continue
    Write-CurrentTime; Write-Host " The powcache.dat file has been $removeAction." -ForegroundColor Green
}

# Download (again) and extract the bootstrap if necessary. Test if 7-Zip is installed to use it.
if (Test-Path $bootstrapZipPath) {
    Write-CurrentTime; Write-Host " Extracting bootstrap from $bootstrapZipPath..." -ForegroundColor Green
    $zipProgram = $null
    if (Test-Path (Join-Path $env:ProgramFiles "7-zip\7z.exe")) {
        $zipProgram = (Join-Path $env:ProgramFiles "7-zip\7z.exe")
    }
    if (Test-Path (Join-Path ${Env:ProgramFiles(x86)} "7-Zip\7z.exe")) {
        $zipProgram = (Join-Path ${Env:ProgramFiles(x86)} "7-zip\7z.exe")
    }
    if ($zipProgram) {
        Write-CurrentTime; Write-Host " 7-Zip detected, using 7-Zip to extract the bootstrap. Faster..." -ForegroundColor Green
        & "$zipProgram" x "$bootstrapZipPath" -o"$walletDirectory" -y
    } else {
        Write-CurrentTime; Write-Host " 7-Zip not detected, using 'Expand-Archive' to extract the bootstrap. Slower..." -ForegroundColor Green
        Expand-Archive -Path $bootstrapZipPath -DestinationPath $walletDirectory -Force -ErrorAction Stop
    }
} else {
    Write-CurrentTime; Write-Host " No 'bootstrap.zip' file detected in the wallet directory." -ForegroundColor Yellow
    $confirmDownload = Read-Host " Do you want to download the bootstrap.zip file? (y/n)"
    if ($confirmDownload -eq "y") {
        Write-CurrentTime; Write-Host " Downloading bootstrap.zip file..." -ForegroundColor Green
        Invoke-WebRequest -Uri $bootstrapUrl -OutFile $bootstrapZipPath -ErrorAction Stop
    } else {
        Write-CurrentTime; Write-Host " Canceling download of bootstrap.zip file." -ForegroundColor Yellow
    }
}

# Display a completion message
Write-CurrentTime; Write-Host " Operation completed successfully!" -ForegroundColor Green
Write-CurrentTime; Write-Host " End of Bootstrap, you can now relaunch RaptoreumCore." -ForegroundColor Green

# Pause so the console does not close automatically if the script is executed directly
pause
