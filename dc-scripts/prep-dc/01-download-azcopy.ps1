# Download and Extract AzCopy to C:\dc-files
# This script runs on the DC VM

param(
    [string]$TargetPath = "C:\dc-files"
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Download AzCopy ===" -ForegroundColor Yellow
Write-Host "Target: $TargetPath`n" -ForegroundColor Cyan

# Create destination folder
if (-not (Test-Path $TargetPath)) {
    New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
    Write-Host "Created directory: $TargetPath" -ForegroundColor Green
} else {
    Write-Host "Directory already exists: $TargetPath" -ForegroundColor Gray
}

# Download AzCopy
Write-Host "`nDownloading AzCopy..." -ForegroundColor Cyan
$azCopyZip = Join-Path $TargetPath 'azcopy.zip'
$azCopyUrl = 'https://aka.ms/downloadazcopy-v10-windows'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $azCopyUrl -OutFile $azCopyZip -UseBasicParsing

Write-Host "Download complete!" -ForegroundColor Green

# Extract AzCopy
Write-Host "`nExtracting AzCopy..." -ForegroundColor Cyan
Expand-Archive -Path $azCopyZip -DestinationPath $TargetPath -Force

# Find and move azcopy.exe to root of target directory
$extractedFolder = Get-ChildItem -Path $TargetPath -Directory | Where-Object { $_.Name -like 'azcopy_windows_*' } | Select-Object -First 1

if ($extractedFolder) {
    $azCopyExe = Join-Path $extractedFolder.FullName 'azcopy.exe'
    $finalPath = Join-Path $TargetPath 'azcopy.exe'
    
    Copy-Item -Path $azCopyExe -Destination $finalPath -Force
    Write-Host "Copied azcopy.exe to: $finalPath" -ForegroundColor Green
    
    # Cleanup
    Remove-Item -Path $extractedFolder.FullName -Recurse -Force
    Write-Host "Cleaned up extracted folder" -ForegroundColor Gray
} else {
    Write-Host "ERROR: Could not find extracted AzCopy folder" -ForegroundColor Red
    exit 1
}

# Remove zip file
Remove-Item -Path $azCopyZip -Force
Write-Host "Removed zip file" -ForegroundColor Gray

# Verify installation
$azCopyFinal = Join-Path $TargetPath 'azcopy.exe'
if (Test-Path $azCopyFinal) {
    $version = & $azCopyFinal --version 2>&1 | Select-Object -First 1
    Write-Host "`nAzCopy installed successfully!" -ForegroundColor Green
    Write-Host "Version: $version" -ForegroundColor Cyan
    Write-Host "Location: $azCopyFinal" -ForegroundColor Cyan
} else {
    Write-Host "`nERROR: AzCopy installation failed!" -ForegroundColor Red
    exit 1
}
