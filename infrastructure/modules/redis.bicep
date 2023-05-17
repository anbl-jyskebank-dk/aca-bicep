param location string
param acaEnvironmentName string
param skuName string
param skuCapacity int
param skuFamily string
param subnetId string
param vnetID string

resource redis 'Microsoft.Cache/redis@2022-06-01' = {
  name: 'redis-${acaEnvironmentName}'
  location: location
  properties: {
    redisVersion: '6.0'
    sku: {
      name: skuName
      capacity: skuCapacity
      family: skuFamily
    }
    enableNonSslPort: false
    publicNetworkAccess: 'Disabled'
    redisConfiguration: {
      'maxmemory-reserved': '30'
      'maxfragmentationmemory-reserved': '30'
      'maxmemory-delta': '30'
    }
  }
}

resource redisCachePrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: 'pep-redis-${acaEnvironmentName}'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'pep-redis-${acaEnvironmentName}'
        properties: {
          privateLinkServiceId: redis.id
          groupIds: [
            'redisCache'
          ]
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

var privateDnsZoneName = 'privatelink.redis.cache.windows.net'

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  
  resource privateDnsZoneVNetLink 'virtualNetworkLinks' = {
    name: uniqueString(vnetID)
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnetID
      }
    }
  }

  resource privateDnsZoneARecord 'A' = {
    name: redis.name
    properties: {
      aRecords: [
        {
          ipv4Address: redisCachePrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
        }
      ]
      ttl: 3600
    }
  }
}

output redisName string = redis.name
output redisKey string = listKeys(redis.id, '2022-06-01').primaryKey
