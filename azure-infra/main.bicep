@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the Azure Migrate project')
param migrateProjectName string = 'migrate-project'

@description('Name of the Recovery Services Vault for replication')
param recoveryVaultName string = 'rsv-migrate'

@description('Name of the Storage Account for replication data')
param replicationStorageAccountName string = 'stmigrate${uniqueString(resourceGroup().id)}'

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

// Storage Account for replication data
resource replicationStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: replicationStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// Recovery Services Vault for Azure Migrate
resource recoveryVault 'Microsoft.RecoveryServices/vaults@2024-04-01' = {
  name: recoveryVaultName
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

// Azure Migrate Project with System Assigned Identity
resource migrateProject 'Microsoft.Migrate/migrateProjects@2020-05-01' = {
  name: migrateProjectName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    Environment: 'Migration'
    Purpose: 'Azure Migrate Workshop'
  }
}

// Grant Azure Migrate project access to the replication storage account
// Storage Blob Data Contributor role (ba92f5b4-2d11-453d-a403-e96b0029c9fe)
resource migrateStorageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(replicationStorageAccount.id, migrateProject.id, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  scope: replicationStorageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: migrateProject.identity.principalId
    principalType: 'ServicePrincipal'
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
output recoveryVaultId string = recoveryVault.id
output recoveryVaultName string = recoveryVault.name
output replicationStorageAccountId string = replicationStorageAccount.id
output replicationStorageAccountName string = replicationStorageAccount.name
output targetVnetId string = vnet.id
output targetVnetName string = vnet.name
output targetSubnetId string = vnet.properties.subnets[0].id
