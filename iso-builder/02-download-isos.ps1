# Download base ISOs for autoinstall image building
# - Ubuntu Server 24.04.3 LTS
# - Windows Server 2019 Evaluation

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'  # Speeds up Invoke-WebRequest significantly

Write-Host "=== Base ISO Downloader ===" -ForegroundColor Cyan
Write-Host ""

$baseIsoDir = Join-Path $PSScriptRoot "base-iso"
if (-not (Test-Path $baseIsoDir)) {
    New-Item -Path $baseIsoDir -ItemType Directory -Force | Out-Null
}

# --- Ubuntu Server 24.04.3 LTS ---
$ubuntuUrl = "https://releases.ubuntu.com/24.04/ubuntu-24.04.3-live-server-amd64.iso"
$ubuntuIso = Join-Path $baseIsoDir "ubuntu-24.04.3-live-server-amd64.iso"

Write-Host "[1/2] Ubuntu Server 24.04.3 LTS" -ForegroundColor Cyan
if (Test-Path $ubuntuIso) {
    $size = [math]::Round((Get-Item $ubuntuIso).Length / 1GB, 2)
    Write-Host "  Already exists: $ubuntuIso ($size GB)" -ForegroundColor Green
} else {
    Write-Host "  Downloading from: $ubuntuUrl"
    Write-Host "  Destination: $ubuntuIso"
    Write-Host "  This may take a while..."
    try {
        Invoke-WebRequest -Uri $ubuntuUrl -OutFile $ubuntuIso -UseBasicParsing
        $size = [math]::Round((Get-Item $ubuntuIso).Length / 1GB, 2)
        Write-Host "  Download complete ($size GB)" -ForegroundColor Green
    } catch {
        Write-Host "  Download failed: $_" -ForegroundColor Red
        exit 1
    }
}

# --- Windows Server 2019 Evaluation ---
$winServerUrl = "https://go.microsoft.com/fwlink/p/?LinkID=2195167&clcid=0x409&culture=en-us&country=US"
$winServerIso = Join-Path $baseIsoDir "windows-server-2019-eval.iso"

Write-Host ""
Write-Host "[2/2] Windows Server 2019 Evaluation" -ForegroundColor Cyan
if (Test-Path $winServerIso) {
    $size = [math]::Round((Get-Item $winServerIso).Length / 1GB, 2)
    Write-Host "  Already exists: $winServerIso ($size GB)" -ForegroundColor Green
} else {
    Write-Host "  Downloading from: $winServerUrl"
    Write-Host "  Destination: $winServerIso"
    Write-Host "  This is a large download, please be patient..."
    try {
        Invoke-WebRequest -Uri $winServerUrl -OutFile $winServerIso -UseBasicParsing
        $size = [math]::Round((Get-Item $winServerIso).Length / 1GB, 2)
        Write-Host "  Download complete ($size GB)" -ForegroundColor Green
    } catch {
        Write-Host "  Download failed: $_" -ForegroundColor Red
        Write-Host "  You can also download manually from:" -ForegroundColor Yellow
        Write-Host "  https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2019" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "All base ISOs ready!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  03-create-ubuntu-iso.ps1   - Build base Ubuntu server ISO"
Write-Host "  04-create-webapp-iso.ps1   - Build Ubuntu webapp ISO"
Write-Host "  05-create-winserver-iso.ps1 - Build Windows Server ADDS ISO"
