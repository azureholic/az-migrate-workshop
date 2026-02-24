@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the Azure Migrate project')
param migrateProjectName string = 'migrate-project'

@description('Virtual Network address prefix for migrated VMs')
param vnetAddressPrefix string = '10.1.0.0/16'

@description('Subnet address prefix for migrated VMs')
param subnetAddressPrefix string = '10.1.0.0/24'

// Virtual Network for migrated VMs
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-migrate-target'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-migrated-vms'
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
    ]
  }
}

// Azure Migrate Project with System Assigned Identity
resource migrateProject 'Microsoft.Migrate/migrateProjects@2020-05-01' = {
  name: migrateProjectName
  location: location
  #disable-next-line BCP187
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
  #disable-next-line BCP187
  tags: {
    Environment: 'Migration'
    Purpose: 'Azure Migrate Workshop'
  }
}

// Solutions are created via ARM deployment since Bicep doesn't have direct resource type
// We use deploymentScripts or nested templates. For simplicity, we'll create them via REST in the deploy script.
// The migrate project needs these solutions to function properly:
// - Servers-Assessment-ServerAssessment
// - Servers-Discovery-ServerDiscovery
// - Servers-Migration-ServerMigration

// Outputs
output migrateProjectId string = migrateProject.id
output migrateProjectName string = migrateProject.name
output targetVnetId string = vnet.id
output targetVnetName string = vnet.name
output targetSubnetId string = vnet.properties.subnets[0].id
