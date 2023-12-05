#######################################################################
#
# First script for building Hyper-V environment for IT 160
# Installs Hyper-V and preps for OS installs
#
#######################################################################

# Change directory to %TEMP% for working
cd $env:TEMP

# Dowload and import CommonFunctions module
$url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/Common/CommonFunctions.psm1"
$output = $(Join-Path $env:TEMP '/CommonFunctions.psm1')
(new-object System.Net.WebClient).DownloadFile($url, $output)
Import-Module $output
#Remove-Item $output

# Disable Server Manager at startup
Set-DesktopDefaults

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
if ( ! (Get-VMSwitch | Where-Object Name -eq 'Internal')){
    Write-Host "Creating Internal vswitch"
    New-VMSwitch -SwitchType Internal -Name Internal
} else { Write-Host "Internal vSwitch already created" }

# Setup second interface
if ( ! (Get-NetAdapter | Where-Object Name -EQ 'Internal')){
    Write-Host "Configuring Internal adapter"
    Get-NetAdapter | where Name -NE 'Public' | Rename-NetAdapter -NewName Internal
    New-NetIPAddress -InterfaceAlias 'Internal' -IPAddress 10.99.0.250 -PrefixLength 24
} else { Write-Host "Internal adapter already exists. Confirm interfaces manually" }

# Configure routing / NAT
New-NetNat -Name external_routing -InternalIPInterfaceAddressPrefix 10.99.0.0/24

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

# Setup Hyper-V default file locations
New-Item -ItemType Directory -Path c:\BaseVMs -Force
Set-VMHost -VirtualHardDiskPath "c:\BaseVMs"
Set-VMHost -VirtualMachinePath "c:\BaseVMs"

#Download Windows ISO
New-Item -ItemType Directory -Path c:\BaseVMs -Force
$url = "https://software-static.download.prss.microsoft.com/sg/download/888969d5-f34g-4e03-ac9d-1f9786c66749/SERVER_EVAL_x64FRE_en-us.iso"
$output = "c:\BaseVMs\W2k2022.ISO"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Create Template VM
new-VM -Name Svr2022Template -MemoryStartupBytes 4GB -BootDevice VHD -NewVHDPath c:\BaseVMs\Svr2022Template.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal -Generation 2
Add-VMDvdDrive -VMName Svr2022Template -Path c:\BaseVMs\W2k2022.ISO
#Set-VMDvdDrive -VMName Svr2022Template -Path c:\BaseVMs\W2k2022.ISO

# Create Template VM
new-VM -Name ServerDM2 -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath c:\BaseVMs\ServerDM2.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal -Generation 2
Add-VMDvdDrive -VMName ServerDM2 -Path c:\BaseVMs\W2k2022.ISO

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
$url = "https://github.com/edgoad/ITVMs/raw/master/IT160/IT160.png"
$output = "c:\Users\Public\Desktop\Network Diagram.png"
Get-WebFile -DownloadUrl $url -TargetFilePath $output


#######################################################################
#
# Power on Template VM and install the OS
# Use Sysprep to generalize
# When finished, run the second script
#
#######################################################################
