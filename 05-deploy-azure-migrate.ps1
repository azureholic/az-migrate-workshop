# Azure Migration Workshop - Deploy Azure Migrate Appliance
# This script orchestrates Azure Migrate appliance deployment on the DC host

param(
    [string]$ResourceGroupName = "rg-migrate-workshop",
    [string]$VMName = "vm-dc",
    [string]$ScriptsPath = ".\dc-scripts\az-migrate-vm",
    [string]$VMFilesPath = "C:\dc-files"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Azure Migration Workshop - Deploy Azure Migrate Appliance ===" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "VM Name: $VMName`n" -ForegroundColor Cyan

# ============================================
# 1. Verify scripts exist
# ============================================
Write-Host "[1/2] Checking scripts..." -ForegroundColor Yellow

if (-not (Test-Path $ScriptsPath)) {
    Write-Host "ERROR: Scripts directory not found: $ScriptsPath" -ForegroundColor Red
    exit 1
}

$script1 = Join-Path $ScriptsPath "01-download-appliance.ps1"
$script2 = Join-Path $ScriptsPath "02-create-appliance.ps1"

if (-not (Test-Path $script1)) {
    Write-Host "ERROR: Script not found: $script1" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $script2)) {
    Write-Host "ERROR: Script not found: $script2" -ForegroundColor Red
    exit 1
}

Write-Host "Found required scripts" -ForegroundColor Green

# ============================================
# 2. Download Azure Migrate Appliance on VM
# ============================================
Write-Host "`n[1/2] Downloading Azure Migrate Appliance ZIP on VM..." -ForegroundColor Cyan
Write-Host "Target location on VM: $VMFilesPath" -ForegroundColor Gray
Write-Host "(This may take a while - ZIP is several GB)`n" -ForegroundColor Yellow

$script1Content = Get-Content -Path $script1 -Raw

try {
    # Save script to temp file
    $tempScriptFile = [System.IO.Path]::GetTempFileName() + ".ps1"
    $script1Content | Out-File -FilePath $tempScriptFile -Encoding UTF8
    
    # Execute on VM
    $output = az vm run-command invoke `
        --resource-group $ResourceGroupName `
        --name $VMName `
        --command-id RunPowerShellScript `
        --scripts "@$tempScriptFile" `
        --parameters "TargetPath=$VMFilesPath" `
        --output json 2>&1
    
    # Clean up temp file
    Remove-Item $tempScriptFile -Force -ErrorAction SilentlyContinue
    
    # Parse and display output
    $result = $output | ConvertFrom-Json
    $stdOut = $result.value | Where-Object { $_.code -like '*StdOut*' } | Select-Object -ExpandProperty message
    Write-Host $stdOut -ForegroundColor Gray
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nAzure Migrate appliance download completed!" -ForegroundColor Green
    } else {
        Write-Host "`nWarning: Command may have completed with errors" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: Failed to execute command on VM: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# 3. Extract and Import Azure Migrate VM in Hyper-V
# ============================================
Write-Host "`n[2/2] Extracting and importing Azure Migrate VM in Hyper-V..." -ForegroundColor Cyan
Write-Host "This will extract the ZIP and import the VM`n" -ForegroundColor Gray

$script2Content = Get-Content -Path $script2 -Raw

try {
    # Save script to temp file
    $tempScriptFile = [System.IO.Path]::GetTempFileName() + ".ps1"
    $script2Content | Out-File -FilePath $tempScriptFile -Encoding UTF8
    
    # Execute on VM
    $output = az vm run-command invoke `
        --resource-group $ResourceGroupName `
        --name $VMName `
        --command-id RunPowerShellScript `
        --scripts "@$tempScriptFile" `
        --output json 2>&1
    
    # Clean up temp file
    Remove-Item $tempScriptFile -Force -ErrorAction SilentlyContinue
    
    # Parse and display output
    $result = $output | ConvertFrom-Json
    $stdOut = $result.value | Where-Object { $_.code -like '*StdOut*' } | Select-Object -ExpandProperty message
    Write-Host $stdOut -ForegroundColor Gray
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nAzure Migrate VM extraction and import completed!" -ForegroundColor Green
    } else {
        Write-Host "`nWarning: Command may have completed with errors" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: Failed to execute command on VM: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# Summary
# ============================================
Write-Host "`n=== Azure Migrate Appliance Deployment Complete ===" -ForegroundColor Yellow
Write-Host "Azure Migrate appliance VM is now running on the DC host" -ForegroundColor Cyan
Write-Host "`nWhat was deployed:" -ForegroundColor Yellow
Write-Host "1. Downloaded Azure Migrate appliance ZIP to C:\dc-files" -ForegroundColor Cyan
Write-Host "2. Extracted ZIP to C:\VMs (version-specific folder)" -ForegroundColor Cyan
Write-Host "3. Imported VM 'az-migrate' in Hyper-V with:" -ForegroundColor Cyan
Write-Host "   - 2 vCPUs, 8GB RAM (static)" -ForegroundColor Gray
Write-Host "   - Connected to External-Switch" -ForegroundColor Gray
Write-Host "4. VM is started and ready for configuration" -ForegroundColor Cyan
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Connect to DC VM via Azure Bastion" -ForegroundColor Cyan
Write-Host "2. Open Hyper-V Manager and connect to 'az-migrate' VM" -ForegroundColor Cyan
Write-Host "3. Complete Azure Migrate appliance configuration wizard" -ForegroundColor Cyan
Write-Host "4. Register the appliance with your Azure Migrate project" -ForegroundColor Cyan
Write-Host "5. Configure discovery for the Ubuntu VM" -ForegroundColor Cyan
Write-Host ""
