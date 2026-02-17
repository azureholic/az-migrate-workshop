# Extract and Import Azure Migrate Appliance VM in Hyper-V
# This script runs on the DC VM

param(
    [string]$VMName = "az-migrate",
    [string]$ZipPath = "C:\dc-files\AzureMigrateAppliance.zip",
    [string]$ExtractPath = "C:\VMs",
    [int64]$MemoryStartupBytes = 8GB,
    [int]$ProcessorCount = 2,
    [string]$SwitchName = "NAT-Switch",
    [string]$StaticIP = "192.168.100.10"
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Extract and Import Azure Migrate Appliance ===" -ForegroundColor Yellow
Write-Host "VM Name: $VMName" -ForegroundColor Cyan
Write-Host "ZIP: $ZipPath" -ForegroundColor Cyan
Write-Host "Extract to: $ExtractPath`n" -ForegroundColor Cyan

# ============================================
# 1. Verify Prerequisites
# ============================================
Write-Host "[1/5] Verifying prerequisites..." -ForegroundColor Yellow

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

# Check if ZIP exists
if (-not (Test-Path $ZipPath)) {
    Write-Host "ERROR: ZIP file not found: $ZipPath" -ForegroundColor Red
    Write-Host "Please run 01-download-appliance.ps1 first" -ForegroundColor Cyan
    exit 1
}

$zipSize = (Get-Item $ZipPath).Length / 1GB
Write-Host "ZIP file found: $([math]::Round($zipSize, 2)) GB" -ForegroundColor Green

# ============================================
# 2. Extract ZIP File
# ============================================
Write-Host "`n[2/5] Extracting ZIP file..." -ForegroundColor Yellow

# Create extraction directory
if (-not (Test-Path $ExtractPath)) {
    Write-Host "Creating directory: $ExtractPath" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $ExtractPath -Force | Out-Null
}

# Check if already extracted - look for version folder
$existingVersionFolder = Get-ChildItem -Path $ExtractPath -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "AzureMigrateAppliance*" } |
    Select-Object -First 1

if ($existingVersionFolder) {
    Write-Host "Appliance already extracted: $($existingVersionFolder.Name)" -ForegroundColor Yellow
    
    # Verify VM export structure
    $testVmPath = Join-Path $existingVersionFolder.FullName "Virtual Machines"
    $testVhdPath = Join-Path $existingVersionFolder.FullName "Virtual Hard Disks"
    
    if ((Test-Path $testVmPath) -and (Test-Path $testVhdPath)) {
        Write-Host "Valid VM export found, skipping extraction" -ForegroundColor Green
        $vmExportPath = $existingVersionFolder.FullName
    } else {
        Write-Host "Invalid structure, re-extracting..." -ForegroundColor Yellow
        Remove-Item $existingVersionFolder.FullName -Recurse -Force
        $existingVersionFolder = $null
    }
}

# Extract if needed
if (-not $existingVersionFolder) {
    Write-Host "Extracting ZIP..." -ForegroundColor Cyan
    Write-Host "This may take a few minutes..." -ForegroundColor Gray
    
    try {
        Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force
        Write-Host "Extraction completed!" -ForegroundColor Green
        
        # Find version folder
        $versionFolder = Get-ChildItem -Path $ExtractPath -Directory |
            Where-Object { $_.Name -like "AzureMigrateAppliance*" } |
            Select-Object -First 1
        
        if (-not $versionFolder) {
            Write-Host "ERROR: No version folder found after extraction" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "Found: $($versionFolder.Name)" -ForegroundColor Cyan
        $vmExportPath = $versionFolder.FullName
        
    } catch {
        Write-Host "ERROR: Failed to extract ZIP: $_" -ForegroundColor Red
        exit 1
    }
}

# Verify VM export structure
$vmConfigPath = Join-Path $vmExportPath "Virtual Machines"
$vhdPath = Join-Path $vmExportPath "Virtual Hard Disks"

if (-not (Test-Path $vmConfigPath) -or -not (Test-Path $vhdPath)) {
    Write-Host "ERROR: Invalid VM export structure" -ForegroundColor Red
    Write-Host "Missing: Virtual Machines or Virtual Hard Disks folders" -ForegroundColor Yellow
    exit 1
}

Write-Host "VM export validated: $vmExportPath" -ForegroundColor Green

# ============================================
# 3. Verify NAT Virtual Switch
# ============================================
Write-Host "`n[3/5] Verifying NAT virtual switch..." -ForegroundColor Yellow

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
# 4. Import VM
# ============================================
Write-Host "`n[4/5] Importing virtual machine..." -ForegroundColor Yellow

# Check if VM already exists
$existingVM = Get-VM -Name $VMName -ErrorAction SilentlyContinue

if ($existingVM) {
    Write-Host "VM already exists in Hyper-V: $VMName" -ForegroundColor Green
    Write-Host "State: $($existingVM.State)" -ForegroundColor Gray
    Write-Host "Skipping import" -ForegroundColor Cyan
} else {
    # Find VM config file
    Write-Host "Searching for VM configuration file..." -ForegroundColor Cyan
    Write-Host "Looking in: $vmConfigPath" -ForegroundColor Gray
    
    # List all files in the folder
    Write-Host "`nContents of Virtual Machines folder:" -ForegroundColor Yellow
    Get-ChildItem -Path $vmConfigPath -File -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "  $($_.Name) - Size: $($_.Length) bytes" -ForegroundColor Gray
    }
    
    $vmConfigFile = Get-ChildItem -Path $vmConfigPath -Filter "*.vmcx" -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if (-not $vmConfigFile) {
        Write-Host "`nERROR: No VM configuration file (.vmcx) found" -ForegroundColor Red
        Write-Host "Expected a .vmcx file in: $vmConfigPath" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "`nFound config file:" -ForegroundColor Green
    Write-Host "  Name: $($vmConfigFile.Name)" -ForegroundColor Cyan
    Write-Host "  Path: $($vmConfigFile.FullName)" -ForegroundColor Cyan
    Write-Host "  Size: $($vmConfigFile.Length) bytes" -ForegroundColor Gray
    
    Write-Host "`nAttempting to import VM..." -ForegroundColor Cyan
    Write-Host "Step 1: Running compatibility check (Compare-VM)..." -ForegroundColor Gray

    try {
        # First run Compare-VM to check compatibility
        $compatReport = Compare-VM -Path $vmConfigFile.FullName
        
        Write-Host "Compatibility check completed!" -ForegroundColor Green
        
        if ($compatReport.Incompatibilities.Count -gt 0) {
            Write-Host "`nFound $($compatReport.Incompatibilities.Count) incompatibility issues:" -ForegroundColor Yellow
            foreach ($issue in $compatReport.Incompatibilities) {
                Write-Host "  - $($issue.Message)" -ForegroundColor Gray
                Write-Host "    Source: $($issue.Source)" -ForegroundColor DarkGray
                Write-Host "    MessageId: $($issue.MessageId)" -ForegroundColor DarkGray
            }
            
            # Fix network adapter incompatibilities
            Write-Host "`nStep 2: Fixing incompatibilities..." -ForegroundColor Cyan
            foreach ($issue in $compatReport.Incompatibilities) {
                if ($issue.MessageId -eq 33012) {
                    # Network switch not found - disconnect the adapter
                    Write-Host "Disconnecting network adapter from missing switch..." -ForegroundColor Yellow
                    $issue.Source | Disconnect-VMNetworkAdapter
                    Write-Host "Network adapter disconnected" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "No incompatibilities found" -ForegroundColor Green
        }
        
        # List current VMs before import
        $vmsBefore = @(Get-VM -ErrorAction SilentlyContinue)
        Write-Host "`nCurrent VMs in Hyper-V: $($vmsBefore.Count)" -ForegroundColor Gray
        
        # Import VM using the compatibility report
        Write-Host "`nStep 3: Importing VM..." -ForegroundColor Cyan
        $importedVM = $compatReport | Import-VM
        
        Write-Host "Import-VM completed!" -ForegroundColor Green
        Write-Host "Imported VM name: $($importedVM.Name)" -ForegroundColor Cyan
        Write-Host "Imported VM ID: $($importedVM.VMId)" -ForegroundColor Gray
        Write-Host "Imported VM state: $($importedVM.State)" -ForegroundColor Gray
        
        # List VMs after import
        $vmsAfter = @(Get-VM -ErrorAction SilentlyContinue)
        Write-Host "VMs in Hyper-V after import: $($vmsAfter.Count)" -ForegroundColor Gray
        
        # Rename to desired name
        if ($importedVM.Name -ne $VMName) {
            Write-Host "`nRenaming VM from '$($importedVM.Name)' to '$VMName'..." -ForegroundColor Cyan
            Rename-VM -VM $importedVM -NewName $VMName
            Write-Host "VM renamed successfully!" -ForegroundColor Green
        } else {
            Write-Host "`nVM already has correct name: $VMName" -ForegroundColor Green
        }
        
        # Verify VM is now visible
        $verifyVM = Get-VM -Name $VMName -ErrorAction SilentlyContinue
        if ($verifyVM) {
            Write-Host "`nVM verification successful!" -ForegroundColor Green
            Write-Host "VM '$VMName' is now registered in Hyper-V" -ForegroundColor Cyan
        } else {
            Write-Host "`nWARNING: VM imported but cannot be found by name '$VMName'" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "`nERROR: Failed to import VM!" -ForegroundColor Red
        Write-Host "Error message: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Error type: $($_.Exception.GetType().FullName)" -ForegroundColor Gray
        Write-Host "`nStack trace:" -ForegroundColor Gray
        Write-Host $_.Exception.StackTrace -ForegroundColor Gray
        exit 1
    }
}

# ============================================
# 5. Configure VM Settings
# ============================================
Write-Host "`n[5/5] Configuring VM settings..." -ForegroundColor Yellow

try {
    # Set processor count
    Set-VMProcessor -VMName $VMName -Count $ProcessorCount
    Write-Host "Processors: $ProcessorCount" -ForegroundColor Gray

    # Set memory
    Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $false -StartupBytes $MemoryStartupBytes
    Write-Host "Memory: $([math]::Round($MemoryStartupBytes/1GB))GB (static)" -ForegroundColor Gray

    # Connect to switch
    Get-VMNetworkAdapter -VMName $VMName | Connect-VMNetworkAdapter -SwitchName $SwitchName
    Write-Host "Network: Connected to $SwitchName" -ForegroundColor Gray

    # Enable guest services
    Enable-VMIntegrationService -VMName $VMName -Name "Guest Service Interface" -ErrorAction SilentlyContinue
    Write-Host "Guest services enabled" -ForegroundColor Gray

    # Start the VM
    Write-Host "`nStarting VM..." -ForegroundColor Cyan
    Start-VM -Name $VMName
    Write-Host "VM started successfully!" -ForegroundColor Green

    # Wait a moment and check status
    Start-Sleep -Seconds 3
    $vm = Get-VM -Name $VMName
    Write-Host "`nVM Status: $($vm.State)" -ForegroundColor Cyan
    Write-Host "Uptime: $($vm.Uptime)" -ForegroundColor Gray

} catch {
    Write-Host "WARNING: Some configuration steps failed: $_" -ForegroundColor Yellow
    Write-Host "VM was imported but may need manual configuration" -ForegroundColor Yellow
}

# ============================================
# Summary
# ============================================
Write-Host "`n=== VM Import Complete ===" -ForegroundColor Yellow

# Add DHCP reservation for static IP
Write-Host "`nConfiguring DHCP reservation for static IP..." -ForegroundColor Cyan
try {
    $vmNetAdapter = Get-VMNetworkAdapter -VMName $VMName
    $macAddress = $vmNetAdapter.MacAddress -replace '(..)(..)(..)(..)(..)(..)','$1-$2-$3-$4-$5-$6'
    
    # Remove existing reservation if present
    Get-DhcpServerv4Reservation -ScopeId 192.168.100.0 -ErrorAction SilentlyContinue | 
        Where-Object { $_.IPAddress -eq $StaticIP -or $_.ClientId -eq $macAddress } |
        Remove-DhcpServerv4Reservation -ErrorAction SilentlyContinue
    
    # Add new reservation
    Add-DhcpServerv4Reservation -ScopeId 192.168.100.0 -IPAddress $StaticIP -ClientId $macAddress -Name $VMName -Description "Azure Migrate Appliance"
    Write-Host "DHCP reservation added: $VMName -> $StaticIP (MAC: $macAddress)" -ForegroundColor Green
} catch {
    Write-Host "WARNING: Could not add DHCP reservation: $_" -ForegroundColor Yellow
    Write-Host "VM will use dynamic IP from DHCP" -ForegroundColor Yellow
}

$vm = Get-VM -Name $VMName
$vmLocation = $vm.ConfigurationLocation

Write-Host "VM Details:" -ForegroundColor Cyan
Write-Host "  Name: $VMName" -ForegroundColor Gray
Write-Host "  State: $($vm.State)" -ForegroundColor Gray
Write-Host "  CPUs: $($vm.ProcessorCount)" -ForegroundColor Gray
Write-Host "  Memory: $([math]::Round($vm.MemoryStartup/1GB))GB" -ForegroundColor Gray
Write-Host "  Location: $vmLocation" -ForegroundColor Gray
Write-Host "  Switch: $SwitchName" -ForegroundColor Gray
Write-Host "  Static IP: $StaticIP (via DHCP reservation)" -ForegroundColor Gray

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Connect to the VM via Hyper-V Manager" -ForegroundColor Cyan
Write-Host "2. Complete Azure Migrate appliance configuration wizard" -ForegroundColor Cyan
Write-Host "3. Register the appliance with your Azure Migrate project" -ForegroundColor Cyan
Write-Host "4. Configure discovery settings for on-premises VMs" -ForegroundColor Cyan
Write-Host ""
