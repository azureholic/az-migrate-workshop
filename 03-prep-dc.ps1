# Azure Migration Workshop - Prepare DC VM
# This script:
# 1. Uploads files to Azure Storage
# 2. Runs setup scripts on the DC VM to download files

param(
    [string]$ResourceGroupName = "rg-migrate-workshop",
    [string]$LocalFilesPath = ".\files",
    [string]$ScriptsPath = ".\dc-scripts\prep-dc",
    [string]$ContainerName = "scripts",
    [string]$VMName = "vm-dc",
    [string]$VMFilesPath = "C:\dc-files"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Azure Migration Workshop - Prepare DC VM ===" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "VM Name: $VMName`n" -ForegroundColor Cyan

# ============================================
# 1. Verify local files and scripts exist
# ============================================
Write-Host "[1/6] Checking local files and scripts..." -ForegroundColor Yellow

# Check files
if (-not (Test-Path $LocalFilesPath)) {
    Write-Host "ERROR: Files directory not found: $LocalFilesPath" -ForegroundColor Red
    Write-Host "Please run 00-prep-local.ps1 first" -ForegroundColor Cyan
    exit 1
}

$filesToUpload = Get-ChildItem -Path $LocalFilesPath -File
if ($filesToUpload.Count -eq 0) {
    Write-Host "ERROR: No files found in $LocalFilesPath" -ForegroundColor Red
    exit 1
}

Write-Host "Found $($filesToUpload.Count) file(s) to upload:" -ForegroundColor Green
foreach ($file in $filesToUpload) {
    $sizeKB = [math]::Round($file.Length / 1KB, 2)
    Write-Host "  - $($file.Name) ($sizeKB KB)" -ForegroundColor Gray
}

# Check scripts
if (-not (Test-Path $ScriptsPath)) {
    Write-Host "ERROR: Scripts directory not found: $ScriptsPath" -ForegroundColor Red
    exit 1
}

$script1 = Join-Path $ScriptsPath "01-download-azcopy.ps1"
$script2 = Join-Path $ScriptsPath "02-download-files.ps1"
$script3 = Join-Path $ScriptsPath "03-enable-hyperv.ps1"

if (-not (Test-Path $script1)) {
    Write-Host "ERROR: Script not found: $script1" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $script2)) {
    Write-Host "ERROR: Script not found: $script2" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $script3)) {
    Write-Host "ERROR: Script not found: $script3" -ForegroundColor Red
    exit 1
}

Write-Host "Found required scripts" -ForegroundColor Green

# ============================================
# 2. Get Storage Account Name
# ============================================
Write-Host "`n[2/6] Getting storage account information..." -ForegroundColor Yellow

try {
    $storageAccounts = az storage account list --resource-group $ResourceGroupName --query "[?starts_with(name, 'stscripts')].name" --output tsv 2>&1
    
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($storageAccounts)) {
        Write-Host "ERROR: Could not find storage account in resource group $ResourceGroupName" -ForegroundColor Red
        Write-Host "Please run 01-deploy-dc.ps1 first" -ForegroundColor Cyan
        exit 1
    }
    
    $storageAccountName = $storageAccounts.Split("`n")[0].Trim()
    Write-Host "Storage Account: $storageAccountName" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to get storage account: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# 3. Upload files to Azure Storage
# ============================================
Write-Host "`n[3/6] Uploading files to Azure Storage..." -ForegroundColor Yellow

try {
    foreach ($file in $filesToUpload) {
        Write-Host "  Uploading $($file.Name)..." -ForegroundColor Gray
        
        az storage blob upload `
            --account-name $storageAccountName `
            --container-name $ContainerName `
            --name $file.Name `
            --file $file.FullName `
            --auth-mode login `
            --overwrite true `
            --output none
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: Failed to upload $($file.Name)" -ForegroundColor Red
            exit 1
        }
    }
    Write-Host "Files uploaded successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR: Failed to upload files: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# 4. Download and run AzCopy script on VM
# ============================================
Write-Host "`n[4/6] Downloading AzCopy on VM..." -ForegroundColor Cyan
Write-Host "(This may take a few minutes)`n" -ForegroundColor Gray

$script1Content = Get-Content -Path $script1 -Raw

try {
    # Save script to temp file
    $tempScriptFile = [System.IO.Path]::GetTempFileName() + ".ps1"
    $script1Content | Out-File -FilePath $tempScriptFile -Encoding UTF8
    
    # Execute on VM
    $output = az vm run-command invoke `
        --resource-group $ResourceGroupName `
        --name $VMName `
        --command-id RunPowerShellScript `
        --scripts "@$tempScriptFile" `
        --parameters "TargetPath=$VMFilesPath" `
        --output json 2>&1
    
    # Clean up temp file
    Remove-Item $tempScriptFile -Force -ErrorAction SilentlyContinue
    
    # Parse and display output
    $result = $output | ConvertFrom-Json
    $stdOut = $result.value | Where-Object { $_.code -like '*StdOut*' } | Select-Object -ExpandProperty message
    Write-Host $stdOut -ForegroundColor Gray
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nAzCopy download completed!" -ForegroundColor Green
    } else {
        Write-Host "`nWarning: Command may have completed with errors" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: Failed to execute command on VM: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# 5. Download files from storage using AzCopy on VM
# ============================================
Write-Host "`n[5/5] Downloading files from Azure Storage to VM..." -ForegroundColor Cyan
Write-Host "Target location on VM: $VMFilesPath`n" -ForegroundColor Gray

$script2Content = Get-Content -Path $script2 -Raw

try {
    # Save script to temp file
    $tempScriptFile = [System.IO.Path]::GetTempFileName() + ".ps1"
    $script2Content | Out-File -FilePath $tempScriptFile -Encoding UTF8
    
    # Execute on VM
    $output = az vm run-command invoke `
        --resource-group $ResourceGroupName `
        --name $VMName `
        --command-id RunPowerShellScript `
        --scripts "@$tempScriptFile" `
        --parameters "StorageAccountName=$storageAccountName" "ContainerName=$ContainerName" "TargetPath=$VMFilesPath" `
        --output json 2>&1
    
    # Clean up temp file
    Remove-Item $tempScriptFile -Force -ErrorAction SilentlyContinue
    
    # Parse and display output
    $result = $output | ConvertFrom-Json
    $stdOut = $result.value | Where-Object { $_.code -like '*StdOut*' } | Select-Object -ExpandProperty message
    Write-Host $stdOut -ForegroundColor Gray
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nFiles successfully downloaded to VM!" -ForegroundColor Green
    } else {
        Write-Host "`nWarning: Command may have completed with errors" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: Failed to execute command on VM: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# 6. Enable Hyper-V on VM (will cause reboot)
# ============================================
Write-Host "`n[6/6] Enabling Hyper-V on VM..." -ForegroundColor Yellow
Write-Host "Note: This will cause the VM to reboot`n" -ForegroundColor Cyan

$script3Content = Get-Content -Path $script3 -Raw

try {
    # Save script to temp file
    $tempScriptFile = [System.IO.Path]::GetTempFileName() + ".ps1"
    $script3Content | Out-File -FilePath $tempScriptFile -Encoding UTF8
    
    # Execute on VM
    Write-Host "Installing Hyper-V feature..." -ForegroundColor Cyan
    $output = az vm run-command invoke `
        --resource-group $ResourceGroupName `
        --name $VMName `
        --command-id RunPowerShellScript `
        --scripts "@$tempScriptFile" `
        --output json 2>&1
    
    # Clean up temp file
    Remove-Item $tempScriptFile -Force -ErrorAction SilentlyContinue
    
    # Parse and display output
    $result = $output | ConvertFrom-Json
    $stdOut = $result.value | Where-Object { $_.code -like '*StdOut*' } | Select-Object -ExpandProperty message
    Write-Host $stdOut -ForegroundColor Gray
    
    Write-Host "`nVM is rebooting..." -ForegroundColor Yellow
    Write-Host "Waiting for VM to come back online (checking every 30 seconds)...`n" -ForegroundColor Cyan
    
    # Wait a bit for the reboot to start
    Start-Sleep -Seconds 30
    
    # Poll until VM is back online
    $maxAttempts = 40  # 40 * 30 seconds = 20 minutes max wait
    $attempt = 0
    $isOnline = $false
    
    while (-not $isOnline -and $attempt -lt $maxAttempts) {
        $attempt++
        Write-Host "[$attempt/$maxAttempts] Checking VM status..." -ForegroundColor Gray
        
        try {
            # Try to run a simple command on the VM
            $testOutput = az vm run-command invoke `
                --resource-group $ResourceGroupName `
                --name $VMName `
                --command-id RunPowerShellScript `
                --scripts "Write-Host 'Online'" `
                --output json 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                $testResult = $testOutput | ConvertFrom-Json
                if ($testResult.value) {
                    Write-Host "VM is back online!" -ForegroundColor Green
                    $isOnline = $true
                }
            }
        } catch {
            # VM not ready yet, continue waiting
        }
        
        if (-not $isOnline -and $attempt -lt $maxAttempts) {
            Start-Sleep -Seconds 30
        }
    }
    
    if (-not $isOnline) {
        Write-Host "WARNING: VM did not come back online within expected time" -ForegroundColor Yellow
        Write-Host "Please check the VM status in Azure Portal" -ForegroundColor Yellow
    } else {
        Write-Host "Hyper-V installation complete!" -ForegroundColor Green
    }
    
} catch {
    Write-Host "ERROR: Failed to enable Hyper-V: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# Summary
# ============================================
Write-Host "`n=== Preparation Complete ===" -ForegroundColor Yellow
Write-Host "Files are now available on the DC VM at: $VMFilesPath" -ForegroundColor Cyan
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Connect to VM via Azure Bastion" -ForegroundColor Cyan
Write-Host "2. Verify files in $VMFilesPath" -ForegroundColor Cyan
Write-Host "3. Continue with VM configuration" -ForegroundColor Cyan
Write-Host ""

