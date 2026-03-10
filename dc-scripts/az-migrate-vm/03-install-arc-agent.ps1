# Install Azure Connected Machine Agent on Azure Migrate Appliance VM
# This script runs on the DC host and uses PowerShell Direct
# to install the Arc agent inside the nested appliance VM

param(
    [string]$ApplianceVMName = "az-migrate",
    [string]$ApplianceIP = "192.168.100.10",
    [string]$AppliancePassword = ""
)

$ErrorActionPreference = 'Stop'

$AgentUrl = "https://aka.ms/AzureConnectedMachineAgent"
$InstallerPath = "C:\Windows\Temp\AzureConnectedMachineAgent.msi"

Write-Host "=== Install Azure Connected Machine Agent ===" -ForegroundColor Yellow
Write-Host "Target VM: $ApplianceVMName ($ApplianceIP)"

# ============================================
# 1. Verify appliance VM is running
# ============================================
Write-Host "[1/3] Verifying appliance VM..."

$vm = Get-VM -Name $ApplianceVMName -ErrorAction SilentlyContinue
if (-not $vm) {
    Write-Host "ERROR: VM '$ApplianceVMName' not found in Hyper-V"
    exit 1
}

if ($vm.State -ne 'Running') {
    Write-Host "Starting VM..."
    Start-VM -Name $ApplianceVMName
    Start-Sleep -Seconds 30
}

Write-Host "Appliance VM is running"

# ============================================
# 2. Wait for VM to be reachable
# ============================================
Write-Host "[2/3] Waiting for appliance VM to be reachable..."

$maxAttempts = 20
$attempt = 0
$isReachable = $false

while (-not $isReachable -and $attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "  [$attempt/$maxAttempts] Pinging $ApplianceIP..."
    
    if (Test-Connection -ComputerName $ApplianceIP -Count 1 -Quiet -ErrorAction SilentlyContinue) {
        $isReachable = $true
        Write-Host "Appliance VM is reachable!"
    } else {
        Start-Sleep -Seconds 15
    }
}

if (-not $isReachable) {
    Write-Host "ERROR: Cannot reach appliance VM at $ApplianceIP"
    exit 1
}

# ============================================
# 3. Install agent via PowerShell Direct
# ============================================
Write-Host "[3/3] Installing Azure Connected Machine Agent..."

$secPassword = ConvertTo-SecureString $AppliancePassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("Administrator", $secPassword)

$installResult = Invoke-Command -VMName $ApplianceVMName -Credential $cred -ScriptBlock {
    param($AgentUrl, $InstallerPath)
    $ErrorActionPreference = 'Stop'

    # Check if agent is already installed
    $existingService = Get-Service -Name "himds" -ErrorAction SilentlyContinue
    if ($existingService) {
        Write-Host "Azure Connected Machine Agent is already installed"
        Write-Host "Service status: $($existingService.Status)"
        $agentPath = "$env:ProgramFiles\AzureConnectedMachineAgent\azcmagent.exe"
        if (Test-Path $agentPath) {
            $version = & $agentPath version 2>$null
            Write-Host "Agent version: $version"
        }
        return "ALREADY_INSTALLED"
    }

    # Download the agent MSI
    Write-Host "Downloading Azure Connected Machine Agent..."
    Write-Host "Source: $AgentUrl"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ProgressPreference = 'SilentlyContinue'
    
    try {
        Invoke-WebRequest -Uri $AgentUrl -OutFile $InstallerPath -UseBasicParsing
    } catch {
        Write-Host "ERROR: Failed to download agent: $($_.Exception.Message)"
        return "DOWNLOAD_FAILED"
    }

    if (-not (Test-Path $InstallerPath)) {
        Write-Host "ERROR: Installer not found after download"
        return "DOWNLOAD_FAILED"
    }

    $fileSize = (Get-Item $InstallerPath).Length / 1MB
    Write-Host "Downloaded: $([math]::Round($fileSize, 2)) MB"

    # Install the agent silently
    Write-Host "Installing agent..."
    $installProcess = Start-Process -FilePath "msiexec.exe" `
        -ArgumentList "/i", $InstallerPath, "/l*v", "C:\Windows\Temp\ArcAgentInstall.log", "/qn" `
        -Wait -PassThru

    if ($installProcess.ExitCode -ne 0) {
        Write-Host "ERROR: Installation failed with exit code $($installProcess.ExitCode)"
        return "INSTALL_FAILED"
    }

    # Verify installation
    $agentPath = "$env:ProgramFiles\AzureConnectedMachineAgent\azcmagent.exe"
    if (Test-Path $agentPath) {
        $version = & $agentPath version 2>$null
        Write-Host "Agent installed successfully!"
        Write-Host "Agent version: $version"
    } else {
        Write-Host "WARNING: Agent binary not found at expected path"
        return "VERIFY_FAILED"
    }

    # Clean up installer
    Remove-Item $InstallerPath -Force -ErrorAction SilentlyContinue

    return "OK"
} -ArgumentList $AgentUrl, $InstallerPath

Write-Host "Result: $installResult"
if ($installResult -ne "OK" -and $installResult -ne "ALREADY_INSTALLED") {
    Write-Host "ERROR: Agent installation failed: $installResult"
    exit 1
}

Write-Host "=== Done ==="
