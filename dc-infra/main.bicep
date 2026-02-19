@description('Location for all resources')
param location string = resourceGroup().location

@description('Admin username for the VM')
param adminUsername string

@description('Admin password for the VM')
@secure()
param adminPassword string

@description('Current user object ID for blob access')
param currentUserObjectId string = ''

// NSG for default subnet - allows Bastion tunnel traffic
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-dc-default'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-Bastion-Tunnel-RDP'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '10.0.1.0/26'  // AzureBastionSubnet
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '33389'
        }
      }
      {
        name: 'Allow-RDP-From-Bastion'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '10.0.1.0/26'  // AzureBastionSubnet
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}

// Public IP for NAT Gateway
resource natGatewayPublicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-natgw-dc'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// NAT Gateway for outbound traffic
resource natGateway 'Microsoft.Network/natGateways@2024-05-01' = {
  name: 'natgw-dc'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 10
    publicIpAddresses: [
      {
        id: natGatewayPublicIp.id
      }
    ]
  }
}

// VNet with 2 subnets
module vnet 'br/public:avm/res/network/virtual-network:0.7.1' = {
  name: 'vnet-dc-deployment'
  params: {
    name: 'vnet-dc'
    location: location
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    subnets: [
      {
        name: 'default'
        addressPrefix: '10.0.0.0/24'
        networkSecurityGroupResourceId: nsg.id
        natGatewayResourceId: natGateway.id
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '10.0.1.0/26'
      }
    ]
  }
}

// Storage Account for scripts
module storageAccount 'br/public:avm/res/storage/storage-account:0.15.0' = {
  name: 'storage-scripts-deployment'
  params: {
    name: 'stscripts${uniqueString(resourceGroup().id)}'
    location: location
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    allowSharedKeyAccess: false
    allowBlobPublicAccess: true
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    blobServices: {
      containers: [
        {
          name: 'scripts'
          publicAccess: 'None'
        }
      ]
    }
    roleAssignments: !empty(currentUserObjectId) ? [
      {
        principalId: currentUserObjectId
        roleDefinitionIdOrName: 'Storage Blob Data Contributor'
        principalType: 'User'
      }
      {
        principalId: vm.outputs.systemAssignedMIPrincipalId
        roleDefinitionIdOrName: 'Storage Blob Data Reader'
        principalType: 'ServicePrincipal'
      }
    ] : [
      {
        principalId: vm.outputs.systemAssignedMIPrincipalId
        roleDefinitionIdOrName: 'Storage Blob Data Reader'
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

// VM with Windows Server
module vm 'br/public:avm/res/compute/virtual-machine:0.11.0' = {
  name: 'vm-dc-deployment'
  params: {
    name: 'vm-dc'
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    zone: 0
    encryptionAtHost: false
    imageReference: {
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      sku: '2022-datacenter-azure-edition'
      version: 'latest'
    }
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: vnet.outputs.subnetResourceIds[0]
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    osType: 'Windows'
    vmSize: 'Standard_D8s_v5'
    managedIdentities: {
      systemAssigned: true
    }
  }
}

// Azure Bastion Standard SKU (enables tunneling for native client access)
module bastion 'br/public:avm/res/network/bastion-host:0.7.0' = {
  name: 'bastion-dc-deployment'
  params: {
    name: 'bastion-dc'
    location: location
    virtualNetworkResourceId: vnet.outputs.resourceId
    skuName: 'Standard'
  }
}

output vnetId string = vnet.outputs.resourceId
output vmId string = vm.outputs.resourceId
output bastionId string = bastion.outputs.resourceId
output storageAccountName string = storageAccount.outputs.name
output vmName string = vm.outputs.name
output natGatewayId string = natGateway.id
output natGatewayPublicIp string = natGatewayPublicIp.properties.ipAddress
