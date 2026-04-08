# Azure Bastion Tunnel + RDP - Connect to nested Azure Migrate Appliance

param(
    [string]$ResourceGroupName,
    [string]$VMName = "vm-dc"
)

# Read config from dc-infra\main.bicepparam (single source of truth)
$bicepParamFile = Join-Path $PSScriptRoot "dc-infra\main.bicepparam"
$bicepContent = Get-Content $bicepParamFile -Raw
if (-not $ResourceGroupName) { $ResourceGroupName = [regex]::Match($bicepContent, "param resourceGroupName = '([^']+)'").Groups[1].Value }

$targetResourceId = az vm show --resource-group $ResourceGroupName --name $VMName --query id -o tsv

Write-Host "Connecting to Azure Migrate appliance (nested VM)..." -ForegroundColor Cyan

# Start the bastion tunnel in a new terminal window
$tunnelCommand = "az network bastion tunnel --name bastion-dc --resource-group $ResourceGroupName --target-resource-id $targetResourceId --resource-port 33389 --port 33389"
Start-Process pwsh -ArgumentList "-NoExit", "-Command", $tunnelCommand

Write-Host "Waiting for tunnel to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Create .rdp file with username pre-filled and launch RDP connection
$rdpFile = Join-Path $env:TEMP "appl-tunnel.rdp"
@"
full address:s:localhost:33389
username:s:Administrator
"@ | Set-Content $rdpFile

Write-Host "Launching RDP to localhost:33389..." -ForegroundColor Green
mstsc $rdpFile
