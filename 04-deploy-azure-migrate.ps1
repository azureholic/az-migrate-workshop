# Azure Migration Workshop - Deploy Azure Migrate
# This script orchestrates (in parallel):
# 1. Azure Migrate infrastructure deployment (project, storage, target VNet)
# 2. Azure Migrate appliance deployment on the DC host (download + Hyper-V import)

param(
    [string]$ResourceGroupName,
    [string]$VMName = "vm-dc",
    [string]$ScriptsPath = ".\dc-scripts\az-migrate-vm",
    [string]$VMFilesPath = "C:\dc-files",
    [string]$AzureInfraTemplate = ".\azure-infra\main.bicep",
    [string]$AzureInfraParams = ".\azure-infra\main.bicepparam",
    [string]$Location
)

$ErrorActionPreference = "Stop"

# Read config from dc-infra\main.bicepparam (single source of truth)
$bicepParamFile = Join-Path $PSScriptRoot "dc-infra\main.bicepparam"
$bicepContent = Get-Content $bicepParamFile -Raw
if (-not $ResourceGroupName) { $ResourceGroupName = [regex]::Match($bicepContent, "param resourceGroupName = '([^']+)'").Groups[1].Value }
if (-not $Location) { $Location = [regex]::Match($bicepContent, "param location = '([^']+)'").Groups[1].Value }

Write-Host "`n=== Azure Migration Workshop - Deploy Azure Migrate ===" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "VM Name: $VMName" -ForegroundColor Cyan
Write-Host "Location: $Location`n" -ForegroundColor Cyan

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
# 1. Verify scripts and templates exist
# ============================================
Write-Host "[1/5] Checking scripts and templates..." -ForegroundColor Yellow

if (-not (Test-Path $ScriptsPath)) {
    Write-Host "ERROR: Scripts directory not found: $ScriptsPath" -ForegroundColor Red
    exit 1
}

$script1 = Join-Path $ScriptsPath "01-download-appliance.ps1"
$script2 = Join-Path $ScriptsPath "02-create-appliance.ps1"

foreach ($s in @($script1, $script2)) {
    if (-not (Test-Path $s)) {
        Write-Host "ERROR: Script not found: $s" -ForegroundColor Red
        exit 1
    }
}

if (-not (Test-Path $AzureInfraTemplate)) {
    Write-Host "ERROR: Bicep template not found: $AzureInfraTemplate" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $AzureInfraParams)) {
    Write-Host "ERROR: Parameters file not found: $AzureInfraParams" -ForegroundColor Red
    exit 1
}

Write-Host "All required scripts and templates found" -ForegroundColor Green

# ============================================
# 1b. Check if Azure Migrate appliance VM already exists
# ============================================
Write-Host "`nChecking if Azure Migrate appliance VM already exists on DC host..." -ForegroundColor Gray

$vmCheckOutput = az vm run-command invoke `
    --resource-group $ResourceGroupName `
    --name $VMName `
    --command-id RunPowerShellScript `
    --scripts "if (Get-VM -Name 'az-migrate' -ErrorAction SilentlyContinue) { Write-Host 'EXISTS' } else { Write-Host 'NOTFOUND' }" `
    --output json 2>$null

$vmCheckResult = ($vmCheckOutput | ConvertFrom-Json).value | Where-Object { $_.code -like '*StdOut*' } | Select-Object -ExpandProperty message
$applianceVMExists = $vmCheckResult.Trim() -eq 'EXISTS'

if ($applianceVMExists) {
    Write-Host "Azure Migrate appliance VM already exists in Hyper-V - skipping download and import" -ForegroundColor Green
} else {
    Write-Host "Appliance VM not found - will deploy" -ForegroundColor Gray
}

# ============================================
# 2. Start Azure infrastructure deployment (parallel)
# ============================================
Write-Host "`n[2/5] Starting Azure Migrate infrastructure deployment..." -ForegroundColor Yellow

$deploymentName = "azure-migrate-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Write-Host "Deployment: $deploymentName" -ForegroundColor Gray
Write-Host "Template: $AzureInfraTemplate" -ForegroundColor Gray

az deployment sub create `
    --location $Location `
    --name $deploymentName `
    --template-file $AzureInfraTemplate `
    --parameters $AzureInfraParams `
        location=$Location `
        dcResourceGroupName=$ResourceGroupName `
    --no-wait `
    --output none

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to start Azure infrastructure deployment" -ForegroundColor Red
    exit 1
}

Write-Host "Azure infrastructure deployment started in background" -ForegroundColor Green
Write-Host "Proceeding with appliance deployment on DC VM in parallel...`n" -ForegroundColor Cyan

# ============================================
# 3. Download Azure Migrate Appliance on DC VM
# ============================================
if ($applianceVMExists) {
    Write-Host "[3/5] Skipping appliance download - VM already exists" -ForegroundColor Gray
} else {
    Write-Host "[3/5] Downloading Azure Migrate Appliance ZIP on DC VM..." -ForegroundColor Yellow
    Write-Host "Target: $VMFilesPath on $VMName" -ForegroundColor Gray
    Write-Host "(This may take a while - ZIP is several GB)`n" -ForegroundColor Yellow

    Invoke-RunCommand -ScriptFile $script1 -Parameters "TargetPath=$VMFilesPath" -StepName "Download appliance"
    Write-Host "`nAppliance download completed!" -ForegroundColor Green
}

# ============================================
# 4. Extract and Import Azure Migrate VM in Hyper-V
# ============================================
if ($applianceVMExists) {
    Write-Host "[4/5] Skipping appliance import - VM already exists" -ForegroundColor Gray
} else {
    Write-Host "`n[4/5] Extracting and importing Azure Migrate VM in Hyper-V..." -ForegroundColor Yellow
    Write-Host "This will extract the ZIP and import the VM into Hyper-V`n" -ForegroundColor Gray

    Invoke-RunCommand -ScriptFile $script2 -StepName "Import appliance VM"
    Write-Host "`nAppliance VM import completed!" -ForegroundColor Green
}

# ============================================
# 5. Wait for Azure deployment + generate key
# ============================================
Write-Host "`n[5/5] Waiting for Azure infrastructure deployment to complete..." -ForegroundColor Yellow

# Wait for Bicep deployment to finish
az deployment sub wait `
    --name $deploymentName `
    --created `
    --timeout 1800 2>&1 | Out-Null

$deployState = az deployment sub show `
    --name $deploymentName `
    --query "properties.provisioningState" `
    --output tsv

if ($deployState -ne "Succeeded") {
    Write-Host "ERROR: Azure infrastructure deployment failed (state: $deployState)" -ForegroundColor Red
    az deployment sub show `
        --name $deploymentName `
        --query "properties.error" --output json
    exit 1
}

Write-Host "Azure infrastructure deployed successfully!" -ForegroundColor Green

# Retrieve deployment outputs
$deployOutputJson = az deployment sub show `
    --name $deploymentName `
    --query "properties.outputs" `
    --output json

$deployOutput = $deployOutputJson | ConvertFrom-Json
$MigrateProjectName = $deployOutput.migrateProjectName.value

# Create Azure Migrate solutions (required for discovery/assessment/migration to work)
Write-Host "`nCreating Azure Migrate solutions..." -ForegroundColor Yellow

$subscriptionId = az account show --query id --output tsv
$solutionsBaseUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Migrate/migrateProjects/$MigrateProjectName/solutions"

$solutions = @(
    @{
        name = "Servers-Discovery-ServerDiscovery"
        body = @{
            properties = @{
                tool = "ServerDiscovery"
                goal = "Servers"
                purpose = "Discovery"
                status = "Inactive"
            }
        }
    },
    @{
        name = "Servers-Assessment-ServerAssessment"
        body = @{
            properties = @{
                tool = "ServerAssessment"
                goal = "Servers"
                purpose = "Assessment"
                status = "Active"
            }
        }
    },
    @{
        name = "Servers-Migration-ServerMigration"
        body = @{
            properties = @{
                tool = "ServerMigration"
                goal = "Servers"
                purpose = "Migration"
                status = "Active"
            }
        }
    }
)

foreach ($solution in $solutions) {
    $solutionUri = "$solutionsBaseUri/$($solution.name)?api-version=2018-09-01-preview"
    $solutionBody = $solution.body | ConvertTo-Json -Depth 5 -Compress
    $tempBodyFile = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tempBodyFile, $solutionBody)
    
    try {
        az rest --method put --uri $solutionUri --body "@$tempBodyFile" --output none 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Created solution: $($solution.name)" -ForegroundColor Green
        } else {
            Write-Host "  Warning: Could not create solution: $($solution.name)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Warning: Error creating solution $($solution.name): $_" -ForegroundColor Yellow
    }
    Remove-Item $tempBodyFile -Force -ErrorAction SilentlyContinue
}

Write-Host "Solutions created" -ForegroundColor Green

Write-Host "`nDeployed Azure resources:" -ForegroundColor Cyan
Write-Host "  Migrate Project:  $($deployOutput.migrateProjectName.value)" -ForegroundColor Gray
Write-Host "  Target VNet:      $($deployOutput.targetVnetName.value)" -ForegroundColor Gray
Write-Host "  PostgreSQL:       $($deployOutput.postgresServerFqdn.value)" -ForegroundColor Gray
Write-Host "  DMS:              $($deployOutput.dmsName.value)" -ForegroundColor Gray

# ============================================
# Summary
# ============================================
Write-Host "`n=== Azure Migrate Deployment Complete ===" -ForegroundColor Yellow

Write-Host "`nAzure Resources:" -ForegroundColor Yellow
Write-Host "  - Migrate Project:  $($deployOutput.migrateProjectName.value)" -ForegroundColor Cyan
Write-Host "  - Target VNet:      $($deployOutput.targetVnetName.value) (in $($deployOutput.migrationTargetResourceGroupName.value))" -ForegroundColor Cyan
Write-Host "  - VNet Peering:     vnet-dc <-> vnet-migrate-target" -ForegroundColor Cyan
Write-Host "  - PostgreSQL:       $($deployOutput.postgresServerFqdn.value) (in $($deployOutput.migrationTargetResourceGroupName.value))" -ForegroundColor Cyan
Write-Host "  - Database Migration Service: $($deployOutput.dmsName.value)" -ForegroundColor Cyan

Write-Host "`nAppliance VM on DC host:" -ForegroundColor Yellow
Write-Host "  - Downloaded and imported into Hyper-V" -ForegroundColor Cyan
Write-Host "  - VM 'az-migrate' running (2 vCPUs, 8GB RAM, NAT-Switch)" -ForegroundColor Cyan

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Connect to DC VM via Azure Bastion" -ForegroundColor Cyan
Write-Host "2. Open Hyper-V Manager and connect to 'az-migrate' VM" -ForegroundColor Cyan
Write-Host "3. Generate appliance key in Azure Portal:" -ForegroundColor Cyan
Write-Host "   Azure Migrate > Servers, databases and web apps > Discover > Generate Key" -ForegroundColor Gray
Write-Host "4. Complete the Azure Migrate appliance configuration wizard" -ForegroundColor Cyan
Write-Host "5. Configure discovery for the nested VMs" -ForegroundColor Cyan
Write-Host ""

exit 0
