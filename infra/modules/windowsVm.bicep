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
// Custom Script Extension - Install Edge, VS Code, Azure CLI, etc.
// Uses winget (pre-installed on Windows Server 2025)
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
      commandToExecute: '''
        powershell -ExecutionPolicy Bypass -Command "
          Start-Transcript -Path C:\\WindowsAzure\\Logs\\DevToolsInstall.log -Append;
          
          # Wait for winget to be available (Windows Server 2025 has it pre-installed)
          $attempts = 0;
          while (-not (Get-Command winget -ErrorAction SilentlyContinue) -and $attempts -lt 10) {
            Write-Host 'Waiting for winget to be available...';
            Start-Sleep -Seconds 30;
            $attempts++;
          }
          
          if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host 'Installing applications with winget...';
            
            # Accept source agreements
            winget source update;
            
            # Install Microsoft Edge
            winget install -e --id Microsoft.Edge --accept-source-agreements --accept-package-agreements -h;
            
            # Install Google Chrome
            winget install -e --id Google.Chrome --accept-source-agreements --accept-package-agreements -h;
            
            # Install VS Code
            winget install -e --id Microsoft.VisualStudioCode --accept-source-agreements --accept-package-agreements -h;
            
            # Install Azure CLI
            winget install -e --id Microsoft.AzureCLI --accept-source-agreements --accept-package-agreements -h;
            
            # Install Git
            winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements -h;
            
            # Install PowerShell 7
            winget install -e --id Microsoft.PowerShell --accept-source-agreements --accept-package-agreements -h;
            
            Write-Host 'Winget installations completed.';
          } else {
            Write-Host 'Winget not available, falling back to direct downloads...';
            
            # Fallback: Install Azure CLI directly
            $ProgressPreference = 'SilentlyContinue';
            Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\\AzureCLI.msi;
            Start-Process msiexec.exe -ArgumentList '/I AzureCLI.msi /quiet' -Wait;
            Remove-Item .\\AzureCLI.msi -Force;
            
            # Fallback: Install VS Code directly
            Invoke-WebRequest -Uri 'https://code.visualstudio.com/sha/download?build=stable&os=win32-x64' -OutFile .\\VSCodeSetup.exe;
            Start-Process -FilePath .\\VSCodeSetup.exe -ArgumentList '/VERYSILENT /MERGETASKS=!runcode' -Wait;
            Remove-Item .\\VSCodeSetup.exe -Force;
          }
          
          # Create desktop shortcut for AI Foundry
          $WshShell = New-Object -ComObject WScript.Shell;
          $Shortcut = $WshShell.CreateShortcut('C:\\Users\\Public\\Desktop\\Azure AI Foundry.url');
          $Shortcut.TargetPath = 'https://ai.azure.com';
          $Shortcut.Save();
          
          Stop-Transcript;
        "
      '''
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
