# Azure Migration Workshop

A hands-on workshop for migrating on-premises Hyper-V workloads to Azure using Azure Migrate.

---

## Prerequisites

- Azure subscription with Owner or Contributor access
- Azure CLI installed
- PowerShell 7+
- Remote Desktop client (mstsc)

---

## Part 1: Deploy the Workshop Environment

### 1.1 Login to Azure

```powershell
az login
az account set --subscription <your-subscription-id>
```

### 1.2 Run the environment setup

From the repository root, run:

```powershell
.\prep-workshop-environment.ps1
```

> **Note:** Deployment takes approximately 30 minutes. This provisions:
> - A DC VM with Hyper-V, NAT networking, and DHCP
> - Azure Migrate project, Recovery Services Vault, and replication storage
> - An Azure Migrate appliance VM (nested in Hyper-V)
> - A webapp VM and an Ubuntu VM (nested in Hyper-V)
> - Azure Bastion for secure access

---

## Part 2: Connect to the DC VM

### 2.1 Set up the Bastion tunnel

On your **local machine**, run:

```powershell
.\tunnel.ps1
```

This opens a Bastion tunnel on port **33389** to the DC VM.

### 2.2 Connect via RDP

1. Open **Remote Desktop Connection** (mstsc)
2. Connect to `localhost:33389`
3. Login with the DC VM credentials:
   - **Username:** `azureuser`
   - **Password:** `$uper$ecretP@ssw0rd`

### 2.3 Set the Azure Migrate appliance password

1. Open **Hyper-V Manager** on the DC VM
2. Connect to the **az-migrate** VM
3. Set a password for the Administrator account when prompted

---

## Part 3: Generate the Azure Migrate Appliance Key

### 3.1 In the Azure Portal

1. Navigate to **Azure Migrate**
2. Select your project (**migrate-project**)
3. Go to **Servers, databases and web apps** > **Discover**
4. Select **Using appliance** for Azure
5. Choose **Yes, with Hyper-V**
6. Name your appliance: `az-migrate`
7. Click **Generate Key**
8. **Copy the key** — you will need it in the next step

---

## Part 4: Configure the Azure Migrate Appliance

Access the appliance via the RDP session (localhost:33389).

### 4.1 Set up prerequisites

1. Paste the **Azure Migrate project key** and click **Verify**
2. Wait for the **Auto Update** to run (takes a couple of minutes — the browser will refresh automatically)
3. Verify the project key again if prompted
4. Wait for the auto-update status to show **no more updates**
5. Click **Login to Azure** and authenticate
6. Wait for **appliance registration** to complete

### 4.2 Manage credentials and discovery sources

#### Step 1: Add Hyper-V host credentials

Click **Add Credentials** and enter:

| Field | Value |
|-------|-------|
| Source Type | Hyper-V Host/Cluster |
| Friendly Name | `datacenter` |
| Username | `azureuser` |
| Password | `$uper$ecretP@ssw0rd` |

#### Step 2: Add Hyper-V host details

Click **Add discovery source** > **Add single item** and enter:

| Field | Value |
|-------|-------|
| Discovery Source | Hyper-V Host/Cluster |
| IP Address / FQDN | `192.168.100.1` |
| Map credentials | `datacenter` |

Wait for validation to complete.

#### Step 3: Add server credentials for guest discovery

Click **Add credentials** and add the following:

**Linux credentials:**

| Field | Value |
|-------|-------|
| Credentials type | Linux (Non Domain) |
| Friendly name | `ubuntu` |
| Username | `ubuntu` |
| Password | `ubuntu` |

Click **Add more**, then add:

**PostgreSQL credentials:**

| Field | Value |
|-------|-------|
| Credentials type | PostgreSQL Server (password based) |
| Friendly name | `postgres` |
| Username | `webadmin` |
| Password | `webadmin123` |

### 4.3 Start discovery

1. Click **Save**
2. Click **Start discovery**
3. Wait for discovery to complete

---

## Reference: Credentials

| Service | Username | Password |
|---------|----------|----------|
| DC VM (azureuser) | `azureuser` | `$uper$ecretP@ssw0rd` |
| Ubuntu VM SSH | `ubuntu` | `ubuntu` |
| Webapp (http://\<vm-ip\>:3000) | — | — |
| PostgreSQL | `webadmin` | `webadmin123` |







