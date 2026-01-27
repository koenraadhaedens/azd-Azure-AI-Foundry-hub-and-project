// ============================================================================
// VM RBAC Module - Role assignments for jumpbox VM managed identity
// and deploying user
// ============================================================================

@description('Principal ID of the VM managed identity')
param vmPrincipalId string

@description('Principal ID of the user running the deployment (optional)')
param deployingUserPrincipalId string = ''

// ============================================================================
// Role Definitions
// ============================================================================

// Cognitive Services User - read access to Cognitive Services
var cognitiveServicesUserRole = resourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')

// Cognitive Services Contributor - manage Cognitive Services
var cognitiveServicesContributorRole = resourceId('Microsoft.Authorization/roleDefinitions', '25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68')

// Azure Machine Learning Data Scientist - work with ML workspaces
var amlDataScientistRole = resourceId('Microsoft.Authorization/roleDefinitions', 'f6c7c914-8db3-469d-8ca1-694a8f32e121')

// Azure AI Developer - develop AI applications
var aiDeveloperRole = resourceId('Microsoft.Authorization/roleDefinitions', '64702f94-c441-49e6-a78b-ef80e0188fee')

// Storage Blob Data Contributor - read/write blob data
var storageBlobDataContributorRole = resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

// Key Vault Secrets User - read secrets
var keyVaultSecretsUserRole = resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

// Reader role - read all resources
var readerRole = resourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')

// ============================================================================
// Role Assignments at Resource Group Scope
// ============================================================================

resource vmCognitiveServicesUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, vmPrincipalId, cognitiveServicesUserRole)
  properties: {
    principalId: vmPrincipalId
    roleDefinitionId: cognitiveServicesUserRole
    principalType: 'ServicePrincipal'
  }
}

resource vmCognitiveServicesContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, vmPrincipalId, cognitiveServicesContributorRole)
  properties: {
    principalId: vmPrincipalId
    roleDefinitionId: cognitiveServicesContributorRole
    principalType: 'ServicePrincipal'
  }
}

resource vmAmlDataScientistRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, vmPrincipalId, amlDataScientistRole)
  properties: {
    principalId: vmPrincipalId
    roleDefinitionId: amlDataScientistRole
    principalType: 'ServicePrincipal'
  }
}

resource vmAiDeveloperRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, vmPrincipalId, aiDeveloperRole)
  properties: {
    principalId: vmPrincipalId
    roleDefinitionId: aiDeveloperRole
    principalType: 'ServicePrincipal'
  }
}

resource vmStorageBlobDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, vmPrincipalId, storageBlobDataContributorRole)
  properties: {
    principalId: vmPrincipalId
    roleDefinitionId: storageBlobDataContributorRole
    principalType: 'ServicePrincipal'
  }
}

resource vmKeyVaultSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, vmPrincipalId, keyVaultSecretsUserRole)
  properties: {
    principalId: vmPrincipalId
    roleDefinitionId: keyVaultSecretsUserRole
    principalType: 'ServicePrincipal'
  }
}

resource vmReaderRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, vmPrincipalId, readerRole)
  properties: {
    principalId: vmPrincipalId
    roleDefinitionId: readerRole
    principalType: 'ServicePrincipal'
  }
}

// ============================================================================
// Role Assignments for Deploying User at Resource Group Scope
// ============================================================================

resource userCognitiveServicesUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(deployingUserPrincipalId)) {
  name: guid(resourceGroup().id, deployingUserPrincipalId, cognitiveServicesUserRole)
  properties: {
    principalId: deployingUserPrincipalId
    roleDefinitionId: cognitiveServicesUserRole
    principalType: 'User'
  }
}

resource userCognitiveServicesContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(deployingUserPrincipalId)) {
  name: guid(resourceGroup().id, deployingUserPrincipalId, cognitiveServicesContributorRole)
  properties: {
    principalId: deployingUserPrincipalId
    roleDefinitionId: cognitiveServicesContributorRole
    principalType: 'User'
  }
}

resource userAmlDataScientistRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(deployingUserPrincipalId)) {
  name: guid(resourceGroup().id, deployingUserPrincipalId, amlDataScientistRole)
  properties: {
    principalId: deployingUserPrincipalId
    roleDefinitionId: amlDataScientistRole
    principalType: 'User'
  }
}

resource userAiDeveloperRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(deployingUserPrincipalId)) {
  name: guid(resourceGroup().id, deployingUserPrincipalId, aiDeveloperRole)
  properties: {
    principalId: deployingUserPrincipalId
    roleDefinitionId: aiDeveloperRole
    principalType: 'User'
  }
}

resource userStorageBlobDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(deployingUserPrincipalId)) {
  name: guid(resourceGroup().id, deployingUserPrincipalId, storageBlobDataContributorRole)
  properties: {
    principalId: deployingUserPrincipalId
    roleDefinitionId: storageBlobDataContributorRole
    principalType: 'User'
  }
}

resource userKeyVaultSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(deployingUserPrincipalId)) {
  name: guid(resourceGroup().id, deployingUserPrincipalId, keyVaultSecretsUserRole)
  properties: {
    principalId: deployingUserPrincipalId
    roleDefinitionId: keyVaultSecretsUserRole
    principalType: 'User'
  }
}

resource userReaderRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(deployingUserPrincipalId)) {
  name: guid(resourceGroup().id, deployingUserPrincipalId, readerRole)
  properties: {
    principalId: deployingUserPrincipalId
    roleDefinitionId: readerRole
    principalType: 'User'
  }
}
