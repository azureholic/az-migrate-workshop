@description('Location for the Database Migration Service')
param location string

@description('Name of the Database Migration Service')
param dmsName string

resource dms 'Microsoft.DataMigration/sqlMigrationServices@2022-03-30-preview' = {
  name: dmsName
  location: location
  properties: {}
}

output dmsId string = dms.id
output dmsName string = dms.name
