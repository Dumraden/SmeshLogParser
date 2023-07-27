function GetLogInfo {
    param (
        [string]$LogFilePath
    )

    # Function to extract information from the log file
    $logContent = Get-Content $LogFilePath
    $appVersion = ($logContent | Select-String -Pattern 'App version:\s+(v\d+\.\d+\.\d+)').Matches.Groups[1] | Select-Object -Last 1
    $genProof = if ($logContent -match 'generating proof with PoW') { 'Done' } else { 'x' }
    $lfProof = if ($logContent -match 'calculating proof of work for nonces') { 'Done' } else { 'x' }
    $foundproof = if ($logContent -match 'Found proof for nonce') { 'Done!' } else { ':(' }
    $corruptedPost = if ($logContent -match 'verify PoST: invalid proof') { 'CORRUPTED POST REPORTED' } else { 'None found' }
    $submittedproof = if ($logContent -match 'submitted to poet proving service ') { 'Done!' } else { 'x' }

    # Extract the NodeID of the line containing "Loaded existing identity"
    $identityLine = $logContent | Select-String -Pattern 'Loaded existing identity' | Select-Object -Last 1
    $identity = if ($identityLine) { $identityLine.Line.Substring($identityLine.Line.Length - 64) } else { 'Not Found' }

    # Extract Current Epoch, Target Epoch, and Poet Round End
    $currentEpoch = 0
    $targetEpoch = 0
    $poetRoundEnd = 'N/A'
    foreach ($line in $logContent -split '\r?\n') {
        if ($line -match '"current epoch": "(\d+)"') {
            $currentEpoch = [int]$matches[1]
        }
        if ($line -match '"target epoch": "(\d+)"') {
            $targetEpoch = [int]$matches[1]
        }
        if ($line -match '"poet round end": "(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}\+\d{4})"') {
            $poetRoundEnd = Get-Date $matches[1] -Format "dd-MM-yyyy HH:mm"
        }
        if ($line -match 'initialization: file already initialized.*"fileIndex": (\d+)') {
            $postfiles = [int]$matches[1]+1
        }
    }

    return $appVersion, $genProof, $lfProof, $foundproof, $identity, $currentEpoch, $targetEpoch, $poetRoundEnd, $submittedproof, $corruptedPost, $postfiles
}

function ShowOverlay {
    param (
        [string]$LogFilePath
    )

    # Get the current time and date
    $currentTime = Get-Date -Format "HH:mm:ss"
    $currentDate = Get-Date -Format "dd-MM-yyyy"

    # Build the ASCII art overlay with the current time, date, and App Version
    $horizontalLine = "─" * 75
    $verticalLine = "│"

    # Extract information from the log file
    $appVersion, $genProof, $lfProof, $foundproof, $identity, $currentEpoch, $targetEpoch, $poetRoundEnd, $submittedproof, $corruptedPost, $postfiles = GetLogInfo -LogFilePath $LogFilePath

    # Display the "Corrupted Post" field in red if found, otherwise display "None found"
    if ($corruptedPost -eq 'CORRUPTED POST REPORTED') {
        $corruptedPostStatus = "CORRUPTED POST REPORTED"
        $corruptedPostColor = "Red"
    } else {
        $corruptedPostStatus = "None found"
        $corruptedPostColor = "White"  # You can change this color to your preference
    }
    $overlay = @"
╭$horizontalLine╮
$verticalLine Time: {0,-10} Date: {1,-30} App Version: {2,-6} $verticalLine
$verticalLine$("{0,-75}" -f " ")$verticalLine
$verticalLine Generating Proof: {3,-56}$verticalLine
$verticalLine Looking for Proof: {4,-55}$verticalLine
$verticalLine Found Proof: {5,-61}$verticalLine
$verticalLine Proof Submitted: {9,-57}$verticalLine
$verticalLine$("{0,-75}" -f " ")$verticalLine
$verticalLine Current Epoch: {6,-58} $verticalLine
$verticalLine When Coin? Epoch: {7,-55} $verticalLine
$verticalLine Next Proof Submission Window: {8,-43} $verticalLine
$verticalLine$("{0,-75}" -f " ")$verticalLine
$verticalLine$("{0,-75}" -f " ")$verticalLine
$verticalLine$("{0,-75}" -f " ")$verticalLine
$verticalLine$("{0,-75}" -f " ")$verticalLine
$verticalLine POST files initialized: {12,-50}$verticalLine
$verticalLine POST Corruption: {10,-57}$verticalLine
$verticalLine$("{0,-75}" -f " ")$verticalLine
$verticalLine$("{0,-75}" -f " ")$verticalLine
$verticalLine$("{0,-75}" -f " ")$verticalLine
$verticalLine ID: {11,-1}      $verticalLine
╰$horizontalLine╯
"@ -f $currentTime, $currentDate, $appVersion, $genProof, $lfProof, $foundproof, $currentEpoch, $targetEpoch, $poetRoundEnd, $submittedproof, $corruptedPostStatus, $identity, $postfiles

    # Clear the console and display the overlay with the new field
    Clear-Host
    Write-Host $overlay -ForegroundColor $corruptedPostColor
}

# Run the function with the log file path
$LogFilePath = "$env:USERPROFILE\spacemesh\log.txt"

# Loop to refresh the overlay and log output every 5 seconds
while ($true) {
    ShowOverlay -LogFilePath $LogFilePath
    Start-Sleep -Seconds 5
}
