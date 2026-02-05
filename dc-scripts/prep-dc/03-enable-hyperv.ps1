# Enable Hyper-V on Windows Server
# This script runs on the DC VM and will cause a reboot

param(
    [string]$LogFile = "C:\HyperV-Setup.log"
)

$ErrorActionPreference = 'Continue'

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Write-Host $logMessage
    Add-Content -Path $LogFile -Value $logMessage
}

Write-Log "=== Hyper-V Installation Script Started ==="
Write-Log "Computer: $env:COMPUTERNAME"
Write-Log "User: $env:USERNAME"

# Check if Hyper-V is already installed
$hyperv = Get-WindowsFeature -Name Hyper-V
if ($hyperv.Installed) {
    Write-Log "Hyper-V is already installed"
    Write-Log "Install State: $($hyperv.InstallState)"
    
    # Check if reboot is pending
    $rebootRequired = (Get-WindowsFeature -Name Hyper-V).InstallState -eq 'InstallPending'
    if ($rebootRequired) {
        Write-Log "Reboot is pending for Hyper-V installation"
        Write-Log "Initiating reboot in 10 seconds..."
        Start-Sleep -Seconds 10
        Restart-Computer -Force
        exit 0
    }
    
    Write-Log "Hyper-V installation complete, no reboot required"
    exit 0
}

# Install Hyper-V and management tools
Write-Log "Installing Hyper-V feature..."

try {
    $result = Install-WindowsFeature -Name Hyper-V `
        -IncludeManagementTools `
        -IncludeAllSubFeature `
        -Restart:$false
    
    Write-Log "Hyper-V installation result:"
    Write-Log "  Success: $($result.Success)"
    Write-Log "  Exit Code: $($result.ExitCode)"
    Write-Log "  Restart Needed: $($result.RestartNeeded)"
    Write-Log "  Features Installed: $($result.FeatureResult.Count)"
    
    if ($result.Success) {
        Write-Log "Hyper-V installed successfully!"
        
        # List installed features
        foreach ($feature in $result.FeatureResult) {
            Write-Log "  - $($feature.DisplayName)"
        }
        
        if ($result.RestartNeeded -eq 'Yes') {
            Write-Log "System restart is required to complete Hyper-V installation"
            Write-Log "Initiating reboot in 10 seconds..."
            Start-Sleep -Seconds 10
            
            # Force restart
            Restart-Computer -Force
        } else {
            Write-Log "No restart required (unexpected)"
        }
    } else {
        Write-Log "ERROR: Hyper-V installation failed!"
        Write-Log "Exit Code: $($result.ExitCode)"
        exit 1
    }
    
} catch {
    Write-Log "ERROR: Exception during Hyper-V installation: $_"
    Write-Log "Exception Type: $($_.Exception.GetType().FullName)"
    Write-Log "Stack Trace: $($_.ScriptStackTrace)"
    exit 1
}

Write-Log "=== Script Completed ==="
