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
if ( ! (Get-VMSwitch | Where-Object Name -eq 'MGMT')){
    Write-Host "Creating MGMT vswitch"
    New-VMSwitch -SwitchType Internal -Name MGMT
} else { Write-Host "MGMT vSwitch already created" }

# Setup second interface
if ( ! (Get-NetAdapter | Where-Object Name -EQ 'MGMT')){
    Write-Host "Configuring MGMT adapter"
    Get-NetAdapter | where Name -NE 'Public' | Rename-NetAdapter -NewName MGMT
    New-NetIPAddress -InterfaceAlias 'MGMT' -IPAddress 192.168.0.250 -PrefixLength 24
} else { Write-Host "MGMT adapter already exists. Confirm interfaces manually" }

# Configure routing / NAT
New-NetNat -Name external_routing_mgmt -InternalIPInterfaceAddressPrefix 192.168.0.0/24

# Create virtual swith
if ( ! (Get-VMSwitch | Where-Object Name -eq 'WAN')){
    Write-Host "Creating WAN vswitch"
    New-VMSwitch -SwitchType Internal -Name WAN
} else { Write-Host "WAN vSwitch already created" }

# Setup second interface
if ( ! (Get-NetAdapter | Where-Object Name -EQ 'WAN')){
    Write-Host "Configuring WAN adapter"
    Get-NetAdapter | where Name -NE 'Public' | where Name -NE 'MGMT' | Rename-NetAdapter -NewName WAN
    New-NetIPAddress -InterfaceAlias 'WAN' -IPAddress 203.0.113.65 -PrefixLength 27
} else { Write-Host "WAN adapter already exists. Confirm interfaces manually" }

# Configure routing / NAT
New-NetNat -Name external_routing_WAN -InternalIPInterfaceAddressPrefix 203.0.113.64/27

# Configure DHCP for MGMT network
#Set-InternalDHCPScope

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
New-Item -ItemType Directory -Path c:\VMs -Force
$url = "https://software-download.microsoft.com/download/pr/Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
$output = "c:\VMs\W2k2016.ISO"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Setup Hyper-V default file locations
Set-VMHost -VirtualHardDiskPath "C:\VMs\Virtual Hard Disks"
Set-VMHost -VirtualMachinePath "C:\VMs"

# Create Template VM
new-VM -Name Svr2016Template -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\Svr2016Template.vhdx" -NewVHDSizeBytes 60GB -SwitchName MGMT -Generation 2
Add-VMDvdDrive -VMName Svr2016Template -Path c:\VMs\W2k2016.ISO

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
