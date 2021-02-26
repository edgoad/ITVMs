#######################################################################
#
# First script for building Hyper-V environment for IT 160
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
if ( ! (Get-VMSwitch | Where-Object Name -eq 'Internal')){
    Write-Host "Creating Internal vswitch"
    New-VMSwitch -SwitchType Internal -Name Internal
} else { Write-Host "Internal vSwitch already created" }

# Setup second interface
if ( ! (Get-NetAdapter | Where-Object Name -EQ 'Internal')){
    Write-Host "Configuring Internal adapter"
    Get-NetAdapter | where Name -NE 'Public' | Rename-NetAdapter -NewName Internal
    New-NetIPAddress -InterfaceAlias 'Internal' -IPAddress 192.168.0.250 -PrefixLength 24
} else { Write-Host "Internal adapter already exists. Confirm interfaces manually" }

# Configure routing / NAT
New-NetNat -Name external_routing -InternalIPInterfaceAddressPrefix 192.168.0.0/24

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
Set-VMHost -VirtualHardDiskPath "C:\VMs"
Set-VMHost -VirtualMachinePath "C:\VMs"

# Create Template VM
new-VM -Name Svr2016Template -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\Svr2016Template.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal
Set-VMDvdDrive -VMName Svr2016Template -Path c:\VMs\W2k2016.ISO

# Create Template VM
new-VM -Name ServerDM2 -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\ServerDM2.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal
Set-VMDvdDrive -VMName ServerDM2 -Path c:\VMs\W2k2016.ISO

# Set all VMs to NOT autostart
Get-VM | Set-VM -AutomaticStartAction Nothing

# Set all VMs to shutdown at logoff
Get-VM | Set-VM -AutomaticStopAction Shutdown

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
