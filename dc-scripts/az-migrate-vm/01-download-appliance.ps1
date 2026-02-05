# Download Azure Migrate Appliance ZIP
# This script runs on the DC VM

param(
    [string]$DownloadUrl = "https://go.microsoft.com/fwlink/?linkid=2191848",
    [string]$TargetPath = "C:\dc-files",
    [string]$FileName = "AzureMigrateAppliance.zip"
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Download Azure Migrate Appliance ===" -ForegroundColor Yellow
Write-Host "URL: $DownloadUrl" -ForegroundColor Cyan
Write-Host "Target: $TargetPath`n" -ForegroundColor Cyan

# ============================================
# 1. Prepare Target Directory
# ============================================
Write-Host "[1/3] Preparing target directory..." -ForegroundColor Yellow

if (-not (Test-Path $TargetPath)) {
    Write-Host "Creating directory: $TargetPath" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
}

$zipPath = Join-Path $TargetPath $FileName
Write-Host "Destination: $zipPath" -ForegroundColor Gray

# ============================================
# 2. Check Existing File
# ============================================
Write-Host "`n[2/3] Checking for existing file..." -ForegroundColor Yellow

if (Test-Path $zipPath) {
    $existingSize = (Get-Item $zipPath).Length / 1GB
    Write-Host "ZIP already exists: $zipPath" -ForegroundColor Yellow
    Write-Host "Size: $([math]::Round($existingSize, 2)) GB" -ForegroundColor Gray
    Write-Host "`nTo re-download, delete the existing file first." -ForegroundColor Cyan
    exit 0
}

# ============================================
# 3. Download File
# ============================================
Write-Host "`n[3/3] Downloading Azure Migrate Appliance..." -ForegroundColor Yellow
Write-Host "This may take a while (file is several GB)...`n" -ForegroundColor Yellow

# Enable TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {
    $ProgressPreference = 'SilentlyContinue'
    
    Write-Host "Starting download..." -ForegroundColor Gray
    $startTime = Get-Date
    
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $zipPath -UseBasicParsing
    
    $ProgressPreference = 'Continue'
    $duration = (Get-Date) - $startTime
    
    Write-Host "`nDownload completed!" -ForegroundColor Green
    Write-Host "Duration: $($duration.ToString('mm\:ss'))" -ForegroundColor Gray
    
    # Verify download
    if (Test-Path $zipPath) {
        $fileSize = (Get-Item $zipPath).Length / 1GB
        Write-Host "`nFile Details:" -ForegroundColor Yellow
        Write-Host "  Name: $FileName" -ForegroundColor Cyan
        Write-Host "  Path: $zipPath" -ForegroundColor Cyan
        Write-Host "  Size: $([math]::Round($fileSize, 2)) GB" -ForegroundColor Cyan
        
        if ($fileSize -lt 1) {
            Write-Host "`nWARNING: File size seems too small!" -ForegroundColor Yellow
            Write-Host "Download may be incomplete or URL may be incorrect." -ForegroundColor Yellow
        } else {
            Write-Host "`nDownload successful!" -ForegroundColor Green
        }
    } else {
        Write-Host "ERROR: File not found after download" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "`nERROR: Failed to download file: $_" -ForegroundColor Red
    
    # Clean up partial download
    if (Test-Path $zipPath) {
        Write-Host "Removing incomplete download..." -ForegroundColor Yellow
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    }
    
    exit 1
}

Write-Host ""
