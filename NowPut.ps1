########################################################
### Script to create transactions for nowput.finance ###
####### Just insert the transaction id in the ##########
######### Tracking section of nowput.finance ###########
########################################################

# Define the Raptoreum CLI path, betting addresses and timelock durations
$rtmCliPath = "E:\Raptoreum\Wallet1.3.17.02\raptoreum-cli.exe -testnet -port=10229 -rpcport=10225 -rpcuser=wizz -rpcpassword=toto"

$callAddresses = [ordered]@{
    "1 minute" = "rmMmcyiCHt7qT9cMe3v6m26vFfAju3ZDnc"
    "3 minutes" = "rhieLuhE1PuLiyuhomLSuPfSfEFjFFLjG6"
    "10 minutes" = "rnD4go5gJa6LLY9PpioGZ6uU6jRdsDV56b"
    "15 minutes" = "rdTUZ1ti8f25dCPTPWw5xCdZcpm7BkeBpp"
    "30 minutes" = "rWKGtBSdgHhNJwJFnkDihyZ1EEu8zenzFd"
    "1 hour" = "rZ9XKcc9fayeouhk9RgWvnJGnqsAba76Ms"
    "2 hours" = "rWjzyxobmju6i6NaBhTfpLdCHuyMjk8S2C"
    "3 hours" = "rYuej4wHWek8Li2VikeETNXnzAgzRFR65B"
    "12 hours" = "rf2imQsSzojiNu5kgAgPxxTzJ7r87iiLjc"
    "1 day" = "re444o2SvjdZDkkpxxSkvRAhPWVi9UfEjW"
    "1 week" = "rkHoQvyVjE4CV1G1BBhfgkdyXtpo8k1hwk"
}
$putAddresses = [ordered]@{
    "1 minute" = "rkdi1Ke6F4D6QhREe2G8VpatzUKTWDVXU9"
    "3 minutes" = "rrabXzxR2hJRDPBkG6XUkiYaoVVBLoHed8"
    "10 minutes" = "rtfiCnxFXfmusXtJTpdBhehtCwU4RZGv5k"
    "15 minutes" = "rXRwPwYXnFFPZrw1EcqyjiQeg4Z9kvho8S"
    "30 minutes" = "rYiTao6pFbAotg4ojyydR2wvkQutRpkzLr"
    "1 hour" = "rgZ8hcy3ePuVSehvNLrZBrx6BVUNGAzZPy"
    "2 hours" = "rWuQPheNERGo3hpP6orShyWKtQCbhLY9rd"
    "3 hours" = "riT3h9MjU9Akuab1v84oXaJiwow122N7qh"
    "12 hours" = "rfm4YCSY6SdvPsNrMPGuqgZsr2YhQ7khqS"
    "1 day" = "rqBVXAdQ3M3c4STfy1cV3fn8AStVt9wwSm"
    "1 week" = "rkmfB73XnXCeoJnMrPq2Ss4QBP72s66Wqk"
}
$timelock = @{
    "1 minute" = 60
    "3 minutes" = 180
    "10 minutes" = 600
    "15 minutes" = 900
    "30 minutes" = 1800
    "1 hour" = 3600
    "2 hours" = 7200
    "3 hours" = 10800
    "12 hours" = 43200
    "1 day" = 86400
    "1 week" = 604800
}

# Display the initial menu to choose between Call or Put
$betType = Read-Host "Please choose your betting option: Call or Put"

# Check if the bet type entered is valid
while ($betType -ne "Call" -and $betType -ne "Put") {
    Write-Host "Invalid bet type entered. Please enter either 'Call' or 'Put'." -ForegroundColor Yellow
    $betType = Read-Host "Please choose your betting option: Call or Put"
}

# Display the menu of betting options
if ($betType -eq "call") {
    Write-Host "Choose the duration of your Call bet:" -ForegroundColor Green
    $callKeys = $callAddresses.Keys | Sort-Object { [array]::IndexOf($callAddresses.Values, $_) }
    $i = 1
    foreach ($key in $callKeys) {
        Write-Host "$i. $key"
        $i++
    }
}
else {
    Write-Host "Choose the duration of your Put bet:" -ForegroundColor Green
    $putKeys = $putAddresses.Keys | Sort-Object { [array]::IndexOf($putAddresses.Values, $_) }
    $i = 1
    foreach ($key in $putKeys) {
        Write-Host "$i. $key"
        $i++
    }
}

# Prompt the user to enter their betting option
[int]$bettingOptionNumber = Read-Host "Enter your betting option number (1-$i):"
while ($bettingOptionNumber -lt 1 -or $bettingOptionNumber -gt $i) {
    Write-Host "Invalid betting option number entered. Please enter a number between 1 and $($i-1)." -ForegroundColor Yellow
    [int]$bettingOptionNumber = Read-Host "Enter your betting option number (1-$i):"
}

# Print the choice
if ($betType -eq "call") {
    $chosenBettingOption = $($callAddresses.Keys)[$bettingOptionNumber-1]
    Write-Host "You have chosen a '$chosenBettingOption' Call..." -ForegroundColor Green
}
else {
    $chosenBettingOption = $($putAddresses.Keys)[$bettingOptionNumber-1]
    Write-Host "You have chosen a '$chosenBettingOption' Put..." -ForegroundColor Green
}
# Get the correct address from choices
if ($betType -eq "Call") {
    $betAddress = $callAddresses[$chosenBettingOption]
} else {
    $betAddress = $putAddresses[$chosenBettingOption]
}

# Prompt the user to enter their bet amount, min 500
$minimumBetAmount = 500
[int]$betAmount = Read-Host "Enter your bet amount (minimum: $minimumBetAmount)"
while (-not [decimal]::TryParse($betAmount, [ref][decimal]0) -or [decimal]$betAmount -lt $minimumBetAmount) {
    Write-Host "Invalid bet amount entered. Please enter a valid number greater than or equal to $minimumBetAmount..." -ForegroundColor Yellow
    [int]$betAmount = Read-Host "Enter your bet amount (minimum: $minimumBetAmount):"
}
Write-Host "You have chosen to bet $betAmount trtm..." -ForegroundColor Green

# Prompt the user to enter how many bets they want to execute
[int]$numBets = Read-Host "How many bets would you like to execute? (1-10)"
while ($numBets -lt 1 -or $numBets -gt 10) {
    Write-Host "Invalid number of bets entered. Please enter a number between 1 and 10..." -ForegroundColor Yellow
    [int]$numBets = Read-Host "How many bets would you like to execute? (1-10)"
}


# Initialize an empty list to store the transaction IDs
$transactionIDs = @()
# Send the bet transaction and get the transaction ID for each bet
for ($i = 0; $i -lt $numBets; $i++) {
$futureMaturity = -1
$futureLocktime = $timelock[$chosenBettingOption]
try {
    $transactionID =cmd /C "$rtmCliPath sendtoaddress `"$betAddress`" $betAmount `"{`\`"future_maturity`\`": $futureMaturity`, `\`"future_locktime`\`"`: $futureLocktime`}`"" 2>&1
}
catch {
    Write-Error "Error during the transaction: $_" -ForegroundColor Yellow
    Break
}
Write-Host "Success ! The transaction has been sent for bet of '$betAmount'trtm on a '$chosenBettingOption' $betType." -ForegroundColor Green
Write-Host "ID for the 'Tracking' section on Nowput.finance: $transactionID" -ForegroundColor Green
#Write-Host "Explorer link: https://testnet.raptoreum.com/tx/$transactionID"
# Add the transaction ID to the list
$transactionIDs += $transactionID
}

# Check the bet result for each transaction ID
Write-Host "Let's track the results (Check every 20 seconds)..." -ForegroundColor Green
foreach ($transactionID in $transactionIDs) {
    $url = "https://ap1.nowput.finance/Hedge?txid=$transactionID"
    $status = $null
    while (-not $status -or $status -eq "ACTIVE" ) {
        $response = Invoke-WebRequest $url
        $content = $response.Content
        $status = $content | Select-String -Pattern '"status":"([^"]+)"' | ForEach-Object { $_.Matches.Groups[1].Value }
        Write-Host "Not yet ! Sleep..." -ForegroundColor Yellow
        Start-Sleep -Seconds 20
    }
    # Print the result of the bet for each transaction ID
    if ($status -eq "HOUSE_WIN") {
        Write-Host "Sorry, you lost the bet for transaction ID $transactionID." -ForegroundColor Yellow
    }
    elseif ($status -eq "USER_WIN") {
        Write-Host "Congratulations! You won the bet for transaction ID $transactionID." -ForegroundColor Green
    }
    else {
        Write-Host "Unexpected status value for transaction ID $transactionID : $status" -ForegroundColor Yellow
    }
}
