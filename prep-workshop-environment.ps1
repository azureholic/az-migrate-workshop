# Azure Migration Workshop - Full Environment Setup
# This script runs all orchestrators in sequence to set up the complete workshop environment

param(
    [string]$ResourceGroupName = "rg-migrate-workshop",
    [string]$Location = "swedencentral"
)

$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot

Write-Host "`n" -NoNewline
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  Azure Migration Workshop - Environment Setup  " -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "`nThis script will set up the complete workshop environment:" -ForegroundColor Yellow
Write-Host "  1. Deploy DC VM infrastructure (Bicep)" -ForegroundColor Gray
Write-Host "  2. Prepare DC VM (Hyper-V, NAT, DHCP)" -ForegroundColor Gray
Write-Host "  3. Deploy Ubuntu VM in Hyper-V" -ForegroundColor Gray
Write-Host "  4. Deploy Azure Migrate infrastructure" -ForegroundColor Gray
Write-Host "`nResource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "Location: $Location`n" -ForegroundColor Cyan

# Track timing
$startTime = Get-Date
$stepTimings = @{}

# ============================================
# Step 1: Deploy DC Infrastructure
# ============================================
Write-Host "`n[1/4] Deploying DC VM Infrastructure..." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

$stepStart = Get-Date
$dcDeployScript = Join-Path $scriptDir "01-deploy-dc.ps1"
if (-not (Test-Path $dcDeployScript)) {
    Write-Host "ERROR: Script not found: $dcDeployScript" -ForegroundColor Red
    exit 1
}

& $dcDeployScript -ResourceGroupName $ResourceGroupName -Location $Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: DC deployment failed" -ForegroundColor Red
    exit 1
}

$stepTimings["DC Deploy"] = (Get-Date) - $stepStart
Write-Host "DC VM infrastructure deployed successfully! ($(($stepTimings["DC Deploy"]).ToString('mm\:ss')))" -ForegroundColor Green

# ============================================
# Step 2: Prepare DC VM
# ============================================
Write-Host "`n[2/4] Preparing DC VM (Hyper-V, NAT, DHCP)..." -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Yellow

$stepStart = Get-Date
$dcPrepScript = Join-Path $scriptDir "02-prep-dc.ps1"
if (-not (Test-Path $dcPrepScript)) {
    Write-Host "ERROR: Script not found: $dcPrepScript" -ForegroundColor Red
    exit 1
}

& $dcPrepScript -ResourceGroupName $ResourceGroupName

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: DC preparation failed" -ForegroundColor Red
    exit 1
}

$stepTimings["DC Prep"] = (Get-Date) - $stepStart
Write-Host "DC VM prepared successfully! ($(($stepTimings["DC Prep"]).ToString('mm\:ss')))" -ForegroundColor Green

# ============================================
# Step 3: Deploy Ubuntu VM
# ============================================
Write-Host "`n[3/4] Deploying Ubuntu VM in Hyper-V..." -ForegroundColor Yellow
Write-Host "=======================================" -ForegroundColor Yellow

$stepStart = Get-Date
$ubuntuScript = Join-Path $scriptDir "03-deploy-ubuntu.ps1"
if (-not (Test-Path $ubuntuScript)) {
    Write-Host "ERROR: Script not found: $ubuntuScript" -ForegroundColor Red
    exit 1
}

& $ubuntuScript -ResourceGroupName $ResourceGroupName

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Ubuntu deployment failed" -ForegroundColor Red
    exit 1
}

$stepTimings["Ubuntu"] = (Get-Date) - $stepStart
Write-Host "Ubuntu VM deployed successfully! ($(($stepTimings["Ubuntu"]).ToString('mm\:ss')))" -ForegroundColor Green

# ============================================
# Step 4: Deploy Azure Migrate
# ============================================
Write-Host "`n[4/4] Deploying Azure Migrate Infrastructure..." -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Yellow

$stepStart = Get-Date
$migrateScript = Join-Path $scriptDir "04-deploy-azure-migrate.ps1"
if (-not (Test-Path $migrateScript)) {
    Write-Host "ERROR: Script not found: $migrateScript" -ForegroundColor Red
    exit 1
}

& $migrateScript -ResourceGroupName $ResourceGroupName -Location $Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Azure Migrate deployment failed" -ForegroundColor Red
    exit 1
}

$stepTimings["Azure Migrate"] = (Get-Date) - $stepStart
Write-Host "Azure Migrate infrastructure deployed successfully! ($(($stepTimings["Azure Migrate"]).ToString('mm\:ss')))" -ForegroundColor Green

# ============================================
# Summary
# ============================================
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n" -NoNewline
Write-Host "===============================================" -ForegroundColor Green
Write-Host "  Workshop Environment Setup Complete!         " -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host "`nTotal Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan

Write-Host "`nStep Breakdown:" -ForegroundColor Yellow
foreach ($step in $stepTimings.GetEnumerator()) {
    Write-Host "  $($step.Key): $($step.Value.ToString('mm\:ss'))" -ForegroundColor Gray
}

Write-Host "`nWhat was deployed:" -ForegroundColor Yellow
Write-Host "  - DC VM with nested virtualization support" -ForegroundColor Gray
Write-Host "  - Hyper-V, NAT networking, DHCP server on DC VM" -ForegroundColor Gray
Write-Host "  - Ubuntu 24.04 VM running in Hyper-V" -ForegroundColor Gray
Write-Host "  - Azure Migrate project with all solutions" -ForegroundColor Gray

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Connect to the DC VM via RDP or Bastion" -ForegroundColor Cyan
Write-Host "2. Open Hyper-V Manager to verify VMs are running" -ForegroundColor Cyan
Write-Host "3. Download and configure the Azure Migrate appliance" -ForegroundColor Cyan
Write-Host "4. Register the appliance with your Azure Migrate project" -ForegroundColor Cyan
Write-Host "5. Start discovery of on-premises VMs" -ForegroundColor Cyan
Write-Host ""
