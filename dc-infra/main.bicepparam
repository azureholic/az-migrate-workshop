using './main.bicep'

param location = 'swedencentral'
param adminUsername = 'azureuser'
param adminPassword = '$uper$ecretP@ssw0rd' // Set your password here or pass via CLI
// currentUserObjectId will be passed from deployment script
