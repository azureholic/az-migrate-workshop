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
Login with az-migration credentials (Administrate/<your pwd>)


other credentials
  - Webapp runs at: http://<vm-ip>:3000
  - PostgreSQL user: webadmin / webadmin123
  - SSH login: ubuntu / ubuntu

