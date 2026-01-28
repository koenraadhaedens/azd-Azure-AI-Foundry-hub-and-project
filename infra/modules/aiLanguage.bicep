// ============================================================================
// Azure AI Language Module - Private Endpoint & Managed Identity (Entra ID only)
// ============================================================================

@description('Azure region for the resources')
param location string

@description('Tags to apply to all resources')
param tags object = {}

@description('Name of the AI Language account')
param aiLanguageName string

@description('Subnet ID for private endpoint')
param subnetId string

@description('Private DNS Zone ID for Cognitive Services')
param privateDnsZoneId string

@description('SKU name for AI Language')
@allowed([
  'F0'  // Free tier
  'S'   // Standard tier
])
param skuName string = 'S'

@description('Principal IDs to grant RBAC roles')
param aadObjectIdForOwners array = []

// ============================================================================
// AI Language Account - Secure Configuration
// ============================================================================

resource aiLanguage 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: aiLanguageName
  location: location
  tags: tags
  kind: 'TextAnalytics'  // AI Language service kind
  sku: {
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: aiLanguageName
    publicNetworkAccess: 'Disabled'  // CRITICAL: No public access
    disableLocalAuth: true           // CRITICAL: Disable key-based auth, Entra ID only
    networkAcls: {
      defaultAction: 'Deny'
    }
    apiProperties: {}
  }
}

// ============================================================================
// Private Endpoint for AI Language
// ============================================================================

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: '${aiLanguageName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${aiLanguageName}-account'
        properties: {
          privateLinkServiceId: aiLanguage.id
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
  name: 'ailanguage-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'ailanguage-config'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

// ============================================================================
// RBAC Role Assignments - Cognitive Services User & Contributor
// ============================================================================

var cognitiveServicesUserRole = resourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')
var cognitiveServicesContributorRole = resourceId('Microsoft.Authorization/roleDefinitions', '25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68')

resource userRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in aadObjectIdForOwners: {
  name: guid(aiLanguage.id, principalId, cognitiveServicesUserRole)
  scope: aiLanguage
  properties: {
    principalId: principalId
    roleDefinitionId: cognitiveServicesUserRole
    principalType: 'User'
  }
}]

resource contributorRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in aadObjectIdForOwners: {
  name: guid(aiLanguage.id, principalId, cognitiveServicesContributorRole)
  scope: aiLanguage
  properties: {
    principalId: principalId
    roleDefinitionId: cognitiveServicesContributorRole
    principalType: 'User'
  }
}]

// ============================================================================
// Outputs
// ============================================================================

output aiLanguageName string = aiLanguage.name
output aiLanguageId string = aiLanguage.id
output aiLanguageEndpoint string = aiLanguage.properties.endpoint
output aiLanguagePrincipalId string = aiLanguage.identity.principalId
