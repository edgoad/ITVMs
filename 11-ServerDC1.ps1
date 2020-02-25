#######################################################################
#
# Run on ServerDM1 once OS is installed
# Updated to run remotely using Hyper-v Direct
#
# NOTE: Will require several reboots
#
#######################################################################

# Setup credentials
$user = "administrator"
$pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)

# Configure name 
#######################################################################
# NOTE: REBOOT!
#######################################################################
Invoke-Command -VMName ServerDC1 -Credential $cred -ScriptBlock { 
    Rename-Computer -NewName ServerDC1 -force -restart 
    }

# Rename NICs 
Invoke-Command -VMName ServerDC1 -Credential $cred -ScriptBlock { 
    Get-NetAdapter | Rename-NetAdapter -NewName Internal 
    }

# Set UP addresses 
Invoke-Command -VMName ServerDC1 -Credential $cred -ScriptBlock {
    New-NetIPAddress -InterfaceAlias Internal -IPAddress 192.168.0.1 -PrefixLength 24 -DefaultGateway 192.168.0.250 
    Set-DnsClientServerAddress -InterfaceAlias Internal -ServerAddresses 127.0.0.1 
    }

# Install ADDS 
Invoke-Command -VMName ServerDC1 -Credential $cred -ScriptBlock {
    Install-WindowsFeature AD-Domain-Services -IncludeManagementTools 
    } 

# Configure AD 
#######################################################################
# NOTE: REBOOT!
#######################################################################
Invoke-Command -VMName ServerDC1 -Credential $cred -ScriptBlock {
    $smPass = ConvertTo-SecureString "Password01" -AsPlainText -Force 
    Install-ADDSForest -DomainName "MCSA2016.local" -SafeModeAdministratorPassword $smPass -Confirm:$false 
    }


# Update credentials for AD domain
$userDom = "mcsa2016\administrator"
$passDom = ConvertTo-SecureString "Password01" -AsPlainText -Force
$credDom = New-Object System.Management.Automation.PSCredential($userDom, $pass)

    # Fix DNS (if needed) 
Invoke-Command -VMName ServerDC1 -Credential $credDom -ScriptBlock {
    Get-DnsServerForwarder | Remove-DnsServerForwarder -Force 
    }

    # Configure Power save 
Invoke-Command -VMName ServerDC1 -Credential $credDom -ScriptBlock {
    powercfg -change -monitor-timeout-ac 0 
    }

    # IE Enhaced mode 
Invoke-Command -VMName ServerDC1 -Credential $credDom -ScriptBlock {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name IsInstalled -Value 0 
    }

    # Set UAC 
Invoke-Command -VMName ServerDC1 -Credential $credDom -ScriptBlock {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type "Dword" 
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 0 -Type "Dword" 
    }
 
