#######################################################################
#
# First script for building Hyper-V environment for IT 460
# Installs Hyper-V and preps for OS installs
#
#######################################################################

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

# Setup Hyper-V defaults


#######################################################################
# automatic reboot here
#######################################################################


#######################################################################
# Install some common tools
#######################################################################
# Install 7-Zip
Install-7Zip
#$url = "https://www.7-zip.org/a/7z1900-x64.msi"
#$output = $(Join-Path $env:TEMP '/7zip.msi')
#(new-object System.Net.WebClient).DownloadFile($url, $output)
##Invoke-Process -FileName "msiexec.exe" -Arguments "/i $output /quiet"
#Start-Process $output -ArgumentList "/qn" -Wait

# Install Microsoft Virtual Machine Converter
$url = "https://download.microsoft.com/download/9/1/E/91E9F42C-3F1F-4AD9-92B7-8DD65DA3B0C2/mvmc_setup.msi"
$output = $(Join-Path $env:TEMP 'mvmc_setup.msi')
(new-object System.Net.WebClient).DownloadFile($url, $output)
#Invoke-Process -FileName "msiexec.exe" -Arguments "/i $output /quiet"
Start-Process $output -ArgumentList "/qn" -Wait

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
#Write-Host "Downloading Kali (this may take some time)"
#$url = "https://cdimage.kali.org/kali-2020.2/kali-linux-2020.2-installer-amd64.iso"
#$output = "c:\VMs\kali-linux-2020.2-installer-amd64.iso"
#(new-object System.Net.WebClient).DownloadFile($url, $output)

# Download Windows Server 2008 R2
#Write-Host "Downloading Windows Server 2008 R2 (this may take some time)"
# https://archive.org/download/windowsserver2008r2x64/Windows%20Server%202008%20R2%20x64.iso
# https://download.microsoft.com/download/7/5/E/75EC4E54-5B02-42D6-8879-D8D3A25FBEF7/7601.17514.101119-1850_x64fre_server_eval_en-us-GRMSXEVAL_EN_DVD.iso
#$url = "https://download.microsoft.com/download/7/5/E/75EC4E54-5B02-42D6-8879-D8D3A25FBEF7/7601.17514.101119-1850_x64fre_server_eval_en-us-GRMSXEVAL_EN_DVD.iso"
#$output = "c:\VMs\windowsserver2008r2x64.iso"
#(new-object System.Net.WebClient).DownloadFile($url, $output)

# Download Ubuntu 14.04
#Write-Host "Downloading Ubuntu 14.04 (this may take some time)"
#$url = "http://releases.ubuntu.com/trusty/ubuntu-14.04.6-desktop-amd64.iso"
#$output = "c:\VMs\ubuntu-14.04.6-desktop-amd64.iso"
#(new-object System.Net.WebClient).DownloadFile($url, $output)

# Download Metasploitable
Write-Host "Downloading Metasploitable (this may take some time)"
$url = "http://downloads.metasploit.com/data/metasploitable/metasploitable-linux-2.0.0.zip"
$output = "$env:TEMP\metasploitable-linux-2.0.0.zip"
(new-object System.Net.WebClient).DownloadFile($url, $output)


#Download Windows 10 ISO
#Write-Host "Downloading Windows 10 (this may take some time)"
#$url = "https://software-download.microsoft.com/download/pr/18363.418.191007-0143.19h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
#$output = "c:\VMs\Windows10.iso"
#(new-object System.Net.WebClient).DownloadFile($url, $output)


##############################################################################
# Setup VMs
##############################################################################
#Create New VMs
#new-VM -Name "Kali Linux" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\KaliLinux.vhdx -NewVHDSizeBytes 60GB -SwitchName private
#new-VM -Name "Windows 2008 R2" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\Win2008R2.vhdx -NewVHDSizeBytes 60GB -SwitchName private
#new-VM -Name "Ubuntu 14.04" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\Ubuntu1404.vhdx -NewVHDSizeBytes 60GB -SwitchName private
#new-VM -Name "Win10VM" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\Win10VM.vhdx -NewVHDSizeBytes 60GB -SwitchName private

#Mount ISO
#Set-VMDvdDrive -VMName "Kali Linux" -Path "c:\VMs\kali-linux-2020.2-installer-amd64.iso"
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
start-Process $swcExePath -ArgumentList "convert in_file_name=""$vmdkFile"" out_file_name=""$metasploitableHardDiskFilePath"" out_file_type=ft_vhdx_thin"

	# Import Metasploitable
Write-Host "Importing Metasploitable VM"
new-vm -Name "Metasploitable" -VHDPath $metasploitableHardDiskFilePath -MemoryStartupBytes 512MB
	# configure NIC
get-vm -Name "Metasploitable" | Add-VMNetworkAdapter -SwitchName "private" -IsLegacy $true


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
#Clear-TempFiles