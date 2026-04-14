# Azure Migration Workshop - Pre-download ISOs and Appliance
# This script downloads all ISOs and the Azure Migrate appliance on the DC VM
# so they are ready when it's time to create the VMs in Hyper-V.
# Each download script already skips if the file exists, so this is safe to re-run.

param(
    [string]$ResourceGroupName,
    [string]$VMName = "vm-dc",
    [string]$VMFilesPath = "C:\dc-files"
)

$ErrorActionPreference = "Stop"

# Read config from dc-infra\main.bicepparam (single source of truth)
$bicepParamFile = Join-Path (Split-Path $PSScriptRoot) "dc-infra\main.bicepparam"
$bicepContent = Get-Content $bicepParamFile -Raw
if (-not $ResourceGroupName) { $ResourceGroupName = [regex]::Match($bicepContent, "param resourceGroupName = '([^']+)'").Groups[1].Value }

Write-Host "`n=== Azure Migration Workshop - Pre-download ISOs ===" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "VM Name: $VMName`n" -ForegroundColor Cyan

# Helper: run a script on the DC VM via az vm run-command and check for errors
function Invoke-RunCommand {
    param(
        [string]$ScriptFile,
        [string[]]$Parameters,
        [string]$StepName
    )

    $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
    try {
        Get-Content -Path $ScriptFile -Raw | Out-File -FilePath $tempFile -Encoding ASCII

        $cmdArgs = @(
            "vm", "run-command", "invoke",
            "--resource-group", $ResourceGroupName,
            "--name", $VMName,
            "--command-id", "RunPowerShellScript",
            "--scripts", "@$tempFile",
            "--output", "json"
        )
        if ($Parameters) {
            $cmdArgs += "--parameters"
            $cmdArgs += $Parameters
        }

        $output = & az @cmdArgs 2>$null

        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: az vm run-command failed for '$StepName' (exit code $LASTEXITCODE)" -ForegroundColor Red
            exit 1
        }

        $result = ($output | ConvertFrom-Json).value
        $stdOut = ($result | Where-Object { $_.code -like '*StdOut*' }).message
        $stdErr = ($result | Where-Object { $_.code -like '*StdErr*' }).message

        if ($stdOut) { Write-Host $stdOut -ForegroundColor Gray }

        if ($stdErr -and $stdErr.Trim().Length -gt 0) {
            Write-Host "`nVM script stderr output:" -ForegroundColor Yellow
            Write-Host $stdErr -ForegroundColor Red
            Write-Host "ERROR: '$StepName' failed on the VM" -ForegroundColor Red
            exit 1
        }
    } finally {
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
}

# ============================================
# 1. Verify scripts exist
# ============================================
Write-Host "[1/4] Checking download scripts..." -ForegroundColor Yellow

$scriptDir = $PSScriptRoot
$ubuntuDownload = Join-Path $scriptDir "ubuntu-vm\01-download-iso.ps1"
$webappDownload = Join-Path $scriptDir "webapp-vm\01-download-iso.ps1"
$migrateDownload = Join-Path $scriptDir "az-migrate-vm\01-download-appliance.ps1"

foreach ($s in @($ubuntuDownload, $webappDownload, $migrateDownload)) {
    if (-not (Test-Path $s)) {
        Write-Host "ERROR: Script not found: $s" -ForegroundColor Red
        exit 1
    }
}

Write-Host "All download scripts found" -ForegroundColor Green

# ============================================
# 2. Download Ubuntu ISO
# ============================================
Write-Host "`n[2/4] Downloading Ubuntu ISO on DC VM..." -ForegroundColor Yellow
Write-Host "(Skips automatically if file already exists)`n" -ForegroundColor Gray

Invoke-RunCommand -ScriptFile $ubuntuDownload -Parameters "TargetPath=$VMFilesPath" -StepName "Download Ubuntu ISO"
Write-Host "Ubuntu ISO download step completed!" -ForegroundColor Green

# ============================================
# 3. Download Webapp ISO
# ============================================
Write-Host "`n[3/4] Downloading Ubuntu Webapp ISO on DC VM..." -ForegroundColor Yellow
Write-Host "(Skips automatically if file already exists)`n" -ForegroundColor Gray

Invoke-RunCommand -ScriptFile $webappDownload -Parameters "TargetPath=$VMFilesPath" -StepName "Download Webapp ISO"
Write-Host "Webapp ISO download step completed!" -ForegroundColor Green

# ============================================
# 4. Download Azure Migrate Appliance
# ============================================
Write-Host "`n[4/4] Downloading Azure Migrate Appliance on DC VM..." -ForegroundColor Yellow
Write-Host "(Skips automatically if file already exists)`n" -ForegroundColor Gray

Invoke-RunCommand -ScriptFile $migrateDownload -Parameters "TargetPath=$VMFilesPath" -StepName "Download Azure Migrate Appliance"
Write-Host "Azure Migrate Appliance download step completed!" -ForegroundColor Green

# ============================================
# Summary
# ============================================
Write-Host "`n=== All ISOs and Appliance Pre-downloaded ===" -ForegroundColor Green
Write-Host "Files are ready on the DC VM at $VMFilesPath" -ForegroundColor Cyan
