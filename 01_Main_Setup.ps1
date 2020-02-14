# Install Hyper-V and RRAS
Install-WindowsFeature Routing, Hyper-V -IncludeManagementTools
New-VMSwitch -SwitchType Internal -Name Internal
New-VMSwitch -SwitchType Private -Name Private

# Setup interfaces
Rename-NetAdapter -InterfaceAlias Ethernet -NewName Public
New-NetIPAddress -InterfaceAlias 'vEthernet (Internal)' -IPAddress 192.168.0.250 -PrefixLength 24
Rename-NetAdapter -InterfaceAlias 'vEthernet (Internal)' -NewName Internal

# Configure RRAS
Install-RemoteAccess -VpnType Vpn
$ExternalInterface='Public'
$InternalInterface='Internal'
 
cmd.exe /c "netsh routing ip nat install"
cmd.exe /c "netsh routing ip nat add interface $ExternalInterface"
cmd.exe /c "netsh routing ip nat set interface $ExternalInterface mode=full"
cmd.exe /c "netsh routing ip nat add interface $InternalInterface"


#Download Windows ISO
New-Item -ItemType Directory -Path c:\VMs -Force
$url = "https://software-download.microsoft.com/download/pr/Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
$output = "c:\VMs\Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
$start_time = Get-Date

Import-Module BitsTransfer
Start-BitsTransfer -Source $url -Destination $output
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

#Create VMs
new-VM -Name ServerDC1 -MemoryStartupBytes 3GB -BootDevice VHD -NewVHDPath C:\VMs\ServerDC1.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal
new-VM -Name ServerDM1 -MemoryStartupBytes 3GB -BootDevice VHD -NewVHDPath C:\VMs\ServerDM1.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal
new-VM -Name ServerDM2 -MemoryStartupBytes 3GB -BootDevice VHD -NewVHDPath C:\VMs\ServerDM2.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal
new-VM -Name ServerSA1 -MemoryStartupBytes 3GB -BootDevice VHD -NewVHDPath C:\VMs\ServerSA1.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal

# Setup memory
Get-VM | Set-VMMemory -DynamicMemoryEnabled $true

#Create Second NIC
Add-VMNetworkAdapter -VMName ServerDC1 -SwitchName Private
Add-VMNetworkAdapter -VMName ServerDM1 -SwitchName Private
Add-VMNetworkAdapter -VMName ServerDM2 -SwitchName Private
Add-VMNetworkAdapter -VMName ServerSA1 -SwitchName Private

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
#hyper-v\Get-VM | hyper-v\Set-VM -AutomaticStartAction Nothing
Get-VM | Set-VM -AutomaticStartAction Nothing

# Set RDP idle logout (maybe???)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "MaxDisconnectionTime" -Value 600000 -Type "Dword"
