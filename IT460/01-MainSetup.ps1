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
#Install-WindowsFeature Hyper-V -IncludeManagementTools -Restart
Install-HypervAndTools

# Create virtual swith
New-VMSwitch -SwitchType Internal -Name Internal

# Setup second interface
Get-NetAdapter | where Name -NE 'Public' | Rename-NetAdapter -NewName Internal
New-NetIPAddress -InterfaceAlias 'Internal' -IPAddress 192.168.0.250 -PrefixLength 24

# Configure routing / NAT
New-NetNat -Name external_routing -InternalIPInterfaceAddressPrefix 192.168.0.0/24


#######################################################################
# automatic reboot here
#######################################################################


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
# Download Kali ISO
# Review URL for latest version
Write-Host "Downloading Kali (this may take some time)"
$url = "https://cdimage.kali.org/kali-2020.2/kali-linux-2020.2-installer-amd64.iso"
$output = "c:\VMs\kali-linux-2020.2-installer-amd64.iso"
(new-object System.Net.WebClient).DownloadFile($url, $output)

# Download DVWA
Write-Host "Downloading DVWA (this may take some time)"
$url = "http://www.dvwa.co.uk/DVWA-1.0.7.iso"
$output = "c:\VMs\DVWA-1.0.7.iso"
(new-object System.Net.WebClient).DownloadFile($url, $output)

# Download Windows Server 2008 R2
Write-Host "Downloading Windows Server 2008 R2 (this may take some time)"
# https://archive.org/download/windowsserver2008r2x64/Windows%20Server%202008%20R2%20x64.iso
# https://download.microsoft.com/download/7/5/E/75EC4E54-5B02-42D6-8879-D8D3A25FBEF7/7601.17514.101119-1850_x64fre_server_eval_en-us-GRMSXEVAL_EN_DVD.iso
$url = "https://download.microsoft.com/download/7/5/E/75EC4E54-5B02-42D6-8879-D8D3A25FBEF7/7601.17514.101119-1850_x64fre_server_eval_en-us-GRMSXEVAL_EN_DVD.iso"
$output = "c:\VMs\windowsserver2008r2x64.iso"
(new-object System.Net.WebClient).DownloadFile($url, $output)

# Download Ubuntu 14.04
Write-Host "Downloading Ubuntu 14.04 (this may take some time)"
$url = "http://releases.ubuntu.com/trusty/ubuntu-14.04.6-desktop-amd64.iso"
$output = "c:\VMs\ubuntu-14.04.6-desktop-amd64.iso"
(new-object System.Net.WebClient).DownloadFile($url, $output)

# Download Metasploitable
Write-Host "Downloading Metasploitable (this may take some time)"
$url = "http://downloads.metasploit.com/data/metasploitable/metasploitable-linux-2.0.0.zip"
$output = "$env:TEMP\metasploitable-linux-2.0.0.zip"
(new-object System.Net.WebClient).DownloadFile($url, $output)


#Download Windows 10 ISO
Write-Host "Downloading Windows 10 (this may take some time)"
$url = "https://software-download.microsoft.com/download/pr/18363.418.191007-0143.19h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
$output = "c:\VMs\Windows10.iso"
(new-object System.Net.WebClient).DownloadFile($url, $output)


##############################################################################
# Setup VMs
##############################################################################
#Create New VMs
new-VM -Name "Kali Linux" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\KaliLinux.vhdx" -NewVHDSizeBytes 60GB -SwitchName Private
new-VM -Name "Metasploitable 3" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\Ubuntu1404.vhdx" -NewVHDSizeBytes 60GB -SwitchName Private
#new-VM -Name "DVWA" -MemoryStartupBytes 512MB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\DVWA.vhdx" -NewVHDSizeBytes 60GB -SwitchName Private
#new-VM -Name "Windows 2008 R2" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\Win2008R2.vhdx" -NewVHDSizeBytes 60GB -SwitchName Private
#new-VM -Name "Ubuntu 14.04" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\Ubuntu1404.vhdx" -NewVHDSizeBytes 60GB -SwitchName Private
#new-VM -Name "Win10VM" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "C:\VMs\Virtual Hard Disks\Win10VM.vhdx" -NewVHDSizeBytes 60GB -SwitchName Private

#Create Second NIC
Add-VMNetworkAdapter -VMName "Kali Linux" -SwitchName Internal

#Mount ISO
Set-VMDvdDrive -VMName "Kali Linux" -Path "c:\VMs\kali-linux-2020.2-installer-amd64.iso"
Set-VMDvdDrive -VMName "Metasploitable 3" -Path "c:\VMs\ubuntu-14.04.6-desktop-amd64.iso"
#Set-VMDvdDrive -VMName "DVWA" -Path "c:\VMs\DVWA-1.0.7.iso"
#Set-VMDvdDrive -VMName "Windows 2008 R2" -Path "c:\VMs\windowsserver2008r2x64.iso"
#Set-VMDvdDrive -VMName "Ubuntu 14.04" -Path "c:\VMs\ubuntu-14.04.6-desktop-amd64.iso"
#Set-VMDvdDrive -VMName Win10VM -Path c:\VMs\Windows10.iso

# Extract, convert, and import Metasploitable
	# Extract
Write-Host "Extracting Metasploitable ZIP file"
$metasploitableZipFile = "$env:TEMP\metasploitable-linux-2.0.0.zip"
$metasploitableHardDiskFilePath = "c:\VMs\Virtual Hard Disks\Metasploitable.vhdx"
$swcExePath = Join-Path $env:ProgramFiles 'StarWind Software\StarWind V2V Converter\V2V_ConverterConsole.exe'
Expand-Archive $metasploitableZipFile -DestinationPath $env:TEMP
	# Convert Metasploitable
Write-Host "Converting Metasploitable image files to Hyper-V hard disk file.  Warning: This may take several minutes."
start-Process $swcExePath -ArgumentList "convert in_file_name=""$vmdkFile"" out_file_name=""$metasploitableHardDiskFilePath"" out_file_type=ft_vhdx_thin" -Wait

	# Import Metasploitable
Write-Host "Importing Metasploitable VM"
$vmdkFile = Get-ChildItem "$env:TEMP\*.vmdk" -Recurse | Select-Object -expand FullName
new-vm -Name "Metasploitable 2" -VHDPath $metasploitableHardDiskFilePath -MemoryStartupBytes 512MB
	# configure NIC
get-vm -Name "Metasploitable 2" | Add-VMNetworkAdapter -SwitchName "Private" -IsLegacy $true


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
Clear-TempFiles

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



#########################
# configuration notes
# metasploitable static IP instructions: https://www.howtoforge.com/community/threads/setting-static-ip-on-ubuntu-8-04-server.25277/
# DVWA requires internet access to setup, then back to Private
# Kali needs both Private and Internal networks