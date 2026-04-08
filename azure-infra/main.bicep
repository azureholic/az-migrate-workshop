targetScope = 'subscription'

@description('Location for all resources')
param location string

@description('Name of the DC resource group (source)')
param dcResourceGroupName string

@description('Name of the migration target resource group')
param migrationTargetResourceGroupName string = 'rg-migration-target'

@description('Base name for the Azure Migrate project (timestamp will be appended for uniqueness)')
param migrateProjectBaseName string = 'migrate-project'

@description('Virtual Network address prefix for migrated VMs')
param vnetAddressPrefix string = '10.1.0.0/16'

@description('Subnet address prefix for migrated VMs')
param subnetAddressPrefix string = '10.1.0.0/24'

@description('PostgreSQL server name')
param postgresServerName string = 'psql-migrate-target-${uniqueString(subscription().subscriptionId, migrationTargetResourceGroupName)}'

@description('PostgreSQL administrator login')
param postgresAdminLogin string = 'pgadmin'

@secure()
@description('PostgreSQL administrator password')
param postgresAdminPassword string

@description('PostgreSQL runtime server name')
param postgresRuntimeServerName string = 'psql-migrate-runtime-${uniqueString(subscription().subscriptionId, migrationTargetResourceGroupName)}'

// Create the migration target resource group
resource migrationTargetRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: migrationTargetResourceGroupName
  location: location
}

// Deploy the migration target VNet into the new resource group
module targetVnet 'modules/migration-target-vnet.bicep' = {
  name: 'migration-target-vnet'
  scope: migrationTargetRg
  params: {
    location: location
    vnetAddressPrefix: vnetAddressPrefix
    subnetAddressPrefix: subnetAddressPrefix
  }
}

// Deploy PostgreSQL Flexible Server into the migration target resource group
module postgresServer 'modules/postgres-flexible-server.bicep' = {
  name: 'postgres-flexible-server'
  scope: migrationTargetRg
  params: {
    location: location
    serverName: postgresServerName
    administratorLogin: postgresAdminLogin
    administratorLoginPassword: postgresAdminPassword
  }
}

// Deploy Private DNS Zone for PostgreSQL runtime server
module postgresDnsZone 'modules/postgres-private-dns.bicep' = {
  name: 'postgres-private-dns'
  scope: migrationTargetRg
  params: {
    vnetId: targetVnet.outputs.vnetId
  }
}

// Deploy PostgreSQL runtime server (VNet integrated) for database migration
module postgresRuntimeServer 'modules/postgres-flexible-server.bicep' = {
  name: 'postgres-runtime-server'
  scope: migrationTargetRg
  params: {
    location: location
    serverName: postgresRuntimeServerName
    administratorLogin: postgresAdminLogin
    administratorLoginPassword: postgresAdminPassword
    delegatedSubnetResourceId: targetVnet.outputs.postgresMigrateSubnetId
    privateDnsZoneArmResourceId: postgresDnsZone.outputs.dnsZoneId
  }
}

// Deploy the Azure Migrate project + storage into the DC resource group
module migrateResources 'modules/migrate-resources.bicep' = {
  name: 'migrate-resources'
  scope: resourceGroup(dcResourceGroupName)
  params: {
    location: location
    migrateProjectBaseName: migrateProjectBaseName
  }
}

// Peering: vnet-migrate-target -> vnet-dc
module peeringTargetToDc 'modules/vnet-peering.bicep' = {
  name: 'peering-target-to-dc'
  scope: migrationTargetRg
  params: {
    localVnetName: targetVnet.outputs.vnetName
    remoteVnetId: resourceId(subscription().subscriptionId, dcResourceGroupName, 'Microsoft.Network/virtualNetworks', 'vnet-dc')
    peeringName: 'peer-to-vnet-dc'
  }
}

// Peering: vnet-dc -> vnet-migrate-target
module peeringDcToTarget 'modules/vnet-peering.bicep' = {
  name: 'peering-dc-to-target'
  scope: resourceGroup(dcResourceGroupName)
  params: {
    localVnetName: 'vnet-dc'
    remoteVnetId: targetVnet.outputs.vnetId
    peeringName: 'peer-to-vnet-migrate-target'
  }
}

// Outputs
output migrateProjectId string = migrateResources.outputs.migrateProjectId
output migrateProjectName string = migrateResources.outputs.migrateProjectName
output targetVnetId string = targetVnet.outputs.vnetId
output targetVnetName string = targetVnet.outputs.vnetName
output targetSubnetId string = targetVnet.outputs.subnetId
output replicationStorageAccountId string = migrateResources.outputs.replicationStorageAccountId
output replicationStorageAccountName string = migrateResources.outputs.replicationStorageAccountName
output migrationTargetResourceGroupName string = migrationTargetRg.name
output postgresServerName string = postgresServer.outputs.serverName
output postgresServerFqdn string = postgresServer.outputs.serverFqdn
output postgresRuntimeServerName string = postgresRuntimeServer.outputs.serverName
output postgresRuntimeServerFqdn string = postgresRuntimeServer.outputs.serverFqdn
