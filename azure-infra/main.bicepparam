using './main.bicep'

// Passed as CLI overrides from dc-infra/main.bicepparam (single source of truth)
param location = ''
param dcResourceGroupName = ''
param migrationTargetResourceGroupName = 'rg-migration-target'
param migrateProjectBaseName = 'az-migrate-workshop'
param vnetAddressPrefix = '10.1.0.0/16'
param subnetAddressPrefix = '10.1.0.0/24'
param postgresAdminLogin = 'pgadmin'
param postgresAdminPassword = 'P@ssw0rd1234!' // Set your password here or pass via CLI
