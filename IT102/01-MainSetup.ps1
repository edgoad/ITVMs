#######################################################################
#
# First script for building Hyper-V environment for IT 102
# Installs Hyper-V and preps for OS installs
#
#######################################################################

# Ensure running in Windows PowerShell 5.1 Desktop edition
if ($PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSEdition -ne 'Desktop') {
    Write-Host "This script must be run in Windows PowerShell 5.1 (Desktop edition)." -ForegroundColor Yellow
    Write-Host "Please restart in PowerShell 5.1 and re-run the script." -ForegroundColor Yellow
    exit 1
}

Write-Host "Starting IT102 Hyper-V environment setup..."

# Change directory to %TEMP% for working
Write-Host "Switching working directory to TEMP..."
cd $env:TEMP

# Download and import CommonFunctions module
Write-Host "Loading common helper functions..."
$url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/Common/CommonFunctions.psm1"
$output = $(Join-Path $env:TEMP '/CommonFunctions.psm1')
if (-not(Test-Path -Path $output -PathType Leaf)) {
    (new-object System.Net.WebClient).DownloadFile($url, $output)
}
Import-Module $output
#Remove-Item $output

# Disable Server Manager at startup
Write-Host "Disabling Server Manager startup task..."
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose

# Disable Windows Updates
Write-Host "Disabling Windows Update service..."
Disable-WindowsUpdates

# Setup first interface
Write-Host "Configuring host network adapters..."
if ( $(Get-NetAdapter | Measure-Object).Count -eq 1 ){
    Write-Host "Setting Public adapter name"
    Get-NetAdapter | Rename-NetAdapter -NewName Public
}
else{
    Write-Host "Cannot set Public interface name. Confirm interfaces manually."
}

# Install Hyper-V
Write-Host "Installing Hyper-V role and tools..."
Install-HypervAndTools

# Create virtual swith
if ( ! (Get-VMSwitch | Where-Object Name -eq 'Internal')){
    Write-Host "Creating Internal vswitch"
    New-VMSwitch -SwitchType Internal -Name Internal
} else { Write-Host "Internal vSwitch already created" }

# Setup second interface
if (-not (Get-NetAdapter -Name 'Internal' -ErrorAction SilentlyContinue)) {
    Write-Host "Configuring Internal adapter"
    $internalAdapter = Get-NetAdapter | Where-Object Name -NE 'Public' | Select-Object -First 1
    if ($internalAdapter) {
        Rename-NetAdapter -Name $internalAdapter.Name -NewName Internal
    }
    else {
        Write-Host "No available adapter found to rename to Internal. Confirm interfaces manually."
    }
}
else {
    Write-Host "Internal adapter already exists."
}

$internalAdapter = Get-NetAdapter -Name 'Internal' -ErrorAction SilentlyContinue
if ($internalAdapter) {
    $internalIp = Get-NetIPAddress -InterfaceAlias 'Internal' -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object IPAddress -EQ '192.168.0.250'
    if (-not $internalIp) {
        Write-Host "Assigning Internal adapter IP address"
        New-NetIPAddress -InterfaceAlias 'Internal' -IPAddress 192.168.0.250 -PrefixLength 24
    }
    else {
        Write-Host "Internal adapter IP address already configured"
    }
}
else {
    Write-Host "Internal adapter not present; skipping IP assignment."
}

# Configure routing / NAT
Write-Host "Configuring NAT and routing for the internal lab network..."
if (-not (Get-NetNat -Name external_routing -ErrorAction SilentlyContinue)) {
    New-NetNat -Name external_routing -InternalIPInterfaceAddressPrefix 192.168.0.0/24
} else {
    Write-Host "NetNat 'external_routing' already exists."
}

#######################################################################
# Install some common tools
#######################################################################
Write-Host "Installing common host tools..."
# Install 7-Zip
Install-7Zip

# Configure logout after 10 minutes
Write-Host "Configuring automatic logout settings..."
Set-Autologout

#######################################################################
# Start setting up Hyper-V
#######################################################################
Write-Host "Applying Hyper-V host defaults..."
Set-HypervDefaults

# Download Ubuntu ISO
Write-Host "Downloading Ubuntu ISO (this may take some time)..."
$url = "https://releases.ubuntu.com/24.04/ubuntu-24.04.4-desktop-amd64.iso"
#$url = "https://releases.ubuntu.com/26.04/ubuntu-26.04-desktop-amd64.iso"
$output = "c:\VMs\ubuntu-desktop-amd64.iso"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Download seed ISO
Write-Host "Downloading seed ISO (this may take some time)..."
$url = "https://github.com/edgoad/ITVMs/raw/master/IT102/seed.iso"
$output = "c:\VMs\seed.iso"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Setup Hyper-V default file locations
Set-VMHost -VirtualHardDiskPath "C:\VMs"
Set-VMHost -VirtualMachinePath "C:\VMs"

##############################################################################
# Setup VMs
##############################################################################
#Create New VMs
Write-Host "Creating and configuring virtual machines..."
if ( ! (Get-VM | Where-Object Name -EQ "UbuntuVM")){
    Write-Host "Creating VM: UbuntuVM"
	new-VM -Name "UbuntuVM" -MemoryStartupBytes 8GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\UbuntuVM.vhdx" -NewVHDSizeBytes 100GB -SwitchName Internal -Generation 2
    Add-VMDvdDrive -VMName "UbuntuVM"
    $vmHardDiskDrive = Get-VMHardDiskDrive -VMName "UbuntuVM"
    $vmDVDDrive = Get-VMDvdDrive -VMName "UbuntuVM"
    Set-VMFirmware "UbuntuVM" -EnableSecureBoot Off -BootOrder $vmHardDiskDrive,$vmDVDDrive

    Set-VMDvdDrive $vmDVDDrive -Path "c:\VMs\ubuntu-desktop-amd64.iso"
    Add-VMDvdDrive -VMName "UbuntuVM" | Set-VMDvdDrive -Path "c:\VMs\seed.iso"
}
# if ( ! (Get-VM | Where-Object Name -EQ "UbuntuVM-Basic")){
#     Write-Host "Creating VM: UbuntuVM-Basic"
# 	new-VM -Name "UbuntuVM-Basic" -MemoryStartupBytes 8GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\UbuntuVM-Basic.vhdx" -NewVHDSizeBytes 100GB -SwitchName Internal -Generation 2
#     Add-VMDvdDrive -VMName "UbuntuVM-Basic"
#     $vmHardDiskDrive = Get-VMHardDiskDrive -VMName "UbuntuVM-Basic"
#     $vmDVDDrive = Get-VMDvdDrive -VMName "UbuntuVM-Basic"
#     Set-VMFirmware "UbuntuVM-Basic" -EnableSecureBoot Off -BootOrder $vmDVDDrive,$vmHardDiskDrive
# }

#Mount ISO
Write-Host "Mounting Ubuntu ISO into VMs..."
# Set-VMDvdDrive -VMName "UbuntuVM" -Path "c:\VMs\ubuntu-desktop-amd64.iso"
#Set-VMDvdDrive -VMName "UbuntuVM-Basic" -Path "c:\VMs\ubuntu-desktop-amd64.iso"

# Set all VMs to NOT autostart
Write-Host "Configuring VM startup behavior..."
Set-VM -VMName "UbuntuVM" -AutomaticStartAction Start

# Set all VMs to shutdown at logoff
Set-VM -VMName "UbuntuVM" -AutomaticStopAction Shutdown

# Set VMs to 2 processors for optimization
Write-Host "Applying VM processor settings..."
Set-VMProcessor -VMName "UbuntuVM" -Count 4

# setup bginfo
Write-Host "Applying desktop defaults and BGInfo setup..."
Set-DesktopDefaults

# Download logon information
Write-Host "Downloading student resource files..."
Write-Host "Downloading Logon Information"
$url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT102/Logon%20Information.txt"
$output = "c:\Users\Public\Desktop\Logon Information.txt"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Download Network Diagram
Write-Host "Downloading Network Diagram"
$url = "https://github.com/edgoad/ITVMs/raw/master/IT102/IT102.png"
$output = "c:\Users\Public\Desktop\Network Diagram.png"
Get-WebFile -DownloadUrl $url -TargetFilePath $output

# Download VM Rename script
Write-Host "Downloading rename script"
$url = "https://github.com/edgoad/ITVMs/raw/master/IT102/renamescript.ps1"
$output = "c:\Users\Public\renamescript.ps1"
Get-WebFile -DownloadUrl $url -TargetFilePath $output


#######################################################################
#
# Power on Template VM and install the OS
# Use Sysprep to generalize
# When finished, run the second script
#
#######################################################################
