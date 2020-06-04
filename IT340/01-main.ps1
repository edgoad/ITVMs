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

# Create virtual switches
New-VMSwitch -SwitchType Private -Name DMZ
New-VMSwitch -SwitchType Private -Name Servers
New-VMSwitch -SwitchType Private -Name Desktop1
New-VMSwitch -SwitchType Private -Name Desktop2
New-VMSwitch -SwitchType Private -Name Guest
New-VMSwitch -SwitchType Internal -Name ISP
New-VMSwitch -SwitchType Internal -Name MGMT

# Use 203.0.113.0/24 for simulated ISP routing
# https://en.wikipedia.org/wiki/Reserved_IP_addresses
# Setup second interface
Get-NetAdapter | where Name -NE 'Public' | Rename-NetAdapter -NewName Internal
#New-NetIPAddress -InterfaceAlias 'ISP' -IPAddress 192.168.0.250 -PrefixLength 24
New-NetIPAddress -InterfaceAlias 'ISP' -IPAddress 203.0.113.1 -PrefixLength 24

# Configure routing / NAT
#New-NetNat -Name external_routing -InternalIPInterfaceAddressPrefix 192.168.0.0/24
New-NetNat -Name external_routing -InternalIPInterfaceAddressPrefix 203.0.113.0/24


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
#http://panacademy.net/CourseFiles/ova/OS9/OS9_FW.ova

# DownloadPalo Alto FW
$url = "http://panacademy.net/CourseFiles/ova/OS9/OS9_FW.ova"
$output = "c:\VMs\OS9_FW.ova"
(new-object System.Net.WebClient).DownloadFile($url, $output)

# Download Windows Server 2016
$url = "https://software-download.microsoft.com/download/pr/Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
$output = "c:\VMs\Windows_Server_2016.ISO"
(new-object System.Net.WebClient).DownloadFile($url, $output)

# Download Ubuntu 14.04
$url = "http://releases.ubuntu.com/trusty/ubuntu-14.04.6-desktop-amd64.iso"
$output = "c:\VMs\ubuntu-14.04.6-desktop-amd64.iso"
(new-object System.Net.WebClient).DownloadFile($url, $output)



##############################################################################
# Setup VMs
##############################################################################
#Create New VMs
new-VM -Name "LabDMZ1" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "c:\VMs\LabDMZ1.vhdx" -NewVHDSizeBytes 60GB -SwitchName DMZ
new-VM -Name "RTR" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "c:\VMs\RTR.vhdx" -NewVHDSizeBytes 60GB -SwitchName ISP
new-VM -Name "LabDC1" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "c:\VMs\LabDC1.vhdx" -NewVHDSizeBytes 60GB -SwitchName Servers
new-VM -Name "LabDesk1" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath "c:\VMs\LabDesk1.vhdx" -NewVHDSizeBytes 60GB -SwitchName Desktop1
#new-VM -Name "PanFW" -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath C:\VMs\KaliLinux.vhdx -NewVHDSizeBytes 60GB -SwitchName private

#Mount ISO
Set-VMDvdDrive -VMName "LabDMZ1" -Path "c:\VMs\ubuntu-14.04.6-desktop-amd64.iso"
Set-VMDvdDrive -VMName "RTR" -Path "c:\VMs\ubuntu-14.04.6-desktop-amd64.iso"
Set-VMDvdDrive -VMName "LabDC1" -Path "c:\VMs\Windows_Server_2016.ISO"
Set-VMDvdDrive -VMName "LabDesk1" -Path "c:\VMs\Windows_Server_2016.ISO"

# Extract, convert, and import PanFW
	# Extract
$PanFWZipFile = "c:\VMs\OS9_FW.ova"
$PanFWHardDiskFilePath = "c:\VMs\Virtual Hard Disks\PanFW.vhdx"
Expand-Archive $metasploitableZipFile -DestinationPath $env:TEMP
	# Import MS VM Converter
Import-Module "$env:ProgramFiles\Microsoft Virtual Machine Converter\MvmcCmdlet.psd1"
	# Convert Metasploitable
Write-Host "Converting PanFW image files to Hyper-V hard disk file.  Warning: This may take several minutes."
$vmdkFile = Get-ChildItem "$env:TEMP\*.vmdk" -Recurse | Select-Object -expand FullName
#todo: test to make sure this returns
ConvertTo-MvmcVirtualHardDisk -SourceLiteralPath $vmdkFile -DestinationLiteralPath $PanFWHardDiskFilePath -VhdType DynamicHardDisk -VhdFormat vhdx | Out-Host
	# Import PanFW
new-vm -Name "PanFW" -VHDPath $metasploitableHardDiskFilePath -MemoryStartupBytes 512MB
	# configure NIC
get-vm -Name "PanFW" | Add-VMNetworkAdapter -SwitchName "ISP" -IsLegacy $true


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
