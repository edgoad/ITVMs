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
