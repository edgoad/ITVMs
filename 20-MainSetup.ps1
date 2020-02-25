#######################################################################
#
# Second script for building Hyper-V environment for IT 160
# Run only after the OS is installed and initial configuration complete
#
#######################################################################

# Shutdown VMs, if not already
Get-VM | Stop-VM 

# Add second VLAN
New-VMSwitch -SwitchType Private -Name Private
 
# Setup interfaces
New-NetIPAddress -InterfaceAlias 'vEthernet (Internal)' -IPAddress 192.168.0.250 -PrefixLength 24
Rename-NetAdapter -InterfaceAlias 'vEthernet (Internal)' -NewName Internal

#Create Second NIC
Add-VMNetworkAdapter -VMName ServerDC1 -SwitchName Private
Add-VMNetworkAdapter -VMName ServerDM1 -SwitchName Private
Add-VMNetworkAdapter -VMName ServerDM2 -SwitchName Private
Add-VMNetworkAdapter -VMName ServerSA1 -SwitchName Private



# Start VMs
Get-VM | Start-VM

# Setup credentials
$user = "administrator"
$pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)
# Update credentials for AD domain
$userDom = "mcsa2016\administrator"
$passDom = ConvertTo-SecureString "Password01" -AsPlainText -Force
$credDom = New-Object System.Management.Automation.PSCredential($userDom, $pass)


# Configure new NIC
Invoke-Command -VMName ServerDC1 -Credential $credDom -ScriptBlock { 
    Get-NetAdapter | where Name -NE 'Internal' | Rename-NetAdapter -NewName Private
    New-NetIPAddress -InterfaceAlias Private -IPAddress 192.168.1.1 -PrefixLength 24 
    }
Invoke-Command -VMName ServerDM1 -Credential $credDom -ScriptBlock { 
    Get-NetAdapter | where Name -NE 'Internal' | Rename-NetAdapter -NewName Private
    New-NetIPAddress -InterfaceAlias Private -IPAddress 192.168.1.2 -PrefixLength 24 
    }
Invoke-Command -VMName ServerDM2 -Credential $cred -ScriptBlock { 
    Get-NetAdapter | where Name -NE 'Internal' | Rename-NetAdapter -NewName Private
    New-NetIPAddress -InterfaceAlias Private -IPAddress 192.168.1.3 -PrefixLength 24 
    }
Invoke-Command -VMName ServerSA1 -Credential $cred -ScriptBlock { 
    Get-NetAdapter | where Name -NE 'Internal' | Rename-NetAdapter -NewName Private
    New-NetIPAddress -InterfaceAlias Private -IPAddress 192.168.1.4 -PrefixLength 24 
    }
