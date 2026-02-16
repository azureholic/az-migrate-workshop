using './main.bicep'

param location = 'swedencentral'
param migrateProjectName = 'az-migrate-workshop'
param recoveryVaultName = 'rsv-migrate'
param vnetAddressPrefix = '10.1.0.0/16'
param subnetAddressPrefix = '10.1.0.0/24'
