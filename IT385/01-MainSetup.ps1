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
New-NetNat -Name external_routing -InternalIPInterfaceAddressPrefix 192.168.56.0/24

#######################################################################
# Install some common tools
#######################################################################
# Install 7-Zip
Install-7Zip

#Install starwind converter
Install-Starwind

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
#Write-Host "Downloading Fedora (this may take some time)"
#$url = "https://download.fedoraproject.org/pub/fedora/linux/releases/33/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64-33-1.2.iso"
#$output = "c:\VMs\Fedora-Workstation-Live-x86_64-33-1.2.iso"
#Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Download Ubuntu ISO
# Review URL for latest version
Write-Host "Downloading Ubuntu (this may take some time)"
#$url = "http://mirror.pit.teraswitch.com/ubuntu-releases/20.04.1/ubuntu-20.04.1-desktop-amd64.iso"
$url = "https://releases.ubuntu.com/20.04/ubuntu-20.04.1-desktop-amd64.iso"
$output = "c:\VMs\ubuntu-20.04.1-desktop-amd64.iso"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

#Download Windows ISO
New-Item -ItemType Directory -Path c:\VMs -Force
$url = "https://software-download.microsoft.com/download/pr/Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
$output = "c:\VMs\W2k2016.ISO"
Get-WebFile -DownloadUrl $url -TargetFilePath $output


##############################################################################
# Setup VMs
##############################################################################
#Create New VMs
#if ( ! (Get-VM | Where-Object Name -EQ "FedoraTemplate")){
#    Write-Host "Creating VM: FedoraTemplate"
#	new-VM -Name "FedoraTemplate" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\FedoraTemplate.vhdx" -NewVHDSizeBytes 100GB -SwitchName Internal
#}

if ( ! (Get-VM | Where-Object Name -EQ "UbuntuTemplate")){
    Write-Host "Creating VM: UbuntuTemplate"
	new-VM -Name "UbuntuTemplate" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\UbuntuTemplate.vhdx" -NewVHDSizeBytes 100GB -SwitchName Internal
}

if ( ! (Get-VM | Where-Object Name -EQ "CSR1")){
    Write-Host "Creating VM: CSR1"
    $VHD = New-VHD -Path "C:\VMs\Virtual Hard Disks\CSR1.vhd" -SizeBytes 10GB
	New-VM -Name "CSR1" -MemoryStartupBytes 2560MB -BootDevice VHD -VHDPath $VHD.Path -SwitchName Internal
}
if ( ! (Get-VM | Where-Object Name -EQ "CSR2")){
    Write-Host "Creating VM: CSR2"
    $VHD = New-VHD -Path "C:\VMs\Virtual Hard Disks\CSR2.vhd" -SizeBytes 10GB
	New-VM -Name "CSR2" -MemoryStartupBytes 2560MB -BootDevice VHD -VHDPath $VHD.Path -SwitchName Internal
}

if ( ! (Get-VM | Where-Object Name -EQ "Server2016")){
    Write-Host "Creating VM: Server2016"
	new-VM -Name "Server2016" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\Server2016.vhdx" -NewVHDSizeBytes 100GB -SwitchName Internal
}

#Mount ISO
#Set-VMDvdDrive -VMName "FedoraTemplate" -Path "c:\VMs\Fedora-Workstation-Live-x86_64-33-1.2.iso"
Set-VMDvdDrive -VMName "UbuntuTemplate" -Path "c:\VMs\ubuntu-20.04.1-desktop-amd64.iso"
Set-VMDvdDrive -VMName "CSR1" -Path "c:\VMs\csr1000v-universalk9.03.11.02.S.154-1.S2-std.iso"
Set-VMDvdDrive -VMName "CSR2" -Path "c:\VMs\csr1000v-universalk9.03.11.02.S.154-1.S2-std.iso"
Set-VMDvdDrive -VMName "Server2016" -Path "c:\VMs\W2k2016.iso"
#Set-VMDvdDrive -VMName "CSR1" -Path "c:\VMs\csr1000v-universalk9.16.12.04a.iso"
#Set-VMDvdDrive -VMName "CSR2" -Path "c:\VMs\csr1000v-universalk9.16.12.04a.iso"

# Add additional NICs
Add-VMNetworkAdapter -VMName CSR1
Add-VMNetworkAdapter -VMName CSR1
Add-VMNetworkAdapter -VMName CSR2
Add-VMNetworkAdapter -VMName CSR2

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
