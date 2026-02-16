# Download Ubuntu 24.04 Webapp Autoinstall ISO
# This script runs on the DC VM
# Downloads a pre-built autoinstall ISO with webapp configuration

param(
    [string]$TargetPath = "C:\dc-files",
    [string]$IsoUrl = "https://saazhpublic.blob.core.windows.net/pub/ubuntu-24.04.3-webapp-autoinstall.iso"
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Download Ubuntu 24.04 Webapp Server ISO ===" -ForegroundColor Yellow
Write-Host "Target: $TargetPath`n" -ForegroundColor Cyan

# Ensure target directory exists
if (-not (Test-Path $TargetPath)) {
    Write-Host "Creating directory: $TargetPath" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
}

# Define output file
$isoFileName = "ubuntu-24.04.3-webapp-autoinstall.iso"
$isoPath = Join-Path $TargetPath $isoFileName

# Check if ISO already exists
if (Test-Path $isoPath) {
    $existingSize = (Get-Item $isoPath).Length / 1MB
    Write-Host "ISO already exists: $isoPath" -ForegroundColor Yellow
    Write-Host "Size: $([math]::Round($existingSize, 2)) MB" -ForegroundColor Gray
    Write-Host "`nTo re-download, delete the existing file first." -ForegroundColor Cyan
    exit 0
}

Write-Host "Downloading Ubuntu 24.04.3 Webapp Autoinstall ISO..." -ForegroundColor Cyan
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
        Write-Host "`nISO Details:" -ForegroundColor Yellow
        Write-Host "  File: $isoFileName" -ForegroundColor Cyan
        Write-Host "  Path: $isoPath" -ForegroundColor Cyan
        Write-Host "  Size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Cyan
        
        # Verify reasonable file size
        if ($fileSize -lt 500) {
            Write-Host "`nWARNING: File size seems too small, download may be incomplete!" -ForegroundColor Yellow
        } else {
            Write-Host "`nUbuntu webapp autoinstall ISO downloaded successfully!" -ForegroundColor Green
        }
    } else {
        Write-Host "ERROR: ISO file not found after download" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "`nERROR: Failed to download ISO: $_" -ForegroundColor Red
    
    # Clean up partial download
    if (Test-Path $isoPath) {
        Write-Host "Removing incomplete download..." -ForegroundColor Yellow
        Remove-Item $isoPath -Force
    }
    
    exit 1
}
