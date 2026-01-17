// ============================================================================
// Storage Module - Storage Account with Private Endpoints (NO shared key access)
// ============================================================================

@description('Azure region for the resources')
param location string

@description('Tags to apply to all resources')
param tags object = {}

@description('Name of the storage account (3-24 chars, lowercase alphanumeric)')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Subnet ID for private endpoints')
param subnetId string

@description('Private DNS Zone ID for blob')
param privateDnsZoneBlobId string

@description('Private DNS Zone ID for file')
param privateDnsZoneFileId string

@description('Private DNS Zone ID for queue')
param privateDnsZoneQueueId string

@description('Private DNS Zone ID for table')
param privateDnsZoneTableId string

@description('Storage account SKU')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param sku string = 'Standard_LRS'

@description('Principal IDs to grant Storage Blob Data Contributor role')
param aadObjectIdForOwners array = []

// ============================================================================
// Storage Account - Secure Configuration
// ============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: sku
  }
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false // CRITICAL: Disable shared key access, AAD only
    publicNetworkAccess: 'Disabled' // CRITICAL: No public access
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    encryption: {
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        table: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Account'
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// ============================================================================
// Blob Service
// ============================================================================

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// ============================================================================
// Private Endpoints
// ============================================================================

resource blobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: '${storageAccountName}-pe-blob'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${storageAccountName}-blob'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource blobPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: blobPrivateEndpoint
  name: 'blob-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'blob-config'
        properties: {
          privateDnsZoneId: privateDnsZoneBlobId
        }
      }
    ]
  }
}

resource filePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: '${storageAccountName}-pe-file'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${storageAccountName}-file'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

resource filePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: filePrivateEndpoint
  name: 'file-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'file-config'
        properties: {
          privateDnsZoneId: privateDnsZoneFileId
        }
      }
    ]
  }
}

resource queuePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: '${storageAccountName}-pe-queue'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${storageAccountName}-queue'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'queue'
          ]
        }
      }
    ]
  }
}

resource queuePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: queuePrivateEndpoint
  name: 'queue-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'queue-config'
        properties: {
          privateDnsZoneId: privateDnsZoneQueueId
        }
      }
    ]
  }
}

resource tablePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: '${storageAccountName}-pe-table'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${storageAccountName}-table'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'table'
          ]
        }
      }
    ]
  }
}

resource tablePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: tablePrivateEndpoint
  name: 'table-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'table-config'
        properties: {
          privateDnsZoneId: privateDnsZoneTableId
        }
      }
    ]
  }
}

// ============================================================================
// RBAC Role Assignments - Storage Blob Data Contributor
// ============================================================================

var storageBlobDataContributorRole = resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

resource storageRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in aadObjectIdForOwners: {
  name: guid(storageAccount.id, principalId, storageBlobDataContributorRole)
  scope: storageAccount
  properties: {
    principalId: principalId
    roleDefinitionId: storageBlobDataContributorRole
    principalType: 'User'
  }
}]

// ============================================================================
// Outputs
// ============================================================================

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
output fileEndpoint string = storageAccount.properties.primaryEndpoints.file
output queueEndpoint string = storageAccount.properties.primaryEndpoints.queue
output tableEndpoint string = storageAccount.properties.primaryEndpoints.table
