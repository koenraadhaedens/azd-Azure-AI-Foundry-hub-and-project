// ============================================================================
// Monitor Module - Log Analytics Workspace and Application Insights
// ============================================================================

@description('Azure region for the resources')
param location string

@description('Tags to apply to all resources')
param tags object = {}

@description('Name of the Log Analytics workspace')
param logAnalyticsName string

@description('Name of the Application Insights instance')
param appInsightsName string

@description('Retention period in days for Log Analytics')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('SKU for Log Analytics workspace')
@allowed([
  'Free'
  'PerGB2018'
  'PerNode'
  'Premium'
  'Standalone'
  'Standard'
])
param logAnalyticsSku string = 'PerGB2018'

// ============================================================================
// Log Analytics Workspace
// ============================================================================

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: logAnalyticsSku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1 // No cap
    }
    publicNetworkAccessForIngestion: 'Enabled' // Required for App Insights
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ============================================================================
// Application Insights (workspace-based)
// ============================================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    DisableLocalAuth: false // App Insights requires connection string
  }
}

// ============================================================================
// Outputs
// ============================================================================

output logAnalyticsId string = logAnalytics.id
output logAnalyticsWorkspaceName string = logAnalytics.name
output logAnalyticsWorkspaceId string = logAnalytics.properties.customerId
output appInsightsId string = appInsights.id
output appInsightsName string = appInsights.name
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
