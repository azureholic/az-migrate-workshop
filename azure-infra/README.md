# Azure Migrate Infrastructure

This Bicep template deploys the Azure Migrate infrastructure for server migration.

## Resources Deployed

- **Azure Migrate Project**: Central hub for assessment and migration
  - Tools: Server Assessment, Server Migration
  
- **Recovery Services Vault**: For VM replication and migration
  - SKU: Standard (RS0)
  - Storage: Geo-Redundant
  
- **Storage Account**: For replication data
  - Type: Standard LRS (locally redundant)
  - Secure: HTTPS only, TLS 1.2 minimum
  
- **Virtual Network**: Target network for migrated VMs
  - Address space: 10.1.0.0/16
  - Subnet: snet-migrated-vms (10.1.0.0/24)

## Deployment

### Using PowerShell

```powershell
# Create resource group
New-AzResourceGroup -Name rg-azure-migrate -Location swedencentral

# Deploy
New-AzResourceGroupDeployment `
  -ResourceGroupName rg-azure-migrate `
  -TemplateFile main.bicep `
  -TemplateParameterFile main.bicepparam
```

### Using Azure CLI

```bash
# Create resource group
az group create --name rg-azure-migrate --location swedencentral

# Deploy
az deployment group create \
  --resource-group rg-azure-migrate \
  --template-file main.bicep \
  --parameters main.bicepparam
```

## Post-Deployment Steps

1. **Download and Configure Azure Migrate Appliance**
   - Navigate to Azure Migrate in the portal
   - Go to "Servers, databases and web apps"
   - Click "Discover" and download the appliance

2. **Set Up Replication**
   - Configure the Recovery Services Vault for replication
   - Set up the replication appliance in your source environment

3. **Start Assessment**
   - Use the Server Assessment tool to analyze your on-premises VMs
   - Review recommendations and dependencies

4. **Configure Migration**
   - Select VMs to migrate
   - Configure target settings (network, size, etc.)
   - Start test migration before production cutover

## Configuration

Edit `main.bicepparam` to customize:
- Location/Region
- Project and vault names
- Network address spaces
- Storage account settings

## Integration with DC Infrastructure

The migrated VMs will use the target VNet (10.1.0.0/16) to separate migration traffic from the domain controller infrastructure (10.0.0.0/16 in dc-infra).

You can peer these networks if needed:

```powershell
# Peer the networks (after deploying both)
az network vnet peering create \
  --name dc-to-migrate \
  --resource-group rg-migrate-workshop \
  --vnet-name vnet-dc \
  --remote-vnet $(az network vnet show -g rg-azure-migrate -n vnet-migrate-target --query id -o tsv) \
  --allow-vnet-access
```

## Notes

- The storage account name is auto-generated with a unique suffix
- Recovery Services Vault is configured for geo-redundant storage
- Azure Migrate project is pre-configured with Server Assessment and Migration tools
- Ensure proper network connectivity between source and Azure environments
