##############################################################################
### Script d'installation automatique du bootstrap Raptoreum, pour Windows ###
##############################################################################

Write-Warning "Démarrage du script d'installation automatique du bootstrap Raptoreum"

# Définition des variables

# Chemin du dossier du portefeuille auquel le bootstrap doit être appliqué. "$env:APPDATA\raptoreumcore" par défaut.
$walletDirectory = "$env:APPDATA\raptoreumcore"
# Chemin du fichier bootstrap.zip
$bootstrapZipPath = "$env:APPDATA\raptoreumcore\bootstrap.zip"

# Autres variables fixes
$walletProcessName = "raptoreum*"
$dateSuffix = Get-Date -Format "ddMMyyyy"
$bootstrapUrl = "https://bootstrap.raptoreum.com/bootstraps/bootstrap.zip"
$blocksDirectory = "$walletDirectory\blocks"
$chainstateDirectory = "$walletDirectory\chainstate"
$evodbDirectory = "$walletDirectory\evodb"
$llmqDirectory = "$walletDirectory\llmq"
$powcachePath = "$walletDirectory\powcache.dat"
# Boîte de dialogue pour sélectionner un dossier ultérieurement
Add-Type -AssemblyName System.Windows.Forms

# Fonction pour afficher la date et l'heure
function Write-CurrentTime {
    Write-Host ('[' + (Get-Date).ToString("HH:mm:ss") + ']') -NoNewline
}

# Fonction pour vérifier le checksum du fichier bootstrap.zip téléchargé/utilisé
function Check-BootstrapZipChecksum {
    Write-CurrentTime; Write-Host " Vérification du checksum du fichier 'bootstrap.zip'..." -ForegroundColor Green
    Write-CurrentTime; Write-Host " Source: https://checksums.raptoreum.com/checksums/bootstrap-checksums.txt" -ForegroundColor Green
    $checksumsUrl = "https://checksums.raptoreum.com/checksums/bootstrap-checksums.txt"
    $checksums = Invoke-WebRequest -Uri $checksumsUrl -UseBasicParsing
    $remoteChecksum = ($checksums.Content.Split("`n") | Select-String -Pattern "v$latestVersion/no-index/bootstrap.zip").ToString().Split(" ")[0].Trim()
    Write-CurrentTime; Write-Host " Checksum: $remoteChecksum" -ForegroundColor Green
    $localChecksum = (Get-FileHash -Path $bootstrapZipPath -Algorithm SHA256 | Select-Object -ExpandProperty Hash).ToLower()
    if ($localChecksum -eq $remoteChecksum) {
        Write-CurrentTime; Write-Host " Vérification du Checksum réussie. Le bootstrap est authentique." -ForegroundColor Green
        Write-CurrentTime; Write-Host " Checksum local    : $($localChecksum)" -ForegroundColor Green
        Write-CurrentTime; Write-Host " Checksum en ligne : $($remoteChecksum)" -ForegroundColor Green
    } else {
        Write-CurrentTime; Write-Host " Vérification du Checksum échouée. Le bootstrap peut avoir été modifié, envisagez de le supprimer. Ou le script peut être obsolète." -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Checksum local    : $($localChecksum)" -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Checksum en ligne : $($remoteChecksum)" -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Arrêt du script..." -ForegroundColor Red
        pause
        exit
    }
}

# Fonction pour obtenir la version de raptoreum-qt.exe
function Get-FileVersion {
    param (
        [string]$FilePath
    )
    $fileVersionInfo = Get-Item $FilePath -ErrorAction SilentlyContinue | Get-ItemProperty | Select-Object -ExpandProperty VersionInfo
    return $fileVersionInfo.ProductVersion
}

# Fonction pour comparer le bootstrap utilisé à la version en ligne. Vérification du checksum ici
function Check-BootstrapZip {
    param(
        [string]$bootstrapZipPath,
        [string]$bootstrapUrl
    )
    $localFile = Get-Item $bootstrapZipPath -ErrorAction SilentlyContinue
    $remoteFile = Invoke-WebRequest -Uri $bootstrapUrl -Method Head -UseBasicParsing
    $remoteLastModified = [datetime]::ParseExact($remoteFile.Headers.'Last-Modified', 'ddd, dd MMM yyyy HH:mm:ss \G\M\T', [System.Globalization.CultureInfo]::InvariantCulture)
    $remoteSize = $remoteFile.Headers.'Content-Length'
    if ($localFile.LastWriteTime -ge $remoteLastModified -and $localFile.Length -eq $remoteSize) {
        Write-CurrentTime; Write-Host " Le fichier bootstrap.zip est à jour." -ForegroundColor Green
        Write-CurrentTime; Write-Host " Bootstrap local    : Taille: $(("{0:N2}" -f ($localFile.Length / 1GB))) Go, Date: $($localFile.LastWriteTime)" -ForegroundColor Green
        Write-CurrentTime; Write-Host " Bootstrap en ligne : Taille: $(("{0:N2}" -f ($remoteSize / 1GB))) Go, Date: $($remoteLastModified)" -ForegroundColor Green
        # Vérifier la somme de contrôle
        Check-BootstrapZipChecksum
    } 
    else {
        Write-CurrentTime; Write-Host " Votre bootstrap n'est pas à jour ou est incomplet." -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Bootstrap local    : Taille: $(("{0:N2}" -f ($localFile.Length / 1GB))) Go, Date: $($localFile.LastWriteTime)" -ForegroundColor Yellow
        Write-CurrentTime; Write-Host " Bootstrap en ligne : Taille: $(("{0:N2}" -f ($remoteSize / 1GB))) Go, Date: $($remoteLastModified)" -ForegroundColor Yellow
        Get-BootstrapSize
        $confirmDownload = Read-Host " Voulez-vous télécharger le fichier bootstrap.zip ?`n (Appuyez sur Entrée si vous ne savez pas) (o/n)"
        if ($confirmDownload.ToLower() -eq "n") {
            Write-CurrentTime; Write-Host " On ne télécharge pas le fichier bootstrap.zip, mais on continue..." -ForegroundColor Yellow
        } 
        else {
            Download-FileWithProgress -Url $bootstrapUrl -FilePath $bootstrapZipPath
            # Vérifier la somme de contrôle
            Check-BootstrapZipChecksum
        }
    }
}

# Fonction pour télécharger le fichier avec suivi de progression
function Download-FileWithProgress {
    param(
        [string]$Url,
        [string]$FilePath
    )    
    Write-CurrentTime; Write-Host " Téléchargement du fichier à partir de $Url" -ForegroundColor Green    
    # Vérifier si le répertoire de destination existe
    if (!(Test-Path $walletDirectory)) {
        Write-CurrentTime; Write-Host " Le répertoire $walletDirectory n'existe pas..." -ForegroundColor Red
        Write-CurrentTime; Write-Host " Veuillez redémarrer le script et sélectionner un emplacement correct pour le portefeuille..." -ForegroundColor Green
        pause
        exit
    }
    try {
        # Créer un travail de transfert BITS
        Start-BitsTransfer -Source $Url -Destination $FilePath -DisplayName "Téléchargement du fichier à partir de $Url"        
    }
    catch {
        Write-CurrentTime; Write-Host " Une erreur s'est produite lors du téléchargement du fichier : $_. Veuillez réessayer ultérieurement." -ForegroundColor Red
        pause
        exit
    }
    Write-CurrentTime; Write-Host " Le fichier a été téléchargé vers $FilePath" -ForegroundColor Green
}

# Fonction pour obtenir la taille du bootstrap en ligne
function Get-BootstrapSize {
    $bootstrapUrl = "https://bootstrap.raptoreum.com/bootstraps/bootstrap.zip"
    $response = Invoke-WebRequest -Uri $bootstrapUrl -Method Head -UseBasicParsing
    $sizeInBytes = $response.Headers.'Content-Length'
    $sizeInGB = [math]::Round($sizeInBytes / 1GB, 2)
    Write-CurrentTime; Write-Host " Taille du bootstrap en ligne : $sizeInBytes octets ($sizeInGB Go)" -ForegroundColor Green
}

# Vérification des versions actuelle et disponible

# Obtenir le numéro de la version la plus récente de RaptoreumCore disponible, depuis github
$uri = "https://api.github.com/repos/Raptor3um/raptoreum/releases/latest"
$response = Invoke-RestMethod -Uri $uri
$latestVersion = $response.tag_name
Write-CurrentTime; Write-Host " Dernière version de RaptoreumCore disponible : $latestVersion" -ForegroundColor Green
Write-CurrentTime; Write-Host " Lien de téléchargement : https://github.com/Raptor3um/raptoreum/releases/tag/$latestVersion" -ForegroundColor Green

# Vérifie la version actuelle sur l'ordinateur, si dans le dossier par défaut
$corePath = "$env:ProgramFiles\RaptoreumCore\raptoreum-qt.exe"
$core = "$env:ProgramFiles\RaptoreumCore"
if (Test-Path $corePath) {
    $coreVersion = Get-FileVersion $corePath
    if ($coreVersion -ne $latestVersion) {
        Write-CurrentTime; Write-Host " Votre version de RaptoreumCore est           : $coreVersion" -ForegroundColor Yellow
    }
    else {
        Write-CurrentTime; Write-Host " Votre version de RaptoreumCore est           : $coreVersion" -ForegroundColor Green
    }
}
else {
    Write-CurrentTime; Write-Host " Votre version de RaptoreumCore est           : Non trouvée" -ForegroundColor Yellow
    # Demander s'il y a un emplacement personnalisé ou non
    $answer = Read-Host " Avez-vous besoin de sélectionner un répertoire personnalisé pour votre lanceur RaptoreumCore ? (o/n)"
    if ($answer.ToLower() -eq "o") {
        # Demander un répertoire personnalisé, si raptoreum-qt.exe n'est pas trouvé dans l'emplacement par défaut
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Sélectionner le répertoire personnalisé pour le lanceur RaptoreumCore"
        $dialog.ShowDialog() | Out-Null
        if ($dialog.SelectedPath) {
            $corePath = $dialog.SelectedPath + "\raptoreum-qt.exe"
            $core = $dialog.SelectedPath
            $coreVersion = Get-FileVersion $corePath
            # Vérifier si le dossier sélectionné contient raptoreum-qt.exe
            if (Test-Path "$corePath") {
                Write-CurrentTime; Write-Host " raptoreum-qt.exe trouvé..." -ForegroundColor Green
                Write-CurrentTime; Write-Host " Le dossier de raptoreum-qt.exe est : " $dialog.SelectedPath ... -ForegroundColor Green
                Write-CurrentTime; Write-Host " Votre version de RaptoreumCore est           : $coreVersion" -ForegroundColor Green
            } else {
                Write-CurrentTime; Write-Host " raptoreum-qt.exe n'a pas été trouvé..." -ForegroundColor Yellow
            }
        } else {
            Write-CurrentTime; Write-Host " Votre version de RaptoreumCore n'a pas été trouvée, mais on continue..." -ForegroundColor Yellow
        }
    }
    if ($coreVersion -eq $null) {
        Write-CurrentTime; Write-Host " Votre version de RaptoreumCore n'a pas été trouvée, mais on continue..." -ForegroundColor Yellow
    }
}

# Obtenir le numéro de la version la plus récente du bootstrap disponible, depuis la page des checksums
$checksumsUrl = "https://checksums.raptoreum.com/checksums/bootstrap-checksums.txt"
$checksums = Invoke-WebRequest -Uri $checksumsUrl -UseBasicParsing
$bootstrapVersion = [regex]::Matches($checksums, '\d+\.\d+\.\d+\.\d+').Value | Select-Object -Last 1
Write-CurrentTime; Write-Host " Dernière version de Bootstrap disponible     : $bootstrapVersion" -ForegroundColor Green
Write-CurrentTime; Write-Host " Lien de téléchargement : https://bootstrap.raptoreum.com/bootstraps/bootstrap.zip" -ForegroundColor Green

# Demande si l'emplacement par défaut du portefeuille est utilisé
$customPath = Read-Host " Votre portefeuille RaptoreumCore utilise-t-il l'emplacement par défaut ?`n (Appuyez sur Entrée si vous ne savez pas) (o/n)"
if ($customPath.ToLower() -eq "n") {
    # Demande un répertoire personnalisé, si raptoreum-qt.exe n'est pas trouvé dans l'emplacement par défaut
    $customDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $customDialog.Description = "Sélectionnez le chemin de votre dossier de portefeuille RaptoreumCore personnalisé"
    $customDialog.ShowDialog() | Out-Null
    if ($customDialog.SelectedPath) {
        # Change les variables de l'emplacement par défaut au répertoire de portefeuille personnalisé
        [string]$walletDirectory = $customDialog.SelectedPath
        [string]$bootstrapZipPath = "$($customDialog.SelectedPath)\bootstrap.zip"
        [string]$blocksDirectory = "$($customDialog.SelectedPath)\blocks"
        [string]$chainstateDirectory = "$($customDialog.SelectedPath)\chainstate"
        [string]$evodbDirectory = "$($customDialog.SelectedPath)\evodb"
        [string]$llmqDirectory = "$($customDialog.SelectedPath)\llmq"
        [string]$powcachePath = "$($customDialog.SelectedPath)\powcache.dat"
        Write-CurrentTime; Write-Host " Votre dossier de portefeuille personnalisé est : '$($customDialog.SelectedPath)' ..." -ForegroundColor Green
        Write-CurrentTime; Write-Host " Utilisation de ce répertoire pour le fichier bootstrap.zip..." -ForegroundColor Green
    } else {
        Write-CurrentTime; Write-Host " Emplacement personnalisé du portefeuille non trouvé, on poursuite avec l'emplacement par défaut..." -ForegroundColor Yellow
    }
}

# Demander si le portefeuille est correctement mis à jour vers la version requise
if (-not ($coreVersion -eq $latestVersion)) {
    $answer = Read-Host " Votre version diffère de la dernière version disponible.`n Voulez-vous mettre à jour RaptoreumCore vers la version $($latestVersion) ? (o/n)"
    if ($answer.ToLower() -eq "o") {
        $downloadUrl = "https://github.com/Raptor3um/raptoreum/releases/download/$latestVersion/raptoreum-win-$latestVersion.zip"
        Write-CurrentTime; Write-Host " Téléchargement de la version $latestVersion de RaptoreumCore..." -ForegroundColor Green            
        # Télécharger le fichier ZIP
        $downloadZipPath = "$walletDirectory\raptoreum-win-$latestVersion.zip"
        Download-FileWithProgress -Url $downloadUrl -FilePath $downloadZipPath
        # Décompresser le fichier ZIP
        Write-CurrentTime; Write-Host " Décompresion de l'archive vers $corePath..."
        try {
            Expand-Archive -Path $downloadZipPath -DestinationPath $core -Force -ErrorAction Stop
            # Supprimer le fichier ZIP après la décompression
            #Write-CurrentTime; Write-Host " Suppression de l'archive téléchargée..."
            #Remove-Item $zipFilePath
            Write-CurrentTime; Write-Host " RaptoreumCore $latestVersion a été installé..." -ForegroundColor Green
        }
        catch {
            Write-CurrentTime; Write-Host " Le script n'a pas les droits nécessaires pour accéder au dossier $core..." -ForegroundColor Red
            Write-CurrentTime; Write-Host " Veuillez relancer le script en mode administrateur..." -ForegroundColor Green
            pause
            exit
        }
    }
    else {
        # Vérifie une dernière fois la version, invite à mettre à jour avec un lien
        if (-not ($coreVersion -eq $latestVersion)) {
            Write-CurrentTime; Write-Host " La version semble être incorrecte, on continue mais vous risquez de rencontrer une erreur au lancement." -ForegroundColor Yellow
            Write-CurrentTime; Write-Host " Lien de téléchargement : https://github.com/Raptor3um/raptoreum/releases/tag/$latestVersion" -ForegroundColor Green
        }
    }
}

# Vérifier si le fichier bootstrap.zip existe localement et, s'il existe, vérifier s'il existe une version plus récente disponible
if (Test-Path $bootstrapZipPath) {
    Check-BootstrapZip -bootstrapZipPath $bootstrapZipPath -bootstrapUrl $bootstrapUrl
} else {
    Write-CurrentTime; Write-Host " Aucun fichier 'bootstrap.zip' local détecté." -ForegroundColor Yellow
    Get-BootstrapSize
    $confirmDownload = Read-Host " Voulez-vous télécharger le fichier bootstrap.zip ?`n (Appuyez sur Entrée si vous ne savez pas) (o/n)"
    if ($confirmDownload.ToLower() -eq "n") {
        Write-CurrentTime; Write-Host " On ne télécharge pas le fichier bootstrap.zip, mais on continue..." -ForegroundColor Yellow
    } else {
        Download-FileWithProgress -Url $bootstrapUrl -FilePath $bootstrapZipPath
        Check-BootstrapZip -bootstrapZipPath $bootstrapZipPath -bootstrapUrl $bootstrapUrl
    }
}

# Vérifier si le processus RaptoreumCore est en cours d'exécution et le tuer s'il l'est
$walletProcess = Get-Process -Name $walletProcessName -ErrorAction SilentlyContinue
if ($walletProcess) {
    Write-CurrentTime; Write-Host " Arrêt du processus RaptoreumCore en cours..." -ForegroundColor Yellow
    Stop-Process $walletProcess.Id -Force
} else {
    Write-CurrentTime; Write-Host " Aucun processus RaptoreumCore détecté..." -ForegroundColor Green
}

# Vérifier si l'un des répertoires existe, sinon, passer l'invite
$directoriesExist = (Test-Path $blocksDirectory) -or (Test-Path $chainstateDirectory) -or (Test-Path $evodbDirectory) -or (Test-Path $llmqDirectory)
if ($directoriesExist) {
    Write-CurrentTime; Write-Host " Dossiers existants trouvés..." -ForegroundColor Green
    # Supprimer les dossiers, s'ils existent
    foreach ($directory in @($blocksDirectory, $chainstateDirectory, $evodbDirectory, $llmqDirectory)) {
        if (Test-Path $directory) {
            Write-CurrentTime; Write-Host " Suppression du dossier $directory en cours..." -ForegroundColor Green
            Remove-Item $directory -Recurse -Force -ErrorAction Stop
            Write-CurrentTime; Write-Host " Le répertoire $directory a été supprimé..." -ForegroundColor Green
        }
    }
} else {
    Write-CurrentTime; Write-Host " Aucun dossier à supprimer n'a été trouvé..." -ForegroundColor Yellow
}

# Supprimer le fichier powcache.dat existant, s'il existe
if (Test-Path $powcachePath) {
    Write-CurrentTime; Write-Host " Suppression du fichier powcache.dat en cours..." -ForegroundColor Green
    Remove-Item $powcachePath -Force -ErrorAction Stop
    Write-CurrentTime; Write-Host " Le fichier powcache.dat a été supprimé..." -ForegroundColor Green
}

# Télécharger (à nouveau) et extraire le bootstrap si nécessaire. Détecter si 7-Zip est installé pour l'utiliser, plus rapide.
if (Test-Path $bootstrapZipPath) {
    Write-CurrentTime; Write-Host " Extraction du bootstrap à partir de : $bootstrapZipPath..." -ForegroundColor Green
    Write-CurrentTime; Write-Host " Extraction du bootstrap vers        : $walletDirectory..." -ForegroundColor Green
    $zipProgram = $null
    $7zipKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\7zFM.exe"
    if (Test-Path $7zipKey) {
        $zipProgram = (Get-ItemProperty $7zipKey).'Path' + "7z.exe"
    }
    if ($zipProgram) {
        Write-CurrentTime; Write-Host " 7-Zip détecté, utilisation de 7-Zip pour extraire le bootstrap. Plus rapide..." -ForegroundColor Green
        & "$zipProgram" x "$bootstrapZipPath" -o"$walletDirectory" -y
    } else {
        Write-CurrentTime; Write-Host " 7-Zip non détecté, utilisation de 'Expand-Archive' pour extraire le bootstrap. Plus lent..." -ForegroundColor Green
        Expand-Archive -Path $bootstrapZipPath -DestinationPath $walletDirectory -Force -ErrorAction Stop
    }
} else {
    Write-CurrentTime; Write-Host " Aucun fichier 'bootstrap.zip' détecté dans le répertoire du portefeuille." -ForegroundColor Yellow
    Do {
        Get-BootstrapSize
        $confirmDownload = Read-Host " Voulez-vous télécharger le fichier bootstrap.zip ?`n (Il faut dire oui...) (o/n)"
    } Until ($confirmDownload.ToLower() -eq "o")
    Download-FileWithProgress -Url $bootstrapUrl -FilePath $bootstrapZipPath
    Check-BootstrapZip -bootstrapZipPath $bootstrapZipPath -bootstrapUrl $bootstrapUrl
}

# Afficher un message de fin
Write-CurrentTime; Write-Host " Opération terminée avec succès !" -ForegroundColor Green
Write-CurrentTime; Write-Host " Fin du Bootstrap, vous pouvez maintenant relancer RaptoreumCore." -ForegroundColor Green

# Pause pour que la console ne se ferme pas automatiquement si le script est exécuté directement
pause
