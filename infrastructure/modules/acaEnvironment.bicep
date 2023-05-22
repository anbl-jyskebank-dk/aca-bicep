param location string
param acaEnvironmentName string
param identityResourceId string
param acrName string
param imageName string
param imageVersion string
param vnetName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'workspace-${acaEnvironmentName}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    features: {
      searchVersion: 1
    }
    retentionInDays: 31
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'app-Insights-${acaEnvironmentName}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource environment 'Microsoft.App/managedEnvironments@2022-10-01' = {
  name: acaEnvironmentName
  location: location
  sku: {
    name: 'Consumption'
  }
  properties: {
    daprAIInstrumentationKey: appInsights.properties.InstrumentationKey
    zoneRedundant: false
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    vnetConfiguration: {
      internal: true
      infrastructureSubnetId: resourceId('Microsoft.Network/VirtualNetworks/subnets', '${vnetName}', 'infrastructure')
      platformReservedCidr: '10.1.0.0/16'
      platformReservedDnsIP: '10.1.0.2'
      dockerBridgeCidr: '10.2.0.1/16'
    }
  }
}

resource defaultApp 'Microsoft.App/containerApps@2022-11-01-preview' = {
  name: 'hello-world'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityResourceId}':{}
    }
  }
  properties: {
    managedEnvironmentId: environment.id
    template: {
      containers: [
        {
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsights.properties.ConnectionString
            }
          ]
          /*probes: [
            {
              type: 'Liveness'
              httpGet: {
                port: 80
                path: 'your url'
              }
              periodSeconds: 240
            }
          ]*/
          image: '${acrName}.azurecr.io/${imageName}:${imageVersion}'
          name: 'hello-world'
          resources: {
            cpu: '0.5'
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
    configuration: {
      registries: [
        {
          identity: identityResourceId
          server: '${acrName}.azurecr.io'
        }
      ]
      /*dapr: {
        enabled: true
        appId: 'hello-world'
        appProtocol: 'http'
        appPort: 80
        enableApiLogging: true
        httpMaxRequestSize: 4
        httpReadBufferSize: 4
        logLevel: 'info'
      }*/
      activeRevisionsMode: 'Single'
      ingress: {
        targetPort: 80
        external: true
        transport: 'http'
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
    }
  }
}
