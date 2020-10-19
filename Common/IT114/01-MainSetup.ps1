#######################################################################
#
# First script for building Hyper-V environment for IT 460
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

# Disable Server Manager at startup
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose

# Setup first interface
Get-NetAdapter | Rename-NetAdapter -NewName Public

# Install Hyper-V
Install-HypervAndTools

# Create virtual swith
New-VMSwitch -SwitchType Internal -Name Internal

# Setup second interface
Get-NetAdapter | where Name -NE 'Public' | Rename-NetAdapter -NewName Internal
New-NetIPAddress -InterfaceAlias 'Internal' -IPAddress 192.168.0.250 -PrefixLength 24

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
#Download Windows 10 ISO
Write-Host "Downloading Windows 10 (this may take some time)"
$url = "https://software-download.microsoft.com/download/pr/18363.418.191007-0143.19h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
$output = "c:\VMs\Windows10.iso"
(new-object System.Net.WebClient).DownloadFile($url, $output)

#Download Windows 7 ISO
Write-Host "Downloading Windows 7 (this may take some time)"
$url = "http://care.dlservice.microsoft.com/dl/download/evalx/win7/x64/EN/7600.16385.090713-1255_x64fre_enterprise_en-us_EVAL_Eval_Enterprise-GRMCENXEVAL_EN_DVD.iso"
$output = "c:\VMs\Windows7.iso"
(new-object System.Net.WebClient).DownloadFile($url, $output)

#Download Windows 8 ISO
Write-Host "Downloading Windows 8.1 (this may take some time)"
$url = "https://software-download.microsoft.com/pr/Win8.1_English_x64.iso"
$output = "c:\VMs\Windows81.iso"
(new-object System.Net.WebClient).DownloadFile($url, $output)


#Download Ubuntu ISO
Write-Host "Downloading Ubuntu 20.04 (this may take some time)"
$url = "https://releases.ubuntu.com/20.04/ubuntu-20.04.1-desktop-amd64.iso"
$output = "c:\VMs\ubuntu-20.04.1-desktop-amd64.iso"
(new-object System.Net.WebClient).DownloadFile($url, $output)


#Download Fedora ISO
Write-Host "Downloading Fedora 32 (this may take some time)"
$url = "https://download.fedoraproject.org/pub/fedora/linux/releases/32/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64-32-1.6.iso"
$output = "c:\VMs\Fedora-Workstation-Live-x86_64-32-1.6.iso"
(new-object System.Net.WebClient).DownloadFile($url, $output)

#Create New VMs
new-VM -Name "Kali Linux" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\KaliLinux.vhdx" -NewVHDSizeBytes 60GB -SwitchName Private
#Mount ISO
Set-VMDvdDrive -VMName "Kali Linux" -Path "c:\VMs\kali-linux-2020.2-installer-amd64.iso"



##############################################################################
# Configure VMs
##############################################################################
# Setup memory
Get-VM | Set-VMMemory -DynamicMemoryEnabled $true

# Set all VMs to NOT autostart
Get-VM | Set-VM -AutomaticStartAction Nothing

# Set all VMs to shutdown at logoff
Get-VM | Set-VM -AutomaticStopAction Shutdown

# setup bginfo
Set-DesktopDefaults

# Clean up temp files
# Clear-TempFiles

# Download logon information
Write-Host "Downloading Logon Information"
$url = "https://raw.githubusercontent.com/edgoad/ITVMs/master/IT460/Logon%20Information.txt"
$output = "c:\Users\Public\Desktop\Logon Information.txt"
(new-object System.Net.WebClient).DownloadFile($url, $output)


##############################################################################
# Final Messages
##############################################################################
Write-Host "\n\n##############################################################################"
Write-Host "# Initial setup complete, Install and configure OSs now"
Write-Host "# Then snapshot all VMs by running the following"
Write-Host" #     Get-VM | Stop-VM"
Write-Host "#     Get-VM | Checkpoint-VM -SnapshotName 'Initial snapshot'"
Write-Host "##############################################################################"

