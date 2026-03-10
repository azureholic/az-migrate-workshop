# Azure Migration Workshop - Install Azure Connected Machine Agent on Azure Migrate Appliance
# This script installs the Azure Arc agent (aka.ms/AzureConnectedMachineAgent)
# on the Azure Migrate Appliance VM running in Hyper-V on the DC host.

param(
    [string]$ResourceGroupName = "rg-migrate-workshop",
    [string]$VMName = "vm-dc",
    [string]$ScriptsPath = ".\dc-scripts\az-migrate-vm",
    [Parameter(Mandatory=$true)]
    [string]$AppliancePassword
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Azure Migration Workshop - Install Azure Connected Machine Agent ===" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "DC VM Name: $VMName`n" -ForegroundColor Cyan

# Helper: run a script on the DC VM via az vm run-command and check for errors
function Invoke-RunCommand {
    param(
        [string]$ScriptFile,
        [string[]]$Parameters,
        [string]$StepName
    )

    $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
    try {
        Get-Content -Path $ScriptFile -Raw | Out-File -FilePath $tempFile -Encoding UTF8

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

        $stderrFile = [System.IO.Path]::GetTempFileName()
        $output = & az @cmdArgs 2>$stderrFile

        if ($LASTEXITCODE -ne 0) {
            $azError = Get-Content $stderrFile -Raw -ErrorAction SilentlyContinue
            Remove-Item $stderrFile -Force -ErrorAction SilentlyContinue
            Write-Host "ERROR: az vm run-command failed for '$StepName' (exit code $LASTEXITCODE)" -ForegroundColor Red
            if ($azError) { Write-Host "Azure CLI error: $azError" -ForegroundColor Red }
            exit 1
        }
        Remove-Item $stderrFile -Force -ErrorAction SilentlyContinue

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
Write-Host "[1/2] Checking scripts..." -ForegroundColor Yellow

$installScript = Join-Path $ScriptsPath "03-install-arc-agent.ps1"
if (-not (Test-Path $installScript)) {
    Write-Host "ERROR: Script not found: $installScript" -ForegroundColor Red
    exit 1
}

Write-Host "Scripts verified" -ForegroundColor Green

# ============================================
# 2. Install Azure Connected Machine Agent
# ============================================
Write-Host "`n[2/2] Installing Azure Connected Machine Agent on appliance VM..." -ForegroundColor Yellow

Invoke-RunCommand -ScriptFile $installScript `
    -Parameters @("AppliancePassword=$AppliancePassword") `
    -StepName "Install Arc Agent"

Write-Host "`n=== Azure Connected Machine Agent Setup Complete ===" -ForegroundColor Yellow
Write-Host "The agent has been installed on the Azure Migrate appliance VM (az-migrate)" -ForegroundColor Cyan
Write-Host "`nTo connect this machine to Azure Arc, RDP into the appliance and run:" -ForegroundColor Yellow
Write-Host '  & "$env:ProgramFiles\AzureConnectedMachineAgent\azcmagent.exe" connect `' -ForegroundColor Gray
Write-Host '      --resource-group "<resource-group>" `' -ForegroundColor Gray
Write-Host '      --tenant-id "<tenant-id>" `' -ForegroundColor Gray
Write-Host '      --location "<location>" `' -ForegroundColor Gray
Write-Host '      --subscription-id "<subscription-id>"' -ForegroundColor Gray
Write-Host ""
