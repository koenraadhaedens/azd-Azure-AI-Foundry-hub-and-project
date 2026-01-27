targetScope = 'subscription'

// =====================================================
// PARAMETERS
// =====================================================

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Name prefix for all resources (keep short to avoid name length limits)')
@minLength(2)
@maxLength(10)
param namePrefix string = 'aif'

@description('Address space for the virtual network')
param vnetAddressPrefix string = '10.10.0.0/16'

@description('CIDR for the workload subnet (for VMs, private endpoints, etc.)')
param workloadSubnetCidr string = '10.10.1.0/24'

@description('CIDR for the Azure Bastion subnet (must be /26 or larger)')
param bastionSubnetCidr string = '10.10.2.0/26'

@description('Enable Azure Bastion for secure RDP access')
param enableBastion bool = true

@description('Enable NAT Gateway for stable egress')
param enableNatGateway bool = false

@description('Deploy Azure AI Services (required for Content Understanding, Document Intelligence, etc.)')
param enableAIServices bool = true

@description('Admin username for the Windows VM')
param vmAdminUsername string = 'azureadmin'

@secure()
@minLength(12)
@maxLength(123)
@description('Admin password for the Windows VM')
param vmAdminPassword string

@description('Array of Microsoft Entra ID Object IDs to grant RBAC roles (Key Vault, Storage, ACR, AI Hub)')
param aadObjectIdForOwners array = []

@description('VM Size for the Windows jumpbox')
param vmSize string = 'Standard_D2s_v6'

// =====================================================
// VARIABLES
// =====================================================

var abbrs = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = {
  'azd-env-name': environmentName
  Environment: 'Dev'
  Project: 'Azure-AI-Foundry-Private'
}

// Resource names
var rgName = '${abbrs.resourcesResourceGroups}${namePrefix}-${environmentName}'
var vnetName = '${abbrs.networkVirtualNetworks}${namePrefix}-${resourceToken}'
var workloadSubnetName = 'snet-workload'
var bastionSubnetName = 'AzureBastionSubnet'
var nsgName = '${abbrs.networkNetworkSecurityGroups}${namePrefix}-workload-${resourceToken}'
var bastionNsgName = '${abbrs.networkNetworkSecurityGroups}${namePrefix}-bastion-${resourceToken}'
var bastionName = '${abbrs.networkBastionHosts}${namePrefix}-${resourceToken}'
var bastionPipName = '${abbrs.networkPublicIPAddresses}${namePrefix}-bastion-${resourceToken}'
var natGatewayName = '${abbrs.networkNatGateways}${namePrefix}-${resourceToken}'
var natGatewayPipName = '${abbrs.networkPublicIPAddresses}${namePrefix}-natgw-${resourceToken}'
var storageAccountName = '${abbrs.storageStorageAccounts}${namePrefix}${resourceToken}'
var keyVaultName = '${abbrs.keyVaultVaults}${namePrefix}-${resourceToken}'
var acrName = '${abbrs.containerRegistryRegistries}${namePrefix}${resourceToken}'
var logAnalyticsName = '${abbrs.operationalInsightsWorkspaces}${namePrefix}-${resourceToken}'
var appInsightsName = '${abbrs.insightsComponents}${namePrefix}-${resourceToken}'
var aiHubName = '${abbrs.machineLearningServicesWorkspaces}hub-${namePrefix}-${resourceToken}'
var aiProjectName = '${abbrs.machineLearningServicesWorkspaces}proj-${namePrefix}-${resourceToken}'
var cognitiveServicesName = '${abbrs.cognitiveServicesAccounts}${namePrefix}-${resourceToken}'
var vmName = '${abbrs.computeVirtualMachines}${namePrefix}-jump'

// =====================================================
// RESOURCE GROUP
// =====================================================

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: tags
}

// =====================================================
// NETWORKING MODULE
// =====================================================

module network 'modules/network.bicep' = {
  name: 'network-deployment'
  scope: rg
  params: {
    location: location
    tags: tags
    vnetName: vnetName
    vnetAddressPrefix: vnetAddressPrefix
    workloadSubnetName: workloadSubnetName
    workloadSubnetCidr: workloadSubnetCidr
    bastionSubnetName: bastionSubnetName
    bastionSubnetCidr: bastionSubnetCidr
    nsgName: nsgName
    bastionNsgName: bastionNsgName
    enableBastion: enableBastion
    enableNatGateway: enableNatGateway
    natGatewayName: natGatewayName
    natGatewayPipName: natGatewayPipName
    bastionName: bastionName
    bastionPipName: bastionPipName
  }
}

// =====================================================
// PRIVATE DNS ZONES MODULE
// =====================================================

module privateDns 'modules/privateDns.bicep' = {
  name: 'private-dns-deployment'
  scope: rg
  params: {
    tags: tags
    vnetId: network.outputs.vnetId
    vnetName: network.outputs.vnetName
  }
}

// =====================================================
// MONITORING MODULE
// =====================================================

module monitor 'modules/monitor.bicep' = {
  name: 'monitor-deployment'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: logAnalyticsName
    appInsightsName: appInsightsName
  }
}

// =====================================================
// STORAGE MODULE
// =====================================================

module storage 'modules/storage.bicep' = {
  name: 'storage-deployment'
  scope: rg
  params: {
    location: location
    tags: tags
    storageAccountName: storageAccountName
    subnetId: network.outputs.workloadSubnetId
    privateDnsZoneBlobId: privateDns.outputs.privateDnsZoneBlobId
    privateDnsZoneFileId: privateDns.outputs.privateDnsZoneFileId
    privateDnsZoneQueueId: privateDns.outputs.privateDnsZoneQueueId
    privateDnsZoneTableId: privateDns.outputs.privateDnsZoneTableId
    aadObjectIdForOwners: aadObjectIdForOwners
  }
}

// =====================================================
// KEY VAULT MODULE
// =====================================================

module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault-deployment'
  scope: rg
  params: {
    location: location
    tags: tags
    keyVaultName: keyVaultName
    subnetId: network.outputs.workloadSubnetId
    privateDnsZoneId: privateDns.outputs.privateDnsZoneKeyVaultId
    aadObjectIdForOwners: aadObjectIdForOwners
  }
}

// =====================================================
// CONTAINER REGISTRY MODULE
// =====================================================

module acr 'modules/acr.bicep' = {
  name: 'acr-deployment'
  scope: rg
  params: {
    location: location
    tags: tags
    acrName: acrName
    subnetId: network.outputs.workloadSubnetId
    privateDnsZoneId: privateDns.outputs.privateDnsZoneAcrId
    aadObjectIdForOwners: aadObjectIdForOwners
  }
}

// =====================================================
// AZURE AI SERVICES MODULE (For Content Understanding, etc.)
// =====================================================

module cognitiveServices 'modules/cognitiveServices.bicep' = if (enableAIServices) {
  name: 'cognitive-services-deployment'
  scope: rg
  params: {
    location: location
    tags: tags
    cognitiveServicesName: cognitiveServicesName
    subnetId: network.outputs.workloadSubnetId
    privateDnsZoneId: privateDns.outputs.privateDnsZoneCognitiveServicesId
    privateDnsZoneOpenAiId: privateDns.outputs.privateDnsZoneOpenAiId
    privateDnsZoneAiServicesId: privateDns.outputs.privateDnsZoneAiServicesId
    aadObjectIdForOwners: aadObjectIdForOwners
  }
}

// =====================================================
// AI FOUNDRY (HUB + PROJECT) MODULE
// =====================================================

module aiFoundry 'modules/aiFoundry.bicep' = {
  name: 'ai-foundry-deployment'
  scope: rg
  params: {
    location: location
    tags: tags
    aiHubName: aiHubName
    aiProjectName: aiProjectName
    storageAccountId: storage.outputs.storageAccountId
    keyVaultId: keyVault.outputs.keyVaultId
    containerRegistryId: acr.outputs.acrId
    applicationInsightsId: monitor.outputs.appInsightsId
    subnetId: network.outputs.workloadSubnetId
    privateDnsZoneAmlApiId: privateDns.outputs.privateDnsZoneAmlApiId
    privateDnsZoneAmlNotebooksId: privateDns.outputs.privateDnsZoneAmlNotebooksId
    aadObjectIdForOwners: aadObjectIdForOwners
    cognitiveServicesId: enableAIServices ? cognitiveServices.outputs.cognitiveServicesId : ''
    cognitiveServicesEndpoint: enableAIServices ? cognitiveServices.outputs.cognitiveServicesEndpoint : ''
  }
}

// =====================================================
// WINDOWS VM (JUMPBOX) MODULE
// =====================================================

module windowsVm 'modules/windowsVm.bicep' = {
  name: 'windows-vm-deployment'
  scope: rg
  params: {
    location: location
    tags: tags
    vmName: vmName
    vmSize: vmSize
    adminUsername: vmAdminUsername
    adminPassword: vmAdminPassword
    subnetId: network.outputs.workloadSubnetId
  }
}

// =====================================================
// OUTPUTS
// =====================================================

// Resource Group
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_LOCATION string = location

// Networking
output VNET_NAME string = network.outputs.vnetName
output VNET_ID string = network.outputs.vnetId
output WORKLOAD_SUBNET_ID string = network.outputs.workloadSubnetId

// Bastion
output BASTION_ENABLED string = string(enableBastion)
output BASTION_NAME string = enableBastion ? network.outputs.bastionName : ''

// VM
output VM_NAME string = windowsVm.outputs.vmName
output VM_PRIVATE_IP string = windowsVm.outputs.vmPrivateIp

// Storage
output STORAGE_ACCOUNT_NAME string = storage.outputs.storageAccountName
output STORAGE_ACCOUNT_ID string = storage.outputs.storageAccountId

// Key Vault
output KEYVAULT_NAME string = keyVault.outputs.keyVaultName
output KEYVAULT_URI string = keyVault.outputs.keyVaultUri

// ACR
output ACR_NAME string = acr.outputs.acrName
output ACR_LOGIN_SERVER string = acr.outputs.acrLoginServer

// Monitoring
output LOG_ANALYTICS_WORKSPACE_NAME string = monitor.outputs.logAnalyticsWorkspaceName
output APP_INSIGHTS_NAME string = monitor.outputs.appInsightsName

// AI Foundry
output AI_HUB_NAME string = aiFoundry.outputs.aiHubName
output AI_HUB_ID string = aiFoundry.outputs.aiHubId
output AI_PROJECT_NAME string = aiFoundry.outputs.aiProjectName
output AI_PROJECT_ID string = aiFoundry.outputs.aiProjectId

// Azure AI Services (if enabled)
output COGNITIVE_SERVICES_NAME string = enableAIServices ? cognitiveServices.outputs.cognitiveServicesName : ''
output COGNITIVE_SERVICES_ENDPOINT string = enableAIServices ? cognitiveServices.outputs.cognitiveServicesEndpoint : ''
