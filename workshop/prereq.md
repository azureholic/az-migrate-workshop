# Azure Migration Workshop - Prerequisites

## Per Participant Requirements

Each participant needs the following before the workshop begins.

### 1. Azure Subscription

- An active Azure subscription.
- The participant's account must have **Owner** role on the subscription.

### 2. Workstation Software

Install the following on the participant's laptop or workstation:

| Tool | Description | Download |
|------|-------------|----------|
| **PowerShell (pwsh)** | PowerShell 7+ (cross-platform) | [https://aka.ms/install-powershell](https://aka.ms/install-powershell) |
| **Azure CLI** | Azure command-line interface | [https://aka.ms/installazurecli](https://aka.ms/installazurecli) |
| **Git** | Git command-line interface | [https://git-scm.com/downloads](https://git-scm.com/downloads) |
| **RDP Client** | Remote Desktop client (mstsc is built-in on Windows) | [https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/remote-desktop-clients](https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/remote-desktop-clients) |

## Environment Setup

### 1. Clone the Repository

Open a PowerShell terminal and clone the workshop repository:

```powershell
git clone https://github.com/azureholic/az-migrate-workshop.git
cd az-migrate-workshop
```

### 2. Sign in to Azure

Open a PowerShell terminal and sign in to the target subscription:

```powershell
az login
az account set --subscription "<subscription-id>"
```

### 3. Configure Parameters

Edit `dc-infra/main.bicepparam` to set the desired resource group name, location, and admin password.

### 4. Run the Setup Script

From the repository root, run:

```powershell
./prep-workshop-environment.ps1
```

This script will automatically:

1. Deploy the DC VM infrastructure (Bicep)
2. Prepare the DC VM (Hyper-V, NAT, DHCP)
3. Deploy a Windows Server 2019 ADDS VM in Hyper-V
4. Pre-download all required ISOs and appliance files
5. Wait for the ADDS VM to finish installation
6. Deploy the Azure Migrate appliance in Hyper-V
7. Deploy the Ubuntu Webapp VM in Hyper-V
8. Deploy an Ubuntu VM in Hyper-V

> **Note:** The full setup takes a while to complete. Ensure you have a stable internet connection throughout.
