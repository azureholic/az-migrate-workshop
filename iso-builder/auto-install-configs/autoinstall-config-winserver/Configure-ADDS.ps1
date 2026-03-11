# Configure-ADDS.ps1
# Installs and configures Active Directory Domain Services
# Creates new forest: migrate.local

$LogFile = "C:\Setup\ADDS-Setup.log"
$Domain = "migrate.local"
$NetBIOSName = "MIGRATE"
$SafeModePassword = ConvertTo-SecureString "Windows123!" -AsPlainText -Force

function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Out-File -Append -FilePath $LogFile
    Write-Host $Message
}

function Configure-WinRM {
    Write-Log "Configuring WinRM for remote management (Azure Migrate)..."
    try {
        # Enable PSRemoting
        Enable-PSRemoting -Force -SkipNetworkProfileCheck -ErrorAction SilentlyContinue

        # Configure WinRM service settings
        Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true -Force
        Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true -Force
        Set-Item WSMan:\localhost\Service\Auth\Negotiate -Value $true -Force
        Set-Item WSMan:\localhost\Service\Auth\Kerberos -Value $true -Force
        Set-Item WSMan:\localhost\Service\Auth\CredSSP -Value $true -Force
        Set-Item WSMan:\localhost\Client\TrustedHosts -Value '*' -Force
        Set-Item WSMan:\localhost\Service\MaxMemoryPerShellMB -Value 1024 -Force

        # Ensure WinRM service is running and set to auto-start
        Set-Service WinRM -StartupType Automatic
        Start-Service WinRM -ErrorAction SilentlyContinue
        winrm quickconfig -quiet 2>&1 | Out-Null

        # Create HTTPS listener with self-signed certificate
        $existingHttps = Get-ChildItem WSMan:\localhost\Listener | Where-Object { $_.Keys -contains 'Transport=HTTPS' }
        if (-not $existingHttps) {
            $hostname = [System.Net.Dns]::GetHostName()
            $cert = New-SelfSignedCertificate -DnsName $hostname, "DC01", "DC01.migrate.local" `
                -CertStoreLocation Cert:\LocalMachine\My -NotAfter (Get-Date).AddYears(5)
            winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"$hostname`";CertificateThumbprint=`"$($cert.Thumbprint)`"}" 2>&1 | Out-Null
            Write-Log "WinRM HTTPS listener created with certificate: $($cert.Thumbprint)"
        } else {
            Write-Log "WinRM HTTPS listener already exists."
        }

        # Open firewall rules for WinRM HTTP and HTTPS
        netsh advfirewall firewall set rule group="Windows Remote Management" new enable=yes 2>&1 | Out-Null
        # Ensure explicit rules for 5985/5986 in case group rule is missing
        netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=tcp action=allow 2>&1 | Out-Null
        netsh advfirewall firewall add rule name="WinRM-HTTPS" dir=in localport=5986 protocol=tcp action=allow 2>&1 | Out-Null

        # Enable CredSSP server role (required by Azure Migrate for domain-joined servers)
        Enable-WSManCredSSP -Role Server -Force -ErrorAction SilentlyContinue

        Write-Log "WinRM configured successfully (HTTP:5985, HTTPS:5986, CredSSP enabled)."
    }
    catch {
        Write-Log "WARNING: Failed to configure WinRM: $_"
    }
}

# Create setup directory if needed
if (-not (Test-Path "C:\Setup")) {
    New-Item -Path "C:\Setup" -ItemType Directory -Force | Out-Null
}

Write-Log "=== Active Directory Domain Services Setup ==="
Write-Log "Domain: $Domain"
Write-Log "NetBIOS Name: $NetBIOSName"

# Configure WinRM for remote management (needed for Azure Migrate)
Configure-WinRM

# Check if already a domain controller
$ADDSFeature = Get-WindowsFeature -Name AD-Domain-Services
if ((Get-WmiObject Win32_ComputerSystem).PartOfDomain -and (Get-ADDomainController -ErrorAction SilentlyContinue)) {
    Write-Log "This server is already a domain controller."

    # Re-apply WinRM config (domain promotion can reset WinRM settings)
    Write-Log "Re-applying WinRM configuration post domain promotion..."
    Configure-WinRM

    # Configure DNS forwarder to Azure DNS for non-migrate.local queries
    Write-Log "Configuring DNS forwarder to Azure DNS (168.63.129.16)..."
    try {
        # Remove all existing forwarders (clears default fec0 IPv6 addresses)
        $existing = Get-DnsServerForwarder -ErrorAction SilentlyContinue
        if ($existing.IPAddress) {
            foreach ($ip in $existing.IPAddress) {
                Remove-DnsServerForwarder -IPAddress $ip -Force -ErrorAction SilentlyContinue
                Write-Log "Removed existing forwarder: $ip"
            }
        }
        # Add Azure DNS as the sole forwarder
        Add-DnsServerForwarder -IPAddress "168.63.129.16" -ErrorAction Stop
        Write-Log "DNS forwarder to Azure DNS (168.63.129.16) added successfully."
    }
    catch {
        Write-Log "WARNING: Failed to configure DNS forwarder: $_"
    }

    # Disable auto-logon after successful setup
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon" -Value "0" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultPassword" -Value "" -Force

    Write-Log "Setup complete!"
    exit 0
}

# Check if ADDS role is installed
if (-not $ADDSFeature.Installed) {
    Write-Log "Installing AD-Domain-Services feature..."
    try {
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -ErrorAction Stop
        Write-Log "AD-Domain-Services feature installed successfully."
    }
    catch {
        Write-Log "ERROR: Failed to install AD-Domain-Services: $_"
        exit 1
    }
}
else {
    Write-Log "AD-Domain-Services feature is already installed."
}

# Check if domain already exists (reboot scenario)
try {
    $existingDomain = Get-ADDomain -ErrorAction SilentlyContinue
    if ($existingDomain) {
        Write-Log "Domain $($existingDomain.DNSRoot) already exists."

        # Re-apply WinRM config (domain promotion can reset WinRM settings)
        Write-Log "Re-applying WinRM configuration post domain promotion..."
        Configure-WinRM
        
        # Configure DNS forwarder to Azure DNS for non-migrate.local queries
        Write-Log "Configuring DNS forwarder to Azure DNS (168.63.129.16)..."
        try {
            # Remove all existing forwarders (clears default fec0 IPv6 addresses)
            $existing = Get-DnsServerForwarder -ErrorAction SilentlyContinue
            if ($existing.IPAddress) {
                foreach ($ip in $existing.IPAddress) {
                    Remove-DnsServerForwarder -IPAddress $ip -Force -ErrorAction SilentlyContinue
                    Write-Log "Removed existing forwarder: $ip"
                }
            }
            # Add Azure DNS as the sole forwarder
            Add-DnsServerForwarder -IPAddress "168.63.129.16" -ErrorAction Stop
            Write-Log "DNS forwarder to Azure DNS (168.63.129.16) added successfully."
        }
        catch {
            Write-Log "WARNING: Failed to configure DNS forwarder: $_"
        }
        
        # Disable auto-logon after successful setup
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon" -Value "0" -Force
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultPassword" -Value "" -Force
        
        Write-Log "Auto-logon disabled. Setup complete!"
        exit 0
    }
}
catch {
    # Domain doesn't exist yet, continue with setup
}

# Install new forest
Write-Log "Creating new AD forest: $Domain"
Write-Log "This will require a reboot..."

try {
    # Import the ADDSDeployment module
    Import-Module ADDSDeployment -ErrorAction Stop
    
    # Schedule this script to run again after reboot via RunOnce
    Write-Log "Scheduling script to run after reboot via RunOnce..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" `
        -Name "ConfigureADDS" `
        -Value "powershell.exe -ExecutionPolicy Bypass -File C:\Setup\Configure-ADDS.ps1" `
        -Force

    # Install new forest
    Install-ADDSForest `
        -DomainName $Domain `
        -DomainNetbiosName $NetBIOSName `
        -SafeModeAdministratorPassword $SafeModePassword `
        -InstallDns:$true `
        -CreateDnsDelegation:$false `
        -DatabasePath "C:\Windows\NTDS" `
        -LogPath "C:\Windows\NTDS" `
        -SysvolPath "C:\Windows\SYSVOL" `
        -DomainMode "WinThreshold" `
        -ForestMode "WinThreshold" `
        -NoRebootOnCompletion:$false `
        -Force:$true `
        -ErrorAction Stop
        
    Write-Log "Forest installation initiated. Server will reboot."
}
catch {
    Write-Log "ERROR: Failed to create AD forest: $_"
    Write-Log "Exception details: $($_.Exception.Message)"
    exit 1
}
