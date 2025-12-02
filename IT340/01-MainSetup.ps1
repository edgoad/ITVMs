#######################################################################
#
# First script for building Hyper-V environment for IT 340
# Installs Hyper-V and preps for OS installs
#
#######################################################################

# Change directory to %TEMP% for working
cd $env:TEMP

# Download and import CommonFunctions module
$url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/Common/CommonFunctions.psm1"
$output = $(Join-Path $env:TEMP '/CommonFunctions.psm1')
if (-not(Test-Path -Path $output -PathType Leaf)) {
    (new-object System.Net.WebClient).DownloadFile($url, $output)
}
Import-Module $output
#Remove-Item $output

# Disable Server Manager at startup
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose

# Setup first interface
if ( $(Get-NetAdapter | Measure-Object).Count -eq 1 ){
    Write-Host "Setting Public adapter name"
    Get-NetAdapter | Rename-NetAdapter -NewName Public
}
else{
    Write-Host "Cannot set Public interface name. Confirm interfaces manually."
}
# Install Hyper-V
Install-HypervAndTools

# Create virtual swith
if ( ! (Get-VMSwitch | Where-Object Name -eq 'internal')){
    Write-Host "Creating internal vswitch"
    New-VMSwitch -SwitchType Internal -Name internal
} else { Write-Host "internal vSwitch already created" }

# Setup second interface
if ( ! (Get-NetAdapter | Where-Object Name -EQ 'internal')){
    Write-Host "Configuring internal adapter"
    Get-NetAdapter | where Name -NE 'Public' | Rename-NetAdapter -NewName internal
    New-NetIPAddress -InterfaceAlias 'internal' -IPAddress 10.99.0250 -PrefixLength 24
} else { Write-Host "internal adapter already exists. Confirm interfaces manually" }

# Configure routing / NAT
New-NetNat -Name external_routing_internal -InternalIPInterfaceAddressPrefix 10.99.00/24

# Create virtual swith Internal1
if ( ! (Get-VMSwitch | Where-Object Name -eq 'Internal1')){
    Write-Host "Creating Internal1 vswitch"
    New-VMSwitch -SwitchType Internal -Name Internal1
} else { Write-Host "Internal1 vSwitch already created" }
if ( ! (Get-VMSwitch | Where-Object Name -eq 'Internal2')){
    Write-Host "Creating Internal2 vswitch"
    New-VMSwitch -SwitchType Internal -Name Internal2
} else { Write-Host "Internal2 vSwitch already created" }




# Configure DHCP for internal network
Set-InternalDHCPScope -InterfaceAlias internal -StartRange 10.99.0.100 -EndRange 10.99.0.200 -SubnetMask 255.255.255.0 -DNSServer 8.8.8.8 -ScopeName "Internal Network" -ScopeDescription "DHCP Scope for Internal Network"

#######################################################################
# Install some common tools
#######################################################################
# Install 7-Zip
Install-7Zip

# Configure logout after 10 minutes
Set-Autologout

#######################################################################
# Start setting up Hyper-V
#######################################################################
Set-HypervDefaults

#Download Windows ISO
Write-Host "Downloading Ubuntu (this may take some time)"
$url = "https://releases.ubuntu.com/24.04.3/ubuntu-24.04.3-desktop-amd64.iso"
$output = "c:\VMs\ubuntu-desktop-amd64.iso"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

Write-Host "Downloading pfSense (this may take some time)"
$url = "https://atxfiles.netgate.com/mirror/downloads/pfSense-CE-2.7.2-RELEASE-amd64.iso.gz"
$output = "c:\VMs\pfSense-CE-2.7.2-RELEASE-amd64.iso.gz"
Get-WebFile -DownloadUrl $url -TargetFilePath $output


# Setup Hyper-V default file locations
Set-VMHost -VirtualHardDiskPath "C:\VMs\Virtual Hard Disks"
Set-VMHost -VirtualMachinePath "C:\VMs"

#Create New VMs
if ( ! (Get-VM | Where-Object Name -EQ "DesktopA")){
    Write-Host "Creating VM: DesktopA"
	new-VM -Name "DesktopA" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\DesktopA.vhdx" -NewVHDSizeBytes 100GB -SwitchName Internal1 -Generation 2
    Set-VMFirmware "DesktopA" -EnableSecureBoot Off
    Set-VMDvdDrive -VMName "DesktopA" -Path "c:\VMs\ubuntu-desktop-amd64.iso"
}
if ( ! (Get-VM | Where-Object Name -EQ "DesktopB")){
    Write-Host "Creating VM: DesktopB"
	new-VM -Name "DesktopB" -MemoryStartupBytes 24GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\DesktopB.vhdx" -NewVHDSizeBytes 100GB -SwitchName Internal1 -Generation 2
    Set-VMFirmware "DesktopB" -EnableSecureBoot Off
    Set-VMDvdDrive -VMName "DesktopB" -Path "c:\VMs\ubuntu-desktop-amd64.iso"
}
if ( ! (Get-VM | Where-Object Name -EQ "Firewall1")){
    Write-Host "Creating VM: Firewall1"
	new-VM -Name "Firewall1" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\Firewall1.vhdx" -NewVHDSizeBytes 100GB -SwitchName Internal -Generation 2
    Set-VMFirmware "Firewall1" -EnableSecureBoot Off
    Set-VMDvdDrive -VMName "Firewall1" -Path "c:\VMs\ubuntu-desktop-amd64.iso"
    Add-VMNetworkAdapter -VMName "Firewall1" -SwitchName "Internal1" -Name "LAN"
}
if ( ! (Get-VM | Where-Object Name -EQ "Firewall2")){
    Write-Host "Creating VM: Firewall2"
	new-VM -Name "Firewall2" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\Firewall2.vhdx" -NewVHDSizeBytes 100GB -SwitchName Internal -Generation 2
    Set-VMFirmware "Firewall2" -EnableSecureBoot Off
    Set-VMDvdDrive -VMName "Firewall2" -Path "c:\VMs\ubuntu-desktop-amd64.iso"
    Add-VMNetworkAdapter -VMName "Firewall2" -SwitchName "Internal2" -Name "LAN"
}

# Set all VMs to NOT autostart
Get-VM | Set-VM -AutomaticStartAction Nothing

# Set all VMs to shutdown at logoff
Get-VM | Set-VM -AutomaticStopAction Shutdown

# Set VMs to 2 processors for optimization
Get-VM | Set-VMProcessor -Count 2

# setup bginfo
Set-DesktopDefaults

# Download Network Diagram
Write-Host "Downloading Network Diagram"
$url = "https://github.com/edgoad/ITVMs/raw/master/IT340/IT340.png"
$output = "c:\Users\Public\Desktop\Network Diagram.png"
Get-WebFile -DownloadUrl $url -TargetFilePath $output


#######################################################################
#
# Power on Template VM and install the OS
# Use Sysprep to generalize
# When finished, run the second script
#
#######################################################################
