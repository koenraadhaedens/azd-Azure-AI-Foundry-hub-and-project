// ============================================================================
// Windows VM Module - Jumpbox for Private Network Access (NO public IP)
// ============================================================================

@description('Azure region for the resources')
param location string

@description('Tags to apply to all resources')
param tags object = {}

@description('Name of the virtual machine')
param vmName string

@description('Subnet ID to deploy the VM into')
param subnetId string

@description('Admin username for the VM')
param adminUsername string

@description('Admin password for the VM')
@secure()
param adminPassword string

@description('Size of the VM')
param vmSize string = 'Standard_D2s_v6'

@description('Windows Server image SKU')
@allowed([
  '2022-datacenter-g2'
  '2022-datacenter-azure-edition'
  '2025-datacenter-g2'
  '2025-datacenter-azure-edition'
])
param windowsOSVersion string = '2025-datacenter-azure-edition'

@description('OS disk type')
@allowed([
  'Premium_LRS'
  'StandardSSD_LRS'
  'Standard_LRS'
])
param osDiskType string = 'Premium_LRS'

@description('Size of OS disk in GB')
param osDiskSizeGB int = 128

@description('Enable auto-shutdown at specified time (UTC)')
param enableAutoShutdown bool = true

@description('URL to the PowerShell script for installing dev tools')
param devToolsScriptUrl string = 'https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/infra/scripts/Install-DevTools.ps1'

@description('Auto-shutdown time in HHmm format (UTC)')
param autoShutdownTime string = '1900'

// ============================================================================
// Network Interface (No public IP - access via Bastion only)
// ============================================================================

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: '${vmName}-nic'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          // NO public IP - access only via Bastion
        }
      }
    ]
    enableAcceleratedNetworking: true
  }
}

// ============================================================================
// Windows Virtual Machine
// ============================================================================

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: take(vmName, 15) // Windows computer name max 15 chars
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
          automaticByPlatformSettings: {
            rebootSetting: 'IfRequired'
          }
        }
        enableVMAgentPlatformUpdates: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        diskSizeGB: osDiskSizeGB
        deleteOption: 'Delete'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
  }
}

// ============================================================================
// Custom Script Extension - Install Dev Tools from external script
// ============================================================================

resource customScript 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  parent: vm
  name: 'InstallDevTools'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        devToolsScriptUrl
      ]
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Bypass -File Install-DevTools.ps1'
    }
  }
}

// ============================================================================
// Auto-Shutdown Schedule (Optional)
// ============================================================================

resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = if (enableAutoShutdown) {
  name: 'shutdown-computevm-${vmName}'
  location: location
  tags: tags
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: autoShutdownTime
    }
    timeZoneId: 'UTC'
    targetResourceId: vm.id
    notificationSettings: {
      status: 'Disabled'
    }
  }
}

// ============================================================================
// Outputs
// ============================================================================

output vmId string = vm.id
output vmName string = vm.name
output vmPrincipalId string = vm.identity.principalId
output vmPrivateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output nicId string = nic.id
