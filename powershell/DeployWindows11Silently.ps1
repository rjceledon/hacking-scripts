# Define the file paths and URLs
$logFile = "C:\Windows11UpgradeLog.txt"
$windows11DownloadUrl = "https://go.microsoft.com/fwlink/?linkid=2171764"  # URL to download Windows 11 Installation Assistant
$windows11IsoUrl = "https://www.microsoft.com/en-us/software-download/windows11"  # Windows 11 official ISO page

# Log function to write to log file
Function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    
    # Write message to log file and output to console
    Add-Content -Path $logFile -Value $logMessage
    Write-Host $logMessage
}

# Function to check if the system meets Windows 11 hardware requirements
Function Check-SystemRequirements {
    Write-Log "Starting system requirement checks..."

    # Check TPM version
    $tpm = Get-WmiObject -class Win32_Tpm -namespace root\CIMV2\Security\MicrosoftTpm
    if ($tpm) {
        if ($tpm.SpecVersion -ge "2.0") {
            Write-Log "TPM 2.0 found."
        } else {
            Write-Log "TPM 2.0 not found, this is required for Windows 11."
            return $false
        }
    } else {
        Write-Log "TPM not found."
        return $false
    }

    # Check Secure Boot
    $secureBoot = Confirm-SecureBootUEFI
    if ($secureBoot) {
        Write-Log "Secure Boot is enabled."
    } else {
        Write-Log "Secure Boot is not enabled. Windows 11 requires Secure Boot."
        return $false
    }

    # Check processor compatibility (Windows 11 supports 64-bit CPUs only)
    $cpu = Get-WmiObject -Class Win32_Processor
    if ($cpu) {
        if ($cpu.Architecture -eq 9) {
            Write-Log "64-bit processor found."
        } else {
            Write-Log "64-bit processor not found. Windows 11 requires a 64-bit CPU."
            return $false
        }
    }

    # Check RAM
    $ram = Get-WmiObject -Class Win32_ComputerSystem
    if ($ram.TotalPhysicalMemory -ge 4GB) {
        Write-Log "Sufficient RAM found (>= 4GB)."
    } else {
        Write-Log "Insufficient RAM. Windows 11 requires at least 4GB."
        return $false
    }

    # Check storage space
    $disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    $storageSpace = [math]::round($disk.FreeSpace / 1GB, 2)
    if ($storageSpace -ge 64) {
        Write-Log "Sufficient storage space found (>= 64GB)."
    } else {
        Write-Log "Insufficient storage space. Windows 11 requires at least 64GB."
        return $false
    }

    # All checks passed
    Write-Log "System meets the minimum requirements for Windows 11."
    return $true
}

# Function to download Windows 11 Installation Assistant
Function Download-Windows11Installer {
    Write-Log "Downloading Windows 11 Installation Assistant..."

    $installerPath = "$env:TEMP\Windows11Setup.exe"
    try {
        Invoke-WebRequest -Uri $windows11DownloadUrl -OutFile $installerPath
        Write-Log "Windows 11 Installation Assistant downloaded successfully at $installerPath."
        return $installerPath
    } catch {
        Write-Log "Failed to download Windows 11 Installation Assistant. Error: $_"
        return $null
    }
}

# Function to run the Windows 11 upgrade silently
Function Upgrade-Windows11 {
    param ([string]$installerPath)

    Write-Log "Initiating Windows 11 upgrade..."

    if ($installerPath -ne $null) {
        Write-Log "Starting the upgrade process..."
        Start-Process -FilePath $installerPath -ArgumentList "/auto upgrade /quiet /noreboot" -Wait
        Write-Log "Windows 11 upgrade process started."
    } else {
        Write-Log "Installer path is invalid, upgrade aborted."
    }
}

# Function to monitor upgrade status
Function Monitor-UpgradeStatus {
    Write-Log "Monitoring upgrade status..."

    # Checking for the setup process
    $process = Get-Process -Name "setup" -ErrorAction SilentlyContinue
    if ($process) {
        Write-Log "Upgrade process is running..."
        while ($process.HasExited -eq $false) {
            Write-Log "Upgrade still in progress..."
            Start-Sleep -Seconds 30
            $process = Get-Process -Name "setup" -ErrorAction SilentlyContinue
        }
        Write-Log "Upgrade process completed successfully."
    } else {
        Write-Log "No upgrade process found. Ensure the upgrade was initiated."
    }
}

# Main logic
Write-Log "Windows 11 upgrade script started."

# Step 1: Check if the system meets the requirements
if (Check-SystemRequirements) {
    # Step 2: Download Windows 11 installer
    $installerPath = Download-Windows11Installer
    if ($installerPath -ne $null) {
        # Step 3: Start the upgrade process silently
        Upgrade-Windows11 -installerPath $installerPath

        # Step 4: Monitor the upgrade process
        Monitor-UpgradeStatus
    } else {
        Write-Log "Failed to download Windows 11 installer. Upgrade aborted."
    }
} else {
    Write-Log "System does not meet the minimum requirements for Windows 11. Upgrade aborted."
}

Write-Log "Windows 11 upgrade script finished."
