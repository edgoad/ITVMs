#######################################################################
#
# First script for building Hyper-V environment for IT 460
# Installs Hyper-V and preps for OS installs
#
#######################################################################

# Disable Server Manager at startup
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose

# Setup first interface
Get-NetAdapter | Rename-NetAdapter -NewName Public

# Install Hyper-V
Install-WindowsFeature Hyper-V -IncludeManagementTools -Restart

#######################################################################
# automatic reboot here
#######################################################################


#######################################################################
# Install some common tools
#######################################################################
# Install 7-Zip
$url = "https://www.7-zip.org/a/7z1900-x64.msi"
$output = $(Join-Path $env:TEMP '/7zip.msi')
(new-object System.Net.WebClient).DownloadFile($url, $output)
#Invoke-Process -FileName "msiexec.exe" -Arguments "/i $output /quiet"
Start-Process $output -ArgumentList "/qn" -Wait

# Install Microsoft Virtual Machine Converter
$url = "https://download.microsoft.com/download/9/1/E/91E9F42C-3F1F-4AD9-92B7-8DD65DA3B0C2/mvmc_setup.msi"
$output = $(Join-Path $env:TEMP 'mvmc_setup.msi')
(new-object System.Net.WebClient).DownloadFile($url, $output)
#Invoke-Process -FileName "msiexec.exe" -Arguments "/i $output /quiet"
Start-Process $output -ArgumentList "/qn" -Wait

# Set RDP idle logout (via local policy)
# The MaxIdleTime is in milliseconds; by default, this script sets MaxIdleTime to 1 minutes.
$maxIdleTime = 10 * 60 * 1000
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "MaxIdleTime" -Value $maxIdleTime -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "MaxDisconnectionTime" -Value $maxIdleTime -Type "Dword" -Force
#Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "MaxIdleTime" -Value 600000 -Type "Dword"

# Setup idle-logoff (https://github.com/lithnet/idle-logoff/)
$LocalTempDir = $env:TEMP
$InstallFile = "lithnet.idlelogoff.setup.msi"
$url = "https://github.com/lithnet/idle-logoff/releases/download/v1.1.6999/lithnet.idlelogoff.setup.msi"
$output = "$LocalTempDir\$InstallFile"

(new-object System.Net.WebClient).DownloadFile($url, $output)
Start-Process $output -ArgumentList "/qn" -Wait

# Configure idle-logoff timeout
New-Item -Path "HKLM:\SOFTWARE\Lithnet"
New-Item -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "Action" -Value 2 -Type "Dword"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "Enabled" -Value 1 -Type "Dword"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "IdleLimit" -Value 10 -Type "Dword"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "IgnoreDisplayRequested" -Value 1 -Type "Dword"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "WarningEnabled" -Value 1 -Type "Dword"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "WarningMessage" -Value "Your session has been idle for too long, and you will be logged out in {0} seconds" -Type "String"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Lithnet\IdleLogOff" -Name "WarningPeriod" -Value 60 -Type "Dword"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name Lithnet.idlelogoff -Value '"C:\Program Files (x86)\Lithnet\IdleLogoff\Lithnet.IdleLogoff.exe" /start'


#######################################################################
# Start setting up Hyper-V
#######################################################################
New-Item -ItemType Directory -Path c:\VMs -Force

# Create virtual switch
# Set switch as Private -- no routing to the internet
New-VMSwitch -SwitchType Private -Name private

# Add Hyper-V shortcut
$SourceFileLocation = "%windir%\System32\virtmgmt.msc"
$ShortcutLocation = "C:\Users\Student\Desktop\Hyper-V Manager.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutLocation)
$Shortcut.TargetPath = $SourceFileLocation
$Shortcut.Save()

# Setup Hyper-V default file locations
Set-VMHost -VirtualHardDiskPath "C:\VMs"
Set-VMHost -VirtualMachinePath "C:\VMs"
Set-VMHost -EnableEnhancedSessionMode:$true


##############################################################################
# Download ISO files for installation
##############################################################################
# Download Kali ISO
# Review URL for latest version
$url = "https://cdimage.kali.org/kali-2020.2/kali-linux-2020.2-installer-amd64.iso"
$output = "c:\VMs\kali-linux-2020.2-installer-amd64.iso"
(new-object System.Net.WebClient).DownloadFile($url, $output)

# Download Windows Server 2008 R2
# https://archive.org/download/windowsserver2008r2x64/Windows%20Server%202008%20R2%20x64.iso
# https://download.microsoft.com/download/7/5/E/75EC4E54-5B02-42D6-8879-D8D3A25FBEF7/7601.17514.101119-1850_x64fre_server_eval_en-us-GRMSXEVAL_EN_DVD.iso
$url = "https://download.microsoft.com/download/7/5/E/75EC4E54-5B02-42D6-8879-D8D3A25FBEF7/7601.17514.101119-1850_x64fre_server_eval_en-us-GRMSXEVAL_EN_DVD.iso"
$output = "c:\VMs\windowsserver2008r2x64.iso"
(new-object System.Net.WebClient).DownloadFile($url, $output)

# Download Ubuntu 14.04
$url = "http://releases.ubuntu.com/trusty/ubuntu-14.04.6-desktop-amd64.iso"
$output = "c:\VMs\ubuntu-14.04.6-desktop-amd64.iso"
(new-object System.Net.WebClient).DownloadFile($url, $output)

# Download Metasploitable
$url = "http://downloads.metasploit.com/data/metasploitable/metasploitable-linux-2.0.0.zip"
$output = "c:\VMs\metasploitable-linux-2.0.0.zip"
(new-object System.Net.WebClient).DownloadFile($url, $output)


#Download Windows 10 ISO
$url = "https://software-download.microsoft.com/download/pr/18363.418.191007-0143.19h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
$output = "c:\VMs\Windows10.iso"
(new-object System.Net.WebClient).DownloadFile($url, $output)


##############################################################################
# Setup VMs
##############################################################################
#Create New VMs
new-VM -Name "Kali Linux" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\KaliLinux.vhdx -NewVHDSizeBytes 60GB -SwitchName private
new-VM -Name "Windows 2008 R2" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\Win2008R2.vhdx -NewVHDSizeBytes 60GB -SwitchName private
new-VM -Name "Ubuntu 14.04" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\Ubuntu1404.vhdx -NewVHDSizeBytes 60GB -SwitchName private
new-VM -Name "Win10VM" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\Win10VM.vhdx -NewVHDSizeBytes 60GB -SwitchName private

#Mount ISO
Set-VMDvdDrive -VMName "Kali Linux" -Path "c:\VMs\kali-linux-2020.2-installer-amd64.iso"
Set-VMDvdDrive -VMName "Windows 2008 R2" -Path "c:\VMs\windowsserver2008r2x64.iso"
Set-VMDvdDrive -VMName "Ubuntu 14.04" -Path "c:\VMs\ubuntu-14.04.6-desktop-amd64.iso"
Set-VMDvdDrive -VMName Win10VM -Path c:\VMs\Windows10.iso

# Extract, convert, and import Metasploitable
	# Extract
$metasploitableZipFile = "c:\VMs\metasploitable-linux-2.0.0.zip"
$metasploitableHardDiskFilePath = "c:\VMs\Virtual Hard Disks\Metasploitable.vhdx"
Expand-Archive $metasploitableZipFile -DestinationPath $env:TEMP
	# Import MS VM Converter
Import-Module "$env:ProgramFiles\Microsoft Virtual Machine Converter\MvmcCmdlet.psd1"
	# Convert Metasploitable
Write-Host "Converting Metasploitable image files to Hyper-V hard disk file.  Warning: This may take several minutes."
$vmdkFile = Get-ChildItem "$env:TEMP\*.vmdk" -Recurse | Select-Object -expand FullName
#todo: test to make sure this returns
ConvertTo-MvmcVirtualHardDisk -SourceLiteralPath $vmdkFile -DestinationLiteralPath $metasploitableHardDiskFilePath -VhdType DynamicHardDisk -VhdFormat vhdx | Out-Host
	# Import Metasploitable
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
#Download bginfo
New-Item -ItemType Directory -Path c:\bginfo -Force
$url = "https://live.sysinternals.com/Bginfo.exe"
$output = "C:\bginfo\Bginfo.exe"

Import-Module BitsTransfer
Start-BitsTransfer -Source $url -Destination $output

#Download default.bgi
$url = "https://github.com/edgoad/ITVMs/raw/master/default.bgi"
$output = "C:\bginfo\default.bgi"
(new-object System.Net.WebClient).DownloadFile($url, $output)

# Set autorun
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name BgInfo -Value "c:\bginfo\bginfo.exe c:\bginfo\default.bgi /timer:0 /silent /nolicprompt"

# install chrome
$LocalTempDir = $env:TEMP; $ChromeInstaller = "ChromeInstaller.exe"; (new-object    System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller"); & "$LocalTempDir\$ChromeInstaller" /silent /install; $Process2Monitor =  "ChromeInstaller"; Do { $ProcessesFound = Get-Process | ?{$Process2Monitor -contains $_.Name} | Select-Object -ExpandProperty Name; If ($ProcessesFound) { "Still running: $($ProcessesFound -join ', ')" | Write-Host; Start-Sleep -Seconds 2 } else { rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose } } Until (!$ProcessesFound)

#######################################################################
#
# Setup BGInfo, save as c:\bginfo\default.ino
# Power on each VM and install the OS
# When finished, run the second script
#
#######################################################################
