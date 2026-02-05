# Create Ubuntu VM in Hyper-V with Unattended Setup
# This script runs on the DC VM

param(
    [string]$VMName = "ubuntu-vm",
    [string]$IsoPath = "C:\dc-files\ubuntu-20.04.6-live-server-amd64.iso",
    [string]$SeedIsoPath = "C:\dc-files\ubuntu-seed.iso",
    [string]$VMPath = "C:\VMs",
    [string]$VHDPath = "C:\VMs\ubuntu-vm\ubuntu-vm.vhdx",
    [int64]$VHDSize = 50GB,
    [int64]$MemoryStartupBytes = 4GB,
    [int]$ProcessorCount = 2,
    [string]$SwitchName = "External-Switch"
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Create Ubuntu VM in Hyper-V ===" -ForegroundColor Yellow
Write-Host "VM Name: $VMName" -ForegroundColor Cyan
Write-Host "Ubuntu ISO: $IsoPath" -ForegroundColor Cyan
Write-Host "Seed ISO: $SeedIsoPath" -ForegroundColor Cyan
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
        Write-Host "Please run 03-enable-hyperv.ps1 first" -ForegroundColor Cyan
        exit 1
    }
    Write-Host "Hyper-V is installed" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Cannot check Hyper-V status: $_" -ForegroundColor Red
    exit 1
}

# Check if ISOs exist
if (-not (Test-Path $IsoPath)) {
    Write-Host "ERROR: Ubuntu ISO not found: $IsoPath" -ForegroundColor Red
    Write-Host "Please run 01-download-iso.ps1 first" -ForegroundColor Cyan
    exit 1
}
Write-Host "Ubuntu ISO found: $IsoPath" -ForegroundColor Green

if (-not (Test-Path $SeedIsoPath)) {
    Write-Host "ERROR: Seed ISO not found: $SeedIsoPath" -ForegroundColor Red
    Write-Host "Please ensure ubuntu-seed.iso is uploaded to C:\dc-files" -ForegroundColor Cyan
    exit 1
}
Write-Host "Seed ISO found: $SeedIsoPath" -ForegroundColor Green

# ============================================
# 2. Create VM Directory
# ============================================
Write-Host "`n[2/6] Creating VM directory..." -ForegroundColor Yellow

$vmDir = Split-Path $VHDPath -Parent
if (-not (Test-Path $vmDir)) {
    New-Item -ItemType Directory -Path $vmDir -Force | Out-Null
    Write-Host "Created directory: $vmDir" -ForegroundColor Green
} else {
    Write-Host "Directory already exists: $vmDir" -ForegroundColor Gray
}

# ============================================
# 3. Create Virtual Switch
# ============================================
Write-Host "`n[3/6] Configuring virtual switch..." -ForegroundColor Yellow

# Check if switch exists
$existingSwitch = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue

if ($existingSwitch) {
    Write-Host "Virtual switch already exists: $SwitchName" -ForegroundColor Gray
    Write-Host "  Type: $($existingSwitch.SwitchType)" -ForegroundColor Gray
} else {
    Write-Host "Creating new external virtual switch..." -ForegroundColor Cyan
    
    # Get the first physical network adapter
    $netAdapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.Physical } | Select-Object -First 1
    
    if ($netAdapter) {
        Write-Host "Using network adapter: $($netAdapter.Name)" -ForegroundColor Gray
        New-VMSwitch -Name $SwitchName -NetAdapterName $netAdapter.Name -AllowManagementOS $true
        Write-Host "Virtual switch created: $SwitchName" -ForegroundColor Green
    } else {
        Write-Host "WARNING: No physical network adapter found, creating internal switch" -ForegroundColor Yellow
        New-VMSwitch -Name $SwitchName -SwitchType Internal
        Write-Host "Internal switch created: $SwitchName" -ForegroundColor Green
    }
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

# Create the VM
Write-Host "Creating VM: $VMName" -ForegroundColor Cyan

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

# Disable secure boot for Linux
Set-VMFirmware -VMName $VMName -EnableSecureBoot Off
Write-Host "Secure Boot: Disabled (for Linux)" -ForegroundColor Gray

# Add DVD drive and attach Ubuntu ISO
Add-VMDvdDrive -VMName $VMName -Path $IsoPath
Write-Host "Ubuntu ISO attached to DVD drive" -ForegroundColor Gray

# Add second DVD drive for cloud-init seed ISO
Add-VMDvdDrive -VMName $VMName -Path $SeedIsoPath
Write-Host "Cloud-init seed ISO attached to DVD drive" -ForegroundColor Gray

# Set boot order to DVD first
$dvdDrive = Get-VMDvdDrive -VMName $VMName | Select-Object -First 1
$hardDrive = Get-VMHardDiskDrive -VMName $VMName
Set-VMFirmware -VMName $VMName -FirstBootDevice $dvdDrive
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
Write-Host "  State: $($vm.State)" -ForegroundColor Gray
Write-Host "  CPUs: $ProcessorCount" -ForegroundColor Gray
Write-Host "  Memory: $([math]::Round($MemoryStartupBytes/1GB))GB" -ForegroundColor Gray
Write-Host "  VHD: $VHDPath ($([math]::Round($VHDSize/1GB))GB)" -ForegroundColor Gray
Write-Host "  Switch: $SwitchName" -ForegroundColor Gray

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. The VM will boot from the Ubuntu ISO" -ForegroundColor Cyan
Write-Host "2. Cloud-init will perform unattended installation" -ForegroundColor Cyan
Write-Host "3. Monitor installation via Hyper-V Manager or Connect-VMConsole" -ForegroundColor Cyan
Write-Host "4. Installation typically takes 10-15 minutes" -ForegroundColor Cyan
Write-Host "5. After installation, the VM will reboot automatically" -ForegroundColor Cyan
Write-Host ""
