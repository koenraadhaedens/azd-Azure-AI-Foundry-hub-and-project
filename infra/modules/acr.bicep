// ============================================================================
// Azure Container Registry Module - Private Endpoint Only
// ============================================================================

@description('Azure region for the resources')
param location string

@description('Tags to apply to all resources')
param tags object = {}

@description('Name of the Container Registry')
param acrName string

@description('Subnet ID for private endpoint')
param subnetId string

@description('Private DNS Zone ID for ACR')
param privateDnsZoneId string

@description('SKU for Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Premium' // Premium required for private endpoints

@description('Principal IDs to grant RBAC roles')
param aadObjectIdForOwners array = []

// ============================================================================
// Container Registry - Secure Configuration
// ============================================================================

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false // CRITICAL: Disable admin user, use AAD
    publicNetworkAccess: 'Disabled' // CRITICAL: No public access
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
    encryption: {
      status: 'disabled' // Use platform-managed keys
    }
    dataEndpointEnabled: false
    policies: {
      retentionPolicy: {
        status: 'enabled'
        days: 30
      }
      trustPolicy: {
        status: 'enabled'
        type: 'Notary'
      }
    }
  }
}

// ============================================================================
// Private Endpoint
// ============================================================================

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: '${acrName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${acrName}-registry'
        properties: {
          privateLinkServiceId: acr.id
          groupIds: [
            'registry'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: privateEndpoint
  name: 'acr-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'acr-config'
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

var acrPullRole = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var acrPushRole = resourceId('Microsoft.Authorization/roleDefinitions', '8311e382-0749-4cb8-b61a-304f252e45ec')

resource pullRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in aadObjectIdForOwners: {
  name: guid(acr.id, principalId, acrPullRole)
  scope: acr
  properties: {
    principalId: principalId
    roleDefinitionId: acrPullRole
    principalType: 'User'
  }
}]

resource pushRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in aadObjectIdForOwners: {
  name: guid(acr.id, principalId, acrPushRole)
  scope: acr
  properties: {
    principalId: principalId
    roleDefinitionId: acrPushRole
    principalType: 'User'
  }
}]

// ============================================================================
// Outputs
// ============================================================================

output acrId string = acr.id
output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
