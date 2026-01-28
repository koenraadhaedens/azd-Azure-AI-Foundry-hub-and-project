# Azure AI Foundry - Private Networking Infrastructure

This repository provides a **production-ready, fully private** Azure AI Foundry deployment using Azure Developer CLI (azd) and Bicep. All resources are deployed with **no public endpoints** and **Microsoft Entra ID (AAD) authentication only**.

---
> 🐛 **Found an issue?** Please [open an issue](../../issues) and tag [@koenraadhaedens](https://github.com/koenraadhaedens) and [@uweinside](https://github.com/uweinside) - we'll look into it!

---

## 👥 Co-Authors

- [@koenraadhaedens](https://github.com/koenraadhaedens)
- [@uweinside](https://github.com/uweinside)

---



## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Azure Subscription                              │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                    Resource Group                                 │  │
│  │                                                                   │  │
│  │  ┌─────────────────────────────────────────────────────────────┐  │  │
│  │  │                    Virtual Network                          │  │  │
│  │  │  ┌─────────────────────────────────────────────────────────┐│  │  │
│  │  │  │              Workload Subnet (snet-workload)            ││  │  │
│  │  │  │                                                         ││  │  │
│  │  │  │  ┌──────────┐  ┌──────────────────────────────────────┐ ││  │  │
│  │  │  │  │ Windows  │  │    Private Endpoints (All PaaS)      │ ││  │  │
│  │  │  │  │ Jumpbox  │  │  • Storage (blob,file,queue,table)   │ ││  │  │
│  │  │  │  │   VM     │  │  • Key Vault                         │ ││  │  │
│  │  │  │  │(no PubIP)│  │  • Container Registry                │ ││  │  │
│  │  │  │  └──────────┘  │  • AI Foundry Hub                    │ ││  │  │
│  │  │  │                │  • Cognitive Services (optional)     │ ││  │  │
│  │  │  │                └──────────────────────────────────────┘ ││  │  │
│  │  │  └─────────────────────────────────────────────────────────┘│  │  │
│  │  │  ┌─────────────────────────────────────────────────────────┐│  │  │
│  │  │  │           AzureBastionSubnet (optional)                 ││  │  │
│  │  │  │  ┌────────────────────────────────────────────────────┐ ││  │  │
│  │  │  │  │ Azure Bastion (Standard SKU, tunneling enabled)    │ ││  │  │
│  │  │  │  └────────────────────────────────────────────────────┘ ││  │  │
│  │  │  └─────────────────────────────────────────────────────────┘│  │  │
│  │  └─────────────────────────────────────────────────────────────┘  │  │
│  │                                                                   │  │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐  │  │
│  │  │   Storage   │ │  Key Vault  │ │     ACR     │ │  Log/AppIns │  │  │
│  │  │ (no keys)   │ │  (RBAC)     │ │ (no admin)  │ │             │  │  │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘  │  │
│  │                                                                   │  │
│  │  ┌───────────────────────────────────────────────────────────────┐│  │
│  │  │              AI Foundry Hub + Project                         ││  │
│  │  │  • publicNetworkAccess: Disabled                              ││  │
│  │  │  • Managed network with internet outbound                     ││  │
│  │  │  • Connected to Storage, KV, ACR, App Insights                ││  │
│  │  │  • Optional: Cognitive Services / Azure OpenAI connection     ││  │
│  │  └───────────────────────────────────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

## 🔐 Security Features

| Resource | Security Configuration |
|----------|----------------------|
| **Storage Account** | `allowSharedKeyAccess: false`, `publicNetworkAccess: Disabled`, `allowBlobPublicAccess: false` |
| **Key Vault** | `enableRbacAuthorization: true`, `publicNetworkAccess: Disabled` |
| **Container Registry** | `adminUserEnabled: false`, `publicNetworkAccess: Disabled` |
| **Cognitive Services** | `disableLocalAuth: true`, `publicNetworkAccess: Disabled` |
| **AI Foundry Hub/Project** | `publicNetworkAccess: Disabled`, System-assigned managed identity |
| **Windows VM** | No public IP, accessible only via Azure Bastion |

## � RBAC Role Assignments

The following roles are automatically assigned on the resource group to both the **VM's managed identity** and the **deploying user**:

| Role | Description |
|------|-------------|
| **Cognitive Services User** | Read access to Cognitive Services endpoints |
| **Cognitive Services Contributor** | Manage Cognitive Services resources |
| **Azure ML Data Scientist** | Work with Azure Machine Learning workspaces |
| **Azure AI Developer** | Develop AI applications |
| **Storage Blob Data Contributor** | Read, write, and delete blob data |
| **Key Vault Secrets User** | Read secrets from Key Vault |
| **Reader** | Read access to all resources in the resource group |

> 💡 These roles enable both the jumpbox VM (via its system-assigned managed identity) and the user running the deployment to interact with all AI Foundry resources without requiring keys or connection strings.

## �📋 Prerequisites

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) (v2.50+)
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) (v1.5+)

- Azure subscription with Owner or Contributor + User Access Administrator roles

> 💡 **Using Azure Cloud Shell?** Azure CLI and Azure Developer CLI are already pre-installed - no additional setup required!

### Supported Regions

If you're planning to use **Content Understanding** or other preview AI features, deploy to one of these supported regions:

| Region | Location Code |
|--------|---------------|

| Sweden Central | `swedencentral` |
| West us | `westus` |

## 🚀 Quick Start

### 1. Clone and Initialize

```bash
git clone <this-repo>
cd azd-Azure-AI-Foundry-hub-and-project

# Initialize azd environment
azd init -e dev
```

### 2. Deploy

```bash
# Login to Azure
azd auth login

# Deploy everything (you will be prompted for location and VM password)
azd up
```

> 📝 **Note:** During deployment, you will be prompted to:
> - Select the Azure location (use a supported region from the table above)
> - Enter the VM admin password (must meet Azure password complexity requirements)
>
> **Optional:** To grant RBAC to specific users, set their AAD Object IDs before deployment:
> ```bash
> azd env set AAD_OBJECT_ID_FOR_OWNERS "<object-id-1>,<object-id-2>"
> ```

### 3. Access AI Foundry Portal

Since all resources are private, you must access AI Foundry through the jumpbox VM:

1. **Connect via Azure Bastion:**
   ```bash
   # Get VM and Bastion names from outputs
   az network bastion rdp \
     --name <bastion-name> \
     --resource-group <resource-group> \
     --target-resource-id <vm-id>
   ```

2. **Or use Azure Portal:**
   - Navigate to the VM in Azure Portal
   - Click "Connect" → "Bastion"
   - Enter credentials: `azureadmin` / `<your-password>`

3. **Open AI Foundry:**
   - Open Edge/Chrome on the VM
   - Navigate to https://ai.azure.com
   - Sign in with your Azure AD credentials

## ⚙️ Configuration Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `environmentName` | Required | Environment name (e.g., `dev`, `prod`) |
| `location` | Required | Azure region |
| `namePrefix` | `aif` | Prefix for resource names (2-10 chars) |
| `vnetAddressPrefix` | `10.10.0.0/16` | VNet address space |
| `workloadSubnetCidr` | `10.10.1.0/24` | Workload subnet CIDR |
| `bastionSubnetCidr` | `10.10.2.0/26` | Bastion subnet CIDR |
| `enableBastion` | `true` | Deploy Azure Bastion |
| `enableNatGateway` | `false` | Deploy NAT Gateway for egress |
| `enableAzureOpenAI` | `false` | Deploy Cognitive Services |
| `vmAdminUsername` | `azureadmin` | VM admin username |
| `vmAdminPassword` | Required | VM admin password |
| `vmSize` | `Standard_D2s_v5` | VM size |
| `aadObjectIdForOwners` | `[]` | AAD Object IDs for RBAC |

## 📁 Project Structure

```
├── azure.yaml                 # azd project manifest
├── README.md                  # This file
└── infra/
    ├── main.bicep             # Main orchestrator
    ├── main.parameters.json   # Parameters file
    ├── abbreviations.json     # Resource naming abbreviations
    └── modules/
        ├── network.bicep      # VNet, subnets, NSGs, Bastion, NAT GW
        ├── privateDns.bicep   # All private DNS zones
        ├── monitor.bicep      # Log Analytics + App Insights
        ├── storage.bicep      # Storage with private endpoints
        ├── keyvault.bicep     # Key Vault with RBAC
        ├── acr.bicep          # Container Registry
        ├── cognitiveServices.bicep  # Azure AI Services
        ├── aiFoundry.bicep    # AI Hub + Project
        └── windowsVm.bicep    # Windows jumpbox VM
```

## 🔧 Post-Deployment Tasks

### Grant Additional Users Access

```bash
# Get your AAD Object ID
az ad signed-in-user show --query id -o tsv

# Set in azd environment and redeploy
azd env set AAD_OBJECT_ID_FOR_OWNERS "<object-id-1>,<object-id-2>"
azd provision
```

### Enable Azure OpenAI

```bash
azd env set ENABLE_AZURE_OPENAI "true"
azd provision
```

### Connect from VM to AI Foundry

The Windows VM is pre-configured with:
- Microsoft Edge & Chrome
- Visual Studio Code
- Azure CLI
- Desktop shortcut to https://ai.azure.com

## 🧹 Cleanup

```bash
# Delete all resources
azd down --force --purge
```

## 📝 Troubleshooting

### Cannot access AI Foundry Portal
- Ensure you're connected to the VM via Bastion
- Check that private DNS zones are linked to the VNet
- Verify your AAD account has the required RBAC roles

### VM cannot reach Azure services
- If `enableNatGateway` is false, the VM has no internet access
- Enable NAT Gateway or use service endpoints for Azure services

### Deployment fails with quota errors
- Check regional quotas for: vCPUs, Public IPs, Bastion hosts
- Try a different region or request quota increase

### "Preview API is not supported in this region"
This error occurs when using the **Content Understanding API (preview)** with an Azure AI Services resource deployed in an unsupported region.

**Supported Regions for Content Understanding (Preview):**
| Region | Location Code |
|--------|---------------|
| East US | `eastus` |
| West US 2 | `westus2` |
| West Europe | `westeurope` |
| Sweden Central | `swedencentral` |

**Solution:** Redeploy your Azure AI Services resource to one of the supported regions:

```bash
# Set location to a supported region
azd env set AZURE_LOCATION "eastus"

# Redeploy
azd up
```

> ⚠️ **Important:** If you're planning to use Content Understanding or other preview AI features, verify region availability in the [Azure AI Services documentation](https://learn.microsoft.com/azure/ai-services/content-understanding/) before deployment.

## 📚 Resources

- [Azure AI Foundry Documentation](https://learn.microsoft.com/azure/ai-studio/)
- [Azure Private Link](https://learn.microsoft.com/azure/private-link/)
- [Azure Bastion](https://learn.microsoft.com/azure/bastion/)
- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/)

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.
