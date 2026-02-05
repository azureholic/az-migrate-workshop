# Start Ubuntu VM and Launch Console
# Simple helper to start the VM and open vmconnect

param(
    [string]$VMName = "ubuntu-vm",
    [string]$ServerName = "localhost"
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Ubuntu VM Console Access ===" -ForegroundColor Yellow
Write-Host "VM Name: $VMName`n" -ForegroundColor Cyan

# Check VM state
$vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue

if (-not $vm) {
    Write-Host "ERROR: VM not found: $VMName" -ForegroundColor Red
    exit 1
}

Write-Host "Current VM State: $($vm.State)" -ForegroundColor Gray

# Start VM if not running
if ($vm.State -ne 'Running') {
    Write-Host "Starting VM..." -ForegroundColor Yellow
    Start-VM -Name $VMName
    Write-Host "VM started" -ForegroundColor Green
    Start-Sleep -Seconds 5
} else {
    Write-Host "VM is already running" -ForegroundColor Green
}

# Launch VMConnect
Write-Host "`nLaunching Hyper-V console..." -ForegroundColor Yellow
Write-Host "Opening vmconnect for $VMName..." -ForegroundColor Cyan

Start-Process "vmconnect.exe" -ArgumentList $ServerName,$VMName

Write-Host "`n=== Instructions ===" -ForegroundColor Yellow
Write-Host "The Hyper-V VM Connect console should now be open.`n" -ForegroundColor Cyan

Write-Host "For Quick Manual Installation:" -ForegroundColor Yellow
Write-Host "1. At the Ubuntu menu, select 'Install Ubuntu Server'" -ForegroundColor White
Write-Host "2. Follow the installer prompts:" -ForegroundColor White
Write-Host "   - Language: English" -ForegroundColor Gray
Write-Host "   - Keyboard: US" -ForegroundColor Gray
Write-Host "   - Network: DHCP (default)" -ForegroundColor Gray
Write-Host "   - Storage: Use entire disk  (default)" -ForegroundColor Gray
Write-Host "   - Username: ubuntu" -ForegroundColor Gray
Write-Host "   - Password: <your choice>" -ForegroundColor Gray
Write-Host "   - Install OpenSSH server: YES" -ForegroundColor Gray
Write-Host "3. Installation takes ~10 minutes" -ForegroundColor White
Write-Host "4. Reboot when prompted`n" -ForegroundColor White

Write-Host "OR for Autoinstall (Advanced):" -ForegroundColor Yellow
Write-Host "1. At the GRUB boot menu, press 'e'" -ForegroundColor White
Write-Host "2. Find the line starting with 'linux'" -ForegroundColor White
Write-Host "3. Add at the end: autoinstall ds=nocloud;s=/dev/sr1/" -ForegroundColor White
Write-Host "4. Press Ctrl+X to boot" -ForegroundColor White
Write-Host "5. Installation will complete automatically`n" -ForegroundColor White

Write-Host "Note: After installation, remember the credentials you set" -ForegroundColor Cyan
Write-Host "You'll need them to login and configure the VM later" -ForegroundColor Cyan
