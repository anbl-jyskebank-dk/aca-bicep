param pubsubContainerAppNames array
param acaEnvironmentName string
param redisName string
@secure()
param redisPassword string

resource pubsubDaprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-10-01' = {
  name: '${acaEnvironmentName}/dad-pub-sub'
  properties: {
    componentType: 'pubsub.redis'
    version: 'v1'
    secrets: [
      {
        name: 'redis-password'
        value: redisPassword
      }
    ]
    metadata: [
      {
        name: 'redisHost'
        value: '${redisName}.redis.cache.windows.net:6380'
      }
      {
        name: 'redisPassword'
        secretRef: 'redis-password'
      }
      {
        name: 'enableTLS'
        value: 'true'
      }
    ]
    ignoreErrors: true
    scopes: pubsubContainerAppNames
  }
}
