# Create bootable Windows Server 2019 Autoinstall ISO with ADDS
# Domain: migrate.local
# Prerequisites: Windows ADK with Deployment Tools (run 01-install-prerequisites.ps1)

#Requires -RunAsAdministrator

$sourceIso = Join-Path $PSScriptRoot "base-iso\windows-server-2019-eval.iso"
$outputDir = Join-Path $PSScriptRoot "autoinstall-iso"
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}
$outputIso = Join-Path $outputDir "windows-server-2019-adds-autoinstall.iso"
$autoinstallDir = Join-Path $PSScriptRoot "auto-install-configs\autoinstall-config-winserver"
$workDir = Join-Path $env:TEMP "WinServerISO_$(Get-Random)"

Write-Host "=== Windows Server 2019 ADDS Autoinstall ISO Builder ===" -ForegroundColor Cyan
Write-Host "Domain: migrate.local" -ForegroundColor Cyan
Write-Host ""

# Validate source ISO
if (-not (Test-Path $sourceIso)) {
    Write-Host "Source ISO not found: $sourceIso" -ForegroundColor Red
    Write-Host "Run 02-download-isos.ps1 first." -ForegroundColor Yellow
    exit 1
}

# Validate config files
$unattendPath = Join-Path $autoinstallDir "unattend.xml"
$addsScriptPath = Join-Path $autoinstallDir "Configure-ADDS.ps1"
$setupCompletePath = Join-Path $autoinstallDir "SetupComplete.cmd"

foreach ($file in @($unattendPath, $addsScriptPath)) {
    if (-not (Test-Path $file)) {
        Write-Host "Required file not found: $file" -ForegroundColor Red
        exit 1
    }
}

# Find oscdimg
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

if (-not $oscdimg) {
    Write-Host "oscdimg.exe not found!" -ForegroundColor Red
    Write-Host "Run 01-install-prerequisites.ps1 to install Windows ADK." -ForegroundColor Yellow
    exit 1
}
Write-Host "Found oscdimg: $oscdimg" -ForegroundColor Green

# Create work directory
New-Item -Path $workDir -ItemType Directory -Force | Out-Null

try {
    # Mount source ISO
    Write-Host "Mounting source ISO..." -ForegroundColor Cyan
    $mountResult = Mount-DiskImage -ImagePath $sourceIso -PassThru
    $driveLetter = ($mountResult | Get-Volume).DriveLetter
    if (-not $driveLetter) {
        throw "Failed to mount ISO - no drive letter assigned"
    }
    Write-Host "  Mounted at: ${driveLetter}:\" -ForegroundColor Green

    # Copy ISO contents
    Write-Host "Copying ISO contents (this may take a few minutes)..." -ForegroundColor Cyan
    Copy-Item -Path "${driveLetter}:\*" -Destination $workDir -Recurse -Force

    # Dismount source ISO
    Dismount-DiskImage -ImagePath $sourceIso | Out-Null
    Write-Host "  Source ISO dismounted" -ForegroundColor Green

    # Remove read-only attributes
    Get-ChildItem -Path $workDir -Recurse | ForEach-Object {
        $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
    }

    # Copy autounattend.xml to root
    Write-Host "Adding autounattend.xml..." -ForegroundColor Cyan
    Copy-Item -Path $unattendPath -Destination (Join-Path $workDir "autounattend.xml") -Force

    # Create Setup directory with ADDS script
    Write-Host "Adding ADDS configuration script..." -ForegroundColor Cyan
    $setupDir = Join-Path $workDir "Setup"
    New-Item -Path $setupDir -ItemType Directory -Force | Out-Null
    Copy-Item -Path $addsScriptPath -Destination $setupDir -Force

    # Copy SetupComplete.cmd to $OEM$ structure
    if (Test-Path $setupCompletePath) {
        $oemDir = Join-Path $workDir "sources\`$OEM`$\`$`$\Setup\Scripts"
        New-Item -Path $oemDir -ItemType Directory -Force | Out-Null
        Copy-Item -Path $setupCompletePath -Destination $oemDir -Force
        Write-Host "  Added SetupComplete.cmd to `$OEM`$ structure" -ForegroundColor Green
    }

    # Get boot files
    $etfsboot = Join-Path $workDir "boot\etfsboot.com"
    $efisys = Join-Path $workDir "efi\microsoft\boot\efisys_noprompt.bin"
    if (-not (Test-Path $efisys)) {
        $efisys = Join-Path $workDir "efi\microsoft\boot\efisys.bin"
    }

    if (-not (Test-Path $etfsboot)) { throw "BIOS boot file not found: $etfsboot" }
    if (-not (Test-Path $efisys)) { throw "UEFI boot file not found" }

    # Remove old output
    if (Test-Path $outputIso) {
        Remove-Item -Path $outputIso -Force
    }

    # Create bootable ISO
    Write-Host "Creating bootable ISO with oscdimg..." -ForegroundColor Cyan
    $oscdimgCmd = "`"$oscdimg`" -m -o -u2 -udfver102 -bootdata:2#p0,e,b`"$etfsboot`"#pEF,e,b`"$efisys`" `"$workDir`" `"$outputIso`""
    $result = cmd /c $oscdimgCmd 2>&1

    if ($LASTEXITCODE -ne 0) {
        $result | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
        throw "oscdimg failed with exit code: $LASTEXITCODE"
    }

    $isoSize = [math]::Round((Get-Item $outputIso).Length / 1GB, 2)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Windows Server ISO created successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Output: $outputIso"
    Write-Host "Size: $isoSize GB"
    Write-Host ""
    Write-Host "Configuration:" -ForegroundColor Yellow
    Write-Host "  Domain:        migrate.local"
    Write-Host "  NetBIOS:       MIGRATE"
    Write-Host "  Computer Name: DC01"
    Write-Host "  Admin Password: Windows123! (CHANGE THIS!)" -ForegroundColor Red
    Write-Host "  DSRM Password:  Windows123! (CHANGE THIS!)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Hyper-V: Gen 2 VM recommended (Secure Boot supported)" -ForegroundColor Cyan
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    try { Dismount-DiskImage -ImagePath $sourceIso -ErrorAction SilentlyContinue | Out-Null } catch {}
    exit 1
}
finally {
    Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan
    if (Test-Path $workDir) {
        Remove-Item -Path $workDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
