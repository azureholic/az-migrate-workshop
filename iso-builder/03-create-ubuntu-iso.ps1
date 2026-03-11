# Create bootable Ubuntu Autoinstall ISO using xorriso
# Reads config from autoinstall-config/ directory
# Prerequisites: WSL with xorriso (run 01-install-prerequisites.ps1)

$sourceIso = Join-Path $PSScriptRoot "base-iso\ubuntu-24.04.3-live-server-amd64.iso"
$outputDir = Join-Path $PSScriptRoot "autoinstall-iso"
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}
$outputIso = Join-Path $outputDir "ubuntu-24.04.3-autoinstall.iso"
$autoinstallDir = Join-Path $PSScriptRoot "auto-install-configs\autoinstall-config-ubuntu"

function ConvertTo-WslPath {
    param([string]$WindowsPath)
    $WindowsPath = $WindowsPath -replace '\\', '/'
    if ($WindowsPath -match '^([A-Za-z]):(.*)$') {
        return "/mnt/$($Matches[1].ToLower())$($Matches[2])"
    }
    return $WindowsPath
}

Write-Host "=== Ubuntu Server Autoinstall ISO Builder ===" -ForegroundColor Cyan
Write-Host ""

# Validate prerequisites
if (-not (Test-Path $sourceIso)) {
    Write-Host "Source ISO not found: $sourceIso" -ForegroundColor Red
    Write-Host "Run 02-download-isos.ps1 first." -ForegroundColor Yellow
    exit 1
}

$userDataPath = Join-Path $autoinstallDir "user-data"
$metaDataPath = Join-Path $autoinstallDir "meta-data"
$grubCfgPath = Join-Path $autoinstallDir "grub.cfg"

if (-not (Test-Path $userDataPath)) {
    Write-Host "user-data not found in $autoinstallDir" -ForegroundColor Red
    exit 1
}

# Ensure Unix line endings on config files
Write-Host "Ensuring Unix line endings on config files..."
foreach ($file in @($userDataPath, $grubCfgPath)) {
    if (Test-Path $file) {
        $content = Get-Content -Raw $file
        [System.IO.File]::WriteAllText($file, $content.Replace("`r`n", "`n"), [System.Text.UTF8Encoding]::new($false))
    }
}

# Remove old output and copy source
if (Test-Path $outputIso) {
    Remove-Item -Force $outputIso
}

Write-Host "Copying source ISO..." -ForegroundColor Cyan
Copy-Item $sourceIso $outputIso

Write-Host "Modifying ISO with xorriso..." -ForegroundColor Cyan

$wslOutputIso = ConvertTo-WslPath $outputIso
$wslUserData = ConvertTo-WslPath $userDataPath
$wslMetaData = ConvertTo-WslPath $metaDataPath
$wslGrubCfg = ConvertTo-WslPath $grubCfgPath

$xorrisoCmd = @"
xorriso -indev '$wslOutputIso' \
    -outdev '$wslOutputIso' \
    -boot_image any replay \
    -map '$wslUserData' /server/user-data \
    -map '$wslMetaData' /server/meta-data \
    -map '$wslUserData' /user-data \
    -map '$wslMetaData' /meta-data \
    -map '$wslGrubCfg' /boot/grub/grub.cfg \
    -commit
"@

wsl bash -c $xorrisoCmd

if ($LASTEXITCODE -ne 0) {
    Write-Host "xorriso modify failed. Trying extract+rebuild..." -ForegroundColor Yellow

    $extractPath = Join-Path $PSScriptRoot "iso-extract"
    $wslExtractPath = ConvertTo-WslPath $extractPath
    $wslSourceIso = ConvertTo-WslPath $sourceIso

    if (Test-Path $extractPath) { Remove-Item -Recurse -Force $extractPath }

    wsl bash -c "xorriso -osirrox on -indev '$wslSourceIso' -extract / '$wslExtractPath'"

    $serverDir = Join-Path $extractPath "server"
    New-Item -ItemType Directory -Force -Path $serverDir | Out-Null
    Copy-Item $userDataPath -Destination $serverDir -Force
    Copy-Item $metaDataPath -Destination $serverDir -Force
    Copy-Item $userDataPath -Destination $extractPath -Force
    Copy-Item $metaDataPath -Destination $extractPath -Force
    Copy-Item $grubCfgPath -Destination (Join-Path $extractPath "boot\grub\grub.cfg") -Force

    Remove-Item -Force $outputIso -ErrorAction SilentlyContinue

    $mbrPath = Join-Path $PSScriptRoot "mbr.img"
    $wslMbrPath = ConvertTo-WslPath $mbrPath
    wsl bash -c "dd if='$wslSourceIso' bs=1 count=432 of='$wslMbrPath' 2>/dev/null"

    $rebuildCmd = @"
cd '$wslExtractPath' && xorriso -as mkisofs \
    -r -V 'Ubuntu-Server-Autoinstall' \
    -o '$wslOutputIso' \
    --grub2-mbr '$wslMbrPath' \
    --protective-msdos-label \
    -partition_cyl_align off \
    -partition_offset 16 \
    --mbr-force-bootable \
    -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b '[BOOT]/2-Boot-NoEmul.img' \
    -appended_part_as_gpt \
    -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
    -c '/boot.catalog' \
    -b '/boot/grub/i386-pc/eltorito.img' \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --grub2-boot-info \
    -eltorito-alt-boot \
    -e '--interval:appended_partition_2:::' \
    -no-emul-boot \
    .
"@

    wsl bash -c $rebuildCmd
    Remove-Item $mbrPath -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $extractPath -ErrorAction SilentlyContinue
}

if ($LASTEXITCODE -eq 0 -and (Test-Path $outputIso)) {
    $isoSize = [math]::Round((Get-Item $outputIso).Length / 1MB, 2)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "ISO created successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Output: $outputIso"
    Write-Host "Size: $isoSize MB"
    Write-Host ""
    Write-Host "Hyper-V: Gen 1 VM (BIOS boot)" -ForegroundColor Cyan
    Write-Host "Credentials: ubuntu / ubuntu" -ForegroundColor Yellow
} else {
    Write-Host "Failed to create ISO" -ForegroundColor Red
    exit 1
}
