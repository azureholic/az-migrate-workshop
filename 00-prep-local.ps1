# Azure Migration Workshop - Local Preparation Script
# This script prepares the local environment by:
# 1. Creating an Ubuntu cloud-init ISO for unattended setup

param(
    [string]$PrepDir = ".\prep-files",
    [string]$OutputDir = ".\files"
)

$ErrorActionPreference = "Stop"

# Enable TLS 1.2 for downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Function to download file with progress
function Download-FileWithProgress {
    param(
        [string]$Url,
        [string]$Destination
    )
    
    Write-Host "Downloading from: $Url" -ForegroundColor Cyan
    Write-Host "Saving to: $Destination" -ForegroundColor Cyan
    
    try {
        # Use Invoke-WebRequest for better compatibility with redirects
        Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
        Write-Host "Download completed!" -ForegroundColor Green
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
        throw
    }
}

# Ensure directories exist
if (-not (Test-Path $PrepDir)) {
    New-Item -ItemType Directory -Path $PrepDir -Force | Out-Null
}
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-Host "`n=== Azure Migration Workshop - Local Prep ===" -ForegroundColor Yellow
Write-Host "Prep directory: $PrepDir" -ForegroundColor Cyan
Write-Host "Output directory: $OutputDir`n" -ForegroundColor Cyan

# ============================================
# 1. Create Ubuntu Cloud-Init ISO
# ============================================
Write-Host "[1/1] Creating Ubuntu Cloud-Init ISO..." -ForegroundColor Yellow

$cidataDir = Join-Path $PrepDir "cidata"
$isoOutput = Join-Path $OutputDir "ubuntu-seed.iso"

if (-not (Test-Path $cidataDir)) {
    Write-Host "Error: cidata directory not found at $cidataDir" -ForegroundColor Red
    exit 1
}

# Check if required files exist
$metaDataFile = Join-Path $cidataDir "meta-data"
$userDataFile = Join-Path $cidataDir "user-data"

if (-not (Test-Path $metaDataFile) -or -not (Test-Path $userDataFile)) {
    Write-Host "Error: meta-data and user-data files are required in cidata directory" -ForegroundColor Red
    exit 1
}

Write-Host "Found cloud-init configuration files:" -ForegroundColor Cyan
Write-Host "  - meta-data: $(Test-Path $metaDataFile)" -ForegroundColor Gray
Write-Host "  - user-data: $(Test-Path $userDataFile)" -ForegroundColor Gray

# Find oscdimg from Windows ADK
$oscdimgPaths = @(
    "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
    "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\x86\Oscdimg\oscdimg.exe",
    "C:\Program Files\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
    "C:\Program Files (x86)\Windows Kits\8.1\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
    "C:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
)

$oscdimg = $null
foreach ($path in $oscdimgPaths) {
    if (Test-Path $path) {
        $oscdimg = $path
        Write-Host "Found oscdimg: $path" -ForegroundColor Green
        break
    }
}

if (-not $oscdimg) {
    Write-Host "ERROR: oscdimg.exe not found!" -ForegroundColor Red
    Write-Host "Please install Windows Assessment and Deployment Kit (ADK)" -ForegroundColor Yellow
    Write-Host "Download from: https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install" -ForegroundColor Cyan
    Write-Host "Required component: Deployment Tools" -ForegroundColor Cyan
    throw "oscdimg.exe not found"
}

# Remove existing ISO if it exists
if (Test-Path $isoOutput) {
    Write-Host "Removing existing ISO..." -ForegroundColor Gray
    Remove-Item $isoOutput -Force
}

# Create ISO using oscdimg from Windows ADK
Write-Host "Creating ISO with oscdimg from Windows ADK..." -ForegroundColor Cyan
Write-Host "  Source: $cidataDir" -ForegroundColor Gray
Write-Host "  Output: $isoOutput" -ForegroundColor Gray

# Build arguments for oscdimg
$oscdimgArgs = @(
    "-j2",              # Joliet file system
    "-lcidata",         # Volume label: cidata
    $cidataDir,         # Source directory
    $isoOutput          # Output ISO file
)

# Execute oscdimg
$output = & $oscdimg $oscdimgArgs 2>&1
$exitCode = $LASTEXITCODE

# Display output
Write-Host $output -ForegroundColor Gray

# Check result
if ($exitCode -eq 0 -and (Test-Path $isoOutput)) {
    $isoSize = (Get-Item $isoOutput).Length / 1KB
    Write-Host "`nISO created successfully!" -ForegroundColor Green
    Write-Host "  Location: $isoOutput" -ForegroundColor Cyan
    Write-Host "  Size: $([math]::Round($isoSize, 2)) KB" -ForegroundColor Cyan
} else {
    Write-Host "`nERROR: Failed to create ISO (Exit code: $exitCode)" -ForegroundColor Red
    throw "ISO creation failed"
}

# ============================================
# Summary
# ============================================
Write-Host "`n=== Preparation Complete ===" -ForegroundColor Yellow
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  [+] Ubuntu ISO: $(if (Test-Path $isoOutput) { 'OK' } else { 'FAILED' })" -ForegroundColor $(if (Test-Path $isoOutput) { 'Green' } else { 'Red' })

Write-Host "`nOutput files location ($OutputDir):" -ForegroundColor Cyan
Write-Host "  - Ubuntu ISO: $isoOutput" -ForegroundColor Gray
Write-Host ""
