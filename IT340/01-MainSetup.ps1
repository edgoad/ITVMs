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
    New-NetIPAddress -InterfaceAlias 'internal' -IPAddress 10.99.0.250 -PrefixLength 24
} else { Write-Host "internal adapter already exists. Confirm interfaces manually" }

# Configure routing / NAT
New-NetNat -Name external_routing_internal -InternalIPInterfaceAddressPrefix 10.99.0.0/24

# Create virtual switchs
if ( ! (Get-VMSwitch | Where-Object Name -eq 'LAN_1')){
    Write-Host "Creating LAN_1 vswitch"
    New-VMSwitch -SwitchType Internal -Name LAN_1
} else { Write-Host "LAN_1 vSwitch already created" }
if ( ! (Get-NetAdapter | Where-Object Name -EQ 'LAN_1')){
    Write-Host "Configuring LAN_1 adapter"
    Get-NetAdapter | where Name -NE 'Public' | Rename-NetAdapter -NewName LAN_1
    New-NetIPAddress -InterfaceAlias 'LAN_1' -IPAddress 192.168.10.10 -PrefixLength 24
} else { Write-Host "LAN_1 adapter already exists. Confirm interfaces manually" }

if ( ! (Get-VMSwitch | Where-Object Name -eq 'LAN_2')){
    Write-Host "Creating LAN_2 vswitch"
    New-VMSwitch -SwitchType Internal -Name LAN_2
} else { Write-Host "LAN_2 vSwitch already created" }
if ( ! (Get-NetAdapter | Where-Object Name -EQ 'LAN_2')){
    Write-Host "Configuring LAN_2 adapter"
    Get-NetAdapter | where Name -NE 'Public' | Rename-NetAdapter -NewName LAN_2
    New-NetIPAddress -InterfaceAlias 'LAN_2' -IPAddress 192.168.20.10 -PrefixLength 24
} else { Write-Host "LAN_2 adapter already exists. Confirm interfaces manually" }




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

#Download Ubuntu ISO
Write-Host "Downloading Ubuntu (this may take some time)"
$url = "https://releases.ubuntu.com/24.04.3/ubuntu-24.04.3-desktop-amd64.iso"
$output = "c:\VMs\ubuntu-desktop-amd64.iso"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

#Download OPNsense ISO
Write-Host "Downloading OPNsense (this may take some time)"
$url = "https://pkg.opnsense.org/releases/25.7/OPNsense-25.7-dvd-amd64.iso.bz2"
$output = "c:\VMs\OPNsense-25.7-dvd-amd64.iso.bz2"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

# extract OPNsense ISO
Write-Host "Extracting OPNsense ISO"
$sourceFile = "c:\VMs\OPNsense-25.7-dvd-amd64.iso.bz2"
$destinationFolder = "C:\VMs"
# Path to 7-Zip executable (adjust if installed elsewhere)
$sevenZipPath = "C:\Program Files\7-Zip\7z.exe"
# Extract the .bz2 file
& $sevenZipPath x $sourceFile "-o$destinationFolder"


# Setup Hyper-V default file locations
Set-VMHost -VirtualHardDiskPath "C:\VMs\Virtual Hard Disks"
Set-VMHost -VirtualMachinePath "C:\VMs"

#Create New VMs
if ( ! (Get-VM | Where-Object Name -EQ "DesktopA")){
    Write-Host "Creating VM: DesktopA"
	new-VM -Name "DesktopA" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\DesktopA.vhdx" -NewVHDSizeBytes 20GB -SwitchName LAN_1 -Generation 2
    Set-VMFirmware "DesktopA" -EnableSecureBoot Off
    Add-VMDvdDrive -VMName "DesktopA" -Path "c:\VMs\ubuntu-desktop-amd64.iso"
}
if ( ! (Get-VM | Where-Object Name -EQ "DesktopB")){
    Write-Host "Creating VM: DesktopB"
	new-VM -Name "DesktopB" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\DesktopB.vhdx" -NewVHDSizeBytes 20GB -SwitchName LAN_1 -Generation 2
    Set-VMFirmware "DesktopB" -EnableSecureBoot Off
    Add-VMDvdDrive -VMName "DesktopB" -Path "c:\VMs\ubuntu-desktop-amd64.iso"
}
if ( ! (Get-VM | Where-Object Name -EQ "Firewall1")){
    Write-Host "Creating VM: Firewall1"
	new-VM -Name "Firewall1" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\Firewall1.vhdx" -NewVHDSizeBytes 20GB -SwitchName Internal -Generation 2
    Set-VMFirmware "Firewall1" -EnableSecureBoot Off
    Add-VMDvdDrive -VMName "Firewall1" -Path "c:\VMs\OPNsense-25.7-dvd-amd64.iso"
}
if ( ! (Get-VM | Where-Object Name -EQ "Firewall2")){
    Write-Host "Creating VM: Firewall2"
	new-VM -Name "Firewall2" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\Firewall2.vhdx" -NewVHDSizeBytes 20GB -SwitchName Internal -Generation 2
    Set-VMFirmware "Firewall2" -EnableSecureBoot Off
    Add-VMDvdDrive -VMName "Firewall2" -Path "c:\VMs\OPNsense-25.7-dvd-amd64.iso"
    Add-VMNetworkAdapter -VMName "Firewall2" -SwitchName "LAN_2" -Name "LAN_2"
}

# Set all VMs to NOT autostart
Get-VM | Set-VM -AutomaticStartAction Nothing

# Set all VMs to shutdown at logoff
Get-VM | Set-VM -AutomaticStopAction Shutdown

# Set VMs to 2 processors for optimization
Get-VM | Set-VMProcessor -Count 2
Get-VM | Set-VMMemory -DynamicMemoryEnabled $true -StartupBytes 2048MB -MinimumBytes 2048MB -MaximumBytes 3072MB

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
