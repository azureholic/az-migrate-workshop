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
Write-Host "  3. Deploy Windows Server 2019 ADDS VM in Hyper-V (DNS server)" -ForegroundColor Gray
Write-Host "  4. Pre-download all ISOs and appliance files" -ForegroundColor Gray
Write-Host "  5. Wait for ADDS VM to complete installation (DNS forwarder check)" -ForegroundColor Gray
Write-Host "  6. Deploy Azure Migrate appliance in Hyper-V" -ForegroundColor Gray
Write-Host "  7. Deploy Ubuntu Webapp VM in Hyper-V" -ForegroundColor Gray
Write-Host "  8. Deploy Ubuntu VM in Hyper-V" -ForegroundColor Gray
Write-Host "`nResource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "Location: $Location`n" -ForegroundColor Cyan

# Track timing
$startTime = Get-Date
$stepTimings = @{}

# ============================================
# Step 1: Deploy DC Infrastructure
# ============================================
Write-Host "`n[1/8] Deploying DC VM Infrastructure..." -ForegroundColor Yellow
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
Write-Host "`n[2/8] Preparing DC VM (Hyper-V, NAT, DHCP)..." -ForegroundColor Yellow
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
# Step 3: Deploy Windows Server 2019 ADDS VM (DNS Server - must be deployed before Ubuntu VMs)
# ============================================
Write-Host "`n[3/8] Deploying Windows Server 2019 ADDS VM in Hyper-V (DNS server)..." -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Yellow

$stepStart = Get-Date
$addsScript = Join-Path $scriptDir "03-deploy-adds.ps1"
if (-not (Test-Path $addsScript)) {
    Write-Host "ERROR: Script not found: $addsScript" -ForegroundColor Red
    exit 1
}

& $addsScript -ResourceGroupName $ResourceGroupName

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: ADDS VM deployment failed" -ForegroundColor Red
    exit 1
}

$stepTimings["ADDS VM"] = (Get-Date) - $stepStart
Write-Host "ADDS VM deployed successfully! ($(($stepTimings["ADDS VM"]).ToString('mm\:ss')))" -ForegroundColor Green

# ============================================
# Step 4: Pre-download all ISOs and appliance (while ADDS installs)
# ============================================
Write-Host "`n[4/8] Pre-downloading all ISOs and appliance files..." -ForegroundColor Yellow
Write-Host "=====================================================" -ForegroundColor Yellow

$stepStart = Get-Date
$predownloadScript = Join-Path $scriptDir "dc-scripts\predownload-isos.ps1"
if (-not (Test-Path $predownloadScript)) {
    Write-Host "ERROR: Script not found: $predownloadScript" -ForegroundColor Red
    exit 1
}

& $predownloadScript -ResourceGroupName $ResourceGroupName

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: ISO pre-download failed" -ForegroundColor Red
    exit 1
}

$stepTimings["Pre-download"] = (Get-Date) - $stepStart
Write-Host "All ISOs and appliance pre-downloaded! ($(($stepTimings["Pre-download"]).ToString('mm\:ss')))" -ForegroundColor Green

# ============================================
# Step 5: Wait for ADDS VM to complete installation
# ============================================
Write-Host "`n[5/8] Waiting for ADDS VM to finish installing (checking DNS forwarder)..." -ForegroundColor Yellow
Write-Host "=========================================================================" -ForegroundColor Yellow
Write-Host "The ADDS VM is auto-installing Windows Server 2019 + AD DS + DNS." -ForegroundColor Gray
Write-Host "Polling every 60 seconds for DNS forwarder (Azure DNS 168.63.129.16)..." -ForegroundColor Gray
Write-Host "The VM will reboot during installation - failed polls are expected.`n" -ForegroundColor Gray

$stepStart = Get-Date
$addsReady = $false
$pollCount = 0
$maxPolls = 60  # 60 minutes max wait

while (-not $addsReady -and $pollCount -lt $maxPolls) {
    $pollCount++
    $elapsed = ((Get-Date) - $stepStart).ToString('mm\:ss')
    Write-Host "  Poll #$pollCount ($elapsed elapsed) - Checking ADDS DNS forwarder..." -ForegroundColor Gray -NoNewline

    try {
        $checkOutput = az vm run-command invoke `
            --resource-group $ResourceGroupName `
            --name "vm-dc" `
            --command-id RunPowerShellScript `
            --scripts "try { `$result = Invoke-Command -ComputerName 192.168.100.20 -Credential (New-Object PSCredential('MIGRATE\Administrator', (ConvertTo-SecureString 'Windows123!' -AsPlainText -Force))) -ScriptBlock { (Get-DnsServerForwarder).IPAddress.IPAddressToString } -ErrorAction Stop; Write-Host `$result } catch { Write-Host 'NOT_READY' }" `
            --output json 2>$null

        if ($LASTEXITCODE -eq 0) {
            $checkResult = ($checkOutput | ConvertFrom-Json).value | Where-Object { $_.code -like '*StdOut*' } | Select-Object -ExpandProperty message

            if ($checkResult -and $checkResult.Trim() -match '168\.63\.129\.16') {
                Write-Host " DNS forwarder is set to Azure DNS!" -ForegroundColor Green
                $addsReady = $true
            } else {
                Write-Host " Not ready yet (got: $($checkResult.Trim()))" -ForegroundColor Yellow
            }
        } else {
            Write-Host " VM unreachable (may be rebooting)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host " Connection failed (VM may be rebooting)" -ForegroundColor Yellow
    }

    if (-not $addsReady) {
        Start-Sleep -Seconds 60
    }
}

if (-not $addsReady) {
    Write-Host "`nERROR: ADDS VM did not become ready within $maxPolls minutes" -ForegroundColor Red
    Write-Host "Check the ADDS VM manually via Hyper-V Manager on the DC host" -ForegroundColor Yellow
    exit 1
}

$stepTimings["ADDS Wait"] = (Get-Date) - $stepStart
Write-Host "ADDS VM is ready! DNS forwarder confirmed. ($(($stepTimings["ADDS Wait"]).ToString('mm\:ss')))" -ForegroundColor Green

# ============================================
# Step 6: Deploy Azure Migrate Appliance
# ============================================
Write-Host "`n[6/8] Deploying Azure Migrate Appliance..." -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow

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
Write-Host "Azure Migrate appliance deployed successfully! ($(($stepTimings["Azure Migrate"]).ToString('mm\:ss')))" -ForegroundColor Green

# ============================================
# Step 7: Deploy Ubuntu Webapp VM
# ============================================
Write-Host "`n[7/8] Deploying Ubuntu Webapp VM in Hyper-V..." -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

$stepStart = Get-Date
$webappScript = Join-Path $scriptDir "05-deploy-webapp.ps1"
if (-not (Test-Path $webappScript)) {
    Write-Host "ERROR: Script not found: $webappScript" -ForegroundColor Red
    exit 1
}

& $webappScript -ResourceGroupName $ResourceGroupName

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Webapp VM deployment failed" -ForegroundColor Red
    exit 1
}

$stepTimings["Webapp VM"] = (Get-Date) - $stepStart
Write-Host "Webapp VM deployed successfully! ($(($stepTimings["Webapp VM"]).ToString('mm\:ss')))" -ForegroundColor Green

# ============================================
# Step 8: Deploy Ubuntu VM
# ============================================
Write-Host "`n[8/8] Deploying Ubuntu VM in Hyper-V..." -ForegroundColor Yellow
Write-Host "=======================================" -ForegroundColor Yellow

$stepStart = Get-Date
$ubuntuScript = Join-Path $scriptDir "06-deploy-ubuntu.ps1"
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
Write-Host "  - Azure Migrate project with all solutions" -ForegroundColor Gray
Write-Host "  - Windows Server 2019 ADDS VM (Domain Controller / DNS Server) in Hyper-V" -ForegroundColor Gray
Write-Host "  - Ubuntu Webapp VM running in Hyper-V" -ForegroundColor Gray
Write-Host "  - Ubuntu 24.04 VM running in Hyper-V" -ForegroundColor Gray

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Connect to the DC VM via Azure Bastion" -ForegroundColor Cyan
Write-Host "2. Open Hyper-V Manager to verify VMs are running" -ForegroundColor Cyan
Write-Host "3. Configure the Azure Migrate appliance and start discovery" -ForegroundColor Cyan
Write-Host "4. Register the Hyper-V host with the Recovery Services vault" -ForegroundColor Cyan
Write-Host ""
