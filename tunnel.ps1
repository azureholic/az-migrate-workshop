# Azure Bastion Tunnel - Connect to DC VM or nested Azure Migrate Appliance via RDP
# 
# Usage:
#   .\tunnel.ps1                    # Connect to Azure Migrate appliance (default)
#   .\tunnel.ps1 -Target AzMigrate  # Connect to Azure Migrate appliance
#   .\tunnel.ps1 -Target DC         # Connect to DC VM directly

param(
    [string]$ResourceGroupName = "rg-migrate-workshop",
    [string]$VMName = "vm-dc",
    [ValidateSet("AzMigrate", "DC")]
    [string]$Target = "AzMigrate"
)

$targetResourceId = az vm show --resource-group $ResourceGroupName --name $VMName --query id -o tsv

switch ($Target) {
    "DC" {
        $port = 3389
        Write-Host "Connecting to DC VM (vm-dc) on port $port..." -ForegroundColor Cyan
        Write-Host "Once connected, RDP to localhost:$port" -ForegroundColor Yellow
    }
    "AzMigrate" {
        $port = 33389
        Write-Host "Connecting to Azure Migrate appliance (nested VM) on port $port..." -ForegroundColor Cyan
        Write-Host "Once connected, RDP to localhost:$port" -ForegroundColor Yellow
    }
}

az network bastion tunnel --name bastion-dc --resource-group $ResourceGroupName --target-resource-id $targetResourceId --resource-port $port --port $port
