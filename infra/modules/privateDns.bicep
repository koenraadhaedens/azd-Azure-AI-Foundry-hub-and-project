// ============================================================================
// Private DNS Zones Module - All required zones for private endpoints
// ============================================================================

@description('Azure region for the resources')
param location string = 'global'

@description('Tags to apply to all resources')
param tags object = {}

@description('VNet ID to link DNS zones to')
param vnetId string

@description('Name of the VNet for link naming')
param vnetName string

// ============================================================================
// Private DNS Zone Names (Azure standard names)
// ============================================================================

var privateDnsZones = [
  // Storage Account
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.queue.${environment().suffixes.storage}'
  'privatelink.table.${environment().suffixes.storage}'
  'privatelink.file.${environment().suffixes.storage}'
  // Key Vault
  'privatelink.vaultcore.azure.net'
  // Container Registry
  'privatelink.azurecr.io'
  // Cognitive Services / Azure OpenAI / Azure AI Services
  'privatelink.cognitiveservices.azure.com'
  'privatelink.openai.azure.com'
  'privatelink.services.ai.azure.com'  // Required for AI Foundry services
  // Azure Machine Learning / AI Foundry
  'privatelink.api.azureml.ms'
  'privatelink.notebooks.azure.net'
]

// ============================================================================
// Private DNS Zones
// ============================================================================

resource dnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for zone in privateDnsZones: {
  name: zone
  location: location
  tags: tags
  properties: {}
}]

// ============================================================================
// VNet Links for each DNS Zone
// ============================================================================

resource vnetLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (zone, i) in privateDnsZones: {
  parent: dnsZones[i]
  name: '${vnetName}-link'
  location: location
  tags: tags
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}]

// ============================================================================
// Outputs - DNS Zone IDs by purpose
// ============================================================================

output privateDnsZoneBlobId string = dnsZones[0].id
output privateDnsZoneQueueId string = dnsZones[1].id
output privateDnsZoneTableId string = dnsZones[2].id
output privateDnsZoneFileId string = dnsZones[3].id
output privateDnsZoneAcrId string = dnsZones[4].id
output privateDnsZoneCognitiveServicesId string = dnsZones[6].id
output privateDnsZoneOpenAiId string = dnsZones[7].id
output privateDnsZoneAiServicesId string = dnsZones[8].id
output privateDnsZoneAmlApiId string = dnsZones[9].id
output privateDnsZoneAmlNotebooksId string = dnsZones[10].id
