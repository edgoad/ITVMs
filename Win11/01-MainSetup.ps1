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

# Configure DHCP for internal network
Set-InternalDHCPScope -InterfaceAlias internal -IPAddress 192.168.0.250 -StartRange 192.168.0.100 -EndRange 192.168.0.200 -SubnetMask 255.255.255.0 -DNSServer 8.8.8.8 -ScopeName "Internal Network" -ScopeDescription "DHCP Scope for Internal Network"

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

#Download Windows 11 ISO
New-Item -ItemType Directory -Path c:\VMs -Force
$url = "https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26100.1742.240906-0331.ge_release_svc_refresh_CLIENT_LTSC_EVAL_x64FRE_en-us.iso"
$url = "https://software.download.prss.microsoft.com/dbazure/Win11_25H2_English_x64.iso?t=72c32885-084c-449a-9892-c2a809d1ba37&P1=1768336761&P2=601&P3=2&P4=zP4D7badrMM2%2ff6tFjvwKhbwp%2baeGC6J%2b7J14k3ASjF5h7Ej6nm9kz%2frIs6%2bvNmrw3blZFs%2fgXXX7f1Z7CBU2IIiKJhVtjTaJxnsazllde%2bQAftv43NPfdJaxFOYOiuuHzPQddTveSmTFrWE3tbsyiWINFc1ta1lAdCeVo7QgZqyjFVlu48sKQFd0KmyJ8TXcE6EQlEUshUpQQCJ1Kuf0ooptc04x5R4E8dxoSRLopBk6O7Vzl%2f86aCy3C0B%2bcgGPciDu%2bjG%2fu6XH%2buw3up0eE%2fjUOEkEYB39O5YsV5oCJM8wdGz97JgEtvRP7VAMh4iCjJAMBTktvxc5e%2bwh3Hj4g%3d%3d"
$output = "c:\VMs\Win11.ISO"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Setup Hyper-V default file locations
Set-VMHost -VirtualHardDiskPath "C:\VMs"
Set-VMHost -VirtualMachinePath "C:\VMs"
# Create VMs
# Create SWS
new-VM -Name SWS -MemoryStartupBytes 8GB -BootDevice VHD -NewVHDPath C:\VMs\SWS.vhdx -NewVHDSizeBytes 60GB -SwitchName Internal -Generation 2
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
Get-VM | Set-VMProcessor -Count 4

# setup bginfo
Set-DesktopDefaults

# Download Network Diagram
# Write-Host "Downloading Network Diagram"
# $url = "https://github.com/edgoad/ITVMs/raw/master/IT224/IT224.png"
# $output = "c:\Users\Public\Desktop\Network Diagram.png"
# Get-WebFile -DownloadUrl $url -TargetFilePath $output


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
