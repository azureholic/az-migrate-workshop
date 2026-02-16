# Azure Bastion Tunnel - Connect to Azure Migrate Appliance via RDP
# Port 33389 on the DC VM is forwarded to the nested az-migrate VM's RDP port (3389)

param(
    [string]$ResourceGroupName = "rg-migrate-workshop",
    [string]$VMName = "vm-dc",
    [int]$Port = 33389
)

$targetResourceId = az vm show --resource-group $ResourceGroupName --name $VMName --query id -o tsv

az network bastion tunnel --name bastion-dc --resource-group $ResourceGroupName --target-resource-id $targetResourceId --resource-port $Port --port $Port
