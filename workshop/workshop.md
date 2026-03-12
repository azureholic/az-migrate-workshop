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

## Part 2: Connect to the VMs

### 2.1 Tunnel options

The `tunnel.ps1` script creates a Bastion tunnel to access VMs via RDP:

```powershell
# Connect to Azure Migrate appliance (default) → localhost:33389
.\tunnel.ps1

# Connect to DC VM directly → localhost:33390
.\tunnel.ps1 -Target DC
```

### 2.2 Connect to the DC VM

1. Run the tunnel script targeting the DC:
   ```powershell
   .\tunnel.ps1 -Target DC
   ```
2. Open **Remote Desktop Connection** (mstsc)
3. Connect to `localhost:33390`
4. Login with credentials:
   - **Username:** `azureuser`
   - **Password:** `$uper$ecretP@ssw0rd`

### 2.3 Connect to the Azure Migrate appliance

1. Run the tunnel script (defaults to AzMigrate):
   ```powershell
   .\tunnel.ps1
   ```
2. Open **Remote Desktop Connection** (mstsc)
3. Connect to `localhost:33389`
4. Login with the appliance credentials

### 2.4 Set the Azure Migrate appliance password

1. Connect to the DC VM (section 2.2)
2. Open **Hyper-V Manager** on the DC VM
3. Connect to the **az-migrate** VM
4. Set a password for the Administrator account when prompted

> **Tip:** After setting the appliance password, you can connect directly to it using `.\tunnel.ps1` (section 2.3)

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

Connect to the appliance using `.\tunnel.ps1` and RDP to `localhost:33389` (see section 2.3).

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
| Windows Hyper-V VM (ADDS) | `MIGRATE\Administrator` or `Administrator@migrate.local` | `Windows123!` |
| Ubuntu VM SSH | `ubuntu` | `ubuntu` |
| Webapp (http://\<webapp-vm-ip\>:3000) | — | — |
| PostgreSQL | `webadmin` | `webadmin123` |

## Reference: VM IP Addresses

| VM | IP Address | Access |
|----|------------|--------|
| az-migrate | 192.168.100.10 (reserved) | RDP via `.\tunnel.ps1` → localhost:33389 |
| adds-vm | 192.168.100.20 (reserved) | RDP from DC VM (Domain Controller) |
| webapp-vm | DHCP (192.168.100.x) | SSH or HTTP:3000 from DC VM |
| ubuntu-vm | DHCP (192.168.100.x) | SSH from DC VM |
| DC VM (gateway) | 192.168.100.1 | Hyper-V host for nested VMs |







