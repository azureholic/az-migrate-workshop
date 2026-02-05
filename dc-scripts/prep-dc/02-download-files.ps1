# Download files from Azure Storage using AzCopy with Managed Identity
# This script runs on the DC VM

param(
    [string]$StorageAccountName,
    [string]$ContainerName = "scripts",
    [string]$TargetPath = "C:\dc-files"
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Download Files from Azure Storage ===" -ForegroundColor Yellow
Write-Host "Storage Account: $StorageAccountName" -ForegroundColor Cyan
Write-Host "Container: $ContainerName" -ForegroundColor Cyan
Write-Host "Target: $TargetPath`n" -ForegroundColor Cyan

# Verify AzCopy exists
$azCopyExe = Join-Path $TargetPath 'azcopy.exe'
if (-not (Test-Path $azCopyExe)) {
    Write-Host "ERROR: AzCopy not found at $azCopyExe" -ForegroundColor Red
    Write-Host "Please run 01-download-azcopy.ps1 first" -ForegroundColor Yellow
    exit 1
}

# Build source URL
$sourceUrl = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/*"
Write-Host "Source URL: $sourceUrl" -ForegroundColor Gray

# Set environment variable for AzCopy to use managed identity
$env:AZCOPY_AUTO_LOGIN_TYPE = 'MSI'

# Download files using AzCopy
Write-Host "`nDownloading files..." -ForegroundColor Cyan

try {
    & $azCopyExe copy $sourceUrl $TargetPath --recursive=true --overwrite=true
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nDownload complete!" -ForegroundColor Green
    } else {
        Write-Host "`nWARNING: AzCopy completed with exit code: $LASTEXITCODE" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: Failed to download files: $_" -ForegroundColor Red
    exit 1
}

# Display downloaded files (excluding azcopy.exe)
Write-Host "`nFiles in ${TargetPath}:" -ForegroundColor Yellow
Get-ChildItem -Path $TargetPath -File | 
    Where-Object { $_.Name -ne 'azcopy.exe' } | 
    Select-Object Name, @{N='Size (KB)';E={[math]::Round($_.Length/1KB,2)}} |
    Format-Table -AutoSize
