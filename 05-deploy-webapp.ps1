# Azure Migration Workshop - Deploy Ubuntu Webapp VM
# This script deploys a second Ubuntu server with webapp configuration

param(
    [string]$ResourceGroupName = "rg-migrate-workshop",
    [string]$VMName = "vm-dc"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Azure Migration Workshop - Deploy Ubuntu Webapp VM ===" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "DC VM Name: $VMName`n" -ForegroundColor Cyan

# ============================================
# 1. Download Ubuntu Webapp ISO
# ============================================
Write-Host "[1/2] Downloading Ubuntu Webapp ISO to DC VM..." -ForegroundColor Yellow

$downloadScript = Get-Content -Path "$PSScriptRoot\dc-scripts\webapp-vm\01-download-iso.ps1" -Raw

$tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
$downloadScript | Out-File -FilePath $tempFile -Encoding ASCII

try {
    $output = & az vm run-command invoke `
        --resource-group $ResourceGroupName `
        --name $VMName `
        --command-id RunPowerShellScript `
        --scripts "@$tempFile" `
        --output json 2>$null

    $result = ($output | ConvertFrom-Json).value
    $stdOut = ($result | Where-Object { $_.code -like '*StdOut*' }).message
    $stdErr = ($result | Where-Object { $_.code -like '*StdErr*' }).message
    
    if ($stdOut) { Write-Host $stdOut -ForegroundColor Gray }
    if ($stdErr -and $stdErr.Trim()) { Write-Host "Warnings: $stdErr" -ForegroundColor Yellow }
    
    Write-Host "ISO download complete!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to download ISO: $_" -ForegroundColor Red
    exit 1
} finally {
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
}

# ============================================
# 2. Create Webapp VM
# ============================================
Write-Host "`n[2/2] Creating Ubuntu Webapp VM in Hyper-V..." -ForegroundColor Yellow

$createVmScript = Get-Content -Path "$PSScriptRoot\dc-scripts\webapp-vm\02-create-vm.ps1" -Raw

$tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
$createVmScript | Out-File -FilePath $tempFile -Encoding ASCII

try {
    $output = & az vm run-command invoke `
        --resource-group $ResourceGroupName `
        --name $VMName `
        --command-id RunPowerShellScript `
        --scripts "@$tempFile" `
        --output json 2>$null

    $result = ($output | ConvertFrom-Json).value
    $stdOut = ($result | Where-Object { $_.code -like '*StdOut*' }).message
    $stdErr = ($result | Where-Object { $_.code -like '*StdErr*' }).message
    
    if ($stdOut) { Write-Host $stdOut -ForegroundColor Gray }
    if ($stdErr -and $stdErr.Trim()) { Write-Host "Warnings: $stdErr" -ForegroundColor Yellow }
    
    Write-Host "Webapp VM created!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to create VM: $_" -ForegroundColor Red
    exit 1
} finally {
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
}

# ============================================
# Summary
# ============================================
Write-Host "`n=== Webapp VM Deployment Complete ===" -ForegroundColor Yellow
Write-Host "The Ubuntu webapp VM is now installing from the autoinstall ISO" -ForegroundColor Cyan
Write-Host "Installation takes approximately 10-15 minutes" -ForegroundColor Cyan
Write-Host "`nVM Details:" -ForegroundColor Yellow
Write-Host "  Name: webapp-vm" -ForegroundColor Gray
Write-Host "  Expected IP: 192.168.100.12 (via DHCP)" -ForegroundColor Gray
Write-Host ""
