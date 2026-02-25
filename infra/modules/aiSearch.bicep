// ============================================================================
// Azure AI Search Module - Private Endpoint & Managed Identity
// ============================================================================

@description('Azure region for the resources')
param location string

@description('Tags to apply to all resources')
param tags object = {}

@description('Name of the Azure AI Search service')
param aiSearchName string

@description('Subnet ID for private endpoint')
param subnetId string

@description('Private DNS Zone ID for Azure AI Search')
param privateDnsZoneId string

@description('SKU name for Azure AI Search')
@allowed([
  'basic'
  'standard'
  'standard2'
  'standard3'
  'storage_optimized_l1'
  'storage_optimized_l2'
])
param skuName string = 'basic'

// ============================================================================
// Azure AI Search Service - Secure Configuration
// ============================================================================

resource aiSearch 'Microsoft.Search/searchServices@2025-05-01' = {
  name: aiSearchName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: skuName
  }
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

// ============================================================================
// Private Endpoint for Azure AI Search
// ============================================================================

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: '${aiSearchName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${aiSearchName}-searchservice'
        properties: {
          privateLinkServiceId: aiSearch.id
          groupIds: [
            'searchService'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: privateEndpoint
  name: 'aisearch-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'aisearch-config'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

output aiSearchName string = aiSearch.name
output aiSearchId string = aiSearch.id
output aiSearchEndpoint string = aiSearch.properties.endpoint
output aiSearchPrincipalId string = aiSearch.identity.principalId
