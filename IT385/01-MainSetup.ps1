#######################################################################
#
# First script for building Hyper-V environment for IT 385
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
Remove-Item $output

# setup bginfo
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

##############################################################################
# Download ISO files for installation
##############################################################################
# Download Fedora ISO
# Review URL for latest version
Write-Host "Downloading Fedora (this may take some time)"
$url = "https://download.fedoraproject.org/pub/fedora/linux/releases/33/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64-33-1.2.iso"
$output = "c:\VMs\Fedora-Workstation-Live-x86_64-33-1.2.iso"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

##############################################################################
# Setup VMs
##############################################################################
#Create New VMs
if ( ! (Get-VM | Where-Object Name -EQ "FedoraTemplate")){
    Write-Host "Creating VM: FedoraTemplate"
	new-VM -Name "FedoraTemplate" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\FedoraTemplate.vhdx" -NewVHDSizeBytes 100GB -SwitchName Internal
}
if ( ! (Get-VM | Where-Object Name -EQ "CSRTemplate")){
    Write-Host "Creating VM: CSRTemplate"
	new-VM -Name "CSRTemplate" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\CSRTemplate.vhdx" -NewVHDSizeBytes 100GB -SwitchName Internal
}

#Mount ISO
Set-VMDvdDrive -VMName "FedoraTemplate" -Path "c:\VMs\Fedora-Workstation-Live-x86_64-33-1.2.iso"
Set-VMDvdDrive -VMName "CSRTemplate" -Path "c:\VMs\csr1000v-universalk9.16.12.04a.iso"

##############################################################################
# Configure VMs
##############################################################################
# Set all VMs to NOT autostart
Get-VM | Set-VM -AutomaticStartAction Nothing

# Set all VMs to shutdown at logoff
Get-VM | Set-VM -AutomaticStopAction Shutdown


# Clean up temp files
# Clear-TempFiles

# Download logon information
Write-Host "Downloading Logon Information"
$url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT385/Logon%20Information.txt"
$output = "c:\Users\Public\Desktop\Logon Information.txt"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Download Network Diagram
Write-Host "Downloading Network Diagram"
$url = "https://github.com/edgoad/ITVMs/raw/master/IT385/IT385.png"
$output = "c:\Users\Public\Desktop\Network Diagram.png"
Get-WebFile -DownloadUrl $url -TargetFilePath $output



#######################################################################
#
# Power on Template VM and install the OS
# Use Sysprep to generalize
# When finished, run the second script
#
#######################################################################
