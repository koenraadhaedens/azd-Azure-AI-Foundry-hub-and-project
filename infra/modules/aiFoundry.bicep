// ============================================================================
// AI Foundry Module - Hub and Project (Machine Learning Services Workspaces)
// ============================================================================

@description('Azure region for the resources')
param location string

@description('Tags to apply to all resources')
param tags object = {}

@description('Name of the AI Foundry Hub')
param aiHubName string

@description('Name of the AI Foundry Project')
param aiProjectName string

@description('Display name for the Hub')
param aiHubDisplayName string = 'AI Foundry Hub'

@description('Display name for the Project')
param aiProjectDisplayName string = 'AI Foundry Project'

@description('Description for the Hub')
param aiHubDescription string = 'Azure AI Foundry Hub for centralized AI resource management'

@description('Description for the Project')
param aiProjectDescription string = 'Azure AI Foundry Project for AI development'

@description('Key Vault ID for secrets')
param keyVaultId string

@description('Storage Account ID for data')
param storageAccountId string

@description('Container Registry ID')
param containerRegistryId string

@description('Application Insights ID for monitoring')
param applicationInsightsId string

@description('Cognitive Services account ID (optional)')
param cognitiveServicesId string = ''

@description('Cognitive Services endpoint (optional)')
param cognitiveServicesEndpoint string = ''

@description('Subnet ID for private endpoints')
param subnetId string

@description('Private DNS Zone ID for ML API')
param privateDnsZoneAmlApiId string

@description('Private DNS Zone ID for Notebooks')
param privateDnsZoneAmlNotebooksId string

@description('Principal IDs to grant RBAC roles')
param aadObjectIdForOwners array = []

// ============================================================================
// AI Foundry Hub (kind: Hub)
// ============================================================================

resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: aiHubName
  location: location
  tags: tags
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    friendlyName: aiHubDisplayName
    description: aiHubDescription
    storageAccount: storageAccountId
    keyVault: keyVaultId
    containerRegistry: containerRegistryId
    applicationInsights: applicationInsightsId
    publicNetworkAccess: 'Disabled' // CRITICAL: No public access
    managedNetwork: {
      isolationMode: 'AllowInternetOutbound'
      outboundRules: !empty(cognitiveServicesId) ? {
        'aiservices-pe': {
          type: 'PrivateEndpoint'
          destination: {
            serviceResourceId: cognitiveServicesId
            subresourceTarget: 'account'
            sparkEnabled: false
          }
        }
      } : {}
    }
    // Disable v1 legacy API
    v1LegacyMode: false
  }
}

// ============================================================================
// AI Foundry Project (kind: Project, linked to Hub)
// ============================================================================

resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: aiProjectName
  location: location
  tags: tags
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    friendlyName: aiProjectDisplayName
    description: aiProjectDescription
    hubResourceId: aiHub.id
    publicNetworkAccess: 'Disabled' // CRITICAL: No public access
  }
}

// ============================================================================
// Private Endpoint for Hub
// ============================================================================

resource hubPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: '${aiHubName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${aiHubName}-amlworkspace'
        properties: {
          privateLinkServiceId: aiHub.id
          groupIds: [
            'amlworkspace'
          ]
        }
      }
    ]
  }
}

resource hubPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: hubPrivateEndpoint
  name: 'hub-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'amlapi-config'
        properties: {
          privateDnsZoneId: privateDnsZoneAmlApiId
        }
      }
      {
        name: 'notebooks-config'
        properties: {
          privateDnsZoneId: privateDnsZoneAmlNotebooksId
        }
      }
    ]
  }
}

// ============================================================================
// AI Services Connection (if Cognitive Services is provided)
// ============================================================================

resource aiServicesConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-04-01' = if (!empty(cognitiveServicesId)) {
  parent: aiHub
  name: 'Default_AzureAIServices'
  properties: {
    category: 'AIServices'
    target: cognitiveServicesEndpoint
    authType: 'AAD'
    isSharedToAll: true
    metadata: {
      ApiType: 'Azure'
      ResourceId: cognitiveServicesId
    }
  }
}

// ============================================================================
// RBAC Role Assignments
// ============================================================================

// Azure Machine Learning Data Scientist role
var amlDataScientistRole = resourceId('Microsoft.Authorization/roleDefinitions', 'f6c7c914-8db3-469d-8ca1-694a8f32e121')

// Azure AI Developer role (for AI Foundry)
var aiDeveloperRole = resourceId('Microsoft.Authorization/roleDefinitions', '64702f94-c441-49e6-a78b-ef80e0188fee')

resource hubDataScientistRoles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in aadObjectIdForOwners: {
  name: guid(aiHub.id, principalId, amlDataScientistRole)
  scope: aiHub
  properties: {
    principalId: principalId
    roleDefinitionId: amlDataScientistRole
    principalType: 'User'
  }
}]

resource projectDataScientistRoles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in aadObjectIdForOwners: {
  name: guid(aiProject.id, principalId, amlDataScientistRole)
  scope: aiProject
  properties: {
    principalId: principalId
    roleDefinitionId: amlDataScientistRole
    principalType: 'User'
  }
}]

resource hubAiDeveloperRoles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in aadObjectIdForOwners: {
  name: guid(aiHub.id, principalId, aiDeveloperRole)
  scope: aiHub
  properties: {
    principalId: principalId
    roleDefinitionId: aiDeveloperRole
    principalType: 'User'
  }
}]

resource projectAiDeveloperRoles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in aadObjectIdForOwners: {
  name: guid(aiProject.id, principalId, aiDeveloperRole)
  scope: aiProject
  properties: {
    principalId: principalId
    roleDefinitionId: aiDeveloperRole
    principalType: 'User'
  }
}]

// ============================================================================
// Grant Hub and Project managed identities access to dependent resources
// ============================================================================

// Key Vault Secrets User role for Hub
var keyVaultSecretsUserRole = resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

resource hubKeyVaultRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultId, aiHub.id, keyVaultSecretsUserRole)
  scope: resourceGroup()
  properties: {
    principalId: aiHub.identity.principalId
    roleDefinitionId: keyVaultSecretsUserRole
    principalType: 'ServicePrincipal'
  }
}

// Storage Blob Data Contributor for Hub
var storageBlobDataContributorRole = resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

resource hubStorageRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccountId, aiHub.id, storageBlobDataContributorRole)
  scope: resourceGroup()
  properties: {
    principalId: aiHub.identity.principalId
    roleDefinitionId: storageBlobDataContributorRole
    principalType: 'ServicePrincipal'
  }
}

// ACR Pull for Hub
var acrPullRole = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource hubAcrRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistryId, aiHub.id, acrPullRole)
  scope: resourceGroup()
  properties: {
    principalId: aiHub.identity.principalId
    roleDefinitionId: acrPullRole
    principalType: 'ServicePrincipal'
  }
}

// Cognitive Services User for Hub (required for Content Understanding, etc.)
var cognitiveServicesUserRole = resourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')

resource hubCognitiveServicesRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(cognitiveServicesId)) {
  name: guid(cognitiveServicesId, aiHub.id, cognitiveServicesUserRole)
  scope: resourceGroup()
  properties: {
    principalId: aiHub.identity.principalId
    roleDefinitionId: cognitiveServicesUserRole
    principalType: 'ServicePrincipal'
  }
}

// ============================================================================
// Outputs
// ============================================================================

output aiHubId string = aiHub.id
output aiHubName string = aiHub.name
output aiHubPrincipalId string = aiHub.identity.principalId
output aiHubDiscoveryUrl string = aiHub.properties.discoveryUrl
output aiProjectId string = aiProject.id
output aiProjectName string = aiProject.name
output aiProjectPrincipalId string = aiProject.identity.principalId
