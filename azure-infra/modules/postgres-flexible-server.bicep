@description('Location for the PostgreSQL server')
param location string

@description('PostgreSQL server name')
param serverName string

@description('PostgreSQL administrator login')
param administratorLogin string

@secure()
@description('PostgreSQL administrator password')
param administratorLoginPassword string

@description('PostgreSQL SKU name')
param skuName string = 'Standard_B1ms'

@description('PostgreSQL SKU tier')
param skuTier string = 'Burstable'

@description('PostgreSQL storage size in GB')
param storageSizeGB int = 32

@description('PostgreSQL version')
param version string = '16'

@description('Delegated subnet resource ID for VNet integration (empty = public access)')
param delegatedSubnetResourceId string = ''

@description('Private DNS zone resource ID (required when using VNet integration)')
param privateDnsZoneArmResourceId string = ''

resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: serverName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    version: version
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storage: {
      storageSizeGB: storageSizeGB
    }
    network: !empty(delegatedSubnetResourceId) ? {
      delegatedSubnetResourceId: delegatedSubnetResourceId
      privateDnsZoneArmResourceId: privateDnsZoneArmResourceId
    } : {
      publicNetworkAccess: 'Enabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
  }
}

output serverName string = postgresServer.name
output serverFqdn string = postgresServer.properties.fullyQualifiedDomainName
output serverId string = postgresServer.id
