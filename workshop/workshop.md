Login to Azure CLI to your subscription
    az login
    az account set --subscription <your subscription>
Run prep-workshop-environment (deployment will take around 30 minutes)
Go to Azure Portal
Connect via Bastion to vm-dc
Open Hyper-V manager
Connect to az-migrate VM
Set password
On local machine run tunnel.ps1
Connect with mstcs to localhost:33389
Login with az-migration credentials (Administrator/<your pwd>)

In azure portal 
go to Azure Migrate, select project
Within project goto discovery -> using appliance for Azure
Choose "yes with Hyper-V"
NAme your appliance (az-migrate) and choose "Generate Key"

On the Azure Migrate Appliance (RDP session through tunner)
1. Set up prerequisites
Copy the Azure Migrate project Key and hit Verify
Auto Update will run (takes a couple of minutes) and browser will refresh automaticly
Verify project key again
wait for auto-update status to complete (no more updates)
Login to Azure
Wait for appliance registration to complete

2. Manage Credentials and discovery sources
Step1 Provide Hyper-V host credentials for discovery of Hyper-V VMs
Hit Add Credentials
    Source Type: HyperV Host/Cluster
    Friendy Name: datacenter
    Username: azureuser
    Password: $uper$ecretP@ssw0rd (see dc-infra/main.bicepparam for credentials)
Step 2: Provide Hyper-V host/cluster details
Hit "Add discovery source"
    Add single item
    Discovery Source: Hyper-V Host/Cluster
    IP Address / FQDN: 192.168.100.1
    Map credentials: datacenter
Wait for validation to complete
Step 3: Provide server credentials to perform guest discovery
Hit Add credentials
    Credentials type: Linux (Non Domain)
    Friendly name: ubuntu
    Username: ubuntu
    Password: ubuntu
Hit Add more
    Credentials type: PostgreSQL Server (password based)
    Friendly name: postgres
    Username: webadmin
    Password: webadmin123
Hit Save
Hit Start discovery
Wait for discovery to complete


//install this
https://aka.ms/downloaddra





other credentials
  - Webapp runs at: http://<vm-ip>:3000
  - PostgreSQL user: webadmin / webadmin123
  - SSH login: ubuntu / ubuntu

