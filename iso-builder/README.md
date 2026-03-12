# Ubuntu & Windows Server Autoinstall ISO Builder

PowerShell toolkit for building custom autoinstall ISOs for Hyper-V virtual machines. Creates unattended installation media for Ubuntu Server and Windows Server 2019 with pre-configured settings.

## Generated ISOs

| ISO | OS | Purpose |
|---|---|---|
| `ubuntu-24.04.3-autoinstall.iso` | Ubuntu Server 24.04.3 | Base server with SSH, DHCP, Hyper-V tools |
| `ubuntu-24.04.3-webapp-autoinstall.iso` | Ubuntu Server 24.04.3 | Web application server with Node.js, PostgreSQL, PM2 |
| `windows-server-2019-adds-autoinstall.iso` | Windows Server 2019 | Active Directory Domain Controller (`migrate.local`) |

## Prerequisites

- Windows 10/11 with Hyper-V enabled
- PowerShell 5.1+
- Internet connection (for downloading ISOs and installing tools)
- Administrator privileges

## Quick Start

Run the scripts in order:

```powershell
# Run as Administrator — required for steps 1 and 5
# 1. Install build tools (WSL + xorriso, Windows ADK + oscdimg)
.\01-install-prerequisites.ps1

# 2. Download base ISOs (Ubuntu Server + Windows Server 2019)
.\02-download-isos.ps1

# 3. Build autoinstall ISOs (run any or all)
.\03-create-ubuntu-iso.ps1
.\04-create-webapp-iso.ps1
.\05-create-winserver-iso.ps1       # Requires RunAsAdministrator
```

## Scripts

| Script | Description |
|---|---|
| `01-install-prerequisites.ps1` | Installs WSL with Ubuntu + xorriso (for Linux ISOs) and Windows ADK Deployment Tools + oscdimg (for Windows ISOs). Requires admin. |
| `02-download-isos.ps1` | Downloads Ubuntu Server 24.04.3 LTS and Windows Server 2019 Evaluation ISOs into `base-iso/`. Skips if already downloaded. |
| `03-create-ubuntu-iso.ps1` | Builds the base Ubuntu autoinstall ISO using xorriso via WSL. Output goes to `autoinstall-iso/`. |
| `04-create-webapp-iso.ps1` | Builds the webapp Ubuntu ISO, bundling the `webapp/` directory into the ISO. Output goes to `autoinstall-iso/`. |
| `05-create-winserver-iso.ps1` | Builds the Windows Server ADDS ISO using oscdimg. Requires admin. Output goes to `autoinstall-iso/`. |

## Directory Structure

```
├── 01-install-prerequisites.ps1
├── 02-download-isos.ps1
├── 03-create-ubuntu-iso.ps1
├── 04-create-webapp-iso.ps1
├── 05-create-winserver-iso.ps1
├── auto-install-configs/
│   ├── autoinstall-config-ubuntu/       # Base Ubuntu server config
│   │   ├── grub.cfg
│   │   ├── meta-data
│   │   └── user-data
│   ├── autoinstall-config-webapp/       # Webapp Ubuntu config
│   │   ├── grub.cfg
│   │   ├── meta-data
│   │   └── user-data
│   └── autoinstall-config-winserver/    # Windows Server ADDS config
│       ├── Configure-ADDS.ps1
│       ├── SetupComplete.cmd
│       └── unattend.xml
├── webapp/                              # Node.js app bundled into webapp ISO
│   ├── app.js
│   ├── package.json
│   ├── setup-db.sh
│   ├── setup-db.sql
│   ├── setup-db-tables.sql
│   ├── webapp-setup.service
│   ├── public/
│   └── views/
├── base-iso/                            # Downloaded base ISOs (not tracked in git)
└── autoinstall-iso/                     # Generated autoinstall ISOs (not tracked in git)
```

## VM Configurations

### Ubuntu Server (`ubuntu-server`)

- **Networking:** DHCP
- **Packages:** openssh-server, curl, wget, Hyper-V tools
- **Credentials:** `ubuntu` / `ubuntu`
- **Storage:** LVM

### Ubuntu Webapp (`ubuntu-webapp`)

Same base as above, plus:

- **Node.js** 20.x with PM2 process manager
- **PostgreSQL** with auto-configured database
- **Products CRUD app** (Express + EJS) on port 3000
- **DB credentials:** `webadmin` / `webadmin123`

### Windows Server 2019 ADDS (`DC01`)

- **Domain:** `migrate.local` (NetBIOS: `MIGRATE`)
- **Role:** Active Directory Domain Controller
- **WinRM:** Enabled for remote management
- **Admin password:** `P@ssw0rd!` (change after install)

## Hyper-V VM Settings

Ubuntu ISOs are designed for **Generation 1** Hyper-V VMs with **Secure Boot disabled**. Windows ISO supports **Secure Boot**
