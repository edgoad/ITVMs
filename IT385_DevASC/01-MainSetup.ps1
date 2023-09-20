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

# Download devasc-sa.py
New-Item -Path "c:\Users\Public\Desktop\LabFiles" -ItemType Directory
Write-Host "Downloading devasc-sa.py"
$url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT385_DevASC/devasc-sa.py"
$output = "c:\Users\Public\Desktop\LabFiles\devasc-sa.py"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Download logon information
#Write-Host "Downloading Logon Information"
#$url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT385_DevASC/Logon%20Information.txt"
#$output = "c:\Users\Public\Desktop\Logon Information.txt"
#Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Rename VM after reboot
Add-RenameAfterReboot
