# Azure Migration Workshop - Deploy Domain Controller Infrastructure
# This script deploys the DC infrastructure including VNet, Storage, VM, and Bastion

param(
    [string]$ResourceGroupName,
    [string]$Location,
    [string]$TemplateFile = ".\dc-infra\main.bicep",
    [string]$ParametersFile = ".\dc-infra\main.bicepparam"
)

$ErrorActionPreference = "Stop"

# Read config from dc-infra\main.bicepparam (single source of truth)
$bicepParamFile = Join-Path $PSScriptRoot "dc-infra\main.bicepparam"
$bicepContent = Get-Content $bicepParamFile -Raw
if (-not $ResourceGroupName) { $ResourceGroupName = [regex]::Match($bicepContent, "param resourceGroupName = '([^']+)'").Groups[1].Value }
if (-not $Location) { $Location = [regex]::Match($bicepContent, "param location = '([^']+)'").Groups[1].Value }

Write-Host "`n=== Azure Migration Workshop - DC Infrastructure Deployment ===" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "Location: $Location`n" -ForegroundColor Cyan

# ============================================
# 1. Verify Azure CLI is installed and logged in
# ============================================
Write-Host "[1/3] Checking Azure CLI..." -ForegroundColor Yellow

try {
    $azVersion = az version --output json 2>&1 | ConvertFrom-Json
    Write-Host "Azure CLI version: $($azVersion.'azure-cli')" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Azure CLI is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install from: https://aka.ms/installazurecli" -ForegroundColor Cyan
    exit 1
}

# Check if logged in
try {
    $account = az account show 2>&1 | ConvertFrom-Json
    Write-Host "Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "Subscription: $($account.name) ($($account.id))" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Not logged in to Azure" -ForegroundColor Red
    Write-Host "Please run: az login" -ForegroundColor Cyan
    exit 1
}

# ============================================
# 2. Create Resource Group
# ============================================
Write-Host "`n[2/3] Creating Resource Group..." -ForegroundColor Yellow

$rgExists = az group exists --name $ResourceGroupName 2>&1
if ($rgExists -eq "true") {
    Write-Host "Resource group '$ResourceGroupName' already exists" -ForegroundColor Gray
} else {
    Write-Host "Creating resource group '$ResourceGroupName' in '$Location'..." -ForegroundColor Cyan
    az group create --name $ResourceGroupName --location $Location --output table
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to create resource group" -ForegroundColor Red
        exit 1
    }
    Write-Host "Resource group created successfully!" -ForegroundColor Green
}

# ============================================
# 3. Deploy Bicep Template
# ============================================
Write-Host "`n[3/3] Deploying DC Infrastructure..." -ForegroundColor Yellow

# Verify template files exist
if (-not (Test-Path $TemplateFile)) {
    Write-Host "ERROR: Template file not found: $TemplateFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $ParametersFile)) {
    Write-Host "ERROR: Parameters file not found: $ParametersFile" -ForegroundColor Red
    exit 1
}

Write-Host "Template: $TemplateFile" -ForegroundColor Gray
Write-Host "Parameters: $ParametersFile" -ForegroundColor Gray
Write-Host "`nStarting deployment (this may take 15-20 minutes)..." -ForegroundColor Cyan
Write-Host "Tip: Bastion deployment is typically the longest step`n" -ForegroundColor Gray

# Build deployment command
$deploymentName = "dc-infra-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

$deployCmd = "az deployment group create " +
    "--resource-group `"$ResourceGroupName`" " +
    "--name `"$deploymentName`" " +
    "--template-file `"$TemplateFile`" " +
    "--parameters `"$ParametersFile`" " +
    "--output json"

Write-Host "Deployment name: $deploymentName" -ForegroundColor Gray

# Execute deployment
$deploymentOutput = Invoke-Expression $deployCmd 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nERROR: Deployment failed!" -ForegroundColor Red
    Write-Host $deploymentOutput -ForegroundColor Red
    exit 1
}

# Parse and display outputs
try {
    $deployment = $deploymentOutput | ConvertFrom-Json
    
    Write-Host "`n=== Deployment Successful ===" -ForegroundColor Green
    Write-Host "`nProvisioning State: $($deployment.properties.provisioningState)" -ForegroundColor Cyan
    
    if ($deployment.properties.outputs) {
        Write-Host "`nDeployed Resources:" -ForegroundColor Yellow
        
        if ($deployment.properties.outputs.vmName) {
            Write-Host "  VM Name: $($deployment.properties.outputs.vmName.value)" -ForegroundColor Cyan
        }
        if ($deployment.properties.outputs.vnetId) {
            Write-Host "  VNet ID: $($deployment.properties.outputs.vnetId.value)" -ForegroundColor Gray
        }
        if ($deployment.properties.outputs.bastionId) {
            Write-Host "  Bastion ID: $($deployment.properties.outputs.bastionId.value)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "`nDeployment completed (could not parse outputs)" -ForegroundColor Yellow
}

# ============================================
# Summary
# ============================================
Write-Host "`n=== Next Steps ===" -ForegroundColor Yellow
Write-Host "1. Connect to the VM via Azure Bastion in the Azure Portal" -ForegroundColor Cyan
Write-Host "2. Run the VM setup scripts to configure Hyper-V and nested VMs" -ForegroundColor Cyan
Write-Host ""
