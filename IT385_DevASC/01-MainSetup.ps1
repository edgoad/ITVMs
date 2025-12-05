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
#Remove-Item $output

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
    New-NetIPAddress -InterfaceAlias 'Internal' -IPAddress 192.168.56.1 -PrefixLength 24
} else { Write-Host "Internal adapter already exists. Confirm interfaces manually" }

# Configure routing / NAT
New-NetNat -Name external_routing -InternalIPInterfaceAddressPrefix 192.168.56.0/24

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

# Configure DHCP for internal network
Set-InternalDHCPScope_DevASC

# Download Ubuntu ISO
# Review URL for latest version
Write-Host "Downloading Ubuntu (this may take some time)"
$url = "https://releases.ubuntu.com/24.04.3/ubuntu-24.04.3-desktop-amd64.iso"
$output = "c:\VMs\ubuntu-desktop-amd64.iso"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Setup Hyper-V default file locations
Set-VMHost -VirtualHardDiskPath "C:\VMs"
Set-VMHost -VirtualMachinePath "C:\VMs"

##############################################################################
# Setup VMs
##############################################################################
#Create New VMs
if ( ! (Get-VM | Where-Object Name -EQ "DEVASC_VM")){
    Write-Host "Creating VM: DEVASC_VM"
	new-VM -Name "DEVASC_VM" -MemoryStartupBytes 7GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\DEVASC_VM.vhdx" -NewVHDSizeBytes 100GB -SwitchName Internal -Generation 2
    Set-VMFirmware "DEVASC_VM" -EnableSecureBoot Off
}
if ( ! (Get-VM | Where-Object Name -EQ "CSR1000v")){
    Write-Host "Creating VM: CSR1000v"
    New-VHD -Path "C:\VMs\Virtual Hard Disks\CSR1000v.vhd" -SizeBytes 8GB  -Fixed
	New-VM -VHDPath "C:\VMs\Virtual Hard Disks\CSR1000v.vhd" -Generation 1 -MemoryStartupBytes 4GB -Name CSR1000v -SwitchName Internal
}


#Mount ISO
Set-VMDvdDrive -VMName "DEVASC_VM" -Path "c:\VMs\ubuntu-desktop-amd64.iso"

# Set all VMs to autostart at boot
Get-VM | Set-VM -AutomaticStartAction Start

# Set all VMs to shutdown at logoff
Get-VM | Set-VM -AutomaticStopAction Shutdown

# Set VMs to 2 processors for optimization
Get-VM | Set-VMProcessor -Count 4


# Download devasc-sa.py
# New-Item -Path "c:\Users\Public\Desktop\LabFiles" -ItemType Directory
# Write-Host "Downloading devasc-sa.py"
# $url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT385_DevASC/devasc-sa.py"
# $output = "c:\Users\Public\Desktop\LabFiles\devasc-sa.py"
# Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Download logon information
#Write-Host "Downloading Logon Information"
#$url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT385_DevASC/Logon%20Information.txt"
#$output = "c:\Users\Public\Desktop\Logon Information.txt"
#Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Rename VM after reboot
Add-RenameAfterReboot
