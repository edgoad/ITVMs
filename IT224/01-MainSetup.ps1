#######################################################################
#
# First script for building Hyper-V environment for IT 224
# Installs Hyper-V and preps for OS installs
# Srv 2016 and Win10
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
$url = "https://software-static.download.prss.microsoft.com/sg/download/888969d5-f34g-4e03-ac9d-1f9786c66749/SERVER_EVAL_x64FRE_en-us.iso"
$output = "c:\VMs\W2k22.ISO"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

#Download Windows 11 ISO
New-Item -ItemType Directory -Path c:\VMs -Force
$url = "https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26100.1742.240906-0331.ge_release_svc_refresh_CLIENT_LTSC_EVAL_x64FRE_en-us.iso"
$output = "c:\VMs\Win11.ISO"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Setup Hyper-V default file locations
Set-VMHost -VirtualHardDiskPath "C:\VMs"
Set-VMHost -VirtualMachinePath "C:\VMs"

# Create DC1
new-VM -Name DC1 -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\DC1.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal -Generation 2
Add-VMDvdDrive -VMName DC1 -Path c:\VMs\W2k22.ISO

# Create DM1
new-VM -Name DM1 -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\DM1.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal -Generation 2
Add-VMDvdDrive -VMName DM1 -Path c:\VMs\W2k22.ISO

# Create SWS
new-VM -Name SWS -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\SWS.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal -Generation 2
Add-VMDvdDrive -VMName SWS -Path c:\VMs\Win11.ISO

# Set boot order of VMs
Get-VM | %{
    $vmDvd = Get-VMDvdDrive $_
    $vmHd = Get-VMHardDiskDrive $_
    $vmNic = Get-VMNetworkAdapter $_
    Set-VMFirmware $_ -BootOrder $vmHd, $vmDvd, $vmNic
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
$url = "https://github.com/edgoad/ITVMs/raw/master/IT224/IT224.png"
$output = "c:\Users\Public\Desktop\Network Diagram.png"
Get-WebFile -DownloadUrl $url -TargetFilePath $output


#########################################################
# Capture snapshot of VMs in uninstalled state 
#########################################################
Get-VM | Stop-VM 
Get-VM | Checkpoint-VM -SnapshotName "Initial snapshot" 


#########################################################
# Setup Rename of host
#########################################################
$command = 'powershell -Command "& { rename-computer -newname $( $( -join ((65..90) + (97..122) | Get-Random -Count 12 | %{[char]$_})) ).SubString(0,12) }"'
New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name "Rename" -Value $Command -PropertyType ExpandString
