// ============================================================================
// Network Module - VNet, Subnets, NSGs, Bastion, NAT Gateway
// ============================================================================

@description('Azure region for the resources')
param location string

@description('Tags to apply to all resources')
param tags object = {}

@description('Name of the virtual network')
param vnetName string

@description('Address prefix for the VNet')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Name of the workload subnet')
param workloadSubnetName string = 'snet-workload'

@description('CIDR for the workload subnet (private endpoints + VMs)')
param workloadSubnetCidr string = '10.0.1.0/24'

@description('Name of the Bastion subnet')
param bastionSubnetName string = 'AzureBastionSubnet'

@description('CIDR for the Azure Bastion subnet (must be named AzureBastionSubnet)')
param bastionSubnetCidr string = '10.0.255.0/27'

@description('Name of the workload NSG')
param nsgName string

@description('Name of the Bastion NSG')
param bastionNsgName string

@description('Enable Azure Bastion for secure RDP/SSH access')
param enableBastion bool = true

@description('Enable NAT Gateway for outbound internet access from VNet')
param enableNatGateway bool = false

@description('Name for NAT Gateway')
param natGatewayName string = ''

@description('Name for NAT Gateway Public IP')
param natGatewayPipName string = ''

@description('Name for Bastion host')
param bastionName string = ''

@description('Name for Bastion Public IP')
param bastionPipName string = ''

// ============================================================================
// Network Security Group for Workload Subnet
// ============================================================================

resource workloadNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowBastionInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: bastionSubnetCidr
          sourcePortRange: '*'
          destinationAddressPrefix: workloadSubnetCidr
          destinationPortRanges: [
            '22'
            '3389'
          ]
          description: 'Allow RDP and SSH from Bastion subnet'
        }
      }
      {
        name: 'AllowVnetInbound'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '*'
          description: 'Allow all traffic within VNet'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          priority: 300
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          description: 'Allow Azure Load Balancer'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          description: 'Deny all other inbound traffic'
        }
      }
    ]
  }
}

// ============================================================================
// Network Security Group for Bastion Subnet
// ============================================================================

resource bastionNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = if (enableBastion) {
  name: bastionNsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          priority: 130
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          priority: 140
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowBastionHostCommunication'
        properties: {
          priority: 150
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
        }
      }
      {
        name: 'AllowSshRdpOutbound'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '22'
            '3389'
          ]
        }
      }
      {
        name: 'AllowAzureCloudOutbound'
        properties: {
          priority: 110
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureCloud'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowBastionCommunication'
        properties: {
          priority: 120
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
        }
      }
      {
        name: 'AllowGetSessionInformation'
        properties: {
          priority: 130
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '80'
        }
      }
    ]
  }
}

// ============================================================================
// NAT Gateway (Optional - for outbound internet access)
// ============================================================================

resource natPublicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = if (enableNatGateway) {
  name: natGatewayPipName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource natGateway 'Microsoft.Network/natGateways@2023-11-01' = if (enableNatGateway) {
  name: natGatewayName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 10
    publicIpAddresses: [
      {
        id: natPublicIp.id
      }
    ]
  }
}

// ============================================================================
// Virtual Network with Subnets
// ============================================================================

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: concat(
      [
        {
          name: workloadSubnetName
          properties: {
            addressPrefix: workloadSubnetCidr
            networkSecurityGroup: {
              id: workloadNsg.id
            }
            natGateway: enableNatGateway ? {
              id: natGateway.id
            } : null
            privateEndpointNetworkPolicies: 'Disabled'
            privateLinkServiceNetworkPolicies: 'Enabled'
          }
        }
      ],
      enableBastion ? [
        {
          name: bastionSubnetName
          properties: {
            addressPrefix: bastionSubnetCidr
            networkSecurityGroup: {
              id: bastionNsg.id
            }
            privateEndpointNetworkPolicies: 'Enabled'
            privateLinkServiceNetworkPolicies: 'Enabled'
          }
        }
      ] : []
    )
  }
}

// ============================================================================
// Azure Bastion (Optional - for secure VM access)
// ============================================================================

resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = if (enableBastion) {
  name: bastionPipName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-11-01' = if (enableBastion) {
  name: bastionName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    enableTunneling: true
    ipConfigurations: [
      {
        name: 'bastionIpConfig'
        properties: {
          publicIPAddress: {
            id: bastionPublicIp.id
          }
          subnet: {
            id: vnet.properties.subnets[1].id
          }
        }
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

output vnetId string = vnet.id
output vnetName string = vnet.name
output workloadSubnetId string = vnet.properties.subnets[0].id
output workloadSubnetName string = vnet.properties.subnets[0].name
output bastionSubnetId string = enableBastion ? vnet.properties.subnets[1].id : ''
output bastionName string = enableBastion ? bastion.name : ''
output bastionId string = enableBastion ? bastion.id : ''
output natGatewayId string = enableNatGateway ? natGateway.id : ''
