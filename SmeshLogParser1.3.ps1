# Overlay for go-spacemesh logs. Ensure you've got the right paths for $LogFilePath (ln 4), the drive letter for $diskReadSpeedBytes (ln 7), as well as the listener port you've specified on the node config JSON.
#
#
# Spacemesh Log file path
$LogFilePath = "C:\Smesh\Smesh1\log.txt"
# Drive Letter the PoST for this node is in
$Driveletter = "G:"
# Listener Port (default 9092)
$port = 9192

function GetLogInfo {
    param (
        [string]$LogFilePath
    )
    # General log capture variable
    $logContent = Get-Content $LogFilePath

    # Capture go-spacemesh.exe app version
    $appVersion = ($logContent | Select-String -Pattern 'App version:\s+(v\d+\.\d+\.\d+)').Matches.Value | Select-Object -Last 1

    # Capture CPU Usage
    $cpuUsage = (Get-Counter -Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    $cpuUsageFormatted = "{0:N1}" -f $cpuUsage
    
    # Capture Drive Read Speed
    $diskReadSpeedBytes = (Get-Counter -Counter "\LogicalDisk($Driveletter)\Disk Read Bytes/sec").CounterSamples.CookedValue
    $diskReadSpeedMBps = $diskReadSpeedBytes / 1MB
    $diskReadSpeedFormatted = "{0:N2}" -f $diskReadSpeedMBps

    # Function to extract Proof information from the log file
        $genProof = "Not yet"
    foreach ($line in $logContent[-1..-($logContent.Count)]) {
        if ($line -match "generating proof with PoW") {
            $genProof = "Done!"
            break
        } elseif ($line -match "waiting till poet round end") {
            $genProof = "Not yet"
            break
        }
    }
        $lfProof = "Not yet"
    foreach ($line in $logContent[-1..-($logContent.Count)]) {
        if ($line -match "calculating proof of work for nonces") {
            $lfProof = "Looking"
            break
      } elseif ($line -match "Found proof for nonce") {
            $lfProof = "Done!"
            break
      } elseif ($line -match "waiting till poet round end") {
            $lfProof = "Not yet"
            break
        }
    }
        $submittedproof = "Not yet"
    foreach ($line in $logContent[-1..-($logContent.Count)]) {
        if ($line -match "challenge submitted to poet proving service") {
            $submittedproof = "Done!"
            break
      } elseif ($line -match "generating proof with PoW") {
            $submittedproof = "Not yet"
            break
        }
    }


    # Extract the NodeID of the line containing "Loaded existing identity"
    $identityLine = $logContent | Select-String -Pattern 'Loaded existing identity' | Select-Object -Last 1
    $identity = if ($identityLine) { $identityLine.Line.Substring($identityLine.Line.Length - 64) } else { 'Not Found' }

    # Calculate the current epoch based on the start date and current date
    $startDate = Get-Date "2023-07-28T08:00:00Z"  # Start date and time in UTC
    $currentDate = Get-Date
    $daysPassed = ($currentDate - $startDate).Days
    $currentEpoch = 1 + [math]::Floor($daysPassed / 14)
     
    
    $status = "Idle..."
    foreach ($line in $logContent[-1..-($logContents.Count)]) {
        if ($line -match "Proving with PoW creator ID") {
            $status = "Looking for Proof"
            break
        } elseif ($line -match "Found proof for nonce") {
            $status = "Found Proof! Waiting to submit..."
            break
        } elseif ($line -match "waiting till poet round end") {
            $status = "Idle..."
            break
        }
    }
    
    # Extract Target Epoch and Poet Round End
    $targetEpoch = 0
    $poetRoundEnd = 'N/A'
    foreach ($line in $logContent -split '\r?\n') {
        if ($line -match '"target epoch": "(\d+)"') {
            $targetEpoch = [int]$matches[1]
        }
        if ($line -match '"poet round end": "(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}\+\d{4})"') {
            $poetRoundEnd = Get-Date $matches[1] -Format "dd-MM-yyyy HH:mm"
        }
        if ($line -match 'initialization: file already initialized.*"fileIndex": (\d+)') {
            $postfiles = ([int]$matches[1] + 1)
        }
    }
    
    #Proof SUBMISSION window:
    $ProofSub = (Get-Date $poetRoundEnd).AddHours(11)
    $ProofSubFormatted = $ProofSub.ToString("dd-MM-yyyy HH:mm")

    # Calculate the total size in bytes
    $fileSizeBytes = [regex]::Match($logContent, '"maxFileSize": (\d+)').Groups[1].Value
    $fileSizeBytes = [int64]$fileSizeBytes

    # Calculate the total size in bytes
    $totalSizeBytes = $postfiles * $fileSizeBytes

    # Calculate the total size in either GiB or TiB
    if ($totalSizeBytes -ge 1TB) {
        $totalSize = $totalSizeBytes / 1TB
        $unit = 'TiB'
    } else {
        $totalSize = $totalSizeBytes / 1GB
        $unit = 'GiB'
}

    $totalSize = "{0:F2}" -f $totalSize

    #Extract Timelines
    $startTimeStamp = $logContent | Select-String -Pattern '(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}).*Proving with PoW creator ID' | Select-Object -Last 1
    $middleTimeStamp = $logContent | Select-String -Pattern '(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}).*Found proof for nonce' | Select-Object -Last 1

    $startTime = if ($startTimeStamp) { Get-Date $startTimeStamp.Matches.Groups[1].Value } else { $null }
    $middleTime = if ($middleTimeStamp) { Get-Date $middleTimeStamp.Matches.Groups[1].Value } else { $null }

    $k2powTime = if ($startTime -and $middleTime) { $middleTime - $startTime } else { $null }
    return $appVersion, $genProof, $lfProof, $identity, $currentEpoch, $targetEpoch, $poetRoundEnd, $submittedproof, $corruptedPost, $postfiles, $status, $k2PowTime, $totalSize, $unit, $diskReadSpeedFormatted, $cpuUsageFormatted, $ProofSubFormatted
}

function ShowOverlay {
    param (
        [string]$LogFilePath
    )

    # Run the grpcurl command and capture the output as a string
    $grpcOutput = .\grpcurl --plaintext 127.0.0.1:$port spacemesh.v1.NodeService.Status

    # Convert the JSON string to a PowerShell object
    $statusObject = $grpcOutput | ConvertFrom-Json

    # Extract values and set them as variables
    $connectedPeers = $statusObject.status.connectedPeers
    $isSynced = $statusObject.status.isSynced
    $syncedLayer = $statusObject.status.syncedLayer.number
    $verifiedLayer = $statusObject.status.verifiedLayer.number
    $topLayer = $statusObject.status.topLayer.number

    # Get the current time and date
    $currentTime = Get-Date -Format "HH:mm:ss"
    $currentDate = Get-Date -Format "dd-MM-yyyy"

    # Build the ASCII art overlay with the current time, date, and App Version
    $horizontalLine = "─" * 75
    $verticalLine = "│"

    # Extract information from the log file
    $appVersion, $genProof, $lfProof, $identity, $currentEpoch, $targetEpoch, $poetRoundEnd, $submittedproof, $corruptedPost, $postfiles, $status, $k2PowTime, $totalSize, $unit, $diskReadSpeedFormatted, $cpuUsageFormatted, $ProofSubFormatted = GetLogInfo -LogFilePath $LogFilePath

    # Display the "Corrupted Post" field in red if found, otherwise display "None found"
        $corruptedPost = if ($logContent -match 'verify PoST: invalid proof') { 'CORRUPTED POST REPORTED' } else { 'None found' }
    if ($corruptedPost -eq 'CORRUPTED POST REPORTED') {
        $corruptedPostStatus = "CORRUPTED POST REPORTED"
        $corruptedPostColor = "Red"
    } else {
        $corruptedPostStatus = "None found"
        $corruptedPostColor = "White"  # You can change this color to your preference
    }
    $overlay = @"
╭$horizontalLine╮
$verticalLine Time: {0,-10} Date: {1,-29} {2,-1} $verticalLine
$verticalLine$("{0,-75}" -f " ")$verticalLine
$verticalLine Status: {12,-52} Synced: {20,-1} $verticalLine
$verticalLine Generating Proof: {3,-45} Peers: {19,-1} $verticalLine
$verticalLine Looking for Proof: {4,-38} Top Layer: {23, -2} $verticalLine
$verticalLine Proof Submitted: {8,-37} Synced Layer: {21, -2} $verticalLine
$verticalLine Found proof in PoST in: {13,-28} Verified Layer: {22,-2} $verticalLine
$verticalLine$("{0,-75}" -f " ")$verticalLine
$verticalLine Current Epoch: {5,-58} $verticalLine
$verticalLine Rewards Expected Epoch: {6,-49} $verticalLine
$verticalLine Next Proof Generation Window: {7,-44}$verticalLine
$verticalLine Next Proof Submission Window: {18,-43} $verticalLine
$verticalLine$("{0,-75}" -f " ")$verticalLine
$verticalLine$("{0,-75}" -f " ")$verticalLine
$verticalLine CPU Usage: {17,-63}$verticalLine
$verticalLine HDD Read Speed (MB/s): {16,-51}$verticalLine
$verticalLine$("{0,-75}" -f " ")$verticalLine
$verticalLine$("{0,-75}" -f " ")$verticalLine
$verticalLine POST Size: {14,-2} {15,-58}$verticalLine
$verticalLine POST files initialized: {11,-50}$verticalLine
$verticalLine POST Corruption: {9,-57}$verticalLine
$verticalLine$("{0,-75}" -f " ")$verticalLine
$verticalLine$("{0,-75}" -f " ")$verticalLine
$verticalLine$("{0,-75}" -f " ")$verticalLine
$verticalLine ID: {10,-1}      $verticalLine
╰$horizontalLine╯
"@ -f $currentTime, $currentDate, $appVersion, $genProof, $lfProof, $currentEpoch, $targetEpoch, $poetRoundEnd, $submittedproof, $corruptedPostStatus, $identity, $postfiles, $status, $k2PowTime, $totalSize, $unit, $diskReadSpeedFormatted, $cpuUsageFormatted, $ProofSubFormatted, $connectedPeers, $isSynced, $syncedLayer, $verifiedLayer, $topLayer
    #       0           1              2           3          4              5             6             7                8             9                 10          11         12         13          14       15           16                     17                  18                   19           20         21             22             23
    # Clear the console and display the overlay with the new field
    Clear-Host
    Write-Host $overlay -ForegroundColor $corruptedPostColor
}
# Loop to refresh the overlay and log output every 5 seconds
while ($true) {
    ShowOverlay -LogFilePath $LogFilePath
    Start-Sleep -Seconds 0.51
}
