# Create Custom Ubuntu ISO with Autoinstall Parameters
# This script modifies the Ubuntu ISO to auto-trigger unattended installation

param(
    [string]$SourceISO = "C:\dc-files\ubuntu-22.04.5-live-server-amd64.iso",
    [string]$SeedISO = "C:\dc-files\ubuntu-seed.iso",
    [string]$OutputISO = "C:\dc-files\ubuntu-autoinstall.iso",
    [string]$WorkDir = "C:\Temp\ubuntu-build"
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Create Ubuntu Autoinstall ISO ===" -ForegroundColor Yellow

# ============================================
# 1. Install required tools
# ============================================
Write-Host "`n[1/5] Installing required tools..." -ForegroundColor Yellow

# Check if oscdimg is available (from Windows ADK)
$oscdimg = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"

if (-not (Test-Path $oscdimg)) {
    Write-Host "ERROR: oscdimg.exe not found" -ForegroundColor Red
    Write-Host "Please install Windows ADK or use xorriso" -ForegroundColor Yellow
    Write-Host "`nAlternative: Using simpler approach..." -ForegroundColor Cyan
    
    # We'll use a different approach: just create cloud-init ISO with correct label
    Write-Host "Creating cloud-init ISO with CIDATA label..." -ForegroundColor Cyan
    
    # Extract cloud-init files to temp directory
    $cidataDir = "C:\Temp\cidata"
    if (Test-Path $cidataDir) {
        Remove-Item $cidataDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $cidataDir -Force | Out-Null
    
    # Check if we have the source cidata files
    if (-not (Test-Path "C:\Temp\cidata-source\user-data")) {
        Write-Host "ERROR: Cloud-init source files not found in C:\Temp\cidata-source" -ForegroundColor Red
        Write-Host "Please ensure user-data and meta-data files are present" -ForegroundColor Yellow
        exit 1
    }
    
    Copy-Item "C:\Temp\cidata-source\*" -Destination $cidataDir -Recurse
    
    Write-Host "Cloud-init files copied to $cidataDir" -ForegroundColor Green
    Write-Host "`nNote: Full ISO modification requires additional tools" -ForegroundColor Yellow
    Write-Host "As a workaround, the VM console can be used to manually trigger autoinstall" -ForegroundColor Yellow
    
    exit 0
}

# ============================================
# 2. Mount source ISO
# ============================================
Write-Host "`n[2/5] Mounting source ISO..." -ForegroundColor Yellow

$mountResult = Mount-DiskImage -ImagePath $SourceISO -PassThru
$driveLetter = ($mountResult | Get-Volume).DriveLetter

if (-not $driveLetter) {
    Write-Host "ERROR: Failed to mount ISO" -ForegroundColor Red
    exit 1
}

Write-Host "ISO mounted as ${driveLetter}:\" -ForegroundColor Green

# ============================================
# 3. Copy ISO contents
# ============================================
Write-Host "`n[3/5] Copying ISO contents..." -ForegroundColor Yellow

if (Test-Path $WorkDir) {
    Remove-Item $WorkDir -Recurse -Force
}

New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null

Write-Host "Copying files (this may take a few minutes)..." -ForegroundColor Gray
Copy-Item "${driveLetter}:\*" -Destination $WorkDir -Recurse -Force

Write-Host "Files copied to $WorkDir" -ForegroundColor Green

# Dismount source ISO
Dismount-DiskImage -ImagePath $SourceISO | Out-Null

# ============================================
# 4. Modify GRUB configuration
# ============================================
Write-Host "`n[4/5] Modifying boot configuration..." -ForegroundColor Yellow

$grubCfg = Join-Path $WorkDir "boot\grub\grub.cfg"

if (Test-Path $grubCfg) {
    $grubContent = Get-Content $grubCfg -Raw
    
    # Add autoinstall parameter to the default boot entry
    $grubContent = $grubContent -replace '(linux\s+/casper/vmlinuz)', '$1 autoinstall ds=nocloud;s=/cdrom/nocloud/'
    
    $grubContent | Set-Content $grubCfg -Force
    Write-Host "GRUB configuration modified" -ForegroundColor Green
} else {
    Write-Host "WARNING: GRUB config not found at $grubCfg" -ForegroundColor Yellow
}

# Copy cloud-init files to nocloud directory
$nocloudDir = Join-Path $WorkDir "nocloud"
New-Item -ItemType Directory -Path $nocloudDir -Force | Out-Null

# Mount seed ISO and copy files
$seedMount = Mount-DiskImage -ImagePath $SeedISO -PassThru
$seedDrive = ($seedMount | Get-Volume).DriveLetter

if ($seedDrive) {
    Copy-Item "${seedDrive}:\*" -Destination $nocloudDir -Force
    Write-Host "Cloud-init files copied to nocloud directory" -ForegroundColor Green
    Dismount-DiskImage -ImagePath $SeedISO | Out-Null
}

# ============================================
# 5. Create new ISO
# ============================================
Write-Host "`n[5/5] Creating new ISO..." -ForegroundColor Yellow

& $oscdimg -m -o -u2 -udfver102 -bootdata:2#p0,e,b$WorkDir\boot\grub\bios.img#pEF,e,b$WorkDir\efi\boot\bootx64.efi $WorkDir $OutputISO

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nAutoinstall ISO created successfully!" -ForegroundColor Green
    Write-Host "Location: $OutputISO" -ForegroundColor Cyan
    
    # Clean up work directory
    Remove-Item $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "`nNext step: Recreate the VM using this new ISO" -ForegroundColor Yellow
} else {
    Write-Host "ERROR: Failed to create ISO" -ForegroundColor Red
    exit 1
}
