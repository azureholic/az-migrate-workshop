# Create Windows Server 2019 ADDS VM in Hyper-V
# This script runs on the DC VM
# Uses Gen 2 VM (UEFI boot) with Secure Boot enabled
# The autoinstall ISO will configure Windows Server 2019 as a Domain Controller

param(
    [string]$VMName = "adds-vm",
    [string]$IsoPath = "C:\dc-files\windows-server-2019-adds-autoinstall.iso",
    [string]$VMPath = "C:\VMs",
    [string]$VHDPath = "C:\VMs\adds-vm\adds-vm.vhdx",
    [int64]$VHDSize = 80GB,
    [int64]$MemoryStartupBytes = 4GB,
    [int]$ProcessorCount = 2,
    [string]$SwitchName = "NAT-Switch",
    [string]$StaticIP = "192.168.100.20"
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Create Windows Server 2019 ADDS VM in Hyper-V ===" -ForegroundColor Yellow
Write-Host "VM Name: $VMName" -ForegroundColor Cyan
Write-Host "ISO: $IsoPath" -ForegroundColor Cyan
Write-Host "VM Path: $VMPath`n" -ForegroundColor Cyan

# ============================================
# 1. Verify Prerequisites
# ============================================
Write-Host "[1/7] Verifying prerequisites..." -ForegroundColor Yellow

# Check if Hyper-V is enabled
try {
    $hyperv = Get-WindowsFeature -Name Hyper-V
    if (-not $hyperv.Installed) {
        Write-Host "ERROR: Hyper-V is not installed!" -ForegroundColor Red
        Write-Host "Please run 03-enable-hyperv.ps1 first" -ForegroundColor Cyan
        exit 1
    }
    Write-Host "Hyper-V is installed" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Cannot check Hyper-V status: $_" -ForegroundColor Red
    exit 1
}

# Check if Windows Server ISO exists
if (-not (Test-Path $IsoPath)) {
    Write-Host "ERROR: Windows Server ISO not found: $IsoPath" -ForegroundColor Red
    Write-Host "Please run 01-download-iso.ps1 first" -ForegroundColor Cyan
    exit 1
}
Write-Host "Windows Server ISO found: $IsoPath" -ForegroundColor Green

# ============================================
# 2. Create VM Directory
# ============================================
Write-Host "`n[2/7] Creating VM directory..." -ForegroundColor Yellow

$vmDir = Split-Path $VHDPath -Parent
if (Test-Path $vmDir) {
    Write-Host "Removing existing directory: $vmDir" -ForegroundColor Yellow
    Remove-Item -Path $vmDir -Recurse -Force
}
New-Item -ItemType Directory -Path $vmDir -Force | Out-Null
Write-Host "Created directory: $vmDir" -ForegroundColor Green

# ============================================
# 3. Verify NAT Virtual Switch
# ============================================
Write-Host "`n[3/7] Verifying NAT virtual switch..." -ForegroundColor Yellow

# NAT switch should be created by 02-prep-dc.ps1
$existingSwitch = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue

if ($existingSwitch) {
    Write-Host "NAT switch found: $SwitchName" -ForegroundColor Green
    Write-Host "  Type: $($existingSwitch.SwitchType)" -ForegroundColor Gray
} else {
    Write-Host "ERROR: NAT switch not found: $SwitchName" -ForegroundColor Red
    Write-Host "Please ensure 02-prep-dc.ps1 was run successfully" -ForegroundColor Yellow
    exit 1
}

# ============================================
# 4. Create VM
# ============================================
Write-Host "`n[4/7] Creating virtual machine..." -ForegroundColor Yellow

# Check if VM already exists
$existingVM = Get-VM -Name $VMName -ErrorAction SilentlyContinue

if ($existingVM) {
    Write-Host "ERROR: VM already exists: $VMName" -ForegroundColor Red
    Write-Host "Current state: $($existingVM.State)" -ForegroundColor Yellow
    Write-Host "Please remove the existing VM first or use a different name" -ForegroundColor Cyan
    exit 1
}

# Create the VM (Gen 2 for UEFI boot with Secure Boot)
Write-Host "Creating VM: $VMName (Generation 2)" -ForegroundColor Cyan

New-VM -Name $VMName `
    -MemoryStartupBytes $MemoryStartupBytes `
    -Generation 2 `
    -NewVHDPath $VHDPath `
    -NewVHDSizeBytes $VHDSize `
    -SwitchName $SwitchName `
    -Path $VMPath

Write-Host "VM created successfully" -ForegroundColor Green

# ============================================
# 5. Configure VM Settings
# ============================================
Write-Host "`n[5/7] Configuring VM settings..." -ForegroundColor Yellow

# Set processor count
Set-VMProcessor -VMName $VMName -Count $ProcessorCount
Write-Host "Processors: $ProcessorCount" -ForegroundColor Gray

# Enable dynamic memory
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true -MinimumBytes 2GB -MaximumBytes $MemoryStartupBytes
Write-Host "Memory: Dynamic (2GB - $([math]::Round($MemoryStartupBytes/1GB))GB)" -ForegroundColor Gray

# Enable Secure Boot with Microsoft Windows template (required for Windows Server)
Set-VMFirmware -VMName $VMName -EnableSecureBoot On -SecureBootTemplate "MicrosoftWindows"
Write-Host "Secure Boot: Enabled (Microsoft Windows template)" -ForegroundColor Gray

# Add DVD drive and attach the autoinstall ISO (Gen 2 VMs don't have DVD by default)
Add-VMDvdDrive -VMName $VMName -Path $IsoPath
Write-Host "Autoinstall ISO attached to DVD" -ForegroundColor Gray

# Set boot order: DVD first
$bootDvd = Get-VMDvdDrive -VMName $VMName
Set-VMFirmware -VMName $VMName -FirstBootDevice $bootDvd
Write-Host "Boot order: DVD first" -ForegroundColor Gray

# Enable guest services (for integration)
Enable-VMIntegrationService -VMName $VMName -Name "Guest Service Interface"
Write-Host "Guest services enabled" -ForegroundColor Gray

# Enable TPM for additional security (optional but recommended for Windows Server)
try {
    Set-VMKeyProtector -VMName $VMName -NewLocalKeyProtector
    Enable-VMTPM -VMName $VMName
    Write-Host "TPM: Enabled" -ForegroundColor Gray
} catch {
    Write-Host "TPM: Not available (continuing without TPM)" -ForegroundColor Yellow
}

# ============================================
# 6. Start VM
# ============================================
Write-Host "`n[6/7] Starting VM..." -ForegroundColor Yellow

Start-VM -Name $VMName
Write-Host "VM started successfully!" -ForegroundColor Green

# Wait a moment and check status
Start-Sleep -Seconds 3
$vm = Get-VM -Name $VMName
Write-Host "`nVM Status: $($vm.State)" -ForegroundColor Cyan
Write-Host "Uptime: $($vm.Uptime)" -ForegroundColor Gray

# ============================================
# 7. Configure DHCP Reservation
# ============================================
Write-Host "`n[7/7] Configuring DHCP reservation for static IP..." -ForegroundColor Yellow
try {
    $vmNetAdapter = Get-VMNetworkAdapter -VMName $VMName
    $macAddress = $vmNetAdapter.MacAddress -replace '(..)(..)(..)(..)(..)(..)','$1-$2-$3-$4-$5-$6'
    
    # Remove existing reservation if present
    Get-DhcpServerv4Reservation -ScopeId 192.168.100.0 -ErrorAction SilentlyContinue | 
        Where-Object { $_.IPAddress -eq $StaticIP -or $_.ClientId -eq $macAddress } |
        Remove-DhcpServerv4Reservation -ErrorAction SilentlyContinue
    
    # Add new reservation
    Add-DhcpServerv4Reservation -ScopeId 192.168.100.0 -IPAddress $StaticIP -ClientId $macAddress -Name $VMName -Description "Windows Server 2019 Domain Controller"
    Write-Host "DHCP reservation added: $VMName -> $StaticIP (MAC: $macAddress)" -ForegroundColor Green
} catch {
    Write-Host "WARNING: Could not add DHCP reservation: $_" -ForegroundColor Yellow
    Write-Host "VM will use dynamic IP from DHCP" -ForegroundColor Yellow
}

# ============================================
# Summary
# ============================================
Write-Host "`n=== VM Creation Complete ===" -ForegroundColor Yellow
Write-Host "VM Details:" -ForegroundColor Cyan
Write-Host "  Name: $VMName" -ForegroundColor Gray
Write-Host "  Generation: 2 (UEFI, Secure Boot On)" -ForegroundColor Gray
Write-Host "  State: $($vm.State)" -ForegroundColor Gray
Write-Host "  CPUs: $ProcessorCount" -ForegroundColor Gray
Write-Host "  Memory: $([math]::Round($MemoryStartupBytes/1GB))GB" -ForegroundColor Gray
Write-Host "  VHD: $VHDPath ($([math]::Round($VHDSize/1GB))GB)" -ForegroundColor Gray
Write-Host "  Switch: $SwitchName" -ForegroundColor Gray
Write-Host "  Static IP: $StaticIP (via DHCP reservation)" -ForegroundColor Gray
Write-Host "  ISO: $IsoPath" -ForegroundColor Gray

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. The VM boots from the autoinstall ISO" -ForegroundColor Cyan
Write-Host "2. Windows Server 2019 installation runs automatically" -ForegroundColor Cyan
Write-Host "3. Active Directory Domain Services will be configured" -ForegroundColor Cyan
Write-Host "4. Installation typically takes 15-30 minutes" -ForegroundColor Cyan
Write-Host "5. After installation, the VM will reboot and become a Domain Controller" -ForegroundColor Cyan
Write-Host "6. Remove the ISO from DVD drive after the first reboot" -ForegroundColor Cyan
Write-Host ""
