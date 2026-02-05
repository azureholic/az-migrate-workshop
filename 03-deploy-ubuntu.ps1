# Azure Migration Workshop - Deploy Ubuntu VM
# This script orchestrates Ubuntu VM deployment on the DC host

param(
    [string]$ResourceGroupName = "rg-migrate-workshop",
    [string]$VMName = "vm-dc",
    [string]$ScriptsPath = ".\dc-scripts\ubuntu-vm",
    [string]$VMFilesPath = "C:\dc-files"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Azure Migration Workshop - Deploy Ubuntu VM ===" -ForegroundColor Yellow
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

$script1 = Join-Path $ScriptsPath "01-download-iso.ps1"
$script2 = Join-Path $ScriptsPath "02-create-vm.ps1"

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
# 2. Download Ubuntu ISO on VM
# ============================================
Write-Host "`n[1/2] Downloading Ubuntu 22.04 ISO on VM..." -ForegroundColor Cyan
Write-Host "Target location on VM: $VMFilesPath" -ForegroundColor Gray
Write-Host "(This may take several minutes - ISO is ~2.5 GB)`n" -ForegroundColor Yellow

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
        Write-Host "`nUbuntu ISO download completed!" -ForegroundColor Green
    } else {
        Write-Host "`nWarning: Command may have completed with errors" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: Failed to execute command on VM: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# 3. Create Ubuntu VM in Hyper-V
# ============================================
Write-Host "`n[2/2] Creating Ubuntu VM in Hyper-V..." -ForegroundColor Cyan
Write-Host "This will create and start the VM with unattended installation`n" -ForegroundColor Gray

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
        Write-Host "`nUbuntu VM creation completed!" -ForegroundColor Green
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
Write-Host "`n=== Ubuntu VM Deployment Complete ===" -ForegroundColor Yellow
Write-Host "Ubuntu VM is now running on the DC host with unattended installation" -ForegroundColor Cyan
Write-Host "`nWhat happened:" -ForegroundColor Yellow
Write-Host "1. Downloaded Ubuntu 22.04.5 LTS ISO to $VMFilesPath" -ForegroundColor Cyan
Write-Host "2. Created Ubuntu VM in Hyper-V with:" -ForegroundColor Cyan
Write-Host "   - 2 vCPUs, 2-4GB RAM" -ForegroundColor Gray
Write-Host "   - 50GB VHD" -ForegroundColor Gray
Write-Host "   - Ubuntu ISO + Cloud-init seed ISO attached" -ForegroundColor Gray
Write-Host "3. VM is now installing Ubuntu automatically" -ForegroundColor Cyan
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Installation will take ~10-15 minutes" -ForegroundColor Cyan
Write-Host "2. Monitor installation via Hyper-V Manager on the DC VM" -ForegroundColor Cyan
Write-Host "3. After installation, VM will reboot and be ready to use" -ForegroundColor Cyan
Write-Host "4. Default credentials: ubuntu / <password from cloud-init>" -ForegroundColor Cyan
Write-Host ""
