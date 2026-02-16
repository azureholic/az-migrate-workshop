# Create Ubuntu Webapp VM in Hyper-V with Fully Unattended Setup
# This script runs on the DC VM
# Uses Gen 2 VM (UEFI boot) with a pre-built autoinstall ISO.
# Secure boot is disabled for Ubuntu compatibility.

param(
    [string]$VMName = "webapp-vm",
    [string]$IsoPath = "C:\dc-files\ubuntu-24.04.3-webapp-autoinstall.iso",
    [string]$VMPath = "C:\VMs",
    [string]$VHDPath = "C:\VMs\webapp-vm\webapp-vm.vhdx",
    [int64]$VHDSize = 50GB,
    [int64]$MemoryStartupBytes = 4GB,
    [int]$ProcessorCount = 2,
    [string]$SwitchName = "NAT-Switch"
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Create Ubuntu Webapp VM in Hyper-V ===" -ForegroundColor Yellow
Write-Host "VM Name: $VMName" -ForegroundColor Cyan
Write-Host "ISO: $IsoPath" -ForegroundColor Cyan
Write-Host "VM Path: $VMPath`n" -ForegroundColor Cyan

# ============================================
# 1. Verify Prerequisites
# ============================================
Write-Host "[1/6] Verifying prerequisites..." -ForegroundColor Yellow

# Check if Hyper-V is enabled
try {
    $hyperv = Get-WindowsFeature -Name Hyper-V
    if (-not $hyperv.Installed) {
        Write-Host "ERROR: Hyper-V is not installed!" -ForegroundColor Red
        Write-Host "Please run 02-prep-dc.ps1 first" -ForegroundColor Cyan
        exit 1
    }
    Write-Host "Hyper-V is installed" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Cannot check Hyper-V status: $_" -ForegroundColor Red
    exit 1
}

# Check if Ubuntu ISO exists
if (-not (Test-Path $IsoPath)) {
    Write-Host "ERROR: Ubuntu Webapp ISO not found: $IsoPath" -ForegroundColor Red
    Write-Host "Please run 01-download-iso.ps1 first" -ForegroundColor Cyan
    exit 1
}
Write-Host "Ubuntu Webapp ISO found: $IsoPath" -ForegroundColor Green

# ============================================
# 2. Create VM Directory
# ============================================
Write-Host "`n[2/6] Creating VM directory..." -ForegroundColor Yellow

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
Write-Host "`n[3/6] Verifying NAT virtual switch..." -ForegroundColor Yellow

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
Write-Host "`n[4/6] Creating virtual machine..." -ForegroundColor Yellow

# Check if VM already exists
$existingVM = Get-VM -Name $VMName -ErrorAction SilentlyContinue

if ($existingVM) {
    Write-Host "ERROR: VM already exists: $VMName" -ForegroundColor Red
    Write-Host "Current state: $($existingVM.State)" -ForegroundColor Yellow
    Write-Host "Please remove the existing VM first or use a different name" -ForegroundColor Cyan
    exit 1
}

# Create the VM (Gen 2 for UEFI boot - required for modern Ubuntu)
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
Write-Host "`n[5/6] Configuring VM settings..." -ForegroundColor Yellow

# Set processor count
Set-VMProcessor -VMName $VMName -Count $ProcessorCount
Write-Host "Processors: $ProcessorCount" -ForegroundColor Gray

# Enable dynamic memory
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true -MinimumBytes 2GB -MaximumBytes $MemoryStartupBytes
Write-Host "Memory: Dynamic (2GB - $([math]::Round($MemoryStartupBytes/1GB))GB)" -ForegroundColor Gray

# Disable Secure Boot for Ubuntu (use Microsoft UEFI CA for third-party OS)
Set-VMFirmware -VMName $VMName -EnableSecureBoot Off
Write-Host "Secure Boot: Disabled (for Ubuntu compatibility)" -ForegroundColor Gray

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

# ============================================
# 6. Start VM
# ============================================
Write-Host "`n[6/6] Starting VM..." -ForegroundColor Yellow

Start-VM -Name $VMName
Write-Host "VM started successfully!" -ForegroundColor Green

# Wait a moment and check status
Start-Sleep -Seconds 3
$vm = Get-VM -Name $VMName
Write-Host "`nVM Status: $($vm.State)" -ForegroundColor Cyan
Write-Host "Uptime: $($vm.Uptime)" -ForegroundColor Gray

# ============================================
# Summary
# ============================================
Write-Host "`n=== VM Creation Complete ===" -ForegroundColor Yellow
Write-Host "VM Details:" -ForegroundColor Cyan
Write-Host "  Name: $VMName" -ForegroundColor Gray
Write-Host "  Generation: 2 (UEFI, Secure Boot Off)" -ForegroundColor Gray
Write-Host "  State: $($vm.State)" -ForegroundColor Gray
Write-Host "  CPUs: $ProcessorCount" -ForegroundColor Gray
Write-Host "  Memory: $([math]::Round($MemoryStartupBytes/1GB))GB" -ForegroundColor Gray
Write-Host "  VHD: $VHDPath ($([math]::Round($VHDSize/1GB))GB)" -ForegroundColor Gray
Write-Host "  Switch: $SwitchName" -ForegroundColor Gray
Write-Host "  ISO: $IsoPath" -ForegroundColor Gray

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. The VM boots from the autoinstall ISO" -ForegroundColor Cyan
Write-Host "2. Fully unattended installation runs automatically" -ForegroundColor Cyan
Write-Host "3. Installation typically takes 10-15 minutes" -ForegroundColor Cyan
Write-Host "4. After installation, the VM will reboot automatically" -ForegroundColor Cyan
Write-Host "5. Remove the ISO from DVD drive after the first reboot" -ForegroundColor Cyan
Write-Host ""
