# Azure Migration Workshop - Prepare DC VM
# This script enables Hyper-V, creates NAT networking, and configures DHCP
# for nested virtualization in Azure

param(
    [string]$ResourceGroupName,
    [string]$VMName = "vm-dc"
)

$ErrorActionPreference = "Stop"

# Read config from dc-infra\main.bicepparam (single source of truth)
$bicepParamFile = Join-Path $PSScriptRoot "dc-infra\main.bicepparam"
$bicepContent = Get-Content $bicepParamFile -Raw
if (-not $ResourceGroupName) { $ResourceGroupName = [regex]::Match($bicepContent, "param resourceGroupName = '([^']+)'").Groups[1].Value }

Write-Host "`n=== Azure Migration Workshop - Prepare DC VM ===" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "VM Name: $VMName`n" -ForegroundColor Cyan

# ============================================
# 1. Check if Hyper-V is already enabled
# ============================================
Write-Host "[1/6] Checking if Hyper-V is already installed..." -ForegroundColor Yellow

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
Write-Host "`n[1/6] Enabling Hyper-V on VM..." -ForegroundColor Yellow
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
Write-Host "`n[2/6] Creating NAT virtual switch..." -ForegroundColor Yellow
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
} else {
    Write-Host "Creating Internal virtual switch: $SwitchName"
    New-VMSwitch -Name $SwitchName -SwitchType Internal
}

# Get the adapter for the internal switch
$adapter = Get-NetAdapter | Where-Object { $_.Name -like "*$SwitchName*" }
if (-not $adapter) {
    # Try alternative naming
    $adapter = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*Hyper-V Virtual Ethernet Adapter*" } | Select-Object -Last 1
}

if ($adapter) {
    Write-Host "Configuring IP address on adapter: $($adapter.Name)"
    New-NetIPAddress -IPAddress $GatewayIP -PrefixLength $PrefixLength -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
    
    # Enable IP forwarding so nested VM traffic is routed through NAT
    Set-NetIPInterface -InterfaceIndex $adapter.ifIndex -Forwarding Enabled
    Write-Host "IP forwarding enabled on adapter: $($adapter.Name)"
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
Write-Host "`n[3/6] Configuring DHCP server..." -ForegroundColor Yellow
Write-Host "Note: DHCP provides automatic IP addresses to nested VMs`n" -ForegroundColor Cyan

$configureDhcpScript = @'
$ErrorActionPreference = 'Stop'

$ScopeName = "NAT-Scope"
$ScopeId = "192.168.100.0"
$StartRange = "192.168.100.10"
$EndRange = "192.168.100.200"
$SubnetMask = "255.255.255.0"
$GatewayIP = "192.168.100.1"
$DnsServer = "192.168.100.20"  # ADDS VM (Domain Controller / DNS Server)

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
Set-DhcpServerv4OptionValue -ScopeId $ScopeId -DnsDomain "migrate.local" -DnsServer $DnsServer -Force -ErrorAction Stop
Write-Host "  Router (Gateway): $GatewayIP"
Write-Host "  DNS Server: $DnsServer (ADDS VM - Domain Controller)"

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
# 5. Configure Port Forwarding for Bastion Tunneling & DMS
# ============================================
Write-Host "`n[4/6] Configuring port forwarding..." -ForegroundColor Yellow
Write-Host "Note: Enables RDP access via Bastion tunnel and PostgreSQL access for DMS`n" -ForegroundColor Cyan

$configurePortForwardingScript = @'
$ErrorActionPreference = 'Stop'

# IP Helper service is required for netsh interface portproxy to function
Set-Service -Name iphlpsvc -StartupType Automatic
Start-Service -Name iphlpsvc

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

# Port forwarding for webapp-vm PostgreSQL (for Azure Database Migration Service)
# webapp-vm gets 192.168.100.30 via DHCP reservation
$PgExternalPort = 5432
$PgInternalIP = "192.168.100.30"
$PgInternalPort = 5432

$null = netsh interface portproxy delete v4tov4 listenport=$PgExternalPort listenaddress=0.0.0.0 2>&1
$result = netsh interface portproxy add v4tov4 listenport=$PgExternalPort listenaddress=0.0.0.0 connectport=$PgInternalPort connectaddress=$PgInternalIP
if ($LASTEXITCODE -eq 0) {
    Write-Host "Port forwarding: $PgExternalPort -> ${PgInternalIP}:${PgInternalPort} (webapp-vm PostgreSQL)"
} else {
    Write-Host "Warning: PostgreSQL port forwarding may not have been configured: $result"
}

$pgRuleName = "Allow-PostgreSQL-$PgExternalPort"
Remove-NetFirewallRule -DisplayName $pgRuleName -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName $pgRuleName -Direction Inbound -LocalPort $PgExternalPort -Protocol TCP -Action Allow | Out-Null
Write-Host "  Firewall rule added: $pgRuleName"

Write-Host "`nPort Forwarding Configuration:"
Write-Host "  $ExternalPort -> ${InternalIP}:${InternalPort} (az-migrate RDP)"
Write-Host "  $PgExternalPort -> ${PgInternalIP}:${PgInternalPort} (webapp-vm PostgreSQL)"
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
# 6. Configure WinRM for Azure Migrate Discovery
# ============================================
Write-Host "`n[5/6] Configuring WinRM for Azure Migrate communication..." -ForegroundColor Yellow
Write-Host "Note: Azure Migrate appliance uses WinRM to discover and assess VMs`n" -ForegroundColor Cyan

$configureWinRMScript = @'
$ErrorActionPreference = 'Stop'

# Enable WinRM service
Write-Host "Enabling WinRM service..."
Enable-PSRemoting -Force -SkipNetworkProfileCheck

# Configure WinRM to listen on all interfaces
Write-Host "Configuring WinRM listeners..."
winrm quickconfig -quiet -force

# Set WinRM service to automatic startup
Set-Service -Name WinRM -StartupType Automatic
Start-Service -Name WinRM

# Configure TrustedHosts to allow connections from NAT network
Write-Host "Configuring TrustedHosts for NAT network (192.168.100.0/24)..."
$currentTrustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value
if ($currentTrustedHosts -eq "") {
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value "192.168.100.*" -Force
} elseif ($currentTrustedHosts -notlike "*192.168.100.*") {
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$currentTrustedHosts,192.168.100.*" -Force
}
Write-Host "  TrustedHosts: $(Get-Item WSMan:\localhost\Client\TrustedHosts | Select-Object -ExpandProperty Value)"

# Enable CredSSP for Azure Migrate (allows credential delegation)
Write-Host "Enabling CredSSP authentication..."
Enable-WSManCredSSP -Role Server -Force | Out-Null
Write-Host "  CredSSP Server enabled"

# Configure firewall rules for WinRM from NAT network
Write-Host "`nConfiguring Windows Firewall for WinRM..."

# Remove existing rules if present
Remove-NetFirewallRule -DisplayName "WinRM-HTTP-NAT-In" -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName "WinRM-HTTPS-NAT-In" -ErrorAction SilentlyContinue

# Add firewall rules for NAT network only
New-NetFirewallRule -DisplayName "WinRM-HTTP-NAT-In" `
    -Direction Inbound `
    -LocalPort 5985 `
    -Protocol TCP `
    -Action Allow `
    -RemoteAddress "192.168.100.0/24" `
    -Profile Any | Out-Null
Write-Host "  Firewall rule added: WinRM-HTTP-NAT-In (port 5985)"

New-NetFirewallRule -DisplayName "WinRM-HTTPS-NAT-In" `
    -Direction Inbound `
    -LocalPort 5986 `
    -Protocol TCP `
    -Action Allow `
    -RemoteAddress "192.168.100.0/24" `
    -Profile Any | Out-Null
Write-Host "  Firewall rule added: WinRM-HTTPS-NAT-In (port 5986)"

# Increase MaxMemoryPerShellMB for large operations
Write-Host "Configuring WinRM memory limits..."
Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB -Value 2048 -Force
Write-Host "  MaxMemoryPerShellMB: 2048"

# Test WinRM configuration
Write-Host "`nTesting WinRM configuration..."
$winrmStatus = Test-WSMan -ComputerName localhost
if ($winrmStatus) {
    Write-Host "  WinRM is responding correctly" -ForegroundColor Green
}

Write-Host "`nWinRM Configuration Complete:"
Write-Host "  Service: Running (Automatic)"
Write-Host "  HTTP Port: 5985"
Write-Host "  HTTPS Port: 5986"
Write-Host "  Allowed Network: 192.168.100.0/24 (NAT network)"
Write-Host "  CredSSP: Enabled"
Write-Host "  TrustedHosts: $(Get-Item WSMan:\localhost\Client\TrustedHosts | Select-Object -ExpandProperty Value)"
Write-Host "`nAzure Migrate appliance can now connect to this host via WinRM"
'@

try {
    $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
    $configureWinRMScript | Out-File -FilePath $tempFile -Encoding ASCII

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
    
    Write-Host "WinRM configuration complete!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to configure WinRM: $_" -ForegroundColor Red
    Write-Host "You may need to configure WinRM manually" -ForegroundColor Yellow
    # Don't exit - WinRM is important but not critical for basic setup
}

# ============================================
# Summary
# ============================================
Write-Host "`n=== Preparation Complete ===" -ForegroundColor Yellow
Write-Host "Hyper-V is now enabled on the DC VM" -ForegroundColor Cyan
Write-Host "NAT switch configured for nested VM internet access" -ForegroundColor Cyan
Write-Host "DHCP server configured for automatic IP assignment" -ForegroundColor Cyan
Write-Host "Port forwarding configured for az-migrate RDP (port 33389) and PostgreSQL (port 5432)" -ForegroundColor Cyan
Write-Host "WinRM configured for Azure Migrate discovery and assessment" -ForegroundColor Cyan
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Run 03-deploy-adds.ps1 to deploy the ADDS VM (DNS server)" -ForegroundColor Cyan
Write-Host "2. Run 04-deploy-azure-migrate.ps1 to deploy Azure Migrate appliance" -ForegroundColor Cyan
Write-Host "3. Verify DNS resolution via ADDS VM before deploying Ubuntu VMs" -ForegroundColor Cyan
Write-Host "4. Run 05-deploy-webapp.ps1 to deploy the Webapp VM" -ForegroundColor Cyan
Write-Host "5. Run 06-deploy-ubuntu.ps1 to deploy the Ubuntu VM" -ForegroundColor Cyan
Write-Host ""

exit 0

