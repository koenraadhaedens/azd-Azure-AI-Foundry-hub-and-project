# Azure AI Foundry Demo Guide

## Prerequisites

- Azure subscription with deployed Azure AI Foundry Hub and Project

---

## Step 1: Connect to the Jump VM via Bastion

1. Navigate to the **Azure Portal** (https://portal.azure.com)
2. Go to your **Resource Group** containing the deployed infrastructure
3. Select the **Virtual Machine** (Jump VM)
4. Click **Connect** → **Bastion**
5. Enter the credentials:
   - **Username:** `azureadmin`
   - **Password:** *(Use the password you provided during deployment)*
6. Click **Connect** to open a new browser tab with the VM session

---

## Step 2: Open Azure AI Foundry

1. On the Jump VM desktop, **double-click** the **Edge AI Foundry** shortcut
2. Edge will open and navigate to the Azure AI Foundry portal
3. Sign in with your Azure credentials if prompted

---

## Step 3: Create a Custom Task in AI Foundry

1. In the Azure AI Foundry portal, navigate to your **Project**
2. Go to **Build** → **Prompt flow** or **Custom tasks**
3. Click **+ Create** to start a new custom task
4. Configure your custom task:
   - Provide a **Name** for the task
   - Select the **Model** you want to use (e.g., GPT-4)
   - Define the **System prompt** for your task
   - Add any **Input/Output** parameters as needed
5. Click **Save** and **Test** your custom task
6. Review the results and iterate as needed

---

## Step 4: Open VS Code and Install Dependencies

1. On the Jump VM, open **Visual Studio Code**
2. Open the project folder containing your AI application code
3. Open the integrated terminal (`Ctrl + '`)
4. Install the required dependencies:

```bash
pip install -r requirements.txt
```

Common dependencies for Azure AI Foundry projects include:
- `azure-identity` - For Entra ID authentication
- `azure-ai-projects` - For AI Foundry project operations
- `openai` - For OpenAI-compatible API calls

---

## Step 5: Configure the .env File with Endpoint

1. In VS Code, create or open the `.env` file in your project root
2. Add the Azure AI Foundry endpoint:

```env
# Azure AI Foundry Configuration
AZURE_AI_PROJECT_ENDPOINT=https://<your-ai-foundry-endpoint>.cognitiveservices.azure.com/
PROJECT_CONNECTION_STRING=<your-project-connection-string>
```

> **How to find your endpoint:**
> - Go to Azure AI Foundry portal
> - Navigate to your Project → Settings
> - Copy the **Endpoint URL** and **Connection String**

---

## Step 6: Authentication - Entra ID Only (No API Keys!)

### Why Entra ID Instead of API Keys?

This deployment uses **Microsoft Entra ID (Azure AD)** authentication exclusively. Here's why:

| Feature | API Keys | Entra ID |
|---------|----------|----------|
| Security | Static secrets that can be leaked | Token-based, short-lived credentials |
| Rotation | Manual rotation required | Automatic token refresh |
| Auditing | Limited visibility | Full Azure audit logs |
| Access Control | All-or-nothing access | Fine-grained RBAC |
| Credential Management | Store/manage secrets | Managed Identity - no secrets to manage |

### How It Works

1. **Managed Identity** is enabled on the Jump VM
2. The VM automatically authenticates to Azure services
3. **No API keys or secrets** are stored in code or config files
4. Access is controlled via **Azure RBAC** roles

### Code Example - Using Entra ID Authentication

```python
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient

# DefaultAzureCredential automatically uses:
# - Managed Identity (on Azure VMs/services)
# - Azure CLI credentials (for local development)
# - Environment variables
credential = DefaultAzureCredential()

# Connect to AI Foundry - NO API KEY NEEDED!
client = AIProjectClient(
    endpoint="https://<your-endpoint>.cognitiveservices.azure.com/",
    credential=credential
)
```

### Benefits of This Approach

✅ **Zero secrets in code** - Nothing to leak or rotate  
✅ **Automatic authentication** - Managed Identity handles everything  
✅ **Audit trail** - All access is logged in Azure  
✅ **Least privilege** - RBAC controls exactly what each identity can do  
✅ **No key management** - Azure handles credential lifecycle  

---

## Summary

| Step | Action |
|------|--------|
| 1 | Connect to Jump VM via Bastion (`azureadmin` + deployment password) |
| 2 | Double-click Edge AI Foundry shortcut |
| 3 | Create and test a custom task in AI Foundry |
| 4 | Open VS Code and install dependencies (`pip install -r requirements.txt`) |
| 5 | Configure `.env` with endpoint (no keys!) |
| 6 | Use `DefaultAzureCredential` for Entra ID authentication |

---

## Next Steps

- Explore the [AI Foundry Documentation](https://learn.microsoft.com/azure/ai-studio/)
- Review the Lab exercises in the `Demos/AI-3002/` folder
- Experiment with different models and prompt configurations
