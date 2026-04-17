# Azure Bastion Tunnel + RDP - Connect to DC VM
#
# Note: Uses local port 33390 instead of 3389 to avoid Windows 11
#       mstsc blocking loopback connections on port 3389.

param(
    [string]$ResourceGroupName,
    [string]$VMName = "vm-dc"
)

# Read config from dc-infra\main.bicepparam (single source of truth)
$bicepParamFile = Join-Path $PSScriptRoot "dc-infra\main.bicepparam"
$bicepContent = Get-Content $bicepParamFile -Raw
if (-not $ResourceGroupName) { $ResourceGroupName = [regex]::Match($bicepContent, "param resourceGroupName = '([^']+)'").Groups[1].Value }

$targetResourceId = az vm show --resource-group $ResourceGroupName --name $VMName --query id -o tsv
Write-Host "Target Resource ID: $targetResourceId" -ForegroundColor Cyan

# Read credentials from dc-infra\main.bicepparam
$bicepParamFile = Join-Path $PSScriptRoot "dc-infra\main.bicepparam"
$bicepContent = Get-Content $bicepParamFile -Raw
$adminUsername = [regex]::Match($bicepContent, "param adminUsername = '([^']+)'").Groups[1].Value
$adminPassword = [regex]::Match($bicepContent, "param adminPassword = '([^']+)'").Groups[1].Value

Write-Host "Connecting to DC VM (vm-dc) as $adminUsername..." -ForegroundColor Cyan

# Start the bastion tunnel in a new terminal window
$tunnelCommand = "az network bastion tunnel --name bastion-dc --resource-group $ResourceGroupName --target-resource-id $targetResourceId --resource-port 3389 --port 33390"
Start-Process pwsh -ArgumentList "-NoExit", "-Command", $tunnelCommand

Write-Host "Waiting for tunnel to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Create .rdp file with username pre-filled and launch RDP connection
$rdpFile = Join-Path $env:TEMP "dc-tunnel.rdp"
@"
full address:s:localhost:33390
username:s:$adminUsername
"@ | Set-Content $rdpFile

# Copy password to clipboard for easy pasting
Set-Clipboard -Value $adminPassword
Write-Host "Password copied to clipboard - just Ctrl+V in the RDP prompt" -ForegroundColor Yellow

Write-Host "Launching RDP to localhost:33390..." -ForegroundColor Green
mstsc $rdpFile
