# Azure Bastion Tunnel - Connect to DC VM or nested Azure Migrate Appliance via RDP
# 
# Usage:
#   .\tunnel.ps1                    # Connect to Azure Migrate appliance (default)
#   .\tunnel.ps1 -Target AzMigrate  # Connect to Azure Migrate appliance
#   .\tunnel.ps1 -Target DC         # Connect to DC VM directly
#
# Note: DC target uses local port 33390 instead of 3389 to avoid Windows 11
#       mstsc blocking loopback connections on port 3389.

param(
    [string]$ResourceGroupName = "rg-migrate-workshop",
    [string]$VMName = "vm-dc",
    [ValidateSet("AzMigrate", "DC")]
    [string]$Target = "AzMigrate"
)

$targetResourceId = az vm show --resource-group $ResourceGroupName --name $VMName --query id -o tsv

switch ($Target) {
    "DC" {
        $resourcePort = 3389
        $localPort = 33390
        Write-Host "Connecting to DC VM (vm-dc)..." -ForegroundColor Cyan
        Write-Host "Once connected, RDP to localhost:$localPort" -ForegroundColor Yellow
    }
    "AzMigrate" {
        $resourcePort = 33389
        $localPort = 33389
        Write-Host "Connecting to Azure Migrate appliance (nested VM)..." -ForegroundColor Cyan
        Write-Host "Once connected, RDP to localhost:$localPort" -ForegroundColor Yellow
    }
}

az network bastion tunnel --name bastion-dc --resource-group $ResourceGroupName --target-resource-id $targetResourceId --resource-port $resourcePort --port $localPort
