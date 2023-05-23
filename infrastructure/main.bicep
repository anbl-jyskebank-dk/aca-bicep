targetScope='subscription'

param acaEnvironmentName string
param location string
param resourceGroupName string
param acrName string
param imageName string
param imageVersion string
param vnetName string
//param pubsubContainerAppNames array
//param redisSkuCapacity int
//param redisSkuFamily string
//param redisSkuName string
//param vnetID string
//param subnetId string

module identity 'modules/identity.bicep' = {
  name: 'defaultAppIdentity'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    name: 'defaultAppIdentity'
  }
}

/*module redis 'modules/redis.bicep' = {
  name: 'redis'
  scope: resourceGroup(resourceGroupName)
  params: {
    acaEnvironmentName: acaEnvironmentName
    location: location
    skuCapacity: redisSkuCapacity
    skuFamily: redisSkuFamily
    skuName: redisSkuName
    vnetID: vnetID
    subnetId: subnetId
  }
}*/

module acr 'modules/acr.bicep' = {
  name: 'acr'
  scope: resourceGroup(resourceGroupName)
  params: {
    acrName: acrName
    principalID: identity.outputs.identityPrincipalId
  }
}

module acaEnvironment 'modules/acaEnvironment.bicep' = {
  name: acaEnvironmentName
  scope: resourceGroup(resourceGroupName) 
  params: {
    acaEnvironmentName: acaEnvironmentName
    identityResourceId: identity.outputs.identityId
    location: location
    acrName: acrName
    imageVersion: imageVersion
    imageName: imageName
    vnetName: vnetName
  }
  dependsOn: [
    acr
  ]
}

/*module dapr 'modules/daprComponents.bicep' = {
  name: 'dapr'
  scope: resourceGroup(resourceGroupName)
  params: {
    acaEnvironmentName: acaEnvironmentName
    pubsubContainerAppNames: pubsubContainerAppNames
    redisPassword: redis.outputs.redisKey
    redisName: redis.outputs.redisName
  }
  dependsOn: [
    redis
    acaEnvironment
  ]
}*/
