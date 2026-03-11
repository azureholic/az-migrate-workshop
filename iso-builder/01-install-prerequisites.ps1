# Install prerequisites for ISO building
# - WSL with xorriso (for Ubuntu ISOs)
# - Windows ADK Deployment Tools / oscdimg (for Windows Server ISOs)
# Idempotent: safe to run multiple times, skips already-installed components.

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$needsReboot = $false

Write-Host "=== Installing ISO Build Prerequisites ===" -ForegroundColor Cyan
Write-Host ""

# --- WSL ---
Write-Host "[1/3] Checking WSL..." -ForegroundColor Cyan
$wslReady = $false
try {
    $wslStatus = wsl --status 2>&1
    if ($LASTEXITCODE -eq 0) {
        $wslReady = $true
        Write-Host "  WSL is installed" -ForegroundColor Green
    }
} catch {}

if (-not $wslReady) {
    # Check if wsl.exe exists but WSL feature needs enabling
    $wslExe = Get-Command wsl.exe -ErrorAction SilentlyContinue
    if (-not $wslExe) {
        Write-Host "  WSL is not installed. Installing..." -ForegroundColor Yellow
        wsl --install --no-distribution
        $needsReboot = $true
        Write-Host "  WSL installed. Reboot required before continuing." -ForegroundColor Yellow
    } else {
        Write-Host "  WSL is installed but may need a reboot to finish setup." -ForegroundColor Yellow
        $needsReboot = $true
    }
}

# Check for WSL distro (only if WSL is ready)
if ($wslReady) {
    $distros = wsl --list --quiet 2>&1 | Where-Object { $_ -and $_ -notmatch '^\s*$' -and $_ -ne '' }
    if (-not $distros) {
        Write-Host "  No WSL distribution found. Installing Ubuntu..." -ForegroundColor Yellow
        wsl --install -d Ubuntu
        Write-Host "  Ubuntu distro installed in WSL" -ForegroundColor Green
    } else {
        Write-Host "  WSL distro found: $($distros[0])" -ForegroundColor Green
    }
}

# --- xorriso in WSL ---
Write-Host ""
Write-Host "[2/3] Checking xorriso in WSL..." -ForegroundColor Cyan
if (-not $wslReady) {
    Write-Host "  Skipped: WSL not ready yet (reboot required)" -ForegroundColor Yellow
} else {
    wsl which xorriso > $null 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  xorriso is already installed" -ForegroundColor Green
    } else {
        Write-Host "  Installing xorriso in WSL..." -ForegroundColor Yellow
        wsl sudo apt-get update -qq
        wsl sudo apt-get install -y xorriso
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  Failed to install xorriso in WSL" -ForegroundColor Red
            exit 1
        }
        Write-Host "  xorriso installed" -ForegroundColor Green
    }
}

# --- Windows ADK / oscdimg ---
Write-Host ""
Write-Host "[3/3] Checking Windows ADK (oscdimg)..." -ForegroundColor Cyan

$oscdimgPaths = @(
    "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
    "C:\Program Files\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
    "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
)

$oscdimg = $null
foreach ($path in $oscdimgPaths) {
    if (Test-Path $path) {
        $oscdimg = $path
        break
    }
}

if ($oscdimg) {
    Write-Host "  oscdimg found: $oscdimg" -ForegroundColor Green
} else {
    Write-Host "  oscdimg not found. Installing Windows ADK Deployment Tools..." -ForegroundColor Yellow

    $adkInstallerUrl = "https://go.microsoft.com/fwlink/?linkid=2243390"
    $adkInstallerPath = Join-Path $env:TEMP "adksetup.exe"

    Write-Host "  Downloading ADK installer..."
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $adkInstallerUrl -OutFile $adkInstallerPath -UseBasicParsing

    Write-Host "  Installing Deployment Tools (silent)..."
    $adkProcess = Start-Process -FilePath $adkInstallerPath `
        -ArgumentList "/features", "OptionId.DeploymentTools", "/quiet", "/norestart" `
        -Wait -PassThru

    if ($adkProcess.ExitCode -ne 0) {
        Write-Host "  ADK installation failed with exit code: $($adkProcess.ExitCode)" -ForegroundColor Red
        Write-Host "  Try installing manually from: https://go.microsoft.com/fwlink/?linkid=2243390" -ForegroundColor Yellow
        exit 1
    }

    # Verify
    $oscdimg = $null
    foreach ($path in $oscdimgPaths) {
        if (Test-Path $path) {
            $oscdimg = $path
            break
        }
    }

    if ($oscdimg) {
        Write-Host "  oscdimg installed: $oscdimg" -ForegroundColor Green
    } else {
        Write-Host "  Installation completed but oscdimg not found at expected paths." -ForegroundColor Red
        exit 1
    }

    Remove-Item $adkInstallerPath -ErrorAction SilentlyContinue
}

Write-Host ""
if ($needsReboot) {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Reboot required to finish WSL setup!" -ForegroundColor Yellow
    Write-Host "After rebooting, run this script again" -ForegroundColor Yellow
    Write-Host "to install remaining components." -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
} else {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "All prerequisites installed!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step: Run 02-download-isos.ps1 to download base ISOs" -ForegroundColor Cyan
}
