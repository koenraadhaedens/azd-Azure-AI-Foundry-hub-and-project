// ============================================================================
// Azure AI Document Intelligence Module - Private Endpoint & Managed Identity
// ============================================================================

@description('Azure region for the resources')
param location string

@description('Tags to apply to all resources')
param tags object = {}

@description('Name of the Document Intelligence account')
param documentIntelligenceName string

@description('Subnet ID for private endpoint')
param subnetId string

@description('Private DNS Zone ID for Cognitive Services')
param privateDnsZoneId string

@description('SKU name for Document Intelligence')
@allowed([
  'F0'  // Free tier
  'S0'  // Standard tier
])
param skuName string = 'S0'

@description('Principal IDs to grant RBAC roles')
param aadObjectIdForOwners array = []

// ============================================================================
// Document Intelligence Account - Secure Configuration
// ============================================================================

resource documentIntelligence 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: documentIntelligenceName
  location: location
  tags: tags
  kind: 'FormRecognizer'  // Document Intelligence service kind
  sku: {
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: documentIntelligenceName
    publicNetworkAccess: 'Disabled'  // CRITICAL: No public access
    disableLocalAuth: true           // CRITICAL: Disable key-based auth, AAD only
    networkAcls: {
      defaultAction: 'Deny'
    }
    apiProperties: {}
  }
}

// ============================================================================
// Private Endpoint for Document Intelligence
// ============================================================================

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: '${documentIntelligenceName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${documentIntelligenceName}-account'
        properties: {
          privateLinkServiceId: documentIntelligence.id
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
  name: 'docint-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'docint-config'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

// ============================================================================
// RBAC Role Assignments - Cognitive Services User
// ============================================================================

// Cognitive Services User role - allows calling Document Intelligence APIs
var cognitiveServicesUserRoleId = 'a97b65f3-24c7-4388-baec-2e87135dc908'

resource cognitiveServicesUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in aadObjectIdForOwners: {
  name: guid(documentIntelligence.id, principalId, cognitiveServicesUserRoleId)
  scope: documentIntelligence
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesUserRoleId)
    principalId: principalId
    principalType: 'User'
  }
}]

// Cognitive Services Contributor role - allows managing the resource
var cognitiveServicesContributorRoleId = '25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68'

resource cognitiveServicesContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in aadObjectIdForOwners: {
  name: guid(documentIntelligence.id, principalId, cognitiveServicesContributorRoleId)
  scope: documentIntelligence
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesContributorRoleId)
    principalId: principalId
    principalType: 'User'
  }
}]

// ============================================================================
// Outputs
// ============================================================================

output documentIntelligenceId string = documentIntelligence.id
output documentIntelligenceName string = documentIntelligence.name
output documentIntelligenceEndpoint string = documentIntelligence.properties.endpoint
output documentIntelligencePrincipalId string = documentIntelligence.identity.principalId
