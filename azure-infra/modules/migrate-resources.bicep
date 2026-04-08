@description('Location for resources')
param location string

@description('Base name for the Azure Migrate project')
param migrateProjectBaseName string

@description('Name of the storage account for replication')
param replicationStorageAccountName string = 'strepl${uniqueString(resourceGroup().id)}'

resource replicationStorage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: replicationStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
  tags: {
    Environment: 'Migration'
    Purpose: 'Replication'
  }
}

resource migrateProject 'Microsoft.Migrate/migrateProjects@2020-05-01' = {
  name: '${migrateProjectBaseName}-${uniqueString(resourceGroup().id)}'
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

output migrateProjectId string = migrateProject.id
output migrateProjectName string = migrateProject.name
output replicationStorageAccountId string = replicationStorage.id
output replicationStorageAccountName string = replicationStorage.name
