# Download Windows Server 2019 ADDS Autoinstall ISO
# This script runs on the DC VM
# Downloads a pre-built autoinstall ISO from Azure blob storage

param(
    [string]$TargetPath = "C:\dc-files",
    [string]$IsoUrl = "https://saazhpublic.blob.core.windows.net/pub/windows-server-2019-adds-autoinstall.iso"
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Download Windows Server 2019 ADDS ISO ===" -ForegroundColor Yellow
Write-Host "Target: $TargetPath`n" -ForegroundColor Cyan

# Ensure target directory exists
if (-not (Test-Path $TargetPath)) {
    Write-Host "Creating directory: $TargetPath" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
}

# Define output file
$isoFileName = "windows-server-2019-adds-autoinstall.iso"
$isoPath = Join-Path $TargetPath $isoFileName

# Check if ISO already exists
if (Test-Path $isoPath) {
    $existingSize = (Get-Item $isoPath).Length / 1MB
    Write-Host "ISO already exists: $isoPath" -ForegroundColor Yellow
    Write-Host "Size: $([math]::Round($existingSize, 2)) MB" -ForegroundColor Gray
    Write-Host "`nTo re-download, delete the existing file first." -ForegroundColor Cyan
    exit 0
}

Write-Host "Downloading Windows Server 2019 ADDS Autoinstall ISO..." -ForegroundColor Cyan
Write-Host "Source: $IsoUrl" -ForegroundColor Gray
Write-Host "Destination: $isoPath" -ForegroundColor Gray
Write-Host "This may take several minutes...`n" -ForegroundColor Yellow

# Enable TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Download with progress
try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $IsoUrl -OutFile $isoPath -UseBasicParsing
    $ProgressPreference = 'Continue'
    
    Write-Host "`nDownload completed!" -ForegroundColor Green
    
    # Verify file
    if (Test-Path $isoPath) {
        $fileSize = (Get-Item $isoPath).Length / 1MB
        Write-Host "File size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Gray
        Write-Host "ISO saved to: $isoPath" -ForegroundColor Cyan
    } else {
        Write-Host "ERROR: File not found after download!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "`nERROR: Download failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    # Clean up partial download
    if (Test-Path $isoPath) {
        Remove-Item $isoPath -Force
        Write-Host "Cleaned up partial download" -ForegroundColor Yellow
    }
    exit 1
}

Write-Host "`n=== Download Complete ===" -ForegroundColor Green
Write-Host "Next step: Run 02-create-vm.ps1 to create the Windows Server 2019 ADDS VM" -ForegroundColor Cyan
