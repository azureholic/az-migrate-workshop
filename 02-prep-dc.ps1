# Azure Migration Workshop - Prepare DC VM
# This script enables Hyper-V, creates NAT networking, and configures DHCP
# for nested virtualization in Azure

param(
    [string]$ResourceGroupName = "rg-migrate-workshop",
    [string]$VMName = "vm-dc"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Azure Migration Workshop - Prepare DC VM ===" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "VM Name: $VMName`n" -ForegroundColor Cyan

# ============================================
# 1. Check if Hyper-V is already enabled
# ============================================
Write-Host "[1/5] Checking if Hyper-V is already installed..." -ForegroundColor Yellow

$hypervCheckOutput = az vm run-command invoke `
    --resource-group $ResourceGroupName `
    --name $VMName `
    --command-id RunPowerShellScript `
    --scripts "(Get-WindowsFeature -Name Hyper-V).Installed" `
    --output json 2>$null

$hypervResult = ($hypervCheckOutput | ConvertFrom-Json).value | Where-Object { $_.code -like '*StdOut*' } | Select-Object -ExpandProperty message
$hypervInstalled = $hypervResult.Trim() -eq 'True'

if ($hypervInstalled) {
    Write-Host "Hyper-V is already installed" -ForegroundColor Green
    Write-Host "Skipping to NAT switch configuration..." -ForegroundColor Cyan
} else {

# ============================================
# 2. Enable Hyper-V (will cause reboot)
# ============================================
Write-Host "`n[1/5] Enabling Hyper-V on VM..." -ForegroundColor Yellow
Write-Host "Note: This will cause the VM to reboot`n" -ForegroundColor Cyan

$enableHyperVScript = @'
$ErrorActionPreference = 'Stop'

Write-Host "Installing Hyper-V feature..."
$result = Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart

if ($result.Success) {
    Write-Host "Hyper-V installation initiated successfully"
    Write-Host "RestartNeeded: $($result.RestartNeeded)"
} else {
    Write-Host "ERROR: Hyper-V installation failed"
    exit 1
}
'@

try {
    $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
    $enableHyperVScript | Out-File -FilePath $tempFile -Encoding ASCII

    $output = & az vm run-command invoke `
        --resource-group $ResourceGroupName `
        --name $VMName `
        --command-id RunPowerShellScript `
        --scripts "@$tempFile" `
        --output json 2>$null

    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

    $result = ($output | ConvertFrom-Json).value
    $stdOut = ($result | Where-Object { $_.code -like '*StdOut*' }).message
    if ($stdOut) { Write-Host $stdOut -ForegroundColor Gray }
    
    Write-Host "`nVM is rebooting..." -ForegroundColor Yellow
    Write-Host "Waiting for VM to come back online (checking every 30 seconds)...`n" -ForegroundColor Cyan
    
    # Wait for the reboot to start
    Start-Sleep -Seconds 30
    
    # Poll until VM is back online
    $maxAttempts = 40  # 40 * 30 seconds = 20 minutes max wait
    $attempt = 0
    $isOnline = $false
    
    while (-not $isOnline -and $attempt -lt $maxAttempts) {
        $attempt++
        Write-Host "[$attempt/$maxAttempts] Checking VM status..." -ForegroundColor Gray
        
        try {
            $testOutput = az vm run-command invoke `
                --resource-group $ResourceGroupName `
                --name $VMName `
                --command-id RunPowerShellScript `
                --scripts "Write-Host 'Online'" `
                --output json 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                $testResult = $testOutput | ConvertFrom-Json
                if ($testResult.value) {
                    Write-Host "VM is back online!" -ForegroundColor Green
                    $isOnline = $true
                }
            }
        } catch {
            # VM not ready yet, continue waiting
        }
        
        if (-not $isOnline -and $attempt -lt $maxAttempts) {
            Start-Sleep -Seconds 30
        }
    }
    
    if (-not $isOnline) {
        Write-Host "WARNING: VM did not come back online within expected time" -ForegroundColor Yellow
        Write-Host "Please check the VM status in Azure Portal" -ForegroundColor Yellow
    } else {
        Write-Host "Hyper-V installation complete!" -ForegroundColor Green
    }
    
} catch {
    Write-Host "ERROR: Failed to enable Hyper-V: $_" -ForegroundColor Red
    exit 1
}
} # End of Hyper-V installation block

# ============================================
# 3. Create NAT Virtual Switch
# ============================================
Write-Host "`n[2/5] Creating NAT virtual switch..." -ForegroundColor Yellow
Write-Host "Note: NAT networking is required for nested VMs in Azure`n" -ForegroundColor Cyan

$createNatSwitchScript = @'
$ErrorActionPreference = 'Stop'

$SwitchName = "NAT-Switch"
$NATNetworkName = "NAT-Network"
$NATSubnet = "192.168.100.0/24"
$GatewayIP = "192.168.100.1"
$PrefixLength = 24

# Check if switch already exists
$existingSwitch = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
if ($existingSwitch) {
    Write-Host "NAT switch already exists: $SwitchName"
    exit 0
}

Write-Host "Creating Internal virtual switch: $SwitchName"
New-VMSwitch -Name $SwitchName -SwitchType Internal

# Get the adapter created for the internal switch
$adapter = Get-NetAdapter | Where-Object { $_.Name -like "*$SwitchName*" }
if (-not $adapter) {
    # Try alternative naming
    $adapter = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*Hyper-V Virtual Ethernet Adapter*" } | Select-Object -Last 1
}

if ($adapter) {
    Write-Host "Configuring IP address on adapter: $($adapter.Name)"
    New-NetIPAddress -IPAddress $GatewayIP -PrefixLength $PrefixLength -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
} else {
    Write-Host "WARNING: Could not find adapter for internal switch"
}

# Create NAT network
Write-Host "Creating NAT network: $NATNetworkName ($NATSubnet)"
$existingNat = Get-NetNat -Name $NATNetworkName -ErrorAction SilentlyContinue
if (-not $existingNat) {
    New-NetNat -Name $NATNetworkName -InternalIPInterfaceAddressPrefix $NATSubnet
    Write-Host "NAT network created successfully"
} else {
    Write-Host "NAT network already exists"
}

Write-Host "`nNAT Switch Configuration:"
Write-Host "  Switch: $SwitchName"
Write-Host "  Gateway: $GatewayIP"
Write-Host "  Subnet: $NATSubnet"
'@

try {
    $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
    $createNatSwitchScript | Out-File -FilePath $tempFile -Encoding ASCII

    $output = & az vm run-command invoke `
        --resource-group $ResourceGroupName `
        --name $VMName `
        --command-id RunPowerShellScript `
        --scripts "@$tempFile" `
        --output json 2>$null

    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

    $result = ($output | ConvertFrom-Json).value
    $stdOut = ($result | Where-Object { $_.code -like '*StdOut*' }).message
    $stdErr = ($result | Where-Object { $_.code -like '*StdErr*' }).message
    
    if ($stdOut) { Write-Host $stdOut -ForegroundColor Gray }
    if ($stdErr) { Write-Host $stdErr -ForegroundColor Yellow }
    
    Write-Host "NAT switch configuration complete!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to create NAT switch: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# 4. Configure DHCP Server
# ============================================
Write-Host "`n[3/5] Configuring DHCP server..." -ForegroundColor Yellow
Write-Host "Note: DHCP provides automatic IP addresses to nested VMs`n" -ForegroundColor Cyan

$configureDhcpScript = @'
$ErrorActionPreference = 'Stop'

$ScopeName = "NAT-Scope"
$ScopeId = "192.168.100.0"
$StartRange = "192.168.100.10"
$EndRange = "192.168.100.200"
$SubnetMask = "255.255.255.0"
$GatewayIP = "192.168.100.1"
$DnsServer = "168.63.129.16"  # Azure DNS

# Check if DHCP Server is already installed
$dhcpFeature = Get-WindowsFeature -Name DHCP
if (-not $dhcpFeature.Installed) {
    Write-Host "Installing DHCP Server feature..."
    Install-WindowsFeature -Name DHCP -IncludeManagementTools
    Write-Host "DHCP Server installed"
} else {
    Write-Host "DHCP Server already installed"
}

# Add DHCP Server to local security groups (required for standalone DHCP)
Write-Host "Configuring DHCP security groups..."
netsh dhcp add securitygroups 2>$null
Restart-Service dhcpserver -ErrorAction SilentlyContinue

# Check if scope already exists
$existingScope = Get-DhcpServerv4Scope -ScopeId $ScopeId -ErrorAction SilentlyContinue
if ($existingScope) {
    Write-Host "DHCP scope already exists: $ScopeName"
} else {
    Write-Host "Creating DHCP scope: $ScopeName ($StartRange - $EndRange)"
    Add-DhcpServerv4Scope -Name $ScopeName `
        -StartRange $StartRange `
        -EndRange $EndRange `
        -SubnetMask $SubnetMask `
        -State Active
    Write-Host "DHCP scope created"
}

# Configure scope options (gateway and DNS)
Write-Host "Configuring DHCP options..."
Set-DhcpServerv4OptionValue -ScopeId $ScopeId -Router $GatewayIP -ErrorAction SilentlyContinue
Set-DhcpServerv4OptionValue -ScopeId $ScopeId -DnsServer $DnsServer -ErrorAction SilentlyContinue
Write-Host "  Router (Gateway): $GatewayIP"
Write-Host "  DNS Server: $DnsServer (Azure DNS)"

# Authorize DHCP server in AD (skip if not domain-joined)
Write-Host "Skipping AD authorization (standalone server)"

# Set server to not require authorization (standalone mode)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12" -Name "ConfigurationState" -Value 2 -ErrorAction SilentlyContinue

Write-Host "`nDHCP Server Configuration:"
Write-Host "  Scope: $ScopeName"
Write-Host "  Range: $StartRange - $EndRange"
Write-Host "  Subnet: $SubnetMask"
Write-Host "  Gateway: $GatewayIP"
Write-Host "  DNS: $DnsServer"
Write-Host "`nNested VMs will automatically receive IP addresses via DHCP"
'@

try {
    $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
    $configureDhcpScript | Out-File -FilePath $tempFile -Encoding ASCII

    $output = & az vm run-command invoke `
        --resource-group $ResourceGroupName `
        --name $VMName `
        --command-id RunPowerShellScript `
        --scripts "@$tempFile" `
        --output json 2>$null

    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

    $result = ($output | ConvertFrom-Json).value
    $stdOut = ($result | Where-Object { $_.code -like '*StdOut*' }).message
    $stdErr = ($result | Where-Object { $_.code -like '*StdErr*' }).message
    
    if ($stdOut) { Write-Host $stdOut -ForegroundColor Gray }
    if ($stdErr) { Write-Host $stdErr -ForegroundColor Yellow }
    
    Write-Host "DHCP server configuration complete!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to configure DHCP server: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# 5. Configure Port Forwarding for Bastion Tunneling
# ============================================
Write-Host "`n[4/5] Configuring port forwarding for az-migrate appliance..." -ForegroundColor Yellow
Write-Host "Note: Enables RDP access via Bastion tunnel`n" -ForegroundColor Cyan

$configurePortForwardingScript = @'
$ErrorActionPreference = 'Stop'

# Port forwarding for az-migrate appliance (RDP)
# az-migrate gets 192.168.100.10 (first VM to request DHCP lease)
$ExternalPort = 33389
$InternalIP = "192.168.100.10"
$InternalPort = 3389

# Remove existing rule if present (suppress errors)
$null = netsh interface portproxy delete v4tov4 listenport=$ExternalPort listenaddress=0.0.0.0 2>&1

# Add port forwarding rule
$result = netsh interface portproxy add v4tov4 listenport=$ExternalPort listenaddress=0.0.0.0 connectport=$InternalPort connectaddress=$InternalIP
if ($LASTEXITCODE -eq 0) {
    Write-Host "Port forwarding: $ExternalPort -> ${InternalIP}:${InternalPort} (az-migrate RDP)"
} else {
    Write-Host "Warning: Port forwarding may not have been configured: $result"
}

# Enable firewall rule
Write-Host "`nConfiguring Windows Firewall..."
$ruleName = "Allow-Bastion-RDP-$ExternalPort"
Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -LocalPort $ExternalPort -Protocol TCP -Action Allow | Out-Null
Write-Host "  Firewall rule added: $ruleName"

Write-Host "`nPort Forwarding Configuration:"
Write-Host "  $ExternalPort -> ${InternalIP}:${InternalPort} (az-migrate RDP)"
Write-Host "`nUse Bastion tunnel to access az-migrate appliance:"
Write-Host "  az network bastion tunnel -n bastion-dc -g <rg> --target-resource-id <vm-dc-id> --resource-port $ExternalPort --port $ExternalPort"
Write-Host "  Then RDP to localhost:$ExternalPort"
'@

try {
    $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
    $configurePortForwardingScript | Out-File -FilePath $tempFile -Encoding ASCII

    $output = & az vm run-command invoke `
        --resource-group $ResourceGroupName `
        --name $VMName `
        --command-id RunPowerShellScript `
        --scripts "@$tempFile" `
        --output json 2>$null

    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

    $result = ($output | ConvertFrom-Json).value
    $stdOut = ($result | Where-Object { $_.code -like '*StdOut*' }).message
    $stdErr = ($result | Where-Object { $_.code -like '*StdErr*' }).message
    
    if ($stdOut) { Write-Host $stdOut -ForegroundColor Gray }
    if ($stdErr) { Write-Host $stdErr -ForegroundColor Yellow }
    
    Write-Host "Port forwarding configuration complete!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to configure port forwarding: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# 6. Download and install ASR Provider (DRA) on DC VM
# ============================================
Write-Host "`n[5/5] Installing Azure Site Recovery Provider..." -ForegroundColor Yellow
Write-Host "Downloading from https://aka.ms/downloaddra`n" -ForegroundColor Gray

$installDraScript = @'
$ErrorActionPreference = 'Stop'

$downloadUrl = "https://aka.ms/downloaddra"
$installerPath = "C:\dc-files\AzureSiteRecoveryProvider.exe"
$extractPath = "C:\dc-files\ASRProvider"

# Check if already installed
$installed = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like '*Azure Site Recovery*' -or $_.Name -like '*Microsoft Azure Site Recovery*' }
if ($installed) {
    Write-Host "Azure Site Recovery Provider is already installed: $($installed.Name)"
    exit 0
}

# Ensure directory exists
if (-not (Test-Path "C:\dc-files")) {
    New-Item -ItemType Directory -Path "C:\dc-files" -Force | Out-Null
}

# Download
if (-not (Test-Path $installerPath)) {
    Write-Host "Downloading ASR Provider..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
        Write-Host "Download complete: $installerPath (Size: $((Get-Item $installerPath).Length) bytes)"
    } catch {
        Write-Host "ERROR: Download failed - $_"
        exit 1
    }
} else {
    Write-Host "Installer already downloaded: $installerPath"
}

# Verify download
if (-not (Test-Path $installerPath) -or (Get-Item $installerPath).Length -lt 1000000) {
    Write-Host "ERROR: Downloaded file is missing or too small"
    exit 1
}

# Extract
if (-not (Test-Path $extractPath)) {
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
}
Write-Host "Extracting installer to $extractPath..."
$extractResult = Start-Process -FilePath $installerPath -ArgumentList "/x:$extractPath", "/q" -Wait -PassThru
Write-Host "Extraction exit code: $($extractResult.ExitCode)"
Start-Sleep -Seconds 15

# List extracted files for debugging
Write-Host "Extracted files:"
Get-ChildItem -Path $extractPath -Recurse | ForEach-Object { Write-Host "  $($_.FullName)" }

# Install silently - look for the provider setup
$setupExe = Get-ChildItem -Path $extractPath -Filter "setupdr.exe" -Recurse | Select-Object -First 1
if (-not $setupExe) {
    # Try alternative installer names
    $setupExe = Get-ChildItem -Path $extractPath -Filter "*.exe" -Recurse | Where-Object { $_.Name -like "*setup*" -or $_.Name -like "*install*" } | Select-Object -First 1
}
if (-not $setupExe) {
    Write-Host "ERROR: Setup executable not found in $extractPath"
    Write-Host "Available executables:"
    Get-ChildItem -Path $extractPath -Filter "*.exe" -Recurse | ForEach-Object { Write-Host "  $($_.Name)" }
    exit 1
}

Write-Host "Installing ASR Provider using: $($setupExe.FullName)"
$installResult = Start-Process -FilePath $setupExe.FullName -ArgumentList "/i", "/q" -Wait -PassThru
Write-Host "Installation exit code: $($installResult.ExitCode)"

# Wait for installation to complete
$maxWait = 300
$waited = 0
while ($waited -lt $maxWait) {
    Start-Sleep -Seconds 10
    $waited += 10
    $check = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like '*Azure Site Recovery*' -or $_.Name -like '*Microsoft Azure Site Recovery*' }
    if ($check) {
        Write-Host "ASR Provider installed successfully: $($check.Name)"
        exit 0
    }
    Write-Host "  Waiting for installation... ($waited s)"
}

Write-Host "WARNING: Installation may still be in progress or failed"
exit 1
'@

$tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
try {
    $installDraScript | Out-File -FilePath $tempFile -Encoding ASCII

    Write-Host "Running ASR installation on remote VM (this may take several minutes)..." -ForegroundColor Gray
    
    $output = & az vm run-command invoke `
        --resource-group $ResourceGroupName `
        --name $VMName `
        --command-id RunPowerShellScript `
        --scripts "@$tempFile" `
        --output json 2>&1

    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

    if (-not $output) {
        Write-Host "WARNING: No output received from remote command" -ForegroundColor Yellow
        Write-Host "You can install manually by downloading from https://aka.ms/downloaddra" -ForegroundColor Yellow
    } else {
        try {
            $result = ($output | ConvertFrom-Json).value
            $stdOut = ($result | Where-Object { $_.code -like '*StdOut*' }).message
            $stdErr = ($result | Where-Object { $_.code -like '*StdErr*' }).message

            if ($stdOut) { 
                Write-Host "Remote output:" -ForegroundColor Gray
                Write-Host $stdOut -ForegroundColor Gray 
            }
            if ($stdErr -and $stdErr.Trim()) { Write-Host "Stderr: $stdErr" -ForegroundColor Yellow }

            # Check if installation actually succeeded by looking for success message or error
            if ($stdOut -match "installed successfully" -or $stdOut -match "already installed") {
                Write-Host "ASR Provider installation complete!" -ForegroundColor Green
            } elseif ($stdOut -match "ERROR:" -or $stdOut -match "not found") {
                Write-Host "WARNING: ASR Provider installation failed - check output above" -ForegroundColor Yellow
                Write-Host "You can install manually by downloading from https://aka.ms/downloaddra" -ForegroundColor Yellow
            } else {
                Write-Host "WARNING: ASR Provider installation status unclear - verify manually" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Raw output from az command:" -ForegroundColor Yellow
            Write-Host $output -ForegroundColor Gray
            Write-Host "WARNING: Could not parse command output" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "WARNING: ASR Provider installation failed: $_" -ForegroundColor Yellow
    Write-Host "You can install manually by downloading from https://aka.ms/downloaddra" -ForegroundColor Yellow
}

# ============================================
# Summary
# ============================================
Write-Host "`n=== Preparation Complete ===" -ForegroundColor Yellow
Write-Host "Hyper-V is now enabled on the DC VM" -ForegroundColor Cyan
Write-Host "NAT switch configured for nested VM internet access" -ForegroundColor Cyan
Write-Host "DHCP server configured for automatic IP assignment" -ForegroundColor Cyan
Write-Host "Port forwarding configured for az-migrate RDP (port 33389)" -ForegroundColor Cyan
Write-Host "Azure Site Recovery Provider installed" -ForegroundColor Cyan
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Run 03-deploy-azure-migrate.ps1 to deploy Azure Migrate" -ForegroundColor Cyan
Write-Host "2. Run 04-deploy-webapp.ps1 to deploy the Webapp VM" -ForegroundColor Cyan
Write-Host "3. Run 05-deploy-ubuntu.ps1 to deploy the Ubuntu VM" -ForegroundColor Cyan
Write-Host ""

exit 0

