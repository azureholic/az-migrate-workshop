@description('Location for the VNet')
param location string

@description('Virtual Network address prefix')
param vnetAddressPrefix string

@description('Subnet address prefix')
param subnetAddressPrefix string

@description('Subnet address prefix for PostgreSQL migration runtime')
param postgresMigrateSubnetAddressPrefix string = '10.1.1.0/24'

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
      {
        name: 'snet-postgres-migrate'
        properties: {
          addressPrefix: postgresMigrateSubnetAddressPrefix
          delegations: [
            {
              name: 'Microsoft.DBforPostgreSQL.flexibleServers'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output subnetId string = vnet.properties.subnets[0].id
output postgresMigrateSubnetId string = vnet.properties.subnets[1].id
