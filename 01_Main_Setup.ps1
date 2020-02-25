#######################################################################
#
# First script for building Hyper-V environment for IT 160
# Installs Hyper-V and preps for OS installs
#
#######################################################################

# Install Hyper-V and RRAS
Install-WindowsFeature Routing, Hyper-V, RSAT-RemoteAccess, RSAT-RemoteAccess-Mgmt -IncludeManagementTools
New-VMSwitch -SwitchType Internal -Name Internal
                
# Setup interfaces
Rename-NetAdapter -InterfaceAlias Ethernet -NewName Public

# Configure RRAS
Install-RemoteAccess -VpnType RoutingOnly

#Download Windows ISO
New-Item -ItemType Directory -Path c:\VMs -Force
$url = "https://software-download.microsoft.com/download/pr/Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
$output = "c:\VMs\Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
$start_time = Get-Date

Import-Module BitsTransfer
Start-BitsTransfer -Source $url -Destination $output
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

#Create VMs
new-VM -Name ServerDC1 -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\ServerDC1.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal
new-VM -Name ServerDM1 -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\ServerDM1.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal
new-VM -Name ServerDM2 -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\ServerDM2.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal
new-VM -Name ServerSA1 -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\ServerSA1.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal

# Setup memory
Get-VM | Set-VMMemory -DynamicMemoryEnabled $true


#Create additional HD
New-VHD -Path C:\VMs\ServerDM1_01.vhdx -SizeBytes 20GB
New-VHD -Path C:\VMs\ServerDM1_02.vhdx -SizeBytes 15GB
New-VHD -Path C:\VMs\ServerDM1_03.vhdx -SizeBytes 10GB
Add-VMHardDiskDrive -VMName ServerDM1 -Path C:\VMs\ServerDM1_01.vhdx
Add-VMHardDiskDrive -VMName ServerDM1 -Path C:\VMs\ServerDM1_02.vhdx
Add-VMHardDiskDrive -VMName ServerDM1 -Path C:\VMs\ServerDM1_03.vhdx
New-VHD -Path C:\VMs\ServerDM2_01.vhdx -SizeBytes 20GB
New-VHD -Path C:\VMs\ServerDM2_02.vhdx -SizeBytes 15GB
New-VHD -Path C:\VMs\ServerDM2_03.vhdx -SizeBytes 10GB
Add-VMHardDiskDrive -VMName ServerDM2 -Path C:\VMs\ServerDM2_01.vhdx
Add-VMHardDiskDrive -VMName ServerDM2 -Path C:\VMs\ServerDM2_02.vhdx
Add-VMHardDiskDrive -VMName ServerDM2 -Path C:\VMs\ServerDM2_03.vhdx
New-VHD -Path C:\VMs\ServerSA1_01.vhdx -SizeBytes 20GB
New-VHD -Path C:\VMs\ServerSA1_02.vhdx -SizeBytes 15GB
New-VHD -Path C:\VMs\ServerSA1_03.vhdx -SizeBytes 10GB
Add-VMHardDiskDrive -VMName ServerSA1 -Path C:\VMs\ServerSA1_01.vhdx
Add-VMHardDiskDrive -VMName ServerSA1 -Path C:\VMs\ServerSA1_02.vhdx
Add-VMHardDiskDrive -VMName ServerSA1 -Path C:\VMs\ServerSA1_03.vhdx

#Mount ISO
Set-VMDvdDrive -VMName ServerDC1 -Path c:\VMs\Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO
Set-VMDvdDrive -VMName ServerDM1 -Path c:\VMs\Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO
Set-VMDvdDrive -VMName ServerDM2 -Path c:\VMs\Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO
Set-VMDvdDrive -VMName ServerSA1 -Path c:\VMs\Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO

# Set all VMs to NOT autostart
Get-VM | Set-VM -AutomaticStartAction Nothing

# Set all VMs to shutdown at logoff
Get-VM | Set-VM -AutomaticStopAction Shutdown

# Set RDP idle logout (maybe???)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "MaxDisconnectionTime" -Value 600000 -Type "Dword"

# enable PING on firewall
netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow




#######################################################################
#
# Power on each VM and install the OS
# When finished, run the second script
#
#######################################################################

