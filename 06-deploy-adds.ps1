# Azure Migration Workshop - Deploy Windows Server 2019 ADDS VM
# This script orchestrates a fully unattended Windows Server Domain Controller deployment on the DC host.
# Uses a pre-built autoinstall ISO - single ISO, fully automated.

param(
    [string]$ResourceGroupName = "rg-migrate-workshop",
    [string]$VMName = "vm-dc",
    [string]$ScriptsPath = ".\dc-scripts\adds-vm",
    [string]$VMFilesPath = "C:\dc-files"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Azure Migration Workshop - Deploy Windows Server 2019 ADDS VM ===" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "VM Name: $VMName`n" -ForegroundColor Cyan

# Helper: run a script on the DC VM via az vm run-command and check for errors
function Invoke-RunCommand {
    param(
        [string]$ScriptFile,
        [string[]]$Parameters,
        [string]$StepName
    )

    $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
    try {
        # Use ASCII encoding to avoid BOM issues with az vm run-command
        Get-Content -Path $ScriptFile -Raw | Out-File -FilePath $tempFile -Encoding ASCII

        $cmdArgs = @(
            "vm", "run-command", "invoke",
            "--resource-group", $ResourceGroupName,
            "--name", $VMName,
            "--command-id", "RunPowerShellScript",
            "--scripts", "@$tempFile",
            "--output", "json"
        )
        if ($Parameters) {
            $cmdArgs += "--parameters"
            $cmdArgs += $Parameters
        }

        $output = & az @cmdArgs 2>$null

        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: az vm run-command failed for '$StepName' (exit code $LASTEXITCODE)" -ForegroundColor Red
            exit 1
        }

        $result = ($output | ConvertFrom-Json).value
        $stdOut = ($result | Where-Object { $_.code -like '*StdOut*' }).message
        $stdErr = ($result | Where-Object { $_.code -like '*StdErr*' }).message

        if ($stdOut) { Write-Host $stdOut -ForegroundColor Gray }

        # Check for errors in stderr (ignore empty or whitespace-only)
        if ($stdErr -and $stdErr.Trim().Length -gt 0) {
            Write-Host "`nVM script stderr output:" -ForegroundColor Yellow
            Write-Host $stdErr -ForegroundColor Red
            Write-Host "ERROR: '$StepName' failed on the VM" -ForegroundColor Red
            exit 1
        }
    } finally {
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
}

# ============================================
# 1. Verify scripts exist
# ============================================
Write-Host "[1/3] Checking scripts..." -ForegroundColor Yellow

if (-not (Test-Path $ScriptsPath)) {
    Write-Host "ERROR: Scripts directory not found: $ScriptsPath" -ForegroundColor Red
    exit 1
}

$script1 = Join-Path $ScriptsPath "01-download-iso.ps1"
$script2 = Join-Path $ScriptsPath "02-create-vm.ps1"

if (-not (Test-Path $script1)) {
    Write-Host "ERROR: Script not found: $script1" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $script2)) {
    Write-Host "ERROR: Script not found: $script2" -ForegroundColor Red
    exit 1
}

Write-Host "Found required scripts" -ForegroundColor Green

# ============================================
# 1b. Check if ADDS VM already exists on DC host
# ============================================
Write-Host "`nChecking if ADDS VM already exists on DC host..." -ForegroundColor Gray

$vmCheckOutput = az vm run-command invoke `
    --resource-group $ResourceGroupName `
    --name $VMName `
    --command-id RunPowerShellScript `
    --scripts "if (Get-VM -Name 'adds-vm' -ErrorAction SilentlyContinue) { Write-Host 'EXISTS' } else { Write-Host 'NOTFOUND' }" `
    --output json 2>$null

$vmCheckResult = ($vmCheckOutput | ConvertFrom-Json).value | Where-Object { $_.code -like '*StdOut*' } | Select-Object -ExpandProperty message

if ($vmCheckResult.Trim() -eq 'EXISTS') {
    Write-Host "ADDS VM already exists in Hyper-V on the DC host - nothing to do" -ForegroundColor Green
    Write-Host "To redeploy, first remove the VM from Hyper-V Manager on the DC host" -ForegroundColor Cyan
    Write-Host "" 
    exit 0
}

Write-Host "ADDS VM not found - proceeding with deployment" -ForegroundColor Gray

# ============================================
# 2. Download Windows Server ISO on VM
# ============================================
Write-Host "`n[2/3] Downloading Windows Server 2019 ADDS autoinstall ISO on VM..." -ForegroundColor Cyan
Write-Host "Target location on VM: $VMFilesPath" -ForegroundColor Gray
Write-Host "(This may take several minutes)`n" -ForegroundColor Yellow

Invoke-RunCommand -ScriptFile $script1 -Parameters "TargetPath=$VMFilesPath" -StepName "Download Windows Server ISO"
Write-Host "`nWindows Server ISO download completed!" -ForegroundColor Green

# ============================================
# 3. Create ADDS VM in Hyper-V
# ============================================
Write-Host "`n[3/3] Creating Windows Server 2019 ADDS VM in Hyper-V..." -ForegroundColor Cyan
Write-Host "Gen 2 VM with Secure Boot enabled and autoinstall ISO attached`n" -ForegroundColor Gray

Invoke-RunCommand -ScriptFile $script2 -StepName "Create ADDS VM"
Write-Host "`nADDS VM creation completed!" -ForegroundColor Green

# ============================================
# Summary
# ============================================
Write-Host "`n=== Windows Server 2019 ADDS VM Deployment Complete ===" -ForegroundColor Yellow
Write-Host "`nWhat happened:" -ForegroundColor Yellow
Write-Host "1. Downloaded Windows Server 2019 ADDS autoinstall ISO to $VMFilesPath" -ForegroundColor Cyan
Write-Host "2. Created ADDS VM in Hyper-V with:" -ForegroundColor Cyan
Write-Host "   - Generation 2 (UEFI, Secure Boot On)" -ForegroundColor Gray
Write-Host "   - 2 vCPUs, 2-4GB RAM" -ForegroundColor Gray
Write-Host "   - 80GB VHD" -ForegroundColor Gray
Write-Host "   - TPM enabled (if available)" -ForegroundColor Gray
Write-Host "   - Static IP: 192.168.100.20 (DHCP reservation)" -ForegroundColor Gray
Write-Host "   - Autoinstall ISO attached" -ForegroundColor Gray
Write-Host "`nThe VM will autoconfigure AD DS, DNS, and DNS forwarding during first boot" -ForegroundColor Cyan
Write-Host "Credentials: MIGRATE\Administrator or Administrator@migrate.local / Windows123!" -ForegroundColor Cyan
Write-Host ""
