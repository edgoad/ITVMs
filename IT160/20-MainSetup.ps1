#######################################################################
#
# Second script for building Hyper-V environment for IT 160
# Run only after the OS is installed and initial configuration complete
#
#######################################################################

#region Setup Private VLAN
# Shutdown VMs, if not already
Get-VM | Stop-VM 

# Add second VLAN
# Create virtual switch
# Set switch as Private -- no routing to the internet
if ((Get-VMSwitch | Where-Object -Property Name -EQ "Private").count -eq 0)
{
    write-host "Creating Private VMswitch"
    New-VMSwitch -SwitchType Private -Name Private
}


$classVMs = "ServerDC1", "ServerDM1", "ServerSA1", "ServerDM2", "ServerHyperV"
#Create Second NIC
#Add-VMNetworkAdapter -VMName ServerDC1 -SwitchName Private
Add-VMNetworkAdapter -VMName ServerDM1 -SwitchName Private
#Add-VMNetworkAdapter -VMName ServerDM2 -SwitchName Private
Add-VMNetworkAdapter -VMName ServerSA1 -SwitchName Private
#endregion

# Start VMs
Get-VM | Start-VM

#region Configure Private IP addresses
# Setup credentials
$user = "administrator"
$pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)
# Update credentials for AD domain
$userDom = "AZ800\administrator"
$passDom = ConvertTo-SecureString "Password01" -AsPlainText -Force
$credDom = New-Object System.Management.Automation.PSCredential($userDom, $pass)


# Configure new NIC
# Invoke-Command -VMName ServerDC1 -Credential $credDom -ScriptBlock { 
#     Get-NetAdapter | where Name -NE 'Internal' | Rename-NetAdapter -NewName Ethernet1
#     New-NetIPAddress -InterfaceAlias Ethernet1 -IPAddress 192.168.1.1 -PrefixLength 24 
#     }
Invoke-Command -VMName ServerDM1 -Credential $credDom -ScriptBlock { 
    Get-NetAdapter | where Name -NE 'Ethernet0' | Rename-NetAdapter -NewName Ethernet1
    New-NetIPAddress -InterfaceAlias Ethernet1 -IPAddress 172.31.0.101 -PrefixLength 24 
    }
# Invoke-Command -VMName ServerDM2 -Credential $credDom -ScriptBlock { 
#     Get-NetAdapter | where Name -NE 'Internal' | Rename-NetAdapter -NewName Ethernet1
#     New-NetIPAddress -InterfaceAlias Ethernet1 -IPAddress 192.168.1.3 -PrefixLength 24 
#     }
Invoke-Command -VMName ServerSA1 -Credential $cred -ScriptBlock { 
    Get-NetAdapter | where Name -NE 'Ethernet0' | Rename-NetAdapter -NewName Ethernet1
    New-NetIPAddress -InterfaceAlias Ethernet1 -IPAddress 172.31.0.240 -PrefixLength 24 
    }
#endregion

#region Use DISM to change Server Edition
#######################################################################
# NOTE: REBOOT!
# Will also return an error code - this is expected
# keys from https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys  
# and https://learn.microsoft.com/en-us/windows-server/get-started/automatic-vm-activation
#######################################################################
Invoke-Command -VMName ServerDC1 -AsJob -Credential $credDom -ScriptBlock { 
    dism /online /Set-Edition:ServerDataCenter /AcceptEULA /quiet /ProductKey:WX4NM-KYWYW-QJJR4-XV3QB-6VM33
    }
Invoke-Command -VMName ServerDM1 -AsJob -Credential $credDom -ScriptBlock { 
    dism /online /Set-Edition:ServerDataCenter /AcceptEULA /quiet /ProductKey:WX4NM-KYWYW-QJJR4-XV3QB-6VM33
    }
Invoke-Command -VMName ServerDM2 -AsJob -Credential $credDom -ScriptBlock { 
    dism /online /Set-Edition:ServerDataCenterCor /AcceptEULA /quiet /ProductKey:WX4NM-KYWYW-QJJR4-XV3QB-6VM33
    }
Invoke-Command -VMName ServerSA1 -AsJob -Credential $cred -ScriptBlock { 
    dism /online /Set-Edition:ServerDataCenter /AcceptEULA /quiet /ProductKey:WX4NM-KYWYW-QJJR4-XV3QB-6VM33
    }
#endregion

#region Use SLMGR to setup AVMA license key
# Setup credentials
$user = "administrator"
$pass = ConvertTo-SecureString "Password01" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)
# Update credentials for AD domain
$userDom = "AZ800\administrator"
$passDom = ConvertTo-SecureString "Password01" -AsPlainText -Force
$credDom = New-Object System.Management.Automation.PSCredential($userDom, $pass)
Invoke-Command -VMName ServerDM1 -AsJob -Credential $credDom -ScriptBlock { 
    cscript //B %windir%\system32\slmgr.vbs /ipk W3GNR-8DDXR-2TFRP-H8P33-DV9BG
    }
Invoke-Command -VMName ServerDM2 -AsJob -Credential $credDom -ScriptBlock { 
    cscript //B %windir%\system32\slmgr.vbs /ipk W3GNR-8DDXR-2TFRP-H8P33-DV9BG
    }
Invoke-Command -VMName ServerSA1 -AsJob -Credential $cred -ScriptBlock { 
    cscript //B %windir%\system32\slmgr.vbs /ipk W3GNR-8DDXR-2TFRP-H8P33-DV9BG
    }
Invoke-Command -VMName ServerDC1 -Credential $credDom -ScriptBlock { 
    cscript //B %windir%\system32\slmgr.vbs /ipk W3GNR-8DDXR-2TFRP-H8P33-DV9BG
    }
#endregion
