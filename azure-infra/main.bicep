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

// Recovery Services Vault backup configuration
resource backupStorageConfig 'Microsoft.RecoveryServices/vaults/backupstorageconfig@2024-04-01' = {
  parent: recoveryVault
  name: 'vaultstorageconfig'
  properties: {
    storageModelType: 'GeoRedundant'
    crossRegionRestoreFlag: false
  }
}

// Azure Migrate Project
resource migrateProject 'Microsoft.Migrate/migrateProjects@2020-05-01' = {
  name: migrateProjectName
  location: location
  properties: {
    registeredTools: [
      'ServerAssessment'
      'ServerMigration'
    ]
  }
  tags: {
    Environment: 'Migration'
    Purpose: 'Azure Migrate Workshop'
  }
}

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
