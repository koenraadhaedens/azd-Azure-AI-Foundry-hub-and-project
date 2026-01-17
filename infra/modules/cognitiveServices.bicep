// ============================================================================
// Cognitive Services Module - Azure AI Services / OpenAI with Private Endpoint
// ============================================================================

@description('Azure region for the resources')
param location string

@description('Tags to apply to all resources')
param tags object = {}

@description('Name of the Cognitive Services account')
param cognitiveServicesName string

@description('Subnet ID for private endpoint')
param subnetId string

@description('Private DNS Zone ID for Cognitive Services')
param privateDnsZoneId string

@description('Kind of Cognitive Services account')
@allowed([
  'AIServices' // Azure AI Services (multi-service, required for AI Foundry)
  'OpenAI' // Azure OpenAI only
])
param kind string = 'AIServices'

@description('SKU name for Cognitive Services')
param skuName string = 'S0'

@description('Principal IDs to grant RBAC roles')
param aadObjectIdForOwners array = []

// ============================================================================
// Cognitive Services Account - Secure Configuration
// ============================================================================

resource cognitiveServices 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: cognitiveServicesName
  location: location
  tags: tags
  kind: kind
  sku: {
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: cognitiveServicesName
    publicNetworkAccess: 'Disabled' // CRITICAL: No public access
    disableLocalAuth: true // CRITICAL: Disable key-based auth, AAD only
    networkAcls: {
      defaultAction: 'Deny'
    }
    apiProperties: {}
  }
}

// ============================================================================
// Private Endpoint for Cognitive Services
// ============================================================================

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: '${cognitiveServicesName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${cognitiveServicesName}-account'
        properties: {
          privateLinkServiceId: cognitiveServices.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: privateEndpoint
  name: 'cognitive-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'cognitive-config'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

// ============================================================================
// RBAC Role Assignments
// ============================================================================

var cognitiveServicesUserRole = resourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')
var cognitiveServicesContributorRole = resourceId('Microsoft.Authorization/roleDefinitions', '25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68')

resource userRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in aadObjectIdForOwners: {
  name: guid(cognitiveServices.id, principalId, cognitiveServicesUserRole)
  scope: cognitiveServices
  properties: {
    principalId: principalId
    roleDefinitionId: cognitiveServicesUserRole
    principalType: 'User'
  }
}]

resource contributorRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in aadObjectIdForOwners: {
  name: guid(cognitiveServices.id, principalId, cognitiveServicesContributorRole)
  scope: cognitiveServices
  properties: {
    principalId: principalId
    roleDefinitionId: cognitiveServicesContributorRole
    principalType: 'User'
  }
}]

// ============================================================================
// Outputs
// ============================================================================

output cognitiveServicesId string = cognitiveServices.id
output cognitiveServicesName string = cognitiveServices.name
output cognitiveServicesEndpoint string = cognitiveServices.properties.endpoint
output cognitiveServicesPrincipalId string = cognitiveServices.identity.principalId
