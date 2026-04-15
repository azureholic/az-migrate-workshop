using './main.bicep'

param resourceGroupName = 'rg-migrate-ws'
param location = 'swedencentral'
// this is used to connect to the Datacenter VM
// when you run tunnel-dc.ps1 use these credentials
param adminUsername = 'azureuser'
param adminPassword = '$uper$ecretP@ssw0rd'
