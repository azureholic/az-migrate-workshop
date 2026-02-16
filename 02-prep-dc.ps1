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
Write-Host "[1/4] Checking if Hyper-V is already installed..." -ForegroundColor Yellow

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
Write-Host "`n[1/4] Enabling Hyper-V on VM..." -ForegroundColor Yellow
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
Write-Host "`n[2/4] Creating NAT virtual switch..." -ForegroundColor Yellow
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
Write-Host "`n[3/4] Configuring DHCP server..." -ForegroundColor Yellow
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
Write-Host "`n[4/4] Configuring port forwarding for az-migrate appliance..." -ForegroundColor Yellow
Write-Host "Note: Enables RDP access via Bastion tunnel`n" -ForegroundColor Cyan

$configurePortForwardingScript = @'
$ErrorActionPreference = 'Stop'

# Port forwarding for az-migrate appliance (RDP)
# az-migrate typically gets 192.168.100.11 (second VM after ubuntu gets .10)
$ExternalPort = 33389
$InternalIP = "192.168.100.11"
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
# Summary
# ============================================
Write-Host "`n=== Preparation Complete ===" -ForegroundColor Yellow
Write-Host "Hyper-V is now enabled on the DC VM" -ForegroundColor Cyan
Write-Host "NAT switch configured for nested VM internet access" -ForegroundColor Cyan
Write-Host "DHCP server configured for automatic IP assignment" -ForegroundColor Cyan
Write-Host "Port forwarding configured for az-migrate RDP (port 33389)" -ForegroundColor Cyan
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Run 03-deploy-ubuntu.ps1 to deploy the Ubuntu VM" -ForegroundColor Cyan
Write-Host "2. Run 04-deploy-azure-migrate.ps1 to deploy Azure Migrate" -ForegroundColor Cyan
Write-Host ""

