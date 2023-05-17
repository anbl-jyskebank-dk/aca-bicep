param name string
param location string

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: name
  location: location
}

output identityPrincipalId string = identity.properties.principalId
output identityClientId string = identity.properties.clientId
output identityId string = identity.id
